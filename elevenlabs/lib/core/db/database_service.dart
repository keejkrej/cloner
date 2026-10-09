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
    final dbDir = Directory(p.join(appDocDir.path, 'ElevenLabsClone'));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    final dbPath = p.join(dbDir.path, 'elevenlabs.db');

    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE voices (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              category TEXT NOT NULL,
              description TEXT NOT NULL,
              sample_path TEXT,
              created_at INTEGER NOT NULL
            );
          ''');

          await db.execute('''
            CREATE TABLE generations (
              id TEXT PRIMARY KEY,
              voice_id TEXT NOT NULL,
              voice_name TEXT NOT NULL,
              full_text TEXT NOT NULL,
              audio_path TEXT NOT NULL,
              character_count INTEGER NOT NULL,
              created_at INTEGER NOT NULL
            );
          ''');
        },
      ),
    );
  }
}
