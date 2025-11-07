import { setRequestLocale, getTranslations } from "next-intl/server";
import { FeatureSection } from "./FeatureSection";
import {
  Map,
  Award,
  Bot,
  Globe,
  BarChart3,
  Ruler,
  Trophy,
  Smartphone,
  User,
  Gamepad2,
  Star,
  Users,
  MapPin,
} from "lucide-react";

type Props = {
  params: Promise<{ locale: string }>;
};

export default async function DemoPage({ params }: Props) {
  const { locale } = await params;
  setRequestLocale(locale);
  const t = await getTranslations("demo");

  // Hack Day Features
  const hackDayFeatures = [
    { icon: Map, key: 1 },
    { icon: Award, key: 2 },
    { icon: Bot, key: 3 },
    { icon: Globe, key: 4 },
    { icon: BarChart3, key: 6 },
  ].map((f) => ({
    icon: f.icon,
    title: t(`hackFeature${f.key}Title`),
    description: t(`hackFeature${f.key}Description`),
  }));

  // Improvement Sprint Features
  const improvementFeatures = [
    { icon: Ruler, key: 1 },
    { icon: Trophy, key: 3 },
    { icon: Smartphone, key: 4 },
    { icon: User, key: 6 },
    { icon: Gamepad2, key: 7 },
    { icon: Star, key: 8 },
    { icon: Users, key: 9 },
    { icon: MapPin, key: 10 },
  ].map((f) => ({
    icon: f.icon,
    title: t(`improvementFeature${f.key}Title`),
    description: t(`improvementFeature${f.key}Description`),
  }));

  return (
    <main className="min-h-screen bg-linear-to-b from-white to-zinc-50 dark:from-zinc-950 dark:to-black">
      {/* Header */}
      <section className="mx-auto max-w-7xl px-4 pb-12 pt-24 sm:px-6 lg:px-8">
        <div className="text-center">
          <h1 className="text-4xl font-bold text-zinc-900 dark:text-white sm:text-5xl">
            {t("title")}
          </h1>
          <p className="mt-4 text-xl text-zinc-600 dark:text-zinc-400">
            {t("subtitle")}
          </p>
        </div>
      </section>

      {/* Video Demo */}
      <section className="mx-auto max-w-7xl px-4 pb-16 sm:px-6 lg:px-8">
        <div className="flex justify-center">
          <div className="w-full max-w-4xl overflow-hidden rounded-2xl">
            <div className="relative pb-[56.25%]">
              <iframe
                className="absolute inset-0 h-full w-full"
                src="https://www.youtube.com/embed/YsDiRaXBxnY"
                title="HiNan! Demo Video"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                allowFullScreen
              />
            </div>
          </div>
        </div>
      </section>

      <FeatureSection
        title={t("hackDayFeaturesTitle")}
        subtitle={t("hackDayFeaturesSubtitle")}
        features={hackDayFeatures}
        variant="light"
      />

      <FeatureSection
        title={t("improvementTitle")}
        subtitle={t("improvementSubtitle")}
        features={improvementFeatures}
        variant="dark"
      />
    </main>
  );
}
