import 'package:equatable/equatable.dart';

class Note extends Equatable {
  final String id;
  final String teacherName;
  final String studentName;
  final String description;
  final DateTime createdAt;
  final String category;
  final bool isCompleted;
  final bool isDeleted;
  final DateTime? reminderTime;
  final String? notes;

  const Note({
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

  Note copyWith({
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
    return Note(
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
}
