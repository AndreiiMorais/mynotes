import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mynotes/services/crud/crud_exceptions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

class NotesService {
  Database? _db;

  List<DataBaseNote> _notes = []; //cache local

  //inicio do singleton
  static final NotesService _shared = NotesService._sharedInstance();
  NotesService._sharedInstance() {
    _notesStreamController = StreamController<List<DataBaseNote>>.broadcast(
      onListen: () {
        _notesStreamController.sink.add(_notes);
      },
    );
  }
  factory NotesService() => _shared;
  //final do singleton

  late final StreamController<List<DataBaseNote>> _notesStreamController;
  Stream<List<DataBaseNote>> get allNotes => _notesStreamController.stream;

  Future<DatabaseUser> getOrCreateUser({required String email}) async {
    try {
      final user = await getUser(email: email);
      return user;
    } on UserDoNotExist {
      final createdUser = await createUser(email: email);
      return createdUser;
    } catch (e) {
      rethrow; //nao é a forma correta, mas é um jeito facil de colocar um break point e fazer um debug
    }
  }

  Future<void> _cacheNotes() async {
    final allNotes = await getAllNotes();
    _notes = allNotes.toList();
    _notesStreamController.add(_notes);
  }

  Database _getDatabaseOrThrow() {
    //funçao para checar se ja existe um db ou jogar uma exception
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpened();
    } else {
      return db;
    }
  }

  Future<void> open() async {
    if (_db != null) {
      throw DatabaseAlreadyOpenException();
    }
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;

      //create the user table
      await db.execute(createUserTable);

      //create the note table
      await db.execute(createNoteTable);
      await _cacheNotes();
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentsDirectory();
    }
  }

  Future<void> _ensureDbIsOpen() async {
    try {
      await open();
    } on DatabaseAlreadyOpenException {
      //empty
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpened();
    } else {
      await db.close();
      _db = null;
    }
  }

  Future<void> deleteUser({required String email}) async {
    //precisa usar um try/catch quando chamar pois ela pode retornar um erro
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      userTable,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (deletedCount != 1) {
      throw CouldNotDeleteUser();
    }
  }

  Future<DatabaseUser> createUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final isUserExistent = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (isUserExistent.isNotEmpty) {
      throw UserAlreadyExists();
    }

    final userId = await db.insert(userTable, {
      emailColumn: email.toLowerCase(),
    });

    return DatabaseUser(
      id: userId,
      email: email,
    );
  }

  Future<DatabaseUser> getUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final isUserExistent = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (isUserExistent.isEmpty) {
      throw UserDoNotExist();
    } else {
      return DatabaseUser.fromRow(isUserExistent.first);
      //aqui retornamos o primeiro item do mapa, pois ou ele encontra 1 ou nao encontra nenhum e retorna o erro
    }
  }

  Future<DataBaseNote> createNote({required DatabaseUser owner}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    //make sure owner exists in the db with the correct id
    final dbUser = await getUser(email: owner.email);
    if (dbUser != owner) {
      throw UserDoNotExist();
    }

    const text = '';
    //create the note
    final noteId = await db.insert(noteTable, {
      userIdColumn: owner.id,
      textColumn: text,
      isSyncWithCloudColumn: 1,
    });

    final note = DataBaseNote(
      id: noteId,
      userId: owner.id,
      text: text,
      isSyncedWithCloud: true,
    );

    _notes.add(note);
    _notesStreamController.add(_notes);

    return note;
  }

  Future<void> deleteNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletecount = await db.delete(
      noteTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deletecount == 0) {
      throw CouldNotDeleteNote();
    } else {
      _notes.removeWhere((note) => note.id == id);
      _notesStreamController.add(_notes);
    }
  }

  Future<int> deleteAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final numberOfDeletions = await db.delete(noteTable);
    _notes = [];
    _notesStreamController.add(_notes);
    return numberOfDeletions;
  }

  Future<DataBaseNote> getNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(
      noteTable,
      limit: 1,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (notes.isEmpty) {
      throw CouldNotFindNote();
    } else {
      final note = DataBaseNote.fromRow(notes.first);
      _notes.removeWhere((note) => note.id == id);
      _notes.add(note);
      _notesStreamController.add(_notes);
      return note;
    }
  }

  Future<Iterable<DataBaseNote>> getAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(noteTable);

    return notes.map((noteRow) => DataBaseNote.fromRow(noteRow));
  }

  Future<DataBaseNote> updateNote({
    required DataBaseNote note,
    required String text,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    //make sure note exists
    await getNote(id: note.id);

    //update db
    final updatesCount = await db.update(noteTable, {
      textColumn: text,
      isSyncWithCloudColumn: 0,
    });

    if (updatesCount == 0) {
      //se for 0 significa que nao atualizou nenhuma note
      throw CouldNotUpdateNote();
    } else {
      final updatedNote = await getNote(id: note.id);
      _notes.removeWhere((note) => note.id == updatedNote.id);
      _notes.add(updatedNote);
      _notesStreamController.add(_notes);
      return updatedNote;
    }
  }
}

@immutable
class DatabaseUser {
  final int id;
  final String email;
  const DatabaseUser({
    required this.id,
    required this.email,
  });

  DatabaseUser.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        email = map[emailColumn] as String;

  @override
  String toString() => 'Person, ID = $id, email = $email';

  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
  //aqui estou sobreescrevendo o == para comparar objetos do mesmo tipo
}

class DataBaseNote {
  final int id;
  final int userId;
  final String text;
  final bool isSyncedWithCloud;

  DataBaseNote({
    required this.id,
    required this.userId,
    required this.text,
    required this.isSyncedWithCloud,
  });

  DataBaseNote.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        userId = map[userIdColumn] as int,
        text = map[textColumn] as String,
        isSyncedWithCloud = (map[isSyncWithCloudColumn] as int) == 1
            ? true
            : false; //no DB está salvo como int, entao fizemos a comparaçao aqui

  @override
  String toString() =>
      'Note, ID = $id, userId = $userId, isSyncedWithCloud = $isSyncedWithCloud, text = $text';
  //text foi para o final por causa do tamanho, para nao atrapalhar outras inf

  @override
  bool operator ==(covariant DataBaseNote other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const dbName = 'notes.db';
const noteTable = 'note';
const userTable = 'user';
const idColumn = 'id';
const emailColumn = 'email';
const userIdColumn = 'user_id';
const textColumn = 'text';
const isSyncWithCloudColumn = 'is_synced_to_cloud';

const createUserTable = '''CREATE TABLE IF NOT EXISTS "user" (
    	"id"	INTEGER NOT NULL,
	    "email"	TEXT NOT NULL UNIQUE,
	    PRIMARY KEY("id" AUTOINCREMENT)
      );''';

const createNoteTable = '''CREATE TABLE IF NOT EXISTS "note" (
        "id"	INTEGER NOT NULL,
        "user_id"	INTEGER NOT NULL,
        "text"	TEXT,
        "is_synced_to_cloud"	INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY("user_id") REFERENCES "user"("id"),
        PRIMARY KEY("id" AUTOINCREMENT)
      );''';
