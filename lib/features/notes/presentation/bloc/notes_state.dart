part of 'notes_bloc.dart';

abstract class NotesState extends Equatable {
  const NotesState();

  @override
  List<Object?> get props => [];
}

class NotesInitial extends NotesState {}

class NotesLoading extends NotesState {}

class NotesError extends NotesState {
  final String message;

  const NotesError(this.message);

  @override
  List<Object> get props => [message];
}

class NotesLoaded extends NotesState {
  final List<NoteModel> notes;
  final List<NoteModel> deletedNotes;

  const NotesLoaded({
    required this.notes,
    required this.deletedNotes,
  });

  @override
  List<Object> get props => [notes, deletedNotes];
}
