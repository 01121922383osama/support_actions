import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/notes_bloc.dart';

class FilterDialog extends StatefulWidget {
  const FilterDialog({super.key});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  String? selectedCategory;
  bool showCompleted = true;
  bool showPending = true;
  DateTime? fromDate;
  DateTime? toDate;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filter Notes',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ).animate().fadeIn().slideY(begin: -0.2),
              const SizedBox(height: 24),
              _buildCategoryFilter().animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 16),
              _buildStatusFilter().animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),
              _buildDateFilter().animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedCategory = null;
                        showCompleted = true;
                        showPending = true;
                        fromDate = null;
                        toDate = null;
                      });
                    },
                    child: const Text('Reset'),
                  ).animate().scale(delay: 400.ms),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      context.read<NotesBloc>().add(
                            FilterNotes(
                              category: selectedCategory,
                              isCompleted: showCompleted,
                              startDate: fromDate,
                              endDate: toDate,
                            ),
                          );
                      Navigator.pop(context);
                    },
                    child: const Text('Apply'),
                  ).animate().scale(delay: 400.ms),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().scale(duration: 300.ms, curve: Curves.easeOut);
  }

  Widget _buildCategoryFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                'Homework',
                'Test',
                'Project',
                'Meeting',
                'Other',
              ].map((category) {
                final isSelected = selectedCategory == category;
                return FilterChip(
                  selected: isSelected,
                  label: Text(category),
                  onSelected: (selected) {
                    setState(() {
                      selectedCategory = selected ? category : null;
                    });
                  },
                  showCheckmark: false,
                  avatar: isSelected
                      ? Icon(Icons.check,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                ).animate(target: isSelected ? 1 : 0).scale();
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilterChip(
                    selected: showCompleted,
                    label: const Text('Completed'),
                    onSelected: (value) {
                      setState(() {
                        showCompleted = value;
                      });
                    },
                  ).animate(target: showCompleted ? 1 : 0).scale(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChip(
                    selected: showPending,
                    label: const Text('Pending'),
                    onSelected: (value) {
                      setState(() {
                        showPending = value;
                      });
                    },
                  ).animate(target: showPending ? 1 : 0).scale(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date Range',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: fromDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2025),
                      );
                      if (date != null) {
                        setState(() {
                          fromDate = date;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                        fromDate?.toString().split(' ')[0] ?? 'Start Date'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: toDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2025),
                      );
                      if (date != null) {
                        setState(() {
                          toDate = date;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(toDate?.toString().split(' ')[0] ?? 'End Date'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
