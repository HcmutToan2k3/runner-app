class ClassGroup {
  final String id;
  final String name;
  final String joinCode;
  final String teacherId;

  const ClassGroup({required this.id, required this.name, required this.joinCode, required this.teacherId});

  factory ClassGroup.fromJson(Map<String, dynamic> j) => ClassGroup(
        id: j['id'] as String,
        name: j['name'] as String,
        joinCode: j['join_code'] as String,
        teacherId: j['teacher_id'] as String,
      );
}
