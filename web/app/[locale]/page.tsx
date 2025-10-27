import Image from "next/image";
import { setRequestLocale, getTranslations } from "next-intl/server";
import { LanguageSwitcher } from "@/components/language-switcher";

type Props = {
  params: Promise<{ locale: string }>;
};

export default async function Home({ params }: Props) {
  const { locale } = await params;
  setRequestLocale(locale);
  const t = await getTranslations("homepage");

  return (
    <div className="flex min-h-screen items-center justify-center bg-zinc-50 dark:bg-black">
      <main className="flex flex-col items-center gap-6 p-8">
        <div className="absolute right-4 top-4">
          <LanguageSwitcher />
        </div>
        <Image
          src="/logo.png"
          alt="HiNan! Logo"
          width={200}
          height={200}
          priority
        />
        <h1 className="text-4xl font-bold text-black dark:text-white">
          HiNan!
        </h1>
        <p className="text-lg text-zinc-600 dark:text-zinc-400">
          {t("tagline")}
        </p>
      </main>
    </div>
  );
}
