import '_json_parsing.dart';
import 'relationship_intention.dart';

/// Profile model
class Profile {
  final int id;
  final int userId;
  final String? displayName;
  final int? age;
  final String? gender;
  final String? bio;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? denomination;
  final String? kashrut;
  final String? shabbatObservance;
  final String? relationshipIntention;
  final List<String> photos;
  final bool isVerified;
  final bool photoVerified;
  final bool identityVerified;
  final String? verificationLevel;
  final double? distance;
  final int? ageMin;
  final int? ageMax;
  final int? distanceMax;
  final String? lookingFor;

  /// This member sent the signed-in member a Super Like (Discover only).
  final bool superLikedYou;

  /// The word that came with that Super Like (1 to 140 characters).
  final String? superLikeNote;

  /// The city this member is passing through with a mazl+ passport.
  final String? travelingCity;

  Profile({
    required this.id,
    required this.userId,
    this.displayName,
    this.age,
    this.gender,
    this.bio,
    this.location,
    this.latitude,
    this.longitude,
    this.denomination,
    this.kashrut,
    this.shabbatObservance,
    this.relationshipIntention,
    this.photos = const [],
    this.isVerified = false,
    this.photoVerified = false,
    this.identityVerified = false,
    this.verificationLevel,
    this.distance,
    this.ageMin,
    this.ageMax,
    this.distanceMax,
    this.lookingFor,
    this.superLikedYou = false,
    this.superLikeNote,
    this.travelingCity,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: parseIntSafe(json['id']) ?? 0,
      userId: parseIntSafe(json['user_id']) ?? 0,
      displayName: json['display_name'] as String?,
      age: parseIntSafe(json['age']),
      gender: json['gender'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      latitude: parseDoubleSafe(json['latitude']),
      longitude: parseDoubleSafe(json['longitude']),
      denomination: json['denomination'] as String?,
      kashrut: json['kashrut_level'] as String?,
      shabbatObservance: json['shabbat_observance'] as String?,
      relationshipIntention: _intentionOf(json['relationship_intention']),
      photos: (json['photos'] as List<dynamic>?)?.cast<String>() ?? [],
      isVerified: json['is_verified'] == true,
      photoVerified: json['photo_verified'] == true,
      identityVerified: json['identity_verified'] == true,
      verificationLevel: json['verification_level'] as String?,
      distance: parseDoubleSafe(json['distance']),
      ageMin: parseIntSafe(json['age_min']),
      ageMax: parseIntSafe(json['age_max']),
      distanceMax: parseIntSafe(json['distance_max']),
      lookingFor: json['looking_for'] as String?,
      superLikedYou: json['super_liked_you'] == true,
      superLikeNote: _textOf(json['super_like_note']),
      travelingCity: _textOf(json['traveling_city']),
    );
  }
}

/// A text field of the server, null when absent, not a string or blank.
String? _textOf(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value.trim();
}

/// The intention as the server words it. A profile stored before the v1 holds
/// the French word the sign-up wrote (« Mariage »): it is read as the server
/// value, so the profile can be edited and saved back without a 400. A value
/// with no server word (« Je ne sais pas ») stays as it was stored.
String? _intentionOf(Object? stored) {
  if (stored is! String) return null;
  return RelationshipIntention.fromStored(stored)?.apiValue ?? stored;
}

/// Current user profile with more details
class UserProfile {
  final int id;
  final String email;
  final String? name;
  final String? picture;
  final Profile? profile;

  UserProfile({
    required this.id,
    required this.email,
    this.name,
    this.picture,
    this.profile,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: parseIntSafe(json['id']) ?? 0,
      email: json['email'] as String,
      name: json['name'] as String?,
      picture: json['picture'] as String?,
      profile: json['profile'] != null ? Profile.fromJson(json['profile']) : null,
    );
  }
}

/// Profile photo model
class ProfilePhoto {
  final int id;
  final String url;
  final int position;
  final bool isPrimary;
  final DateTime? createdAt;

  ProfilePhoto({
    required this.id,
    required this.url,
    required this.position,
    this.isPrimary = false,
    this.createdAt,
  });

  factory ProfilePhoto.fromJson(Map<String, dynamic> json) {
    return ProfilePhoto(
      id: parseIntSafe(json['id']) ?? 0,
      url: json['url'] as String,
      position: parseIntSafe(json['position']) ?? 0,
      isPrimary: json['is_primary'] == true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }
}
