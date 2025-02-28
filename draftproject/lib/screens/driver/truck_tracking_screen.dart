import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/tracking_service.dart';
import 'package:draftproject/services/direction_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class TruckTrackingScreen extends StatefulWidget {
  const TruckTrackingScreen({super.key});

  @override
  State<TruckTrackingScreen> createState() => _TruckTrackingScreenState();
}

class _TruckTrackingScreenState extends State<TruckTrackingScreen> {
  final TrackingService _trackingService = TrackingService();
  final DirectionsService _directionsService = DirectionsService();
  final AuthService _authService = AuthService();
  GoogleMapController? mapController;
  Position? currentPosition;
  bool isTracking = false;
  UserModel? currentUser;
  Set<Polyline> _polylines = {};
  List<LatLng> _routePoints = [];
  Timer? _locationTimer; // Added missing Timer field

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _loadCurrentUser();
    _checkActiveTracking();
  }

  Future<void> _checkActiveTracking() async {
    currentUser = await _authService.getCurrentUser();
    if (currentUser != null) {
      bool isActive = await _trackingService.isDriverActive(currentUser!.uid);
      setState(() {
        isTracking = isActive;
      });
    }
  }

  Future<void> _loadCurrentUser() async {
    currentUser = await _authService.getCurrentUser();
    setState(() {});
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

    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        currentPosition = position;
      });

      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15,
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Error getting location: $e');
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

  void _startTracking() async {
    if (currentUser == null) return;

    setState(() {
      isTracking = true;
      _routePoints = [];
    });

    await _trackingService.startTracking(
      currentUser!.uid,
      currentUser!.name,
    );

    // Start tracking route points
    _locationTimer =
        Timer.periodic(const Duration(seconds: 10), (timer) async {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _routePoints.add(LatLng(position.latitude, position.longitude));
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: _routePoints,
            color: Colors.blue,
            width: 5,
          ),
        };
      });

      await _trackingService.UpdateRoutePoints(currentUser!.uid, _routePoints as LatLng);
    });
  }

  void _stopTracking() async {
    if (currentUser == null) return;

    setState(() {
      isTracking = false;
      _polylines.clear();
      _routePoints.clear();
    });

    _locationTimer?.cancel();
    await _trackingService.stopTracking(currentUser!.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Truck Tracking'),
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
                      zoom: 15,
                    ),
                  ),
                );
              }
            },
            initialCameraPosition: CameraPosition(
              target: currentPosition != null
                  ? LatLng(currentPosition!.latitude,
                      currentPosition!.longitude)
                  : const LatLng(6.9271, 79.8612),
              zoom: 15,
            ),
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapToolbarEnabled: true,
            zoomControlsEnabled: true,
            compassEnabled: true,
          ),
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
                    isTracking ? 'Currently Tracking' : 'Tracking Stopped',
                    style: TextStyle(
                      color: isTracking ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: isTracking ? null : _startTracking,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Route'),
                      ),
                      ElevatedButton.icon(
                        onPressed: isTracking ? _stopTracking : null,
                        icon: const Icon(Icons.stop),
                        label: const Text('End Route'),
                      ),
                    ],
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
    _locationTimer?.cancel();
    mapController?.dispose();
    super.dispose();
  }
}
