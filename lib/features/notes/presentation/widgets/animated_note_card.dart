import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../data/models/note_model.dart';

class AnimatedNoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onComplete;
  final bool showSlideActions;

  const AnimatedNoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
    required this.onComplete,
    this.showSlideActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${note.teacherName} - ${note.studentName}',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    decoration: note.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          note.description,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      note.isCompleted
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      color: note.isCompleted
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    onPressed: onComplete,
                  )
                      .animate(
                        target: note.isCompleted ? 1 : 0,
                      )
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.0, 1.0),
                      ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(note.category),
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    side: BorderSide.none,
                  ),
                  if (note.reminderTime != null)
                    Chip(
                      label: const Text('Reminder'),
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      side: BorderSide.none,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(),
        )
        .shimmer(
          duration: 2.seconds,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          angle: 45,
          size: 3,
          curve: Curves.easeInOut,
        );

    if (!showSlideActions) return card;

    return Slidable(
      key: ValueKey(note.id),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onComplete(),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.primary,
            icon: note.isCompleted
                ? Icons.check_circle
                : Icons.check_circle_outline,
            label: note.isCompleted ? 'Uncomplete' : 'Complete',
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            foregroundColor: Theme.of(context).colorScheme.error,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: card,
    );
  }
}
