import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/gps_point.dart';
import 'gps_filter.dart';

/// Streams filtered GPS points, including while the screen is locked.
/// Platform setup (Info.plist background mode, Android foreground service
/// permissions) is described in README.md.
class LocationTracker {
  final GpsFilter filter;
  final _controller = StreamController<GpsPoint>.broadcast();
  StreamSubscription<Position>? _sub;

  LocationTracker(this.filter);

  Stream<GpsPoint> get positions => _controller.stream;

  Future<void> start() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Location services are turned off');
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      throw StateError('Location permission denied');
    }
    filter.reset();
    await _sub?.cancel();
    _sub = Geolocator.getPositionStream(locationSettings: _settings()).listen((pos) {
      final p = GpsPoint(
        lat: pos.latitude,
        lng: pos.longitude,
        accuracyM: pos.accuracy,
        speedMps: pos.speed,
        t: pos.timestamp,
      );
      if (filter.accept(p)) _controller.add(p);
    });
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  LocationSettings _settings() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
          intervalDuration: const Duration(seconds: 1),
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'Run in progress',
            notificationText: 'Recording your route',
            enableWakeLock: true,
          ),
        );
      case TargetPlatform.iOS:
        return AppleSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          activityType: ActivityType.fitness,
          distanceFilter: 3,
          pauseLocationUpdatesAutomatically: false,
          allowBackgroundLocationUpdates: true,
          showBackgroundLocationIndicator: true,
        );
      default:
        return const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 3);
    }
  }
}
