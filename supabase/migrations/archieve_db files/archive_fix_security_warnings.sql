-- Fix security warnings by setting search_path for functions
-- This prevents search_path hijacking

ALTER FUNCTION public.has_blocked(UUID) SET search_path = public;
ALTER FUNCTION public.is_blocked_by(UUID) SET search_path = public;
ALTER FUNCTION public.ensure_user_exists(UUID, TEXT, TEXT) SET search_path = public;
ALTER FUNCTION public.increment_post_report_count() SET search_path = public;
ALTER FUNCTION public.update_post_reports_updated_at() SET search_path = public;
ALTER FUNCTION public.increment_post_views(BIGINT[]) SET search_path = public;

-- Move pg_net extension to extensions schema
CREATE SCHEMA IF NOT EXISTS extensions;
-- pg_net is not relocatable, so we must drop and recreate it
DROP EXTENSION IF EXISTS pg_net;
CREATE EXTENSION pg_net SCHEMA extensions;
