import type { ReactNode } from "react";
import type { Metadata } from "next";
import { NextIntlClientProvider } from "next-intl";
import { getMessages, setRequestLocale } from "next-intl/server";
import { locales, isRtl, type Locale } from "@/i18n/config";
import "../globals.css";

export function generateStaticParams() {
  return locales.map((locale) => ({ locale }));
}

export const metadata: Metadata = {
  title: "ShopEasy",
  description: "E-commerce multi-vendor platform",
};

type LocaleLayoutProps = {
  children: ReactNode;
  params: Promise<{ locale: Locale }>;
};

export default async function LocaleLayout({ children, params }: LocaleLayoutProps) {
  const { locale } = await params;
  setRequestLocale(locale);
  const messages = await getMessages();

  return (
    <html lang={locale} dir={isRtl(locale) ? "rtl" : "ltr"}>
      <body>
        <NextIntlClientProvider messages={messages}>{children}</NextIntlClientProvider>
      </body>
    </html>
  );
}
