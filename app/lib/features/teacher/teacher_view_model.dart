import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/class_repository.dart';
import '../../models/assignment.dart';
import '../../models/class_group.dart';

final classesProvider = FutureProvider.autoDispose<List<ClassGroup>>(
  (ref) => ref.watch(classRepositoryProvider).getClasses(),
);

final assignmentsProvider = FutureProvider.autoDispose.family<List<Assignment>, String>(
  (ref, classId) => ref.watch(classRepositoryProvider).getAssignments(classId),
);

final leaderboardProvider = FutureProvider.autoDispose.family<List<LeaderboardEntry>, String>(
  (ref, assignmentId) => ref.watch(classRepositoryProvider).ranking(assignmentId),
);
