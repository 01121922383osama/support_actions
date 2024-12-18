import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/note_model.dart';
import '../../domain/repositories/notes_repository.dart';

part 'notes_event.dart';
part 'notes_state.dart';

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final NotesRepository repository;

  NotesBloc({required this.repository}) : super(NotesInitial()) {
    on<LoadNotes>(_onLoadNotes);
    on<CreateNote>(_onCreateNote);
    on<UpdateNote>(_onUpdateNote);
    on<DeleteNote>(_onDeleteNote);
    on<DeleteAllNotes>(_onDeleteAllNotes);
    on<RestoreNote>(_onRestoreNote);
    on<FilterNotes>(_onFilterNotes);
    on<DeleteNotePermanently>(_onDeleteNotePermanently);
    on<EmptyRecycleBin>(_onEmptyRecycleBin);
  }

  Future<void> _onCreateNote(CreateNote event, Emitter<NotesState> emit) async {
    if (state is NotesLoading) return;

    emit(NotesLoading());
    final result = await repository.createNote(event.note);
    result.fold(
      (failure) => emit(NotesError(failure.message)),
      (note) => add(LoadNotes()),
    );
  }

  Future<void> _onDeleteAllNotes(
      DeleteAllNotes event, Emitter<NotesState> emit) async {
    if (state is NotesLoading) return;

    emit(NotesLoading());
    final result = await repository.deleteAllNotes();

    await result.fold(
      (failure) async {
        if (!emit.isDone) {
          emit(NotesError(failure.message));
        }
      },
      (success) async {
        final notesResult = await repository.getNotes();
        final deletedNotesResult = await repository.getDeletedNotes();

        final notes = notesResult.fold(
          (failure) => <NoteModel>[],
          (notes) => notes,
        );

        final deletedNotes = deletedNotesResult.fold(
          (failure) => <NoteModel>[],
          (deletedNotes) => deletedNotes,
        );

        if (!emit.isDone) {
          emit(NotesLoaded(
            notes: notes,
            deletedNotes: deletedNotes,
          ));
        }
      },
    );
  }

  Future<void> _onDeleteNote(DeleteNote event, Emitter<NotesState> emit) async {
    if (state is NotesLoading) return;

    emit(NotesLoading());
    final result = await repository.deleteNote(event.noteId);

    await result.fold(
      (failure) async {
        if (!emit.isDone) {
          emit(NotesError(failure.message));
        }
      },
      (success) async {
        final notesResult = await repository.getNotes();
        final deletedNotesResult = await repository.getDeletedNotes();

        final notes = notesResult.fold(
          (failure) => <NoteModel>[],
          (notes) => notes,
        );

        final deletedNotes = deletedNotesResult.fold(
          (failure) => <NoteModel>[],
          (notes) => notes,
        );

        if (!emit.isDone) {
          emit(NotesLoaded(notes: notes, deletedNotes: deletedNotes));
        }
      },
    );
  }

  Future<void> _onDeleteNotePermanently(
    DeleteNotePermanently event,
    Emitter<NotesState> emit,
  ) async {
    if (state is NotesLoading) return;

    emit(NotesLoading());
    final result = await repository.permanentlyDeleteNote(event.noteId);
    result.fold(
      (failure) => emit(NotesError(failure.message)),
      (success) => add(LoadNotes()),
    );
  }

  Future<void> _onEmptyRecycleBin(
    EmptyRecycleBin event,
    Emitter<NotesState> emit,
  ) async {
    if (state is NotesLoading) return;

    emit(NotesLoading());
    // Delete all notes in the recycle bin
    if (state is NotesLoaded) {
      final currentState = state as NotesLoaded;
      for (final note in currentState.deletedNotes) {
        final result = await repository.permanentlyDeleteNote(note.id);
        if (result.isLeft()) {
          emit(NotesError('Failed to empty recycle bin'));
          return;
        }
      }
      add(LoadNotes());
    }
  }

  Future<void> _onFilterNotes(
      FilterNotes event, Emitter<NotesState> emit) async {
    if (state is NotesLoading) return;

    emit(NotesLoading());
    final result = await repository.filterNotes(
      isCompleted: event.isCompleted,
      category: event.category,
      startDate: event.startDate,
      endDate: event.endDate,
    );

    // Also get deleted notes
    final deletedNotesResult = await repository.getDeletedNotes();

    final notes = result.fold(
      (failure) => <NoteModel>[],
      (notes) => notes,
    );

    final deletedNotes = deletedNotesResult.fold(
      (failure) => <NoteModel>[],
      (notes) => notes,
    );

    if (!emit.isDone) {
      emit(NotesLoaded(notes: notes, deletedNotes: deletedNotes));
    }
  }

  Future<void> _onLoadNotes(LoadNotes event, Emitter<NotesState> emit) async {
    if (state is NotesLoading) return;

    emit(NotesLoading());
    try {
      final notesResult = await repository.getNotes();
      final deletedNotesResult = await repository.getDeletedNotes();

      final notes = notesResult.fold(
        (failure) => <NoteModel>[],
        (notes) => notes,
      );

      final deletedNotes = deletedNotesResult.fold(
        (failure) => <NoteModel>[],
        (notes) => notes,
      );

      if (!emit.isDone) {
        emit(NotesLoaded(notes: notes, deletedNotes: deletedNotes));
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(NotesError(e.toString()));
      }
    }
  }

  Future<void> _onRestoreNote(
      RestoreNote event, Emitter<NotesState> emit) async {
    if (state is NotesLoading) return;

    emit(NotesLoading());
    final result = await repository.restoreNote(event.noteId);

    await result.fold(
      (failure) async {
        if (!emit.isDone) {
          emit(NotesError(failure.message));
        }
      },
      (success) async {
        final notesResult = await repository.getNotes();
        final deletedNotesResult = await repository.getDeletedNotes();

        final notes = notesResult.fold(
          (failure) => <NoteModel>[],
          (notes) => notes,
        );

        final deletedNotes = deletedNotesResult.fold(
          (failure) => <NoteModel>[],
          (notes) => notes,
        );

        if (!emit.isDone) {
          emit(NotesLoaded(notes: notes, deletedNotes: deletedNotes));
        }
      },
    );
  }

  Future<void> _onUpdateNote(UpdateNote event, Emitter<NotesState> emit) async {
    if (state is NotesLoading) return;

    emit(NotesLoading());
    try {
      final result = await repository.updateNote(event.note);
      await result.fold(
        (failure) async {
          if (!emit.isDone) {
            emit(NotesError(failure.message));
          }
        },
        (success) async {
          final notesResult = await repository.getNotes();
          final deletedNotesResult = await repository.getDeletedNotes();

          final notes = notesResult.fold(
            (failure) => <NoteModel>[],
            (notes) => notes,
          );

          final deletedNotes = deletedNotesResult.fold(
            (failure) => <NoteModel>[],
            (notes) => notes,
          );

          if (!emit.isDone) {
            emit(NotesLoaded(notes: notes, deletedNotes: deletedNotes));
          }
        },
      );
    } catch (e) {
      if (!emit.isDone) {
        emit(NotesError(e.toString()));
      }
    }
  }
}
