import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Helper function for safe double parsing
double? _parseDoubleSafe(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// City suggestion from Places API
class CitySuggestion {
  final String placeId;
  final String city;
  final String? postalCode;
  final String displayName; // "City 12345" format
  final double? latitude;
  final double? longitude;

  CitySuggestion({
    required this.placeId,
    required this.city,
    this.postalCode,
    required this.displayName,
    this.latitude,
    this.longitude,
  });
}

/// Service for city autocomplete using Google Places API
class PlacesService {
  static final PlacesService _instance = PlacesService._internal();
  factory PlacesService() => _instance;
  PlacesService._internal();

  // Google Places API key - should be in environment config
  // For now we'll use the API.gouv.fr address API which is free and perfect for France
  static const String _apiGeoBaseUrl = 'https://api-adresse.data.gouv.fr';

  /// Search for cities based on user input
  /// Uses the French government address API (free, no key needed)
  Future<List<CitySuggestion>> searchCities(String query) async {
    if (query.trim().length < 2) {
      return [];
    }

    try {
      // Use the French address API to search for municipalities
      final url = Uri.parse(
        '$_apiGeoBaseUrl/search/?q=${Uri.encodeComponent(query)}&type=municipality&limit=5',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>? ?? [];

        return features.map((feature) {
          final properties = feature['properties'] as Map<String, dynamic>;
          final geometry = feature['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List<dynamic>;

          final city = properties['city'] as String? ?? properties['name'] as String? ?? '';
          final postalCode = properties['postcode'] as String?;

          return CitySuggestion(
            placeId: properties['id'] as String? ?? '',
            city: city,
            postalCode: postalCode,
            displayName: postalCode != null ? '$city $postalCode' : city,
            longitude: coordinates.isNotEmpty ? _parseDoubleSafe(coordinates[0]) : null,
            latitude: coordinates.length > 1 ? _parseDoubleSafe(coordinates[1]) : null,
          );
        }).toList();
      }

      return [];
    } catch (e) {
      debugPrint('PlacesService: Error searching cities: $e');
      return [];
    }
  }

  /// Search for addresses (full addresses, not just cities)
  /// This can be used later for more precise location features
  Future<List<CitySuggestion>> searchAddresses(String query) async {
    if (query.trim().length < 3) {
      return [];
    }

    try {
      final url = Uri.parse(
        '$_apiGeoBaseUrl/search/?q=${Uri.encodeComponent(query)}&limit=5',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>? ?? [];

        // Group by city to avoid showing full addresses
        // Only return city-level results
        final Map<String, CitySuggestion> citiesMap = {};

        for (final feature in features) {
          final properties = feature['properties'] as Map<String, dynamic>;
          final geometry = feature['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List<dynamic>;

          final city = properties['city'] as String?;
          if (city == null) continue;

          final postalCode = properties['postcode'] as String?;
          final key = '$city-$postalCode';

          if (!citiesMap.containsKey(key)) {
            citiesMap[key] = CitySuggestion(
              placeId: properties['id'] as String? ?? key,
              city: city,
              postalCode: postalCode,
              displayName: postalCode != null ? '$city $postalCode' : city,
              longitude: coordinates.isNotEmpty ? _parseDoubleSafe(coordinates[0]) : null,
              latitude: coordinates.length > 1 ? _parseDoubleSafe(coordinates[1]) : null,
            );
          }
        }

        return citiesMap.values.toList();
      }

      return [];
    } catch (e) {
      debugPrint('PlacesService: Error searching addresses: $e');
      return [];
    }
  }
}
