-- Option A: Firebase Auth + Supabase tables (Third-Party Auth).
-- profiles.id and all user_id columns store the Firebase UID (TEXT),
-- not the Supabase auth.users UUID.
--
-- Run this in Supabase Dashboard > SQL Editor AFTER adding the Firebase
-- Third-Party Auth integration (Auth > Third-Party Auth > Firebase project ID).
--
-- Notes:
-- 1. If tables don't exist yet / app is pre-production, the ALTERs are no-ops
--    guarded by DO blocks. New rows from the app will use Firebase UIDs directly.
-- 2. RLS policies accept BOTH Firebase JWT sub and legacy Supabase auth.uid()
--    during the transition. Remove the auth.uid() OR-branch once all users
--    have re-logged-in via Firebase.

-- 1) Allow TEXT Firebase UIDs in id / user_id columns (idempotent).
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='profiles' AND column_name='id') THEN
    BEGIN
      ALTER TABLE public.profiles ALTER COLUMN id TYPE text USING id::text;
    EXCEPTION WHEN others THEN NULL;
    END;
    BEGIN
      ALTER TABLE public.profiles ALTER COLUMN id DROP DEFAULT;
    EXCEPTION WHEN others THEN NULL;
    END;
    BEGIN
      ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;
    EXCEPTION WHEN others THEN NULL;
    END;
  END IF;
END $$;

DO $$ DECLARE r record; BEGIN
  FOR r IN SELECT table_name FROM (VALUES ('user_conditions'),('user_allergies'),('user_medications'),('saved_foods'),('food_decisions'),('food_reports')) AS t(table_name)
  LOOP
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name=r.table_name AND column_name='user_id') THEN
      BEGIN
        EXECUTE format('ALTER TABLE public.%I ALTER COLUMN user_id TYPE text USING user_id::text', r.table_name);
      EXCEPTION WHEN others THEN NULL;
      END;
    END IF;
  END LOOP;
END $$;

-- 2) Indexes used by RLS + lookups (IF NOT EXISTS).
CREATE INDEX IF NOT EXISTS idx_profiles_id ON public.profiles (id);
CREATE INDEX IF NOT EXISTS idx_user_conditions_user_id ON public.user_conditions (user_id);
CREATE INDEX IF NOT EXISTS idx_user_allergies_user_id ON public.user_allergies (user_id);
CREATE INDEX IF NOT EXISTS idx_user_medications_user_id ON public.user_medications (user_id);
CREATE INDEX IF NOT EXISTS idx_saved_foods_user_id ON public.saved_foods (user_id);
CREATE INDEX IF NOT EXISTS idx_food_decisions_user_id ON public.food_decisions (user_id);
CREATE INDEX IF NOT EXISTS idx_food_reports_user_id ON public.food_reports (user_id);

-- 3) RLS: enable + recreate policies for Firebase JWT sub (+ legacy uid fallback).
-- Helper predicate (inlined per policy for performance):
--   (select auth.jwt() ->> 'sub') = <owner_col>
--   OR (select auth.uid())::text = <owner_col>

-- profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;

CREATE POLICY "profiles_select_own" ON public.profiles FOR SELECT
TO authenticated
USING (
  (select auth.jwt() ->> 'sub') = id
  OR (select auth.uid())::text = id
);

CREATE POLICY "profiles_insert_own" ON public.profiles FOR INSERT
TO authenticated
WITH CHECK (
  (select auth.jwt() ->> 'sub') = id
  OR (select auth.uid())::text = id
);

CREATE POLICY "profiles_update_own" ON public.profiles FOR UPDATE
TO authenticated
USING (
  (select auth.jwt() ->> 'sub') = id
  OR (select auth.uid())::text = id
)
WITH CHECK (
  (select auth.jwt() ->> 'sub') = id
  OR (select auth.uid())::text = id
);

-- user_conditions
ALTER TABLE public.user_conditions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "user_conditions_all_own" ON public.user_conditions;
CREATE POLICY "user_conditions_all_own" ON public.user_conditions FOR ALL
TO authenticated
USING (
  (select auth.jwt() ->> 'sub') = user_id
  OR (select auth.uid())::text = user_id
)
WITH CHECK (
  (select auth.jwt() ->> 'sub') = user_id
  OR (select auth.uid())::text = user_id
);

-- user_allergies
ALTER TABLE public.user_allergies ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "user_allergies_all_own" ON public.user_allergies;
CREATE POLICY "user_allergies_all_own" ON public.user_allergies FOR ALL
TO authenticated
USING (
  (select auth.jwt() ->> 'sub') = user_id
  OR (select auth.uid())::text = user_id
)
WITH CHECK (
  (select auth.jwt() ->> 'sub') = user_id
  OR (select auth.uid())::text = user_id
);

-- user_medications
ALTER TABLE public.user_medications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "user_medications_all_own" ON public.user_medications;
CREATE POLICY "user_medications_all_own" ON public.user_medications FOR ALL
TO authenticated
USING (
  (select auth.jwt() ->> 'sub') = user_id
  OR (select auth.uid())::text = user_id
)
WITH CHECK (
  (select auth.jwt() ->> 'sub') = user_id
  OR (select auth.uid())::text = user_id
);

-- saved_foods
ALTER TABLE public.saved_foods ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "saved_foods_all_own" ON public.saved_foods;
CREATE POLICY "saved_foods_all_own" ON public.saved_foods FOR ALL
TO authenticated
USING (
  (select auth.jwt() ->> 'sub') = user_id
  OR (select auth.uid())::text = user_id
)
WITH CHECK (
  (select auth.jwt() ->> 'sub') = user_id
  OR (select auth.uid())::text = user_id
);

-- food_decisions
ALTER TABLE public.food_decisions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "food_decisions_all_own" ON public.food_decisions;
CREATE POLICY "food_decisions_all_own" ON public.food_decisions FOR ALL
TO authenticated
USING (
  (select auth.jwt() ->> 'sub') = user_id
  OR (select auth.uid())::text = user_id
)
WITH CHECK (
  (select auth.jwt() ->> 'sub') = user_id
  OR (select auth.uid())::text = user_id
);

-- food_reports
ALTER TABLE public.food_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "food_reports_all_own" ON public.food_reports;
CREATE POLICY "food_reports_all_own" ON public.food_reports FOR ALL
TO authenticated
USING (
  (select auth.jwt() ->> 'sub') = user_id
  OR (select auth.uid())::text = user_id
)
WITH CHECK (
  (select auth.jwt() ->> 'sub') = user_id
  OR (select auth.uid())::text = user_id
);
