-- Optimize RLS policies to reduce auth initplan overhead and duplicate permissive rules
-- Generated on 2025-11-11

BEGIN;

-- Bookmarks: ensure auth context resolved once per statement
DROP POLICY IF EXISTS "Users can view own bookmarks" ON public.bookmarks;
CREATE POLICY "Users can view own bookmarks"
  ON public.bookmarks
  FOR SELECT
  USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can create own bookmarks" ON public.bookmarks;
CREATE POLICY "Users can create own bookmarks"
  ON public.bookmarks
  FOR INSERT
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete own bookmarks" ON public.bookmarks;
CREATE POLICY "Users can delete own bookmarks"
  ON public.bookmarks
  FOR DELETE
  USING ((select auth.uid()) = user_id);

-- Application payments: consolidate view policies and wrap auth lookups
DROP POLICY IF EXISTS "Users can view own payments" ON application_payments;
DROP POLICY IF EXISTS "Admins can view all payments" ON application_payments;
CREATE POLICY "Users can view own payments"
  ON application_payments
  FOR SELECT
  USING (
    user_id = (select auth.uid())
    OR (
      (select auth.uid()) IN (
        SELECT u.id
        FROM public.users u
        WHERE u.email = ANY(
          SELECT unnest(string_to_array(current_setting('app.admin_emails', true), ','))
        )
      )
    )
  );

DROP POLICY IF EXISTS "Users can create own payments" ON application_payments;
CREATE POLICY "Users can create own payments"
  ON application_payments
  FOR INSERT
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Service role can update payments" ON application_payments;
CREATE POLICY "Service role can update payments"
  ON application_payments
  FOR UPDATE
  TO service_role
  USING (true);

DROP POLICY IF EXISTS "Admins can manage payments" ON application_payments;
CREATE POLICY "Admins can manage payments"
  ON application_payments
  FOR UPDATE
  USING (
    (select auth.uid()) IN (
      SELECT u.id
      FROM public.users u
      WHERE u.email = ANY(
        SELECT unnest(string_to_array(current_setting('app.admin_emails', true), ','))
      )
    )
  )
  WITH CHECK (
    (select auth.uid()) IN (
      SELECT u.id
      FROM public.users u
      WHERE u.email = ANY(
        SELECT unnest(string_to_array(current_setting('app.admin_emails', true), ','))
      )
    )
  );

-- Notifications: wrap auth lookups
DROP POLICY IF EXISTS "Users can view their own notifications" ON notifications;
CREATE POLICY "Users can view their own notifications"
  ON notifications
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update their own notifications" ON notifications;
CREATE POLICY "Users can update their own notifications"
  ON notifications
  FOR UPDATE
  TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Authenticated users can create notifications" ON notifications;
CREATE POLICY "Authenticated users can create notifications"
  ON notifications
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "Users can delete their own notifications" ON notifications;
CREATE POLICY "Users can delete their own notifications"
  ON notifications
  FOR DELETE
  TO authenticated
  USING ((select auth.uid()) = user_id);

-- Premium payments: wrap auth lookups
DROP POLICY IF EXISTS "Users can view own premium payments" ON premium_payments;
CREATE POLICY "Users can view own premium payments"
  ON premium_payments
  FOR SELECT
  USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert own premium payments" ON premium_payments;
CREATE POLICY "Users can insert own premium payments"
  ON premium_payments
  FOR INSERT
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own premium payments" ON premium_payments;
CREATE POLICY "Users can update own premium payments"
  ON premium_payments
  FOR UPDATE
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- Comments: collapse duplicate permissive policies and wrap auth lookups
DROP POLICY IF EXISTS "comments_select" ON comments;
DROP POLICY IF EXISTS "comments_select_own" ON comments;
CREATE POLICY "comments_select" ON comments
  FOR SELECT
  USING (
    deleted_at IS NULL
    OR (author_id = (select auth.uid()))
  );

DROP POLICY IF EXISTS "comments_insert" ON comments;
CREATE POLICY "comments_insert" ON comments
  FOR INSERT
  WITH CHECK ((select auth.uid()) = author_id);

DROP POLICY IF EXISTS "comments_update" ON comments;
CREATE POLICY "comments_update" ON comments
  FOR UPDATE
  USING ((select auth.uid()) = author_id)
  WITH CHECK ((select auth.uid()) = author_id);

-- Media: keep single SELECT policy and split write access
DROP POLICY IF EXISTS "view media" ON media;
CREATE POLICY "view media" ON media
  FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "manage media" ON media;
DROP POLICY IF EXISTS "manage media insert" ON media;
DROP POLICY IF EXISTS "manage media update" ON media;
DROP POLICY IF EXISTS "manage media delete" ON media;

CREATE POLICY "manage media insert" ON media
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.posts
      WHERE posts.id = media.post_id
        AND posts.user_id = (select auth.uid())
    )
  );

CREATE POLICY "manage media update" ON media
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1
      FROM public.posts
      WHERE posts.id = media.post_id
        AND posts.user_id = (select auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.posts
      WHERE posts.id = media.post_id
        AND posts.user_id = (select auth.uid())
    )
  );

CREATE POLICY "manage media delete" ON media
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1
      FROM public.posts
      WHERE posts.id = media.post_id
        AND posts.user_id = (select auth.uid())
    )
  );

-- Business applications: combine SELECT permissions and scope admin updates
DROP POLICY IF EXISTS "Users can view own applications" ON business_applications;
DROP POLICY IF EXISTS "Admins can view all applications" ON business_applications;
CREATE POLICY "Users can access applications" ON business_applications
  FOR SELECT
  USING (
    applicant_id = (select auth.uid())
    OR (
      (select auth.uid()) IN (
        SELECT u.id
        FROM public.users u
        WHERE u.email = ANY(
          SELECT unnest(string_to_array(current_setting('app.admin_emails', true), ','))
        )
      )
    )
  );

DROP POLICY IF EXISTS "Users can create applications" ON business_applications;
CREATE POLICY "Users can create applications" ON business_applications
  FOR INSERT
  WITH CHECK ((select auth.uid()) = applicant_id);

CREATE POLICY "Admins can manage applications" ON business_applications
  FOR UPDATE
  USING (
    (select auth.uid()) IN (
      SELECT u.id
      FROM public.users u
      WHERE u.email = ANY(
        SELECT unnest(string_to_array(current_setting('app.admin_emails', true), ','))
      )
    )
  )
  WITH CHECK (
    (select auth.uid()) IN (
      SELECT u.id
      FROM public.users u
      WHERE u.email = ANY(
        SELECT unnest(string_to_array(current_setting('app.admin_emails', true), ','))
      )
    )
  );

CREATE POLICY "Admins can delete applications" ON business_applications
  FOR DELETE
  USING (
    (select auth.uid()) IN (
      SELECT u.id
      FROM public.users u
      WHERE u.email = ANY(
        SELECT unnest(string_to_array(current_setting('app.admin_emails', true), ','))
      )
    )
  );

COMMIT;
