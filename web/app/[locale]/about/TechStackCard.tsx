type TechStackCardProps = {
  title: string;
  description: string;
};

export function TechStackCard({ title, description }: TechStackCardProps) {
  return (
    <div className="rounded-xl border border-zinc-200 bg-white p-6 transition-all hover:border-zinc-300 dark:border-zinc-800 dark:bg-zinc-900 dark:hover:border-zinc-700">
      <h3 className="mb-3 text-lg font-semibold text-zinc-900 dark:text-white">
        {title}
      </h3>
      <p className="text-sm leading-relaxed text-zinc-600 dark:text-zinc-300">
        {description}
      </p>
    </div>
  );
}
