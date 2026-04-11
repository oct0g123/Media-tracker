import { useMemo } from 'react';
import { TrendingUp, Star, Clock, CheckCircle, BookOpen, Heart } from 'lucide-react';
import type { MediaItem, MediaType } from '../types';
import { MEDIA_TYPE_META, STATUS_META } from '../types';
import { TypeBadge, StatusBadge } from './Badge';
import StarRating from './StarRating';

interface Props {
  items: MediaItem[];
  onItemClick: (item: MediaItem) => void;
}

export default function Dashboard({ items, onItemClick }: Props) {
  const stats = useMemo(() => {
    const completed = items.filter(i => i.status === 'completed');
    const inProgress = items.filter(i => i.status === 'in_progress');
    const backlog = items.filter(i => i.status === 'backlog');
    const favorites = items.filter(i => i.isFavorite);
    const rated = items.filter(i => i.rating !== null);
    const avgRating = rated.length > 0
      ? rated.reduce((sum, i) => sum + (i.rating ?? 0), 0) / rated.length
      : 0;

    const byType = Object.keys(MEDIA_TYPE_META).map(t => ({
      type: t as MediaType,
      count: items.filter(i => i.type === t).length,
      completed: items.filter(i => i.type === t && i.status === 'completed').length,
    })).filter(x => x.count > 0).sort((a, b) => b.count - a.count);

    // Recent completions
    const recentCompleted = [...completed]
      .sort((a, b) => (b.dateCompleted ?? '').localeCompare(a.dateCompleted ?? ''))
      .slice(0, 6);

    // Top rated
    const topRated = [...rated]
      .sort((a, b) => (b.rating ?? 0) - (a.rating ?? 0))
      .slice(0, 5);

    return { completed, inProgress, backlog, favorites, avgRating, byType, recentCompleted, topRated };
  }, [items]);

  const statCards = [
    { label: 'Total Entries', value: items.length, icon: BookOpen, color: 'text-brand-600 bg-brand-50 dark:bg-brand-900/20 dark:text-brand-400' },
    { label: 'Completed', value: stats.completed.length, icon: CheckCircle, color: 'text-green-600 bg-green-50 dark:bg-green-900/20 dark:text-green-400' },
    { label: 'In Progress', value: stats.inProgress.length, icon: Clock, color: 'text-blue-600 bg-blue-50 dark:bg-blue-900/20 dark:text-blue-400' },
    { label: 'Backlog', value: stats.backlog.length, icon: TrendingUp, color: 'text-gray-600 bg-gray-100 dark:bg-gray-800 dark:text-gray-400' },
    { label: 'Favorites', value: stats.favorites.length, icon: Heart, color: 'text-red-600 bg-red-50 dark:bg-red-900/20 dark:text-red-400' },
    { label: 'Avg Rating', value: stats.avgRating > 0 ? stats.avgRating.toFixed(1) : '—', icon: Star, color: 'text-amber-600 bg-amber-50 dark:bg-amber-900/20 dark:text-amber-400' },
  ];

  if (items.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-24 text-center">
        <div className="text-6xl mb-4">📚</div>
        <h2 className="text-2xl font-bold text-gray-900 dark:text-gray-100 mb-2">Your library is empty</h2>
        <p className="text-gray-500 dark:text-gray-400">Start by adding some movies, books, games, or podcasts!</p>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Stat cards */}
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4">
        {statCards.map(card => (
          <div key={card.label} className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700 p-4 flex flex-col gap-3">
            <div className={`w-9 h-9 rounded-xl flex items-center justify-center ${card.color}`}>
              <card.icon size={18} />
            </div>
            <div>
              <div className="text-2xl font-bold text-gray-900 dark:text-gray-100">{card.value}</div>
              <div className="text-xs text-gray-500 dark:text-gray-400">{card.label}</div>
            </div>
          </div>
        ))}
      </div>

      {/* By type breakdown */}
      <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700 p-6">
        <h3 className="font-bold text-gray-900 dark:text-gray-100 mb-4">Library Breakdown</h3>
        <div className="space-y-3">
          {stats.byType.map(({ type, count, completed }) => {
            const meta = MEDIA_TYPE_META[type];
            const pct = count > 0 ? Math.round((completed / count) * 100) : 0;
            return (
              <div key={type} className="flex items-center gap-3">
                <span className="text-xl w-7 flex-shrink-0">{meta.icon}</span>
                <span className="text-sm text-gray-700 dark:text-gray-300 w-24 flex-shrink-0">{meta.label}</span>
                <div className="flex-1 bg-gray-100 dark:bg-gray-700 rounded-full h-2">
                  <div
                    className="bg-brand-500 h-2 rounded-full transition-all"
                    style={{ width: `${(count / Math.max(...stats.byType.map(x => x.count))) * 100}%` }}
                  />
                </div>
                <span className="text-xs text-gray-500 dark:text-gray-400 w-12 text-right flex-shrink-0">{count} total</span>
                <span className="text-xs text-green-600 dark:text-green-400 w-14 text-right flex-shrink-0">{pct}% done</span>
              </div>
            );
          })}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Status breakdown */}
        <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700 p-6">
          <h3 className="font-bold text-gray-900 dark:text-gray-100 mb-4">By Status</h3>
          <div className="space-y-2">
            {(Object.keys(STATUS_META) as Array<keyof typeof STATUS_META>).map(s => {
              const count = items.filter(i => i.status === s).length;
              const pct = items.length > 0 ? Math.round((count / items.length) * 100) : 0;
              if (count === 0) return null;
              return (
                <div key={s} className="flex items-center justify-between">
                  <StatusBadge status={s} />
                  <div className="flex items-center gap-2 flex-1 mx-3">
                    <div className="flex-1 bg-gray-100 dark:bg-gray-700 rounded-full h-1.5">
                      <div className={`${STATUS_META[s].dot} h-1.5 rounded-full`} style={{ width: `${pct}%` }} />
                    </div>
                  </div>
                  <span className="text-sm font-medium text-gray-900 dark:text-gray-100 w-8 text-right">{count}</span>
                </div>
              );
            })}
          </div>
        </div>

        {/* Top rated */}
        {stats.topRated.length > 0 && (
          <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700 p-6">
            <h3 className="font-bold text-gray-900 dark:text-gray-100 mb-4">Top Rated</h3>
            <div className="space-y-3">
              {stats.topRated.map(item => (
                <button
                  key={item.id}
                  onClick={() => onItemClick(item)}
                  className="flex items-center gap-3 w-full text-left hover:bg-gray-50 dark:hover:bg-gray-700/50 rounded-xl p-2 -mx-2 transition-colors"
                >
                  <span className="text-xl">{MEDIA_TYPE_META[item.type].icon}</span>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-gray-900 dark:text-gray-100 truncate">{item.title}</p>
                    {item.creator && <p className="text-xs text-gray-400 truncate">{item.creator}</p>}
                  </div>
                  <StarRating value={item.rating} readonly size="sm" />
                </button>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Recent completions */}
      {stats.recentCompleted.length > 0 && (
        <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700 p-6">
          <h3 className="font-bold text-gray-900 dark:text-gray-100 mb-4">Recently Completed</h3>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
            {stats.recentCompleted.map(item => (
              <button
                key={item.id}
                onClick={() => onItemClick(item)}
                className="flex items-center gap-3 text-left bg-gray-50 dark:bg-gray-700/50 rounded-xl p-3 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
              >
                <span className="text-2xl">{MEDIA_TYPE_META[item.type].icon}</span>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-semibold text-gray-900 dark:text-gray-100 truncate">{item.title}</p>
                  <div className="flex items-center gap-2 mt-0.5">
                    <TypeBadge type={item.type} size="sm" />
                    {item.rating && <StarRating value={item.rating} readonly size="sm" />}
                  </div>
                  {item.dateCompleted && (
                    <p className="text-xs text-gray-400 mt-0.5">
                      {new Date(item.dateCompleted).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
                    </p>
                  )}
                </div>
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Currently in progress */}
      {stats.inProgress.length > 0 && (
        <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700 p-6">
          <h3 className="font-bold text-gray-900 dark:text-gray-100 mb-4">Currently Consuming</h3>
          <div className="space-y-2">
            {stats.inProgress.map(item => (
              <button
                key={item.id}
                onClick={() => onItemClick(item)}
                className="flex items-center gap-3 w-full text-left bg-blue-50 dark:bg-blue-900/20 rounded-xl p-3 hover:bg-blue-100 dark:hover:bg-blue-900/30 transition-colors"
              >
                <span className="text-2xl">{MEDIA_TYPE_META[item.type].icon}</span>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-semibold text-gray-900 dark:text-gray-100 truncate">{item.title}</p>
                  {item.creator && <p className="text-xs text-gray-400 truncate">{item.creator}</p>}
                </div>
                {item.progress && (
                  <span className="text-xs text-blue-600 dark:text-blue-300 flex-shrink-0">{item.progress}</span>
                )}
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
