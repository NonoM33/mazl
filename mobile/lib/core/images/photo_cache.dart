import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

/// Le cache disque des photos : 500 objets, 30 jours. Dédié, pour qu'il ne soit
/// jamais vidé par un autre usage du cache par défaut.
class MazlPhotoCache {
  const MazlPhotoCache._();

  static const String storeKey = 'mazlPhotos';
  static const int maxObjects = 500;
  static const Duration stalePeriod = Duration(days: 30);

  static CacheManager? _override;
  static CacheManager? _manager;

  /// Le gestionnaire utilisé partout. Créé à la demande : un test qui ne charge
  /// aucune photo ne touche jamais au système de fichiers.
  static CacheManager get manager => _override ?? (_manager ??= _build());

  static CacheManager _build() => CacheManager(
    Config(storeKey, stalePeriod: stalePeriod, maxNrOfCacheObjects: maxObjects),
  );

  @visibleForTesting
  static set debugManager(CacheManager? value) => _override = value;

  /// Vide le cache disque (déconnexion, changement de compte).
  static Future<void> clear() async {
    try {
      // Sans dossier temporaire (test sans plugin), il n'y a rien à vider, et
      // construire le gestionnaire échouerait hors de ce try.
      if (_override == null && _manager == null) await getTemporaryDirectory();
      await manager.emptyCache();
    } on Object catch (error) {
      debugPrint('MazlPhotoCache: purge impossible ($error)');
    }
    MazlImageSeen.clear();
  }
}

/// La clé de cache d'une photo. L'API signe chaque photo (`?exp=…&sig=…`) :
/// deux réponses donnent deux URL pour la même image. L'identité d'une photo
/// est son chemin `/media/photos/<id>` (ou `/media/chat/<id>`), jamais sa
/// signature. Pour une adresse externe (Unsplash…), les paramètres décident de
/// la taille : on garde l'adresse complète, ordre des paramètres normalisé.
String photoCacheKey(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasAuthority) return url;
  if (uri.path.startsWith('/media/photos/') ||
      uri.path.startsWith('/media/chat/')) {
    return '${uri.scheme}://${uri.authority}${uri.path}';
  }
  if (uri.queryParameters.isEmpty) return url;
  final names = uri.queryParameters.keys.toList()..sort();
  final query = [
    for (final name in names)
      '$name=${Uri.encodeQueryComponent(uri.queryParameters[name]!)}',
  ].join('&');
  return uri.replace(query: query).toString();
}

/// Les clés de photos déjà affichées pendant cette session : une image revue
/// (même chargée du disque) apparaît d'un coup, sans refondu.
class MazlImageSeen {
  const MazlImageSeen._();

  static final Set<String> _keys = <String>{};

  static bool contains(String key) => _keys.contains(key);
  static void add(String key) => _keys.add(key);
  static void clear() => _keys.clear();
}

/// Arrondit une taille en pixels au multiple de 64 supérieur : le cache mémoire
/// n'a pas une entrée par pixel de mise en page (pliage du Duo, rotation).
int bucketedPixels(double logical, double devicePixelRatio) {
  final pixels = logical * devicePixelRatio;
  return ((pixels / 64).ceil() * 64).clamp(64, 2048);
}

/// Remplace le réseau dans les tests.
@visibleForTesting
ImageProvider<Object> Function(String url, int? cacheWidth)? debugImageProvider;

/// Le fournisseur d'image de toute l'app : clé stable, cache dédié, décodage à
/// la taille d'affichage (largeur en pixels, la hauteur suit le ratio).
ImageProvider<Object> mazlImageProvider(String url, {int? cacheWidth}) {
  final override = debugImageProvider;
  if (override != null) return override(url, cacheWidth);
  final base = CachedNetworkImageProvider(
    url,
    cacheKey: photoCacheKey(url),
    cacheManager: MazlPhotoCache.manager,
  );
  return cacheWidth == null
      ? base
      : ResizeImage(base, width: cacheWidth, allowUpscaling: false);
}

/// Charge d'avance les photos [urls] (cartes suivantes de Découverte, profils
/// ouverts) : disque d'abord, puis mémoire à la taille [logicalWidth].
Future<void> precachePhotos(
  BuildContext context,
  Iterable<String?> urls, {
  double? logicalWidth,
}) async {
  final dpr = MediaQuery.devicePixelRatioOf(context);
  final width = logicalWidth == null ? null : bucketedPixels(logicalWidth, dpr);
  for (final url in urls) {
    if (url == null || !url.startsWith('http')) continue;
    if (!context.mounted) return;
    try {
      await precacheImage(mazlImageProvider(url, cacheWidth: width), context);
    } on Object catch (error) {
      debugPrint('precachePhotos: $error');
    }
  }
}

/// Remplace la recherche de vignette dans les tests.
@visibleForTesting
Future<ImageProvider<Object>?> Function(String cacheKey)? debugThumbnailLookup;

/// Une petite version de la photo [cacheKey] si le cache disque l'a déjà (vue
/// plus tôt), sinon `null`.
Future<ImageProvider<Object>?> cachedThumbnail(String cacheKey) async {
  final override = debugThumbnailLookup;
  if (override != null) return override(cacheKey);
  try {
    final info = await MazlPhotoCache.manager.getFileFromCache(cacheKey);
    final file = info?.file;
    if (file == null) return null;
    return ResizeImage(FileImage(file), width: 32);
  } on Object {
    return null;
  }
}
