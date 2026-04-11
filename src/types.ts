export type MediaType =
  | 'movie'
  | 'tv'
  | 'book'
  | 'podcast'
  | 'game'
  | 'music'
  | 'anime'
  | 'comic';

export type MediaStatus =
  | 'backlog'
  | 'in_progress'
  | 'completed'
  | 'dropped'
  | 'on_hold';

export type SortField = 'title' | 'dateAdded' | 'dateCompleted' | 'rating' | 'type' | 'status';
export type SortDir = 'asc' | 'desc';

export interface MediaItem {
  id: string;
  title: string;
  type: MediaType;
  status: MediaStatus;
  rating: number | null; // 1-5
  notes: string;
  genre: string;
  creator: string; // author / director / developer / artist
  year: number | null;
  progress: string; // free-form: "p. 142", "ep 5/24", "40%", etc.
  totalLength: string; // "350 pages", "24 episodes", "~20 hrs", etc.
  coverUrl: string;
  tags: string[];
  dateAdded: string; // ISO date string
  dateStarted: string | null;
  dateCompleted: string | null;
  isFavorite: boolean;
  playCount: number; // for music/podcasts re-listens, rewatches, re-reads
}

export interface FilterState {
  search: string;
  types: MediaType[];
  statuses: MediaStatus[];
  tags: string[];
  favoritesOnly: boolean;
  minRating: number;
}

export interface SortState {
  field: SortField;
  dir: SortDir;
}

export type View = 'dashboard' | 'library';
export type DisplayMode = 'grid' | 'list';

export const MEDIA_TYPE_META: Record<MediaType, { label: string; icon: string; color: string; colorDark: string; creatorLabel: string }> = {
  movie:   { label: 'Movie',      icon: '🎬', color: 'bg-red-100 text-red-700',     colorDark: 'dark:bg-red-900/30 dark:text-red-300',     creatorLabel: 'Director' },
  tv:      { label: 'TV Show',    icon: '📺', color: 'bg-blue-100 text-blue-700',   colorDark: 'dark:bg-blue-900/30 dark:text-blue-300',   creatorLabel: 'Creator' },
  book:    { label: 'Book',       icon: '📖', color: 'bg-amber-100 text-amber-700', colorDark: 'dark:bg-amber-900/30 dark:text-amber-300', creatorLabel: 'Author' },
  podcast: { label: 'Podcast',    icon: '🎙️', color: 'bg-purple-100 text-purple-700', colorDark: 'dark:bg-purple-900/30 dark:text-purple-300', creatorLabel: 'Host' },
  game:    { label: 'Video Game', icon: '🎮', color: 'bg-green-100 text-green-700', colorDark: 'dark:bg-green-900/30 dark:text-green-300', creatorLabel: 'Developer' },
  music:   { label: 'Music',      icon: '🎵', color: 'bg-pink-100 text-pink-700',   colorDark: 'dark:bg-pink-900/30 dark:text-pink-300',   creatorLabel: 'Artist' },
  anime:   { label: 'Anime',      icon: '✨', color: 'bg-cyan-100 text-cyan-700',   colorDark: 'dark:bg-cyan-900/30 dark:text-cyan-300',   creatorLabel: 'Studio' },
  comic:   { label: 'Comic/Manga',icon: '💬', color: 'bg-orange-100 text-orange-700', colorDark: 'dark:bg-orange-900/30 dark:text-orange-300', creatorLabel: 'Author' },
};

export const STATUS_META: Record<MediaStatus, { label: string; color: string; dot: string }> = {
  backlog:     { label: 'Backlog',      color: 'bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400',        dot: 'bg-gray-400' },
  in_progress: { label: 'In Progress',  color: 'bg-blue-100 text-blue-700 dark:bg-blue-900/40 dark:text-blue-300',     dot: 'bg-blue-500' },
  completed:   { label: 'Completed',    color: 'bg-green-100 text-green-700 dark:bg-green-900/40 dark:text-green-300', dot: 'bg-green-500' },
  dropped:     { label: 'Dropped',      color: 'bg-red-100 text-red-600 dark:bg-red-900/40 dark:text-red-400',         dot: 'bg-red-500' },
  on_hold:     { label: 'On Hold',      color: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/40 dark:text-yellow-300', dot: 'bg-yellow-500' },
};
