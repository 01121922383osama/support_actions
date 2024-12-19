import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/pages/settings_page.dart';
import '../../../../core/presentation/transitions/custom_page_transition.dart';
import '../../../../core/presentation/widgets/animated_app_bar.dart';
import '../../../../core/presentation/widgets/loading_animation.dart';
import '../../domain/entities/note.dart';
import '../bloc/notes_bloc.dart';
import '../widgets/animated_notes_list.dart';
import '../widgets/filter_dialog.dart';
import '../widgets/note_form_dialog.dart';
import 'recycle_bin_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AnimatedAppBar(
        title: 'Support Notes',
        showSearchField: true,
        onSearch: (query) {
          // TODO: Implement search
        },
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ).animate().scale(),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              Navigator.push(
                context,
                CustomPageTransition(page: const RecycleBinPage()),
              );
            },
          ).animate().scale(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                CustomPageTransition(page: const SettingsPage()),
              );
            },
          ).animate().scale(),
        ],
      ),
      body: BlocBuilder<NotesBloc, NotesState>(
        builder: (context, state) {
          if (state is NotesLoading) {
            return const LoadingAnimation();
          } else if (state is NotesError) {
            return Center(
              child: Text(state.message)
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(),
            );
          } else if (state is NotesLoaded) {
            if (state.notes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.note_add,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    )
                        .animate()
                        .scale(duration: 500.ms)
                        .then()
                        .shake(duration: 500.ms),
                    const SizedBox(height: 16),
                    Text(
                      'No notes yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ).animate().fadeIn().slideY(),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the + button to create one',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ).animate().fadeIn(delay: 200.ms).slideY(),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<NotesBloc>().add(LoadNotes());
              },
              child: AnimatedNotesList(
                notes: state.notes,
                onTap: (note) => _showNoteFormDialog(context, note.toEntity()),
                onDelete: (note) {
                  context.read<NotesBloc>().add(DeleteNote(note.id));
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: const Text('Note moved to recycle bin'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {
                            context.read<NotesBloc>().add(RestoreNote(note.id));
                          },
                        ),
                      ),
                    );
                },
                onComplete: (note) {
                  context.read<NotesBloc>().add(
                        UpdateNote(
                          note.copyWith(isCompleted: !note.isCompleted),
                        ),
                      );
                },
                onReorder: (oldIndex, newIndex) {
                  // TODO: Implement reordering logic
                },
              ),
            );
          }
          return const Center(
            child: Text('Something went wrong'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNoteFormDialog(context),
        label: const Text('Add Note'),
        icon: const Icon(Icons.add),
      )
          .animate(
            onPlay: (controller) => controller.repeat(),
          )
          .shimmer(
            duration: 2.seconds,
            color: Colors.white24,
            angle: 45,
            size: 3,
          )
          .animate()
          .scale(),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const FilterDialog(),
    );
  }

  void _showNoteFormDialog(BuildContext context, [Note? note]) {
    showDialog(
      context: context,
      builder: (context) => NoteFormDialog(note: note),
    );
  }
}
