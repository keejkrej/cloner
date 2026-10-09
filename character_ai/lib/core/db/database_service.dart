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
    final dbDir = Directory(p.join(appDocDir.path, 'CharacterAIClone'));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    final dbPath = p.join(dbDir.path, 'character_ai.db');

    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE characters (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              avatar TEXT NOT NULL,
              personality TEXT NOT NULL,
              speaking_style TEXT NOT NULL,
              greeting TEXT NOT NULL,
              voice TEXT NOT NULL,
              created_at INTEGER NOT NULL
            );
          ''');

          await db.execute('''
            CREATE TABLE messages (
              id TEXT PRIMARY KEY,
              character_id TEXT NOT NULL,
              role TEXT NOT NULL,
              content TEXT NOT NULL,
              audio_path TEXT,
              created_at INTEGER NOT NULL,
              FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE
            );
          ''');

          await db.execute('''
            CREATE TABLE character_memories (
              id TEXT PRIMARY KEY,
              character_id TEXT NOT NULL,
              fact TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE
            );
          ''');
        },
      ),
    );
  }
}
