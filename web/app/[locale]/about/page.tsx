import { setRequestLocale, getTranslations } from "next-intl/server";

type Props = {
  params: Promise<{ locale: string }>;
};

type TeamMember = {
  initial: string;
  name: string;
  role: string;
  responsibility: string;
  githubUrl: string;
  githubUsername: string;
};

type DataSource = {
  icon: string;
  title: string;
  description: string;
  links: Array<{ label: string; url: string }>;
};

type TechStack = {
  title: string;
  description: string;
};

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

const GitHubIcon = () => (
  <svg className="h-3.5 w-3.5" fill="currentColor" viewBox="0 0 24 24">
    <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z" />
  </svg>
);

export default async function AboutPage({ params }: Props) {
  const { locale } = await params;
  setRequestLocale(locale);
  const t = await getTranslations("about");

  // Team members configuration
  const teamMembersConfig = [
    {
      initial: "W",
      githubUrl: "https://github.com/itzmeowww",
      githubUsername: "itzmeowww",
    },
    {
      initial: "M",
      githubUrl: "https://github.com/martgru",
      githubUsername: "martgru",
    },
    {
      initial: "R",
      githubUrl: "https://github.com/Riochin",
      githubUsername: "Riochin",
    },
    {
      initial: "J",
      githubUrl: "https://github.com/Cerealmaster0621",
      githubUsername: "Cerealmaster0621",
    },
    {
      initial: "J",
      githubUrl: "https://github.com/RedBlueBird",
      githubUsername: "RedBlueBird",
    },
  ];

  const teamMembers: TeamMember[] = teamMembersConfig.map((config, i) => ({
    initial: config.initial,
    name: t(`member${i + 1}Name`),
    role: t(`member${i + 1}Role`),
    responsibility: t(`member${i + 1}Responsibility`),
    githubUrl: config.githubUrl,
    githubUsername: config.githubUsername,
  }));

  // Data sources configuration
  const dataSourcesConfig = [
    {
      icon: "🏛️",
      links: [{ label: "visitWebsite", url: "https://www.gsi.go.jp/" }],
    },
    {
      icon: "🤖",
      links: [
        { label: "Gemini API", url: "https://ai.google.dev/gemini-api" },
        { label: "Flux.1", url: "https://blackforestlabs.ai/" },
      ],
    },
  ];

  const dataSources: DataSource[] = dataSourcesConfig.map((config, i) => ({
    icon: config.icon,
    title: t(`dataSource${i + 1}Title`),
    description: t(`dataSource${i + 1}Description`),
    links: config.links,
  }));

  // Tech stack - fully derived from translations
  const techStack: TechStack[] = [1, 2, 3].map((i) => ({
    title: t(`techStack${i}Title`),
    description: t(`techStack${i}Description`),
  }));

  return (
    <main className="min-h-screen bg-white dark:bg-zinc-950">
      {/* Header */}
      <section className="mx-auto max-w-4xl px-6 pb-16 pt-32 sm:px-8 sm:pt-36">
        <div className="text-center">
          <h1 className="text-4xl font-bold tracking-tight text-zinc-900 dark:text-white sm:text-5xl">
            {t("title")}
          </h1>
          <p className="mx-auto mt-6 max-w-2xl text-lg leading-relaxed text-zinc-600 dark:text-zinc-400">
            {t("subtitle")}
          </p>
        </div>
      </section>

      {/* Team Members */}
      <section className="border-t border-zinc-200 bg-linear-to-b from-zinc-50 to-white py-16 dark:border-zinc-800 dark:from-zinc-900 dark:to-zinc-950">
        <div className="mx-auto max-w-6xl px-6 sm:px-8">
          <div className="mb-12 text-center">
            <h2 className="text-3xl font-bold tracking-tight text-zinc-900 dark:text-white">
              {t("teamTitle")}
            </h2>
            <p className="mt-4 text-base text-zinc-600 dark:text-zinc-400">
              {t("teamSubtitle")}
            </p>
          </div>

          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {teamMembers.map((member, index) => (
              <div
                key={index}
                className="group rounded-xl border border-zinc-200 bg-white p-6 transition-all hover:border-zinc-300 dark:border-zinc-800 dark:bg-zinc-900 dark:hover:border-zinc-700"
              >
                <div className="mb-4 flex items-start gap-4">
                  <img
                    src={`https://github.com/${member.githubUsername}.png`}
                    alt={member.name}
                    className="h-12 w-12 shrink-0 rounded-full bg-zinc-100 dark:bg-zinc-800"
                  />
                  <div className="min-w-0 flex-1">
                    <h3 className="font-semibold text-zinc-900 dark:text-white">
                      {member.name}
                    </h3>
                    <p className="mt-1 text-sm text-zinc-500 dark:text-zinc-400">
                      {member.role}
                    </p>
                  </div>
                </div>
                <p className="mb-4 text-sm leading-relaxed text-zinc-600 dark:text-zinc-300">
                  {member.responsibility}
                </p>
                <a
                  href={member.githubUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 text-sm font-medium text-orange-600 transition-colors hover:text-orange-700 dark:text-orange-400 dark:hover:text-orange-300"
                >
                  <GitHubIcon />
                  GitHub
                </a>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Data Sources */}
      <section className="border-t border-zinc-200 bg-white py-16 dark:border-zinc-800 dark:bg-zinc-950">
        <div className="mx-auto max-w-5xl px-6 sm:px-8">
          <div className="mb-12 text-center">
            <h2 className="text-3xl font-bold tracking-tight text-zinc-900 dark:text-white">
              {t("dataSourcesTitle")}
            </h2>
            <p className="mt-4 text-base text-zinc-600 dark:text-zinc-400">
              {t("dataSourcesSubtitle")}
            </p>
          </div>

          <div className="grid gap-6 md:grid-cols-2">
            {dataSources.map((source, index) => (
              <div
                key={index}
                className="rounded-xl border border-zinc-200 bg-linear-to-br from-zinc-50 to-white p-6 dark:border-zinc-800 dark:from-zinc-900 dark:to-zinc-950"
              >
                <div className="mb-4 flex items-center gap-3">
                  <span className="text-2xl">{source.icon}</span>
                  <h3 className="text-lg font-semibold text-zinc-900 dark:text-white">
                    {source.title}
                  </h3>
                </div>
                <p className="mb-4 text-sm leading-relaxed text-zinc-600 dark:text-zinc-300">
                  {source.description}
                </p>
                <div className="flex flex-wrap gap-3">
                  {source.links.map((link, linkIndex) => (
                    <a
                      key={linkIndex}
                      href={link.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="inline-flex items-center gap-2 text-sm font-medium text-orange-600 transition-colors hover:text-orange-700 dark:text-orange-400 dark:hover:text-orange-300"
                    >
                      {link.label === "visitWebsite"
                        ? t("visitWebsite")
                        : link.label}
                      <ExternalLinkIcon />
                    </a>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Technology Stack */}
      <section className="border-t border-zinc-200 bg-linear-to-b from-zinc-50 to-white py-16 dark:border-zinc-800 dark:from-zinc-900 dark:to-zinc-950">
        <div className="mx-auto max-w-5xl px-6 sm:px-8">
          <div className="mb-12 text-center">
            <h2 className="text-3xl font-bold tracking-tight text-zinc-900 dark:text-white">
              {t("techStackTitle")}
            </h2>
          </div>

          <div className="mx-auto grid max-w-3xl gap-6 sm:grid-cols-3">
            {techStack.map((tech, index) => (
              <div
                key={index}
                className="rounded-xl border border-zinc-200 bg-white p-6 transition-all hover:border-zinc-300 dark:border-zinc-800 dark:bg-zinc-900 dark:hover:border-zinc-700"
              >
                <h3 className="mb-3 text-lg font-semibold text-zinc-900 dark:text-white">
                  {tech.title}
                </h3>
                <p className="text-sm leading-relaxed text-zinc-600 dark:text-zinc-300">
                  {tech.description}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>
    </main>
  );
}
