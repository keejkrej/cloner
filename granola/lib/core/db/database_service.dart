import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  static Future<Database> _initDb() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final dbDir = Directory(p.join(appDocDir.path, 'GranolaClone'));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    final dbPath = p.join(dbDir.path, 'granola.db');

    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE meetings (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              scratch_notes TEXT NOT NULL,
              enhanced_notes TEXT,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            );
          ''');

          await db.execute('''
            CREATE TABLE transcript_utterances (
              id TEXT PRIMARY KEY,
              meeting_id TEXT NOT NULL,
              speaker_label TEXT NOT NULL,
              text TEXT NOT NULL,
              timestamp_ms INTEGER NOT NULL,
              created_at INTEGER NOT NULL,
              FOREIGN KEY (meeting_id) REFERENCES meetings(id) ON DELETE CASCADE
            );
          ''');
        },
      ),
    );
  }
}
