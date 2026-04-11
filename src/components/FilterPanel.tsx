import { X } from 'lucide-react';
import type { FilterState, MediaType, MediaStatus } from '../types';
import { MEDIA_TYPE_META, STATUS_META } from '../types';

interface Props {
  filter: FilterState;
  onChange: (f: FilterState) => void;
  availableTags: string[];
  onClose: () => void;
}

export default function FilterPanel({ filter, onChange, availableTags, onClose }: Props) {
  const toggleType = (t: MediaType) => {
    onChange({
      ...filter,
      types: filter.types.includes(t) ? filter.types.filter(x => x !== t) : [...filter.types, t],
    });
  };

  const toggleStatus = (s: MediaStatus) => {
    onChange({
      ...filter,
      statuses: filter.statuses.includes(s) ? filter.statuses.filter(x => x !== s) : [...filter.statuses, s],
    });
  };

  const toggleTag = (t: string) => {
    onChange({
      ...filter,
      tags: filter.tags.includes(t) ? filter.tags.filter(x => x !== t) : [...filter.tags, t],
    });
  };

  const hasFilters = filter.types.length > 0 || filter.statuses.length > 0 || filter.tags.length > 0 || filter.favoritesOnly || filter.minRating > 0;

  return (
    <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700 p-5 shadow-sm space-y-5">
      <div className="flex items-center justify-between">
        <h3 className="font-semibold text-gray-900 dark:text-gray-100 text-sm">Filters</h3>
        <div className="flex gap-2">
          {hasFilters && (
            <button
              onClick={() => onChange({ search: filter.search, types: [], statuses: [], tags: [], favoritesOnly: false, minRating: 0 })}
              className="text-xs text-brand-600 dark:text-brand-400 hover:underline"
            >
              Clear all
            </button>
          )}
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-200">
            <X size={16} />
          </button>
        </div>
      </div>

      {/* Media Types */}
      <div>
        <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-2">Type</p>
        <div className="flex flex-wrap gap-2">
          {(Object.keys(MEDIA_TYPE_META) as MediaType[]).map(t => {
            const meta = MEDIA_TYPE_META[t];
            const active = filter.types.includes(t);
            return (
              <button
                key={t}
                onClick={() => toggleType(t)}
                className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium border transition-all ${
                  active
                    ? 'border-brand-500 bg-brand-50 dark:bg-brand-900/30 text-brand-700 dark:text-brand-300'
                    : 'border-gray-200 dark:border-gray-700 text-gray-600 dark:text-gray-400 hover:border-gray-300 dark:hover:border-gray-600'
                }`}
              >
                {meta.icon} {meta.label}
              </button>
            );
          })}
        </div>
      </div>

      {/* Status */}
      <div>
        <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-2">Status</p>
        <div className="flex flex-wrap gap-2">
          {(Object.keys(STATUS_META) as MediaStatus[]).map(s => {
            const meta = STATUS_META[s];
            const active = filter.statuses.includes(s);
            return (
              <button
                key={s}
                onClick={() => toggleStatus(s)}
                className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium border transition-all ${
                  active
                    ? 'border-brand-500 bg-brand-50 dark:bg-brand-900/30 text-brand-700 dark:text-brand-300'
                    : 'border-gray-200 dark:border-gray-700 text-gray-600 dark:text-gray-400 hover:border-gray-300 dark:hover:border-gray-600'
                }`}
              >
                <span className={`w-1.5 h-1.5 rounded-full ${meta.dot}`} />
                {meta.label}
              </button>
            );
          })}
        </div>
      </div>

      {/* Minimum Rating */}
      <div>
        <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-2">Min Rating</p>
        <div className="flex gap-2">
          {[0, 1, 2, 3, 4, 5].map(r => (
            <button
              key={r}
              onClick={() => onChange({ ...filter, minRating: r })}
              className={`w-8 h-8 rounded-lg text-xs font-semibold border transition-all ${
                filter.minRating === r
                  ? 'border-brand-500 bg-brand-50 dark:bg-brand-900/30 text-brand-700 dark:text-brand-300'
                  : 'border-gray-200 dark:border-gray-700 text-gray-600 dark:text-gray-400 hover:border-gray-300'
              }`}
            >
              {r === 0 ? 'All' : `${r}★`}
            </button>
          ))}
        </div>
      </div>

      {/* Favorites */}
      <label className="flex items-center gap-2 cursor-pointer">
        <input
          type="checkbox"
          checked={filter.favoritesOnly}
          onChange={e => onChange({ ...filter, favoritesOnly: e.target.checked })}
          className="w-4 h-4 rounded accent-brand-500"
        />
        <span className="text-sm text-gray-700 dark:text-gray-300">Favorites only ❤️</span>
      </label>

      {/* Tags */}
      {availableTags.length > 0 && (
        <div>
          <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-2">Tags</p>
          <div className="flex flex-wrap gap-1.5">
            {availableTags.map(tag => {
              const active = filter.tags.includes(tag);
              return (
                <button
                  key={tag}
                  onClick={() => toggleTag(tag)}
                  className={`px-2 py-0.5 rounded-full text-xs transition-all ${
                    active
                      ? 'bg-brand-500 text-white'
                      : 'bg-gray-100 dark:bg-gray-700 text-gray-500 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-600'
                  }`}
                >
                  #{tag}
                </button>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}
