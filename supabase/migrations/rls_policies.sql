-- ============================================================
-- GSIAC/ULGDSP — Row-Level Security (RLS) Policies
-- Run this on Supabase SQL Editor (Dashboard → SQL Editor)
-- ============================================================

-- 1. CITIZENS TABLE
-- Citizens can read and update only their own profile.
ALTER TABLE public.citizens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "citizens_select_own" ON public.citizens;
CREATE POLICY "citizens_select_own" ON public.citizens
  FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "citizens_update_own" ON public.citizens;
CREATE POLICY "citizens_update_own" ON public.citizens
  FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "citizens_insert_own" ON public.citizens;
CREATE POLICY "citizens_insert_own" ON public.citizens
  FOR INSERT WITH CHECK (auth.uid() = id);


-- 2. DOCUMENT REQUESTS TABLE
-- Citizens can read/insert their own requests only.
ALTER TABLE public.document_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "doc_requests_select_own" ON public.document_requests;
CREATE POLICY "doc_requests_select_own" ON public.document_requests
  FOR SELECT USING (auth.uid() = citizen_id);

DROP POLICY IF EXISTS "doc_requests_insert_own" ON public.document_requests;
CREATE POLICY "doc_requests_insert_own" ON public.document_requests
  FOR INSERT WITH CHECK (auth.uid() = citizen_id);


-- 3. BENEFICIARY APPLICATIONS TABLE
-- Citizens can read/insert their own applications only.
ALTER TABLE public.beneficiary_applications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "ben_apps_select_own" ON public.beneficiary_applications;
CREATE POLICY "ben_apps_select_own" ON public.beneficiary_applications
  FOR SELECT USING (auth.uid() = citizen_id);

DROP POLICY IF EXISTS "ben_apps_insert_own" ON public.beneficiary_applications;
CREATE POLICY "ben_apps_insert_own" ON public.beneficiary_applications
  FOR INSERT WITH CHECK (auth.uid() = citizen_id);


-- 4. NOTIFICATIONS TABLE
-- Users can read, update, and delete only their own notifications.
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notifications_select_own" ON public.notifications;
CREATE POLICY "notifications_select_own" ON public.notifications
  FOR SELECT USING (auth.uid()::text = user_id::text);

DROP POLICY IF EXISTS "notifications_update_own" ON public.notifications;
CREATE POLICY "notifications_update_own" ON public.notifications
  FOR UPDATE USING (auth.uid()::text = user_id::text);

DROP POLICY IF EXISTS "notifications_delete_own" ON public.notifications;
CREATE POLICY "notifications_delete_own" ON public.notifications
  FOR DELETE USING (auth.uid()::text = user_id::text);

-- Allow system/service role to insert notifications for any user
-- (insertions are done by providers on behalf of the system)
DROP POLICY IF EXISTS "notifications_insert_any" ON public.notifications;
CREATE POLICY "notifications_insert_any" ON public.notifications
  FOR INSERT WITH CHECK (true);


-- 5. BENEFICIARY PROGRAMS TABLE
-- Public read-only access (programs are managed by admin panel).
ALTER TABLE public.beneficiary_programs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "programs_select_all" ON public.beneficiary_programs;
CREATE POLICY "programs_select_all" ON public.beneficiary_programs
  FOR SELECT USING (true);


-- ============================================================
-- STORAGE BUCKET POLICIES (for signed URL access)
-- These restrict direct public access to uploaded documents.
-- After enabling signed URLs in the app, you can optionally
-- disable public access on these buckets via Dashboard →
-- Storage → [bucket] → Settings → Toggle off "Public bucket".
-- ============================================================
