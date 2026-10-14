import '../models/gps_point.dart';
import '../models/run.dart';
import 'api_client.dart';
import 'local_db.dart';

class RunRepository {
  final LocalDb local;
  final ApiClient api;

  RunRepository(this.local, this.api);

  Future<void> saveLocal(Run run) => local.upsertRun(run);

  Future<void> addPoint(String runId, GpsPoint p) => local.insertPoint(runId, p);

  Future<List<GpsPoint>> pointsFor(String runId) => local.pointsFor(runId);

  /// Uploads finished runs. Safe to call repeatedly (app start, connectivity back).
  Future<int> syncPending() async {
    var synced = 0;
    for (final run in await local.runsWithStatus(RunStatus.pendingSync)) {
      try {
        final points = await local.pointsFor(run.id);
        await api.insert('runs', run.toRow());
        if (points.isNotEmpty) {
          await api.insert('gps_points', [
            for (var i = 0; i < points.length; i++) {'run_id': run.id, 'seq': i, ...points[i].toJson()},
          ]);
        }
        await api.invoke('validate-run', {'run_id': run.id});
        await local.setStatus(run.id, RunStatus.synced);
        synced++;
      } catch (_) {
        // Leave as pendingSync; retried on next sync.
      }
    }
    return synced;
  }

  Future<List<Run>> history() => local.allRuns();

  /// Teacher view: all runs for an assignment, from the server.
  Future<List<Run>> runsForAssignment(String assignmentId) async {
    final rows = await api.select('runs', eqCol: 'assignment_id', eqVal: assignmentId, order: 'started_at');
    return rows.map(Run.fromRow).toList();
  }
}
