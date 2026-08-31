cat << 'EOF' > lib/db_helper.dart
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class BookModel {
  final int id;
  final String code;
  final String name;
  final String testament;

  BookModel({required this.id, required this.code, required this.name, required this.testament});

  factory BookModel.fromMap(Map<String, dynamic> map) {
    return BookModel(
      id: map['id'] as int,
      code: map['code'] as String,
      name: map['name_ta'] as String,
      testament: map['testament'] as String,
    );
  }
}

class VerseModel {
  final int number;
  final String text;

  VerseModel({required this.number, required this.text});

  factory VerseModel.fromMap(Map<String, dynamic> map) {
    return VerseModel(
      number: map['verse'] as int,
      text: map['text_ta'] as String,
    );
  }
}

class DatabaseHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tamil_bible.db');

    if (!await databaseExists(path)) {
      ByteData data = await rootBundle.load('assets/tamil_bible.db');
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
    }

    return await openDatabase(path, readOnly: true);
  }

  static Future<List<BookModel>> getBooks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('books', orderBy: 'id ASC');
    return maps.map((e) => BookModel.fromMap(e)).toList();
  }

  static Future<List<int>> getChapters(int bookId) async {
    final db = await database;
    final List<Map<String, dynamic>> res = await db.rawQuery(
      'SELECT DISTINCT chapter FROM verses WHERE book_id = ? ORDER BY chapter ASC',
      [bookId],
    );
    return res.map((e) => e['chapter'] as int).toList();
  }

  static Future<List<VerseModel>> getVerses(int bookId, int chapter) async {
    final db = await database;
    final List<Map<String, dynamic>> res = await db.query(
      'verses',
      where: 'book_id = ? AND chapter = ?',
      whereArgs: [bookId, chapter],
      orderBy: 'verse ASC',
    );
    return res.map((e) => VerseModel.fromMap(e)).toList();
  }

  static Future<List<Map<String, dynamic>>> searchTamil(String query) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT b.name_ta, v.chapter, v.verse, v.text_ta 
      FROM verses v
      JOIN books b ON v.book_id = b.id
      WHERE v.text_ta LIKE ?
      LIMIT 50
    ''', ['%$query%']);
  }
}
EOF