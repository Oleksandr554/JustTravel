import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/journey.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String dbPath = p.join(await getDatabasesPath(), 'just_travel_v2.db'); 
    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
     
    );
  }


  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE journeys (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL, 
        mainImagePath TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        city TEXT NOT NULL,
        country TEXT NOT NULL,
        description TEXT NOT NULL,
        additionalImagePaths TEXT,
        status TEXT NOT NULL
      )
    ''');
  }


  Future<int> insertJourney(Journey journey) async {
    final db = await database;
    Map<String, dynamic> journeyMap = journey.toMap();
    if (journeyMap['id'] == null) {
      journeyMap.remove('id');
    }
    return await db.insert('journeys', journeyMap, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  
  Future<List<Journey>> getJourneysForUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'journeys',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'startDate DESC',
    );
    return List.generate(maps.length, (i) {
      return Journey.fromMap(maps[i]);
    });
  }

  Future<Journey?> getJourneyById(int id, String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'journeys',
      where: 'id = ? AND userId = ?', 
      whereArgs: [id, userId],
    );
    if (maps.isNotEmpty) {
      return Journey.fromMap(maps.first);
    }
    return null;
  }

  
  Future<void> deleteJourneysForUser(String userId) async {
    final db = await database;
    await db.delete(
      'journeys',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    print("Deleted all journeys for user $userId");
  }

  
  Future<void> deleteAllDataAndRecreate() async {
     String path = p.join(await getDatabasesPath(), 'just_travel_v2.db');
     await deleteDatabase(path);
     _database = null;
     await database;
     print("Database deleted and recreated.");
  }
}