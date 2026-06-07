export const locales = ["fr", "en"] as const;
export type Locale = (typeof locales)[number];

export const defaultLocale: Locale = "fr";

export const localeNames: Record<Locale, string> = {
  fr: "Francais",
  en: "English",
};

export const rtlLocales: readonly Locale[] = []; // Empty for Sprint 1 (FR + EN are LTR). Will include 'ar' when added.

export function isRtl(locale: Locale): boolean {
  return (rtlLocales as readonly string[]).includes(locale);
}
