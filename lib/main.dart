import 'dart:developer';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:support_actions/core/presentation/pages/splash_screen.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'core/presentation/theme/app_theme.dart';
import 'core/presentation/theme/theme_bloc.dart';
import 'core/services/reminder_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/notes/data/models/note_model.dart';
import 'features/notes/data/repositories/notes_repository_impl.dart';
import 'features/notes/domain/repositories/notes_repository.dart';
import 'features/notes/presentation/bloc/notes_bloc.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    await Supabase.initialize(
      url: 'https://hrlvovkqcnzyivhgxiwx.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhybHZvdmtxY256eWl2aGd4aXd4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ1MjU5ODQsImV4cCI6MjA1MDEwMTk4NH0.NjFHwUsjP36RRUUA9ZOvvHa1MAgj-h9qCZ90P9WOO0Y',
    );
    await Hive.initFlutter();
    // Initialize timezone
    tz.initializeTimeZones();

    // Initialize notification service
    await ReminderService.init();

    // Register Hive adapters
    Hive.registerAdapter(NoteModelAdapter());

    // Open Hive boxes
    try {
      await Future.wait([
        Hive.openBox('supabase_authentication'),
        Hive.openBox<NoteModel>('notes'),
        Hive.openBox<NoteModel>('deleted_notes'),
      ]);
      log('✅ Hive Boxes Opened Successfully');
    } catch (e, stackTrace) {
      log('❌ Error Opening Hive Boxes', error: e, stackTrace: stackTrace);
    }

    // Initialize repository
    final notesRepository = NotesRepositoryImpl(
      supabaseClient: Supabase.instance.client,
      notesBox: Hive.box<NoteModel>('notes'),
      deletedNotesBox: Hive.box<NoteModel>('deleted_notes'),
    );

    runApp(MyApp(notesRepository: notesRepository));
  } catch (e, stackTrace) {
    log('❌ Critical Initialization Error: $e',
        error: e, stackTrace: stackTrace);

    // Fallback error widget
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Failed to initialize app: $e'),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  final NotesRepository notesRepository;

  const MyApp({
    super.key,
    required this.notesRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<NotesRepository>.value(value: notesRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeBloc>(
            create: (_) => ThemeBloc(),
          ),
          BlocProvider<AuthBloc>(
            create: (_) => AuthBloc(
              supabase: Supabase.instance.client,
            )..add(CheckAuthStatus()),
          ),
          BlocProvider<NotesBloc>(
            create: (_) => NotesBloc(
              repository: notesRepository,
            )..add(LoadNotes()),
          ),
        ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return DynamicColorBuilder(
              builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: 'Support Notes',
                  themeMode: themeState.themeMode,
                  theme: AppTheme.lightTheme(lightDynamic),
                  darkTheme: AppTheme.darkTheme(darkDynamic),
                  builder: (context, child) => ResponsiveBreakpoints.builder(
                    child: child!,
                    breakpoints: [
                      const Breakpoint(start: 0, end: 450, name: MOBILE),
                      const Breakpoint(start: 451, end: 800, name: TABLET),
                      const Breakpoint(
                        start: 801,
                        end: double.infinity,
                        name: DESKTOP,
                      ),
                    ],
                  ),
                  home: const SplashScreen(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
