import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import '../models/course_model_complete.dart';
import '../models/user_model.dart';

/// Service de gestion de la localisation avec flutter_osm_plugin
class LocationService {
  static const String nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static const int searchLimit = 10;

  // Controller optionnel pour les opérations nécessitant un MapController
  MapController? _mapController;

  LocationService({MapController? mapController})
      : _mapController = mapController;

  /// Vérifie si les permissions de localisation sont accordées
  Future<bool> checkLocationPermission() async {
    try {
      // Vérifier le statut actuel de la permission
      PermissionStatus status = await Permission.location.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        // Demander la permission
        status = await Permission.location.request();
        return status.isGranted;
      }

      if (status.isPermanentlyDenied) {
        // L'utilisateur a refusé définitivement, ouvrir les paramètres
        return false;
      }

      return false;
    } catch (e) {
      print('Erreur vérification permission: $e');
      return false;
    }
  }

  /// Vérifie si le service de localisation est activé
  Future<bool> isLocationServiceEnabled() async {
    try {
      final status = await Permission.location.serviceStatus;
      return status.isEnabled;
    } catch (e) {
      print('Erreur vérification service: $e');
      return false;
    }
  }

  /// Obtient la position actuelle en utilisant MapController
  /// Note: Nécessite un MapController initialisé
  Future<GeoPoint?> getCurrentPosition() async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        throw Exception('Permission de localisation refusée');
      }

      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Service de localisation désactivé');
      }

      // Si un MapController est disponible, l'utiliser pour obtenir la position
      if (_mapController != null) {
        try {
          final position = await _mapController!.myLocation();
          return position;
        } catch (e) {
          print('Erreur obtention position via MapController: $e');
          return null;
        }
      } else {
        print('MapController non disponible pour obtenir la position');
        return null;
      }
    } catch (e) {
      print('Erreur obtention position: $e');
      return null;
    }
  }

  /// Obtient la localisation actuelle pour un cours
  Future<CourseLocation?> getCurrentCourseLocation() async {
    try {
      final position = await getCurrentPosition();
      if (position == null) return null;

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        return CourseLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          address: 'Position actuelle',
        );
      }

      final place = placemarks.first;
      final address = [
        place.street,
        place.postalCode,
        place.locality,
      ].where((e) => e != null && e.isNotEmpty).join(', ');

      return CourseLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address.isNotEmpty ? address : 'Position actuelle',
        city: place.locality,
        country: place.country,
      );
    } catch (e) {
      print('Erreur obtention localisation cours: $e');
      return null;
    }
  }

  /// Obtient la localisation actuelle pour un utilisateur
  Future<AppLocation?> getCurrentUserLocation() async {
    try {
      final position = await getCurrentPosition();
      if (position == null) return null;

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        return AppLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          address: 'Position actuelle',
        );
      }

      final place = placemarks.first;
      final address = [
        place.street,
        place.postalCode,
        place.locality,
      ].where((e) => e != null && e.isNotEmpty).join(', ');

      return AppLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address.isNotEmpty ? address : 'Position actuelle',
        city: place.locality,
        country: place.country,
      );
    } catch (e) {
      print('Erreur obtention localisation utilisateur: $e');
      return null;
    }
  }

  /// Recherche une localisation par requête texte via Nominatim
  Future<List<LocationSearchResult>> searchLocation(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final url = Uri.parse(
        '$nominatimBaseUrl/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=$searchLimit',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'HospitalDZApp/1.0',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => LocationSearchResult.fromJson(json)).toList();
      } else {
        throw Exception(
            'Erreur recherche localisation: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur recherche OSM: $e');
      return [];
    }
  }

  /// Convertit un résultat de recherche en CourseLocation
  Future<CourseLocation> convertSearchResultToCourseLocation(
    LocationSearchResult result,
  ) async {
    return CourseLocation(
      latitude: result.latitude,
      longitude: result.longitude,
      address: result.displayName,
      city: result.city,
      country: result.country,
    );
  }

  /// Convertit un résultat de recherche en AppLocation
  Future<AppLocation> convertSearchResultToAppLocation(
    LocationSearchResult result,
  ) async {
    return AppLocation(
      latitude: result.latitude,
      longitude: result.longitude,
      address: result.displayName,
      city: result.city,
      country: result.country,
    );
  }

  /// Obtient l'adresse à partir de coordonnées (géocodage inverse)
  Future<String> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) {
        return '$latitude, $longitude';
      }

      final place = placemarks.first;
      return [
        place.street,
        place.postalCode,
        place.locality,
        place.country,
      ].where((e) => e != null && e.isNotEmpty).join(', ');
    } catch (e) {
      print('Erreur géocodage inverse: $e');
      return '$latitude, $longitude';
    }
  }

  /// Calcule la distance entre deux points en kilomètres (Formule de Haversine)
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Rayon de la Terre en km

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

  /// Calcule la distance entre deux GeoPoints
  double calculateDistanceGeoPoint(GeoPoint point1, GeoPoint point2) {
    return calculateDistance(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  /// Convertit des degrés en radians
  double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  /// Trie les cours par distance par rapport à une position utilisateur
  Future<List<CourseModel>> sortCoursesByDistance(
    List<CourseModel> courses,
    double userLat,
    double userLon,
  ) async {
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
        (a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

    return coursesWithDistance
        .map((item) => item['course'] as CourseModel)
        .toList();
  }

  /// Filtre les cours dans un rayon donné
  Future<List<CourseModel>> filterCoursesByRadius(
    List<CourseModel> courses,
    double centerLat,
    double centerLon,
    double radiusKm,
  ) async {
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

  /// Formate une distance pour l'affichage
  String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceKm.round()} km';
    }
  }

  /// Ouvre les paramètres de l'application pour activer les permissions
  Future<void> openLocationSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      print('Erreur ouverture paramètres: $e');
    }
  }

  /// Stream de position (nécessite un MapController avec tracking activé)
  /// Note: Cette fonctionnalité doit être configurée dans le widget OSMFlutter
  /// avec userTrackingOption.enableTracking = true
  Stream<GeoPoint> getPositionStream() {
    throw UnimplementedError(
        'Le tracking de position doit être configuré dans OSMFlutter avec '
        'userTrackingOption.enableTracking = true et utiliser le callback onLocationChanged');
  }

  /// Définit le MapController à utiliser
  void setMapController(MapController controller) {
    _mapController = controller;
  }

  /// Vérifie si le MapController est disponible
  bool get hasMapController => _mapController != null;
}
