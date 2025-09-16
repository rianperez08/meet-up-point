import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { useAuth } from "@/hooks/useAuth";
import { CreateSessionDialog } from "@/components/CreateSessionDialog";
import { JoinSessionDialog } from "@/components/JoinSessionDialog";
import { UserSessions } from "@/components/UserSessions";
import { MapPin, Users, Plus } from "lucide-react";

const Dashboard = () => {
  const { user, signOut } = useAuth();
  const [createDialogOpen, setCreateDialogOpen] = useState(false);
  const [joinDialogOpen, setJoinDialogOpen] = useState(false);

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10">
      <header className="border-b bg-background/80 backdrop-blur-sm">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <MapPin className="h-6 w-6 text-primary" />
            <h1 className="text-xl font-bold">Grab Midpoint</h1>
          </div>
          <div className="flex items-center gap-4">
            <span className="text-sm text-muted-foreground">
              Welcome, {user?.user_metadata?.full_name || user?.email}
            </span>
            <Button variant="outline" onClick={signOut}>
              Sign Out
            </Button>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-8">
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          <Card className="hover:shadow-lg transition-shadow cursor-pointer" onClick={() => setCreateDialogOpen(true)}>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Plus className="h-5 w-5 text-primary" />
                Create Session
              </CardTitle>
              <CardDescription>
                Start a new session and invite up to 5 people
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Button className="w-full">Create New Session</Button>
            </CardContent>
          </Card>

          <Card className="hover:shadow-lg transition-shadow cursor-pointer" onClick={() => setJoinDialogOpen(true)}>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Users className="h-5 w-5 text-primary" />
                Join Session
              </CardTitle>
              <CardDescription>
                Join an existing session with an invite code
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Button variant="secondary" className="w-full">Join Session</Button>
            </CardContent>
          </Card>
        </div>

        <div className="mt-8">
          <UserSessions />
        </div>

        <CreateSessionDialog 
          open={createDialogOpen} 
          onOpenChange={setCreateDialogOpen} 
        />
        
        <JoinSessionDialog 
          open={joinDialogOpen} 
          onOpenChange={setJoinDialogOpen} 
        />
      </main>
    </div>
  );
};

export default Dashboard;