import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/item_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'items.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
    CREATE TABLE items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      task TEXT,
      description TEXT,
      isDone INTEGER,
      position INTEGER,
      dueDate INTEGER
    )''');
      },
    );
  }

  Future<List<ItemModel>> getItems() async {
    final db = await database;
    final maps = await db.query('items', orderBy: 'position ASC');
    return maps.map((map) => ItemModel.fromMap(map)).toList();
  }

  Future<int> addItem(ItemModel item) async {
    final db = await database;
    return await db.insert('items', item.toMap());
  }

  Future<int> updateItem(ItemModel item) async {
    final db = await database;
    return await db.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updatePositions(List<ItemModel> items) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < items.length; i++) {
      items[i].position = i;
      batch.update(
        'items',
        items[i].toMap(),
        where: 'id = ?',
        whereArgs: [items[i].id],
      );
    }
    await batch.commit(noResult: true);
  }
}
