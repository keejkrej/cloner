import 'dart:io';
import '../../core/db/database_service.dart';
import 'models/chat_message.dart';
import 'models/project.dart';

class ProjectRepository {
  Future<List<Project>> getAllProjects() async {
    final db = await DatabaseService.database;
    final rows = await db.query('projects', orderBy: 'updated_at DESC');
    return rows.map((r) => Project.fromMap(r)).toList();
  }

  Future<Project?> getProject(String id) async {
    final db = await DatabaseService.database;
    final rows = await db.query('projects', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Project.fromMap(rows.first);
  }

  Future<void> saveProject(Project project) async {
    final db = await DatabaseService.database;
    await db.insert(
      'projects',
      project.toMap(),
      conflictAlgorithm: null,
    );
  }

  Future<void> updateProjectTimestamp(String id) async {
    final db = await DatabaseService.database;
    await db.update(
      'projects',
      {'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteProject(String id, String dirPath) async {
    final db = await DatabaseService.database;
    await db.delete('chat_messages', where: 'project_id = ?', whereArgs: [id]);
    await db.delete('projects', where: 'id = ?', whereArgs: [id]);

    final dir = Directory(dirPath);
    if (await dir.exists()) {
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    }
  }

  Future<List<ChatMessage>> getMessages(String projectId) async {
    final db = await DatabaseService.database;
    final rows = await db.query(
      'chat_messages',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'created_at ASC',
    );
    return rows.map((r) => ChatMessage.fromMap(r)).toList();
  }

  Future<void> saveMessage(ChatMessage message) async {
    final db = await DatabaseService.database;
    await db.insert('chat_messages', message.toMap());
  }
}
