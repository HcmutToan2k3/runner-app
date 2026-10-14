import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/gps_point.dart';
import '../models/run.dart';

/// On-device store. Every GPS point is written as it arrives, so a run
/// survives the app being killed or the network dropping.
class LocalDb {
  Database? _db;

  Future<Database> get db async => _db ??= await openDatabase(
        p.join(await getDatabasesPath(), 'runner.db'),
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE runs (
              id TEXT PRIMARY KEY,
              student_id TEXT NOT NULL,
              assignment_id TEXT,
              started_at TEXT NOT NULL,
              duration_sec INTEGER NOT NULL DEFAULT 0,
              distance_km REAL NOT NULL DEFAULT 0,
              status TEXT NOT NULL
            )''');
          await db.execute('''
            CREATE TABLE points (
              run_id TEXT NOT NULL,
              lat REAL NOT NULL,
              lng REAL NOT NULL,
              accuracy_m REAL NOT NULL,
              speed_mps REAL NOT NULL,
              t TEXT NOT NULL
            )''');
          await db.execute('CREATE INDEX idx_points_run ON points(run_id)');
        },
      );

  Future<void> upsertRun(Run run) async {
    final row = run.toRow()..remove('avg_pace_sec_per_km');
    row['status'] = run.status.name;
    await (await db).insert('runs', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertPoint(String runId, GpsPoint pt) async {
    await (await db).insert('points', {'run_id': runId, ...pt.toJson()});
  }

  Future<List<GpsPoint>> pointsFor(String runId) async {
    final rows = await (await db).query('points', where: 'run_id = ?', whereArgs: [runId], orderBy: 't');
    return rows.map(GpsPoint.fromJson).toList();
  }

  Future<List<Run>> runsWithStatus(RunStatus status) async {
    final rows = await (await db).query('runs', where: 'status = ?', whereArgs: [status.name]);
    return rows.map(Run.fromRow).toList();
  }

  Future<List<Run>> allRuns() async {
    final rows = await (await db).query('runs', orderBy: 'started_at DESC');
    return rows.map(Run.fromRow).toList();
  }

  Future<void> setStatus(String runId, RunStatus status) async {
    await (await db).update('runs', {'status': status.name}, where: 'id = ?', whereArgs: [runId]);
  }
}
