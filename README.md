# Support Notes App

A Flutter application for managing teacher-student support notes with features like reminders, categories, and offline support.

## Features

- Create, read, update, and delete support notes
- Categorize notes and filter by status, category, and date
- Set hourly reminders for important notes
- Offline support with local storage
- Recycle bin for deleted notes
- Responsive design for mobile, tablet, and web

## Tech Stack

- **Frontend**: Flutter with Material Design 3
- **State Management**: BLoC pattern with flutter_bloc
- **Backend**: Supabase for real-time database and authentication
- **Local Storage**: Hive for offline data persistence
- **Notifications**: flutter_local_notifications
- **Architecture**: Clean Architecture with MVVM pattern

## Setup Instructions

1. **Prerequisites**
   - Flutter SDK (latest stable version)
   - Dart SDK
   - Android Studio / VS Code with Flutter extensions
   - A Supabase account

2. **Clone the Repository**
   ```bash
   git clone [repository-url]
   cd support_actions
   ```

3. **Install Dependencies**
   ```bash
   flutter pub get
   ```

4. **Supabase Setup**
   - Create a new Supabase project
   - Run the SQL migration script from `supabase/migrations/20231218_create_notes_table.sql`
   - Update `supabaseUrl` and `supabaseAnonKey` in `lib/main.dart` with your project credentials

5. **Run the App**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── core/
│   ├── error/
│   │   └── failures.dart
│   └── services/
│       └── notification_service.dart
├── features/
│   └── notes/
│       ├── data/
│       │   ├── models/
│       │   │   └── note_model.dart
│       │   └── repositories/
│       │       └── notes_repository_impl.dart
│       ├── domain/
│       │   └── repositories/
│       │       └── notes_repository.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── notes_bloc.dart
│           │   ├── notes_event.dart
│           │   └── notes_state.dart
│           ├── pages/
│           │   ├── home_page.dart
│           │   └── recycle_bin_page.dart
│           └── widgets/
│               ├── note_form_dialog.dart
│               └── filter_dialog.dart
└── main.dart
```

## Key Features Implementation

### 1. Note Management
- CRUD operations with real-time sync
- Local caching for offline support
- Soft delete with recycle bin functionality

### 2. Reminders
- Hourly notifications until note is marked as completed
- Customizable reminder messages
- Background notification support

### 3. Filtering & Categories
- Filter by completion status
- Category-based organization
- Date range filtering

### 4. Responsive Design
- Adaptive UI for different screen sizes
- Material Design 3 components
- Consistent experience across platforms

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
