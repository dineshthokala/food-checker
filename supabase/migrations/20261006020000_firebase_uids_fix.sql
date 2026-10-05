-- Fix: ensure id / user_id columns are TEXT (Firebase UIDs).
-- Run in Supabase Dashboard > SQL Editor. Safe to re-run.

-- 0) Drop every FK that touches these columns (by OID, not by name).
DO $$ DECLARE c record; BEGIN
  FOR c IN
    SELECT nsp.nspname AS schema, rel.relname AS tbl, con.conname
    FROM pg_constraint con
    JOIN pg_class rel ON rel.oid = con.conrelid
    JOIN pg_namespace nsp ON nsp.oid = con.connamespace
    JOIN LATERAL unnest(con.conkey) WITH ORDINALITY AS k(attnum, ord) ON true
    JOIN pg_attribute att ON att.attrelid = rel.oid AND att.attnum = k.attnum
    WHERE con.contype = 'f'
      AND nsp.nspname = 'public'
      AND (
        (rel.relname = 'profiles' AND att.attname = 'id')
        OR (rel.relname IN ('user_conditions','user_allergies','user_medications','saved_foods','food_decisions','food_reports')
            AND att.attname = 'user_id')
      )
  LOOP
    BEGIN
      EXECUTE format('ALTER TABLE %I.%I DROP CONSTRAINT %I', c.schema, c.tbl, c.conname);
    EXCEPTION WHEN others THEN NULL;
    END;
  END LOOP;
END $$;

-- 1) Drop all policies that depend on the uuid column type
DO $$ DECLARE r record; BEGIN
  FOR r IN SELECT schemaname, tablename, policyname 
           FROM pg_policies 
           WHERE tablename IN ('profiles','user_conditions','user_allergies','user_medications','saved_foods','food_decisions','food_reports')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', r.policyname, r.schemaname, r.tablename);
  END LOOP;
END $$;

-- 2) child user_id columns -> TEXT.
DO $$ DECLARE r record; BEGIN
  FOR r IN SELECT t FROM (VALUES ('user_conditions'),('user_allergies'),('user_medications'),('saved_foods'),('food_decisions'),('food_reports')) AS v(t)
  LOOP
    BEGIN
      EXECUTE format('ALTER TABLE public.%I ALTER COLUMN user_id TYPE text USING user_id::text', r.t);
    EXCEPTION WHEN others THEN NULL;
    END;
  END LOOP;
END $$;

-- 3) Recreate the policies now that columns are text
CREATE POLICY "profiles_select_own" ON public.profiles FOR SELECT
TO authenticated
USING ((select auth.jwt() ->> 'sub') = id::text OR (select auth.uid())::text = id::text);

CREATE POLICY "profiles_insert_own" ON public.profiles FOR INSERT
TO authenticated
WITH CHECK ((select auth.jwt() ->> 'sub') = id::text OR (select auth.uid())::text = id::text);

CREATE POLICY "profiles_update_own" ON public.profiles FOR UPDATE
TO authenticated
USING ((select auth.jwt() ->> 'sub') = id::text OR (select auth.uid())::text = id::text)
WITH CHECK ((select auth.jwt() ->> 'sub') = id::text OR (select auth.uid())::text = id::text);

CREATE POLICY "user_conditions_all_own" ON public.user_conditions FOR ALL
TO authenticated
USING ((select auth.jwt() ->> 'sub') = user_id::text OR (select auth.uid())::text = user_id::text)
WITH CHECK ((select auth.jwt() ->> 'sub') = user_id::text OR (select auth.uid())::text = user_id::text);

CREATE POLICY "user_allergies_all_own" ON public.user_allergies FOR ALL
TO authenticated
USING ((select auth.jwt() ->> 'sub') = user_id::text OR (select auth.uid())::text = user_id::text)
WITH CHECK ((select auth.jwt() ->> 'sub') = user_id::text OR (select auth.uid())::text = user_id::text);

CREATE POLICY "user_medications_all_own" ON public.user_medications FOR ALL
TO authenticated
USING ((select auth.jwt() ->> 'sub') = user_id::text OR (select auth.uid())::text = user_id::text)
WITH CHECK ((select auth.jwt() ->> 'sub') = user_id::text OR (select auth.uid())::text = user_id::text);

CREATE POLICY "saved_foods_all_own" ON public.saved_foods FOR ALL
TO authenticated
USING ((select auth.jwt() ->> 'sub') = user_id::text OR (select auth.uid())::text = user_id::text)
WITH CHECK ((select auth.jwt() ->> 'sub') = user_id::text OR (select auth.uid())::text = user_id::text);

CREATE POLICY "food_decisions_all_own" ON public.food_decisions FOR ALL
TO authenticated
USING ((select auth.jwt() ->> 'sub') = user_id::text OR (select auth.uid())::text = user_id::text)
WITH CHECK ((select auth.jwt() ->> 'sub') = user_id::text OR (select auth.uid())::text = user_id::text);

CREATE POLICY "food_reports_all_own" ON public.food_reports FOR ALL
TO authenticated
USING ((select auth.jwt() ->> 'sub') = user_id::text OR (select auth.uid())::text = user_id::text)
WITH CHECK ((select auth.jwt() ->> 'sub') = user_id::text OR (select auth.uid())::text = user_id::text);
