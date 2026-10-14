enum Role { teacher, student }

class AppUser {
  final String id;
  final String name;
  final String email;
  final Role role;
  final String? schoolId;
  final String? studentCode;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.schoolId,
    this.studentCode,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        role: Role.values.byName(j['role'] as String),
        schoolId: j['school_id'] as String?,
        studentCode: j['student_code'] as String?,
      );
}
