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
    final dbDir = Directory(p.join(appDocDir.path, 'PerplexityClone'));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    final dbPath = p.join(dbDir.path, 'perplexity.db');

    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE threads (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            );
          ''');

          await db.execute('''
            CREATE TABLE messages (
              id TEXT PRIMARY KEY,
              thread_id TEXT NOT NULL,
              role TEXT NOT NULL,
              content TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              FOREIGN KEY (thread_id) REFERENCES threads(id) ON DELETE CASCADE
            );
          ''');

          await db.execute('''
            CREATE TABLE sources (
              id TEXT PRIMARY KEY,
              thread_id TEXT NOT NULL,
              index_num INTEGER NOT NULL,
              title TEXT NOT NULL,
              url TEXT NOT NULL,
              snippet TEXT NOT NULL,
              score REAL NOT NULL,
              FOREIGN KEY (thread_id) REFERENCES threads(id) ON DELETE CASCADE
            );
          ''');
        },
      ),
    );
  }
}
