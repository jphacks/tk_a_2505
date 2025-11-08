import { LucideIcon } from "lucide-react";

type FeatureCardProps = {
  icon: LucideIcon;
  title: string;
  description: string;
};

export function FeatureCard({
  icon: Icon,
  title,
  description,
}: FeatureCardProps) {
  return (
    <div className="h-full w-full rounded-lg border border-zinc-200 bg-zinc-50 p-6 dark:border-zinc-800 dark:bg-zinc-950">
      <div className="mb-3 flex items-center gap-2">
        <Icon className="h-6 w-6 text-orange-500" />
        <h3 className="text-lg font-semibold text-zinc-900 dark:text-white">
          {title}
        </h3>
      </div>
      <p className="text-sm text-zinc-600 dark:text-zinc-400">{description}</p>
    </div>
  );
}
