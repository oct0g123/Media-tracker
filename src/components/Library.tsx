import { useMemo, useState } from 'react';
import { Search, SlidersHorizontal, LayoutGrid, List, ArrowUpDown, Plus } from 'lucide-react';
import type { FilterState, SortState, MediaItem, SortField } from '../types';
import { MEDIA_TYPE_META } from '../types';
import MediaCard from './MediaCard';
import MediaRow from './MediaRow';
import FilterPanel from './FilterPanel';

interface Props {
  items: MediaItem[];
  onEdit: (item: MediaItem) => void;
  onDelete: (id: string) => void;
  onToggleFavorite: (id: string) => void;
  onStatusChange: (id: string, status: MediaItem['status']) => void;
  onAdd: () => void;
}

const SORT_OPTIONS: Array<{ value: SortField; label: string }> = [
  { value: 'dateAdded', label: 'Date Added' },
  { value: 'title', label: 'Title' },
  { value: 'rating', label: 'Rating' },
  { value: 'dateCompleted', label: 'Date Completed' },
  { value: 'type', label: 'Type' },
  { value: 'status', label: 'Status' },
];

const DEFAULT_FILTER: FilterState = {
  search: '',
  types: [],
  statuses: [],
  tags: [],
  favoritesOnly: false,
  minRating: 0,
};

const STATUS_ORDER: Record<string, number> = { in_progress: 0, backlog: 1, on_hold: 2, completed: 3, dropped: 4 };

export default function Library({ items, onEdit, onDelete, onToggleFavorite, onStatusChange, onAdd }: Props) {
  const [filter, setFilter] = useState<FilterState>(DEFAULT_FILTER);
  const [sort, setSort] = useState<SortState>({ field: 'dateAdded', dir: 'desc' });
  const [displayMode, setDisplayMode] = useState<'grid' | 'list'>('grid');
  const [showFilters, setShowFilters] = useState(false);

  const allTags = useMemo(() => {
    const set = new Set<string>();
    items.forEach(i => i.tags.forEach(t => set.add(t)));
    return [...set].sort();
  }, [items]);

  const filtered = useMemo(() => {
    let result = items;

    if (filter.search) {
      const q = filter.search.toLowerCase();
      result = result.filter(i =>
        i.title.toLowerCase().includes(q) ||
        i.creator.toLowerCase().includes(q) ||
        i.genre.toLowerCase().includes(q) ||
        i.notes.toLowerCase().includes(q) ||
        i.tags.some(t => t.includes(q))
      );
    }

    if (filter.types.length > 0) {
      result = result.filter(i => filter.types.includes(i.type));
    }

    if (filter.statuses.length > 0) {
      result = result.filter(i => filter.statuses.includes(i.status));
    }

    if (filter.favoritesOnly) {
      result = result.filter(i => i.isFavorite);
    }

    if (filter.minRating > 0) {
      result = result.filter(i => i.rating !== null && i.rating >= filter.minRating);
    }

    if (filter.tags.length > 0) {
      result = result.filter(i => filter.tags.every(t => i.tags.includes(t)));
    }

    // Sort
    result = [...result].sort((a, b) => {
      let cmp = 0;
      switch (sort.field) {
        case 'title':
          cmp = a.title.localeCompare(b.title);
          break;
        case 'rating':
          cmp = (b.rating ?? -1) - (a.rating ?? -1);
          break;
        case 'dateAdded':
          cmp = (b.dateAdded ?? '').localeCompare(a.dateAdded ?? '');
          break;
        case 'dateCompleted':
          cmp = (b.dateCompleted ?? '').localeCompare(a.dateCompleted ?? '');
          break;
        case 'type':
          cmp = a.type.localeCompare(b.type);
          break;
        case 'status':
          cmp = (STATUS_ORDER[a.status] ?? 99) - (STATUS_ORDER[b.status] ?? 99);
          break;
      }
      return sort.dir === 'asc' ? -cmp : cmp;
    });

    return result;
  }, [items, filter, sort]);

  const toggleSort = (field: SortField) => {
    setSort(s => s.field === field
      ? { field, dir: s.dir === 'asc' ? 'desc' : 'asc' }
      : { field, dir: field === 'title' ? 'asc' : 'desc' }
    );
  };

  const activeFilterCount = filter.types.length + filter.statuses.length + filter.tags.length +
    (filter.favoritesOnly ? 1 : 0) + (filter.minRating > 0 ? 1 : 0);

  return (
    <div className="space-y-4">
      {/* Toolbar */}
      <div className="flex items-center gap-3 flex-wrap">
        {/* Search */}
        <div className="relative flex-1 min-w-48">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <input
            value={filter.search}
            onChange={e => setFilter(f => ({ ...f, search: e.target.value }))}
            placeholder="Search by title, creator, tag..."
            className="w-full pl-9 pr-4 py-2.5 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl text-sm text-gray-900 dark:text-gray-100 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-brand-500"
          />
        </div>

        {/* Filter toggle */}
        <button
          onClick={() => setShowFilters(v => !v)}
          className={`flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-medium border transition-all ${
            showFilters || activeFilterCount > 0
              ? 'bg-brand-50 dark:bg-brand-900/20 border-brand-300 dark:border-brand-700 text-brand-700 dark:text-brand-300'
              : 'bg-white dark:bg-gray-800 border-gray-200 dark:border-gray-700 text-gray-600 dark:text-gray-400 hover:border-gray-300'
          }`}
        >
          <SlidersHorizontal size={16} />
          Filters
          {activeFilterCount > 0 && (
            <span className="bg-brand-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center leading-none">
              {activeFilterCount}
            </span>
          )}
        </button>

        {/* Sort */}
        <div className="flex items-center gap-1 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl px-1 py-1">
          <ArrowUpDown size={14} className="text-gray-400 ml-2" />
          <select
            value={sort.field}
            onChange={e => toggleSort(e.target.value as SortField)}
            className="text-sm text-gray-700 dark:text-gray-200 bg-transparent border-none focus:outline-none pr-2 py-1 cursor-pointer"
          >
            {SORT_OPTIONS.map(o => (
              <option key={o.value} value={o.value}>{o.label}</option>
            ))}
          </select>
          <button
            onClick={() => setSort(s => ({ ...s, dir: s.dir === 'asc' ? 'desc' : 'asc' }))}
            className="px-2 py-1 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 text-xs font-medium"
          >
            {sort.dir === 'asc' ? '↑' : '↓'}
          </button>
        </div>

        {/* Display mode */}
        <div className="flex items-center bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl p-1">
          <button
            onClick={() => setDisplayMode('grid')}
            className={`p-1.5 rounded-lg transition-colors ${displayMode === 'grid' ? 'bg-brand-100 dark:bg-brand-900/40 text-brand-600 dark:text-brand-400' : 'text-gray-400 hover:text-gray-600'}`}
          >
            <LayoutGrid size={16} />
          </button>
          <button
            onClick={() => setDisplayMode('list')}
            className={`p-1.5 rounded-lg transition-colors ${displayMode === 'list' ? 'bg-brand-100 dark:bg-brand-900/40 text-brand-600 dark:text-brand-400' : 'text-gray-400 hover:text-gray-600'}`}
          >
            <List size={16} />
          </button>
        </div>

        {/* Add button */}
        <button
          onClick={onAdd}
          className="flex items-center gap-2 px-4 py-2.5 bg-brand-600 hover:bg-brand-700 text-white rounded-xl text-sm font-medium transition-colors shadow-sm"
        >
          <Plus size={16} />
          Add
        </button>
      </div>

      {/* Quick type tabs */}
      <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-thin">
        <button
          onClick={() => setFilter(f => ({ ...f, types: [] }))}
          className={`flex-shrink-0 px-3 py-1.5 rounded-full text-sm font-medium transition-all ${
            filter.types.length === 0
              ? 'bg-gray-900 dark:bg-gray-100 text-white dark:text-gray-900'
              : 'bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 text-gray-600 dark:text-gray-400 hover:border-gray-300'
          }`}
        >
          All ({items.length})
        </button>
        {(Object.keys(MEDIA_TYPE_META) as Array<keyof typeof MEDIA_TYPE_META>).map(t => {
          const count = items.filter(i => i.type === t).length;
          if (count === 0) return null;
          const meta = MEDIA_TYPE_META[t];
          const active = filter.types.length === 1 && filter.types[0] === t;
          return (
            <button
              key={t}
              onClick={() => setFilter(f => ({ ...f, types: active ? [] : [t] }))}
              className={`flex-shrink-0 flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-medium transition-all ${
                active
                  ? 'bg-gray-900 dark:bg-gray-100 text-white dark:text-gray-900'
                  : 'bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 text-gray-600 dark:text-gray-400 hover:border-gray-300'
              }`}
            >
              <span>{meta.icon}</span>
              {meta.label} ({count})
            </button>
          );
        })}
      </div>

      {/* Filter panel */}
      {showFilters && (
        <FilterPanel
          filter={filter}
          onChange={setFilter}
          availableTags={allTags}
          onClose={() => setShowFilters(false)}
        />
      )}

      {/* Results count */}
      <div className="text-sm text-gray-500 dark:text-gray-400">
        {filtered.length === items.length
          ? `${items.length} entries`
          : `${filtered.length} of ${items.length} entries`}
      </div>

      {/* Empty state */}
      {filtered.length === 0 && (
        <div className="flex flex-col items-center justify-center py-20 text-center">
          <div className="text-5xl mb-4">🔍</div>
          <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-1">No entries found</h3>
          <p className="text-gray-500 dark:text-gray-400 text-sm">
            {items.length === 0 ? 'Add your first entry to get started.' : 'Try adjusting your filters or search.'}
          </p>
          {items.length === 0 && (
            <button
              onClick={onAdd}
              className="mt-4 flex items-center gap-2 px-5 py-2.5 bg-brand-600 hover:bg-brand-700 text-white rounded-xl text-sm font-medium transition-colors"
            >
              <Plus size={16} /> Add First Entry
            </button>
          )}
        </div>
      )}

      {/* Grid mode */}
      {displayMode === 'grid' && filtered.length > 0 && (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-4">
          {filtered.map(item => (
            <MediaCard
              key={item.id}
              item={item}
              onEdit={onEdit}
              onDelete={onDelete}
              onToggleFavorite={onToggleFavorite}
              onStatusChange={onStatusChange}
            />
          ))}
        </div>
      )}

      {/* List mode */}
      {displayMode === 'list' && filtered.length > 0 && (
        <div className="space-y-2">
          {filtered.map(item => (
            <MediaRow
              key={item.id}
              item={item}
              onEdit={onEdit}
              onDelete={onDelete}
              onToggleFavorite={onToggleFavorite}
              onStatusChange={onStatusChange}
            />
          ))}
        </div>
      )}
    </div>
  );
}
