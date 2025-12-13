// ============================================================================
// FICHIER: location_picker_dialog_windows.dart (VERSION CORRIGÉE)
// Version Windows Desktop compatible avec flutter_map
// Initialise automatiquement la carte sur la position actuelle
// Compatible avec flutter_map: ^4.0.0 à ^6.x (API stable)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/course_model_complete.dart';
import '../services/location_service_osm.dart';

/// Dialog de sélection de localisation compatible Windows Desktop
class LocationPickerDialogWindows extends StatefulWidget {
  final dynamic initialLocation; // Accepte AppLocation ou CourseLocation

  const LocationPickerDialogWindows({super.key, this.initialLocation});

  @override
  State<LocationPickerDialogWindows> createState() =>
      _LocationPickerDialogWindowsState();
}

class _LocationPickerDialogWindowsState
    extends State<LocationPickerDialogWindows> {
  late MapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  late LocationService _locationService;

  LatLng? _selectedPosition;
  String? _selectedAddress;
  List<LocationSearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingCurrentLocation = false;
  bool _initialLocationSet = false;

  // Marqueur de sélection
  final List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();

    _mapController = MapController();
    _locationService = LocationService();

    // Déterminer et configurer la position initiale
    if (widget.initialLocation != null) {
      _setupInitialLocation();
    } else {
      // Charger la position actuelle en mode création
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadCurrentLocation();
      });
    }
  }

  void _setupInitialLocation() {
    double lat, lon;
    String addr;

    // Support pour AppLocation et CourseLocation
    if (widget.initialLocation is CourseLocation) {
      final loc = widget.initialLocation as CourseLocation;
      lat = loc.latitude;
      lon = loc.longitude;
      addr = loc.address;
    } else {
      // Position par défaut si type inconnu
      lat = 35.3967;
      lon = 0.1403;
      addr = 'Position par défaut';
    }

    _selectedPosition = LatLng(lat, lon);
    _selectedAddress = addr;
    _initialLocationSet = true;
    _addMarkerAtPosition(_selectedPosition!);

    print('🔵 [LocationPickerWindows] Position initiale: $lat, $lon');

    // Centrer la carte après le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mapController.move(_selectedPosition!, 13.0);
        print('✅ [LocationPickerWindows] Carte centrée sur position initiale');
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    if (!mounted) return;

    print('🔵 [LocationPickerWindows] _loadCurrentLocation - DÉBUT');
    setState(() => _isLoadingCurrentLocation = true);

    try {
      final position = await _locationService.getCurrentPosition();

      if (position != null && mounted) {
        print('✅ [LocationPickerWindows] Position: ${position
            .latitude}, ${position.longitude}');

        final latLng = LatLng(position.latitude, position.longitude);

        setState(() {
          _selectedPosition = latLng;
        });

        // Centrer la carte et ajouter le marqueur
        _mapController.move(latLng, 15.0);
        _addMarkerAtPosition(latLng);

        // Récupérer l'adresse
        final address = await _locationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (mounted) {
          setState(() => _selectedAddress = address);
          print('✅ [LocationPickerWindows] Adresse: $address');
        }
      } else {
        print('⚠️ [LocationPickerWindows] Position NULL');

        // Position par défaut (Mascara, Algérie) si la géolocalisation échoue
        if (mounted) {
          final defaultPos = LatLng(35.3967, 0.1403);
          setState(() {
            _selectedPosition = defaultPos;
            _selectedAddress = 'Mascara, Algérie';
          });
          _mapController.move(defaultPos, 13.0);
          _addMarkerAtPosition(defaultPos);

          print('⚠️ [LocationPickerWindows] Utilisation position par défaut');
        }
      }
    } catch (e, stackTrace) {
      print('❌ [LocationPickerWindows] Erreur: $e');
      print('❌ [LocationPickerWindows] StackTrace: $stackTrace');

      // Position par défaut en cas d'erreur
      if (mounted) {
        final defaultPos = LatLng(35.3967, 0.1403);
        setState(() {
          _selectedPosition = defaultPos;
          _selectedAddress = 'Mascara, Algérie';
        });
        _mapController.move(defaultPos, 13.0);
        _addMarkerAtPosition(defaultPos);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingCurrentLocation = false);
      }
    }

    print('🔵 [LocationPickerWindows] _loadCurrentLocation - FIN');
  }

  Future<void> _searchLocation(String query) async {
    if (query
        .trim()
        .isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _locationService.searchLocation(query);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      print('❌ [LocationPickerWindows] Erreur recherche: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  void _selectSearchResult(LocationSearchResult result) {
    final latLng = LatLng(result.latitude, result.longitude);

    setState(() {
      _selectedPosition = latLng;
      _selectedAddress = result.displayName;
      _searchResults = [];
      _searchController.clear();
    });

    _mapController.move(latLng, 15.0);
    _addMarkerAtPosition(latLng);

    print('✅ [LocationPickerWindows] Résultat recherche sélectionné: ${result
        .displayName}');
  }

  Future<void> _onMapTap(TapPosition tapPosition, LatLng position) async {
    setState(() {
      _selectedPosition = position;
      _selectedAddress = null;
    });

    _addMarkerAtPosition(position);

    final address = await _locationService.getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (mounted) {
      setState(() => _selectedAddress = address);
    }
  }

  void _addMarkerAtPosition(LatLng position) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          point: position,
          width: 50,
          height: 50,
          builder: (context) =>
          const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 50,
          ),
        ),
      );
    });

    print('✅ [LocationPickerWindows] Marqueur ajouté: ${position
        .latitude}, ${position.longitude}');
  }

  void _confirmSelection() {
    if (_selectedPosition != null && _selectedAddress != null) {
      // Retourner CourseLocation pour compatibilité avec create_course_screen
      final location = CourseLocation(
        latitude: _selectedPosition!.latitude,
        longitude: _selectedPosition!.longitude,
        address: _selectedAddress!,
      );
      Navigator.pop(context, location);

      print(
          '✅ [LocationPickerWindows] Location confirmée: ${location.address}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery
        .of(context)
        .size;
    final isLargeScreen = size.width > 600;

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: isLargeScreen ? 800 : size.width * 0.9,
        height: isLargeScreen ? 600 : size.height * 0.8,
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchBar(),
            if (_searchResults.isNotEmpty) _buildSearchResults(),
            Expanded(child: _buildMap()),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme
            .of(context)
            .colorScheme
            .primaryContainer,
        border: Border(
          bottom: BorderSide(color: Theme
              .of(context)
              .dividerColor),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: Theme
                .of(context)
                .colorScheme
                .onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sélectionner une localisation',
                  style: Theme
                      .of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    color: Theme
                        .of(context)
                        .colorScheme
                        .onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedAddress != null)
                  Text(
                    _selectedAddress!,
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                      color:
                      Theme
                          .of(context)
                          .colorScheme
                          .onPrimaryContainer,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  if (_isLoadingCurrentLocation)
                    Text(
                      'Recherche de votre position...',
                      style: Theme
                          .of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                        color:
                        Theme
                            .of(context)
                            .colorScheme
                            .onPrimaryContainer,
                      ),
                    ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher une adresse...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
                    : (_searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchResults = []);
                  },
                )
                    : null),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                if (value.length >= 3) {
                  _searchLocation(value);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            icon: _isLoadingCurrentLocation
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.my_location),
            onPressed: _isLoadingCurrentLocation ? null : _loadCurrentLocation,
            tooltip: 'Ma position',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Theme
            .of(context)
            .colorScheme
            .surface,
        border: Border(
          bottom: BorderSide(color: Theme
              .of(context)
              .dividerColor),
        ),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final result = _searchResults[index];
          return ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(
              result.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _selectSearchResult(result),
          );
        },
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        // API flutter_map version stable
        center: _selectedPosition ?? LatLng(35.3967, 0.1403),
        zoom: 13.0,
        minZoom: 3.0,
        maxZoom: 19.0,
        onTap: _onMapTap,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.hospitaldz.app',
          maxZoom: 19,
        ),
        MarkerLayer(
          markers: _markers,
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme
            .of(context)
            .colorScheme
            .surface,
        border: Border(
          top: BorderSide(color: Theme
              .of(context)
              .dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Position sélectionnée',
                  style: Theme
                      .of(context)
                      .textTheme
                      .labelSmall,
                ),
                if (_selectedAddress != null)
                  Text(
                    _selectedAddress!,
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  if (_isLoadingCurrentLocation)
                    Text(
                      'Recherche de votre position...',
                      style: Theme
                          .of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                        color: Theme
                            .of(context)
                            .colorScheme
                            .secondary,
                      ),
                    )
                  else
                    Text(
                      'Cliquez sur la carte pour sélectionner',
                      style: Theme
                          .of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                        color: Theme
                            .of(context)
                            .colorScheme
                            .secondary,
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: _selectedPosition != null && _selectedAddress != null
                ? _confirmSelection
                : null,
            icon: const Icon(Icons.check),
            label: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}