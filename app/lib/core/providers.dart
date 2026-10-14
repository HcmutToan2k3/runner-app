import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_client.dart';
import '../data/class_repository.dart';
import '../data/local_db.dart';
import '../data/run_repository.dart';
import '../tracking/gps_filter.dart';
import '../tracking/location_tracker.dart';
import '../tracking/run_calculator.dart';
import 'config.dart';

final apiClientProvider = Provider((_) => ApiClient());
final localDbProvider = Provider((_) => LocalDb());

final runRepositoryProvider =
    Provider((ref) => RunRepository(ref.watch(localDbProvider), ref.watch(apiClientProvider)));
final classRepositoryProvider = Provider((ref) => ClassRepository(ref.watch(apiClientProvider)));

final locationTrackerProvider = Provider((_) => LocationTracker(
      GpsFilter(maxAccuracyM: AppConfig.maxAccuracyM, maxSpeedMps: AppConfig.maxSpeedMps),
    ));
final runCalculatorProvider = Provider((_) => const RunCalculator());
