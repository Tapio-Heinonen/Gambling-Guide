import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

int handID(List<int> cards, int dealerCard) {
  /// Given a list of cards, calculates a unique, deterministic ID
  /// This ID is then used to store and reference the hand in the database
  
  // In its current form, this ID depends on hand order,
  // i.e. the hand (4, 5) is treated as separate from (5, 4)
  // This isn't great, but I feel like it's good enough for now
  String id = "";
  List<int> sorted = List.from(cards);
  sorted.sort();

  for (final card in sorted) {
    id += "${card.toString()}0";
  }
  id += dealerCard.toString();

  return int.parse(id);
}

class DatabaseHelper {
  /// Creates and manages a SQL database to track which hands have been mastered
  /// Hands are stored by their ID, as calculated with the function above
  /// A hand has been mastered (answered successfully) if it exists in the database
  static Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mastery.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE mastery (
            id INTEGER PRIMARY KEY
          )
        ''');
      },
    );
  }

  Future<void> addMastered(int id) async {
    final db = await database;
    await db.insert(
      'mastery',
      {'id': id},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<bool> isMastered(int id) async {
    final db = await database;
    final result = await db.query(
      'mastery',
      columns: ['COUNT(*)'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return result.first['COUNT(*)'] == 1;
    }
    return false; // Default if not found
  }

  Future<int> countMastered() async {
    final db = await database;
    final result = await db.query(
      'mastery',
      distinct: true,
      columns: ['COUNT(*)'],
    );
    if (result.isNotEmpty) {
      return result.first['COUNT(*)'] as int;
    }
    return 0; // No entries found
  }

  Future<int> addMasteredAndGetCount(int handID) async {
    final db = await database;
    return await db.transaction((txn) async {
      await txn.insert('mastery', {'id': handID}, conflictAlgorithm: ConflictAlgorithm.ignore);
      final count = Sqflite.firstIntValue(await txn.rawQuery('SELECT COUNT(*) FROM mastery'));
      return count ?? 0;
    });
  }

  Future<List<Map<String, dynamic>>> getAllMastered() async {
    final db = await database;
    return await db.query('mastery');
  }

  Future<void> resetDatabase() async {
  final db = await database;
  await db.delete('mastery'); // Deletes all rows in the table
  }
}
