import { useState, useCallback } from 'react';
import type { MediaItem, MediaType, MediaStatus } from './types';

const STORAGE_KEY = 'mediatracker_items';

function loadItems(): MediaItem[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return getSampleData();
    return JSON.parse(raw) as MediaItem[];
  } catch {
    return getSampleData();
  }
}

function saveItems(items: MediaItem[]) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(items));
}

function generateId(): string {
  return Date.now().toString(36) + Math.random().toString(36).slice(2);
}

export function useMediaStore() {
  const [items, setItems] = useState<MediaItem[]>(loadItems);

  const persist = useCallback((next: MediaItem[]) => {
    setItems(next);
    saveItems(next);
  }, []);

  const addItem = useCallback((data: Omit<MediaItem, 'id' | 'dateAdded'>) => {
    const item: MediaItem = {
      ...data,
      id: generateId(),
      dateAdded: new Date().toISOString(),
    };
    persist([item, ...items]);
    return item;
  }, [items, persist]);

  const updateItem = useCallback((id: string, data: Partial<MediaItem>) => {
    persist(items.map(i => i.id === id ? { ...i, ...data } : i));
  }, [items, persist]);

  const deleteItem = useCallback((id: string) => {
    persist(items.filter(i => i.id !== id));
  }, [items, persist]);

  const toggleFavorite = useCallback((id: string) => {
    persist(items.map(i => i.id === id ? { ...i, isFavorite: !i.isFavorite } : i));
  }, [items, persist]);

  return { items, addItem, updateItem, deleteItem, toggleFavorite };
}

function getSampleData(): MediaItem[] {
  const now = new Date().toISOString();
  const sample: Array<Omit<MediaItem, 'id' | 'dateAdded'>> = [
    {
      title: 'Dune',
      type: 'book' as MediaType,
      status: 'completed' as MediaStatus,
      rating: 5,
      notes: 'An absolute masterpiece of science fiction. The world-building is unparalleled.',
      genre: 'Science Fiction',
      creator: 'Frank Herbert',
      year: 1965,
      progress: 'Finished',
      totalLength: '688 pages',
      coverUrl: '',
      tags: ['classic', 'sci-fi', 'epic'],
      dateStarted: '2024-01-10T00:00:00.000Z',
      dateCompleted: '2024-02-01T00:00:00.000Z',
      isFavorite: true,
      playCount: 1,
    },
    {
      title: 'The Last of Us',
      type: 'game' as MediaType,
      status: 'completed' as MediaStatus,
      rating: 5,
      notes: 'Emotional story. One of the best narratives in gaming.',
      genre: 'Action-Adventure',
      creator: 'Naughty Dog',
      year: 2013,
      progress: '100%',
      totalLength: '~15 hours',
      coverUrl: '',
      tags: ['story-rich', 'survival', 'emotional'],
      dateStarted: '2024-03-01T00:00:00.000Z',
      dateCompleted: '2024-03-12T00:00:00.000Z',
      isFavorite: true,
      playCount: 1,
    },
    {
      title: 'Inception',
      type: 'movie' as MediaType,
      status: 'completed' as MediaStatus,
      rating: 4,
      notes: 'Mind-bending plot. Need to watch it again.',
      genre: 'Sci-Fi / Thriller',
      creator: 'Christopher Nolan',
      year: 2010,
      progress: 'Watched',
      totalLength: '148 min',
      coverUrl: '',
      tags: ['mind-bending', 'heist'],
      dateStarted: '2024-02-20T00:00:00.000Z',
      dateCompleted: '2024-02-20T00:00:00.000Z',
      isFavorite: false,
      playCount: 2,
    },
    {
      title: 'Breaking Bad',
      type: 'tv' as MediaType,
      status: 'completed' as MediaStatus,
      rating: 5,
      notes: 'Perfect start to finish. Best TV show ever made.',
      genre: 'Drama / Crime',
      creator: 'Vince Gilligan',
      year: 2008,
      progress: 'Finished',
      totalLength: '5 seasons',
      coverUrl: '',
      tags: ['drama', 'crime', 'must-watch'],
      dateStarted: '2024-01-01T00:00:00.000Z',
      dateCompleted: '2024-01-28T00:00:00.000Z',
      isFavorite: true,
      playCount: 1,
    },
    {
      title: 'Lex Fridman Podcast',
      type: 'podcast' as MediaType,
      status: 'in_progress' as MediaStatus,
      rating: 4,
      notes: 'Great long-form conversations with scientists, engineers, and thinkers.',
      genre: 'Technology / Science',
      creator: 'Lex Fridman',
      year: 2018,
      progress: 'Ep. 320 of 400+',
      totalLength: '400+ episodes',
      coverUrl: '',
      tags: ['tech', 'ai', 'science'],
      dateStarted: '2023-06-01T00:00:00.000Z',
      dateCompleted: null,
      isFavorite: false,
      playCount: 0,
    },
    {
      title: 'Hollow Knight',
      type: 'game' as MediaType,
      status: 'in_progress' as MediaStatus,
      rating: null,
      notes: 'Beautiful art direction. The combat is tight.',
      genre: 'Metroidvania',
      creator: 'Team Cherry',
      year: 2017,
      progress: '40%',
      totalLength: '~40 hours',
      coverUrl: '',
      tags: ['indie', 'metroidvania', 'difficult'],
      dateStarted: '2024-03-15T00:00:00.000Z',
      dateCompleted: null,
      isFavorite: false,
      playCount: 0,
    },
    {
      title: 'Neuromancer',
      type: 'book' as MediaType,
      status: 'backlog' as MediaStatus,
      rating: null,
      notes: 'The original cyberpunk novel. Want to read before watching the adaptation.',
      genre: 'Cyberpunk',
      creator: 'William Gibson',
      year: 1984,
      progress: '',
      totalLength: '271 pages',
      coverUrl: '',
      tags: ['cyberpunk', 'classic'],
      dateStarted: null,
      dateCompleted: null,
      isFavorite: false,
      playCount: 0,
    },
    {
      title: 'Attack on Titan',
      type: 'anime' as MediaType,
      status: 'completed' as MediaStatus,
      rating: 5,
      notes: 'One of the greatest anime ever made. The ending was divisive but I loved it.',
      genre: 'Action / Dark Fantasy',
      creator: 'MAPPA / Wit Studio',
      year: 2013,
      progress: 'Finished',
      totalLength: '87 episodes',
      coverUrl: '',
      tags: ['action', 'dark', 'epic'],
      dateStarted: '2023-12-01T00:00:00.000Z',
      dateCompleted: '2024-01-15T00:00:00.000Z',
      isFavorite: true,
      playCount: 1,
    },
  ];

  return sample.map(s => ({ ...s, id: generateId(), dateAdded: now }));
}
