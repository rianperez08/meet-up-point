-- Restrict all RLS policies to only apply to authenticated users to resolve anonymous access warnings

-- 1. Update session participants policies to only apply to authenticated users
DROP POLICY IF EXISTS "Users can join sessions" ON public.session_participants;
CREATE POLICY "Users can join sessions"
ON public.session_participants
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can leave sessions" ON public.session_participants;
CREATE POLICY "Users can leave sessions"
ON public.session_participants
FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own participation" ON public.session_participants;
CREATE POLICY "Users can update their own participation"
ON public.session_participants
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view participants in their sessions" ON public.session_participants;
CREATE POLICY "Users can view participants in their sessions"
ON public.session_participants
FOR SELECT
TO authenticated
USING (
  auth.uid() = user_id
  OR
  EXISTS (
    SELECT 1 FROM public.sessions s
    WHERE s.id = session_id
      AND s.created_by = auth.uid()
  )
  OR
  public.user_in_session(session_id, auth.uid())
);

-- 2. Update sessions policies to only apply to authenticated users
DROP POLICY IF EXISTS "Users can create sessions" ON public.sessions;
CREATE POLICY "Users can create sessions"
ON public.sessions
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = created_by);

DROP POLICY IF EXISTS "Session creators can update their sessions" ON public.sessions;
CREATE POLICY "Session creators can update their sessions"
ON public.sessions
FOR UPDATE
TO authenticated
USING (auth.uid() = created_by);

DROP POLICY IF EXISTS "Users can view sessions they participate in" ON public.sessions;
CREATE POLICY "Users can view sessions they participate in"
ON public.sessions
FOR SELECT
TO authenticated
USING (
  created_by = auth.uid()
  OR EXISTS (
    SELECT 1 FROM public.session_participants sp
    WHERE sp.session_id = sessions.id
      AND sp.user_id = auth.uid()
  )
);

-- 3. Update profiles policies to only apply to authenticated users
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile"
ON public.profiles
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile"
ON public.profiles
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view profiles in shared sessions" ON public.profiles;
CREATE POLICY "Users can view profiles in shared sessions"
ON public.profiles
FOR SELECT
TO authenticated
USING (
  auth.uid() = user_id 
  OR 
  EXISTS (
    SELECT 1 
    FROM session_participants sp1
    JOIN session_participants sp2 ON sp1.session_id = sp2.session_id
    WHERE sp1.user_id = auth.uid() 
    AND sp2.user_id = profiles.user_id
  )
);

-- 4. Update midpoint calculations policies to only apply to authenticated users
DROP POLICY IF EXISTS "Session participants can create midpoint calculations" ON public.midpoint_calculations;
CREATE POLICY "Session participants can create midpoint calculations"
ON public.midpoint_calculations
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM sessions
    WHERE sessions.id = midpoint_calculations.session_id
    AND (
      sessions.created_by = auth.uid()
      OR EXISTS (
        SELECT 1 FROM session_participants
        WHERE session_participants.session_id = midpoint_calculations.session_id
        AND session_participants.user_id = auth.uid()
      )
    )
  )
);

DROP POLICY IF EXISTS "Users can view midpoint calculations for their sessions" ON public.midpoint_calculations;
CREATE POLICY "Users can view midpoint calculations for their sessions"
ON public.midpoint_calculations
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM sessions
    WHERE sessions.id = midpoint_calculations.session_id
    AND (
      sessions.created_by = auth.uid()
      OR EXISTS (
        SELECT 1 FROM session_participants
        WHERE session_participants.session_id = midpoint_calculations.session_id
        AND session_participants.user_id = auth.uid()
      )
    )
  )
);