import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/widgets/animated_app_bar.dart';
import '../../../../core/presentation/widgets/loading_animation.dart';
import '../bloc/notes_bloc.dart';
import '../widgets/animated_notes_list.dart';

class RecycleBinPage extends StatelessWidget {
  const RecycleBinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AnimatedAppBar(
        title: 'Recycle Bin',
        showSearchField: true,
        onSearch: (query) {
          // TODO: Implement search
        },
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Empty Recycle Bin')
                      .animate()
                      .fadeIn()
                      .scale(),
                  content: const Text(
                    'Are you sure you want to permanently delete all notes?',
                  ).animate().fadeIn(delay: 200.ms).slideY(),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ).animate().scale(delay: 400.ms),
                    FilledButton(
                      onPressed: () {
                        context.read<NotesBloc>().add(DeleteAllNotes());
                        Navigator.pop(context);
                      },
                      child: const Text('Delete All'),
                    ).animate().scale(delay: 400.ms),
                  ],
                ).animate().scale(),
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
            if (state.deletedNotes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    )
                        .animate()
                        .scale(duration: 500.ms)
                        .then()
                        .shake(duration: 500.ms),
                    const SizedBox(height: 16),
                    Text(
                      'Recycle Bin is Empty',
                      style: Theme.of(context).textTheme.titleLarge,
                    ).animate().fadeIn().slideY(),
                    const SizedBox(height: 8),
                    Text(
                      'Deleted notes will appear here',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ).animate().fadeIn(delay: 200.ms).slideY(),
                  ],
                ),
              );
            }
            return AnimatedNotesList(
              notes: state.deletedNotes,
              onTap: (_) {}, // Disabled in recycle bin
              onDelete: (note) {
                context.read<NotesBloc>().add(DeleteNotePermanently(note.id));
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Note permanently deleted'),
                    ),
                  );
              },
              onComplete: (note) {
                context.read<NotesBloc>().add(RestoreNote(note.id));
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Note restored'),
                    ),
                  );
              },
            );
          }
          return const Center(child: Text('Something went wrong'));
        },
      ),
    );
  }
}
