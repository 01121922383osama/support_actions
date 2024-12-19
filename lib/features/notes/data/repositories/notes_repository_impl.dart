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

      if (createdNote.reminderTime != null) {
        try {
          await ReminderService.scheduleNotification(
            id: createdNote.id,
            title:
                'Note Reminder: ${createdNote.description ?? 'Untitled Note'}',
            body: createdNote.description ?? 'No description',
            scheduledTime: createdNote.reminderTime!,
          );
          log('Notification scheduled successfully for note: ${createdNote.id}');
        } catch (e) {
          log('CreateNote Error (scheduling notification): $e',
              error: e, stackTrace: StackTrace.current);
        }
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

  @override
  Future<Either<Failure, NoteModel>> updateNote(NoteModel updatedNote) async {
    try {
      // Log the note being updated
      log('Updating note: ${updatedNote.id}, Reminder Time: ${updatedNote.reminderTime}');

      // Perform Supabase update
      final response = await _supabaseClient
          .from('notes')
          .update(updatedNote.toJson())
          .eq('id', updatedNote.id)
          .select()
          .single();

      final updatedNoteFromResponse = NoteModel.fromJson(response);

      // Handle reminder scheduling
      if (updatedNoteFromResponse.reminderTime != null) {
        try {
          log('Attempting to schedule notification for note: ${updatedNoteFromResponse.id}');
          await ReminderService.scheduleNotification(
            id: updatedNoteFromResponse.id,
            title: 'Note Reminder',
            body: updatedNoteFromResponse.description ?? 'You have a reminder',
            scheduledTime: updatedNoteFromResponse.reminderTime!,
          );
          log('Notification scheduled successfully for note: ${updatedNoteFromResponse.id}');
        } catch (scheduleError) {
          log('Error scheduling notification: $scheduleError');
          // Optionally, you might want to handle this error more specifically
        }
      } else {
        log('No reminder time set for note: ${updatedNoteFromResponse.id}');
      }

      // Update local Hive storage
      await _notesBox.put(updatedNoteFromResponse.id, updatedNoteFromResponse);

      return Right(updatedNoteFromResponse);
    } catch (e) {
      log('UpdateNote Error: $e');
      return Left(ServerFailure('Failed to update note: $e'));
    }
  }
}
