import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/reminder_service.dart';
import '../../domain/repositories/notes_repository.dart';
import '../models/note_model.dart';

class NotesRepositoryImpl implements NotesRepository {
  final SupabaseClient _supabaseClient;
  final Box<NoteModel> _notesBox;
  final Box<NoteModel> _deletedNotesBox;

  NotesRepositoryImpl({
    required SupabaseClient supabaseClient,
    required Box<NoteModel> notesBox,
    required Box<NoteModel> deletedNotesBox,
  })  : _supabaseClient = supabaseClient,
        _notesBox = notesBox,
        _deletedNotesBox = deletedNotesBox;

  @override
  Future<Either<Failure, NoteModel>> createNote(NoteModel note) async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated'));
      }

      final noteData = {
        ...note.toJson(),
        'user_id': user.id,
      };

      // Ensure user_id is always set
      if (noteData['user_id'] == null) {
        log('Error: User ID is required for note creation');
        return Left(ServerFailure('User not authenticated'));
      }

      final response =
          await _supabaseClient.from('notes').insert(noteData).select();

      // Remove unnecessary null checks
      final createdNote = NoteModel.fromJson(response);

      // Use new helper method for notification scheduling
      if (createdNote.reminderTime != null) {
        await _handleNotificationScheduling(createdNote);
      }

      await _notesBox.put(createdNote.id, createdNote);

      return Right(createdNote);
    } on PostgrestException catch (e) {
      log('CreateNote Error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteAllNotes() async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        log('DeleteAllNotes: User not authenticated');
        return Left(ServerFailure('User not authenticated'));
      }

      log('DeleteAllNotes: Deleting all notes for user ${user.id}');

      // Call the RPC function to delete all notes and get the count
      final deletedCount = await _supabaseClient.rpc('delete_all_notes');
      log('DeleteAllNotes: Deleted $deletedCount notes');

      // Get all notes that are now marked as deleted
      final response = await _supabaseClient
          .from('notes')
          .select()
          .eq('user_id', user.id)
          .eq('deleted', true);

      log('DeleteAllNotes: Raw response after deletion: $response');

      // Ensure response is not null and is a list
      final List<dynamic> responseList = response ?? [];

      final List<NoteModel> deletedNotes =
          List<Map<String, dynamic>>.from(responseList)
              .map((json) => NoteModel.fromJson(json))
              .toList();

      log('DeleteAllNotes: Parsed ${deletedNotes.length} deleted notes');

      // Update local cache
      await _notesBox.clear(); // Clear all notes from main box
      await _deletedNotesBox.clear(); // Clear existing deleted notes

      // Add all deleted notes to deleted box
      for (final note in deletedNotes) {
        await _deletedNotesBox.put(note.id, note);
        log('DeleteAllNotes: Cached deleted note ${note.id}');
      }

      return const Right(true);
    } catch (e) {
      log('DeleteAllNotes Error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteNote(String noteId) async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        log('DeleteNote: User not authenticated');
        return Left(ServerFailure('User not authenticated'));
      }

      log('DeleteNote: Getting note $noteId for user ${user.id}');
      final response = await _supabaseClient
          .from('notes')
          .select()
          .eq('id', noteId)
          .eq('user_id', user.id)
          .single();

      if (response == null) {
        log('DeleteNote: Note not found');
        return Left(ServerFailure('Note not found'));
      }

      log('DeleteNote: Found note: $response');
      final note = NoteModel.fromJson(response);

      log('DeleteNote: Updating note to deleted state');
      await _supabaseClient.rpc('soft_delete_note', params: {
        'note_id': noteId,
      });

      final updatedResponse = await _supabaseClient
          .from('notes')
          .select()
          .eq('id', noteId)
          .eq('user_id', user.id)
          .single();

      if (updatedResponse == null) {
        log('DeleteNote: Failed to get updated note');
        return Left(ServerFailure('Failed to get updated note'));
      }

      log('DeleteNote: Updated note response: $updatedResponse');
      final updatedNote = NoteModel.fromJson(updatedResponse);

      log('DeleteNote: Updating local cache');
      await _notesBox.delete(noteId);
      await _deletedNotesBox.put(noteId, updatedNote);

      return const Right(true);
    } catch (e) {
      log('DeleteNote Error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<NoteModel>>> filterNotes({
    bool? isCompleted,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated'));
      }

      var query = _supabaseClient
          .from('notes')
          .select()
          .eq('user_id', user.id)
          .eq('deleted', false);

      if (isCompleted != null) {
        query = query.eq('is_completed', isCompleted);
      }
      if (category != null) {
        query = query.eq('category', category);
      }
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query;
      final notes = response.map((json) => NoteModel.fromJson(json)).toList();
      return Right(notes);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getCategories() async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated'));
      }

      final response = await _supabaseClient
          .from('notes')
          .select('category')
          .eq('user_id', user.id)
          .eq('deleted', false)
          .order('created_at', ascending: false);
      final categories =
          response.map((json) => json['category'] as String).toList();
      return Right(categories);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<NoteModel>>> getDeletedNotes() async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        log('GetDeletedNotes: User not authenticated');
        return Left(ServerFailure('User not authenticated'));
      }

      log('GetDeletedNotes: Fetching deleted notes for user ${user.id}');
      final response = await _supabaseClient
          .from('notes')
          .select()
          .eq('user_id', user.id)
          .eq('deleted', true);

      log('GetDeletedNotes: Raw response: $response');

      if (response == null) {
        log('GetDeletedNotes: No response from server');
        return const Right([]);
      }

      final List<NoteModel> notes = List<Map<String, dynamic>>.from(response)
          .map((json) => NoteModel.fromJson(json))
          .toList();

      log('GetDeletedNotes: Parsed ${notes.length} notes');

      await _deletedNotesBox.clear();
      for (final note in notes) {
        await _deletedNotesBox.put(note.id, note);
        log('GetDeletedNotes: Cached note ${note.id}');
      }

      return Right(notes);
    } catch (e) {
      log('GetDeletedNotes Error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<NoteModel>>> getNotes() async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated'));
      }

      final response = await _supabaseClient
          .from('notes')
          .select()
          .eq('user_id', user.id)
          .eq('deleted', false);

      final notes = response.map((json) => NoteModel.fromJson(json)).toList();

      await _notesBox.clear();
      for (final note in notes) {
        await _notesBox.put(note.id, note);
      }

      return Right(notes);
    } catch (e) {
      try {
        final notes = _notesBox.values.toList();
        return Right(notes);
      } catch (e) {
        return Left(CacheFailure(e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, bool>> permanentlyDeleteNote(String noteId) async {
    try {
      await _deletedNotesBox.delete(noteId);
      await _supabaseClient.from('notes').delete().eq('id', noteId);
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> restoreNote(String noteId) async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated'));
      }

      final response = await _supabaseClient
          .from('notes')
          .select()
          .eq('id', noteId)
          .eq('user_id', user.id)
          .single();

      final note = NoteModel.fromJson(response);

      await _supabaseClient
          .from('notes')
          .update({'deleted': false})
          .eq('id', noteId)
          .eq('user_id', user.id);

      await _deletedNotesBox.delete(noteId);
      await _notesBox.put(noteId, note.copyWith(isDeleted: false));

      return const Right(true);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // Optional: Method to sync local Hive cache with Supabase stream
  @override
  Future<void> syncNotesWithLocalCache() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) return;

    try {
      // Fetch all notes from Supabase
      final response =
          await _supabaseClient.from('notes').select().eq('user_id', user.id);

      final notes = response.map((json) => NoteModel.fromJson(json)).toList();

      // Clear and update local Hive cache
      await _notesBox.clear();
      for (var note in notes) {
        await _notesBox.put(note.id, note);
      }

      log('🔄 Synced ${notes.length} notes to local cache');
    } catch (e) {
      log('❌ Error syncing notes to local cache: $e');
    }
  }

  @override
  Future<Either<Failure, NoteModel>> updateNote(NoteModel updatedNote) async {
    try {
      log('Updating note: ${updatedNote.id}, Reminder Time: ${updatedNote.reminderTime}');

      final response = await _supabaseClient
          .from('notes')
          .update(updatedNote.toJson())
          .eq('id', updatedNote.id)
          .select()
          .single();

      final updatedNoteFromResponse = NoteModel.fromJson(response);

      // Use new helper method for notification scheduling
      if (updatedNoteFromResponse.reminderTime != null) {
        await _handleNotificationScheduling(updatedNoteFromResponse);
      }

      await _notesBox.put(updatedNoteFromResponse.id, updatedNoteFromResponse);

      return Right(updatedNoteFromResponse);
    } catch (e) {
      log('UpdateNote Error: $e');
      return Left(ServerFailure('Failed to update note: $e'));
    }
  }

  // Stream method to fetch filtered notes
  @override
  Stream<List<NoteModel>> watchFilteredNotes({
    String? teacherName,
    String? studentName,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      log('❌ Cannot fetch filtered notes: User not authenticated');
      return Stream.value([]);
    }

    // Start with base query
    var query = _supabaseClient
        .from('notes')
        .stream(primaryKey: ['id']).eq('user_id', user.id);

    // Apply optional filters
    if (teacherName != null) {
      query = query.eq('teacher_name', teacherName);
    }

    if (studentName != null) {
      query = query.eq('student_name', studentName);
    }

    if (startDate != null) {
      query = query.gte('created_at', startDate.toIso8601String());
    }

    if (endDate != null) {
      query = query.lte('created_at', endDate.toIso8601String());
    }

    return query.map((event) {
      try {
        final notes = event.map((json) => NoteModel.fromJson(json)).toList();

        log('🔍 Filtered notes: ${notes.length} '
            '(Teacher: $teacherName, Student: $studentName)');

        return notes;
      } catch (e) {
        log('❌ Error converting filtered notes stream: $e');
        return [];
      }
    });
  }

  // Stream method to fetch all notes for the current user
  @override
  Stream<List<NoteModel>> watchNotes() {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      log('❌ Cannot fetch notes: User not authenticated');
      return Stream.value([]);
    }

    return _supabaseClient
        .from('notes')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((event) {
          try {
            // Convert Supabase response to NoteModel list
            final notes =
                event.map((json) => NoteModel.fromJson(json)).toList();

            // Optional: Sort notes by creation or reminder time
            notes.sort((a, b) {
              if (a.reminderTime != null && b.reminderTime != null) {
                return a.reminderTime!.compareTo(b.reminderTime!);
              }
              return 0;
            });

            log('📝 Fetched ${notes.length} notes for user ${user.id}');
            return notes;
          } catch (e) {
            log('❌ Error converting notes stream: $e');
            return [];
          }
        });
  }

  // Stream method to fetch notes with upcoming reminders
  @override
  Stream<List<NoteModel>> watchUpcomingReminders() {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      log('❌ Cannot fetch upcoming reminders: User not authenticated');
      return Stream.value([]);
    }

    final now = DateTime.now();

    return _supabaseClient
        .from('notes')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .gt('reminder_time', now.toIso8601String()) // Greater than current time
        .map((event) {
          try {
            final notes =
                event.map((json) => NoteModel.fromJson(json)).toList();

            // Sort by closest reminder time
            notes.sort((a, b) => a.reminderTime!.compareTo(b.reminderTime!));

            log('⏰ Upcoming reminders: ${notes.length}');
            return notes;
          } catch (e) {
            log('❌ Error converting upcoming reminders stream: $e');
            return [];
          }
        });
  }

  // Helper method to handle notification scheduling with enhanced error handling
  Future<void> _handleNotificationScheduling(NoteModel note) async {
    if (note.reminderTime == null) {
      log('ℹ️ No reminder time set for note: ${note.id}');
      return;
    }

    try {
      // Validate reminder time
      final now = DateTime.now();
      final reminderTime = note.reminderTime!;

      log('🕒 Reminder Scheduling Validation:'
          '\n - Note ID: ${note.id}'
          '\n - Current Time: $now'
          '\n - Reminder Time: $reminderTime'
          '\n - Time Difference: ${reminderTime.difference(now)}');

      // Check if reminder is too far in the future (e.g., more than 1 year)
      final maxReminderDuration = now.add(const Duration(days: 365));
      if (reminderTime.isAfter(maxReminderDuration)) {
        log('⚠️ Reminder time is too far in the future. Skipping scheduling.');
        return;
      }

      // Prevent scheduling past reminders
      if (reminderTime.isBefore(now)) {
        log('⚠️ Reminder time is in the past. Skipping scheduling.');
        return;
      }

      // Generate a more descriptive notification title and body
      final title = 'Note Reminder: ${note.teacherName} ${note.studentName}';
      final body = note.description ?? 'No description provided';

      // Attempt to schedule notification
      await ReminderService.scheduleNotification(
        id: note.id,
        title: title,
        body: body,
        scheduledTime: reminderTime,
      );

      log('✅ Notification scheduled successfully:'
          '\n - Note ID: ${note.id}'
          '\n - Scheduled Time: $reminderTime');
    } catch (e, stackTrace) {
      // Comprehensive error logging
      log('❌ Notification Scheduling Error:', error: e, stackTrace: stackTrace);

      // Optional: You could implement a retry mechanism or
      // send an error report to a logging service
      await _logSchedulingError(note, e);
    }
  }

  // Log scheduling errors for potential later investigation
  Future<void> _logSchedulingError(NoteModel note, Object error) async {
    try {
      // In a real-world scenario, you might want to:
      // 1. Send error to a logging service
      // 2. Store in local error log
      // 3. Notify user through a separate mechanism
      log('📝 Logging Notification Scheduling Error:'
          '\n - Note ID: ${note.id}'
          '\n - Teacher: ${note.teacherName}'
          '\n - Student: ${note.studentName}'
          '\n - Reminder Time: ${note.reminderTime}'
          '\n - Error: $error');
    } catch (logError) {
      // Fallback logging in case of any issues with error logging
      log('❌ Error logging scheduling error: $logError');
    }
  }
}
