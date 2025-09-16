import { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "@/hooks/useAuth";
import { Button } from "@/components/ui/button";
import { MapPin, Users, Navigation } from "lucide-react";

const Index = () => {
  const navigate = useNavigate();
  const { user, loading } = useAuth();

  useEffect(() => {
    if (user) {
      navigate("/dashboard");
    }
  }, [user, navigate]);

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto"></div>
          <p className="mt-4 text-muted-foreground">Loading...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10">
      <div className="container mx-auto px-4 py-16">
        <div className="text-center max-w-4xl mx-auto">
          <div className="mb-8">
            <div className="inline-flex items-center justify-center h-16 w-16 rounded-full bg-primary/10 mb-6">
              <MapPin className="h-8 w-8 text-primary" />
            </div>
            <h1 className="text-5xl font-bold mb-6 bg-gradient-to-r from-primary to-primary/70 bg-clip-text text-transparent">
              Grab Midpoint
            </h1>
            <p className="text-xl text-muted-foreground mb-8 max-w-2xl mx-auto">
              Find the perfect meeting spot for your group and book your ride with Grab. 
              Create sessions, invite friends, and discover the ideal midpoint location.
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-8 mb-12">
            <div className="text-center p-6">
              <Users className="h-12 w-12 text-primary mx-auto mb-4" />
              <h3 className="text-lg font-semibold mb-2">Invite Friends</h3>
              <p className="text-muted-foreground">Create sessions and invite up to 5 people to join</p>
            </div>
            <div className="text-center p-6">
              <Navigation className="h-12 w-12 text-primary mx-auto mb-4" />
              <h3 className="text-lg font-semibold mb-2">Find Midpoint</h3>
              <p className="text-muted-foreground">Automatically calculate the perfect meeting location</p>
            </div>
            <div className="text-center p-6">
              <MapPin className="h-12 w-12 text-primary mx-auto mb-4" />
              <h3 className="text-lg font-semibold mb-2">Book with Grab</h3>
              <p className="text-muted-foreground">Seamlessly book your ride to the chosen destination</p>
            </div>
          </div>

          <Button 
            size="lg" 
            className="text-lg px-8 py-6"
            onClick={() => navigate("/auth")}
          >
            Get Started with Google
          </Button>
        </div>
      </div>
    </div>
  );
};

export default Index;
