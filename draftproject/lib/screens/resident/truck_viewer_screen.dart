import 'package:draftproject/models/truck_location_modek.dart';
import 'package:draftproject/services/direction_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../services/tracking_service.dart';


class TruckViewerScreen extends StatefulWidget {
  const TruckViewerScreen({super.key});

  @override
  State<TruckViewerScreen> createState() => _TruckViewerScreenState();
}

class _TruckViewerScreenState extends State<TruckViewerScreen> {
  final TrackingService _trackingService = TrackingService();
  final DirectionsService _directionsService = DirectionsService();
  GoogleMapController? mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Position? _userLocation;
  bool _isFirstLoad = true;
  TruckLocationModel? _nearestTruck;
  Timer? _locationUpdateTimer;
  StreamSubscription? _truckRouteSubscription;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    // Start periodic location updates
    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _updateUserLocation(),
    );
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorDialog('Location services are disabled');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorDialog('Location permission denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showErrorDialog('Location permissions are permanently denied');
      return;
    }

    await _updateUserLocation();
  }

  Future<void> _updateUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      setState(() {
        _userLocation = position;
      });

      if (_isFirstLoad && mapController != null) {
        _isFirstLoad = false;
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            15,
          ),
        );
      }

      await _updateNearestTruck();
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateNearestTruck() async {
    if (_userLocation == null) return;

    TruckLocationModel? nearestTruck = await _trackingService.getNearestTruck(
      LatLng(_userLocation!.latitude, _userLocation!.longitude),
    );

    if (nearestTruck != null) {
      setState(() {
        _nearestTruck = nearestTruck;
      });

      // Update route subscription for the nearest truck
      _truckRouteSubscription?.cancel();
      _truckRouteSubscription = _trackingService
          .getTruckRoute(nearestTruck.driverId)
          .listen((points) {
        if (points.isNotEmpty) {
          setState(() {
            _polylines = {
              _directionsService.createPolyline('truck_route', points),
            };
          });
        }
      });

      // Get directions to nearest truck
      await _updateDirectionsToNearestTruck();
    }
  }

  Future<void> _updateDirectionsToNearestTruck() async {
    if (_userLocation == null || _nearestTruck == null) return;

    List<LatLng> directionPoints = await _directionsService.getDirectionsPoints(
      origin: LatLng(_userLocation!.latitude, _userLocation!.longitude),
      destination: LatLng(_nearestTruck!.latitude, _nearestTruck!.longitude),
    );

    if (directionPoints.isNotEmpty) {
      setState(() {
        _polylines.add(
          _directionsService.createPolyline('directions', directionPoints),
        );
      });
    }
  }

  Set<Marker> _createMarkers(List<TruckLocationModel> trucks) {
    Set<Marker> markers = {};
    
    // Add user location marker
    if (_userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(_userLocation!.latitude, _userLocation!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    // Add truck markers
    for (var truck in trucks) {
      bool isNearest = _nearestTruck?.driverId == truck.driverId;
      markers.add(
        Marker(
          markerId: MarkerId(truck.driverId),
          position: LatLng(truck.latitude, truck.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isNearest ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueYellow
          ),
          infoWindow: InfoWindow(
            title: '${isNearest ? '(Nearest) ' : ''}Driver: ${truck.driverName}',
            snippet: 'Last updated: ${_formatDateTime(truck.timestamp)}',
          ),
        ),
      );
    }

    return markers;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Garbage Trucks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _updateUserLocation,
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              if (_userLocation != null && mapController != null) {
                mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(_userLocation!.latitude, _userLocation!.longitude),
                    15,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<List<TruckLocationModel>>(
            stream: _trackingService.getActiveTrucks(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.hasData) {
                _markers = _createMarkers(snapshot.data!);
              }

              return GoogleMap(
                onMapCreated: (controller) {
                  mapController = controller;
                  if (_userLocation != null) {
                    controller.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(_userLocation!.latitude, _userLocation!.longitude),
                        15,
                      ),
                    );
                  }
                },
                initialCameraPosition: CameraPosition(
                  target: _userLocation != null
                      ? LatLng(_userLocation!.latitude, _userLocation!.longitude)
                      : const LatLng(6.9271, 79.8612), // Default to Colombo
                  zoom: 15,
                ),
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: true,
                zoomControlsEnabled: true,
                compassEnabled: true,
              );
            },
          ),
          if (_nearestTruck != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Nearest Truck: ${_nearestTruck!.driverName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last updated: ${_formatDateTime(_nearestTruck!.timestamp)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _truckRouteSubscription?.cancel();
    mapController?.dispose();
    super.dispose();
  }
}