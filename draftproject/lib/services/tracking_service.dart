import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:draftproject/models/truck_location_modek.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class TrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _locationTimer;

  Future<void> startTracking(String driverId, String driverName) async {
    // Update initial status
    await _firestore.collection('truck_locations').doc(driverId).set({
      'driverId': driverId,
      'driverName': driverName,
      'isActive': true,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Start periodic updates
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
  }

  Future<void> stopTracking(String driverId) async {
    _locationTimer?.cancel();
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
        data['timestamp'] = (data['timestamp'] as Timestamp).toDate();
        return TruckLocationModel.fromMap(data);
      }).toList();
    });
  }
}