-- Fix performance warnings by optimizing RLS policies
-- 1. Wrap auth.uid() and current_setting() in (select ...) to prevent re-evaluation for each row
-- 2. Combine multiple permissive policies into single policies

-- =============================================================================
-- POSTS
-- =============================================================================
DROP POLICY IF EXISTS "Admins can delete any post" ON posts;
DROP POLICY IF EXISTS "delete posts" ON posts;
CREATE POLICY "Admins and users can delete posts" ON posts FOR DELETE USING (
  (select auth.uid()) = user_id OR (select is_admin())
);

DROP POLICY IF EXISTS "Admins can update any post" ON posts;
DROP POLICY IF EXISTS "update posts" ON posts;
CREATE POLICY "Admins and users can update posts" ON posts FOR UPDATE USING (
  (select auth.uid()) = user_id OR (select is_admin())
);

-- =============================================================================
-- BUSINESS APPLICATIONS
-- =============================================================================
DROP POLICY IF EXISTS "Admins can delete applications" ON business_applications;
CREATE POLICY "Admins can delete applications" ON business_applications FOR DELETE USING (
  (select is_admin())
);

DROP POLICY IF EXISTS "Admins can manage applications" ON business_applications;
CREATE POLICY "Admins can manage applications" ON business_applications FOR UPDATE USING (
  (select is_admin())
);

DROP POLICY IF EXISTS "Users can access applications" ON business_applications;
CREATE POLICY "Users can access applications" ON business_applications FOR SELECT USING (
  (select auth.uid()) = applicant_id OR (select is_admin())
);

-- =============================================================================
-- POST REPORTS
-- =============================================================================
DROP POLICY IF EXISTS "Admins can view all reports" ON post_reports;
DROP POLICY IF EXISTS "Users can view their own reports" ON post_reports;
CREATE POLICY "Admins and users can view reports" ON post_reports FOR SELECT USING (
  (select auth.uid()) = reporter_id OR (select is_admin())
);

DROP POLICY IF EXISTS "Admins can update reports" ON post_reports;
CREATE POLICY "Admins can update reports" ON post_reports FOR UPDATE USING (
  (select is_admin())
);

DROP POLICY IF EXISTS "Users can create reports" ON post_reports;
CREATE POLICY "Users can create reports" ON post_reports FOR INSERT WITH CHECK (
  (select auth.uid()) = reporter_id
);

-- =============================================================================
-- APPLICATION PAYMENTS
-- =============================================================================
DROP POLICY IF EXISTS "Admins can view all payments" ON application_payments;
DROP POLICY IF EXISTS "Users can view own payments" ON application_payments;
CREATE POLICY "Admins and users can view payments" ON application_payments FOR SELECT USING (
  (select auth.uid()) = user_id OR (select is_admin())
);

DROP POLICY IF EXISTS "Users can create own payments" ON application_payments;
CREATE POLICY "Users can create own payments" ON application_payments FOR INSERT WITH CHECK (
  (select auth.uid()) = user_id
);

-- =============================================================================
-- USER BLOCKS
-- =============================================================================
DROP POLICY IF EXISTS "Users can block others" ON user_blocks;
CREATE POLICY "Users can block others" ON user_blocks FOR INSERT WITH CHECK (
  (select auth.uid()) = blocker_id
);

DROP POLICY IF EXISTS "Users can unblock others" ON user_blocks;
CREATE POLICY "Users can unblock others" ON user_blocks FOR DELETE USING (
  (select auth.uid()) = blocker_id
);

DROP POLICY IF EXISTS "Users can view their own blocks" ON user_blocks;
CREATE POLICY "Users can view their own blocks" ON user_blocks FOR SELECT USING (
  (select auth.uid()) = blocker_id
);

-- =============================================================================
-- BOOKMARKS
-- =============================================================================
DROP POLICY IF EXISTS "Users can create own bookmarks" ON bookmarks;
CREATE POLICY "Users can create own bookmarks" ON bookmarks FOR INSERT WITH CHECK (
  (select auth.uid()) = user_id
);

DROP POLICY IF EXISTS "Users can delete own bookmarks" ON bookmarks;
CREATE POLICY "Users can delete own bookmarks" ON bookmarks FOR DELETE USING (
  (select auth.uid()) = user_id
);

DROP POLICY IF EXISTS "Users can view own bookmarks" ON bookmarks;
CREATE POLICY "Users can view own bookmarks" ON bookmarks FOR SELECT USING (
  (select auth.uid()) = user_id
);

-- =============================================================================
-- PREMIUM PAYMENTS
-- =============================================================================
DROP POLICY IF EXISTS "Users can insert own premium payments" ON premium_payments;
CREATE POLICY "Users can insert own premium payments" ON premium_payments FOR INSERT WITH CHECK (
  (select auth.uid()) = user_id
);

DROP POLICY IF EXISTS "Users can update own premium payments" ON premium_payments;
CREATE POLICY "Users can update own premium payments" ON premium_payments FOR UPDATE USING (
  (select auth.uid()) = user_id
);

DROP POLICY IF EXISTS "Users can view own premium payments" ON premium_payments;
CREATE POLICY "Users can view own premium payments" ON premium_payments FOR SELECT USING (
  (select auth.uid()) = user_id
);

-- =============================================================================
-- NOTIFICATIONS
-- =============================================================================
DROP POLICY IF EXISTS "Users can delete their own notifications" ON notifications;
CREATE POLICY "Users can delete their own notifications" ON notifications FOR DELETE USING (
  (select auth.uid()) = user_id
);

DROP POLICY IF EXISTS "Users can update their own notifications" ON notifications;
CREATE POLICY "Users can update their own notifications" ON notifications FOR UPDATE USING (
  (select auth.uid()) = user_id
);

DROP POLICY IF EXISTS "Users can view their own notifications" ON notifications;
CREATE POLICY "Users can view their own notifications" ON notifications FOR SELECT USING (
  (select auth.uid()) = user_id
);
