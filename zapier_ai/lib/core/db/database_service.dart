import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  Database? _db;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final dbDir = Directory(p.join(appDocDir.path, 'ZapierAI'));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }

    final dbPath = p.join(dbDir.path, 'zapier_ai.db');

    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE workflows (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              description TEXT NOT NULL,
              is_active INTEGER NOT NULL DEFAULT 1,
              trigger_json TEXT NOT NULL,
              actions_json TEXT NOT NULL,
              created_at TEXT NOT NULL,
              last_run_at TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE workflow_runs (
              id TEXT PRIMARY KEY,
              workflow_id TEXT NOT NULL,
              workflow_title TEXT NOT NULL,
              status TEXT NOT NULL,
              started_at TEXT NOT NULL,
              finished_at TEXT,
              trigger_payload_json TEXT NOT NULL,
              FOREIGN KEY (workflow_id) REFERENCES workflows(id) ON DELETE CASCADE
            )
          ''');

          await db.execute('''
            CREATE TABLE step_logs (
              id TEXT PRIMARY KEY,
              run_id TEXT NOT NULL,
              step_id TEXT NOT NULL,
              step_name TEXT NOT NULL,
              service TEXT NOT NULL,
              status TEXT NOT NULL,
              inputs_json TEXT NOT NULL,
              outputs_json TEXT NOT NULL,
              error_message TEXT,
              executed_at TEXT NOT NULL,
              FOREIGN KEY (run_id) REFERENCES workflow_runs(id) ON DELETE CASCADE
            )
          ''');
        },
      ),
    );
  }
}
