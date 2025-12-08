import { useState, useEffect, useCallback } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Checkbox } from '../ui/checkbox';
import { Progress } from '../ui/progress';
import { ScrollArea } from '../ui/scroll-area';
import { Textarea } from '../ui/textarea';
import { 
  CheckCircle2, Circle, ClipboardCheck, RefreshCw, 
  FileText, Download, Trash2, TrendingUp
} from 'lucide-react';
import { toastSuccess, toastError } from '../../../lib/toast';

interface TestingChecklistPageProps {
  liveData?: any;
}

interface ChecklistItem {
  id: string;
  text: string;
  category: string;
  checked?: boolean;
  checkedAt?: number;
  notes?: string;
}

interface ChecklistCategory {
  id: string;
  title: string;
  items: ChecklistItem[];
}

interface ChecklistData {
  checklist: {
    categories: ChecklistCategory[];
  };
  progress: {
    total: number;
    checked: number;
    percentage: number;
  };
}

export function TestingChecklistPage({ liveData }: TestingChecklistPageProps) {
  const [data, setData] = useState<ChecklistData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [expandedCategories, setExpandedCategories] = useState<Set<string>>(new Set());
  const [selectedItem, setSelectedItem] = useState<string | null>(null);
  const [itemNotes, setItemNotes] = useState<Record<string, string>>({});
  const [saving, setSaving] = useState<Record<string, boolean>>({});

  // Fetch checklist data
  const fetchChecklist = useCallback(async () => {
    try {
      setIsLoading(true);
      const resourceName = (window as any).GetParentResourceName?.() || 'ec_admin_ultimate';
      const response = await fetch(`https://${resourceName}/testing:getChecklist`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
      });

      if (!response.ok) {
        throw new Error('Failed to fetch checklist');
      }

      const result = await response.json();
      if (result.success && result.checklist) {
        setData(result);
        
        // Initialize notes
        const notes: Record<string, string> = {};
        result.checklist.categories.forEach((cat: ChecklistCategory) => {
          cat.items.forEach((item: ChecklistItem) => {
            if (item.notes) {
              notes[item.id] = item.notes;
            }
          });
        });
        setItemNotes(notes);
        
        // Expand all categories by default
        const allCategories = new Set(result.checklist.categories.map((c: ChecklistCategory) => c.id));
        setExpandedCategories(allCategories);
      }
    } catch (error: any) {
      console.error('Error fetching checklist:', error);
      toastError('Failed to load testing checklist');
    } finally {
      setIsLoading(false);
    }
  }, []);

  // Update item (check/uncheck) - AUTO-SAVES
  const updateItem = useCallback(async (itemId: string, category: string, checked: boolean, notes?: string) => {
    try {
      setSaving(prev => ({ ...prev, [itemId]: true }));
      
      const response = await fetch('https://ec_admin_ultimate/testing:updateItem', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          itemId,
          category,
          checked,
          notes: notes || itemNotes[itemId] || null
        })
      });

      if (!response.ok) {
        throw new Error('Failed to update item');
      }

      const result = await response.json();
      if (result.success) {
        // Update local state immediately
        setData(prev => {
          if (!prev) return null;
          
          const updated = { ...prev };
          updated.checklist.categories.forEach(cat => {
            cat.items.forEach(item => {
              if (item.id === itemId) {
                item.checked = checked;
                item.checkedAt = checked ? Date.now() : undefined;
                if (notes !== undefined) {
                  item.notes = notes;
                }
              }
            });
          });
          
          // Recalculate progress
          let total = 0;
          let checkedCount = 0;
          updated.checklist.categories.forEach(cat => {
            cat.items.forEach(item => {
              total++;
              if (item.checked) checkedCount++;
            });
          });
          
          updated.progress = {
            total,
            checked: checkedCount,
            percentage: total > 0 ? Math.floor((checkedCount / total) * 100) : 0
          };
          
          return updated;
        });
        
        if (checked) {
          toastSuccess(`✅ Checked: ${data?.checklist.categories.find(c => c.id === category)?.items.find(i => i.id === itemId)?.text || itemId}`);
        }
      }
    } catch (error: any) {
      console.error('Error updating item:', error);
      toastError('Failed to update checklist item');
    } finally {
      setSaving(prev => {
        const updated = { ...prev };
        delete updated[itemId];
        return updated;
      });
    }
  }, [itemNotes, data]);

  // Save notes for an item
  const saveNotes = useCallback(async (itemId: string, category: string, notes: string) => {
    const item = data?.checklist.categories.find(c => c.id === category)?.items.find(i => i.id === itemId);
    if (!item) return;
    
    await updateItem(itemId, category, item.checked || false, notes);
    setItemNotes(prev => ({ ...prev, [itemId]: notes }));
  }, [data, updateItem]);

  // Reset all progress
  const resetProgress = useCallback(async () => {
    if (!confirm('Are you sure you want to reset all testing progress? This cannot be undone.')) {
      return;
    }

    try {
      const resourceName = (window as any).GetParentResourceName?.() || 'ec_admin_ultimate';
      const response = await fetch(`https://${resourceName}/testing:resetProgress`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
      });

      if (!response.ok) {
        throw new Error('Failed to reset progress');
      }

      const result = await response.json();
      if (result.success) {
        toastSuccess('Testing progress reset successfully');
        fetchChecklist();
      }
    } catch (error: any) {
      console.error('Error resetting progress:', error);
      toastError('Failed to reset progress');
    }
  }, [fetchChecklist]);

  // Toggle category expansion
  const toggleCategory = useCallback((categoryId: string) => {
    setExpandedCategories(prev => {
      const updated = new Set(prev);
      if (updated.has(categoryId)) {
        updated.delete(categoryId);
      } else {
        updated.add(categoryId);
      }
      return updated;
    });
  }, []);

  // Load checklist on mount
  useEffect(() => {
    fetchChecklist();
  }, [fetchChecklist]);

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="text-center">
          <RefreshCw className="h-8 w-8 animate-spin mx-auto mb-4 text-muted-foreground" />
          <p className="text-muted-foreground">Loading testing checklist...</p>
        </div>
      </div>
    );
  }

  if (!data) {
    return (
      <div className="flex items-center justify-center h-full">
        <Card className="w-full max-w-md">
          <CardHeader>
            <CardTitle>Error Loading Checklist</CardTitle>
            <CardDescription>Failed to load testing checklist</CardDescription>
          </CardHeader>
          <CardContent>
            <Button onClick={fetchChecklist} className="w-full">
              <RefreshCw className="h-4 w-4 mr-2" />
              Retry
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  const { checklist, progress } = data;

  return (
    <div className="space-y-6 p-6">
      {/* Header with Progress */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="flex items-center gap-2">
                <ClipboardCheck className="h-6 w-6" />
                Testing Checklist
              </CardTitle>
              <CardDescription>
                Track your testing progress - items auto-save when checked
              </CardDescription>
            </div>
            <div className="flex items-center gap-4">
              <Button variant="outline" size="sm" onClick={resetProgress}>
                <Trash2 className="h-4 w-4 mr-2" />
                Reset Progress
              </Button>
              <Button variant="outline" size="sm" onClick={fetchChecklist}>
                <RefreshCw className="h-4 w-4 mr-2" />
                Refresh
              </Button>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium">Overall Progress</p>
                <p className="text-2xl font-bold">{progress.checked} / {progress.total}</p>
              </div>
              <div className="text-right">
                <p className="text-sm text-muted-foreground">Completion</p>
                <p className="text-2xl font-bold text-primary">{progress.percentage}%</p>
              </div>
            </div>
            <Progress value={progress.percentage} className="h-3" />
          </div>
        </CardContent>
      </Card>

      {/* Checklist Categories */}
      <ScrollArea className="h-[calc(100vh-300px)]">
        <div className="space-y-4">
          {checklist.categories.map((category) => {
            const categoryItems = category.items || [];
            const categoryChecked = categoryItems.filter(item => item.checked).length;
            const categoryTotal = categoryItems.length;
            const categoryProgress = categoryTotal > 0 ? Math.floor((categoryChecked / categoryTotal) * 100) : 0;
            const isExpanded = expandedCategories.has(category.id);

            return (
              <Card key={category.id}>
                <CardHeader>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3 flex-1">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => toggleCategory(category.id)}
                        className="h-8 w-8 p-0"
                      >
                        {isExpanded ? '▼' : '▶'}
                      </Button>
                      <div className="flex-1">
                        <CardTitle className="text-lg">{category.title}</CardTitle>
                        <CardDescription>
                          {categoryChecked} / {categoryTotal} items checked ({categoryProgress}%)
                        </CardDescription>
                      </div>
                    </div>
                    <Badge variant={categoryProgress === 100 ? "default" : "secondary"}>
                      {categoryProgress}%
                    </Badge>
                  </div>
                </CardHeader>
                {isExpanded && (
                  <CardContent>
                    <div className="space-y-3">
                      {categoryItems.map((item) => (
                        <div
                          key={item.id}
                          className={`flex items-start gap-3 p-3 rounded-lg border transition-colors ${
                            item.checked
                              ? 'bg-green-50 dark:bg-green-950/20 border-green-200 dark:border-green-800'
                              : 'bg-background border-border hover:bg-muted/50'
                          }`}
                        >
                          <div className="pt-1">
                            <Checkbox
                              checked={item.checked || false}
                              onCheckedChange={(checked) => {
                                updateItem(item.id, category.id, checked === true);
                              }}
                              disabled={saving[item.id]}
                            />
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-start justify-between gap-2">
                              <label
                                className="flex-1 text-sm font-medium cursor-pointer"
                                onClick={() => {
                                  if (!saving[item.id]) {
                                    updateItem(item.id, category.id, !item.checked);
                                  }
                                }}
                              >
                                {item.text}
                              </label>
                              {item.checked && item.checkedAt && (
                                <span className="text-xs text-muted-foreground whitespace-nowrap">
                                  {new Date(item.checkedAt * 1000).toLocaleDateString()}
                                </span>
                              )}
                            </div>
                            {(selectedItem === item.id || item.notes) && (
                              <div className="mt-2">
                                <Textarea
                                  placeholder="Add notes (optional)..."
                                  value={itemNotes[item.id] || item.notes || ''}
                                  onChange={(e) => {
                                    setItemNotes(prev => ({ ...prev, [item.id]: e.target.value }));
                                  }}
                                  onBlur={() => {
                                    if (itemNotes[item.id] !== undefined) {
                                      saveNotes(item.id, category.id, itemNotes[item.id] || '');
                                    }
                                  }}
                                  className="min-h-[60px] text-xs"
                                  rows={2}
                                />
                              </div>
                            )}
                            {!selectedItem && !item.notes && (
                              <Button
                                variant="ghost"
                                size="sm"
                                className="mt-1 h-6 text-xs"
                                onClick={() => setSelectedItem(item.id)}
                              >
                                <FileText className="h-3 w-3 mr-1" />
                                Add Notes
                              </Button>
                            )}
                          </div>
                          {saving[item.id] && (
                            <RefreshCw className="h-4 w-4 animate-spin text-muted-foreground" />
                          )}
                        </div>
                      ))}
                    </div>
                  </CardContent>
                )}
              </Card>
            );
          })}
        </div>
      </ScrollArea>
    </div>
  );
}
