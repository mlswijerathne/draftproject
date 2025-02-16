import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class ResidentLocation extends StatefulWidget {
  const ResidentLocation({super.key});

  @override
  State<ResidentLocation> createState() => _ResidentLocationState();
}

class _ResidentLocationState extends State<ResidentLocation> {
  GoogleMapController? mapController;
  Position? currentPosition;
  Set<Marker> markers = {};
  Set<Polygon> zones = {};
  
  // Default position (Colombo, Sri Lanka)
  static const LatLng defaultLocation = LatLng(6.9271, 79.8612);
  bool isLoading = true;

  // Define zone colors with transparency
  static final colors = [
    Color(0x507B1FA2), // Purple zone
    Color(0x50388E3C), // Green zone
    Color(0x50F57C00), // Orange zone
  ];

  @override
  void initState() {
    super.initState();
    _checkPermissionAndGetLocation();
  }

  void _createZones() {
    if (currentPosition == null) return;

    // Create three zones around the current position
    final centerLat = currentPosition!.latitude;
    final centerLng = currentPosition!.longitude;
    
    // Define the zones with proper typing
    final List<Map<String, dynamic>> zoneDefinitions = [
      {
        'name': 'Zone A',
        'points': <LatLng>[
          LatLng(centerLat + 0.02, centerLng - 0.02),
          LatLng(centerLat + 0.02, centerLng + 0.02),
          LatLng(centerLat - 0.02, centerLng + 0.02),
          LatLng(centerLat - 0.02, centerLng - 0.02),
        ],
      },
      {
        'name': 'Zone B',
        'points': <LatLng>[
          LatLng(centerLat + 0.02, centerLng + 0.02),
          LatLng(centerLat + 0.02, centerLng + 0.06),
          LatLng(centerLat - 0.02, centerLng + 0.06),
          LatLng(centerLat - 0.02, centerLng + 0.02),
        ],
      },
      {
        'name': 'Zone C',
        'points': <LatLng>[
          LatLng(centerLat + 0.02, centerLng - 0.06),
          LatLng(centerLat + 0.02, centerLng - 0.02),
          LatLng(centerLat - 0.02, centerLng - 0.02),
          LatLng(centerLat - 0.02, centerLng - 0.06),
        ],
      },
    ];

    // Create polygons for each zone
    zones.clear();
    for (var i = 0; i < zoneDefinitions.length; i++) {
      final zone = zoneDefinitions[i];
      zones.add(
        Polygon(
          polygonId: PolygonId('zone_${i + 1}'),
          points: (zone['points'] as List<LatLng>),
          fillColor: colors[i],
          strokeColor: colors[i].withOpacity(0.8),
          strokeWidth: 2,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${zone['name'] as String} selected'),
                action: SnackBarAction(
                  label: 'View Schedule',
                  onPressed: () {
                    // Add schedule viewing functionality here
                    print('View schedule for ${zone['name'] as String}');
                  },
                ),
              ),
            );
          },
        ),
      );

      // Add a marker for the zone label
      markers.add(
        Marker(
          markerId: MarkerId('zone_marker_${i + 1}'),
          position: _getCenterOfPolygon(zone['points'] as List<LatLng>),
          infoWindow: InfoWindow(
            title: zone['name'] as String,
            snippet: 'Tap for collection schedule',
          ),
        ),
      );
    }

    setState(() {});
  }

  LatLng _getCenterOfPolygon(List<LatLng> points) {
    double latitude = 0;
    double longitude = 0;
    
    for (var point in points) {
      latitude += point.latitude;
      longitude += point.longitude;
    }
    
    return LatLng(
      latitude / points.length,
      longitude / points.length,
    );
  }

  Future<void> _checkPermissionAndGetLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => isLoading = false);
      _showErrorDialog('Location services are disabled. Please enable them in settings.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => isLoading = false);
        _showErrorDialog('Location permission denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => isLoading = false);
      _showErrorDialog('Location permissions are permanently denied. Please enable them in settings.');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      setState(() {
        currentPosition = position;
        isLoading = false;
        markers.add(
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: const InfoWindow(title: 'Current Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      });

      _createZones();

      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 13, // Zoomed out slightly to show all zones
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorDialog('Error getting location: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waste Collection Zones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkPermissionAndGetLocation,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Zone Information'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• Purple: Zone A - Monday & Thursday'),
                      Text('• Green: Zone B - Tuesday & Friday'),
                      Text('• Orange: Zone C - Wednesday & Saturday'),
                      SizedBox(height: 16),
                      Text('Tap on a zone to view more details and collection schedule.'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              mapController = controller;
              if (currentPosition != null) {
                controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(
                        currentPosition!.latitude,
                        currentPosition!.longitude,
                      ),
                      zoom: 13,
                    ),
                  ),
                );
              }
            },
            initialCameraPosition: CameraPosition(
              target: currentPosition != null 
                ? LatLng(currentPosition!.latitude, currentPosition!.longitude)
                : defaultLocation,
              zoom: 13,
            ),
            markers: markers,
            polygons: zones,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapToolbarEnabled: true,
            zoomControlsEnabled: true,
            compassEnabled: true,
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}