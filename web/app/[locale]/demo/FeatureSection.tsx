import { FeatureCard } from "./FeatureCard";

type Feature = {
  icon: string;
  title: string;
  description: string;
};

type FeatureSectionProps = {
  title: string;
  subtitle: string;
  features: Feature[];
  variant?: "light" | "dark";
};

export function FeatureSection({
  title,
  subtitle,
  features,
  variant = "light",
}: FeatureSectionProps) {
  const bgClass =
    variant === "light"
      ? "bg-white dark:bg-zinc-900"
      : "bg-zinc-50 dark:bg-black";

  const cardBgClass =
    variant === "light"
      ? "bg-zinc-50 dark:bg-zinc-950"
      : "bg-white dark:bg-zinc-900";

  return (
    <section className={`${bgClass} py-16`}>
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="mb-12 text-center">
          <h2 className="text-3xl font-bold text-zinc-900 dark:text-white">
            {title}
          </h2>
          <p className="mt-4 text-lg text-zinc-600 dark:text-zinc-400">
            {subtitle}
          </p>
        </div>

        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          {features.map((feature, index) => (
            <div key={index} className={cardBgClass}>
              <FeatureCard
                icon={feature.icon}
                title={feature.title}
                description={feature.description}
              />
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
