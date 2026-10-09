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
    final dbDir = Directory(p.join(appDocDir.path, 'NotebookLMClone'));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    final dbPath = p.join(dbDir.path, 'notebooklm.db');

    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE notebooks (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            );
          ''');

          await db.execute('''
            CREATE TABLE sources (
              id TEXT PRIMARY KEY,
              notebook_id TEXT NOT NULL,
              title TEXT NOT NULL,
              file_path TEXT NOT NULL,
              page_count INTEGER NOT NULL,
              created_at INTEGER NOT NULL,
              FOREIGN KEY (notebook_id) REFERENCES notebooks(id) ON DELETE CASCADE
            );
          ''');

          await db.execute('''
            CREATE TABLE chunks (
              id TEXT PRIMARY KEY,
              notebook_id TEXT NOT NULL,
              source_id TEXT NOT NULL,
              source_title TEXT NOT NULL,
              page_number INTEGER NOT NULL,
              chunk_index INTEGER NOT NULL,
              content TEXT NOT NULL,
              FOREIGN KEY (notebook_id) REFERENCES notebooks(id) ON DELETE CASCADE,
              FOREIGN KEY (source_id) REFERENCES sources(id) ON DELETE CASCADE
            );
          ''');

          await db.execute('''
            CREATE TABLE messages (
              id TEXT PRIMARY KEY,
              notebook_id TEXT NOT NULL,
              role TEXT NOT NULL,
              content TEXT NOT NULL,
              citations_json TEXT,
              created_at INTEGER NOT NULL,
              FOREIGN KEY (notebook_id) REFERENCES notebooks(id) ON DELETE CASCADE
            );
          ''');

          await db.execute('''
            CREATE TABLE audio_overviews (
              id TEXT PRIMARY KEY,
              notebook_id TEXT NOT NULL,
              title TEXT NOT NULL,
              audio_path TEXT NOT NULL,
              script_json TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              FOREIGN KEY (notebook_id) REFERENCES notebooks(id) ON DELETE CASCADE
            );
          ''');
        },
      ),
    );
  }
}
