import type { Metadata } from "next";
import { Noto_Sans_JP } from "next/font/google";
import "./globals.css";

const notoSansJP = Noto_Sans_JP({
  variable: "--font-noto-sans-jp",
  subsets: ["latin"],
  weight: ["300", "400", "500", "600", "700"],
});

export const metadata: Metadata = {
  title: "HiNan! - 歩いて避難訓練を習慣にする",
  description: "HiNan! は、AIが生成するシナリオに基づき、実際に近くの避難所まで歩いて避難訓練を行うモバイルアプリです。ゲーミフィケーションを通して、避難訓練を楽しく・繰り返せる・健康的な体験にします。",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body
        className={`${notoSansJP.variable} font-sans antialiased`}
      >
        {children}
      </body>
    </html>
  );
}
