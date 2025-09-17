-- Drop the overly permissive policy that allows viewing all profiles
DROP POLICY IF EXISTS "Users can view all profiles" ON public.profiles;

-- Create a more secure policy that only allows users to view:
-- 1. Their own profile
-- 2. Profiles of users who participate in the same sessions
CREATE POLICY "Users can view profiles in shared sessions" 
ON public.profiles 
FOR SELECT 
USING (
  -- Users can always view their own profile
  auth.uid() = user_id 
  OR 
  -- Users can view profiles of people in their shared sessions
  EXISTS (
    SELECT 1 
    FROM session_participants sp1
    JOIN session_participants sp2 ON sp1.session_id = sp2.session_id
    WHERE sp1.user_id = auth.uid() 
    AND sp2.user_id = profiles.user_id
  )
);