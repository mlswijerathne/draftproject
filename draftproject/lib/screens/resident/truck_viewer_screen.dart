// truck_viewer_screen.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/tracking_service.dart';
import '../../models/truck_location_modek.dart';

class TruckViewerScreen extends StatefulWidget {
  const TruckViewerScreen({super.key});

  @override
  State<TruckViewerScreen> createState() => _TruckViewerScreenState();
}

class _TruckViewerScreenState extends State<TruckViewerScreen> {
  final TrackingService _trackingService = TrackingService();
  GoogleMapController? mapController;
  Set<Marker> _markers = {};
  bool _isFirstLoad = true;

  Set<Marker> _createMarkers(List<TruckLocationModel> trucks) {
    return trucks.map((truck) {
      return Marker(
        markerId: MarkerId(truck.driverId),
        position: LatLng(truck.latitude, truck.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Driver: ${truck.driverName}',
          snippet: 'Last updated: ${_formatDateTime(truck.timestamp)}',
        ),
      );
    }).toSet();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  String _formatDateTime(DateTime dateTime) {
    String minutes = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.hour}:$minutes';
  }

  void _centerMapOnFirstTruck(List<TruckLocationModel> trucks) {
    if (_isFirstLoad && trucks.isNotEmpty && mapController != null) {
      _isFirstLoad = false;
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(trucks.first.latitude, trucks.first.longitude),
          15,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Garbage Trucks'),
      ),
      body: StreamBuilder<List<TruckLocationModel>>(
        stream: _trackingService.getActiveTrucks(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            _markers = _createMarkers(snapshot.data!);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _centerMapOnFirstTruck(snapshot.data!);
            });
          }

          return GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(6.9271, 79.8612), // Default to Colombo
              zoom: 12,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapToolbarEnabled: true,
            zoomControlsEnabled: true,
            compassEnabled: true,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }
}