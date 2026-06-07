/**
 * Currency utilities using dinero.js v2.
 *
 * Stub file for Sprint 1 - full implementation in Sprint 2+.
 * All amounts are stored in minor units (cents) with ISO 4217 currency codes.
 */

import { dinero, toDecimal, type Dinero } from "dinero.js";
import { CAD, USD, EUR } from "@dinero.js/currencies";

export const currencies = {
  CAD,
  USD,
  EUR,
} as const;

export type SupportedCurrency = keyof typeof currencies;

export function createMoney(amount: number, currency: SupportedCurrency): Dinero<number> {
  return dinero({ amount, currency: currencies[currency] });
}

export function formatMoney(money: Dinero<number>, locale: string): string {
  const decimal = toDecimal(money);
  return new Intl.NumberFormat(locale, {
    style: "currency",
    currency: money.toJSON().currency.code,
  }).format(Number(decimal));
}
