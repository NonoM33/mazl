import { z } from "zod";
import type { Permission } from "../../staff/domain/roles";
import {
  applePlanDto,
  applePriceBody,
  applePriceResultDto,
  campaignBody,
  campaignDto,
  campaignListDto,
  campaignPatchBody,
  openApiDocument,
  presetListDto,
  pricePointsDto,
  productDisplayDto,
  productListDto,
  productPatchBody,
  publicStorefrontDto,
  webPriceBody,
  webPriceResultDto,
} from "./schemas";
import {
  applePlanExample,
  campaignCancelledExample,
  campaignDraftExample,
  campaignExample,
  campaignRequestExample,
  presetExample,
  productDisplayExample,
  productViewExample,
  publicStorefrontExample,
} from "./examples";

// The storefront API, declared once: the routes are registered from this list and the
// OpenAPI document is generated from it (docs/api/storefront-openapi.json).

export const STAFF_BASE = "/api/backoffice/storefront";
export const PUBLIC_PATH = "/api/storefront";

export interface ErrorSpec {
  readonly status: 400 | 401 | 403 | 404 | 409 | 500 | 502 | 503;
  readonly code: string;
  readonly message?: string;
  readonly description: string;
}

export interface ParameterSpec {
  readonly name: string;
  readonly in: "path" | "query";
  readonly description: string;
  readonly required: boolean;
  readonly schema: z.ZodType;
  readonly example: unknown;
}

export interface OperationSpec {
  readonly operationId: string;
  readonly method: "get" | "post" | "patch";
  // OpenAPI notation, {id}; the router uses :id.
  readonly path: string;
  readonly tag: string;
  readonly summary: string;
  readonly description: string;
  // null: public route, no authentication.
  readonly permission: Permission | null;
  readonly parameters: readonly ParameterSpec[];
  readonly body?: { readonly schema: z.ZodType; readonly examples: Readonly<Record<string, { readonly summary: string; readonly value: unknown }>> };
  readonly success: {
    readonly status: 200 | 201;
    readonly description: string;
    readonly schema: z.ZodType;
    // false: the body is the data itself, without { success, data }.
    readonly enveloped: boolean;
    readonly example: unknown;
  };
  readonly errors: readonly ErrorSpec[];
}

const UNAUTHORIZED: ErrorSpec = { status: 401, code: "unauthorized", message: "Connexion requise.", description: "Pas de session staff valide." };
const FORBIDDEN: ErrorSpec = { status: 403, code: "forbidden", message: "Droits insuffisants.", description: "Le rôle de la session n'a pas la permission requise." };
const MFA_REQUIRED: ErrorSpec = { status: 403, code: "mfa_required", message: "Second facteur requis.", description: "La session n'a pas passé le second facteur (TOTP) exigé." };
const INTERNAL: ErrorSpec = { status: 500, code: "internal_error", description: "Erreur inattendue du serveur (détail dans les journaux, jamais dans la réponse)." };
const INVALID_BODY: ErrorSpec = { status: 400, code: "invalid_body", message: "visible: Invalid input", description: "Corps absent, illisible ou hors schéma." };
const PRODUCT_NOT_FOUND: ErrorSpec = { status: 404, code: "product_not_found", description: "Produit inconnu du catalogue." };
const CAMPAIGN_NOT_FOUND: ErrorSpec = { status: 404, code: "campaign_not_found", description: "Campagne inconnue." };
const STORE_NOT_CONFIGURED: ErrorSpec = {
  status: 503,
  code: "store_not_configured",
  message: "The apple store is not configured on this server",
  description: "Aucun accès à Apple ou à Stripe n'est branché sur ce serveur : rien n'a été envoyé.",
};
const STORE_ERROR: ErrorSpec = {
  status: 502,
  code: "store_error",
  message: "apple: request refused",
  description: "Apple ou Stripe a refusé l'appel ou n'a pas répondu ; le message est tronqué et sans secret.",
};

const staffErrors = [UNAUTHORIZED, FORBIDDEN, MFA_REQUIRED, INTERNAL];

const productIdParam: ParameterSpec = {
  name: "productId",
  in: "path",
  description: "Identifiant du produit, celui du catalogue des offres (com.mazl.app.plus.3m…).",
  required: true,
  schema: z.string(),
  example: "com.mazl.app.plus.3m",
};
const campaignIdParam: ParameterSpec = { name: "id", in: "path", description: "Numéro de la campagne.", required: true, schema: z.number().int().min(1), example: 12 };
const yearParam = (required: boolean): ParameterSpec => ({
  name: "year",
  in: "query",
  description: required ? "Année civile (2020 à 2100)." : "Année civile (2020 à 2100) ; sans elle, toutes les campagnes.",
  required,
  schema: z.number().int().min(2020).max(2100),
  example: 2027,
});

export const OPERATIONS: readonly OperationSpec[] = [
  {
    operationId: "storefrontPublic",
    method: "get",
    path: PUBLIC_PATH,
    tag: "Vitrine publique",
    summary: "Ce que l'app doit montrer : ordre des offres, mise en avant, campagne en cours",
    description:
      "Route publique, sans authentification, mise en cache 60 secondes (Cache-Control). Qui : l'app mobile et le site, à l'ouverture et au retour au premier plan. " +
      "Les textes sont dans la langue d'Accept-Language (fr par défaut, repli fr). Aucun prix n'est envoyé pour iOS : l'affichage vient de StoreKit. " +
      "iosOfferCode n'est présent que si le code a bien été créé chez Apple ; appIcon est null hors campagne ou si la campagne ne change pas l'icône. " +
      "Aucun effet de bord.",
    permission: null,
    parameters: [],
    success: { status: 200, description: "La vitrine du moment.", schema: publicStorefrontDto, enveloped: true, example: publicStorefrontExample },
    errors: [INTERNAL],
  },
  {
    operationId: "storefrontListProducts",
    method: "get",
    path: `${STAFF_BASE}/products`,
    tag: "Catalogue",
    summary: "Lister le catalogue avec les prix réels",
    description:
      "Rôles : administrateur ou super-administrateur (permission storefront.manage). Rend, pour chaque produit, l'affichage choisi (visibilité, ordre, mise en avant, texte) " +
      "et les prix réels lus chez Apple (France et les pays témoins US, GB, IL, CA) et chez Stripe. Un store injoignable ou non configuré " +
      "n'échoue pas la liste : son bloc passe à status \"unavailable\" avec la raison. Aucun effet de bord ; deux appels aux stores par produit.",
    permission: "storefront.manage",
    parameters: [],
    success: { status: 200, description: "Le catalogue.", schema: productListDto, enveloped: true, example: { products: [productViewExample] } },
    errors: staffErrors,
  },
  {
    operationId: "storefrontUpdateProduct",
    method: "patch",
    path: `${STAFF_BASE}/products/{productId}`,
    tag: "Catalogue",
    summary: "Modifier l'affichage d'un produit",
    description:
      "Rôles : administrateur ou super-administrateur (permission storefront.manage). Change la visibilité, l'ordre, la mise en avant ou le texte d'accroche ; " +
      "l'app le reprend au prochain chargement de /api/storefront. Les prix ne passent pas par ici. Effet de bord : une ligne dans l'audit staff.",
    permission: "storefront.manage",
    parameters: [productIdParam],
    body: {
      schema: productPatchBody,
      examples: {
        feature: { summary: "Mettre en avant avec un texte", value: { featured: true, highlight: { fr: "Le plus choisi", en: "Most popular" } } },
        hide: { summary: "Masquer un produit", value: { visible: false } },
      },
    },
    success: { status: 200, description: "Le produit mis à jour.", schema: productDisplayDto, enveloped: true, example: productDisplayExample },
    errors: [INVALID_BODY, PRODUCT_NOT_FOUND, ...staffErrors],
  },
  {
    operationId: "storefrontApplePricePoints",
    method: "get",
    path: `${STAFF_BASE}/products/{productId}/apple-price-points`,
    tag: "Prix",
    summary: "Lister les paliers de prix Apple d'un produit",
    description:
      "Rôles : administrateur ou super-administrateur (permission storefront.manage). Les paliers (price points) qu'Apple propose pour un pays, " +
      "à choisir avant de changer un prix. Lecture seule chez Apple, aucun effet de bord ; sans territory, la France (FRA).",
    permission: "storefront.manage",
    parameters: [
      productIdParam,
      { name: "territory", in: "query", description: "Pays au format Apple, trois lettres (FRA, USA…). Défaut FRA.", required: false, schema: z.string().regex(/^[A-Z]{3}$/), example: "FRA" },
    ],
    success: {
      status: 200,
      description: "Les paliers du pays.",
      schema: pricePointsDto,
      enveloped: true,
      example: {
        productId: "com.mazl.app.plus.3m",
        territory: "FRA",
        pricePoints: [{ id: "price_point_example_2", territory: "FRA", customerPrice: "26.99", proceeds: "18.90" }],
      },
    },
    errors: [{ status: 400, code: "invalid_query", description: "territory n'est pas un code à trois lettres majuscules." }, PRODUCT_NOT_FOUND, STORE_NOT_CONFIGURED, STORE_ERROR, ...staffErrors],
  },
  {
    operationId: "storefrontApplePrice",
    method: "post",
    path: `${STAFF_BASE}/products/{productId}/apple-price`,
    tag: "Prix",
    summary: "Changer le prix de base Apple d'un produit (essai à blanc d'abord)",
    description:
      "Rôle : super-administrateur seulement (permission storefront.stores). Par défaut dryRun vaut true : Apple est interrogé, rien n'est écrit, et la réponse " +
      "dit pays par pays ce qui changerait. Avec dryRun false le plan est recalculé puis appliqué à App Store Connect. preserveCurrentPrice (true par défaut) " +
      "laisse les abonnés actuels au prix qu'ils paient. startDate : aujourd'hui (Paris) ou plus tard, au plus 2 ans. " +
      "Effets de bord quand dryRun est false : une ligne par pays dans storefront_price_changes et une entrée dans l'audit staff, échec compris.",
    permission: "storefront.stores",
    parameters: [productIdParam],
    body: {
      schema: applePriceBody,
      examples: {
        dryRun: { summary: "Essai à blanc", value: { pricePointId: "price_point_example_2", startDate: "2027-03-01" } },
        apply: { summary: "Appliquer, les abonnés gardent leur prix", value: { pricePointId: "price_point_example_2", startDate: "2027-03-01", preserveCurrentPrice: true, dryRun: false } },
      },
    },
    success: { status: 200, description: "Le plan ; dryRun dit s'il a été appliqué.", schema: applePriceResultDto, enveloped: true, example: { dryRun: true, plan: applePlanExample } },
    errors: [
      INVALID_BODY,
      { status: 400, code: "invalid_price_change", message: "startDate cannot be in the past", description: "Date de départ invalide." },
      PRODUCT_NOT_FOUND,
      STORE_NOT_CONFIGURED,
      STORE_ERROR,
      ...staffErrors,
    ],
  },
  {
    operationId: "storefrontWebPrice",
    method: "post",
    path: `${STAFF_BASE}/products/{productId}/web-price`,
    tag: "Prix",
    summary: "Créer un nouveau prix web (Stripe) et l'adopter",
    description:
      "Rôle : super-administrateur seulement (permission storefront.stores). Un prix Stripe ne se modifie pas : un nouveau prix est créé (abonnement mensuel récurrent " +
      "pour les mazl+, paiement unique pour les packs), puis son identifiant est rangé dans le catalogue et remplace la variable d'environnement STRIPE_PRICE_*. " +
      "Les paiements en cours gardent l'ancien prix, les suivants prennent le nouveau (la vitrine web du paiement se rafraîchit en 10 minutes). " +
      "Effets de bord : une ligne dans storefront_price_changes et l'audit staff, échec compris.",
    permission: "storefront.stores",
    parameters: [productIdParam],
    body: { schema: webPriceBody, examples: { nominal: { summary: "Passer à 26,99 euros", value: { amountCents: 2699, currency: "eur" } } } },
    success: {
      status: 200,
      description: "Le nouveau prix et l'ancien identifiant.",
      schema: webPriceResultDto,
      enveloped: true,
      example: {
        price: { priceId: "price_example_plus_3m_v2", amountCents: 2699, currency: "eur" },
        previousPriceId: "price_example_plus_3m",
        product: { ...productDisplayExample, stripePriceId: "price_example_plus_3m_v2" },
      },
    },
    errors: [
      INVALID_BODY,
      { status: 400, code: "invalid_price_change", message: "amountCents must be an integer from 50 to 1000000", description: "Montant hors bornes." },
      PRODUCT_NOT_FOUND,
      STORE_NOT_CONFIGURED,
      STORE_ERROR,
      ...staffErrors,
    ],
  },
  {
    operationId: "storefrontListCampaigns",
    method: "get",
    path: `${STAFF_BASE}/campaigns`,
    tag: "Campagnes",
    summary: "Lister les campagnes",
    description:
      "Rôles : administrateur ou super-administrateur (permission storefront.manage). Les campagnes qui touchent l'année demandée (toutes sans year), " +
      "avec leur état calculé : draft, scheduled, live, ended ou cancelled. Aucun effet de bord.",
    permission: "storefront.manage",
    parameters: [yearParam(false)],
    success: { status: 200, description: "Les campagnes, la plus ancienne d'abord.", schema: campaignListDto, enveloped: true, example: { campaigns: [campaignExample] } },
    errors: [{ status: 400, code: "invalid_query", description: "year n'est pas une année entre 2020 et 2100." }, ...staffErrors],
  },
  {
    operationId: "storefrontCreateCampaign",
    method: "post",
    path: `${STAFF_BASE}/campaigns`,
    tag: "Campagnes",
    summary: "Créer une campagne (brouillon)",
    description:
      "Rôles : administrateur ou super-administrateur (permission storefront.manage). Crée un brouillon : rien n'est envoyé à Apple ni à Stripe tant qu'il n'est pas publié. " +
      "Règles : fin après début, 45 jours au plus, réduction de 5 à 90 %, produits connus et non répétés, textes français complets (les autres langues sont facultatives). " +
      "Effet de bord : l'audit staff.",
    permission: "storefront.manage",
    parameters: [],
    body: { schema: campaignBody, examples: { valentine: { summary: "Saint-Valentin 2027, 30 % sur le trimestre", value: campaignRequestExample } } },
    success: { status: 201, description: "Le brouillon créé.", schema: campaignDto, enveloped: true, example: campaignDraftExample },
    errors: [INVALID_BODY, { status: 400, code: "invalid_campaign", message: "a campaign lasts 45 days at most", description: "Une règle métier de la campagne n'est pas respectée." }, ...staffErrors],
  },
  {
    operationId: "storefrontCampaignPresets",
    method: "get",
    path: `${STAFF_BASE}/campaigns/presets`,
    tag: "Campagnes",
    summary: "Proposer une campagne par fête pour une année",
    description:
      "Rôles : administrateur ou super-administrateur (permission storefront.manage). Une proposition par thème avec ses dates calculées (fêtes juives sur le calendrier hébraïque, " +
      "fête des mères avec l'exception de la Pentecôte, Black Friday...), heure de Paris. existing liste les campagnes déjà enregistrées sur la fenêtre, " +
      "conflicts les campagnes programmées qui empêcheraient la publication, overlapsThemes les autres fêtes qui se chevauchent. Aucun effet de bord.",
    permission: "storefront.manage",
    parameters: [yearParam(true)],
    success: { status: 200, description: "Les propositions de l'année.", schema: presetListDto, enveloped: true, example: { year: 2027, presets: [presetExample] } },
    errors: [{ status: 400, code: "invalid_query", description: "year absent ou hors de 2020 à 2100." }, ...staffErrors],
  },
  {
    operationId: "storefrontUpdateCampaign",
    method: "patch",
    path: `${STAFF_BASE}/campaigns/{id}`,
    tag: "Campagnes",
    summary: "Modifier une campagne",
    description:
      "Rôles : administrateur ou super-administrateur (permission storefront.manage). Brouillon : tout se modifie. Programmée (pas encore commencée) : nom, textes et " +
      "changement d'icône seulement, car les dates et les produits sont liés aux codes créés chez Apple et Stripe (annuler puis recréer). En cours : uniquement une fin plus " +
      "proche, ou l'annulation. Terminée ou annulée : rien. Effet de bord : l'audit staff.",
    permission: "storefront.manage",
    parameters: [campaignIdParam],
    body: {
      schema: campaignPatchBody,
      examples: {
        texts: { summary: "Changer le nom", value: { name: "Saint-Valentin 2027 (révisée)" } },
        endEarlier: { summary: "Terminer plus tôt une campagne en cours", value: { endsAt: "2027-02-12T00:00:00+01:00" } },
      },
    },
    success: { status: 200, description: "La campagne mise à jour.", schema: campaignDto, enveloped: true, example: campaignExample },
    errors: [
      INVALID_BODY,
      { status: 400, code: "invalid_campaign", message: "endsAt must be after startsAt", description: "Une règle métier de la campagne n'est pas respectée." },
      CAMPAIGN_NOT_FOUND,
      { status: 409, code: "campaign_not_editable", message: "A live campaign can only be ended earlier or cancelled", description: "Cette modification n'est pas permise dans l'état actuel de la campagne." },
      ...staffErrors,
    ],
  },
  {
    operationId: "storefrontPublishCampaign",
    method: "post",
    path: `${STAFF_BASE}/campaigns/{id}/publish`,
    tag: "Campagnes",
    summary: "Publier une campagne : codes Apple, promotion Stripe, programmation",
    description:
      "Rôle : super-administrateur seulement (permission storefront.stores). Pour chaque abonnement ciblé, crée un code d'offre Apple avec un code personnalisé (VALENTIN27), " +
      "et pour chaque produit vendu sur le web une promotion Stripe (coupon et code promo, valable jusqu'à la fin) ; puis la campagne passe à scheduled. " +
      "Deux campagnes programmées ne se chevauchent jamais. Un échec Apple ou Stripe laisse un brouillon avec l'erreur enregistrée ; ce qui était déjà créé est réutilisé " +
      "à l'essai suivant. Effets de bord : appels aux stores, l'audit staff.",
    permission: "storefront.stores",
    parameters: [campaignIdParam],
    success: { status: 200, description: "La campagne programmée.", schema: campaignDto, enveloped: true, example: campaignExample },
    errors: [
      CAMPAIGN_NOT_FOUND,
      { status: 400, code: "invalid_campaign", message: "the campaign is already over", description: "La campagne est invalide ou déjà finie." },
      { status: 409, code: "campaign_overlap", message: "The campaign overlaps the scheduled campaign 7", description: "Une autre campagne programmée couvre une partie de la période." },
      { status: 409, code: "campaign_wrong_state", message: "Only a draft can be published (this one is scheduled)", description: "Seul un brouillon se publie." },
      STORE_NOT_CONFIGURED,
      STORE_ERROR,
      ...staffErrors,
    ],
  },
  {
    operationId: "storefrontCancelCampaign",
    method: "post",
    path: `${STAFF_BASE}/campaigns/{id}/cancel`,
    tag: "Campagnes",
    summary: "Annuler une campagne : désactiver les codes Apple et la promotion Stripe",
    description:
      "Rôle : super-administrateur seulement (permission storefront.stores). Désactive chez Apple et Stripe tout ce que la publication avait créé, puis marque la campagne cancelled ; " +
      "la vitrine et le paiement web cessent de l'appliquer aussitôt. Si un store refuse, la campagne reste telle quelle avec l'erreur enregistrée (réessayer, ou la terminer plus tôt) : " +
      "aucun code ne reste actif derrière une campagne annulée. Un brouillon sans code s'annule sans appeler les stores. Effets de bord : appels aux stores, l'audit staff.",
    permission: "storefront.stores",
    parameters: [campaignIdParam],
    success: { status: 200, description: "La campagne annulée.", schema: campaignDto, enveloped: true, example: campaignCancelledExample },
    errors: [
      CAMPAIGN_NOT_FOUND,
      { status: 409, code: "campaign_wrong_state", message: "A ended campaign cannot be cancelled", description: "Une campagne terminée ou déjà annulée ne s'annule pas." },
      STORE_NOT_CONFIGURED,
      STORE_ERROR,
      ...staffErrors,
    ],
  },
  {
    operationId: "storefrontOpenApi",
    method: "get",
    path: `${STAFF_BASE}/openapi.json`,
    tag: "Documentation",
    summary: "Ce document, au format OpenAPI",
    description:
      "Rôles : administrateur ou super-administrateur (permission storefront.manage). Absent en production (404) : la carte complète des routes d'administration " +
      "n'est pas distribuée. Le même fichier est versionné dans docs/api/storefront-openapi.json. Aucun effet de bord.",
    permission: "storefront.manage",
    parameters: [],
    success: { status: 200, description: "Le document OpenAPI 3.1.", schema: openApiDocument, enveloped: false, example: { openapi: "3.1.0", info: { title: "MAZL storefront", version: "1.0.0" }, paths: {} } },
    errors: [{ status: 404, code: "not_found", description: "Désactivé en production." }, ...staffErrors],
  },
];

export const honoPath = (path: string): string => path.replace(/\{(\w+)\}/g, ":$1");
