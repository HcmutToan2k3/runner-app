import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../models/run.dart';
import '../../tracking/run_calculator.dart';

final historyProvider = FutureProvider.autoDispose<List<Run>>((ref) => ref.watch(runRepositoryProvider).history());

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runs = ref.watch(historyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My runs')),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(runRepositoryProvider).syncPending();
          ref.invalidate(historyProvider);
        },
        child: runs.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (list) => list.isEmpty
              ? ListView(children: const [Padding(padding: EdgeInsets.all(32), child: Text('No runs yet'))])
              : ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = list[i];
                    return ListTile(
                      title: Text('${r.distanceKm.toStringAsFixed(2)} km  ·  ${RunCalculator.formatDuration(r.durationSec)}'),
                      subtitle: Text(DateFormat('d MMM yyyy, HH:mm').format(r.startedAt.toLocal())),
                      trailing: Chip(label: Text(r.status.name)),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
