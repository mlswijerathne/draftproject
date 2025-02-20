class TruckLocationModel {
  final String driverId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final bool isActive;
  final String driverName;

  TruckLocationModel({
    required this.driverId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.isActive,
    required this.driverName,
  });

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      'isActive': isActive,
      'driverName': driverName,
    };
  }

  factory TruckLocationModel.fromMap(Map<String, dynamic> map) {
    return TruckLocationModel(
      driverId: map['driverId'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      timestamp: (map['timestamp'] as DateTime?) ?? DateTime.now(),
      isActive: map['isActive'] ?? false,
      driverName: map['driverName'] ?? '',
    );
  }
}