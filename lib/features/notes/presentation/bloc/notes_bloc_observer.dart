import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/note_model.dart';
import 'notes_bloc.dart';

class NotesBlocObserver extends BlocObserver {
  NotesBlocObserver();

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);

    if (bloc is NotesBloc) {
      final event = transition.event;

      if (event is CreateNote) {
        _handleNoteCreation(event.note);
      } else if (event is UpdateNote) {
        _handleNoteUpdate(event.note, transition.currentState as NotesState);
      }
    }
  }

  void _handleNoteCreation(NoteModel note) {
    if (note.reminderTime != null) {}
  }

  void _handleNoteUpdate(NoteModel note, NotesState currentState) {
    if (note.reminderTime != null) {
    } else {}
  }
}
