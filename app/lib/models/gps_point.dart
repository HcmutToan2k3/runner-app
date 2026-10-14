class GpsPoint {
  final double lat;
  final double lng;
  final double accuracyM;
  final double speedMps;
  final DateTime t;

  const GpsPoint({
    required this.lat,
    required this.lng,
    required this.accuracyM,
    required this.speedMps,
    required this.t,
  });

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'accuracy_m': accuracyM,
        'speed_mps': speedMps,
        't': t.toUtc().toIso8601String(),
      };

  factory GpsPoint.fromJson(Map<String, dynamic> j) => GpsPoint(
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        accuracyM: (j['accuracy_m'] as num).toDouble(),
        speedMps: (j['speed_mps'] as num).toDouble(),
        t: DateTime.parse(j['t'] as String),
      );
}
