import 'package:mazl/core/matching/discover_filters.dart';
import 'package:mazl/core/matching/discover_filters_api.dart';
import 'package:mazl/core/services/api_service.dart';

/// In-memory server of the Discover filters: a save changes what the next
/// load returns, unless a refusal was queued.
class FakeDiscoverFiltersApi implements DiscoverFiltersApi {
  FakeDiscoverFiltersApi({
    this.plus = true,
    this.filters = DiscoverFilters.none,
  });

  bool plus;
  DiscoverFilters filters;
  bool failLoad = false;

  /// Answers handed to the next saves, in order; once empty a save succeeds.
  final refusals = <ApiResponse<DiscoverFilters>>[];
  final saved = <DiscoverFilters>[];
  int loads = 0;

  @override
  Future<ApiResponse<DiscoverFiltersState>> load() async {
    loads++;
    if (failLoad) return ApiResponse.failure('network', ApiErrorKind.network);
    return ApiResponse.success(
      DiscoverFiltersState(filters: filters, plus: plus),
    );
  }

  @override
  Future<ApiResponse<DiscoverFilters>> save(DiscoverFilters next) async {
    saved.add(next);
    if (refusals.isNotEmpty) return refusals.removeAt(0);
    filters = next;
    return ApiResponse.success(next);
  }
}

ApiResponse<DiscoverFilters> plusRequired() => ApiResponse(
  success: false,
  error: 'Discover filters (HTTP 402)',
  errorKind: ApiErrorKind.creditsExhausted,
  errorCode: DiscoverFiltersError.plusRequired,
  statusCode: 402,
);

ApiResponse<DiscoverFilters> consentRequired() => ApiResponse(
  success: false,
  error: 'Discover filters (HTTP 409)',
  errorKind: ApiErrorKind.conflict,
  errorCode: DiscoverFiltersError.religiousConsentRequired,
  statusCode: 409,
);
