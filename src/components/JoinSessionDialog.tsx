import { useState } from "react";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useToast } from "@/hooks/use-toast";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/hooks/useAuth";

interface JoinSessionDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export const JoinSessionDialog = ({ open, onOpenChange }: JoinSessionDialogProps) => {
  const [inviteCode, setInviteCode] = useState("");
  const [loading, setLoading] = useState(false);
  const { toast } = useToast();
  const { user } = useAuth();

  const handleJoin = async () => {
    if (!inviteCode.trim() || !user) return;

    setLoading(true);
    try {
      // Find session by invite code
      const { data: session, error: sessionError } = await supabase
        .from('sessions')
        .select('*, session_participants(count)')
        .eq('invite_code', inviteCode.trim().toUpperCase())
        .eq('status', 'active')
        .single();

      if (sessionError) throw new Error("Session not found");

      // Check if session is full
      const participantCount = session.session_participants?.[0]?.count || 0;
      if (participantCount >= session.max_participants) {
        throw new Error("Session is full");
      }

      // Check if user is already in session
      const { data: existingParticipant } = await supabase
        .from('session_participants')
        .select('id')
        .eq('session_id', session.id)
        .eq('user_id', user.id)
        .single();

      if (existingParticipant) {
        throw new Error("You're already in this session");
      }

      // Join session
      const { error: joinError } = await supabase
        .from('session_participants')
        .insert({
          session_id: session.id,
          user_id: user.id,
        });

      if (joinError) throw joinError;

      toast({
        title: "Joined session!",
        description: `You've joined "${session.name}"`,
      });
      
      setInviteCode("");
      onOpenChange(false);
    } catch (error: any) {
      toast({
        title: "Error joining session",
        description: error.message,
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Join Session</DialogTitle>
          <DialogDescription>
            Enter the invite code to join an existing session.
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-4">
          <div>
            <Label htmlFor="invite-code">Invite Code</Label>
            <Input
              id="invite-code"
              placeholder="e.g., ABC123"
              value={inviteCode}
              onChange={(e) => setInviteCode(e.target.value.toUpperCase())}
              maxLength={6}
            />
          </div>
          <div className="flex gap-2">
            <Button
              onClick={handleJoin}
              disabled={!inviteCode.trim() || loading}
              className="flex-1"
            >
              {loading ? "Joining..." : "Join Session"}
            </Button>
            <Button variant="outline" onClick={() => onOpenChange(false)}>
              Cancel
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
};