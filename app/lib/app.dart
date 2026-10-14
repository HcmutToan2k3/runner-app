import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/auth_view_model.dart';
import 'features/auth/login_screen.dart';
import 'features/history/history_screen.dart';
import 'features/run/run_screen.dart';
import 'features/teacher/teacher_dashboard_screen.dart';
import 'models/user.dart';

class RunnerApp extends ConsumerWidget {
  const RunnerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).user;
    return MaterialApp(
      title: 'Runner',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: switch (user) {
        null => const LoginScreen(),
        AppUser(role: Role.teacher) => const TeacherDashboardScreen(),
        _ => const StudentHome(),
      },
    );
  }
}

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: const [RunScreen(), HistoryScreen()]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.directions_run), label: 'Run'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}
