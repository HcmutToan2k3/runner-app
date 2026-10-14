import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../tracking/run_calculator.dart';
import 'run_view_model.dart';

class RunScreen extends ConsumerWidget {
  const RunScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(runViewModelProvider);
    final vm = ref.read(runViewModelProvider.notifier);
    final route = s.points.map((p) => LatLng(p.lat, p.lng)).toList();
    final pace = const RunCalculator().paceSecPerKm(s.elapsedSec, s.distanceKm);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            key: ValueKey(route.isEmpty),
            options: MapOptions(
              initialCenter: route.isEmpty ? const LatLng(10.7769, 106.7009) : route.last,
              initialZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'vn.edu.runnerapp',
              ),
              PolylineLayer(polylines: [
                Polyline(points: route, strokeWidth: 5, color: Colors.teal),
              ]),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _Stat('Distance', '${s.distanceKm.toStringAsFixed(2)} km'),
                          _Stat('Time', RunCalculator.formatDuration(s.elapsedSec)),
                          _Stat('Pace', '${RunCalculator.formatPace(pace)} /km'),
                        ],
                      ),
                      if (s.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(s.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ),
                      const SizedBox(height: 16),
                      _Controls(state: s.tracking, vm: vm),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final TrackingState state;
  final RunViewModel vm;

  const _Controls({required this.state, required this.vm});

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      TrackingState.idle => FilledButton.icon(
          onPressed: () => vm.start(),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start run'),
        ),
      TrackingState.running => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          OutlinedButton(onPressed: vm.pause, child: const Text('Pause')),
          const SizedBox(width: 12),
          FilledButton(onPressed: vm.finish, child: const Text('Finish')),
        ]),
      TrackingState.paused => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          FilledButton(onPressed: vm.resume, child: const Text('Resume')),
          const SizedBox(width: 12),
          OutlinedButton(onPressed: vm.finish, child: const Text('Finish')),
        ]),
    };
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ]);
}
