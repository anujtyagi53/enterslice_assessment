class LocationItem {
  final int id;
  final double latitude;
  final double longitude;
  final double accuracy;
  final int timestamp;

  const LocationItem({required this.id, required this.latitude, required this.longitude, required this.accuracy, required this.timestamp});

  factory LocationItem.fromMap(Map map) => LocationItem(
    id: (map['id'] as num).toInt(),
    latitude: (map['latitude'] as num).toDouble(),
    longitude: (map['longitude'] as num).toDouble(),
    accuracy: (map['accuracy'] as num).toDouble(),
    timestamp: (map['timestamp'] as num).toInt(),
  );

  String get latLong => '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}
