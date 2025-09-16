import { useState } from "react";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useToast } from "@/hooks/use-toast";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/hooks/useAuth";

interface CreateSessionDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export const CreateSessionDialog = ({ open, onOpenChange }: CreateSessionDialogProps) => {
  const [sessionName, setSessionName] = useState("");
  const [loading, setLoading] = useState(false);
  const { toast } = useToast();
  const { user } = useAuth();

  const handleCreate = async () => {
    if (!sessionName.trim() || !user) return;

    setLoading(true);
    try {
      // Generate invite code
      const { data: codeData } = await supabase.rpc('generate_invite_code');
      
      const { data, error } = await supabase
        .from('sessions')
        .insert({
          name: sessionName.trim(),
          created_by: user.id,
          invite_code: codeData,
        })
        .select()
        .single();

      if (error) throw error;

      // Add creator as participant
      await supabase
        .from('session_participants')
        .insert({
          session_id: data.id,
          user_id: user.id,
        });

      toast({
        title: "Session created!",
        description: `Invite code: ${data.invite_code}`,
      });
      
      setSessionName("");
      onOpenChange(false);
    } catch (error: any) {
      toast({
        title: "Error creating session",
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
          <DialogTitle>Create New Session</DialogTitle>
          <DialogDescription>
            Create a session and invite up to 5 people to find your perfect meeting spot.
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-4">
          <div>
            <Label htmlFor="session-name">Session Name</Label>
            <Input
              id="session-name"
              placeholder="e.g., Lunch with Friends"
              value={sessionName}
              onChange={(e) => setSessionName(e.target.value)}
            />
          </div>
          <div className="flex gap-2">
            <Button
              onClick={handleCreate}
              disabled={!sessionName.trim() || loading}
              className="flex-1"
            >
              {loading ? "Creating..." : "Create Session"}
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