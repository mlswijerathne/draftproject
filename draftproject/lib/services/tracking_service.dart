import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../models/truck_location_modek.dart';

class TrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static Timer? _locationTimer;  // Make static to persist across instances

  Future<bool> isDriverActive(String driverId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('truck_locations')
          .doc(driverId)
          .get();
      return doc.exists && (doc.data() as Map<String, dynamic>)['isActive'] == true;
    } catch (e) {
      print('Error checking driver status: $e');
      return false;
    }
  }

  Future<void> startTracking(String driverId, String driverName) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      // Update initial status with current location
      await _firestore.collection('truck_locations').doc(driverId).set({
        'driverId': driverId,
        'driverName': driverName,
        'isActive': true,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Start periodic updates if not already running
      _locationTimer?.cancel();
      _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high
          );

          await _firestore.collection('truck_locations').doc(driverId).set({
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': FieldValue.serverTimestamp(),
            'isActive': true,
            'driverId': driverId,
            'driverName': driverName,
          });
        } catch (e) {
          print('Error updating location: $e');
        }
      });
    } catch (e) {
      print('Error starting tracking: $e');
    }
  }

  Future<void> stopTracking(String driverId) async {
    _locationTimer?.cancel();
    _locationTimer = null;
    await _firestore.collection('truck_locations').doc(driverId).update({
      'isActive': false,
    });
  }

  Stream<List<TruckLocationModel>> getActiveTrucks() {
    return _firestore
        .collection('truck_locations')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        // Convert Firestore Timestamp to DateTime
        if (data['timestamp'] != null) {
          data['timestamp'] = (data['timestamp'] as Timestamp).toDate();
        } else {
          data['timestamp'] = DateTime.now(); // Provide default timestamp
        }
        return TruckLocationModel.fromMap(data);
      }).toList();
    });
  }
}