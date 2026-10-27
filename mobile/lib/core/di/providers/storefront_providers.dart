import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../storefront/app_icon_gateway.dart';
import '../../storefront/festive_icon.dart';
import '../../storefront/storefront_controller.dart';
import '../../storefront/storefront_models.dart';
import '../../storefront/storefront_repository.dart';

/// Overridden by a fake in tests.
final storefrontRepositoryProvider = Provider<StorefrontRepository>(
  (ref) => StorefrontRepository(
    remote: HttpStorefrontRemote(),
    cache: SharedPreferencesStorefrontCache(),
  ),
);

final storefrontControllerProvider =
    StateNotifierProvider<StorefrontController, StorefrontState>(
      (ref) => StorefrontController(ref.watch(storefrontRepositoryProvider)),
    );

/// The storefront as of now: no campaign and the default catalogue until the
/// server (or the answer kept on the phone) says otherwise.
final storefrontProvider = Provider<Storefront>(
  (ref) => ref.watch(storefrontControllerProvider).current,
);

final appIconGatewayProvider = Provider<AppIconGateway>(
  (ref) => platformAppIconGateway(),
);

final festiveIconApplierProvider = Provider<FestiveIconApplier>(
  (ref) => FestiveIconApplier(ref.watch(appIconGatewayProvider)),
);

final festiveIconSettingStoreProvider = Provider<FestiveIconSettingStore>(
  (ref) => SharedPreferencesFestiveIconSettingStore(),
);

/// Replaced in `main` by the setting read before `runApp`.
final savedFestiveIconEnabledProvider = Provider<bool>((ref) => true);

/// The « Icône des fêtes » setting.
final festiveIconEnabledProvider =
    StateNotifierProvider<FestiveIconSettingController, bool>(
      (ref) => FestiveIconSettingController(
        ref.watch(festiveIconSettingStoreProvider),
        initial: ref.watch(savedFestiveIconEnabledProvider),
      ),
    );
