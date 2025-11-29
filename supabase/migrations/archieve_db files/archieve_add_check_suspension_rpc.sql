-- RPC to check if a user is suspended by email
-- This is SECURITY DEFINER to allow checking without being logged in
CREATE OR REPLACE FUNCTION get_suspension_status(email_input TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  user_data RECORD;
  result JSON;
BEGIN
  -- Find the user in public.users by email
  SELECT is_suspended, suspension_reason 
  INTO user_data
  FROM public.users
  WHERE email = email_input
  LIMIT 1;

  IF user_data IS NULL THEN
    RETURN json_build_object('found', false);
  END IF;

  RETURN json_build_object(
    'found', true,
    'is_suspended', user_data.is_suspended,
    'suspension_reason', user_data.suspension_reason
  );
END;
$$;

GRANT EXECUTE ON FUNCTION get_suspension_status(TEXT) TO anon, authenticated;
