import 'package:flutter/foundation.dart';

///super class para agrupar todas as exceptions relacionadas a cloud storage
class CloudStorageException implements Exception {
  const CloudStorageException();
}

// C in CRUD
class CouldNotCreateNoteException implements CloudStorageException {}

// R in CRUD
class CouldNotGetAllNotesException implements CloudStorageException {}

// U in CRUD
class CouldNotUpdateNoteException implements CloudStorageException {}

// D in CRUD
class CouldNotDeleteNoteException implements CloudStorageException {}
