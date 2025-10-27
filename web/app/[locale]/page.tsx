import Image from "next/image";
import Link from "next/link";
import { setRequestLocale, getTranslations } from "next-intl/server";
import { assetPrefix } from "@/lib/asset-prefix";
import { Button } from "@/components/ui/button";

type Props = {
  params: Promise<{ locale: string }>;
};

export default async function Home({ params }: Props) {
  const { locale } = await params;
  setRequestLocale(locale);
  const t = await getTranslations("homepage");

  return (
    <main className="min-h-screen bg-gradient-to-b from-white to-zinc-50 dark:from-zinc-950 dark:to-black">
      {/* Hero Section */}
      <section className="mx-auto max-w-7xl px-4 pb-16 pt-24 sm:px-6 lg:px-8">
        <div className="grid items-center gap-12 lg:grid-cols-2 lg:gap-16">
          {/* Right Content - Phone Mockup (shown first on mobile) */}
          <div className="relative flex justify-center overflow-hidden lg:order-2">
            <div className="relative h-[400px] w-full lg:h-auto lg:w-full lg:max-w-[400px]">
              <Image
                src={`${assetPrefix}/screen1.png`}
                alt="HiNan! App Screenshot"
                width={350}
                height={700}
                priority
                unoptimized
                className="absolute left-1/2 top-0 h-[500px] w-auto -translate-x-1/2 rounded-3xl object-cover object-top lg:static lg:h-auto lg:w-full lg:translate-x-0"
              />
            </div>
          </div>

          {/* Left Content (shown second on mobile) */}
          <div className="flex flex-col gap-6 text-center lg:order-1 lg:text-left">
            <div className="flex items-center justify-center gap-3 lg:justify-start">
              <Image
                src={`${assetPrefix}/logo.png`}
                alt="HiNan! Logo"
                width={64}
                height={64}
                priority
                unoptimized
              />
              <h1 className="text-5xl font-bold text-orange-500 sm:text-6xl">
                HiNan!
              </h1>
            </div>
            <h2 className="text-3xl font-bold text-zinc-900 dark:text-white sm:text-4xl">
              {t("tagline")}
            </h2>
            <p className="text-lg text-zinc-600 dark:text-zinc-400">
              {t("description")}
            </p>
            <div className="flex flex-wrap justify-center gap-4 lg:justify-start">
              <Button
                asChild
                size="lg"
                className="bg-orange-500 hover:bg-orange-600"
              >
                <Link href="#demo">{t("tryDemo")}</Link>
              </Button>
              <Button asChild size="lg" variant="outline">
                <Link href="#features">{t("learnMore")}</Link>
              </Button>
            </div>
          </div>
        </div>
      </section>

      {/* Features Preview */}
      <section id="features" className="bg-white py-16 dark:bg-zinc-900">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="text-center">
            <h2 className="text-3xl font-bold text-zinc-900 dark:text-white">
              {t("featuresTitle")}
            </h2>
            <p className="mt-4 text-lg text-zinc-600 dark:text-zinc-400">
              {t("featuresDescription")}
            </p>
          </div>
          <div className="mt-12 grid gap-8 md:grid-cols-3">
            <div className="rounded-lg border border-zinc-200 bg-zinc-50 p-6 dark:border-zinc-800 dark:bg-zinc-950">
              <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-lg bg-orange-500 text-2xl text-white">
                🏠
              </div>
              <h3 className="mb-2 text-xl font-semibold text-zinc-900 dark:text-white">
                {t("feature1Title")}
              </h3>
              <p className="text-zinc-600 dark:text-zinc-400">
                {t("feature1Description")}
              </p>
            </div>
            <div className="rounded-lg border border-zinc-200 bg-zinc-50 p-6 dark:border-zinc-800 dark:bg-zinc-950">
              <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-lg bg-orange-500 text-2xl text-white">
                🎮
              </div>
              <h3 className="mb-2 text-xl font-semibold text-zinc-900 dark:text-white">
                {t("feature2Title")}
              </h3>
              <p className="text-zinc-600 dark:text-zinc-400">
                {t("feature2Description")}
              </p>
            </div>
            <div className="rounded-lg border border-zinc-200 bg-zinc-50 p-6 dark:border-zinc-800 dark:bg-zinc-950">
              <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-lg bg-orange-500 text-2xl text-white">
                🚶
              </div>
              <h3 className="mb-2 text-xl font-semibold text-zinc-900 dark:text-white">
                {t("feature3Title")}
              </h3>
              <p className="text-zinc-600 dark:text-zinc-400">
                {t("feature3Description")}
              </p>
            </div>
          </div>
        </div>
      </section>
    </main>
  );
}
