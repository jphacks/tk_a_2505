const ExternalLinkIcon = () => (
  <svg
    className="h-3.5 w-3.5"
    fill="none"
    stroke="currentColor"
    viewBox="0 0 24 24"
  >
    <path
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth={2}
      d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"
    />
  </svg>
);

type Link = {
  label: string;
  url: string;
};

type DataSourceCardProps = {
  icon: string;
  title: string;
  description: string;
  links: Link[];
};

export function DataSourceCard({
  icon,
  title,
  description,
  links,
}: DataSourceCardProps) {
  return (
    <div className="rounded-xl border border-zinc-200 bg-linear-to-br from-zinc-50 to-white p-6 dark:border-zinc-800 dark:from-zinc-900 dark:to-zinc-950">
      <div className="mb-4 flex items-center gap-3">
        <span className="text-2xl">{icon}</span>
        <h3 className="text-lg font-semibold text-zinc-900 dark:text-white">
          {title}
        </h3>
      </div>
      <p className="mb-4 text-sm leading-relaxed text-zinc-600 dark:text-zinc-300">
        {description}
      </p>
      <div className="flex flex-wrap gap-3">
        {links.map((link, index) => (
          <a
            key={index}
            href={link.url}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 text-sm font-medium text-orange-600 transition-colors hover:text-orange-700 dark:text-orange-400 dark:hover:text-orange-300"
          >
            {link.label}
            <ExternalLinkIcon />
          </a>
        ))}
      </div>
    </div>
  );
}
