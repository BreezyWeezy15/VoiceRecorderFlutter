import 'package:sqflite/sqflite.dart';

import '../Note.dart';

class DbHelper {

  DbHelper._privateConstructor();
  static final DbHelper instance = DbHelper._privateConstructor();

  static const String tableName = "records";
  static const String recordID = "id";
  static const String recordTitle = "title";
  static const String recordPath = "path";
  static const String recordLength = "length";

  static Database? _database;

  Future<Database?> createDB() async {
    if (_database != null) return _database;
    _database = await _initDB();
    return _database;
  }

  Future<Database> _initDB() async {
    String path = await getDatabasesPath();
    path = "$path/records.db"; // Fixed file path construction

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        $recordID INTEGER PRIMARY KEY AUTOINCREMENT,
        $recordTitle TEXT NOT NULL,
        $recordPath TEXT NOT NULL,
        $recordLength TEXT NOT NULL
      )
    ''');
  }

  Future<int?> create(Note note) async {
    final db = await createDB();
    if (db != null) {
      return await db.insert(tableName, note.toJson());
    }
    return null;
  }

  Future<List<Note>?> getAllNotes() async {
    final db = await createDB();
    if (db != null) {
      final List<Map<String, dynamic>> maps = await db.query(tableName);
      return List<Note>.from(maps.map((map) => Note.fromJson(map)));
    }
    return null;
  }

  Future<int?> deleteAllNotes() async {
    final db = await createDB();
    return await db?.delete(tableName);
  }

  Future<int?> deleteNote(Note note) async {
    final db = await createDB();
    return await db?.delete(
      tableName,
      where: "$recordPath = ?",
      whereArgs: [note.path]
    );
  }

}
