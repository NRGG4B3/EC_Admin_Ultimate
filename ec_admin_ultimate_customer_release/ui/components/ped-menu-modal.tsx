import { useState } from 'react';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from './ui/dialog';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { ScrollArea } from './ui/scroll-area';
import { Badge } from './ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from './ui/tabs';
import { User, Search, Users, Shield } from 'lucide-react';

interface PedMenuModalProps {
  isOpen: boolean;
  onClose: () => void;
  targetPlayerId?: number | null; // null = self, number = other player
}

// Comprehensive ped list organized by category
const pedCategories = {
  male: [
    { model: 'mp_m_freemode_01', name: 'Male Freemode', category: 'Freemode' },
    { model: 'a_m_y_business_01', name: 'Young Business Male', category: 'Civilian' },
    { model: 'a_m_y_business_02', name: 'Business Male 2', category: 'Civilian' },
    { model: 'a_m_y_business_03', name: 'Business Male 3', category: 'Civilian' },
    { model: 'a_m_y_businessman_01', name: 'Businessman', category: 'Civilian' },
    { model: 'a_m_y_clubcust_01', name: 'Club Customer', category: 'Civilian' },
    { model: 'a_m_y_downtown_01', name: 'Downtown Male', category: 'Civilian' },
    { model: 'a_m_y_eastsa_01', name: 'East SA Male', category: 'Civilian' },
    { model: 'a_m_y_epsilon_01', name: 'Epsilon Male', category: 'Civilian' },
    { model: 'a_m_y_gay_01', name: 'Gay Male', category: 'Civilian' },
    { model: 'a_m_y_genstreet_01', name: 'Street Male', category: 'Civilian' },
    { model: 'a_m_y_golfer_01', name: 'Golfer', category: 'Civilian' },
    { model: 'a_m_y_hipster_01', name: 'Hipster', category: 'Civilian' },
    { model: 'a_m_y_runner_01', name: 'Runner', category: 'Civilian' },
    { model: 'a_m_y_skater_01', name: 'Skater', category: 'Civilian' },
    { model: 'a_m_y_soucent_01', name: 'South Central Male', category: 'Civilian' },
    { model: 'a_m_y_stbla_01', name: 'Street Black Male', category: 'Civilian' },
    { model: 'a_m_y_vinewood_01', name: 'Vinewood Male', category: 'Civilian' },
    { model: 'a_m_y_yoga_01', name: 'Yoga Male', category: 'Civilian' },
  ],
  female: [
    { model: 'mp_f_freemode_01', name: 'Female Freemode', category: 'Freemode' },
    { model: 'a_f_y_business_01', name: 'Young Business Female', category: 'Civilian' },
    { model: 'a_f_y_business_02', name: 'Business Female 2', category: 'Civilian' },
    { model: 'a_f_y_business_03', name: 'Business Female 3', category: 'Civilian' },
    { model: 'a_f_y_business_04', name: 'Business Female 4', category: 'Civilian' },
    { model: 'a_f_y_clubcust_01', name: 'Club Customer Female', category: 'Civilian' },
    { model: 'a_f_y_fitness_01', name: 'Fitness Female', category: 'Civilian' },
    { model: 'a_f_y_genhot_01', name: 'Hot Female', category: 'Civilian' },
    { model: 'a_f_y_golfer_01', name: 'Golfer Female', category: 'Civilian' },
    { model: 'a_f_y_hipster_01', name: 'Hipster Female', category: 'Civilian' },
    { model: 'a_f_y_runner_01', name: 'Runner Female', category: 'Civilian' },
    { model: 'a_f_y_skater_01', name: 'Skater Female', category: 'Civilian' },
    { model: 'a_f_y_soucent_01', name: 'South Central Female', category: 'Civilian' },
    { model: 'a_f_y_tourist_01', name: 'Tourist Female', category: 'Civilian' },
    { model: 'a_f_y_vinewood_01', name: 'Vinewood Female', category: 'Civilian' },
    { model: 'a_f_y_yoga_01', name: 'Yoga Female', category: 'Civilian' },
  ],
  emergency: [
    { model: 's_m_y_cop_01', name: 'Police Officer', category: 'Law Enforcement' },
    { model: 's_f_y_cop_01', name: 'Female Police Officer', category: 'Law Enforcement' },
    { model: 's_m_y_sheriff_01', name: 'Sheriff', category: 'Law Enforcement' },
    { model: 's_f_y_sheriff_01', name: 'Female Sheriff', category: 'Law Enforcement' },
    { model: 's_m_y_swat_01', name: 'SWAT', category: 'Law Enforcement' },
    { model: 's_m_y_fireman_01', name: 'Firefighter', category: 'Emergency' },
    { model: 's_m_m_paramedic_01', name: 'Paramedic', category: 'Emergency' },
    { model: 's_m_y_uscg_01', name: 'Coast Guard', category: 'Law Enforcement' },
    { model: 's_m_y_armymech_01', name: 'Army Mechanic', category: 'Military' },
    { model: 's_m_y_blackops_01', name: 'Black Ops', category: 'Military' },
    { model: 's_m_y_marine_01', name: 'Marine', category: 'Military' },
    { model: 's_m_y_pilot_01', name: 'Pilot', category: 'Military' },
    { model: 's_m_y_ranger_01', name: 'Ranger', category: 'Law Enforcement' },
    { model: 's_m_y_hwaycop_01', name: 'Highway Cop', category: 'Law Enforcement' },
  ],
  gang: [
    { model: 'g_m_y_ballaeast_01', name: 'Ballas East', category: 'Gang' },
    { model: 'g_m_y_ballaorig_01', name: 'Ballas OG', category: 'Gang' },
    { model: 'g_m_y_ballasout_01', name: 'Ballas South', category: 'Gang' },
    { model: 'g_m_y_famca_01', name: 'Families', category: 'Gang' },
    { model: 'g_m_y_famdnf_01', name: 'Families DNF', category: 'Gang' },
    { model: 'g_m_y_famfor_01', name: 'Families Forum', category: 'Gang' },
    { model: 'g_m_y_korean_01', name: 'Korean', category: 'Gang' },
    { model: 'g_m_y_korean_02', name: 'Korean 2', category: 'Gang' },
    { model: 'g_m_y_korlieut_01', name: 'Korean Lieutenant', category: 'Gang' },
    { model: 'g_m_y_lost_01', name: 'Lost MC', category: 'Gang' },
    { model: 'g_m_y_lost_02', name: 'Lost MC 2', category: 'Gang' },
    { model: 'g_m_y_lost_03', name: 'Lost MC 3', category: 'Gang' },
    { model: 'g_m_y_mexgang_01', name: 'Mexican Gang', category: 'Gang' },
    { model: 'g_m_y_mexgoon_01', name: 'Mexican Goon', category: 'Gang' },
    { model: 'g_m_y_mexgoon_02', name: 'Mexican Goon 2', category: 'Gang' },
    { model: 'g_m_y_mexgoon_03', name: 'Mexican Goon 3', category: 'Gang' },
    { model: 'g_m_y_salvaboss_01', name: 'Salva Boss', category: 'Gang' },
    { model: 'g_m_y_salvagoon_01', name: 'Salva Goon', category: 'Gang' },
    { model: 'g_m_y_strpunk_01', name: 'Street Punk', category: 'Gang' },
    { model: 'g_m_y_strpunk_02', name: 'Street Punk 2', category: 'Gang' },
  ],
  story: [
    { model: 'player_zero', name: 'Michael', category: 'Story' },
    { model: 'player_one', name: 'Franklin', category: 'Story' },
    { model: 'player_two', name: 'Trevor', category: 'Story' },
    { model: 'ig_tracydisanto', name: 'Tracy', category: 'Story' },
    { model: 'ig_jimmydisanto', name: 'Jimmy', category: 'Story' },
    { model: 'ig_lestercrest', name: 'Lester', category: 'Story' },
    { model: 'ig_brad', name: 'Brad', category: 'Story' },
    { model: 'ig_ashley', name: 'Ashley', category: 'Story' },
    { model: 'ig_andreas', name: 'Andreas', category: 'Story' },
    { model: 'ig_ballasog', name: 'Ballas OG', category: 'Story' },
    { model: 'ig_bankman', name: 'Bankman', category: 'Story' },
    { model: 'ig_barry', name: 'Barry', category: 'Story' },
    { model: 'ig_beverly', name: 'Beverly', category: 'Story' },
    { model: 'ig_car3guy1', name: 'Car Buyer', category: 'Story' },
    { model: 'ig_chef', name: 'Chef', category: 'Story' },
    { model: 'ig_chengsr', name: 'Cheng Sr', category: 'Story' },
    { model: 'ig_clay', name: 'Clay', category: 'Story' },
    { model: 'ig_claypain', name: 'Claypain', category: 'Story' },
    { model: 'ig_cletus', name: 'Cletus', category: 'Story' },
    { model: 'ig_dale', name: 'Dale', category: 'Story' },
    { model: 'ig_davenorton', name: 'Dave Norton', category: 'Story' },
    { model: 'ig_denise', name: 'Denise', category: 'Story' },
    { model: 'ig_devin', name: 'Devin', category: 'Story' },
  ]
};

export function PedMenuModal({ isOpen, onClose, targetPlayerId = null }: PedMenuModalProps) {
  const [selectedTab, setSelectedTab] = useState('male');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedPed, setSelectedPed] = useState<string | null>(null);

  const currentPeds = pedCategories[selectedTab as keyof typeof pedCategories] || [];
  
  const filteredPeds = currentPeds.filter(ped => 
    ped.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    ped.model.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const handlePedSelect = (pedModel: string) => {
    setSelectedPed(pedModel);
    
    // Send to FiveM
    if (typeof window !== 'undefined') {
      fetch(`https://ec_admin_ultimate/changePed`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
          pedModel,
          targetPlayerId: targetPlayerId 
        })
      }).then(() => {
        console.log(`[PED MENU] Changed ${targetPlayerId ? `player ${targetPlayerId}` : 'self'} to: ${pedModel}`);
        
        // Show toast
        const event = new CustomEvent('show-toast', {
          detail: { 
            message: `Ped changed to: ${pedModel}`, 
            type: 'success' 
          }
        });
        window.dispatchEvent(event);
        
        // Close after short delay
        setTimeout(() => {
          onClose();
        }, 800);
      }).catch(() => {
        console.log(`[DEV] Change Ped: ${pedModel} for ${targetPlayerId || 'self'}`);
      });
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-3xl max-h-[90vh]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <User className="size-5 text-primary" />
            {targetPlayerId ? `Change Player ${targetPlayerId} Ped` : 'Change Your Ped/Skin'}
          </DialogTitle>
          <DialogDescription>
            {targetPlayerId 
              ? `Select a ped model to change player ${targetPlayerId}'s character`
              : 'Select a ped model to change your character appearance'
            }
          </DialogDescription>
        </DialogHeader>

        {/* Search */}
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 size-4 text-muted-foreground" />
          <Input
            placeholder="Search ped models..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-9"
          />
        </div>

        {/* Tabs for categories */}
        <Tabs value={selectedTab} onValueChange={setSelectedTab} className="w-full">
          <TabsList className="grid w-full grid-cols-5">
            <TabsTrigger value="male" className="text-xs">
              <Users className="size-3.5 mr-1.5" />
              Male
            </TabsTrigger>
            <TabsTrigger value="female" className="text-xs">
              <Users className="size-3.5 mr-1.5" />
              Female
            </TabsTrigger>
            <TabsTrigger value="emergency" className="text-xs">
              <Shield className="size-3.5 mr-1.5" />
              Emergency
            </TabsTrigger>
            <TabsTrigger value="gang" className="text-xs">
              <Users className="size-3.5 mr-1.5" />
              Gang
            </TabsTrigger>
            <TabsTrigger value="story" className="text-xs">
              <User className="size-3.5 mr-1.5" />
              Story
            </TabsTrigger>
          </TabsList>

          <ScrollArea className="h-[400px] mt-4">
            <div className="grid grid-cols-2 gap-2 pr-4">
              {filteredPeds.map((ped) => (
                <button
                  key={ped.model}
                  onClick={() => handlePedSelect(ped.model)}
                  className={`
                    p-3 rounded-lg border transition-all duration-200 text-left group hover:shadow-md
                    ${selectedPed === ped.model 
                      ? 'border-primary bg-primary/5 shadow-md' 
                      : 'border-border hover:border-primary/50 hover:bg-accent'
                    }
                  `}
                >
                  <div className="flex items-center justify-between mb-1">
                    <p className="font-medium text-sm truncate">{ped.name}</p>
                    {selectedPed === ped.model && (
                      <Badge variant="default" className="text-xs">Selected</Badge>
                    )}
                  </div>
                  <p className="text-xs text-muted-foreground truncate mb-1">{ped.model}</p>
                  <Badge variant="outline" className="text-xs">{ped.category}</Badge>
                </button>
              ))}
            </div>

            {filteredPeds.length === 0 && (
              <div className="text-center py-16">
                <Search className="size-12 mx-auto mb-4 text-muted-foreground/50" />
                <p className="text-muted-foreground">No peds found</p>
                <p className="text-sm text-muted-foreground mt-1">Try a different search term</p>
              </div>
            )}
          </ScrollArea>
        </Tabs>

        <DialogFooter>
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button 
            onClick={() => selectedPed && handlePedSelect(selectedPed)}
            disabled={!selectedPed}
          >
            <User className="size-4 mr-2" />
            Apply Ped
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
