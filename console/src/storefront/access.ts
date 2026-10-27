import type { MeDto } from "../shared/api/contracts";

/** Changer un prix et programmer ou annuler une campagne : super-administrateur seulement. */
export const canWriteStorefront = (me: Pick<MeDto, "role">): boolean => me.role === "super_admin";

export const SUPER_ADMIN_ONLY = "Réservé aux super-administrateurs.";
