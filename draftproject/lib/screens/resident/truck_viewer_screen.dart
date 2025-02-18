import 'package:draftproject/models/truck_location_modek.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/tracking_service.dart';

class TruckViewerScreen extends StatefulWidget {
  const TruckViewerScreen({super.key});

  @override
  State<TruckViewerScreen> createState() => _TruckViewerScreenState();
}

class _TruckViewerScreenState extends State<TruckViewerScreen> {
  final TrackingService _trackingService = TrackingService();
  GoogleMapController? mapController;
  Set<Marker> _markers = {};

  void _updateMarkers(List<TruckLocationModel> trucks) {
    setState(() {
      _markers = trucks.map((truck) {
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
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute}';
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
          if (snapshot.hasData) {
            _updateMarkers(snapshot.data!);
          }

          return GoogleMap(
            onMapCreated: (controller) {
              mapController = controller;
            },
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