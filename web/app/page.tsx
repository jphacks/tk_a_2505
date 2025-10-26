import Image from "next/image";

export default function Home() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-zinc-50 dark:bg-black">
      <main className="flex flex-col items-center gap-6 p-8">
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
          歩いて避難訓練を習慣にする
        </p>
      </main>
    </div>
  );
}
