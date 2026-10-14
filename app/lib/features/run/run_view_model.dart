import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers.dart';
import '../../models/gps_point.dart';
import '../../models/run.dart';
import '../../tracking/run_calculator.dart';

enum TrackingState { idle, running, paused }

class RunState {
  final TrackingState tracking;
  final List<GpsPoint> points;
  final double distanceKm;
  final int elapsedSec;
  final String? error;

  const RunState({
    this.tracking = TrackingState.idle,
    this.points = const [],
    this.distanceKm = 0,
    this.elapsedSec = 0,
    this.error,
  });

  RunState copyWith({TrackingState? tracking, List<GpsPoint>? points, double? distanceKm, int? elapsedSec, String? error}) =>
      RunState(
        tracking: tracking ?? this.tracking,
        points: points ?? this.points,
        distanceKm: distanceKm ?? this.distanceKm,
        elapsedSec: elapsedSec ?? this.elapsedSec,
        error: error,
      );
}

class RunViewModel extends Notifier<RunState> {
  StreamSubscription<GpsPoint>? _sub;
  Timer? _timer;
  String? _runId;
  String? _assignmentId;
  DateTime? _startedAt;
  bool _justResumed = false;

  @override
  RunState build() {
    ref.onDispose(() {
      _sub?.cancel();
      _timer?.cancel();
    });
    return const RunState();
  }

  Future<void> start({String? assignmentId}) async {
    final userId = ref.read(apiClientProvider).currentUserId;
    if (userId == null) return;
    final tracker = ref.read(locationTrackerProvider);
    try {
      await tracker.start();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return;
    }
    _runId = const Uuid().v4();
    _assignmentId = assignmentId;
    _startedAt = DateTime.now();
    await ref.read(runRepositoryProvider).saveLocal(_currentRun(userId, RunStatus.recording));

    state = const RunState(tracking: TrackingState.running);
    _sub = tracker.positions.listen(_onPoint);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.tracking == TrackingState.running) {
        state = state.copyWith(elapsedSec: state.elapsedSec + 1);
      }
    });
  }

  void _onPoint(GpsPoint p) {
    if (state.tracking != TrackingState.running || _runId == null) return;
    ref.read(runRepositoryProvider).addPoint(_runId!, p);
    // Don't count the straight line between where the student paused and resumed.
    final last = (state.points.isEmpty || _justResumed) ? null : state.points.last;
    _justResumed = false;
    final addKm = last == null ? 0.0 : haversineM(last, p) / 1000;
    state = state.copyWith(points: [...state.points, p], distanceKm: state.distanceKm + addKm);
  }

  void pause() => state = state.copyWith(tracking: TrackingState.paused);

  void resume() {
    _justResumed = true;
    ref.read(locationTrackerProvider).filter.reset();
    state = state.copyWith(tracking: TrackingState.running);
  }

  Future<void> finish() async {
    await ref.read(locationTrackerProvider).stop();
    await _sub?.cancel();
    _timer?.cancel();
    final userId = ref.read(apiClientProvider).currentUserId;
    if (_runId != null && userId != null) {
      final repo = ref.read(runRepositoryProvider);
      await repo.saveLocal(_currentRun(userId, RunStatus.pendingSync));
      unawaited(repo.syncPending());
    }
    _runId = null;
    state = const RunState();
  }

  Run _currentRun(String userId, RunStatus status) => Run(
        id: _runId!,
        studentId: userId,
        assignmentId: _assignmentId,
        startedAt: _startedAt!,
        durationSec: state.elapsedSec,
        distanceKm: state.distanceKm,
        status: status,
      );
}

final runViewModelProvider = NotifierProvider<RunViewModel, RunState>(RunViewModel.new);
