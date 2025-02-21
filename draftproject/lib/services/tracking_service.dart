import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:draftproject/models/truck_location_modek.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static Timer? _locationTimer;

  /// ✅ Check if the driver is currently active
  Future<bool> isDriverActive(String driverId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('truck_locations').doc(driverId).get();
      return doc.exists &&
          (doc.data() as Map<String, dynamic>)['isActive'] == true;
    } catch (e) {
      print('Error checking driver status: $e');
      return false;
    }
  }

  /// ✅ Start tracking the truck's location
  Future<void> startTracking(String driverId, String driverName) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      await _firestore.collection('truck_locations').doc(driverId).set({
        'driverId': driverId,
        'driverName': driverName,
        'isActive': true,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'routeStartTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _locationTimer?.cancel();
      _locationTimer =
          Timer.periodic(const Duration(seconds: 10), (timer) async {
        try {
          Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high);

          await _firestore.collection('truck_locations').doc(driverId).update({
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': FieldValue.serverTimestamp(),
          });

          // ✅ Update route points
          await UpdateRoutePoints(driverId, LatLng(position.latitude, position.longitude));
        } catch (e) {
          print('Error updating location: $e');
        }
      });
    } catch (e) {
      print('Error starting tracking: $e');
    }
  }

  /// ✅ Update route points in Firestore
  Future<void>UpdateRoutePoints(String driverId, LatLng point) async {
    try {
      await _firestore.collection('truck_routes').doc(driverId).set({
        'points': FieldValue.arrayUnion([
          {
            'lat': point.latitude,
            'lng': point.longitude,
            'timestamp': FieldValue.serverTimestamp(),
          }
        ]),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating route point: $e');
    }
  }

  /// ✅ Stop tracking and archive route data
  Future<void> stopTracking(String driverId) async {
    _locationTimer?.cancel();
    _locationTimer = null;

    await _firestore.collection('truck_locations').doc(driverId).update({
      'isActive': false,
      'routeEndTime': FieldValue.serverTimestamp(),
    });

    // ✅ Archive the route
    DocumentSnapshot routeDoc =
        await _firestore.collection('truck_routes').doc(driverId).get();

    if (routeDoc.exists) {
      await _firestore.collection('route_history').add({
        'driverId': driverId,
        'route': routeDoc.data(),
        'completedAt': FieldValue.serverTimestamp(),
      });

      // ✅ Clear current route after archiving
      await routeDoc.reference.delete();
    }
  }

  /// ✅ Get active trucks in real-time
  Stream<List<TruckLocationModel>> getActiveTrucks() {
    return _firestore
        .collection('truck_locations')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['timestamp'] = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        return TruckLocationModel.fromMap(data);
      }).toList();
    });
  }

  /// ✅ Find the nearest active truck
  Future<TruckLocationModel?> getNearestTruck(LatLng userLocation) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('truck_locations')
          .where('isActive', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) return null;

      TruckLocationModel? nearestTruck;
      double shortestDistance = double.infinity;

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['timestamp'] = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        TruckLocationModel truck = TruckLocationModel.fromMap(data);

        double distance = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          truck.latitude,
          truck.longitude,
        );

        if (distance < shortestDistance) {
          shortestDistance = distance;
          nearestTruck = truck;
        }
      }

      return nearestTruck;
    } catch (e) {
      print('Error finding nearest truck: $e');
      return null;
    }
  }

  /// ✅ Get truck's route in real-time
  Stream<List<LatLng>> getTruckRoute(String driverId) {
    return _firestore.collection('truck_routes').doc(driverId).snapshots().map((snapshot) {
      if (!snapshot.exists) return [];

      List<dynamic> points = (snapshot.data()?['points'] ?? []);
      return points.map<LatLng>((point) => LatLng(point['lat'], point['lng'])).toList();
    });
  }
}
