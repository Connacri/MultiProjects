import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import '../models/course_model_complete.dart';
import '../models/user_model.dart';

/// Service de localisation ULTRA-SIMPLIFIÉ pour Windows
/// Stratégie : API IP-based (ipapi.co) + Fallback position par défaut
class LocationService {
  static const String nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static const int searchLimit = 10;

  // Position par défaut : Mascara, Algérie
  static const double defaultLatitude = 35.3967;
  static const double defaultLongitude = 0.1403;
  static const String defaultAddress = 'Mascara, Algérie';
  static const String defaultCity = 'Mascara';
  static const String defaultCountry = 'Algérie';

  MapController? _mapController;

  LocationService({MapController? mapController})
      : _mapController = mapController;

  /// ============================================================================
  /// GESTION DES PERMISSIONS (Android/iOS uniquement)
  /// ============================================================================

  Future<bool> checkLocationPermission() async {
    // Sur Windows, on skip complètement les permissions
    if (!kIsWeb && Platform.isWindows) {
      return true;
    }

    try {
      PermissionStatus status = await Permission.location.status;

      if (status.isGranted) return true;

      if (status.isDenied) {
        status = await Permission.location.request();
        return status.isGranted;
      }

      return false;
    } catch (e) {
      print('⚠️ [LocationService] Erreur permission: $e');
      return !kIsWeb && Platform.isWindows;
    }
  }

  Future<bool> isLocationServiceEnabled() async {
    if (!kIsWeb && Platform.isWindows) {
      return true;
    }

    try {
      final status = await Permission.location.serviceStatus;
      return status.isEnabled;
    } catch (e) {
      return !kIsWeb && Platform.isWindows;
    }
  }

  /// ============================================================================
  /// OBTENTION DE LA POSITION - VERSION SIMPLIFIÉE WINDOWS
  /// ============================================================================

  Future<GeoPoint?> getCurrentPosition() async {
    print('🔍 [LocationService] getCurrentPosition - DÉBUT');

    // ========================================================================
    // SUR WINDOWS : Utiliser UNIQUEMENT la géolocalisation IP
    // ========================================================================
    if (!kIsWeb && Platform.isWindows) {
      print('💻 [LocationService] Windows détecté - Géolocalisation IP');

      // Essayer ipapi.co (gratuit, sans clé API)
      final ipPosition = await _getPositionFromIPApi();
      if (ipPosition != null) {
        print('✅ [LocationService] Position IP obtenue: ${ipPosition
            .latitude}, ${ipPosition.longitude}');
        return ipPosition;
      }

      // Fallback : Position par défaut
      print(
          '⚠️ [LocationService] Géolocalisation IP échouée, position par défaut');
      return GeoPoint(latitude: defaultLatitude, longitude: defaultLongitude);
    }

    // ========================================================================
    // SUR ANDROID/IOS : Utiliser Geolocator classique
    // ========================================================================
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        print('❌ [LocationService] Permission refusée');
        return null;
      }

      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ [LocationService] Service désactivé');
        return null;
      }

      // Essayer MapController si disponible
      if (_mapController != null) {
        try {
          final position = await _mapController!.myLocation();
          print('✅ [LocationService] Position via MapController');
          return position;
        } catch (e) {
          print('⚠️ [LocationService] MapController échoué: $e');
        }
      }

      // Fallback : Geolocator
      return await _getPositionUsingGeolocator();
    } catch (e) {
      print('❌ [LocationService] Erreur: $e');
      return null;
    }
  }

  /// NOUVELLE MÉTHODE : Géolocalisation via IP (ipapi.co - 100% gratuit)
  Future<GeoPoint?> _getPositionFromIPApi() async {
    print('🌐 [LocationService] Géolocalisation IP en cours...');

    try {
      // API ipapi.co : 1000 requêtes/jour gratuites, pas de clé nécessaire
      final url = Uri.parse('https://ipapi.co/json/');

      final response = await http.get(url).timeout(
        const Duration(seconds: 6),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final latitude = data['latitude'] as double?;
        final longitude = data['longitude'] as double?;
        final city = data['city'] as String?;
        final country = data['country_name'] as String?;

        if (latitude != null && longitude != null) {
          print('✅ [IP] Position: $latitude, $longitude');
          print('📍 [IP] Lieu: $city, $country');

          return GeoPoint(latitude: latitude, longitude: longitude);
        }
      } else {
        print('⚠️ [IP] Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [IP] Erreur: $e');
    }

    // Fallback : Essayer une API alternative (ip-api.com)
    try {
      print('🌐 [LocationService] Tentative API alternative...');
      final url = Uri.parse('http://ip-api.com/json/');

      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          final latitude = data['lat'] as double?;
          final longitude = data['lon'] as double?;

          if (latitude != null && longitude != null) {
            print('✅ [IP-API] Position: $latitude, $longitude');
            return GeoPoint(latitude: latitude, longitude: longitude);
          }
        }
      }
    } catch (e) {
      print('❌ [IP-API] Erreur: $e');
    }

    return null;
  }

  /// Geolocator pour Android/iOS uniquement
  Future<GeoPoint?> _getPositionUsingGeolocator() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).timeout(const Duration(seconds: 8));

      print('✅ [Geolocator] Position: ${position.latitude}, ${position
          .longitude}');

      return GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      print('❌ [Geolocator] Erreur: $e');
      return null;
    }
  }

  /// ============================================================================
  /// GÉOCODAGE INVERSE (Toujours via Nominatim HTTP)
  /// ============================================================================

  Future<String> getAddressFromCoordinates(double latitude,
      double longitude,) async {
    print('🔍 [LocationService] Géocodage inverse: $latitude, $longitude');

    // Essayer Nominatim (fonctionne sur TOUTES les plateformes)
    try {
      final address = await _getAddressFromNominatim(latitude, longitude);
      if (address != null) {
        print('✅ [Nominatim] Adresse: $address');
        return address;
      }
    } catch (e) {
      print('⚠️ [Nominatim] Erreur: $e');
    }

    // Fallback : Coordonnées formatées
    return _formatCoordinates(latitude, longitude);
  }

  Future<String?> _getAddressFromNominatim(double latitude,
      double longitude,) async {
    try {
      final url = Uri.parse(
        '$nominatimBaseUrl/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'HospitalDZApp/1.0'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['display_name'] != null) {
          return data['display_name'] as String;
        }

        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final addressParts = <String>[];

          if (address['road'] != null) addressParts.add(address['road']);
          if (address['postcode'] != null) addressParts.add(
              address['postcode']);
          if (address['city'] != null) addressParts.add(address['city']);
          if (address['town'] != null) addressParts.add(address['town']);
          if (address['village'] != null) addressParts.add(address['village']);

          if (addressParts.isNotEmpty) {
            return addressParts.join(', ');
          }
        }
      }

      return null;
    } catch (e) {
      print('❌ [Nominatim] Erreur: $e');
      return null;
    }
  }

  String _formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  /// ============================================================================
  /// MÉTHODES POUR CourseLocation et AppLocation
  /// ============================================================================

  Future<CourseLocation?> getCurrentCourseLocation() async {
    print('🔍 [LocationService] getCurrentCourseLocation - DÉBUT');

    try {
      final position = await getCurrentPosition();

      if (position == null) {
        print(
            '⚠️ [LocationService] Position NULL - Retour position par défaut');

        // Retourner position par défaut au lieu de null
        return CourseLocation(
          latitude: defaultLatitude,
          longitude: defaultLongitude,
          address: defaultAddress,
          city: defaultCity,
          country: defaultCountry,
        );
      }

      print(
          '✅ [LocationService] Position reçue: ${position.latitude}, ${position
              .longitude}');

      final address = await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String? city;
      String? country;

      if (!address.contains(',') || address.contains('°')) {
        city = null;
        country = null;
      } else {
        final parts = address.split(',').map((e) => e.trim()).toList();
        if (parts.length >= 2) {
          city = parts[parts.length - 2];
          country = parts[parts.length - 1];
        }
      }

      final courseLocation = CourseLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        city: city,
        country: country,
      );

      print('✅ [LocationService] CourseLocation créé avec succès');
      return courseLocation;
    } catch (e, stackTrace) {
      print('❌ [LocationService] ERREUR: $e');
      print('❌ [LocationService] StackTrace: $stackTrace');

      // En cas d'erreur, retourner position par défaut
      return CourseLocation(
        latitude: defaultLatitude,
        longitude: defaultLongitude,
        address: defaultAddress,
        city: defaultCity,
        country: defaultCountry,
      );
    }
  }

  Future<AppLocation?> getCurrentUserLocation() async {
    print('🔍 [LocationService] getCurrentUserLocation - DÉBUT');

    try {
      final position = await getCurrentPosition();

      if (position == null) {
        print(
            '⚠️ [LocationService] Position NULL - Retour position par défaut');

        return AppLocation(
          latitude: defaultLatitude,
          longitude: defaultLongitude,
          address: defaultAddress,
          city: defaultCity,
          country: defaultCountry,
        );
      }

      final address = await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String? city;
      String? country;

      if (!address.contains(',') || address.contains('°')) {
        city = null;
        country = null;
      } else {
        final parts = address.split(',').map((e) => e.trim()).toList();
        if (parts.length >= 2) {
          city = parts[parts.length - 2];
          country = parts[parts.length - 1];
        }
      }

      return AppLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        city: city,
        country: country,
      );
    } catch (e) {
      print('❌ [LocationService] ERREUR: $e');

      return AppLocation(
        latitude: defaultLatitude,
        longitude: defaultLongitude,
        address: defaultAddress,
        city: defaultCity,
        country: defaultCountry,
      );
    }
  }

  /// ============================================================================
  /// RECHERCHE DE LOCALISATION (Nominatim)
  /// ============================================================================

  Future<List<LocationSearchResult>> searchLocation(String query) async {
    print('🔍 [LocationService] searchLocation: "$query"');
    if (query
        .trim()
        .isEmpty) return [];

    try {
      final url = Uri.parse(
        '$nominatimBaseUrl/search?q=${Uri.encodeComponent(
            query)}&format=json&addressdetails=1&limit=$searchLimit',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'HospitalDZApp/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ [LocationService] ${data.length} résultats trouvés');
        return data.map((json) => LocationSearchResult.fromJson(json)).toList();
      } else {
        print('❌ [LocationService] Status code: ${response.statusCode}');
        throw Exception('Erreur recherche: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [LocationService] ERREUR searchLocation: $e');
      return [];
    }
  }

  /// ============================================================================
  /// CONVERSIONS
  /// ============================================================================

  Future<CourseLocation> convertSearchResultToCourseLocation(
      LocationSearchResult result,) async {
    return CourseLocation(
      latitude: result.latitude,
      longitude: result.longitude,
      address: result.displayName,
      city: result.city,
      country: result.country,
    );
  }

  Future<AppLocation> convertSearchResultToAppLocation(
      LocationSearchResult result,) async {
    return AppLocation(
      latitude: result.latitude,
      longitude: result.longitude,
      address: result.displayName,
      city: result.city,
      country: result.country,
    );
  }

  /// ============================================================================
  /// CALCULS DE DISTANCE
  /// ============================================================================

  double calculateDistance(double lat1,
      double lon1,
      double lat2,
      double lon2,) {
    const double earthRadius = 6371;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double calculateDistanceGeoPoint(GeoPoint point1, GeoPoint point2) {
    return calculateDistance(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  Future<List<CourseModel>> sortCoursesByDistance(List<CourseModel> courses,
      double userLat,
      double userLon,) async {
    final coursesWithDistance = courses.map((course) {
      final distance = calculateDistance(
        userLat,
        userLon,
        course.location.latitude,
        course.location.longitude,
      );
      return {'course': course, 'distance': distance};
    }).toList();

    coursesWithDistance.sort(
            (a, b) =>
            (a['distance'] as double).compareTo(b['distance'] as double));

    return coursesWithDistance
        .map((item) => item['course'] as CourseModel)
        .toList();
  }

  Future<List<CourseModel>> filterCoursesByRadius(List<CourseModel> courses,
      double centerLat,
      double centerLon,
      double radiusKm,) async {
    return courses.where((course) {
      final distance = calculateDistance(
        centerLat,
        centerLon,
        course.location.latitude,
        course.location.longitude,
      );
      return distance <= radiusKm;
    }).toList();
  }

  String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceKm.round()} km';
    }
  }

  /// ============================================================================
  /// UTILITAIRES
  /// ============================================================================

  Future<void> openLocationSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      print('❌ [LocationService] ERREUR openLocationSettings: $e');
    }
  }

  void setMapController(MapController controller) {
    _mapController = controller;
  }

  bool get hasMapController => _mapController != null;
}

/// ============================================================================
/// MODÈLE POUR RÉSULTATS DE RECHERCHE
/// ============================================================================

class LocationSearchResult {
  final String displayName;
  final double latitude;
  final double longitude;
  final String? city;
  final String? country;

  LocationSearchResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.city,
    this.country,
  });

  factory LocationSearchResult.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>?;

    return LocationSearchResult(
      displayName: json['display_name'] as String,
      latitude: double.parse(json['lat'] as String),
      longitude: double.parse(json['lon'] as String),
      city: address?['city'] as String? ??
          address?['town'] as String? ??
          address?['village'] as String?,
      country: address?['country'] as String?,
    );
  }
}