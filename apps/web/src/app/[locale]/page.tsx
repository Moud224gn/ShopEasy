import { useTranslations } from "next-intl";
import { setRequestLocale } from "next-intl/server";
import type { Locale } from "@/i18n/config";

type HomePageProps = {
  params: Promise<{ locale: Locale }>;
};

export default async function HomePage({ params }: HomePageProps) {
  const { locale } = await params;
  setRequestLocale(locale);

  return <HomeContent />;
}

function HomeContent() {
  const t = useTranslations("common");

  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-8">
      <h1 className="text-4xl font-bold">{t("welcome")}</h1>
      <p className="mt-4 text-lg text-gray-600">{t("description")}</p>
    </main>
  );
}
