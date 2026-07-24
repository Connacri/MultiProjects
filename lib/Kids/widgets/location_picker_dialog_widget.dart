// ============================================================================
// FICHIER: location_picker_dialog_widget.dart (VERSION CORRIGÉE)
// Utilise flutter_osm_plugin: ^1.4.3
// Initialise automatiquement la carte sur la position actuelle
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

import '../models/user_model.dart';
import '../services/location_service_osm.dart';

class LocationPickerDialog extends StatefulWidget {
  final AppLocation? initialLocation;

  const LocationPickerDialog({super.key, this.initialLocation});

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  late MapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  late LocationService _locationService;

  GeoPoint? _selectedPosition;
  String? _selectedAddress;
  List<LocationSearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingCurrentLocation = false;
  bool _mapReady = false;
  bool _initialLocationSet = false;

  @override
  void initState() {
    super.initState();

    GeoPoint initialPosition;

    // Déterminer la position initiale
    if (widget.initialLocation != null) {
      // Utiliser la location fournie
      initialPosition = GeoPoint(
        latitude: widget.initialLocation!.latitude,
        longitude: widget.initialLocation!.longitude,
      );
      _selectedPosition = initialPosition;
      _selectedAddress = widget.initialLocation!.address;
      _initialLocationSet = true;

      print(
          '🔵 [LocationPicker] Position initiale fournie: ${initialPosition.latitude}, ${initialPosition.longitude}');
    } else {
      // Position par défaut (Mascara, Algérie) - sera remplacée par la position actuelle
      initialPosition = GeoPoint(latitude: 35.3967, longitude: 0.1403);
      print('🔵 [LocationPicker] Position par défaut temporaire');
    }

    // Initialiser le contrôleur de carte
    _mapController = MapController(
      initPosition: initialPosition,
    );

    // Initialiser le service de localisation avec le controller
    _locationService = LocationService(mapController: _mapController);

    // Charger la position actuelle si pas de position initiale fournie
    if (widget.initialLocation == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadCurrentLocation();
      });
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    if (!mounted) return;

    print('🔵 [LocationPicker] _loadCurrentLocation - DÉBUT');
    setState(() => _isLoadingCurrentLocation = true);

    try {
      final position = await _locationService.getCurrentPosition();

      if (position != null && mounted) {
        print(
            '✅ [LocationPicker] Position obtenue: ${position.latitude}, ${position.longitude}');

        setState(() {
          _selectedPosition = position;
        });

        // Centrer la carte et ajouter le marqueur SEULEMENT si la carte est prête
        if (_mapReady) {
          await _centerMapAndAddMarker(position);
        }

        // Récupérer l'adresse
        final address = await _locationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (mounted) {
          setState(() => _selectedAddress = address);
          print('✅ [LocationPicker] Adresse: $address');
        }
      } else {
        print(
            '⚠️ [LocationPicker] Position NULL, utilisation position par défaut');
      }
    } catch (e, stackTrace) {
      print('❌ [LocationPicker] Erreur chargement position: $e');
      print('❌ [LocationPicker] StackTrace: $stackTrace');
    } finally {
      if (mounted) {
        setState(() => _isLoadingCurrentLocation = false);
      }
    }

    print('🔵 [LocationPicker] _loadCurrentLocation - FIN');
  }

  Future<void> _centerMapAndAddMarker(GeoPoint position) async {
    if (!_mapReady) return;

    try {
      print(
          '🔵 [LocationPicker] Centrage carte sur: ${position.latitude}, ${position.longitude}');

      await _mapController.changeLocation(position);
      await _mapController.setZoom(zoomLevel: 15);
      await _addMarkerAtPosition(position);

      print('✅ [LocationPicker] Carte centrée et marqueur ajouté');
    } catch (e) {
      print('❌ [LocationPicker] Erreur centrage carte: $e');
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
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
      print('❌ [LocationPicker] Erreur recherche: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _selectSearchResult(LocationSearchResult result) async {
    final geoPoint = GeoPoint(
      latitude: result.latitude,
      longitude: result.longitude,
    );

    setState(() {
      _selectedPosition = geoPoint;
      _selectedAddress = result.displayName;
      _searchResults = [];
      _searchController.clear();
    });

    if (_mapReady) {
      await _centerMapAndAddMarker(geoPoint);
    }
  }

  Future<void> _onMapTap(GeoPoint position) async {
    setState(() {
      _selectedPosition = position;
      _selectedAddress = null;
    });

    await _addMarkerAtPosition(position);

    final address = await _locationService.getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (mounted) {
      setState(() => _selectedAddress = address);
    }
  }

  Future<void> _addMarkerAtPosition(GeoPoint position) async {
    if (!_mapReady) return;

    try {
      // Supprimer tous les marqueurs existants
      try {
        await _mapController.removeMarker(position);
      } catch (e) {
        // Ignorer l'erreur si le marqueur n'existe pas
      }

      // Ajouter le nouveau marqueur
      await _mapController.addMarker(
        position,
        markerIcon: const MarkerIcon(
          icon: Icon(
            Icons.location_on,
            color: Colors.red,
            size: 56,
          ),
        ),
      );

      print(
          '✅ [LocationPicker] Marqueur ajouté à: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('❌ [LocationPicker] Erreur ajout marqueur: $e');
    }
  }

  void _confirmSelection() {
    if (_selectedPosition != null && _selectedAddress != null) {
      final location = AppLocation(
        latitude: _selectedPosition!.latitude,
        longitude: _selectedPosition!.longitude,
        address: _selectedAddress!,
      );
      Navigator.pop(context, location);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
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
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sélectionner une localisation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_selectedAddress != null)
                  Text(
                    _selectedAddress!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else if (_isLoadingCurrentLocation)
                  Text(
                    'Recherche de votre position...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
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
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
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
    return OSMFlutter(
      controller: _mapController,
      osmOption: OSMOption(
        zoomOption: const ZoomOption(
          initZoom: 13,
          minZoomLevel: 3,
          maxZoomLevel: 19,
          stepZoom: 1.0,
        ),
        userLocationMarker: UserLocationMaker(
          personMarker: const MarkerIcon(
            icon: Icon(
              Icons.location_history_rounded,
              color: Colors.blue,
              size: 48,
            ),
          ),
          directionArrowMarker: const MarkerIcon(
            icon: Icon(
              Icons.double_arrow,
              color: Colors.blue,
              size: 48,
            ),
          ),
        ),
        roadConfiguration: const RoadOption(
          roadColor: Colors.blue,
        ),
      ),
      onMapIsReady: (isReady) async {
        if (isReady && mounted) {
          print('✅ [LocationPicker] Carte prête');
          setState(() => _mapReady = true);

          // Si on a une position initiale fournie, ajouter le marqueur
          if (_initialLocationSet && _selectedPosition != null) {
            await _addMarkerAtPosition(_selectedPosition!);
            print('✅ [LocationPicker] Marqueur initial ajouté');
          }
          // Sinon, si on a déjà récupéré la position actuelle, centrer dessus
          else if (_selectedPosition != null && !_isLoadingCurrentLocation) {
            await _centerMapAndAddMarker(_selectedPosition!);
            print('✅ [LocationPicker] Carte centrée sur position actuelle');
          }
        }
      },
      onGeoPointClicked: (geoPoint) async {
        await _onMapTap(geoPoint);
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
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
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                if (_selectedAddress != null)
                  Text(
                    _selectedAddress!,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                else if (_isLoadingCurrentLocation)
                  Text(
                    'Recherche de votre position...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  )
                else
                  Text(
                    'Cliquez sur la carte pour sélectionner',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
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
