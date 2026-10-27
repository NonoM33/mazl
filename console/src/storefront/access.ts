import type { MeDto } from "../shared/api/contracts";

/** Changer un prix, programmer ou annuler une campagne : permission `storefront.stores` (celle que le serveur exige, super-administrateur seulement). */
export const canWriteStorefront = (me: Pick<MeDto, "permissions">): boolean => me.permissions.includes("storefront.stores");

export const SUPER_ADMIN_ONLY = "Réservé aux super-administrateurs.";
