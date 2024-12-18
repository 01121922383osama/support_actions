import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../data/models/note_model.dart';
import 'animated_note_card.dart';

class AnimatedNotesList extends StatelessWidget {
  final List<NoteModel> notes;
  final Function(NoteModel) onTap;
  final Function(NoteModel) onDelete;
  final Function(NoteModel) onComplete;
  final Function(int oldIndex, int newIndex)? onReorder;

  const AnimatedNotesList({
    super.key,
    required this.notes,
    required this.onTap,
    required this.onDelete,
    required this.onComplete,
    this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            )
                .animate(
                  onPlay: (controller) => controller.repeat(),
                )
                .scale(
                  duration: 2.seconds,
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.2, 1.2),
                )
                .then()
                .scale(
                  duration: 2.seconds,
                  begin: const Offset(1.2, 1.2),
                  end: const Offset(0.8, 0.8),
                ),
            const SizedBox(height: 16),
            Text(
              'No notes yet',
              style: Theme.of(context).textTheme.titleLarge,
            ).animate().fadeIn().slideY(),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to create one',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ).animate().fadeIn(delay: 200.ms).slideY(),
          ],
        ),
      );
    }

    if (onReorder != null) {
      return ReorderableListView.builder(
        itemCount: notes.length,
        padding: const EdgeInsets.all(8.0),
        proxyDecorator: (child, index, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final double animValue = Curves.easeInOut.transform(animation.value);
              final double elevation = lerpDouble(1, 6, animValue)!;
              final double scale = lerpDouble(1, 1.02, animValue)!;
              return Transform.scale(
                scale: scale,
                child: Material(
                  elevation: elevation,
                  color: Colors.transparent,
                  child: child,
                ),
              );
            },
            child: child,
          );
        },
        onReorder: onReorder!,
        itemBuilder: (context, index) {
          final note = notes[index];
          return AnimationConfiguration.staggeredList(
            key: ValueKey(note.id),
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: AnimatedNoteCard(
                  note: note,
                  onTap: () => onTap(note),
                  onDelete: () => onDelete(note),
                  onComplete: () => onComplete(note),
                ),
              ),
            ),
          );
        },
      );
    }

    return AnimationLimiter(
      child: ListView.builder(
        itemCount: notes.length,
        padding: const EdgeInsets.all(8.0),
        itemBuilder: (context, index) {
          final note = notes[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: AnimatedNoteCard(
                  note: note,
                  onTap: () => onTap(note),
                  onDelete: () => onDelete(note),
                  onComplete: () => onComplete(note),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

double? lerpDouble(num? a, num? b, double t) {
  if (a == null && b == null) return null;
  a ??= 0.0;
  b ??= 0.0;
  return a + (b - a) * t;
}
