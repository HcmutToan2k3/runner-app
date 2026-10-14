import 'package:flutter_test/flutter_test.dart';
import 'package:runner_app/models/gps_point.dart';
import 'package:runner_app/tracking/gps_filter.dart';
import 'package:runner_app/tracking/run_calculator.dart';

GpsPoint pt(double lat, double lng, int sec, {double acc = 5}) => GpsPoint(
      lat: lat,
      lng: lng,
      accuracyM: acc,
      speedMps: 0,
      t: DateTime.utc(2026, 1, 1).add(Duration(seconds: sec)),
    );

void main() {
  group('RunCalculator', () {
    test('0.001 deg latitude is about 111 m', () {
      final km = const RunCalculator().distanceKm([pt(10.0, 106.0, 0), pt(10.001, 106.0, 30)]);
      expect(km, closeTo(0.111, 0.001));
    });

    test('formats pace and duration', () {
      expect(RunCalculator.formatPace(330), '5:30');
      expect(RunCalculator.formatDuration(3725), '1:02:05');
      expect(RunCalculator.formatDuration(65), '01:05');
    });
  });

  group('GpsFilter', () {
    test('rejects inaccurate points', () {
      final f = GpsFilter(maxAccuracyM: 25, maxSpeedMps: 7);
      expect(f.accept(pt(10, 106, 0, acc: 50)), isFalse);
    });

    test('rejects jumps faster than max speed', () {
      final f = GpsFilter(maxAccuracyM: 25, maxSpeedMps: 7);
      expect(f.accept(pt(10.0, 106.0, 0)), isTrue);
      expect(f.accept(pt(10.001, 106.0, 5)), isFalse); // 111 m in 5 s = 22 m/s
      expect(f.accept(pt(10.001, 106.0, 30)), isTrue); // 111 m in 30 s = 3.7 m/s
    });
  });
}
