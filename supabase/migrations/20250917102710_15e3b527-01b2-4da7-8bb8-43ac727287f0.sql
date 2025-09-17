-- 1) Helper function to safely check if a user is in a session (bypasses RLS)
CREATE OR REPLACE FUNCTION public.user_in_session(_session_id uuid, _user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  select exists (
    select 1
    from public.session_participants
    where session_id = _session_id
      and user_id = _user_id
  );
$$;

-- 2) Fix recursive SELECT policy on session_participants
DROP POLICY IF EXISTS "Users can view participants in their sessions" ON public.session_participants;
CREATE POLICY "Users can view participants in their sessions"
ON public.session_participants
FOR SELECT
USING (
  -- Can view their own row
  auth.uid() = user_id
  OR
  -- Session creator can view all participants
  EXISTS (
    SELECT 1 FROM public.sessions s
    WHERE s.id = session_id
      AND s.created_by = auth.uid()
  )
  OR
  -- Any participant in the session can view other participants
  public.user_in_session(session_id, auth.uid())
);

-- 3) Correct the SELECT policy on sessions to use the right join
DROP POLICY IF EXISTS "Users can view sessions they participate in" ON public.sessions;
CREATE POLICY "Users can view sessions they participate in"
ON public.sessions
FOR SELECT
USING (
  created_by = auth.uid()
  OR EXISTS (
    SELECT 1 FROM public.session_participants sp
    WHERE sp.session_id = sessions.id
      AND sp.user_id = auth.uid()
  )
);