import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/notification_service.dart';
import '../../data/models/note_model.dart';
import 'notes_bloc.dart';

class NotesBlocObserver extends BlocObserver {
  final NotificationService notificationService;

  NotesBlocObserver(this.notificationService);

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
    if (note.reminderTime != null) {
      notificationService.scheduleHourlyReminder(
        note.id,
        'Support Note Reminder',
        '${note.teacherName} - ${note.studentName}: ${note.description}',
      );
    }
  }

  void _handleNoteUpdate(NoteModel note, NotesState currentState) {
    if (note.reminderTime != null) {
      notificationService.scheduleHourlyReminder(
        note.id,
        'Support Note Reminder',
        '${note.teacherName} - ${note.studentName}: ${note.description}',
      );
    } else {
      notificationService.cancelReminders(note.id);
    }
  }
}
