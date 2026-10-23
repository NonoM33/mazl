/// Données d'affichage d'un profil, déjà débarrassées de leur origine
/// (profil d'un autre ou le sien).
class ProfileViewData {
  const ProfileViewData({
    required this.name,
    required this.location,
    this.age,
    this.distance,
    this.bio,
    this.lookingFor,
    this.gender,
    this.denomination,
    this.kashrut,
    this.shabbatObservance,
    this.photos = const [],
    this.fallbackPicture,
    this.isVerified = false,
    this.verificationLevel,
  });

  final String name;
  final String location;
  final int? age;
  final double? distance;
  final String? bio;
  final String? lookingFor;
  final String? gender;
  final String? denomination;
  final String? kashrut;
  final String? shabbatObservance;
  final List<String> photos;

  /// Photo de connexion (SSO), utilisée quand aucune photo n'a été envoyée.
  final String? fallbackPicture;
  final bool isVerified;
  final String? verificationLevel;

  /// Premier mot du nom, pour « J'aime Sarah ».
  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.first.isEmpty ? 'cette personne' : parts.first;
  }

  /// « Paris · à 4 km ».
  String get metaLine {
    final parts = <String>[
      if (location.isNotEmpty) location,
      if (distance != null) _distanceLabel(distance!),
    ];
    return parts.join(' · ');
  }

  /// Photos à montrer dans la galerie, repli SSO compris.
  List<String> get galleryPhotos {
    if (photos.isNotEmpty) return photos;
    final fallback = fallbackPicture;
    return fallback == null ? const [] : [fallback];
  }

  /// Vrai quand la personne n'a envoyé aucune photo.
  bool get hasNoUploadedPhoto => photos.isEmpty;

  /// Lignes de « L'essentiel » : seuls les champs renseignés.
  List<ProfileFact> get facts {
    final genderLabel = switch (gender) {
      'male' => 'Homme',
      'female' => 'Femme',
      _ => null,
    };
    return [
      _fact('Pratique', denomination),
      _fact('Cacherout', kashrut),
      _fact('Shabbat', shabbatObservance),
      _fact('Genre', genderLabel),
    ].whereType<ProfileFact>().toList();
  }

  static ProfileFact? _fact(String label, String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : ProfileFact(label, trimmed);
  }

  static String _distanceLabel(double km) =>
      km < 1 ? 'à moins de 1 km' : 'à ${km.round()} km';
}

class ProfileFact {
  const ProfileFact(this.label, this.value);

  final String label;
  final String value;
}
