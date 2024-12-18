import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import '../../domain/entities/note.dart';

part 'note_model.g.dart';

@HiveType(typeId: 0)
class NoteModel extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String teacherName;

  @HiveField(2)
  final String studentName;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final String category;

  @HiveField(6)
  final bool isCompleted;

  @HiveField(7)
  final bool isDeleted;

  @HiveField(8)
  final DateTime? reminderTime;

  @HiveField(9)
  final String? notes;

  const NoteModel({
    required this.id,
    required this.teacherName,
    required this.studentName,
    required this.description,
    required this.createdAt,
    required this.category,
    this.isCompleted = false,
    this.isDeleted = false,
    this.reminderTime,
    this.notes,
  });

  factory NoteModel.fromEntity(Note note) {
    return NoteModel(
      id: note.id,
      teacherName: note.teacherName,
      studentName: note.studentName,
      description: note.description,
      createdAt: note.createdAt,
      category: note.category,
      isCompleted: note.isCompleted,
      isDeleted: note.isDeleted,
      reminderTime: note.reminderTime,
      notes: note.notes,
    );
  }

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'],
      teacherName: json['teacher_name'],
      studentName: json['student_name'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      category: json['category'],
      isCompleted: json['is_completed'] ?? false,
      isDeleted: json['deleted'] ?? false,
      reminderTime: json['reminder_time'] != null
          ? DateTime.parse(json['reminder_time'])
          : null,
      notes: json['notes'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        teacherName,
        studentName,
        description,
        createdAt,
        category,
        isCompleted,
        isDeleted,
        reminderTime,
        notes,
      ];

  NoteModel copyWith({
    String? id,
    String? teacherName,
    String? studentName,
    String? description,
    DateTime? createdAt,
    String? category,
    bool? isCompleted,
    bool? isDeleted,
    DateTime? reminderTime,
    String? notes,
  }) {
    return NoteModel(
      id: id ?? this.id,
      teacherName: teacherName ?? this.teacherName,
      studentName: studentName ?? this.studentName,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      isDeleted: isDeleted ?? this.isDeleted,
      reminderTime: reminderTime ?? this.reminderTime,
      notes: notes ?? this.notes,
    );
  }

  Note toEntity() {
    return Note(
      id: id,
      teacherName: teacherName,
      studentName: studentName,
      description: description,
      createdAt: createdAt,
      category: category,
      isCompleted: isCompleted,
      isDeleted: isDeleted,
      reminderTime: reminderTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher_name': teacherName,
      'student_name': studentName,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'category': category,
      'is_completed': isCompleted,
      'deleted': isDeleted,
      'reminder_time': reminderTime?.toIso8601String(),
      'notes': notes,
    };
  }
}
