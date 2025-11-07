import { setRequestLocale, getTranslations } from "next-intl/server";
import { TeamMemberCard } from "./TeamMemberCard";
import { DataSourceCard } from "./DataSourceCard";
import { TechStackCard } from "./TechStackCard";
import { Building2, Bot, LucideIcon } from "lucide-react";

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
      icon: Building2,
      links: [{ label: "visitWebsite", url: "https://www.gsi.go.jp/" }],
    },
    {
      icon: Bot,
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
              <TeamMemberCard key={index} {...member} />
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
              <DataSourceCard
                key={index}
                icon={source.icon}
                title={source.title}
                description={source.description}
                links={source.links.map((link) => ({
                  label:
                    link.label === "visitWebsite"
                      ? t("visitWebsite")
                      : link.label,
                  url: link.url,
                }))}
              />
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
              <TechStackCard key={index} {...tech} />
            ))}
          </div>
        </div>
      </section>
    </main>
  );
}
