import { setRequestLocale, getTranslations } from "next-intl/server";

type Props = {
  params: Promise<{ locale: string }>;
};

export default async function DemoPage({ params }: Props) {
  const { locale } = await params;
  setRequestLocale(locale);
  const t = await getTranslations("demo");

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

      {/* Hack Day Features */}
      <section className="bg-white py-16 dark:bg-zinc-900">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="mb-12 text-center">
            <h2 className="text-3xl font-bold text-zinc-900 dark:text-white">
              {t("hackDayFeaturesTitle")}
            </h2>
            <p className="mt-4 text-lg text-zinc-600 dark:text-zinc-400">
              {t("hackDayFeaturesSubtitle")}
            </p>
          </div>

          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            <div className="rounded-lg border border-zinc-200 bg-zinc-50 p-6 dark:border-zinc-800 dark:bg-zinc-950">
              <div className="mb-3 flex items-center gap-2">
                <span className="text-2xl">🗺️</span>
                <h3 className="text-lg font-semibold text-zinc-900 dark:text-white">
                  {t("hackFeature1Title")}
                </h3>
              </div>
              <p className="text-sm text-zinc-600 dark:text-zinc-400">
                {t("hackFeature1Description")}
              </p>
            </div>

            <div className="rounded-lg border border-zinc-200 bg-zinc-50 p-6 dark:border-zinc-800 dark:bg-zinc-950">
              <div className="mb-3 flex items-center gap-2">
                <span className="text-2xl">🏅</span>
                <h3 className="text-lg font-semibold text-zinc-900 dark:text-white">
                  {t("hackFeature2Title")}
                </h3>
              </div>
              <p className="text-sm text-zinc-600 dark:text-zinc-400">
                {t("hackFeature2Description")}
              </p>
            </div>

            <div className="rounded-lg border border-zinc-200 bg-zinc-50 p-6 dark:border-zinc-800 dark:bg-zinc-950">
              <div className="mb-3 flex items-center gap-2">
                <span className="text-2xl">🤖</span>
                <h3 className="text-lg font-semibold text-zinc-900 dark:text-white">
                  {t("hackFeature3Title")}
                </h3>
              </div>
              <p className="text-sm text-zinc-600 dark:text-zinc-400">
                {t("hackFeature3Description")}
              </p>
            </div>

            <div className="rounded-lg border border-zinc-200 bg-zinc-50 p-6 dark:border-zinc-800 dark:bg-zinc-950">
              <div className="mb-3 flex items-center gap-2">
                <span className="text-2xl">🌍</span>
                <h3 className="text-lg font-semibold text-zinc-900 dark:text-white">
                  {t("hackFeature4Title")}
                </h3>
              </div>
              <p className="text-sm text-zinc-600 dark:text-zinc-400">
                {t("hackFeature4Description")}
              </p>
            </div>

            <div className="rounded-lg border border-zinc-200 bg-zinc-50 p-6 dark:border-zinc-800 dark:bg-zinc-950">
              <div className="mb-3 flex items-center gap-2">
                <span className="text-2xl">🎯</span>
                <h3 className="text-lg font-semibold text-zinc-900 dark:text-white">
                  {t("hackFeature5Title")}
                </h3>
              </div>
              <p className="text-sm text-zinc-600 dark:text-zinc-400">
                {t("hackFeature5Description")}
              </p>
            </div>

            <div className="rounded-lg border border-zinc-200 bg-zinc-50 p-6 dark:border-zinc-800 dark:bg-zinc-950">
              <div className="mb-3 flex items-center gap-2">
                <span className="text-2xl">📊</span>
                <h3 className="text-lg font-semibold text-zinc-900 dark:text-white">
                  {t("hackFeature6Title")}
                </h3>
              </div>
              <p className="text-sm text-zinc-600 dark:text-zinc-400">
                {t("hackFeature6Description")}
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Improvement Sprint Features */}
      <section className="bg-zinc-50 py-16 dark:bg-black">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="mb-12 text-center">
            <h2 className="text-3xl font-bold text-zinc-900 dark:text-white">
              {t("improvementTitle")}
            </h2>
            <p className="mt-4 text-lg text-zinc-600 dark:text-zinc-400">
              {t("improvementSubtitle")}
            </p>
          </div>

          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            <div className="rounded-lg border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-900">
              <div className="mb-3 flex items-center gap-2">
                <span className="text-2xl">📏</span>
                <h3 className="text-lg font-semibold text-zinc-900 dark:text-white">
                  {t("improvementFeature1Title")}
                </h3>
              </div>
              <p className="text-sm text-zinc-600 dark:text-zinc-400">
                {t("improvementFeature1Description")}
              </p>
            </div>

            <div className="rounded-lg border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-900">
              <div className="mb-3 flex items-center gap-2">
                <span className="text-2xl">🎬</span>
                <h3 className="text-lg font-semibold text-zinc-900 dark:text-white">
                  {t("improvementFeature2Title")}
                </h3>
              </div>
              <p className="text-sm text-zinc-600 dark:text-zinc-400">
                {t("improvementFeature2Description")}
              </p>
            </div>

            <div className="rounded-lg border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-900">
              <div className="mb-3 flex items-center gap-2">
                <span className="text-2xl">🏆</span>
                <h3 className="text-lg font-semibold text-zinc-900 dark:text-white">
                  {t("improvementFeature3Title")}
                </h3>
              </div>
              <p className="text-sm text-zinc-600 dark:text-zinc-400">
                {t("improvementFeature3Description")}
              </p>
            </div>

            <div className="rounded-lg border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-900">
              <div className="mb-3 flex items-center gap-2">
                <span className="text-2xl">📱</span>
                <h3 className="text-lg font-semibold text-zinc-900 dark:text-white">
                  {t("improvementFeature4Title")}
                </h3>
              </div>
              <p className="text-sm text-zinc-600 dark:text-zinc-400">
                {t("improvementFeature4Description")}
              </p>
            </div>

            <div className="rounded-lg border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-900">
              <div className="mb-3 flex items-center gap-2">
                <span className="text-2xl">💬</span>
                <h3 className="text-lg font-semibold text-zinc-900 dark:text-white">
                  {t("improvementFeature5Title")}
                </h3>
              </div>
              <p className="text-sm text-zinc-600 dark:text-zinc-400">
                {t("improvementFeature5Description")}
              </p>
            </div>

            <div className="rounded-lg border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-900">
              <div className="mb-3 flex items-center gap-2">
                <span className="text-2xl">👤</span>
                <h3 className="text-lg font-semibold text-zinc-900 dark:text-white">
                  {t("improvementFeature6Title")}
                </h3>
              </div>
              <p className="text-sm text-zinc-600 dark:text-zinc-400">
                {t("improvementFeature6Description")}
              </p>
            </div>

            <div className="rounded-lg border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-900">
              <div className="mb-3 flex items-center gap-2">
                <span className="text-2xl">🎮</span>
                <h3 className="text-lg font-semibold text-zinc-900 dark:text-white">
                  {t("improvementFeature7Title")}
                </h3>
              </div>
              <p className="text-sm text-zinc-600 dark:text-zinc-400">
                {t("improvementFeature7Description")}
              </p>
            </div>

            <div className="rounded-lg border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-900">
              <div className="mb-3 flex items-center gap-2">
                <span className="text-2xl">⭐</span>
                <h3 className="text-lg font-semibold text-zinc-900 dark:text-white">
                  {t("improvementFeature8Title")}
                </h3>
              </div>
              <p className="text-sm text-zinc-600 dark:text-zinc-400">
                {t("improvementFeature8Description")}
              </p>
            </div>

            <div className="rounded-lg border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-900">
              <div className="mb-3 flex items-center gap-2">
                <span className="text-2xl">👥</span>
                <h3 className="text-lg font-semibold text-zinc-900 dark:text-white">
                  {t("improvementFeature9Title")}
                </h3>
              </div>
              <p className="text-sm text-zinc-600 dark:text-zinc-400">
                {t("improvementFeature9Description")}
              </p>
            </div>

            <div className="rounded-lg border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-900">
              <div className="mb-3 flex items-center gap-2">
                <span className="text-2xl">🗺️</span>
                <h3 className="text-lg font-semibold text-zinc-900 dark:text-white">
                  {t("improvementFeature10Title")}
                </h3>
              </div>
              <p className="text-sm text-zinc-600 dark:text-zinc-400">
                {t("improvementFeature10Description")}
              </p>
            </div>
          </div>
        </div>
      </section>
    </main>
  );
}
