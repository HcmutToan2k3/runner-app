class Assignment {
  final String id;
  final String classId;
  final String title;
  final double targetKm;
  final int? timeLimitSec;
  final DateTime? dueAt;

  const Assignment({
    required this.id,
    required this.classId,
    required this.title,
    required this.targetKm,
    this.timeLimitSec,
    this.dueAt,
  });

  factory Assignment.fromJson(Map<String, dynamic> j) => Assignment(
        id: j['id'] as String,
        classId: j['class_id'] as String,
        title: j['title'] as String,
        targetKm: (j['target_km'] as num).toDouble(),
        timeLimitSec: j['time_limit_sec'] as int?,
        dueAt: j['due_at'] == null ? null : DateTime.parse(j['due_at'] as String),
      );
}
