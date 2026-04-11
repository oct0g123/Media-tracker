import { Star } from 'lucide-react';

interface Props {
  value: number | null;
  onChange?: (v: number | null) => void;
  size?: 'sm' | 'md';
  readonly?: boolean;
}

export default function StarRating({ value, onChange, size = 'md', readonly = false }: Props) {
  const sz = size === 'sm' ? 14 : 18;

  return (
    <div className="flex items-center gap-0.5">
      {[1, 2, 3, 4, 5].map(n => (
        <button
          key={n}
          type="button"
          disabled={readonly}
          onClick={() => onChange?.(value === n ? null : n)}
          className={readonly ? 'cursor-default' : 'cursor-pointer hover:scale-110 transition-transform'}
        >
          <Star
            size={sz}
            className={
              value !== null && n <= value
                ? 'fill-amber-400 text-amber-400'
                : 'text-gray-300 dark:text-gray-600'
            }
          />
        </button>
      ))}
    </div>
  );
}
