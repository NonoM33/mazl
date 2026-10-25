import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'discover_filters_api.dart';

/// Les filtres avancés de Découvrir. Remplacé par un faux dans les tests.
final discoverFiltersApiProvider = Provider<DiscoverFiltersApi>(
  (ref) => HttpDiscoverFiltersApi(),
);
