import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class LocalDatabaseService {
  Database? _database;
  String _databaseName;

  LocalDatabaseService(this._databaseName);

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initializeDatabase();
    return _database!;
  }

  String getDatabasePath() {
    return _databaseName;
  }

  Future<bool> TableExists(Database db, String tableName) async {
    var result = await db.rawQuery(
        'SELECT EXISTS (SELECT 1 FROM sqlite_master WHERE type = \'table\' AND name = \'$tableName\')');

    return result[0]['EXISTS (SELECT 1 FROM sqlite_master WHERE type = \'table\' AND name = \'$tableName\')'] == 1;
  }

  Future<Database> _initializeDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        // Create database tables
        if (_databaseName == 'users') {
          bool tableExists = await TableExists(db, 'my_content');

          if (!tableExists) {
            await db.execute('''
            CREATE TABLE my_content (
              id INTEGER PRIMARY KEY,
              username TEXT,  
              email TEXT,
              name TEXT,
              phone TEXT,
              mobilePhone TEXT,
              photo TEXT
            )
          ''');
          }
        } else if (_databaseName == 'departments') {
          bool tableExists = await TableExists(db, 'my_departments');

          if (!tableExists) {
            await db.execute('''
            CREATE TABLE my_departments (
              departmentName TEXT PRIMARY KEY,
              departmentNumber INTEGER,
              description TEXT,
              lat REAL,
              lng REAL
            )
          ''');
          }
        }
        else if (_databaseName == 'News') {
          bool tableExists = await TableExists(db, 'my_news');

          if (!tableExists) {
            await db.execute('''
            CREATE TABLE my_news (
              title TEXT PRIMARY KEY,
              date TEXT,
              summary TEXT,
              imageUrl TEXT,
              articleUrl TEXT
            )
          ''');
          }
        }
        else if (_databaseName == 'Calendar') {
          bool tableExists = await TableExists(db, 'my_calendar');

          if (!tableExists) {
            await db.execute('''
            CREATE TABLE my_calendar (
              title TEXT PRIMARY KEY,
              description TEXT,
              date TEXT,
              enddate TEXT
            )
          ''');
          }
        }

        else {
          bool tableExists = await TableExists(db, _databaseName);

          if (!tableExists) {
            await db.execute('''
      CREATE TABLE $_databaseName (
        messageID TEXT PRIMARY KEY,
        content TEXT,
        conversationId TEXT,
        senderId TEXT,
        timestamp INTEGER
      )
    ''');
          }
        }
      },
    );
  }

  static Future<LocalDatabaseService> create(String databaseName) async {
    LocalDatabaseService service = LocalDatabaseService(databaseName);
    await service._initializeDatabase();  // Ensure database is initialized.
    return service;
  }
  Future<bool> isDatabaseEmpty(String tableName) async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $tableName'));

    return count == 0;
  }

  Future<void> insertContent(String tableName, Map<String, dynamic> content) async {
    final db = await database;
    await db.insert(tableName, content,
        conflictAlgorithm: ConflictAlgorithm.replace);

  }

  Future<void> clearDatabase(String tableName) async {
    final db = await database;
    await db.delete(tableName);
  }

  Future<List<Map<String, dynamic>>> getAllContent(String tableName) async {
    final db = await database;
    return db.query(tableName);
  }

  Future<void> updateContent(String tableName, Map<String, dynamic> content) async {
    final db = await database;
    await db.update(tableName, content,
        where: 'id = ?', whereArgs: [content['id']]);
  }
  Future<void> deleteContent(String tableName, String id) async {
    final db = await database;
    await db.delete(
      tableName,
      where: "title = ?",
      whereArgs: [id],
    );
  }

}
