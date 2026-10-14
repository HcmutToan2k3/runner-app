import 'gps_point.dart';

/// recording -> pendingSync -> synced -> (approved | flagged)
enum RunStatus { recording, pendingSync, synced, approved, flagged }

class Run {
  final String id;
  final String studentId;
  final String? assignmentId;
  final DateTime startedAt;
  final int durationSec;
  final double distanceKm;
  final RunStatus status;
  final List<GpsPoint> points;

  const Run({
    required this.id,
    required this.studentId,
    required this.startedAt,
    required this.durationSec,
    required this.distanceKm,
    required this.status,
    this.assignmentId,
    this.points = const [],
  });

  /// Seconds per km, or null when too short to be meaningful.
  double? get avgPaceSecPerKm => distanceKm < 0.05 ? null : durationSec / distanceKm;

  Run copyWith({RunStatus? status, List<GpsPoint>? points}) => Run(
        id: id,
        studentId: studentId,
        assignmentId: assignmentId,
        startedAt: startedAt,
        durationSec: durationSec,
        distanceKm: distanceKm,
        status: status ?? this.status,
        points: points ?? this.points,
      );

  /// Row shape for the `runs` table (points go to `gps_points`).
  Map<String, dynamic> toRow() => {
        'id': id,
        'student_id': studentId,
        'assignment_id': assignmentId,
        'started_at': startedAt.toUtc().toIso8601String(),
        'duration_sec': durationSec,
        'distance_km': distanceKm,
        'avg_pace_sec_per_km': avgPaceSecPerKm,
      };

  factory Run.fromRow(Map<String, dynamic> j) => Run(
        id: j['id'] as String,
        studentId: j['student_id'] as String,
        assignmentId: j['assignment_id'] as String?,
        startedAt: DateTime.parse(j['started_at'] as String),
        durationSec: j['duration_sec'] as int,
        distanceKm: (j['distance_km'] as num).toDouble(),
        status: RunStatus.values.byName(j['status'] as String? ?? 'synced'),
      );
}
