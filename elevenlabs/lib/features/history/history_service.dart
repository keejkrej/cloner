import 'dart:io';
import '../../core/db/database_service.dart';
import 'models/generation.dart';

class HistoryService {
  Future<List<Generation>> getGenerations() async {
    final db = await DatabaseService.database;
    final rows = await db.query('generations', orderBy: 'created_at DESC');
    return rows.map((r) => Generation.fromMap(r)).toList();
  }

  Future<void> saveGeneration(Generation generation) async {
    final db = await DatabaseService.database;
    await db.insert('generations', generation.toMap());
  }

  Future<void> deleteGeneration(String id, String audioPath) async {
    final db = await DatabaseService.database;
    await db.delete('generations', where: 'id = ?', whereArgs: [id]);
    final file = File(audioPath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
