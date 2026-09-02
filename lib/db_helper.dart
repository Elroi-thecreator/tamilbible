import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class BookModel {
  final int id;
  final String name;
  final String nameEn;
  final String testament;

  BookModel({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.testament,
  });

  static const List<String> canonicalEnglishNames = [
    "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy",
    "Joshua", "Judges", "Ruth", "1 Samuel", "2 Samuel",
    "1 Kings", "2 Kings", "1 Chronicles", "2 Chronicles", "Ezra",
    "Nehemiah", "Esther", "Job", "Psalms", "Proverbs",
    "Ecclesiastes", "Song of Solomon", "Isaiah", "Jeremiah", "Lamentations",
    "Ezekiel", "Daniel", "Hosea", "Joel", "Amos",
    "Obadiah", "Jonah", "Micah", "Nahum", "Habakkuk",
    "Zephaniah", "Haggai", "Zechariah", "Malachi",
    "Matthew", "Mark", "Luke", "John", "Acts",
    "Romans", "1 Corinthians", "2 Corinthians", "Galatians", "Ephesians",
    "Philippians", "Colossians", "1 Thessalonians", "2 Thessalonians", "1 Timothy",
    "2 Timothy", "Titus", "Philemon", "Hebrews", "James",
    "1 Peter", "2 Peter", "1 John", "2 John", "3 John",
    "Jude", "Revelation"
  ];

  factory BookModel.fromMap(Map<String, dynamic> map) {
    final bookId = map['id'] as int;
    final fallbackEn = (bookId >= 1 && bookId <= 66)
        ? canonicalEnglishNames[bookId - 1]
        : 'Book $bookId';

    return BookModel(
      id: bookId,
      name: (map['name_ta'] ?? map['name'] ?? '') as String,
      nameEn: (map['name_en'] ?? fallbackEn) as String,
      testament: (map['testament'] ?? 'OT') as String,
    );
  }
}

class VerseModel {
  final int number;
  final String text;
  final String? textEn;

  VerseModel({
    required this.number,
    required this.text,
    this.textEn,
  });

  factory VerseModel.fromMap(Map<String, dynamic> map) {
    return VerseModel(
      number: map['verse'] as int,
      text: (map['text_ta'] ?? map['text'] ?? '') as String,
      textEn: map['text_en'] as String?,
    );
  }
}

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tamil_bible.db');

    final exists = await databaseExists(path);
    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      final data = await rootBundle.load('assets/tamil_bible.db');
      final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
    }

    return await openDatabase(path, readOnly: false);
  }

  static Future<List<BookModel>> getBooks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('books', orderBy: 'id ASC');
    return List.generate(maps.length, (i) => BookModel.fromMap(maps[i]));
  }

  static Future<List<int>> getChapters(int bookId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT chapter FROM verses WHERE book_id = ? ORDER BY chapter ASC;',
      [bookId],
    );
    return maps.map((m) => m['chapter'] as int).toList();
  }

  static Future<List<VerseModel>> getVerses(int bookId, int chapter) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'verses',
      columns: ['verse', 'text_ta', 'text_en'],
      where: 'book_id = ? AND chapter = ?',
      whereArgs: [bookId, chapter],
      orderBy: 'verse ASC',
    );
    return List.generate(maps.length, (i) => VerseModel.fromMap(maps[i]));
  }

  static Future<String?> getSingleVerseText(int bookId, int chapter, int verse) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'verses',
      columns: ['text_ta'],
      where: 'book_id = ? AND chapter = ? AND verse = ?',
      whereArgs: [bookId, chapter, verse],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return (maps.first['text_ta'] ?? '') as String;
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> searchTamil(String query) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT v.book_id, b.name_ta, v.chapter, v.verse, v.text_ta 
      FROM verses v
      JOIN books b ON v.book_id = b.id
      WHERE v.text_ta LIKE ?
      ORDER BY v.book_id ASC, v.chapter ASC, v.verse ASC
      LIMIT 100;
    ''', ['%$query%']);
  }
}