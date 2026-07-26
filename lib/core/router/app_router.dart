import 'package:flutter/material.dart';

import '../../features/analytics/screens/analytics_screen.dart';
import '../../features/calendar/screens/calendar_screen.dart';
import '../../features/calendar/screens/event_form_screen.dart';
import '../../features/calendar/screens/event_list_screen.dart';
import '../../features/calendar/screens/google_calendar_sync_screen.dart';
import '../../features/calendar/screens/unified_timeline_screen.dart';
import '../../features/financial/screens/financial_screen.dart';
import '../../features/financial/screens/accounts_page.dart';
import '../../features/financial/screens/budgets_page.dart';
import '../../features/financial/screens/categories_page.dart';
import '../../features/financial/screens/financial_activity_log_screen.dart';
import '../../features/financial/screens/transactions_page.dart';
import '../../features/financial/screens/transaction_form_screen.dart';
import '../../data/models/financial/transaction_model.dart';
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
import '../../features/planning/screens/achievements_screen.dart';
import '../../features/planning/screens/day_planning_screen.dart';
import '../../features/planning/screens/goals_screen.dart';
import '../../features/planning/screens/life_plan_screen.dart';
import '../../features/planning/screens/life_planning_topics_screen.dart';
import '../../features/planning/screens/planning_home_screen.dart';
import '../../features/planning/screens/reviews_screen.dart';
import '../../features/notes/screens/note_categories_screen.dart';
import '../../features/notes/screens/note_editor_screen.dart';
import '../../features/notes/screens/notes_home_screen.dart';
import '../../features/notes/screens/search_results_screen.dart';
import '../../features/notes/screens/todo_list_screen.dart';
import '../../features/religious/screens/athkar_history_screen.dart';
import '../../features/religious/screens/athkar_screen.dart';
import '../../features/religious/screens/bad_practice_screen.dart';
import '../../features/religious/screens/prayer_logs_screen.dart';
import '../../features/religious/screens/prayer_log_screen.dart';
import '../../features/religious/screens/quran_reading_screen.dart';
import '../../features/religious/screens/quran_progress_screen.dart';
import '../../features/religious/screens/religious_screen.dart';
import '../../features/religious/screens/religious_history_screen.dart';
import '../../features/religious/screens/spiritual_progress_screen.dart';
import '../../features/security/screens/security_screen.dart';
import '../../features/security/screens/biometric_lock_screen.dart';
import '../../features/security/screens/credential_form_screen.dart';
import '../../features/security/screens/credential_list_screen.dart';
import '../../features/security/screens/password_generator_screen.dart';
import '../../features/security/screens/security_categories_screen.dart';
import '../../features/sports/screens/calendar_view_screen.dart';
import '../../features/sports/screens/daily_log_screen.dart';
import '../../features/sports/screens/exercise_library_screen.dart';
import '../../features/sports/screens/sports_dashboard_screen.dart';
import '../../features/sports/screens/sports_screen.dart';
import '../../features/sports/screens/weekly_schedule_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/backup_screen.dart';
import '../../features/settings/screens/restore_screen.dart';
import '../../shared/widgets/log_viewer_screen.dart';
import '../../shared/widgets/database_viewer_screen.dart';

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
      case ReligiousScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const ReligiousScreen(),
          settings: settings,
        );
      case ReligiousHistoryScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const ReligiousHistoryScreen(),
          settings: settings,
        );
      case SpiritualProgressScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const SpiritualProgressScreen(),
          settings: settings,
        );
      case AthkarScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const AthkarScreen(),
          settings: settings,
        );
      case AthkarHistoryScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const AthkarHistoryScreen(),
          settings: settings,
        );
      case BadPracticeScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const BadPracticeScreen(),
          settings: settings,
        );
      case FinancialScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const FinancialScreen(),
          settings: settings,
        );
      case BudgetsPage.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const BudgetsPage(),
          settings: settings,
        );
      case TransactionsPage.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const TransactionsPage(),
          settings: settings,
        );
      case CategoriesPage.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const CategoriesPage(),
          settings: settings,
        );
      case AccountsPage.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const AccountsPage(),
          settings: settings,
        );
      case FinancialActivityLogScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const FinancialActivityLogScreen(),
          settings: settings,
        );
      case TransactionFormScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => TransactionFormScreen(
            transaction: settings.arguments as TransactionModel?,
          ),
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
      case DailyLogScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const DailyLogScreen(),
          settings: settings,
        );
      case WeeklyScheduleScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const WeeklyScheduleScreen(),
          settings: settings,
        );
      case ExerciseLibraryScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const ExerciseLibraryScreen(),
          settings: settings,
        );
      case SportsDashboardScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const SportsDashboardScreen(),
          settings: settings,
        );
      case CalendarViewScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const CalendarViewScreen(),
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
      case PlanningHomeScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const PlanningHomeScreen(),
          settings: settings,
        );
      case DayPlanningScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const DayPlanningScreen(),
          settings: settings,
        );
      case LifePlanningTopicsScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const LifePlanningTopicsScreen(),
          settings: settings,
        );
      case LifePlanScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const LifePlanScreen(),
          settings: settings,
        );
      case GoalsScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const GoalsScreen(),
          settings: settings,
        );
      case AchievementsScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const AchievementsScreen(),
          settings: settings,
        );
      case ReviewsScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const ReviewsScreen(),
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
      case '/dev/logs':
        return MaterialPageRoute<void>(
          builder: (_) => const LogViewerScreen(),
          settings: settings,
        );
      case '/dev/database':
        return MaterialPageRoute<void>(
          builder: (_) => const DatabaseViewerScreen(),
          settings: settings,
        );
      default:
        return null;
    }
  }
}
