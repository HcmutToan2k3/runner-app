import '../models/gps_point.dart';
import 'run_calculator.dart';

/// Drops noisy or physically impossible GPS points before they reach the run.
class GpsFilter {
  final double maxAccuracyM;
  final double maxSpeedMps;
  GpsPoint? _last;

  GpsFilter({required this.maxAccuracyM, required this.maxSpeedMps});

  bool accept(GpsPoint p) {
    if (p.accuracyM > maxAccuracyM) return false;
    final last = _last;
    if (last != null) {
      final dtSec = p.t.difference(last.t).inMilliseconds / 1000.0;
      if (dtSec <= 0) return false;
      if (haversineM(last, p) / dtSec > maxSpeedMps) return false;
    }
    _last = p;
    return true;
  }

  void reset() => _last = null;
}
