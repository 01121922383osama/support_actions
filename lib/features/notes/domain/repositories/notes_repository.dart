import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../data/models/note_model.dart';

abstract class NotesRepository {
  Future<Either<Failure, NoteModel>> createNote(NoteModel note);
  Future<Either<Failure, bool>> deleteAllNotes();
  Future<Either<Failure, bool>> deleteNote(String noteId);
  Future<Either<Failure, List<NoteModel>>> filterNotes({
    bool? isCompleted,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Either<Failure, List<String>>> getCategories();
  Future<Either<Failure, List<NoteModel>>> getDeletedNotes();
  Future<Either<Failure, List<NoteModel>>> getNotes();
  Future<Either<Failure, bool>> permanentlyDeleteNote(String noteId);
  Future<Either<Failure, bool>> restoreNote(String noteId);
  Future<Either<Failure, NoteModel>> updateNote(NoteModel note);
}
