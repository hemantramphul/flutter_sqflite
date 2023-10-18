// Import the plugins Path provider and SQLite.
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io' as io;

// Import UserModel
import 'package:flutter_sqflite/models/noteModel.dart';

class DatabaseHelper {
  // SQLite database instance
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  // Database name and version
  static const String databaseName = 'database.db';

  // Set the version. This executes the onCreate function and provides a
  // path to perform database upgrades and downgrades.
  static const int versionNumber = 1;

  // Table name
  static const String tableNotes = 'Notes';

  // Table (Users) Columns
  static const String colId = 'id';
  static const String colTitle = 'title';
  static const String colDescription = 'description';

  // Define a getter to access the database asynchronously.
  Future<Database> get database async {
    // If the database instance is already initialized, return it.
    if (_database != null) {
      return _database!;
    }

    // If the database instance is not initialized, call the initialization method.
    _database = await _initDatabase();

    // Return the initialized database instance.
    return _database!;
  }

  _initDatabase() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();

    // Set the path to the database. Note: Using the `join` function from the
    // `path` package is best practice to ensure the path is correctly
    // constructed for each platform.
    String path = join(documentsDirectory.path, databaseName);
    // When the database is first created, create a table to store Notes.
    var db =
        await openDatabase(path, version: versionNumber, onCreate: _onCreate);
    return db;
  }

  // Run the CREATE TABLE statement on the database.
  _onCreate(Database db, int intVersion) async {
    await db.execute("CREATE TABLE IF NOT EXISTS $tableNotes ("
        " $colId INTEGER PRIMARY KEY AUTOINCREMENT, "
        " $colTitle TEXT NOT NULL, "
        " $colDescription TEXT"
        ")");
  }

  // A method that retrieves all the notes from the Notes table.
  Future<List<NoteModel>> getAll() async {
    // Get a reference to the database.
    final db = await database;

    // Query the table for all The Notes. {SELECT * FROM Notes ORDER BY Id ASC}
    final result = await db.query(tableNotes, orderBy: '$colId ASC');

    // Convert the List<Map<String, dynamic> into a List<Note>.
    return result.map((json) => NoteModel.fromJson(json)).toList();
  }

  // Serach note by Id
  Future<NoteModel> read(int id) async {
    final db = await database;
    final maps = await db.query(
      tableNotes,
      where: '$colId = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return NoteModel.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  // Define a function that inserts notes into the database
  Future<void> insert(NoteModel note) async {
    // Get a reference to the database.
    final db = await database;

    // Insert the Note into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same Note is inserted twice.
    //
    // In this case, replace any previous data.
    await db.insert(tableNotes, note.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Define a function to update a note
  Future<int> update(NoteModel note) async {
    // Get a reference to the database.
    final db = await database;

    // Update the given Note.
    var res = await db.update(tableNotes, note.toJson(),
        // Ensure that the Note has a matching id.
        where: '$colId = ?',
        // Pass the Note's id as a whereArg to prevent SQL injection.
        whereArgs: [note.id]);
    return res;
  }

  // Define a function to delete a note
  Future<void> delete(int id) async {
    // Get a reference to the database.
    final db = await database;
    try {
      // Remove the Note from the database.
      await db.delete(tableNotes,
          // Use a `where` clause to delete a specific Note.
          where: "$colId = ?",
          // Pass the Dog's id as a whereArg to prevent SQL injection.
          whereArgs: [id]);
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
