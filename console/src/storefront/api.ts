// Routes du back-office de la vitrine (docs/storefront/CONTRACT.md §5), relatives à la base du client d'API.
import type { ApiClient, ApiResult } from "../shared/api/client";
import type {
  ApplePriceBody,
  ApplePricePlanDto,
  CampaignDto,
  CampaignInput,
  CampaignListDto,
  PresetListDto,
  PricePointsDto,
  ProductDto,
  ProductPatch,
  ProductsDto,
  WebPriceBody,
  WebPriceDto,
} from "./types";

/** Préfixe commun des routes de la vitrine. */
export const STOREFRONT_PATH = "/storefront";

export interface StorefrontApi {
  products(): Promise<ApiResult<ProductsDto>>;
  patchProduct(productId: string, patch: ProductPatch): Promise<ApiResult<ProductDto>>;
  applePricePoints(productId: string, territory: string): Promise<ApiResult<PricePointsDto>>;
  applePrice(productId: string, body: ApplePriceBody): Promise<ApiResult<ApplePricePlanDto>>;
  webPrice(productId: string, body: WebPriceBody): Promise<ApiResult<WebPriceDto>>;
  campaigns(year: number): Promise<ApiResult<CampaignListDto>>;
  presets(year: number): Promise<ApiResult<PresetListDto>>;
  createCampaign(input: CampaignInput): Promise<ApiResult<CampaignDto>>;
  updateCampaign(id: number, input: Partial<CampaignInput>): Promise<ApiResult<CampaignDto>>;
  publish(id: number): Promise<ApiResult<CampaignDto>>;
  cancel(id: number): Promise<ApiResult<CampaignDto>>;
}

export function storefrontApi(api: ApiClient): StorefrontApi {
  const base = STOREFRONT_PATH;
  const product = (productId: string): string => `${base}/products/${encodeURIComponent(productId)}`;
  return {
    products: () => api.get(`${base}/products`),
    patchProduct: (productId, patch) => api.patch(product(productId), patch),
    applePricePoints: (productId, territory) => api.get(`${product(productId)}/apple-price-points`, { territory }),
    applePrice: (productId, body) => api.post(`${product(productId)}/apple-price`, body),
    webPrice: (productId, body) => api.post(`${product(productId)}/web-price`, body),
    campaigns: (year) => api.get(`${base}/campaigns`, { year }),
    presets: (year) => api.get(`${base}/campaigns/presets`, { year }),
    createCampaign: (input) => api.post(`${base}/campaigns`, input),
    updateCampaign: (id, input) => api.patch(`${base}/campaigns/${id}`, input),
    publish: (id) => api.post(`${base}/campaigns/${id}/publish`),
    cancel: (id) => api.post(`${base}/campaigns/${id}/cancel`),
  };
}
