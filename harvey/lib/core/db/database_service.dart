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
    final dbDir = Directory(p.join(appDocDir.path, 'HarveyClone'));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    final dbPath = p.join(dbDir.path, 'harvey.db');

    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE matters (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              description TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            );
          ''');

          await db.execute('''
            CREATE TABLE contracts (
              id TEXT PRIMARY KEY,
              matter_id TEXT NOT NULL,
              title TEXT NOT NULL,
              file_path TEXT NOT NULL,
              page_count INTEGER NOT NULL,
              raw_text TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              FOREIGN KEY (matter_id) REFERENCES matters(id) ON DELETE CASCADE
            );
          ''');

          await db.execute('''
            CREATE TABLE clauses (
              id TEXT PRIMARY KEY,
              contract_id TEXT NOT NULL,
              clause_type TEXT NOT NULL,
              section_number TEXT NOT NULL,
              section_title TEXT NOT NULL,
              summary_value TEXT NOT NULL,
              verbatim_passage TEXT NOT NULL,
              page_number INTEGER NOT NULL,
              citation TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              FOREIGN KEY (contract_id) REFERENCES contracts(id) ON DELETE CASCADE
            );
          ''');

          await db.execute('''
            CREATE TABLE qa_messages (
              id TEXT PRIMARY KEY,
              matter_id TEXT NOT NULL,
              role TEXT NOT NULL,
              content TEXT NOT NULL,
              citations_json TEXT,
              created_at INTEGER NOT NULL,
              FOREIGN KEY (matter_id) REFERENCES matters(id) ON DELETE CASCADE
            );
          ''');
        },
      ),
    );
  }
}
