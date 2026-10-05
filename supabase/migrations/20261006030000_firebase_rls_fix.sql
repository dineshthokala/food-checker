-- Fix: Make RLS policies work with Firebase JWTs that might map to 'anon' role
-- Run this in Supabase Dashboard > SQL Editor.

-- 1) Drop all existing policies for these tables to avoid conflicts
DO $$ DECLARE r record; BEGIN
  FOR r IN SELECT schemaname, tablename, policyname 
           FROM pg_policies 
           WHERE tablename IN ('profiles','user_conditions','user_allergies','user_medications','saved_foods','food_decisions','food_reports')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', r.policyname, r.schemaname, r.tablename);
  END LOOP;
END $$;

-- 2) Recreate policies using 'TO public' so they work even if PostgREST assigns the 'anon' role.
-- We strictly verify the JWT 'sub' (or 'user_id') or the legacy auth.uid() matches the row's user_id.

CREATE POLICY "profiles_select_own" ON public.profiles FOR SELECT TO public
USING (COALESCE(auth.jwt()->>'sub', auth.jwt()->>'user_id', auth.uid()::text) = id::text);

CREATE POLICY "profiles_insert_own" ON public.profiles FOR INSERT TO public
WITH CHECK (COALESCE(auth.jwt()->>'sub', auth.jwt()->>'user_id', auth.uid()::text) = id::text);

CREATE POLICY "profiles_update_own" ON public.profiles FOR UPDATE TO public
USING (COALESCE(auth.jwt()->>'sub', auth.jwt()->>'user_id', auth.uid()::text) = id::text)
WITH CHECK (COALESCE(auth.jwt()->>'sub', auth.jwt()->>'user_id', auth.uid()::text) = id::text);

CREATE POLICY "user_conditions_all_own" ON public.user_conditions FOR ALL TO public
USING (COALESCE(auth.jwt()->>'sub', auth.jwt()->>'user_id', auth.uid()::text) = user_id::text)
WITH CHECK (COALESCE(auth.jwt()->>'sub', auth.jwt()->>'user_id', auth.uid()::text) = user_id::text);

CREATE POLICY "user_allergies_all_own" ON public.user_allergies FOR ALL TO public
USING (COALESCE(auth.jwt()->>'sub', auth.jwt()->>'user_id', auth.uid()::text) = user_id::text)
WITH CHECK (COALESCE(auth.jwt()->>'sub', auth.jwt()->>'user_id', auth.uid()::text) = user_id::text);

CREATE POLICY "user_medications_all_own" ON public.user_medications FOR ALL TO public
USING (COALESCE(auth.jwt()->>'sub', auth.jwt()->>'user_id', auth.uid()::text) = user_id::text)
WITH CHECK (COALESCE(auth.jwt()->>'sub', auth.jwt()->>'user_id', auth.uid()::text) = user_id::text);

CREATE POLICY "saved_foods_all_own" ON public.saved_foods FOR ALL TO public
USING (COALESCE(auth.jwt()->>'sub', auth.jwt()->>'user_id', auth.uid()::text) = user_id::text)
WITH CHECK (COALESCE(auth.jwt()->>'sub', auth.jwt()->>'user_id', auth.uid()::text) = user_id::text);

CREATE POLICY "food_decisions_all_own" ON public.food_decisions FOR ALL TO public
USING (COALESCE(auth.jwt()->>'sub', auth.jwt()->>'user_id', auth.uid()::text) = user_id::text)
WITH CHECK (COALESCE(auth.jwt()->>'sub', auth.jwt()->>'user_id', auth.uid()::text) = user_id::text);

CREATE POLICY "food_reports_all_own" ON public.food_reports FOR ALL TO public
USING (COALESCE(auth.jwt()->>'sub', auth.jwt()->>'user_id', auth.uid()::text) = user_id::text)
WITH CHECK (COALESCE(auth.jwt()->>'sub', auth.jwt()->>'user_id', auth.uid()::text) = user_id::text);
