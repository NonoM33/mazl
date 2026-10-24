import '../../../../../l10n/l10n.dart';
import '../../l10n/profile_answer_labels.dart';

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
  /// `null` quand le membre n'a pas indiqué sa ville.
  final String? location;
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
  String firstName(AppLocalizations l10n) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.first.isEmpty ? l10n.profileThisPerson : parts.first;
  }

  /// « Paris · à 4 km ». Sans ville, le pays par défaut.
  String metaLine(AppLocalizations l10n) {
    final place = location ?? l10n.profileDefaultLocation;
    final parts = <String>[
      if (place.isNotEmpty) place,
      if (distance != null) _distanceLabel(l10n, distance!),
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
  List<ProfileFact> facts(AppLocalizations l10n) {
    final genderLabel = switch (gender) {
      'male' => l10n.profileGenderMale,
      'female' => l10n.profileGenderFemale,
      _ => null,
    };
    return [
      _fact(l10n.profileFactPractice, denominationFact(l10n, denomination)),
      _fact(l10n.profileFactKashrut, kashrutFact(l10n, kashrut)),
      _fact(l10n.profileShabbat, shabbatFact(l10n, shabbatObservance)),
      _fact(l10n.profileFactGender, genderLabel),
    ].whereType<ProfileFact>().toList();
  }

  static ProfileFact? _fact(String label, String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : ProfileFact(label, trimmed);
  }

  static String _distanceLabel(AppLocalizations l10n, double km) =>
      km < 1 ? l10n.profileDistanceUnderOneKm : l10n.profileDistanceKm(km.round());
}

class ProfileFact {
  const ProfileFact(this.label, this.value);

  final String label;
  final String value;
}
