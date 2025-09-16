-- Create enum for session status
CREATE TYPE public.session_status AS ENUM ('active', 'completed', 'cancelled');

-- Create profiles table for additional user information
CREATE TABLE public.profiles (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  email TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create sessions table
CREATE TABLE public.sessions (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  invite_code TEXT NOT NULL UNIQUE,
  status session_status NOT NULL DEFAULT 'active',
  max_participants INTEGER NOT NULL DEFAULT 5,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create session participants table
CREATE TABLE public.session_participants (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  session_id UUID NOT NULL REFERENCES public.sessions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  address TEXT,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  joined_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(session_id, user_id)
);

-- Create midpoint calculations table
CREATE TABLE public.midpoint_calculations (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  session_id UUID NOT NULL REFERENCES public.sessions(id) ON DELETE CASCADE,
  midpoint_latitude DECIMAL(10, 8) NOT NULL,
  midpoint_longitude DECIMAL(11, 8) NOT NULL,
  calculated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.midpoint_calculations ENABLE ROW LEVEL SECURITY;

-- Create policies for profiles
CREATE POLICY "Users can view all profiles" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can update their own profile" ON public.profiles FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Create policies for sessions
CREATE POLICY "Users can view sessions they participate in" ON public.sessions FOR SELECT USING (
  created_by = auth.uid() OR 
  EXISTS (SELECT 1 FROM public.session_participants WHERE session_id = id AND user_id = auth.uid())
);
CREATE POLICY "Users can create sessions" ON public.sessions FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Session creators can update their sessions" ON public.sessions FOR UPDATE USING (auth.uid() = created_by);

-- Create policies for session participants
CREATE POLICY "Users can view participants in their sessions" ON public.session_participants FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.sessions WHERE id = session_id AND (created_by = auth.uid() OR EXISTS (SELECT 1 FROM public.session_participants sp WHERE sp.session_id = id AND sp.user_id = auth.uid())))
);
CREATE POLICY "Users can join sessions" ON public.session_participants FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own participation" ON public.session_participants FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can leave sessions" ON public.session_participants FOR DELETE USING (auth.uid() = user_id);

-- Create policies for midpoint calculations
CREATE POLICY "Users can view midpoint calculations for their sessions" ON public.midpoint_calculations FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.sessions WHERE id = session_id AND (created_by = auth.uid() OR EXISTS (SELECT 1 FROM public.session_participants WHERE session_id = id AND user_id = auth.uid())))
);
CREATE POLICY "Session participants can create midpoint calculations" ON public.midpoint_calculations FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.sessions WHERE id = session_id AND (created_by = auth.uid() OR EXISTS (SELECT 1 FROM public.session_participants WHERE session_id = id AND user_id = auth.uid())))
);

-- Create function to update timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Create triggers for automatic timestamp updates
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_sessions_updated_at BEFORE UPDATE ON public.sessions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Create function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (user_id, display_name, email, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', NEW.raw_user_meta_data ->> 'name'),
    NEW.email,
    NEW.raw_user_meta_data ->> 'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Create trigger for automatic profile creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Create function to generate invite codes
CREATE OR REPLACE FUNCTION public.generate_invite_code()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  result TEXT := '';
  i INTEGER;
BEGIN
  FOR i IN 1..6 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::INTEGER, 1);
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql;