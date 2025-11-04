-- Function to delete user account (both auth and user data)
-- This function allows users to delete their own account
-- It runs with elevated privileges (SECURITY DEFINER) to access auth.users table
-- WARNING: This function permanently deletes user data and cannot be undone

CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user_id uuid;
BEGIN
  -- Get the current authenticated user's ID
  current_user_id := auth.uid();

  -- Check if user is authenticated
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Delete user data from users table
  -- Note: If you have ON DELETE CASCADE constraints in your schema,
  -- this will automatically delete related records (missions, badges, etc.)
  DELETE FROM public.users WHERE id = current_user_id;

  -- Delete the auth user (requires SECURITY DEFINER to access auth schema)
  -- This will invalidate all sessions for this user
  DELETE FROM auth.users WHERE id = current_user_id;

  -- Transaction will commit automatically if no errors occur
  -- If any error occurs, all changes will be rolled back automatically
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION delete_user_account() TO authenticated;

-- Add comment
COMMENT ON FUNCTION delete_user_account() IS 'Allows authenticated users to delete their own account and all associated data';
