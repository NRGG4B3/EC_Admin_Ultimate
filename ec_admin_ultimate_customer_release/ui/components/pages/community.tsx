import { useState, useEffect, useCallback } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Input } from '../ui/input';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '../ui/dialog';
import { Label } from '../ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Textarea } from '../ui/textarea';
import { ScrollArea } from '../ui/scroll-area';
import { Switch } from '../ui/switch';
import { 
  Users, Calendar, Trophy, Bell, TrendingUp, Plus, Trash2, 
  RefreshCw, Search, Edit, Crown, Star, Medal, Target,
  Megaphone, Heart, MessageSquare, Award, Flag, Clock,
  MapPin, DollarSign, CheckCircle, XCircle, Play, Pause
} from 'lucide-react';
import { toastSuccess, toastError } from '../../lib/toast';

interface CommunityPageProps {
  liveData: any;
}

interface Group {
  id: number;
  name: string;
  description: string;
  group_type: string;
  leader_id: string;
  leader_name: string;
  member_count: number;
  max_members: number;
  is_public: number;
  color: string;
  actual_members: number;
  created_at: string;
}

interface Event {
  id: number;
  title: string;
  description: string;
  event_type: string;
  organizer_id: string;
  organizer_name: string;
  start_time: string;
  duration: number;
  location: string;
  max_participants: number;
  participant_count: number;
  prize_pool: number;
  status: string;
  actual_participants: number;
  created_at: string;
}

interface Achievement {
  id: number;
  name: string;
  description: string;
  category: string;
  icon: string;
  points: number;
  requirement_type: string;
  requirement_value: number;
  is_secret: number;
  unlocked_count: number;
  created_at: string;
}

interface LeaderboardEntry {
  player_id: string;
  player_name: string;
  total_playtime: number;
  total_money: number;
  total_arrests: number;
  total_deaths: number;
  total_kills: number;
  achievement_points: number;
  reputation_score: number;
  rank_position: number;
}

interface Announcement {
  id: number;
  title: string;
  message: string;
  announcement_type: string;
  posted_by: string;
  priority: number;
  is_pinned: number;
  created_at: string;
}

interface CommunityData {
  groups: Group[];
  events: Event[];
  achievements: Achievement[];
  leaderboards: {
    playtime: LeaderboardEntry[];
    money: LeaderboardEntry[];
    achievements: LeaderboardEntry[];
    reputation: LeaderboardEntry[];
  };
  announcements: Announcement[];
  socialFeed: any[];
  stats: {
    totalGroups: number;
    totalMembers: number;
    totalEvents: number;
    upcomingEvents: number;
    totalAchievements: number;
    totalUnlocks: number;
    totalPlayers: number;
    announcements: number;
    activeGroups: number;
  };
  framework: string;
}

export function CommunityPage({ liveData }: CommunityPageProps) {
  const [activeTab, setActiveTab] = useState('groups');
  const [searchTerm, setSearchTerm] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [data, setData] = useState<CommunityData | null>(null);

  // Modals
  const [groupModal, setGroupModal] = useState(false);
  const [eventModal, setEventModal] = useState(false);
  const [achievementModal, setAchievementModal] = useState(false);
  const [announcementModal, setAnnouncementModal] = useState(false);
  const [grantModal, setGrantModal] = useState<{ isOpen: boolean; achievement?: Achievement }>({ isOpen: false });
  const [deleteModal, setDeleteModal] = useState<{ isOpen: boolean; type?: string; id?: number; name?: string }>({ isOpen: false });

  const [formData, setFormData] = useState<any>({});

  // Fetch community data
  const fetchData = useCallback(async () => {
    try {
      const response = await fetch('https://ec_admin_ultimate/community:getData', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
      });

      if (response.ok) {
        // Data will be received via NUI message
      }
    } catch (error) {
      console.log('[Community] Not in FiveM environment');
    }
  }, []);

  // Listen for NUI messages
  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const { action, data: msgData } = event.data;

      if (action === 'communityData') {
        if (msgData.success) {
          setData(msgData.data);
        }
      } else if (action === 'communityResponse') {
        if (msgData.success) {
          toastSuccess({ title: msgData.message });
          fetchData();
        } else {
          toastError({ title: msgData.message });
        }
      } else if (action === 'newAnnouncement') {
        toastSuccess({ 
          title: msgData.title,
          description: msgData.message
        });
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, [fetchData]);

  // Initial load
  useEffect(() => {
    const loadData = async () => {
      await fetchData();
      setIsLoading(false);
    };

    loadData();

    // Auto-refresh every 20 seconds
    const interval = setInterval(() => {
      fetchData();
    }, 20000);

    return () => clearInterval(interval);
  }, [fetchData]);

  // Manual refresh
  const handleRefresh = async () => {
    setRefreshing(true);
    await fetchData();
    setRefreshing(false);
    toastSuccess({ title: 'Data refreshed' });
  };

  // Create group
  const handleCreateGroup = async () => {
    if (!formData.groupName) {
      toastError({ title: 'Please enter a group name' });
      return;
    }

    try {
      await fetch('https://ec_admin_ultimate/community:createGroup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: formData.groupName,
          description: formData.groupDescription || '',
          groupType: formData.groupType || 'custom',
          maxMembers: formData.maxMembers || 50,
          isPublic: formData.isPublic !== false,
          color: formData.groupColor || '#3b82f6'
        })
      });

      setGroupModal(false);
      setFormData({});
    } catch (error) {
      toastError({ title: 'Failed to create group' });
    }
  };

  // Create event
  const handleCreateEvent = async () => {
    if (!formData.eventTitle || !formData.startTime) {
      toastError({ title: 'Please fill all required fields' });
      return;
    }

    try {
      await fetch('https://ec_admin_ultimate/community:createEvent', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: formData.eventTitle,
          description: formData.eventDescription || '',
          eventType: formData.eventType || 'custom',
          startTime: formData.startTime,
          duration: formData.duration || 60,
          location: formData.location || '',
          maxParticipants: formData.maxParticipants || 50,
          prizePool: formData.prizePool || 0
        })
      });

      setEventModal(false);
      setFormData({});
    } catch (error) {
      toastError({ title: 'Failed to create event' });
    }
  };

  // Create achievement
  const handleCreateAchievement = async () => {
    if (!formData.achievementName) {
      toastError({ title: 'Please enter an achievement name' });
      return;
    }

    try {
      await fetch('https://ec_admin_ultimate/community:createAchievement', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: formData.achievementName,
          description: formData.achievementDescription || '',
          category: formData.category || 'general',
          icon: formData.icon || 'trophy',
          points: formData.points || 10,
          requirementType: formData.requirementType || 'manual',
          requirementValue: formData.requirementValue || 1,
          isSecret: formData.isSecret === true
        })
      });

      setAchievementModal(false);
      setFormData({});
    } catch (error) {
      toastError({ title: 'Failed to create achievement' });
    }
  };

  // Create announcement
  const handleCreateAnnouncement = async () => {
    if (!formData.announcementTitle || !formData.announcementMessage) {
      toastError({ title: 'Please fill all required fields' });
      return;
    }

    try {
      await fetch('https://ec_admin_ultimate/community:createAnnouncement', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: formData.announcementTitle,
          message: formData.announcementMessage,
          announcementType: formData.announcementType || 'info',
          priority: formData.priority || 1,
          isPinned: formData.isPinned === true
        })
      });

      setAnnouncementModal(false);
      setFormData({});
    } catch (error) {
      toastError({ title: 'Failed to create announcement' });
    }
  };

  // Delete item
  const handleDelete = async () => {
    if (!deleteModal.type || !deleteModal.id) return;

    try {
      const endpoint = `community:delete${deleteModal.type.charAt(0).toUpperCase() + deleteModal.type.slice(1)}`;
      await fetch('https://ec_admin_ultimate/deleteItem', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          [deleteModal.type + 'Id']: deleteModal.id
        })
      });

      setDeleteModal({ isOpen: false });
    } catch (error) {
      toastError({ title: `Failed to delete ${deleteModal.type}` });
    }
  };

  // Update event status
  const handleUpdateEventStatus = async (eventId: number, status: string) => {
    try {
      await fetch('https://ec_admin_ultimate/community:updateEventStatus', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ eventId, status })
      });
    } catch (error) {
      toastError({ title: 'Failed to update event status' });
    }
  };

  // Grant achievement
  const handleGrantAchievement = async () => {
    if (!formData.grantPlayerId || !grantModal.achievement) {
      toastError({ title: 'Please enter a player ID' });
      return;
    }

    try {
      await fetch('https://ec_admin_ultimate/community:grantAchievement', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          playerId: formData.grantPlayerId,
          playerName: formData.grantPlayerName || 'Unknown',
          achievementId: grantModal.achievement.id
        })
      });

      setGrantModal({ isOpen: false });
      setFormData({});
    } catch (error) {
      toastError({ title: 'Failed to grant achievement' });
    }
  };

  // Format date
  const formatDate = (dateStr: string) => {
    return new Date(dateStr).toLocaleString();
  };

  // Format time
  const formatTime = (minutes: number) => {
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    return hours > 0 ? hours + 'h ' + mins + 'm' : mins + 'm';
  };

  // Get data from state
  const groups = data?.groups || [];
  const events = data?.events || [];
  const achievements = data?.achievements || [];
  const leaderboards = data?.leaderboards || { playtime: [], money: [], achievements: [], reputation: [] };
  const announcements = data?.announcements || [];
  const stats = data?.stats || {
    totalGroups: 0,
    totalMembers: 0,
    totalEvents: 0,
    upcomingEvents: 0,
    totalAchievements: 0,
    totalUnlocks: 0,
    totalPlayers: 0,
    announcements: 0,
    activeGroups: 0
  };

  // Filter data
  const filteredGroups = groups.filter(g =>
    g.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    g.leader_name.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const filteredEvents = events.filter(e =>
    e.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
    e.organizer_name.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const filteredAchievements = achievements.filter(a =>
    a.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    a.category.toLowerCase().includes(searchTerm.toLowerCase())
  );

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="text-center py-12">
          <Users className="size-8 mx-auto mb-4 animate-pulse text-primary" />
          <p className="text-lg font-medium">Loading Community...</p>
          <p className="text-sm text-muted-foreground">Fetching community data</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl tracking-tight flex items-center gap-3">
            <Users className="size-8 text-primary" />
            Community Management
          </h1>
          <p className="text-muted-foreground mt-1">
            Manage groups, events, achievements, and leaderboards
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Button 
            variant="outline" 
            size="sm" 
            onClick={() => setAnnouncementModal(true)}
          >
            <Megaphone className="size-4 mr-2" />
            Announce
          </Button>
          <Button 
            variant="outline" 
            size="sm" 
            onClick={handleRefresh}
            disabled={refreshing}
          >
            <RefreshCw className={`size-4 mr-2 ${refreshing ? 'animate-spin' : ''}`} />
            Refresh
          </Button>
        </div>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-9 gap-4">
        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-blue-500/10 rounded-lg mx-auto w-fit mb-2">
                <Users className="size-6 text-blue-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Total Groups</p>
              <p className="text-xl font-bold">{stats.totalGroups}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-green-500/10 rounded-lg mx-auto w-fit mb-2">
                <CheckCircle className="size-6 text-green-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Active Groups</p>
              <p className="text-xl font-bold">{stats.activeGroups}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-purple-500/10 rounded-lg mx-auto w-fit mb-2">
                <Crown className="size-6 text-purple-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Total Members</p>
              <p className="text-xl font-bold">{stats.totalMembers}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-yellow-500/10 rounded-lg mx-auto w-fit mb-2">
                <Calendar className="size-6 text-yellow-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Total Events</p>
              <p className="text-xl font-bold">{stats.totalEvents}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-orange-500/10 rounded-lg mx-auto w-fit mb-2">
                <Clock className="size-6 text-orange-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Upcoming</p>
              <p className="text-xl font-bold">{stats.upcomingEvents}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-pink-500/10 rounded-lg mx-auto w-fit mb-2">
                <Trophy className="size-6 text-pink-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Achievements</p>
              <p className="text-xl font-bold">{stats.totalAchievements}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-cyan-500/10 rounded-lg mx-auto w-fit mb-2">
                <Star className="size-6 text-cyan-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Total Unlocks</p>
              <p className="text-xl font-bold">{stats.totalUnlocks}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-indigo-500/10 rounded-lg mx-auto w-fit mb-2">
                <TrendingUp className="size-6 text-indigo-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Players</p>
              <p className="text-xl font-bold">{stats.totalPlayers}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-red-500/10 rounded-lg mx-auto w-fit mb-2">
                <Bell className="size-6 text-red-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Announcements</p>
              <p className="text-xl font-bold">{stats.announcements}</p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
        <TabsList className="grid w-full grid-cols-5">
          <TabsTrigger value="groups" className="flex items-center gap-2">
            <Users className="size-4" />
            Groups ({filteredGroups.length})
          </TabsTrigger>
          <TabsTrigger value="events" className="flex items-center gap-2">
            <Calendar className="size-4" />
            Events ({filteredEvents.length})
          </TabsTrigger>
          <TabsTrigger value="achievements" className="flex items-center gap-2">
            <Trophy className="size-4" />
            Achievements ({filteredAchievements.length})
          </TabsTrigger>
          <TabsTrigger value="leaderboards" className="flex items-center gap-2">
            <TrendingUp className="size-4" />
            Leaderboards
          </TabsTrigger>
          <TabsTrigger value="announcements" className="flex items-center gap-2">
            <Bell className="size-4" />
            Announcements ({announcements.length})
          </TabsTrigger>
        </TabsList>

        {/* Search */}
        <div className="flex-1 relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
          <Input
            placeholder="Search..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-9"
          />
        </div>

        {/* Groups Tab */}
        <TabsContent value="groups" className="space-y-4 mt-6">
          <div className="flex justify-end mb-4">
            <Button onClick={() => setGroupModal(true)}>
              <Plus className="size-4 mr-2" />
              Create Group
            </Button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {filteredGroups.map((group) => (
              <Card key={group.id}>
                <CardContent className="p-6">
                  <div className="space-y-3">
                    <div className="flex items-start justify-between">
                      <div className="flex items-center gap-2">
                        <div 
                          className="size-3 rounded-full" 
                          style={{ backgroundColor: group.color }}
                        />
                        <h3 className="font-bold">{group.name}</h3>
                      </div>
                      <Button 
                        variant="ghost" 
                        size="sm"
                        onClick={() => setDeleteModal({ isOpen: true, type: 'group', id: group.id, name: group.name })}
                      >
                        <Trash2 className="size-4 text-destructive" />
                      </Button>
                    </div>
                    <p className="text-sm text-muted-foreground">{group.description}</p>
                    <div className="flex items-center justify-between">
                      <Badge>{group.group_type}</Badge>
                      <Badge variant="outline">
                        {group.actual_members || 0} / {group.max_members}
                      </Badge>
                    </div>
                    <div className="flex items-center gap-2 text-sm">
                      <Crown className="size-4 text-yellow-500" />
                      <span>{group.leader_name}</span>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        {/* Events Tab */}
        <TabsContent value="events" className="space-y-4 mt-6">
          <div className="flex justify-end mb-4">
            <Button onClick={() => setEventModal(true)}>
              <Plus className="size-4 mr-2" />
              Create Event
            </Button>
          </div>

          <ScrollArea className="h-[600px]">
            <div className="space-y-3">
              {filteredEvents.map((event) => (
                <Card key={event.id}>
                  <CardContent className="p-4">
                    <div className="flex items-start justify-between">
                      <div className="space-y-2 flex-1">
                        <div className="flex items-center gap-2">
                          <h3 className="font-bold">{event.title}</h3>
                          <Badge variant={
                            event.status === 'scheduled' ? 'default' :
                            event.status === 'ongoing' ? 'secondary' :
                            event.status === 'completed' ? 'outline' : 'destructive'
                          }>
                            {event.status}
                          </Badge>
                          <Badge>{event.event_type}</Badge>
                        </div>
                        <p className="text-sm text-muted-foreground">{event.description}</p>
                        <div className="grid grid-cols-2 gap-2 text-sm">
                          <div className="flex items-center gap-1">
                            <Clock className="size-4" />
                            <span>{formatDate(event.start_time)}</span>
                          </div>
                          <div className="flex items-center gap-1">
                            <Users className="size-4" />
                            <span>{event.actual_participants || 0} / {event.max_participants}</span>
                          </div>
                          {event.location && (
                            <div className="flex items-center gap-1">
                              <MapPin className="size-4" />
                              <span>{event.location}</span>
                            </div>
                          )}
                          {event.prize_pool > 0 && (
                            <div className="flex items-center gap-1">
                              <DollarSign className="size-4" />
                              <span>${event.prize_pool}</span>
                            </div>
                          )}
                        </div>
                      </div>
                      <div className="flex items-center gap-2">
                        {event.status === 'scheduled' && (
                          <Button 
                            variant="outline" 
                            size="sm"
                            onClick={() => handleUpdateEventStatus(event.id, 'ongoing')}
                          >
                            <Play className="size-4" />
                          </Button>
                        )}
                        {event.status === 'ongoing' && (
                          <Button 
                            variant="outline" 
                            size="sm"
                            onClick={() => handleUpdateEventStatus(event.id, 'completed')}
                          >
                            <CheckCircle className="size-4" />
                          </Button>
                        )}
                        <Button 
                          variant="ghost" 
                          size="sm"
                          onClick={() => setDeleteModal({ isOpen: true, type: 'event', id: event.id, name: event.title })}
                        >
                          <Trash2 className="size-4 text-destructive" />
                        </Button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          </ScrollArea>
        </TabsContent>

        {/* Achievements Tab */}
        <TabsContent value="achievements" className="space-y-4 mt-6">
          <div className="flex justify-end mb-4">
            <Button onClick={() => setAchievementModal(true)}>
              <Plus className="size-4 mr-2" />
              Create Achievement
            </Button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {filteredAchievements.map((achievement) => (
              <Card key={achievement.id}>
                <CardContent className="p-6">
                  <div className="space-y-3">
                    <div className="flex items-start justify-between">
                      <div className="flex items-center gap-2">
                        <Trophy className="size-6 text-yellow-500" />
                        <div>
                          <h3 className="font-bold">{achievement.name}</h3>
                          <Badge variant="outline" className="mt-1">{achievement.category}</Badge>
                        </div>
                      </div>
                      <div className="flex items-center gap-2">
                        <Button 
                          variant="outline" 
                          size="sm"
                          onClick={() => setGrantModal({ isOpen: true, achievement })}
                        >
                          <Award className="size-4" />
                        </Button>
                        <Button 
                          variant="ghost" 
                          size="sm"
                          onClick={() => setDeleteModal({ isOpen: true, type: 'achievement', id: achievement.id, name: achievement.name })}
                        >
                          <Trash2 className="size-4 text-destructive" />
                        </Button>
                      </div>
                    </div>
                    <p className="text-sm text-muted-foreground">{achievement.description}</p>
                    <div className="flex items-center justify-between">
                      <Badge>{achievement.points} points</Badge>
                      <span className="text-sm text-muted-foreground">
                        {achievement.unlocked_count || 0} unlocks
                      </span>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        {/* Leaderboards Tab */}
        <TabsContent value="leaderboards" className="space-y-4 mt-6">
          <Tabs defaultValue="playtime" className="space-y-4">
            <TabsList className="grid w-full grid-cols-4">
              <TabsTrigger value="playtime">Playtime</TabsTrigger>
              <TabsTrigger value="money">Money</TabsTrigger>
              <TabsTrigger value="achievements">Achievements</TabsTrigger>
              <TabsTrigger value="reputation">Reputation</TabsTrigger>
            </TabsList>

            <TabsContent value="playtime">
              <Card>
                <CardHeader>
                  <CardTitle>Top Players by Playtime</CardTitle>
                </CardHeader>
                <CardContent>
                  <ScrollArea className="h-[500px]">
                    <div className="space-y-2">
                      {leaderboards.playtime.map((entry, index) => (
                        <div key={entry.player_id} className="flex items-center justify-between p-3 border rounded-lg">
                          <div className="flex items-center gap-3">
                            <div className="flex items-center justify-center size-8 rounded-full bg-primary/10">
                              <span className="font-bold">#{index + 1}</span>
                            </div>
                            <span className="font-medium">{entry.player_name}</span>
                          </div>
                          <Badge>{formatTime(entry.total_playtime)}</Badge>
                        </div>
                      ))}
                    </div>
                  </ScrollArea>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="money">
              <Card>
                <CardHeader>
                  <CardTitle>Top Players by Money</CardTitle>
                </CardHeader>
                <CardContent>
                  <ScrollArea className="h-[500px]">
                    <div className="space-y-2">
                      {leaderboards.money.map((entry, index) => (
                        <div key={entry.player_id} className="flex items-center justify-between p-3 border rounded-lg">
                          <div className="flex items-center gap-3">
                            <div className="flex items-center justify-center size-8 rounded-full bg-primary/10">
                              <span className="font-bold">#{index + 1}</span>
                            </div>
                            <span className="font-medium">{entry.player_name}</span>
                          </div>
                          <Badge>${entry.total_money.toLocaleString()}</Badge>
                        </div>
                      ))}
                    </div>
                  </ScrollArea>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="achievements">
              <Card>
                <CardHeader>
                  <CardTitle>Top Players by Achievement Points</CardTitle>
                </CardHeader>
                <CardContent>
                  <ScrollArea className="h-[500px]">
                    <div className="space-y-2">
                      {leaderboards.achievements.map((entry, index) => (
                        <div key={entry.player_id} className="flex items-center justify-between p-3 border rounded-lg">
                          <div className="flex items-center gap-3">
                            <div className="flex items-center justify-center size-8 rounded-full bg-primary/10">
                              <span className="font-bold">#{index + 1}</span>
                            </div>
                            <span className="font-medium">{entry.player_name}</span>
                          </div>
                          <Badge>{entry.achievement_points} points</Badge>
                        </div>
                      ))}
                    </div>
                  </ScrollArea>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="reputation">
              <Card>
                <CardHeader>
                  <CardTitle>Top Players by Reputation</CardTitle>
                </CardHeader>
                <CardContent>
                  <ScrollArea className="h-[500px]">
                    <div className="space-y-2">
                      {leaderboards.reputation.map((entry, index) => (
                        <div key={entry.player_id} className="flex items-center justify-between p-3 border rounded-lg">
                          <div className="flex items-center gap-3">
                            <div className="flex items-center justify-center size-8 rounded-full bg-primary/10">
                              <span className="font-bold">#{index + 1}</span>
                            </div>
                            <span className="font-medium">{entry.player_name}</span>
                          </div>
                          <Badge>{entry.reputation_score}</Badge>
                        </div>
                      ))}
                    </div>
                  </ScrollArea>
                </CardContent>
              </Card>
            </TabsContent>
          </Tabs>
        </TabsContent>

        {/* Announcements Tab */}
        <TabsContent value="announcements" className="space-y-4 mt-6">
          <ScrollArea className="h-[600px]">
            <div className="space-y-3">
              {announcements.map((announcement) => (
                <Card key={announcement.id}>
                  <CardContent className="p-4">
                    <div className="flex items-start justify-between">
                      <div className="space-y-2 flex-1">
                        <div className="flex items-center gap-2">
                          <h3 className="font-bold">{announcement.title}</h3>
                          <Badge variant={
                            announcement.announcement_type === 'info' ? 'default' :
                            announcement.announcement_type === 'warning' ? 'destructive' :
                            announcement.announcement_type === 'success' ? 'secondary' :
                            'outline'
                          }>
                            {announcement.announcement_type}
                          </Badge>
                          {announcement.is_pinned === 1 && (
                            <Flag className="size-4 text-yellow-500" />
                          )}
                        </div>
                        <p className="text-sm">{announcement.message}</p>
                        <div className="flex items-center gap-4 text-xs text-muted-foreground">
                          <span>By: {announcement.posted_by}</span>
                          <span>•</span>
                          <span>{formatDate(announcement.created_at)}</span>
                        </div>
                      </div>
                      <Button 
                        variant="ghost" 
                        size="sm"
                        onClick={() => setDeleteModal({ isOpen: true, type: 'announcement', id: announcement.id, name: announcement.title })}
                      >
                        <Trash2 className="size-4 text-destructive" />
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          </ScrollArea>
        </TabsContent>
      </Tabs>

      {/* Create Group Modal */}
      <Dialog open={groupModal} onOpenChange={setGroupModal}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Create Group</DialogTitle>
            <DialogDescription>Create a new community group</DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="groupName">Name</Label>
              <Input
                id="groupName"
                placeholder="Enter group name"
                value={formData.groupName || ''}
                onChange={(e) => setFormData({ ...formData, groupName: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="groupDescription">Description</Label>
              <Textarea
                id="groupDescription"
                placeholder="Enter description"
                value={formData.groupDescription || ''}
                onChange={(e) => setFormData({ ...formData, groupDescription: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="groupType">Type</Label>
              <Select
                value={formData.groupType || 'custom'}
                onValueChange={(value) => setFormData({ ...formData, groupType: value })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="crew">Crew</SelectItem>
                  <SelectItem value="clan">Clan</SelectItem>
                  <SelectItem value="organization">Organization</SelectItem>
                  <SelectItem value="faction">Faction</SelectItem>
                  <SelectItem value="custom">Custom</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="maxMembers">Max Members</Label>
              <Input
                id="maxMembers"
                type="number"
                placeholder="50"
                value={formData.maxMembers || ''}
                onChange={(e) => setFormData({ ...formData, maxMembers: e.target.value })}
              />
            </div>

            <div className="flex items-center space-x-2">
              <Switch
                id="isPublic"
                checked={formData.isPublic !== false}
                onCheckedChange={(checked) => setFormData({ ...formData, isPublic: checked })}
              />
              <Label htmlFor="isPublic">Public Group</Label>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setGroupModal(false)}>
              Cancel
            </Button>
            <Button onClick={handleCreateGroup}>
              Create Group
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Create Event Modal */}
      <Dialog open={eventModal} onOpenChange={setEventModal}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Create Event</DialogTitle>
            <DialogDescription>Schedule a community event</DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="eventTitle">Title</Label>
              <Input
                id="eventTitle"
                placeholder="Enter event title"
                value={formData.eventTitle || ''}
                onChange={(e) => setFormData({ ...formData, eventTitle: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="eventDescription">Description</Label>
              <Textarea
                id="eventDescription"
                placeholder="Enter description"
                value={formData.eventDescription || ''}
                onChange={(e) => setFormData({ ...formData, eventDescription: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="eventType">Type</Label>
              <Select
                value={formData.eventType || 'custom'}
                onValueChange={(value) => setFormData({ ...formData, eventType: value })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="race">Race</SelectItem>
                  <SelectItem value="tournament">Tournament</SelectItem>
                  <SelectItem value="meetup">Meetup</SelectItem>
                  <SelectItem value="heist">Heist</SelectItem>
                  <SelectItem value="custom">Custom</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="startTime">Start Time</Label>
              <Input
                id="startTime"
                type="datetime-local"
                value={formData.startTime || ''}
                onChange={(e) => setFormData({ ...formData, startTime: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="duration">Duration (minutes)</Label>
              <Input
                id="duration"
                type="number"
                placeholder="60"
                value={formData.duration || ''}
                onChange={(e) => setFormData({ ...formData, duration: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="location">Location</Label>
              <Input
                id="location"
                placeholder="Enter location"
                value={formData.location || ''}
                onChange={(e) => setFormData({ ...formData, location: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="maxParticipants">Max Participants</Label>
              <Input
                id="maxParticipants"
                type="number"
                placeholder="50"
                value={formData.maxParticipants || ''}
                onChange={(e) => setFormData({ ...formData, maxParticipants: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="prizePool">Prize Pool ($)</Label>
              <Input
                id="prizePool"
                type="number"
                placeholder="0"
                value={formData.prizePool || ''}
                onChange={(e) => setFormData({ ...formData, prizePool: e.target.value })}
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setEventModal(false)}>
              Cancel
            </Button>
            <Button onClick={handleCreateEvent}>
              Create Event
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Create Achievement Modal */}
      <Dialog open={achievementModal} onOpenChange={setAchievementModal}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Create Achievement</DialogTitle>
            <DialogDescription>Create a new achievement</DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="achievementName">Name</Label>
              <Input
                id="achievementName"
                placeholder="Enter achievement name"
                value={formData.achievementName || ''}
                onChange={(e) => setFormData({ ...formData, achievementName: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="achievementDescription">Description</Label>
              <Textarea
                id="achievementDescription"
                placeholder="Enter description"
                value={formData.achievementDescription || ''}
                onChange={(e) => setFormData({ ...formData, achievementDescription: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="category">Category</Label>
              <Input
                id="category"
                placeholder="general"
                value={formData.category || ''}
                onChange={(e) => setFormData({ ...formData, category: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="points">Points</Label>
              <Input
                id="points"
                type="number"
                placeholder="10"
                value={formData.points || ''}
                onChange={(e) => setFormData({ ...formData, points: e.target.value })}
              />
            </div>

            <div className="flex items-center space-x-2">
              <Switch
                id="isSecret"
                checked={formData.isSecret === true}
                onCheckedChange={(checked) => setFormData({ ...formData, isSecret: checked })}
              />
              <Label htmlFor="isSecret">Secret Achievement</Label>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setAchievementModal(false)}>
              Cancel
            </Button>
            <Button onClick={handleCreateAchievement}>
              Create Achievement
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Create Announcement Modal */}
      <Dialog open={announcementModal} onOpenChange={setAnnouncementModal}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Create Announcement</DialogTitle>
            <DialogDescription>Post a community announcement</DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="announcementTitle">Title</Label>
              <Input
                id="announcementTitle"
                placeholder="Enter title"
                value={formData.announcementTitle || ''}
                onChange={(e) => setFormData({ ...formData, announcementTitle: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="announcementMessage">Message</Label>
              <Textarea
                id="announcementMessage"
                placeholder="Enter message"
                value={formData.announcementMessage || ''}
                onChange={(e) => setFormData({ ...formData, announcementMessage: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="announcementType">Type</Label>
              <Select
                value={formData.announcementType || 'info'}
                onValueChange={(value) => setFormData({ ...formData, announcementType: value })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="info">Info</SelectItem>
                  <SelectItem value="warning">Warning</SelectItem>
                  <SelectItem value="success">Success</SelectItem>
                  <SelectItem value="event">Event</SelectItem>
                  <SelectItem value="update">Update</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="priority">Priority</Label>
              <Input
                id="priority"
                type="number"
                placeholder="1"
                value={formData.priority || ''}
                onChange={(e) => setFormData({ ...formData, priority: e.target.value })}
              />
            </div>

            <div className="flex items-center space-x-2">
              <Switch
                id="isPinned"
                checked={formData.isPinned === true}
                onCheckedChange={(checked) => setFormData({ ...formData, isPinned: checked })}
              />
              <Label htmlFor="isPinned">Pin Announcement</Label>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setAnnouncementModal(false)}>
              Cancel
            </Button>
            <Button onClick={handleCreateAnnouncement}>
              Post Announcement
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Grant Achievement Modal */}
      <Dialog open={grantModal.isOpen} onOpenChange={(open) => !open && setGrantModal({ isOpen: false })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Grant Achievement</DialogTitle>
            <DialogDescription>
              Grant "{grantModal.achievement?.name}" to a player
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="grantPlayerId">Player ID (License/CitizenID)</Label>
              <Input
                id="grantPlayerId"
                placeholder="Enter player identifier"
                value={formData.grantPlayerId || ''}
                onChange={(e) => setFormData({ ...formData, grantPlayerId: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="grantPlayerName">Player Name</Label>
              <Input
                id="grantPlayerName"
                placeholder="Enter player name"
                value={formData.grantPlayerName || ''}
                onChange={(e) => setFormData({ ...formData, grantPlayerName: e.target.value })}
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setGrantModal({ isOpen: false })}>
              Cancel
            </Button>
            <Button onClick={handleGrantAchievement}>
              Grant Achievement
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation Modal */}
      <Dialog open={deleteModal.isOpen} onOpenChange={(open) => !open && setDeleteModal({ isOpen: false })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Confirm Delete</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete "{deleteModal.name}"?
            </DialogDescription>
          </DialogHeader>

          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteModal({ isOpen: false })}>
              Cancel
            </Button>
            <Button variant="destructive" onClick={handleDelete}>
              Delete
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}