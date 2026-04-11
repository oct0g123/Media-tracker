import { Heart, Edit2, Trash2, BookOpen, MoreVertical, RefreshCw } from 'lucide-react';
import { useState, useRef, useEffect } from 'react';
import type { MediaItem } from '../types';
import { MEDIA_TYPE_META } from '../types';
import { TypeBadge, StatusBadge } from './Badge';
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

export default function MediaCard({ item, onEdit, onDelete, onToggleFavorite, onStatusChange }: Props) {
  const [menuOpen, setMenuOpen] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);
  const meta = MEDIA_TYPE_META[item.type];

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) {
        setMenuOpen(false);
      }
    };
    if (menuOpen) document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, [menuOpen]);

  return (
    <div className="group relative bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700 shadow-sm hover:shadow-md transition-all duration-200 overflow-hidden flex flex-col">
      {/* Cover / Color Banner */}
      <div className="relative h-36 flex-shrink-0 overflow-hidden">
        {item.coverUrl ? (
          <img src={item.coverUrl} alt={item.title} className="w-full h-full object-cover" />
        ) : (
          <div className={`w-full h-full flex items-center justify-center text-6xl bg-gradient-to-br from-gray-100 to-gray-200 dark:from-gray-700 dark:to-gray-800`}>
            {meta.icon}
          </div>
        )}
        {/* Favorite button */}
        <button
          onClick={() => onToggleFavorite(item.id)}
          className={`absolute top-2 right-2 p-1.5 rounded-full backdrop-blur-sm transition-all ${
            item.isFavorite
              ? 'bg-red-500 text-white'
              : 'bg-white/70 text-gray-400 opacity-0 group-hover:opacity-100'
          }`}
        >
          <Heart size={14} className={item.isFavorite ? 'fill-white' : ''} />
        </button>
        {/* Play count badge */}
        {item.playCount > 1 && (
          <div className="absolute bottom-2 left-2 flex items-center gap-1 bg-black/60 text-white text-xs px-2 py-0.5 rounded-full">
            <RefreshCw size={10} />
            <span>×{item.playCount}</span>
          </div>
        )}
      </div>

      {/* Content */}
      <div className="p-4 flex flex-col gap-2 flex-1">
        <div className="flex items-start justify-between gap-2">
          <div className="flex-1 min-w-0">
            <h3 className="font-semibold text-gray-900 dark:text-gray-100 text-sm leading-tight line-clamp-2 mb-0.5">
              {item.title}
            </h3>
            {item.creator && (
              <p className="text-xs text-gray-500 dark:text-gray-400 truncate">{item.creator}</p>
            )}
          </div>
          {/* Menu */}
          <div className="relative flex-shrink-0" ref={menuRef}>
            <button
              onClick={() => setMenuOpen(v => !v)}
              className="p-1 rounded-lg text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
            >
              <MoreVertical size={16} />
            </button>
            {menuOpen && (
              <div className="absolute right-0 top-7 z-50 w-36 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-600 rounded-xl shadow-lg py-1 text-sm">
                <button
                  onClick={() => { onEdit(item); setMenuOpen(false); }}
                  className="flex items-center gap-2 w-full px-3 py-2 text-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-gray-700"
                >
                  <Edit2 size={14} /> Edit
                </button>
                <button
                  onClick={() => { onDelete(item.id); setMenuOpen(false); }}
                  className="flex items-center gap-2 w-full px-3 py-2 text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20"
                >
                  <Trash2 size={14} /> Delete
                </button>
              </div>
            )}
          </div>
        </div>

        {/* Badges */}
        <div className="flex flex-wrap gap-1.5">
          <TypeBadge type={item.type} size="sm" />
          <StatusBadge status={item.status} />
        </div>

        {/* Rating */}
        {item.rating !== null && (
          <StarRating value={item.rating} readonly size="sm" />
        )}

        {/* Progress */}
        {item.progress && (
          <div className="flex items-center gap-1.5 text-xs text-gray-500 dark:text-gray-400">
            <BookOpen size={12} />
            <span>{item.progress}{item.totalLength ? ` / ${item.totalLength}` : ''}</span>
          </div>
        )}

        {/* Tags */}
        {item.tags.length > 0 && (
          <div className="flex flex-wrap gap-1 mt-auto pt-1">
            {item.tags.slice(0, 3).map(tag => (
              <span key={tag} className="text-xs px-1.5 py-0.5 bg-gray-100 dark:bg-gray-700 text-gray-500 dark:text-gray-400 rounded-md">
                #{tag}
              </span>
            ))}
            {item.tags.length > 3 && (
              <span className="text-xs text-gray-400">+{item.tags.length - 3}</span>
            )}
          </div>
        )}

        {/* Quick status change */}
        <div className="mt-2 pt-2 border-t border-gray-100 dark:border-gray-700">
          <select
            value={item.status}
            onChange={e => onStatusChange(item.id, e.target.value as MediaItem['status'])}
            className="w-full text-xs bg-gray-50 dark:bg-gray-700/50 border border-gray-200 dark:border-gray-600 rounded-lg px-2 py-1.5 text-gray-700 dark:text-gray-200 cursor-pointer focus:outline-none focus:ring-2 focus:ring-brand-500"
          >
            {STATUS_OPTIONS.map(o => (
              <option key={o.value} value={o.value}>{o.label}</option>
            ))}
          </select>
        </div>
      </div>
    </div>
  );
}
