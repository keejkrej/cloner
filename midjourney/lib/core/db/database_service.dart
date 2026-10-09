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
    final dbDir = Directory(p.join(appDocDir.path, 'MidjourneyClone'));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    final dbPath = p.join(dbDir.path, 'midjourney.db');

    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE generated_images (
              id TEXT PRIMARY KEY,
              prompt TEXT NOT NULL,
              enhanced_prompt TEXT NOT NULL,
              aspect_ratio TEXT NOT NULL,
              image_path TEXT NOT NULL,
              created_at INTEGER NOT NULL
            );
          ''');
        },
      ),
    );
  }
}
