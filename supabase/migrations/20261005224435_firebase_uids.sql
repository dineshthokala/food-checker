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
-- Drop FKs that pin these columns to UUID first (e.g. profiles.id -> auth.users.id,
-- child user_id -> profiles.id), then alter. FK names vary, so drop dynamically.
DO $$ DECLARE c record; BEGIN
  FOR c IN
    SELECT con.conname, rel.relname AS tbl, nsp.nspname AS schema
    FROM pg_constraint con
    JOIN pg_class rel ON rel.oid = con.conrelid
    JOIN pg_namespace nsp ON nsp.oid = con.connamespace
    WHERE con.contype = 'f'
      AND (
        (rel.relname = 'profiles' AND pg_get_constraintdef(con.oid) ILIKE '%(id)%')
        OR (rel.relname IN ('user_conditions','user_allergies','user_medications','saved_foods','food_decisions','food_reports')
            AND pg_get_constraintdef(con.oid) ILIKE '%(user_id)%')
      )
  LOOP
    BEGIN
      EXECUTE format('ALTER TABLE %I.%I DROP CONSTRAINT IF EXISTS %I', c.schema, c.tbl, c.conname);
    EXCEPTION WHEN others THEN NULL;
    END;
  END LOOP;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='profiles' AND column_name='id') THEN
    BEGIN
      ALTER TABLE public.profiles ALTER COLUMN id DROP DEFAULT;
    EXCEPTION WHEN others THEN NULL;
    END;
    BEGIN
      ALTER TABLE public.profiles ALTER COLUMN id TYPE text USING id::text;
    EXCEPTION WHEN others THEN
      RAISE NOTICE 'profiles.id alter skipped: %', SQLERRM;
    END;
  END IF;
END $$;

DO $$ DECLARE r record; BEGIN
  FOR r IN SELECT table_name FROM (VALUES ('user_conditions'),('user_allergies'),('user_medications'),('saved_foods'),('food_decisions'),('food_reports')) AS t(table_name)
  LOOP
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name=r.table_name AND column_name='user_id') THEN
      BEGIN
        EXECUTE format('ALTER TABLE public.%I ALTER COLUMN user_id TYPE text USING user_id::text', r.table_name);
      EXCEPTION WHEN others THEN
        RAISE NOTICE '% user_id alter skipped', r.table_name;
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
-- Owner columns are cast to ::text so policies work whether the column is
-- still UUID (alter skipped) or already TEXT. Never compare text = uuid directly.

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
  (select auth.jwt() ->> 'sub') = id::text
  OR (select auth.uid())::text = id::text
);

CREATE POLICY "profiles_insert_own" ON public.profiles FOR INSERT
TO authenticated
WITH CHECK (
  (select auth.jwt() ->> 'sub') = id::text
  OR (select auth.uid())::text = id::text
);

CREATE POLICY "profiles_update_own" ON public.profiles FOR UPDATE
TO authenticated
USING (
  (select auth.jwt() ->> 'sub') = id::text
  OR (select auth.uid())::text = id::text
)
WITH CHECK (
  (select auth.jwt() ->> 'sub') = id::text
  OR (select auth.uid())::text = id::text
);

-- user_conditions
ALTER TABLE public.user_conditions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "user_conditions_all_own" ON public.user_conditions;
CREATE POLICY "user_conditions_all_own" ON public.user_conditions FOR ALL
TO authenticated
USING (
  (select auth.jwt() ->> 'sub') = user_id::text
  OR (select auth.uid())::text = user_id::text
)
WITH CHECK (
  (select auth.jwt() ->> 'sub') = user_id::text
  OR (select auth.uid())::text = user_id::text
);

-- user_allergies
ALTER TABLE public.user_allergies ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "user_allergies_all_own" ON public.user_allergies;
CREATE POLICY "user_allergies_all_own" ON public.user_allergies FOR ALL
TO authenticated
USING (
  (select auth.jwt() ->> 'sub') = user_id::text
  OR (select auth.uid())::text = user_id::text
)
WITH CHECK (
  (select auth.jwt() ->> 'sub') = user_id::text
  OR (select auth.uid())::text = user_id::text
);

-- user_medications
ALTER TABLE public.user_medications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "user_medications_all_own" ON public.user_medications;
CREATE POLICY "user_medications_all_own" ON public.user_medications FOR ALL
TO authenticated
USING (
  (select auth.jwt() ->> 'sub') = user_id::text
  OR (select auth.uid())::text = user_id::text
)
WITH CHECK (
  (select auth.jwt() ->> 'sub') = user_id::text
  OR (select auth.uid())::text = user_id::text
);

-- saved_foods
ALTER TABLE public.saved_foods ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "saved_foods_all_own" ON public.saved_foods;
CREATE POLICY "saved_foods_all_own" ON public.saved_foods FOR ALL
TO authenticated
USING (
  (select auth.jwt() ->> 'sub') = user_id::text
  OR (select auth.uid())::text = user_id::text
)
WITH CHECK (
  (select auth.jwt() ->> 'sub') = user_id::text
  OR (select auth.uid())::text = user_id::text
);

-- food_decisions
ALTER TABLE public.food_decisions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "food_decisions_all_own" ON public.food_decisions;
CREATE POLICY "food_decisions_all_own" ON public.food_decisions FOR ALL
TO authenticated
USING (
  (select auth.jwt() ->> 'sub') = user_id::text
  OR (select auth.uid())::text = user_id::text
)
WITH CHECK (
  (select auth.jwt() ->> 'sub') = user_id::text
  OR (select auth.uid())::text = user_id::text
);

-- food_reports
ALTER TABLE public.food_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "food_reports_all_own" ON public.food_reports;
CREATE POLICY "food_reports_all_own" ON public.food_reports FOR ALL
TO authenticated
USING (
  (select auth.jwt() ->> 'sub') = user_id::text
  OR (select auth.uid())::text = user_id::text
)
WITH CHECK (
  (select auth.jwt() ->> 'sub') = user_id::text
  OR (select auth.uid())::text = user_id::text
);
