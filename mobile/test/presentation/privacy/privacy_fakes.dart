import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazl/core/di/providers/privacy_providers.dart';
import 'package:mazl/core/privacy/privacy_consent_api.dart';
import 'package:mazl/core/privacy/religious_data_consent.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/l10n/l10n.dart';

const consentText = 'Je consens au traitement de ma pratique religieuse.';

/// In-memory server: a PUT changes what the next GET returns.
class FakePrivacyConsentApi implements PrivacyConsentApi {
  FakePrivacyConsentApi({this.granted, this.version});

  bool? granted;
  String? version;
  bool failFetch = false;
  bool failDecide = false;
  final calls = <String>[];

  @override
  Future<ApiResponse<ReligiousDataConsent>> religiousData() async {
    calls.add('get');
    if (failFetch) return ApiResponse.failure('network', ApiErrorKind.network);
    return ApiResponse.success(
      ReligiousDataConsent(
        granted: granted,
        version: version,
        decidedAt: null,
        currentVersion: '2026-10-24',
        text: consentText,
      ),
    );
  }

  @override
  Future<ApiResponse<void>> decideReligiousData({
    required bool granted,
    required String version,
  }) async {
    calls.add('put:$granted:$version');
    if (failDecide) return ApiResponse.failure('boom', ApiErrorKind.server);
    this.granted = granted;
    this.version = version;
    return ApiResponse<void>.success(null);
  }
}

Widget host(FakePrivacyConsentApi api, Widget child) => ProviderScope(
  overrides: [privacyConsentApiProvider.overrideWithValue(api)],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('fr'),
    home: Scaffold(body: child),
  ),
);
