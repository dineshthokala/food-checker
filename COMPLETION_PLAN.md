# FoodChecker — Phased Completion Plan

**Last updated**: 2026-10-06
**Status**: Auth + core screens wired. DB migration & Edge Function need verification.

---

## Current State Summary

| Component | Status | Notes |
|-----------|--------|-------|
| **Auth** | ✅ Done | Firebase Auth (Email + Google) → Supabase Postgres via Third-Party Auth (`lib/firebase_auth_repository.dart`) |
| **Onboarding** | ✅ Done | 4-step: Conditions → Body/Personal → Diet/Allergies/Meds → Consent (`onboarding_screen.dart`) |
| **Home** | ✅ Done | Search, barcode scan, category browse, recent searches, safe foods preview (`home_screen.dart`) |
| **Result** | ✅ Done | Verdict badge, summary, portion tip, alternatives, decision logging, confetti, share, report (`result_screen.dart`) |
| **Safe Foods** | ✅ Done | List, swipe-to-delete, pull-to-refresh, tap to re-check (`safe_foods_screen.dart`) |
| **Profile** | ✅ Done | Avatar, BMI, conditions/allergies/meds, password change, sign out, recent decisions (`profile_screen.dart`) |
| **Offline** | ✅ Done | Hive caching: decisions, reports, safe foods, recent searches (`offline_db.dart`) |
| **Edge Function** | ⚠️ Unverified | `check-food` expected in Supabase Dashboard → Edge Functions |
| **DB Schema** | ⚠️ Pending | `profiles.id` may still be UUID; run diagnostics to confirm |

---

## Phase 1: Stabilize & Ship (Week 1) — **Blocking**

| # | Task | Status | Owner | Notes |
|---|------|--------|-------|-------|
| 1.1 | Run `diagnose_id_types.sql` | 🔴 Blocking | Dev | Confirms `profiles.id` / `user_id` are TEXT |
| 1.2 | Run `diagnose_triggers.sql` | 🔴 Blocking | Dev | Finds `handle_new_user` trigger forcing uuid |
| 1.3 | Fix DB if migration failed | 🔴 Blocking | Dev | `DROP TRIGGER handle_new_user ON auth.users;` then re-run ALTER |
| 1.4 | Verify Edge Function `check-food` | 🔴 Blocking | Dev | Test with sample payload in Supabase Dashboard |
| 1.5 | Add iOS `GoogleService-Info.plist` | 🟡 Needed | Dev | Run `flutterfire configure` after |
| 1.6 | Android release build + internal test | 🟡 Needed | Dev | Keystore, signing, `flutter build appbundle` |
| 1.7 | Smoke test happy path | 🟡 Needed | Dev/QA | Register → Onboard → Search → Save → Profile |

**Goal**: App runs on device, user completes onboarding, gets verdicts, data persists.

---

## Phase 2: Core Quality (Week 2–3)

| Area | Tasks | Rationale |
|------|-------|-----------|
| **Search Intelligence** | Replace hardcoded suggestions (`food_search_provider.dart:104-132`) with server autocomplete (Supabase `pg_trgm` or Meilisearch) | Supports 1000+ foods; offline fallback remains |
| **Rule Engine → Tables** | Move `MockFoodRepository._foodTags` + `_conditionRules` to Supabase tables (`food_tags`, `condition_rules`) | Update rules without app releases |
| **Offline Sync Queue** | Background sync via Realtime or `pg_cron` for decisions/reports | Guarantees eventual consistency |
| **Image Upload** | Profile avatar → Supabase Storage bucket + RLS | Currently only local `File` in state |
| **Error Boundaries** | Wrap screens in `ErrorWidget.builder` + Talker toast | Prevents white-screen crashes |

---

## Phase 3: Differentiation (Week 4–6)

| Feature | Description | Why |
|---------|-------------|-----|
| **Meal/Recipe Check** | Input multiple ingredients → combined verdict | High retention; real-world use case |
| **Daily Log / Timeline** | Calendar view of `food_decisions` + streak counter | Gamifies adherence |
| **Export/Share PDF** | "Doctor visit report" — last 30 days decisions + conditions | Clinical utility |
| **Smart Notifications** | "Time for lunch — check your meal?" via FCM | Re-engagement |
| **Family/Caregiver Mode** | Share profile read-only via Supabase invite flow | Caregiver / doctor involvement |
| **AI Explanations** | Edge Function calls LLM for richer `summary` + `portionTip` | Personalized, trustworthy reasoning |

---

## Phase 4: Scale & Polish (Week 7+)

| Area | Tasks |
|------|-------|
| **iOS Polish** | Dynamic Island for scan, Haptics, VoiceOver labels, App Intents ("Check [food]") |
| **Web PWA** | `flutter build web` → Firebase Hosting |
| **Analytics** | Firebase Analytics + custom events (`food_checked`, `onboarding_completed`, `decision_logged`) |
| **A/B Tests** | Verdict color variants, onboarding copy, alt suggestions placement |
| **Localization** | `intl` + ARB files for Hindi, Spanish, Arabic (top user bases) |

---

## Immediate Next Steps (Today)

1. **Run diagnostics** — paste output of `supabase/migrations/diagnose_id_types.sql` and `diagnose_triggers.sql`
2. **Confirm Edge Function** — test `check-food` in Supabase Dashboard
3. **iOS config** — add `GoogleService-Info.plist` to `ios/Runner/`, run `flutterfire configure`
4. **Decide brand name** — if renaming from "FoodChecker", I'll do a global rename (app ID, bundle, splash, strings) in one pass

---

## File Map (Key Files)

```
lib/
├── main.dart                          # Firebase + Supabase init (Option A)
├── firebase_options.dart              # Android config from google-services.json
├── app.dart                           # Router + theme + Talker
├── core/
│   ├── router/app_router.dart         # GoRouter (no Supabase deep links)
│   ├── theme/app_colors.dart          # Color system
│   ├── theme/app_theme.dart           # Material theme
│   ├── constants/medical_data.dart    # Conditions, allergies, medications, diet types
│   ├── constants/food_data.dart       # Food categories + autocomplete list
│   └── utils/logger.dart              # Talker wrapper
├── models/
│   ├── user_profile.dart              # Full profile + conditions/allergies/meds
│   ├── food_result.dart               # Verdict, summary, alternatives, portion tip
│   └── onboarding_data.dart           # 4-step onboarding state
├── providers/
│   ├── auth_provider.dart             # Firebase authStateChanges listener
│   ├── food_search_provider.dart      # Search, suggestions, recent, result
│   ├── onboarding_provider.dart       # Step state + field setters
│   └── safe_foods_provider.dart       # Local + Supabase sync
├── repositories/
│   ├── auth_repository.dart           # Interface + provider (Firebase impl)
│   ├── firebase_auth_repository.dart  # Email/Google + Supabase profile CRUD
│   ├── food_repository.dart           # Interface + Supabase + Mock fallback
│   ├── supabase_food_repository.dart  # Edge Function `check-food`
│   ├── supabase_safe_foods_repository.dart
│   ├── supabase_food_decision_repository.dart
│   └── supabase_food_report_repository.dart
└── screens/
    ├── splash_screen.dart             # Green branded splash
    ├── auth/login_screen.dart         # Email + Google
    ├── auth/register_screen.dart      # Email + Google
    ├── onboarding/onboarding_screen.dart   # 4 steps (chips, forms, consent)
    ├── home/home_screen.dart          # Search + categories + safe preview
    ├── result/result_screen.dart      # Verdict + decision + share + report
    ├── safe_foods/safe_foods_screen.dart
    ├── profile/profile_screen.dart    # Avatar, BMI, edit, password, decisions
    ├── scanner/scanner_screen.dart    # mobile_scanner barcode → pop
    └── shell/app_shell.dart           # Bottom nav
```

---

## DB Migration Files (Supabase)

| File | Purpose |
|------|---------|
| `supabase/migrations/20261005224435_firebase_uids.sql` | Initial: TEXT columns + RLS on `auth.jwt()->>'sub'` |
| `supabase/migrations/20261006020000_firebase_uids_fix.sql` | Drop FKs by column, drop UUID default, ALTER to TEXT |
| `supabase/migrations/diagnose_id_types.sql` | Shows actual `data_type` + FK count per column |
| `supabase/migrations/diagnose_triggers.sql` | Lists triggers on profile/child tables |

---

## Dependencies (pubspec.yaml additions for this plan)

```yaml
# Already added
firebase_core: ^3.15.2
firebase_auth: ^5.7.0
google_sign_in: ^6.3.0

# Phase 2+
# firebase_messaging: ^15.x   # Notifications
# flutter_local_notifications: ^17.x
# supabase_realtime: ^2.x     # Background sync
# meilisearch: ^0.x           # Search (or pg_trgm)

# Phase 3+
# pdf: ^3.x                   # Doctor report export
# share_plus: ^12.x           # Already present
# openai: ^0.x / http         # AI explanations
```

---

## Notes for Future Maintainers

- **Auth flow**: `lib/main.dart` initializes Firebase first, then Supabase with `accessToken: () => FirebaseAuth.currentUser?.getIdToken()`. All Supabase queries run with Firebase JWT.
- **Profile ID**: `profiles.id` = Firebase `uid` (TEXT). Do **not** use `auth.uid()` in RLS; use `(select auth.jwt() ->> 'sub')`.
- **Offline-first**: Every write goes to Hive first, then Supabase. Reads fall back to Hive on error.
- **Rule engine**: Currently in `MockFoodRepository`. Move to Supabase tables for zero-downtime updates.
- **Scanner**: Returns raw barcode to Home via `context.pop(barcode)`; Home then searches the value.
- **Renaming app**: Change `applicationId` (Android), `PRODUCT_BUNDLE_IDENTIFIER` (iOS), `name` (pubspec), `title` (app.dart), splash config, Firebase project. I can script this.