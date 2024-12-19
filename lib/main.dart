import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'core/presentation/pages/splash_screen.dart';
import 'core/presentation/theme/app_theme.dart';
import 'core/presentation/theme/theme_bloc.dart';
import 'core/services/reminder_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/notes/data/models/note_model.dart';
import 'features/notes/data/repositories/notes_repository_impl.dart';
import 'features/notes/domain/repositories/notes_repository.dart';
import 'features/notes/presentation/bloc/notes_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Timezone
  tz.initializeTimeZones();

  // Initialize Notification Service
  await ReminderService.init();
  // Initialize Local Notifications
  await ReminderService.initializeLocalNotifications();

  await ReminderService.startListeningNotificationEvents();

  // Register web background service if on web platform
  if (kIsWeb) {
    await ReminderService.registerBackgroundService();
  } else {
    await ReminderService.startListeningNotificationEvents();
  }

  // Initialize Notification Service
  await ReminderService.scheduleNotification(
    id: 'test',
    title: 'Test Notification',
    body: 'This is a test notification',
    // add this time 12/19/2024 at 5:46 pm
    scheduledTime: DateTime(2024, 12, 19, 17, 47, 0),
  );

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://hrlvovkqcnzyivhgxiwx.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhybHZvdmtxY256eWl2aGd4aXd4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ1MjU5ODQsImV4cCI6MjA1MDEwMTk4NH0.NjFHwUsjP36RRUUA9ZOvvHa1MAgj-h9qCZ90P9WOO0Y',
    debug: true,
  );

  // Initialize Hive
  if (kIsWeb) {
    await Hive.initFlutter('support_notes');
  } else {
    await Hive.initFlutter();
  }

  Hive.registerAdapter(NoteModelAdapter());

  // Open Hive boxes
  final notesBox = await Hive.openBox<NoteModel>('notes');
  final deletedNotesBox = await Hive.openBox<NoteModel>('deleted_notes');

  // Initialize Repository
  final notesRepository = NotesRepositoryImpl(
    supabaseClient: Supabase.instance.client,
    notesBox: notesBox,
    deletedNotesBox: deletedNotesBox,
  );

  runApp(MyApp(
    notesRepository: notesRepository,
  ));
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
            create: (context) => ThemeBloc(),
          ),
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              supabase: Supabase.instance.client,
            )..add(CheckAuthStatus()),
          ),
          BlocProvider<NotesBloc>(
            create: (context) => NotesBloc(
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
                          start: 801, end: double.infinity, name: DESKTOP),
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
