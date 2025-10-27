"use client";

import { useTranslations } from "next-intl";
import { LanguageSwitcher } from "./language-switcher";
import { assetPrefix } from "@/lib/asset-prefix";
import { Button } from "@/components/ui/button";
import Image from "next/image";
import { useState } from "react";
import { Menu, X } from "lucide-react";
import { Link, usePathname } from "@/i18n/routing";

export function Navbar() {
  const t = useTranslations("navbar");
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const pathname = usePathname();

  const mainNavItems = [
    { key: "demo", href: "/demo" },
    { key: "about", href: "/about" },
  ];

  const isActive = (href: string) => {
    return pathname === href;
  };

  return (
    <nav className="fixed top-0 z-50 w-full border-b border-zinc-200/50 bg-white/90 shadow-sm backdrop-blur-lg dark:border-zinc-800/50 dark:bg-zinc-900/90">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="flex h-16 items-center justify-between">
          {/* Logo */}
          <Link
            href="/"
            className="group flex items-center gap-2 transition-opacity hover:opacity-80"
          >
            <Image
              src={`${assetPrefix}/logo.png`}
              alt="HiNan! Logo"
              width={36}
              height={36}
              unoptimized
              className="transition-transform group-hover:scale-105"
            />
            <span className="text-xl font-bold text-orange-500">HiNan!</span>
          </Link>

          {/* Desktop Navigation */}
          <div className="hidden items-center gap-1 md:flex">
            {mainNavItems.map((item) => (
              <Link
                key={item.key}
                href={item.href}
                className={`rounded-md px-3 py-2 text-sm font-medium transition-colors ${
                  isActive(item.href)
                    ? "bg-orange-50 text-orange-600 dark:bg-orange-950 dark:text-orange-400"
                    : "text-zinc-700 hover:bg-zinc-100 hover:text-zinc-900 dark:text-zinc-300 dark:hover:bg-zinc-800 dark:hover:text-white"
                }`}
              >
                {t(item.key)}
              </Link>
            ))}
            <div className="ml-2">
              <LanguageSwitcher />
            </div>
          </div>

          {/* Mobile menu button */}
          <div className="flex items-center gap-2 md:hidden">
            <LanguageSwitcher />
            <Button
              variant="ghost"
              size="icon"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="text-zinc-600 dark:text-zinc-400"
            >
              {mobileMenuOpen ? (
                <X className="h-5 w-5" />
              ) : (
                <Menu className="h-5 w-5" />
              )}
            </Button>
          </div>
        </div>
      </div>

      {/* Mobile Navigation */}
      {mobileMenuOpen && (
        <div className="border-t border-zinc-200/50 bg-white/95 backdrop-blur-lg dark:border-zinc-800/50 dark:bg-zinc-900/95 md:hidden">
          <div className="space-y-1 px-3 pb-3 pt-2">
            {mainNavItems.map((item) => (
              <Link
                key={item.key}
                href={item.href}
                onClick={() => setMobileMenuOpen(false)}
                className={`block rounded-lg px-3 py-2.5 text-base font-medium transition-colors ${
                  isActive(item.href)
                    ? "bg-orange-50 text-orange-600 dark:bg-orange-950 dark:text-orange-400"
                    : "text-zinc-700 hover:bg-zinc-100 dark:text-zinc-300 dark:hover:bg-zinc-800"
                }`}
              >
                {t(item.key)}
              </Link>
            ))}
          </div>
        </div>
      )}
    </nav>
  );
}
