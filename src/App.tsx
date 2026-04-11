import { useState, useCallback } from 'react';
import { Plus, LayoutDashboard, Library as LibraryIcon, Moon, Sun, Trash2 } from 'lucide-react';
import { useMediaStore } from './store';
import type { MediaItem, View } from './types';
import Dashboard from './components/Dashboard';
import Library from './components/Library';
import MediaModal from './components/MediaModal';

function useDarkMode() {
  const [dark, setDark] = useState(() => {
    if (typeof window === 'undefined') return false;
    const stored = localStorage.getItem('theme');
    if (stored) return stored === 'dark';
    return window.matchMedia('(prefers-color-scheme: dark)').matches;
  });

  const toggle = useCallback(() => {
    setDark(d => {
      const next = !d;
      document.documentElement.classList.toggle('dark', next);
      localStorage.setItem('theme', next ? 'dark' : 'light');
      return next;
    });
  }, []);

  // Apply on mount
  useState(() => {
    document.documentElement.classList.toggle('dark', dark);
  });

  return { dark, toggle };
}

export default function App() {
  const { items, addItem, updateItem, deleteItem, toggleFavorite } = useMediaStore();
  const [view, setView] = useState<View>('dashboard');
  const [modalItem, setModalItem] = useState<MediaItem | null | undefined>(undefined); // undefined = closed
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);
  const { dark, toggle: toggleDark } = useDarkMode();

  const openAdd = () => setModalItem(null);
  const openEdit = (item: MediaItem) => setModalItem(item);
  const closeModal = () => setModalItem(undefined);

  const handleSave = useCallback((data: Omit<MediaItem, 'id' | 'dateAdded'>) => {
    if (modalItem) {
      updateItem(modalItem.id, data);
    } else {
      addItem(data);
    }
    closeModal();
  }, [modalItem, addItem, updateItem]);

  const handleDelete = (id: string) => {
    setDeleteConfirm(id);
  };

  const confirmDelete = () => {
    if (deleteConfirm) {
      deleteItem(deleteConfirm);
      setDeleteConfirm(null);
    }
  };

  const handleStatusChange = useCallback((id: string, status: MediaItem['status']) => {
    const now = new Date().toISOString();
    const item = items.find(i => i.id === id);
    if (!item) return;
    const updates: Partial<MediaItem> = { status };
    if (status === 'in_progress' && !item.dateStarted) updates.dateStarted = now;
    if (status === 'completed' && !item.dateCompleted) updates.dateCompleted = now;
    updateItem(id, updates);
  }, [items, updateItem]);

  // Dashboard item click opens edit modal
  const handleDashboardItemClick = (item: MediaItem) => {
    openEdit(item);
    setView('library');
  };

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-950 text-gray-900 dark:text-gray-100">
      {/* Header */}
      <header className="sticky top-0 z-40 bg-white/80 dark:bg-gray-900/80 backdrop-blur-md border-b border-gray-200 dark:border-gray-800">
        <div className="max-w-screen-xl mx-auto px-4 sm:px-6 py-3 flex items-center gap-4">
          {/* Logo */}
          <div className="flex items-center gap-2.5 flex-shrink-0">
            <div className="w-8 h-8 bg-brand-600 rounded-lg flex items-center justify-center text-white font-bold text-sm">M</div>
            <span className="font-bold text-gray-900 dark:text-gray-100 text-lg hidden sm:block">MediaTracker</span>
          </div>

          {/* Nav */}
          <nav className="flex items-center gap-1 mx-4">
            <button
              onClick={() => setView('dashboard')}
              className={`flex items-center gap-2 px-3 py-2 rounded-xl text-sm font-medium transition-colors ${
                view === 'dashboard'
                  ? 'bg-gray-100 dark:bg-gray-800 text-gray-900 dark:text-gray-100'
                  : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 hover:bg-gray-50 dark:hover:bg-gray-800/50'
              }`}
            >
              <LayoutDashboard size={16} /> Dashboard
            </button>
            <button
              onClick={() => setView('library')}
              className={`flex items-center gap-2 px-3 py-2 rounded-xl text-sm font-medium transition-colors ${
                view === 'library'
                  ? 'bg-gray-100 dark:bg-gray-800 text-gray-900 dark:text-gray-100'
                  : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 hover:bg-gray-50 dark:hover:bg-gray-800/50'
              }`}
            >
              <LibraryIcon size={16} /> Library
              <span className="bg-gray-200 dark:bg-gray-700 text-gray-600 dark:text-gray-300 text-xs rounded-full px-1.5 py-0.5 leading-none">
                {items.length}
              </span>
            </button>
          </nav>

          <div className="flex-1" />

          {/* Dark mode + Add */}
          <button
            onClick={toggleDark}
            className="p-2 rounded-xl text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
          >
            {dark ? <Sun size={18} /> : <Moon size={18} />}
          </button>
          <button
            onClick={openAdd}
            className="flex items-center gap-2 px-4 py-2 bg-brand-600 hover:bg-brand-700 text-white rounded-xl text-sm font-medium transition-colors shadow-sm"
          >
            <Plus size={16} />
            <span className="hidden sm:inline">Add Entry</span>
          </button>
        </div>
      </header>

      {/* Main */}
      <main className="max-w-screen-xl mx-auto px-4 sm:px-6 py-6">
        {view === 'dashboard' && (
          <Dashboard items={items} onItemClick={handleDashboardItemClick} />
        )}
        {view === 'library' && (
          <Library
            items={items}
            onEdit={openEdit}
            onDelete={handleDelete}
            onToggleFavorite={toggleFavorite}
            onStatusChange={handleStatusChange}
            onAdd={openAdd}
          />
        )}
      </main>

      {/* Add/Edit Modal */}
      {modalItem !== undefined && (
        <MediaModal
          item={modalItem}
          onSave={handleSave}
          onClose={closeModal}
        />
      )}

      {/* Delete confirm dialog */}
      {deleteConfirm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-200 dark:border-gray-700 p-6 w-full max-w-sm shadow-2xl">
            <div className="flex items-center gap-3 mb-3">
              <div className="w-10 h-10 bg-red-100 dark:bg-red-900/30 rounded-xl flex items-center justify-center text-red-600 dark:text-red-400">
                <Trash2 size={20} />
              </div>
              <h3 className="font-bold text-gray-900 dark:text-gray-100">Delete Entry</h3>
            </div>
            <p className="text-sm text-gray-600 dark:text-gray-400 mb-5">
              Are you sure you want to delete "
              <strong>{items.find(i => i.id === deleteConfirm)?.title}</strong>"?
              This action cannot be undone.
            </p>
            <div className="flex gap-3">
              <button
                onClick={() => setDeleteConfirm(null)}
                className="flex-1 px-4 py-2.5 rounded-xl text-sm font-medium border border-gray-200 dark:border-gray-700 text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={confirmDelete}
                className="flex-1 px-4 py-2.5 rounded-xl text-sm font-medium bg-red-600 hover:bg-red-700 text-white transition-colors"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
