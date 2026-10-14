import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  
  // Base de datos simulada para Web
  final List<Map<String, dynamic>> _webDb = [];

  DatabaseHelper._init() {
    if (kIsWeb) {
      _webDb.add({'id': 1, 'username': 'admin', 'password': '123'});
      _webDb.add({'id': 2, 'username': '1234567', 'password': 'password'});
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not supported on Web.');
    }
    
    _database = await _initDB('continental.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
CREATE TABLE users (
  id $idType,
  username $textType,
  password $textType
)
''');

    await db.insert('users', {'username': 'admin', 'password': '123'});
    await db.insert('users', {'username': '1234567', 'password': 'password'});
  }

  Future<bool> login(String username, String password) async {
    if (kIsWeb) {
      return _webDb.any((u) => u['username'] == username && u['password'] == password);
    } else {
      final db = await instance.database;
      final result = await db.query(
        'users',
        where: 'username = ? AND password = ?',
        whereArgs: [username, password],
      );
      return result.isNotEmpty;
    }
  }
}
