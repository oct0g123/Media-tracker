import { Heart, Edit2, Trash2, RefreshCw } from 'lucide-react';
import type { MediaItem } from '../types';
import { MEDIA_TYPE_META } from '../types';
import { TypeBadge } from './Badge';
import StarRating from './StarRating';

interface Props {
  item: MediaItem;
  onEdit: (item: MediaItem) => void;
  onDelete: (id: string) => void;
  onToggleFavorite: (id: string) => void;
  onStatusChange: (id: string, status: MediaItem['status']) => void;
}

const STATUS_OPTIONS: Array<{ value: MediaItem['status']; label: string }> = [
  { value: 'backlog', label: 'Backlog' },
  { value: 'in_progress', label: 'In Progress' },
  { value: 'completed', label: 'Completed' },
  { value: 'on_hold', label: 'On Hold' },
  { value: 'dropped', label: 'Dropped' },
];

export default function MediaRow({ item, onEdit, onDelete, onToggleFavorite, onStatusChange }: Props) {
  const meta = MEDIA_TYPE_META[item.type];
  return (
    <div className="group flex items-center gap-4 px-4 py-3 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl hover:shadow-sm transition-all duration-150">
      {/* Icon / cover */}
      <div className="flex-shrink-0 w-10 h-10 rounded-lg bg-gray-100 dark:bg-gray-700 flex items-center justify-center text-2xl overflow-hidden">
        {item.coverUrl ? (
          <img src={item.coverUrl} alt="" className="w-full h-full object-cover rounded-lg" />
        ) : (
          <span>{meta.icon}</span>
        )}
      </div>

      {/* Title + creator */}
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <span className="font-semibold text-gray-900 dark:text-gray-100 text-sm truncate">{item.title}</span>
          {item.isFavorite && <Heart size={12} className="fill-red-500 text-red-500 flex-shrink-0" />}
          {item.playCount > 1 && (
            <span className="flex items-center gap-0.5 text-xs text-gray-400">
              <RefreshCw size={10} />×{item.playCount}
            </span>
          )}
        </div>
        <div className="flex items-center gap-2 mt-0.5 flex-wrap">
          {item.creator && <span className="text-xs text-gray-500 dark:text-gray-400">{item.creator}</span>}
          {item.year && <span className="text-xs text-gray-400">{item.year}</span>}
          {item.tags.slice(0, 2).map(tag => (
            <span key={tag} className="text-xs px-1.5 py-0.5 bg-gray-100 dark:bg-gray-700 text-gray-400 rounded">#{tag}</span>
          ))}
        </div>
      </div>

      {/* Type badge */}
      <div className="hidden sm:block flex-shrink-0">
        <TypeBadge type={item.type} size="sm" />
      </div>

      {/* Progress */}
      {item.progress && (
        <div className="hidden md:block flex-shrink-0 text-xs text-gray-500 dark:text-gray-400 max-w-[100px] truncate">
          {item.progress}
        </div>
      )}

      {/* Status dropdown */}
      <div className="flex-shrink-0">
        <select
          value={item.status}
          onChange={e => onStatusChange(item.id, e.target.value as MediaItem['status'])}
          className="text-xs bg-transparent border border-gray-200 dark:border-gray-600 rounded-lg px-2 py-1 text-gray-600 dark:text-gray-300 cursor-pointer focus:outline-none focus:ring-2 focus:ring-brand-500"
        >
          {STATUS_OPTIONS.map(o => (
            <option key={o.value} value={o.value}>{o.label}</option>
          ))}
        </select>
      </div>

      {/* Rating */}
      <div className="hidden lg:block flex-shrink-0">
        <StarRating value={item.rating} readonly size="sm" />
      </div>

      {/* Actions */}
      <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity flex-shrink-0">
        <button
          onClick={() => onToggleFavorite(item.id)}
          className={`p-1.5 rounded-lg transition-colors ${item.isFavorite ? 'text-red-500' : 'text-gray-400 hover:text-red-400'}`}
        >
          <Heart size={14} className={item.isFavorite ? 'fill-red-500' : ''} />
        </button>
        <button
          onClick={() => onEdit(item)}
          className="p-1.5 rounded-lg text-gray-400 hover:text-brand-600 hover:bg-brand-50 dark:hover:bg-brand-900/20 transition-colors"
        >
          <Edit2 size={14} />
        </button>
        <button
          onClick={() => onDelete(item.id)}
          className="p-1.5 rounded-lg text-gray-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors"
        >
          <Trash2 size={14} />
        </button>
      </div>
    </div>
  );
}
