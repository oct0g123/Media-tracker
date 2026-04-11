import type { MediaType, MediaStatus } from '../types';
import { MEDIA_TYPE_META, STATUS_META } from '../types';

interface TypeBadgeProps {
  type: MediaType;
  size?: 'sm' | 'md';
}

export function TypeBadge({ type, size = 'md' }: TypeBadgeProps) {
  const meta = MEDIA_TYPE_META[type];
  const textSize = size === 'sm' ? 'text-xs' : 'text-xs';
  return (
    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full font-medium ${textSize} ${meta.color} ${meta.colorDark}`}>
      <span>{meta.icon}</span>
      <span>{meta.label}</span>
    </span>
  );
}

interface StatusBadgeProps {
  status: MediaStatus;
  size?: 'sm' | 'md';
}

export function StatusBadge({ status }: StatusBadgeProps) {
  const meta = STATUS_META[status];
  return (
    <span className={`inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-xs font-medium ${meta.color}`}>
      <span className={`w-1.5 h-1.5 rounded-full ${meta.dot}`} />
      {meta.label}
    </span>
  );
}
