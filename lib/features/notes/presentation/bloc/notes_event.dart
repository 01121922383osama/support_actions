part of 'notes_bloc.dart';

class CreateNote extends NotesEvent {
  final NoteModel note;

  const CreateNote(this.note);

  @override
  List<Object> get props => [note];
}

class DeleteAllNotes extends NotesEvent {}

class DeleteNote extends NotesEvent {
  final String noteId;

  const DeleteNote(this.noteId);

  @override
  List<Object> get props => [noteId];
}

class DeleteNotePermanently extends NotesEvent {
  final String noteId;

  const DeleteNotePermanently(this.noteId);

  @override
  List<Object> get props => [noteId];
}

class EmptyRecycleBin extends NotesEvent {}

class FilterNotes extends NotesEvent {
  final bool? isCompleted;
  final String? category;
  final DateTime? startDate;
  final DateTime? endDate;

  const FilterNotes({
    this.isCompleted,
    this.category,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [isCompleted, category, startDate, endDate];
}

class LoadNotes extends NotesEvent {}

abstract class NotesEvent extends Equatable {
  const NotesEvent();

  @override
  List<Object?> get props => [];
}

class RestoreNote extends NotesEvent {
  final String noteId;

  const RestoreNote(this.noteId);

  @override
  List<Object> get props => [noteId];
}

class UpdateNote extends NotesEvent {
  final NoteModel note;

  const UpdateNote(this.note);

  @override
  List<Object> get props => [note];
}
