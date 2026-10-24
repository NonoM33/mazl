import { describe, expect, test } from "bun:test";
import type { EventRow } from "../../web/src/shared/api/types";
import { attendeesLabel, clock, priceLabel, rsvpErrorMessage, shortDay, spotsLabel, spotsLeft, whenLabel } from "../../web/src/features/events/event-format";

const base: EventRow = {
  id: 1, title: "Dîner", description: null, event_type: "shabbat_dinner", location: "Paris 16e", address: null,
  date: "2026-10-30", time: "19:30:00", end_time: null, price: "35.00", currency: "EUR", max_attendees: 40, image_url: null, attendee_count: "12",
};

describe("places restantes", () => {
  test("max_attendees moins attendee_count (une chaîne côté API)", () => {
    expect(spotsLeft(base)).toBe(28);
    expect(spotsLabel(base)).toBe("28 places restantes");
  });
  test("une seule place, au singulier", () => {
    expect(spotsLabel({ ...base, attendee_count: 39 })).toBe("1 place restante");
  });
  test("complet, jamais négatif même en cas de surréservation", () => {
    expect(spotsLeft({ ...base, attendee_count: "45" })).toBe(0);
    expect(spotsLabel({ ...base, attendee_count: "40" })).toBe("Complet");
  });
  test("sans plafond, on ne compte rien", () => {
    expect(spotsLeft({ ...base, max_attendees: null })).toBeNull();
    expect(spotsLabel({ ...base, max_attendees: null })).toBeNull();
  });
});

describe("inscrits", () => {
  test("accord au singulier pour zéro et un", () => {
    expect(attendeesLabel({ ...base, attendee_count: "0" })).toBe("0 inscrit");
    expect(attendeesLabel({ ...base, attendee_count: 1 })).toBe("1 inscrit");
    expect(attendeesLabel({ ...base, attendee_count: "12" })).toBe("12 inscrits");
  });
});

describe("prix", () => {
  const nbsp = /\s/g;
  test("gratuit", () => {
    expect(priceLabel({ ...base, price: "0.00" })).toBe("Gratuit");
    expect(priceLabel({ ...base, price: null })).toBe("Gratuit");
  });
  test("euros, la décimale venant de l'API est en euros et non en centimes", () => {
    expect(priceLabel(base).replace(nbsp, " ")).toBe("35,00 €");
    expect(priceLabel({ ...base, price: "12.50" }).replace(nbsp, " ")).toBe("12,50 €");
  });
});

describe("dates", () => {
  test("le jour s'affiche tel qu'écrit, sans décalage de fuseau", () => {
    expect(shortDay("2026-10-30")).toBe("ven. 30 oct.");
    expect(shortDay("2026-10-30T00:00:00.000Z")).toBe("ven. 30 oct.");
  });
  test("heure sans les secondes", () => {
    expect(clock("19:30:00")).toBe("19:30");
    expect(clock(null)).toBeNull();
    expect(whenLabel(base)).toBe("ven. 30 oct. · 19:30");
  });
});

describe("erreurs d'inscription", () => {
  test("libellés français", () => {
    expect(rsvpErrorMessage("Event is full")).toBe("Complet");
    expect(rsvpErrorMessage("Event is over")).toBe("Événement passé");
    expect(rsvpErrorMessage("Event not found")).toBe("Événement introuvable");
  });
});
