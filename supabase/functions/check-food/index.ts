import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface CheckFoodRequest {
  food: string;
  conditions?: string[];
  allergies?: string[];
  medications?: string[];
  diet_type?: string;
  ethnicity?: string;
}

interface FoodResultPayload {
  food: string;
  verdict: "good" | "limit" | "avoid";
  summary: string;
  portion_tip?: string;
  alternatives: string[];
  relevant_conditions: string[];
  confidence?: string;
  sources?: string[];
  disclaimer?: string;
}

// Built-in rule-engine fallback for guaranteed zero-downtime & offline resilience
function evaluateRuleEngine(req: CheckFoodRequest): FoodResultPayload {
  const food = req.food.trim();
  const q = food.toLowerCase();
  const conditions = req.conditions || [];
  const allergies = req.allergies || [];
  const medications = req.medications || [];

  // Check Allergies First
  for (const allergy of allergies) {
    const a = allergy.toLowerCase();
    if (
      (a.includes("peanut") && q.includes("peanut")) ||
      (a.includes("tree nut") && (q.includes("almond") || q.includes("walnut") || q.includes("cashew") || q.includes("pistachio"))) ||
      (a.includes("dairy") && (q.includes("milk") || q.includes("cheese") || q.includes("butter") || q.includes("paneer") || q.includes("cream") || q.includes("yogurt"))) ||
      (a.includes("gluten") && (q.includes("wheat") || q.includes("bread") || q.includes("pasta") || q.includes("barley"))) ||
      (a.includes("shellfish") && (q.includes("shrimp") || q.includes("prawn") || q.includes("crab") || q.includes("lobster") || q.includes("oyster"))) ||
      (a.includes("egg") && q.includes("egg")) ||
      (a.includes("soy") && (q.includes("soy") || q.includes("tofu") || q.includes("edamame")))
    ) {
      return {
        food,
        verdict: "avoid",
        summary: `Contains ${allergy}, which triggers your documented allergy. Immediate avoidance recommended.`,
        portion_tip: "Do not consume.",
        alternatives: ["Allergen-free alternatives", "Fresh whole fruits", "Safe vegetables"],
        relevant_conditions: [allergy],
        confidence: "high",
        sources: ["Allergy Safety Guidelines"],
        disclaimer: "This is general guidance, not medical advice. Always consult your doctor or dietitian.",
      };
    }
  }

  // Check Medication Interactions
  for (const med of medications) {
    const m = med.toLowerCase();
    if (m.includes("statin") && (q.includes("grapefruit") || q.includes("pomelo"))) {
      return {
        food,
        verdict: "avoid",
        summary: `Grapefruit significantly increases statin concentration in your blood, raising risk of muscle toxicity.`,
        portion_tip: "Avoid completely while taking statins.",
        alternatives: ["Oranges", "Apples", "Strawberries"],
        relevant_conditions: [med],
        confidence: "high",
        sources: ["FDA Drug Interaction Guidance"],
        disclaimer: "This is general guidance, not medical advice. Always consult your doctor or dietitian.",
      };
    }
    if (m.includes("warfarin") && (q.includes("spinach") || q.includes("kale") || q.includes("broccoli"))) {
      return {
        food,
        verdict: "limit",
        summary: `High Vitamin K in greens can reduce the effectiveness of warfarin blood thinners. Maintain a steady, consistent intake.`,
        portion_tip: "Keep daily intake consistent; avoid sudden large portions.",
        alternatives: ["Carrots", "Cucumbers", "Bell Peppers"],
        relevant_conditions: [med],
        confidence: "high",
        sources: ["American Heart Association"],
        disclaimer: "This is general guidance, not medical advice. Always consult your doctor or dietitian.",
      };
    }
  }

  // Check Conditions
  const activeConditions: string[] = [];
  let verdict: "good" | "limit" | "avoid" = "good";
  let summary = `${food} is generally safe and nutritious based on your health profile.`;
  let portionTip: string | undefined = "Enjoy as part of a balanced diet.";
  const alternatives: string[] = [];

  for (const condition of conditions) {
    const c = condition.toLowerCase();
    if (c.includes("diabetes")) {
      if (q.includes("sugar") || q.includes("soda") || q.includes("cake") || q.includes("candy") || q.includes("ice cream")) {
        verdict = "avoid";
        activeConditions.push(condition);
        summary = `High simple sugars cause rapid blood glucose spikes in diabetes.`;
        portionTip = "Avoid concentrated sugary foods.";
        alternatives.push("Berries", "Dark Chocolate (85%+)", "Nuts");
      } else if (q.includes("white rice") || q.includes("white bread") || q.includes("potato") || q.includes("pasta") || q.includes("mango")) {
        if (verdict !== "avoid") verdict = "limit";
        activeConditions.push(condition);
        summary = `High glycemic carbohydrates can spike blood glucose levels.`;
        portionTip = "Limit portion to 1/2 cup and pair with protein & fiber.";
        alternatives.push("Brown Rice", "Quinoa", "Cauliflower Rice");
      }
    }

    if (c.includes("hypertension") || c.includes("blood pressure")) {
      if (q.includes("pickle") || q.includes("chips") || q.includes("sausage") || q.includes("bacon") || q.includes("canned soup")) {
        verdict = "avoid";
        activeConditions.push(condition);
        summary = `High sodium content increases fluid retention and blood pressure.`;
        portionTip = "Choose low-sodium or unsalted versions.";
        alternatives.push("Fresh vegetables", "Unsalted roasted nuts", "Air-popped popcorn");
      }
    }

    if (c.includes("kidney") || c.includes("renal") || c.includes("ckd")) {
      if (q.includes("banana") || q.includes("spinach") || q.includes("avocado") || q.includes("tomato") || q.includes("potato")) {
        if (verdict !== "avoid") verdict = "limit";
        activeConditions.push(condition);
        summary = `High potassium content requires monitoring in kidney disease.`;
        portionTip = "Leach potatoes/vegetables or keep portions small.";
        alternatives.push("Apples", "Berries", "Cabbage", "Cucumber");
      }
    }

    if (c.includes("gout")) {
      if (q.includes("red meat") || q.includes("liver") || q.includes("alcohol") || q.includes("beer") || q.includes("sardine") || q.includes("shrimp")) {
        verdict = "avoid";
        activeConditions.push(condition);
        summary = `High purine foods break down into uric acid, triggering painful gout flare-ups.`;
        portionTip = "Avoid high-purine meats and alcohol.";
        alternatives.push("Tofu", "Eggs", "Low-fat dairy", "Cherries");
      }
    }

    if (c.includes("gerd") || c.includes("acid reflux")) {
      if (q.includes("coffee") || q.includes("tomato") || q.includes("citrus") || q.includes("orange") || q.includes("fried") || q.includes("chocolate") || q.includes("alcohol")) {
        if (verdict !== "avoid") verdict = "limit";
        activeConditions.push(condition);
        summary = `Acidic or high-fat foods can relax the lower esophageal sphincter, triggering acid reflux.`;
        portionTip = "Avoid eating within 3 hours before lying down.";
        alternatives.push("Oatmeal", "Bananas", "Chamomile Tea", "Lean poultry");
      }
    }

    if (c.includes("celiac") || c.includes("gluten")) {
      if (q.includes("wheat") || q.includes("bread") || q.includes("pasta") || q.includes("barley") || q.includes("rye") || q.includes("roti")) {
        verdict = "avoid";
        activeConditions.push(condition);
        summary = `Contains gluten, which damages the intestinal lining in celiac disease.`;
        portionTip = "Must be strictly 100% certified gluten-free.";
        alternatives.push("Quinoa", "Brown Rice", "Gluten-Free Oats", "Corn Tortillas");
      }
    }
  }

  return {
    food,
    verdict,
    summary,
    portionTip,
    alternatives: alternatives.length > 0 ? Array.from(new Set(alternatives)).slice(0, 4) : ["Fresh seasonal fruits", "Steamed vegetables", "Lean proteins"],
    relevant_conditions: Array.from(new Set(activeConditions)),
    confidence: "high",
    sources: ["ADA Guidelines", "USDA FoodData Central"],
    disclaimer: "This is general guidance, not medical advice. Always consult your doctor or dietitian.",
  };
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body: CheckFoodRequest = await req.json();
    const { food, conditions = [], allergies = [], medications = [], diet_type, ethnicity } = body;

    if (!food || typeof food !== "string" || food.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: "Missing or invalid 'food' field in request body" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const normalizedFood = food.trim().toLowerCase();

    // 1. Calculate deterministic conditions hash for caching
    const sortedConditions = [...conditions].sort();
    const sortedAllergies = [...allergies].sort();
    const sortedMedications = [...medications].sort();
    const profileKey = [
      `c:${sortedConditions.join(",")}`,
      `a:${sortedAllergies.join(",")}`,
      `m:${sortedMedications.join(",")}`,
      `d:${diet_type || ""}`,
      `e:${ethnicity || ""}`,
    ].join("|");

    const encoder = new TextEncoder();
    const hashBuffer = await crypto.subtle.digest("SHA-256", encoder.encode(profileKey));
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const conditionsHash = hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");

    // 2. Initialize Supabase Client
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: { persistSession: false },
    });

    // 3. Check Food Cache Table
    try {
      const { data: cachedRow } = await supabase
        .from("food_cache")
        .select("result, expires_at")
        .eq("food_normalized", normalizedFood)
        .eq("conditions_hash", conditionsHash)
        .maybeSingle();

      if (cachedRow && new Date(cachedRow.expires_at) > new Date()) {
        return new Response(
          JSON.stringify({
            ...cachedRow.result,
            source: "cache",
          }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    } catch (cacheReadErr) {
      console.warn("Cache read failed, continuing to AI evaluation:", cacheReadErr);
    }

    // 4. Evaluate with Gemini AI if API key is present
    const geminiApiKey = Deno.env.get("GEMINI_API_KEY");
    let resultPayload: FoodResultPayload | null = null;
    let modelVersion = "rules-engine-v1";

    if (geminiApiKey) {
      try {
        const prompt = `You are a clinical dietitian. Evaluate whether the food "${food}" is safe or advisable for a person with this health profile:
- Health Conditions: ${conditions.join(", ") || "None"}
- Allergies: ${allergies.join(", ") || "None"}
- Medications: ${medications.join(", ") || "None"}
- Diet Type: ${diet_type || "Standard"}
- Ethnicity/Culture: ${ethnicity || "Standard"}

Safety Rules:
1. If the food contains a user's allergen, verdict MUST be "avoid".
2. If the food has severe adverse interactions with user's conditions/medications (e.g. grapefruit+statins, sodium+hypertension, high potassium+CKD, sugar+diabetes), verdict MUST be "avoid" or "limit".
3. If safe and nutritious for this profile, verdict is "good".
4. Output ONLY valid JSON matching this schema:
{
  "food": "${food}",
  "verdict": "good" | "limit" | "avoid",
  "summary": "2-3 short, clear sentences explaining why relative to their health profile.",
  "portion_tip": "Optional practical portion or cooking tip",
  "alternatives": ["Alternative 1", "Alternative 2", "Alternative 3"],
  "relevant_conditions": ["Condition or allergy name"],
  "confidence": "high" | "medium" | "low",
  "sources": ["e.g. ADA Guidelines, USDA"]
}`;

        const aiResponse = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiApiKey}`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              contents: [{ parts: [{ text: prompt }] }],
              generationConfig: {
                response_mime_type: "application/json",
                temperature: 0.2,
              },
            }),
          }
        );

        if (aiResponse.ok) {
          const aiData = await aiResponse.json();
          const rawText = aiData?.candidates?.[0]?.content?.parts?.[0]?.text;
          if (rawText) {
            const parsed = JSON.parse(rawText);
            if (parsed.verdict && parsed.summary) {
              resultPayload = {
                food: parsed.food || food,
                verdict: parsed.verdict.toLowerCase(),
                summary: parsed.summary,
                portion_tip: parsed.portion_tip,
                alternatives: Array.isArray(parsed.alternatives) ? parsed.alternatives : [],
                relevant_conditions: Array.isArray(parsed.relevant_conditions) ? parsed.relevant_conditions : [],
                confidence: parsed.confidence || "high",
                sources: Array.isArray(parsed.sources) ? parsed.sources : ["Gemini Clinical Nutrition Model"],
                disclaimer: "This is general guidance, not medical advice. Always consult your doctor or dietitian.",
              };
              modelVersion = "gemini-1.5-flash";
            }
          }
        }
      } catch (aiErr) {
        console.warn("Gemini AI call failed, falling back to rule engine:", aiErr);
      }
    }

    // 5. Fallback to Rule Engine if AI call was skipped or unsuccessful
    if (!resultPayload) {
      resultPayload = evaluateRuleEngine(body);
    }

    // 6. Write to Food Cache
    try {
      await supabase.from("food_cache").upsert(
        {
          food_normalized: normalizedFood,
          conditions_hash: conditionsHash,
          result: resultPayload,
          model_version: modelVersion,
          expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
        },
        { onConflict: "food_normalized, conditions_hash" }
      );
    } catch (cacheWriteErr) {
      console.warn("Cache write failed:", cacheWriteErr);
    }

    return new Response(
      JSON.stringify({
        ...resultPayload,
        source: modelVersion.startsWith("gemini") ? "ai" : "rule_engine",
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err?.message || "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
