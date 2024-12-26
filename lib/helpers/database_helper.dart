import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/note.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path, version: 2, // Incremented version for schema updates
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE notes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      content TEXT NOT NULL,
      date TEXT NOT NULL,
      imagePath TEXT
    )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add the `imagePath` column in version 2
      await db.execute('ALTER TABLE notes ADD COLUMN imagePath TEXT');
    }
  }

  Future<List<Note>> getNotes() async {
    final db = await instance.database;
    final result = await db.query('notes', orderBy: 'date DESC');
    return result.map((json) => Note.fromMap(json)).toList();
  }

  Future<int> insert(Note note) async {
    final db = await instance.database;
    return await db.insert('notes', note.toMap());
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> update(Note note) async {
    final db = await instance.database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<String> getNoteContents() async {
    final notes = await DatabaseHelper.instance.getNotes();
    return notes.map((note) {
      final words = note.content.split(' ');
      final trimmedContent =
          words.length > 25 ? words.take(25).join(' ') + '...' : note.content;
      return trimmedContent;
    }).join('\n\n');
  }
}
