import '../models/assignment.dart';
import '../models/class_group.dart';
import 'api_client.dart';

class LeaderboardEntry {
  final String studentName;
  final double distanceKm;
  final int durationSec;
  final String status;

  const LeaderboardEntry(this.studentName, this.distanceKm, this.durationSec, this.status);
}

class ClassRepository {
  final ApiClient api;

  ClassRepository(this.api);

  Future<List<ClassGroup>> getClasses() async =>
      (await api.select('class_groups', order: 'name')).map(ClassGroup.fromJson).toList();

  Future<List<Assignment>> getAssignments(String classId) async =>
      (await api.select('assignments', eqCol: 'class_id', eqVal: classId, order: 'due_at'))
          .map(Assignment.fromJson)
          .toList();

  Future<List<LeaderboardEntry>> ranking(String assignmentId) async {
    final rows = await api.rpc('assignment_leaderboard', {'p_assignment_id': assignmentId});
    return rows
        .map((r) => LeaderboardEntry(
              r['student_name'] as String,
              (r['distance_km'] as num).toDouble(),
              r['duration_sec'] as int,
              r['status'] as String,
            ))
        .toList();
  }

  Future<void> createClass(String name) async {
    await api.insert('class_groups', {'name': name, 'teacher_id': api.currentUserId});
  }

  Future<void> createAssignment(String classId, String title, double targetKm, DateTime? dueAt) async {
    await api.insert('assignments', {
      'class_id': classId,
      'title': title,
      'target_km': targetKm,
      'due_at': dueAt?.toUtc().toIso8601String(),
    });
  }
}
