import 'dart:math';

import '../models/gps_point.dart';

const _earthRadiusM = 6371000.0;

/// Great-circle distance between two points, in metres.
double haversineM(GpsPoint a, GpsPoint b) {
  double rad(double d) => d * pi / 180;
  final dLat = rad(b.lat - a.lat);
  final dLng = rad(b.lng - a.lng);
  final h = sin(dLat / 2) * sin(dLat / 2) +
      cos(rad(a.lat)) * cos(rad(b.lat)) * sin(dLng / 2) * sin(dLng / 2);
  return 2 * _earthRadiusM * asin(min(1.0, sqrt(h)));
}

class RunCalculator {
  const RunCalculator();

  double distanceKm(List<GpsPoint> points) {
    var m = 0.0;
    for (var i = 1; i < points.length; i++) {
      m += haversineM(points[i - 1], points[i]);
    }
    return m / 1000;
  }

  /// Seconds per km; null if distance is too small to give a sensible pace.
  double? paceSecPerKm(int durationSec, double km) => km < 0.05 ? null : durationSec / km;

  static String formatPace(double? secPerKm) {
    if (secPerKm == null || secPerKm.isInfinite) return '--:--';
    final s = secPerKm.round();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  static String formatDuration(int sec) {
    final h = sec ~/ 3600, m = (sec % 3600) ~/ 60, s = sec % 60;
    final mm = m.toString().padLeft(2, '0'), ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }
}
