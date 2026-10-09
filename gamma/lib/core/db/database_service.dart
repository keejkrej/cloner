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
    final dbDir = Directory(p.join(appDocDir.path, 'GammaClone'));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    final dbPath = p.join(dbDir.path, 'gamma.db');

    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE decks (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              topic TEXT NOT NULL,
              theme_id TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            );
          ''');

          await db.execute('''
            CREATE TABLE slides (
              id TEXT PRIMARY KEY,
              deck_id TEXT NOT NULL,
              slide_order INTEGER NOT NULL,
              layout TEXT NOT NULL,
              title TEXT NOT NULL,
              subtitle TEXT,
              bullets_json TEXT,
              left_column_title TEXT,
              left_column_text TEXT,
              right_column_title TEXT,
              right_column_text TEXT,
              stat_number TEXT,
              stat_label TEXT,
              quote_text TEXT,
              quote_author TEXT,
              image_url TEXT,
              image_prompt TEXT,
              FOREIGN KEY (deck_id) REFERENCES decks(id) ON DELETE CASCADE
            );
          ''');
        },
      ),
    );
  }
}
