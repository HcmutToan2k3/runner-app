import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../models/assignment.dart';
import '../../models/class_group.dart';
import '../../tracking/run_calculator.dart';
import '../auth/auth_view_model.dart';
import 'teacher_view_model.dart';

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classes = ref.watch(classesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My classes'), actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => ref.read(authViewModelProvider.notifier).logout(),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final name = await _ask(context, 'New class name');
          if (name == null || name.isEmpty) return;
          await ref.read(classRepositoryProvider).createClass(name);
          ref.invalidate(classesProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: classes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => ListView(children: [
          for (final c in list)
            ListTile(
              title: Text(c.name),
              subtitle: Text('Join code: ${c.joinCode}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _ClassScreen(c))),
            ),
        ]),
      ),
    );
  }
}

class _ClassScreen extends ConsumerWidget {
  final ClassGroup group;

  const _ClassScreen(this.group);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignments = ref.watch(assignmentsProvider(group.id));
    return Scaffold(
      appBar: AppBar(title: Text(group.name)),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Assignment'),
        onPressed: () async {
          final km = double.tryParse(await _ask(context, 'Target distance (km)') ?? '');
          if (km == null) return;
          await ref.read(classRepositoryProvider).createAssignment(group.id, '${km.toStringAsFixed(1)} km run', km, null);
          ref.invalidate(assignmentsProvider(group.id));
        },
      ),
      body: assignments.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => ListView(children: [
          for (final a in list)
            ListTile(
              title: Text(a.title),
              subtitle: Text('Target ${a.targetKm} km'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _LeaderboardScreen(a))),
            ),
        ]),
      ),
    );
  }
}

class _LeaderboardScreen extends ConsumerWidget {
  final Assignment assignment;

  const _LeaderboardScreen(this.assignment);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(leaderboardProvider(assignment.id));
    return Scaffold(
      appBar: AppBar(title: Text(assignment.title)),
      body: board.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) => ListView.builder(
          itemCount: rows.length,
          itemBuilder: (_, i) {
            final r = rows[i];
            return ListTile(
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text(r.studentName),
              subtitle: Text('${r.distanceKm.toStringAsFixed(2)} km · ${RunCalculator.formatDuration(r.durationSec)}'),
              trailing: r.status == 'flagged' ? const Icon(Icons.flag, color: Colors.red) : null,
            );
          },
        ),
      ),
    );
  }
}

Future<String?> _ask(BuildContext context, String label) {
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: TextField(controller: c, autofocus: true, decoration: InputDecoration(labelText: label)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('OK')),
      ],
    ),
  );
}
