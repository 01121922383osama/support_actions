import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/note_model.dart';
import '../../domain/entities/note.dart';
import '../bloc/notes_bloc.dart';

class NoteFormDialog extends StatefulWidget {
  final Note? note;

  const NoteFormDialog({super.key, this.note});

  @override
  State<NoteFormDialog> createState() => _NoteFormDialogState();
}

class _NoteFormDialogState extends State<NoteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _teacherNameController;
  late TextEditingController _studentNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;
  late String _selectedCategory;
  late DateTime _selectedDate;
  late bool _hasReminder;
  late DateTime? _reminderTime;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _teacherNameController =
        TextEditingController(text: widget.note?.teacherName);
    _studentNameController =
        TextEditingController(text: widget.note?.studentName);
    _descriptionController =
        TextEditingController(text: widget.note?.description);
    _notesController = TextEditingController(text: widget.note?.notes);
    _selectedCategory = widget.note?.category ?? 'Action';
    _selectedDate = widget.note?.createdAt ?? DateTime.now();
    _hasReminder = widget.note?.reminderTime != null;
    _reminderTime = widget.note?.reminderTime;
    _isCompleted = widget.note?.isCompleted ?? false;
  }

  @override
  void dispose() {
    _teacherNameController.dispose();
    _studentNameController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.note == null ? 'New Note' : 'Edit Note',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ).animate().fadeIn().slideY(begin: -0.2),
                const SizedBox(height: 24),
                _buildInputField(
                  controller: _teacherNameController,
                  label: 'Teacher Name',
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter teacher name' : null,
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _studentNameController,
                  label: 'Student Name',
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter student name' : null,
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _descriptionController,
                  label: 'Description',
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter description' : null,
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 16),
                _buildCategorySelector().animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 16),
                _buildDateAndTimeSection().animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 16),
                _buildReminderSection().animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _notesController,
                  label: 'Additional Notes',
                  maxLines: 3,
                ).animate().fadeIn(delay: 700.ms),
                const SizedBox(height: 16),
                _buildCompletionCheckbox().animate().fadeIn(delay: 800.ms),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ).animate().scale(delay: 900.ms),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _saveNote,
                      child: Text(widget.note == null ? 'Create' : 'Update'),
                    ).animate().scale(delay: 900.ms),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().scale(duration: 300.ms, curve: Curves.easeOut);
  }

  void _saveNote() {
    if (_formKey.currentState!.validate()) {
      final note = NoteModel(
        id: widget.note?.id ?? const Uuid().v4(),
        teacherName: _teacherNameController.text.trim(),
        studentName: _studentNameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        createdAt: _selectedDate,
        reminderTime: _hasReminder ? _reminderTime : null,
        notes: _notesController.text.trim(),
        isCompleted: _isCompleted,
      );

      if (widget.note == null) {
        context.read<NotesBloc>().add(CreateNote(note));
      } else {
        context.read<NotesBloc>().add(UpdateNote(note));
      }

      Navigator.pop(context);
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildCategorySelector() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(labelText: 'Category'),
      items: const [
        'Action',
        'Follow-up',
        'Completed',
        'Pending',
      ].map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedCategory = value;
          });
        }
      },
    );
  }

  Widget _buildDateAndTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date & Time',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(_selectedDate.toString().split(' ')[0]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReminderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Switch(
              value: _hasReminder,
              onChanged: (value) {
                setState(() {
                  _hasReminder = value;
                  if (value && _reminderTime == null) {
                    _reminderTime = DateTime.now().add(const Duration(hours: 1));
                  }
                });
              },
            ),
            const SizedBox(width: 8),
            Text(
              'Enable Reminder',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
        if (_hasReminder) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_reminderTime ?? DateTime.now()),
              );
              if (time != null) {
                setState(() {
                  final now = DateTime.now();
                  _reminderTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    time.hour,
                    time.minute,
                  );
                });
              }
            },
            icon: const Icon(Icons.access_time),
            label: Text(_reminderTime != null
                ? TimeOfDay.fromDateTime(_reminderTime!).format(context)
                : 'Set Time'),
          ),
        ],
      ],
    );
  }

  Widget _buildCompletionCheckbox() {
    return CheckboxListTile(
      title: const Text('Mark as Completed'),
      value: _isCompleted,
      onChanged: (value) {
        setState(() {
          _isCompleted = value ?? false;
        });
      },
    );
  }
}
