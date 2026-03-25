import 'package:flutter/material.dart';

import '../../features/analytics/screens/analytics_screen.dart';
import '../../features/calendar/screens/calendar_screen.dart';
import '../../features/calendar/screens/event_form_screen.dart';
import '../../features/calendar/screens/event_list_screen.dart';
import '../../features/calendar/screens/google_calendar_sync_screen.dart';
import '../../features/calendar/screens/unified_timeline_screen.dart';
import '../../features/financial/screens/financial_screen.dart';
import '../../features/financial/screens/budget_management_screen.dart';
import '../../features/financial/screens/financial_home_screen.dart';
import '../../features/financial/screens/financial_reports_screen.dart';
import '../../features/financial/screens/transaction_form_screen.dart';
import '../../features/financial/screens/transaction_list_screen.dart';
import '../../features/habits/screens/habits_screen.dart';
import '../../features/habits/screens/daily_events_screen.dart';
import '../../features/habits/screens/habit_detail_screen.dart';
import '../../features/habits/screens/habit_form_screen.dart';
import '../../features/habits/screens/habits_home_screen.dart';
import '../../features/habits/screens/mood_tracker_screen.dart';
import '../../features/health/screens/health_screen.dart';
import '../../features/health/screens/blood_tests_screen.dart';
import '../../features/health/screens/health_home_screen.dart';
import '../../features/health/screens/health_metrics_screen.dart';
import '../../features/health/screens/medication_form_screen.dart';
import '../../features/health/screens/medication_list_screen.dart';
import '../../features/notes/screens/notes_screen.dart';
import '../../features/notes/screens/note_categories_screen.dart';
import '../../features/notes/screens/note_editor_screen.dart';
import '../../features/notes/screens/notes_home_screen.dart';
import '../../features/notes/screens/search_results_screen.dart';
import '../../features/notes/screens/todo_list_screen.dart';
import '../../features/religious/screens/prayer_logs_screen.dart';
import '../../features/religious/screens/prayer_log_screen.dart';
import '../../features/religious/screens/quran_reading_screen.dart';
import '../../features/religious/screens/quran_progress_screen.dart';
import '../../features/religious/screens/religious_home_screen.dart';
import '../../features/religious/screens/spiritual_progress_screen.dart';
import '../../features/security/screens/security_screen.dart';
import '../../features/security/screens/biometric_lock_screen.dart';
import '../../features/security/screens/credential_form_screen.dart';
import '../../features/security/screens/credential_list_screen.dart';
import '../../features/security/screens/password_generator_screen.dart';
import '../../features/security/screens/security_categories_screen.dart';
import '../../features/sports/screens/sports_screen.dart';
import '../../features/sports/screens/active_workout_screen.dart';
import '../../features/sports/screens/exercise_library_screen.dart';
import '../../features/sports/screens/progress_charts_screen.dart';
import '../../features/sports/screens/sports_home_screen.dart';
import '../../features/sports/screens/workout_list_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/backup_screen.dart';
import '../../features/settings/screens/restore_screen.dart';

class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case PrayerLogsScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const PrayerLogsScreen(),
          settings: settings,
        );
      case PrayerLogScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const PrayerLogScreen(),
          settings: settings,
        );
      case QuranProgressScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const QuranProgressScreen(),
          settings: settings,
        );
      case QuranReadingScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const QuranReadingScreen(),
          settings: settings,
        );
      case ReligiousHomeScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const ReligiousHomeScreen(),
          settings: settings,
        );
      case SpiritualProgressScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const SpiritualProgressScreen(),
          settings: settings,
        );
      case FinancialScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const FinancialScreen(),
          settings: settings,
        );
      case FinancialHomeScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const FinancialHomeScreen(),
          settings: settings,
        );
      case TransactionListScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const TransactionListScreen(),
          settings: settings,
        );
      case TransactionFormScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const TransactionFormScreen(),
          settings: settings,
        );
      case BudgetManagementScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const BudgetManagementScreen(),
          settings: settings,
        );
      case FinancialReportsScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const FinancialReportsScreen(),
          settings: settings,
        );
      case HabitsScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const HabitsScreen(),
          settings: settings,
        );
      case HabitsHomeScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const HabitsHomeScreen(),
          settings: settings,
        );
      case HabitDetailScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const HabitDetailScreen(),
          settings: settings,
        );
      case HabitFormScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const HabitFormScreen(),
          settings: settings,
        );
      case DailyEventsScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const DailyEventsScreen(),
          settings: settings,
        );
      case MoodTrackerScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const MoodTrackerScreen(),
          settings: settings,
        );
      case SportsScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const SportsScreen(),
          settings: settings,
        );
      case SportsHomeScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const SportsHomeScreen(),
          settings: settings,
        );
      case WorkoutListScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const WorkoutListScreen(),
          settings: settings,
        );
      case ActiveWorkoutScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const ActiveWorkoutScreen(),
          settings: settings,
        );
      case ExerciseLibraryScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const ExerciseLibraryScreen(),
          settings: settings,
        );
      case ProgressChartsScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const ProgressChartsScreen(),
          settings: settings,
        );
      case HealthScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const HealthScreen(),
          settings: settings,
        );
      case HealthHomeScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const HealthHomeScreen(),
          settings: settings,
        );
      case MedicationListScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const MedicationListScreen(),
          settings: settings,
        );
      case MedicationFormScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const MedicationFormScreen(),
          settings: settings,
        );
      case HealthMetricsScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const HealthMetricsScreen(),
          settings: settings,
        );
      case BloodTestsScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const BloodTestsScreen(),
          settings: settings,
        );
      case NotesScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const NotesScreen(),
          settings: settings,
        );
      case NotesHomeScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const NotesHomeScreen(),
          settings: settings,
        );
      case NoteEditorScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const NoteEditorScreen(),
          settings: settings,
        );
      case TodoListScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const TodoListScreen(),
          settings: settings,
        );
      case NoteCategoriesScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const NoteCategoriesScreen(),
          settings: settings,
        );
      case SearchResultsScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const SearchResultsScreen(),
          settings: settings,
        );
      case CalendarScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const CalendarScreen(),
          settings: settings,
        );
      case EventListScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const EventListScreen(),
          settings: settings,
        );
      case EventFormScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const EventFormScreen(),
          settings: settings,
        );
      case UnifiedTimelineScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const UnifiedTimelineScreen(),
          settings: settings,
        );
      case GoogleCalendarSyncScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const GoogleCalendarSyncScreen(),
          settings: settings,
        );
      case SecurityScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const SecurityScreen(),
          settings: settings,
        );
      case BiometricLockScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const BiometricLockScreen(),
          settings: settings,
        );
      case CredentialListScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const CredentialListScreen(),
          settings: settings,
        );
      case CredentialFormScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const CredentialFormScreen(),
          settings: settings,
        );
      case PasswordGeneratorScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const PasswordGeneratorScreen(),
          settings: settings,
        );
      case SecurityCategoriesScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const SecurityCategoriesScreen(),
          settings: settings,
        );
      case AnalyticsScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const AnalyticsScreen(),
          settings: settings,
        );
      case SettingsScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const SettingsScreen(),
          settings: settings,
        );
      case BackupScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const BackupScreen(),
          settings: settings,
        );
      case RestoreScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const RestoreScreen(),
          settings: settings,
        );
      default:
        return null;
    }
  }
}
