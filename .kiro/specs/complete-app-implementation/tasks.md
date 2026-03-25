# Implementation Tasks - Abdalsalam Personal Life Management App

## Overview

This document breaks down the 25 requirements from the requirements document into actionable implementation tasks. Tasks are organized into 5 phases following the implementation strategy defined in the requirements.

**Total Requirements**: 25
**Total Phases**: 5
**Estimated Tasks**: 150+

## Task Status Legend

- `[ ]` Not started
- `[~]` Queued
- `[-]` In progress
- `[x]` Completed
- `[\]` Canceld
- `[ ]*` Optional task (not required for completion)

## Phase 1: Foundation (Requirements 1, 2, 13, 14, 15, 24)

### 1. Core Foundation & Architecture (Requirement 1)

- [x] 1.1 Create base classes and types
  - [x] 1.1.1 Implement BaseModel abstract class with id, createdAt, updatedAt, deletedAt
  - [x] 1.1.2 Implement Result<T, Error> type with Success and Failure classesm
  - [x] 1.1.3 Implement AppError hierarchy (DatabaseError, ValidationError, ServiceError, NotFoundError, ExportError, ImportError, NetworkError, AuthError)
  - [\] 1.1.4 Write unit tests for base classes and types

- [x] 1.2 Create BaseRepository interface and implementation
  - [x] 1.2.1 Define BaseRepository interface with 24 required methods
  - [x] 1.2.2 Implement BaseRepositoryImpl abstract class with common logic
  - [ ] 1.2.3 Write unit tests for BaseRepositoryImpl methods

- [x] 1.3 Create BaseService interface and implementation
  - [x] 1.3.1 Define BaseService interface with 29 required methods
  - [x] 1.3.2 Implement BaseServiceImpl abstract class with common logic
  - [ ] 1.3.3 Write unit tests for BaseServiceImpl methods

- [x] 1.4 Integrate abdalsalam_logic_flutter package
  - [x] 1.4.1 Add abdalsalam_logic_flutter dependency to pubspec.yaml
  - [x] 1.4.2 Initialize StorageGateway in main.dart
  - [x] 1.4.3 Initialize LoggerService in main.dart
  - [x] 1.4.4 Initialize AppStateManager with config in main.dart
  - [x] 1.4.5 Create Riverpod providers for core services


### 2. Data Export & Import System (Requirement 2)

- [x] 2.1 Implement export functionality
  - [x] 2.1.1 Create ExportService with exportWithMetadata method
  - [x] 2.1.2 Implement SHA-256 checksum calculation
  - [x] 2.1.3 Implement metadata generation (serviceName, version, exportedAt, recordCount, checksum)
  - [x] 2.1.4 Implement selective export by module, date range, and filters
  - [x] 2.1.5 Implement unified export for all modules
  - [ ] 2.1.6 Write unit tests for export functionality
  - [ ] 2.1.7 Write property-based test for Property 1 (Export Structure Completeness)
  - [ ] 2.1.8 Write property-based test for Property 2 (Export Checksum Integrity)

- [x] 2.2 Implement import functionality
  - [x] 2.2.1 Create ImportService with importWithValidation method
  - [x] 2.2.2 Implement metadata validation
  - [x] 2.2.3 Implement version compatibility checking
  - [x] 2.2.4 Implement checksum verification
  - [x] 2.2.5 Implement record-level validation
  - [x] 2.2.6 Implement duplicate detection and resolution (skip, replace, merge)
  - [ ] 2.2.7 Write unit tests for import functionality
  - [ ] 2.2.8 Write property-based test for Property 3 (Import Metadata Validation)
  - [ ] 2.2.9 Write property-based test for Property 4 (Import Checksum Verification)
  - [ ] 2.2.10 Write property-based test for Property 5 (Duplicate Detection Strategy)

- [x] 2.3 Implement file operations
  - [x] 2.3.1 Integrate FileOperations from abdalsalam_logic_flutter
  - [x] 2.3.2 Implement save export to device storage
  - [x] 2.3.3 Implement share export functionality
  - [x] 2.3.4 Implement load import from device storage
  - [ ] 2.3.5 Write integration tests for file operations

### 3. Offline-First Architecture (Requirement 13)

- [ ] 3.1 Configure local storage
  - [x] 3.1.1 Configure StorageGateway with SQLite backend
  - [x] 3.1.2 Create database schema for all modules
  - [x] 3.1.3 Create indexes on userId, date fields, and status
  - [ ] 3.1.4 Test database operations offline

- [x] 3.2 Implement offline indicators
  - [x] 3.2.1 Create offline banner widget
  - [x] 3.2.2 Add offline indicator to app bar
  - [x] 3.2.3 Listen to AppStateManager connectivity stream
  - [x] 3.2.4 Update UI based on online/offline state

- [x] 3.3 Implement sync queue
  - [x] 3.3.1 Create sync queue for operations when offline
  - [x] 3.3.2 Implement queue persistence
  - [x] 3.3.3 Implement automatic sync when connection restored
  - [ ] 3.3.4 Write tests for sync queue functionality

- [x] 3.4 Cache critical data
  - [x] 3.4.1 Implement prayer times caching (30 days)
  - [x] 3.4.2 Implement offline export to local storage
  - [x] 3.4.3 Implement offline import from local storage
  - [ ] 3.4.4 Write property-based test for Property 24 (Offline Operation Functionality)


### 4. State-Aware Operations (Requirement 14)

- [x] 4.1 Implement battery monitoring
  - [x] 4.1.1 Listen to AppStateManager battery stream
  - [x] 4.1.2 Defer non-critical operations when battery < 20%
  - [x] 4.1.3 Disable auto-sync when battery < 10%
  - [x] 4.1.4 Display battery warning indicator in UI

- [x] 4.2 Implement connectivity awareness
  - [x] 4.2.1 Listen to AppStateManager connectivity stream
  - [x] 4.2.2 Prompt before large sync on cellular
  - [x] 4.2.3 Auto-sync on WiFi if enabled
  - [x] 4.2.4 Display connectivity indicator in UI

- [x] 4.3 Implement storage monitoring
  - [x] 4.3.1 Listen to AppStateManager storage stream
  - [x] 4.3.2 Display warning when storage low
  - [x] 4.3.3 Suggest data cleanup options
  - [x] 4.3.4 Log storage state changes

- [x] 4.4 Implement state-aware settings
  - [x] 4.4.1 Add settings to override state-aware behavior
  - [x] 4.4.2 Add force sync option
  - [x] 4.4.3 Add disable battery optimization option
  - [x] 4.4.4 Persist settings using StorageGateway

### 5. Data Validation & Integrity (Requirement 15)

- [x] 5.1 Implement validation framework
  - [x] 5.1.1 Create validation utilities for common checks
  - [x] 5.1.2 Implement required field validation
  - [x] 5.1.3 Implement date validation (valid dates, logical ordering)
  - [x] 5.1.4 Implement numeric range validation
  - [x] 5.1.5 Implement enum validation
  - [x] 5.1.6 Implement foreign key validation
  - [x] 5.1.7 Implement email format validation
  - [x] 5.1.8 Implement URL format validation
  - [x] 5.1.9 Implement password strength validation
  - [ ] 5.1.10 Write unit tests for all validation utilities

- [x] 5.2 Implement validation in services
  - [x] 5.2.1 Add validate() method to all services
  - [x] 5.2.2 Call validate() before create/update operations
  - [x] 5.2.3 Return ValidationError with specific field errors
  - [ ] 5.2.4 Write property-based test for Property 25 (Entity Validation Before Persistence)
  - [ ] 5.2.5 Write property-based test for Property 26 (Date Range Validation)
  - [ ] 5.2.6 Write property-based test for Property 27 (Password Strength Validation)

- [x] 5.3 Implement user-friendly error messages
  - [x] 5.3.1 Create error message mapping for validation errors
  - [x] 5.3.2 Display validation errors in UI forms
  - [x] 5.3.3 Highlight invalid fields in forms
  - [ ] 5.3.4 Write widget tests for error display

### 6. Error Handling & Logging (Requirement 24)

- [x] 6.1 Implement logging infrastructure
  - [x] 6.1.1 Use LoggerService from abdalsalam_logic_flutter
  - [x] 6.1.2 Add [ServiceName] prefix to all service logs
  - [x] 6.1.3 Log all service operations (info level)
  - [x] 6.1.4 Log errors with error object and stack trace
  - [x] 6.1.5 Log warnings for recoverable issues
  - [x] 6.1.6 Log debug information for detailed debugging

- [x] 6.2 Implement error handling
  - [x] 6.2.1 Create ErrorHandler utility class
  - [x] 6.2.2 Catch all exceptions and convert to AppError types
  - [x] 6.2.3 Display user-friendly error messages in UI
  - [x] 6.2.4 Log technical details for debugging
  - [ ] 6.2.5 Write unit tests for error handling

- [x] 6.3 Implement lifecycle and state logging
  - [x] 6.3.1 Log app lifecycle events (startup, pause, resume, terminate)
  - [x] 6.3.2 Log state changes (online/offline, battery level)
  - [x] 6.3.3 Log state-aware decisions
  - [x] 6.3.4 Implement log export functionality


## Phase 2: Core Modules (Requirements 3, 4, 5, 6, 7, 8)

### 7. Religious Tracking Module (Requirement 3)

- [x] 7.1 Create data models
  - [x] 7.1.1 Implement PrayerLog model extending BaseModel
  - [x] 7.1.2 Implement QuranReading model extending BaseModel
  - [x] 7.1.3 Implement SpiritualProgress model extending BaseModel
  - [ ] 7.1.4 Write unit tests for model toJson/fromJson
  - [ ] 7.1.5 Write property-based test for Property 6 (Prayer Log Field Completeness)

- [x] 7.2 Create repository
  - [x] 7.2.1 Implement PrayerRepository interface
  - [x] 7.2.2 Implement PrayerRepositoryImpl extending BaseRepositoryImpl
  - [x] 7.2.3 Create database tables (prayer_logs, quran_readings, spiritual_progress)
  - [x] 7.2.4 Create indexes on userId, performedAt, prayerType
  - [ ] 7.2.5 Write unit tests for repository methods

- [x] 7.3 Create service
  - [x] 7.3.1 Implement ReligiousService extending BaseServiceImpl
  - [x] 7.3.2 Implement validate() method for prayer logs
  - [x] 7.3.3 Implement getStatistics() with prayer-specific metrics
  - [x] 7.3.4 Implement streak calculation logic
  - [x] 7.3.5 Implement completion rate calculation
  - [ ] 7.3.6 Write unit tests for service methods
  - [ ] 7.3.7 Write property-based test for Property 7 (Prayer Completion Statistics)
  - [ ] 7.3.8 Write property-based test for Property 8 (Prayer Streak Calculation)

- [x] 7.4 Implement prayer time calculation
  - [x] 7.4.1 Integrate prayer time calculation library
  - [x] 7.4.2 Calculate prayer times based on location and date
  - [x] 7.4.3 Cache prayer times for 30 days
  - [ ] 7.4.4 Write unit tests for prayer time calculation

- [x] 7.5 Create UI screens
  - [x] 7.5.1 Create ReligiousHomeScreen with overview
  - [x] 7.5.2 Create PrayerLogScreen with list and form
  - [x] 7.5.3 Create QuranReadingScreen with progress tracking
  - [x] 7.5.4 Create SpiritualProgressScreen with journal
  - [ ] 7.5.5 Write widget tests for screens

- [x] 7.6 Create UI widgets
  - [x] 7.6.1 Create PrayerTimeCard widget
  - [x] 7.6.2 Create PrayerStreakWidget
  - [x] 7.6.3 Create QuranProgressChart
  - [x] 7.6.4 Create PrayerCalendarHeatmap
  - [ ] 7.6.5 Write widget tests for components

- [x] 7.7 Implement prayer reminders
  - [x] 7.7.1 Schedule prayer reminders 10 minutes before each prayer
  - [x] 7.7.2 Handle notification taps to navigate to prayer log
  - [ ] 7.7.3 Write integration tests for reminders

### 8. Financial Management Module (Requirement 4)

- [x] 8.1 Create data models
  - [x] 8.1.1 Implement Transaction model extending BaseModel
  - [x] 8.1.2 Implement Category model extending BaseModel
  - [x] 8.1.3 Implement Budget model extending BaseModel
  - [ ] 8.1.4 Write unit tests for model toJson/fromJson
  - [ ] 8.1.5 Write property-based test for Property 9 (Transaction Field Completeness)

- [x] 8.2 Create repository
  - [x] 8.2.1 Implement FinancialRepository interface
  - [x] 8.2.2 Implement FinancialRepositoryImpl extending BaseRepositoryImpl
  - [x] 8.2.3 Create database tables (transactions, categories, budgets)
  - [x] 8.2.4 Create indexes on userId, date, categoryId, type
  - [ ] 8.2.5 Write unit tests for repository methods

- [x] 8.3 Create service
  - [x] 8.3.1 Implement FinancialService extending BaseServiceImpl
  - [x] 8.3.2 Implement validate() method for transactions
  - [x] 8.3.3 Implement getStatistics() with financial metrics
  - [x] 8.3.4 Implement running balance calculation
  - [x] 8.3.5 Implement category breakdown calculation
  - [x] 8.3.6 Implement budget alert checking
  - [ ] 8.3.7 Write unit tests for service methods
  - [ ] 8.3.8 Write property-based test for Property 10 (Running Balance Calculation)
  - [ ] 8.3.9 Write property-based test for Property 11 (Budget Alert Trigger)

- [x] 8.4 Create predefined categories
  - [x] 8.4.1 Create default categories (Food, Transport, Health, Entertainment, Bills, Salary, Investment)
  - [x] 8.4.2 Support custom category creation
  - [x] 8.4.3 Support subcategories with parentCategoryId
  - [ ] 8.4.4 Write unit tests for category management

- [x] 8.5 Create UI screens
  - [x] 8.5.1 Create FinancialHomeScreen with balance and summary
  - [x] 8.5.2 Create TransactionListScreen with search and filter
  - [x] 8.5.3 Create TransactionFormScreen
  - [x] 8.5.4 Create BudgetManagementScreen
  - [x] 8.5.5 Create FinancialReportsScreen with charts
  - [ ] 8.5.6 Write widget tests for screens

- [x] 8.6 Create UI widgets
  - [x] 8.6.1 Create BalanceCard widget
  - [x] 8.6.2 Create CategoryPieChart widget
  - [x] 8.6.3 Create MonthlySpendingChart widget
  - [x] 8.6.4 Create BudgetProgressBar widget
  - [ ] 8.6.5 Write widget tests for components

- [x] 8.7 Implement budget alerts
  - [x] 8.7.1 Check budget threshold on transaction creation
  - [x] 8.7.2 Send notification when threshold exceeded
  - [ ] 8.7.3 Write integration tests for budget alerts


### 9. Habits & Daily Events Module (Requirement 5)

- [x] 9.1 Create data models
  - [x] 9.1.1 Implement Habit model extending BaseModel
  - [x] 9.1.2 Implement HabitLog model extending BaseModel
  - [x] 9.1.3 Implement DailyEvent model extending BaseModel
  - [ ] 9.1.4 Write unit tests for model toJson/fromJson
  - [ ] 9.1.5 Write property-based test for Property 12 (Habit Log Field Completeness)

- [x] 9.2 Create repository
  - [x] 9.2.1 Implement HabitsRepository interface
  - [x] 9.2.2 Implement HabitsRepositoryImpl extending BaseRepositoryImpl
  - [x] 9.2.3 Create database tables (habits, habit_logs, daily_events)
  - [x] 9.2.4 Create indexes on userId, completedAt, habitId
  - [ ] 9.2.5 Write unit tests for repository methods

- [x] 9.3 Create service
  - [x] 9.3.1 Implement HabitsService extending BaseServiceImpl
  - [x] 9.3.2 Implement validate() method for habits
  - [x] 9.3.3 Implement getStatistics() with habit metrics
  - [x] 9.3.4 Implement streak calculation logic
  - [x] 9.3.5 Implement completion rate calculation
  - [x] 9.3.6 Implement pattern analysis
  - [ ] 9.3.7 Write unit tests for service methods
  - [ ] 9.3.8 Write property-based test for Property 13 (Habit Streak Calculation)

- [x] 9.4 Create UI screens
  - [x] 9.4.1 Create HabitsHomeScreen with active habits
  - [x] 9.4.2 Create HabitDetailScreen with calendar and stats
  - [x] 9.4.3 Create HabitFormScreen
  - [x] 9.4.4 Create DailyEventsScreen with journal
  - [x] 9.4.5 Create MoodTrackerScreen
  - [ ] 9.4.6 Write widget tests for screens

- [x] 9.5 Create UI widgets
  - [x] 9.5.1 Create HabitCard widget with check-in button
  - [x] 9.5.2 Create CompletionCalendar widget
  - [x] 9.5.3 Create MoodTrendChart widget
  - [x] 9.5.4 Create StreakBadge widget
  - [ ] 9.5.5 Write widget tests for components

- [x] 9.6 Implement habit reminders
  - [x] 9.6.1 Schedule habit reminders at configured times
  - [x] 9.6.2 Handle notification taps to navigate to habit
  - [ ] 9.6.3 Write integration tests for reminders

### 10. Sports & Fitness Module (Requirement 6)

- [x] 10.1 Create data models
  - [x] 10.1.1 Implement Workout model extending BaseModel
  - [x] 10.1.2 Implement Exercise model extending BaseModel
  - [x] 10.1.3 Implement WorkoutSchedule model extending BaseModel
  - [ ] 10.1.4 Write unit tests for model toJson/fromJson
  - [ ] 10.1.5 Write property-based test for Property 14 (Workout Field Completeness)

- [x] 10.2 Create repository
  - [x] 10.2.1 Implement SportsRepository interface
  - [x] 10.2.2 Implement SportsRepositoryImpl extending BaseRepositoryImpl
  - [x] 10.2.3 Create database tables (workouts, exercises, workout_schedules)
  - [x] 10.2.4 Create indexes on userId, startTime, workoutId
  - [ ] 10.2.5 Write unit tests for repository methods

- [x] 10.3 Create service
  - [x] 10.3.1 Implement SportsService extending BaseServiceImpl
  - [x] 10.3.2 Implement validate() method for workouts
  - [x] 10.3.3 Implement getStatistics() with fitness metrics
  - [x] 10.3.4 Implement personal record tracking
  - [x] 10.3.5 Implement progress calculation
  - [ ] 10.3.6 Write unit tests for service methods
  - [ ] 10.3.7 Write property-based test for Property 15 (Workout Statistics Calculation)

- [x] 10.4 Create exercise library
  - [x] 10.4.1 Create predefined exercise list with instructions
  - [x] 10.4.2 Add muscle group categorization
  - [x] 10.4.3 Support custom exercise creation
  - [ ] 10.4.4 Write unit tests for exercise library

- [x] 10.5 Create UI screens
  - [x] 10.5.1 Create SportsHomeScreen with recent workouts
  - [x] 10.5.2 Create WorkoutListScreen with search and filter
  - [x] 10.5.3 Create ActiveWorkoutScreen with timer
  - [x] 10.5.4 Create ExerciseLibraryScreen
  - [x] 10.5.5 Create ProgressChartsScreen
  - [ ] 10.5.6 Write widget tests for screens

- [x] 10.6 Create UI widgets
  - [x] 10.6.1 Create WorkoutCard widget
  - [x] 10.6.2 Create RestTimer widget
  - [x] 10.6.3 Create ProgressChart widget
  - [x] 10.6.4 Create PRBadge widget
  - [ ] 10.6.5 Write widget tests for components

- [x] 10.7 Implement workout templates
  - [x] 10.7.1 Create workout template system
  - [x] 10.7.2 Support quick logging from templates
  - [ ] 10.7.3 Write unit tests for templates


### 11. Health Management Module (Requirement 7)

- [x] 11.1 Create data models
  - [x] 11.1.1 Implement Medication model extending BaseModel
  - [x] 11.1.2 Implement MedicationLog model extending BaseModel
  - [x] 11.1.3 Implement BloodTest model extending BaseModel
  - [x] 11.1.4 Implement HealthMetric model extending BaseModel
  - [ ] 11.1.5 Write unit tests for model toJson/fromJson
  - [ ] 11.1.6 Write property-based test for Property 16 (Medication Field Completeness)

- [x] 11.2 Create repository
  - [x] 11.2.1 Implement HealthRepository interface
  - [x] 11.2.2 Implement HealthRepositoryImpl extending BaseRepositoryImpl
  - [x] 11.2.3 Create database tables (medications, medication_logs, blood_tests, health_metrics)
  - [x] 11.2.4 Create indexes on userId, takenAt, medicationId, measuredAt
  - [ ] 11.2.5 Write unit tests for repository methods

- [x] 11.3 Create service
  - [x] 11.3.1 Implement HealthService extending BaseServiceImpl
  - [x] 11.3.2 Implement validate() method for medications
  - [x] 11.3.3 Implement getStatistics() with health metrics
  - [x] 11.3.4 Implement adherence rate calculation
  - [x] 11.3.5 Implement metric trend analysis
  - [ ] 11.3.6 Write unit tests for service methods
  - [ ] 11.3.7 Write property-based test for Property 17 (Medication Adherence Rate)

- [x] 11.4 Create UI screens
  - [x] 11.4.1 Create HealthHomeScreen with today's medications
  - [x] 11.4.2 Create MedicationListScreen
  - [x] 11.4.3 Create MedicationFormScreen
  - [x] 11.4.4 Create HealthMetricsScreen with charts
  - [x] 11.4.5 Create BloodTestsScreen
  - [ ] 11.4.6 Write widget tests for screens

- [x] 11.5 Create UI widgets
  - [x] 11.5.1 Create MedicationScheduleCard widget
  - [x] 11.5.2 Create AdherenceRateWidget
  - [x] 11.5.3 Create HealthMetricChart widget
  - [x] 11.5.4 Create RefillReminderBadge widget
  - [ ] 11.5.5 Write widget tests for components

- [x] 11.6 Implement medication reminders
  - [x] 11.6.1 Schedule medication reminders at configured times
  - [x] 11.6.2 Send refill reminders 3 days before refillDate
  - [x] 11.6.3 Handle notification taps to navigate to medication log
  - [ ] 11.6.4 Write integration tests for reminders

### 12. Notes & Tasks Module (Requirement 8)

- [x] 12.1 Create data models
  - [x] 12.1.1 Implement Note model extending BaseModel
  - [x] 12.1.2 Implement Todo model extending BaseModel
  - [x] 12.1.3 Implement NoteCategory model extending BaseModel
  - [ ] 12.1.4 Write unit tests for model toJson/fromJson
  - [ ] 12.1.5 Write property-based test for Property 18 (Note Field Completeness)
  - [ ] 12.1.6 Write property-based test for Property 19 (Todo Field Completeness)

- [x] 12.2 Create repository
  - [x] 12.2.1 Implement NotesRepository interface
  - [x] 12.2.2 Implement NotesRepositoryImpl extending BaseRepositoryImpl
  - [x] 12.2.3 Create database tables (notes, todos, note_categories)
  - [x] 12.2.4 Create indexes on userId, createdAt, categoryId, status
  - [ ] 12.2.5 Write unit tests for repository methods

- [x] 12.3 Create service
  - [x] 12.3.1 Implement NotesService extending BaseServiceImpl
  - [x] 12.3.2 Implement validate() method for notes and todos
  - [x] 12.3.3 Implement getStatistics() with notes metrics
  - [x] 12.3.4 Implement full-text search functionality
  - [x] 12.3.5 Implement tag-based filtering
  - [ ] 12.3.6 Write unit tests for service methods
  - [ ] 12.3.7 Write property-based test for Property 28 (Note Search Inclusion)

- [x] 12.4 Implement rich text editor
  - [x] 12.4.1 Integrate rich text editor package
  - [x] 12.4.2 Support bold, italic, underline formatting
  - [x] 12.4.3 Support ordered and unordered lists
  - [x] 12.4.4 Support headings
  - [ ] 12.4.5 Write widget tests for editor

- [x] 12.5 Create UI screens
  - [x] 12.5.1 Create NotesHomeScreen with list
  - [x] 12.5.2 Create NoteEditorScreen with rich text
  - [x] 12.5.3 Create TodoListScreen with filters
  - [x] 12.5.4 Create CategoriesScreen
  - [x] 12.5.5 Create SearchResultsScreen with highlighting
  - [ ] 12.5.6 Write widget tests for screens

- [x] 12.6 Create UI widgets
  - [x] 12.6.1 Create NoteCard widget
  - [x] 12.6.2 Create TodoItem widget
  - [x] 12.6.3 Create RichTextEditor widget
  - [x] 12.6.4 Create TagChip widget
  - [ ] 12.6.5 Write widget tests for components

- [x] 12.7 Implement todo reminders
  - [x] 12.7.1 Schedule todo reminders at configured reminderAt time
  - [x] 12.7.2 Handle notification taps to navigate to todo
  - [ ] 12.7.3 Write integration tests for reminders


## Phase 3: Integration (Requirements 9, 10, 11, 12)

### 13. Calendar Integration Module (Requirement 9)

- [x] 13.1 Create data models
  - [x] 13.1.1 Implement Event model extending BaseModel
  - [x] 13.1.2 Implement Reminder model extending BaseModel
  - [ ] 13.1.3 Write unit tests for model toJson/fromJson
  - [ ] 13.1.4 Write property-based test for Property 20 (Event Field Completeness)

- [x] 13.2 Create repository
  - [x] 13.2.1 Implement CalendarRepository interface
  - [x] 13.2.2 Implement CalendarRepositoryImpl extending BaseRepositoryImpl
  - [x] 13.2.3 Create database tables (events, reminders)
  - [x] 13.2.4 Create indexes on userId, startTime, eventId
  - [ ] 13.2.5 Write unit tests for repository methods

- [x] 13.3 Create service
  - [x] 13.3.1 Implement CalendarService extending BaseServiceImpl
  - [x] 13.3.2 Implement validate() method for events
  - [x] 13.3.3 Implement getStatistics() with calendar metrics
  - [x] 13.3.4 Implement unified calendar view (all modules)
  - [ ] 13.3.5 Write unit tests for service methods

- [x] 13.4 Implement Google Calendar sync
  - [x] 13.4.1 Integrate googleapis and google_sign_in packages
  - [x] 13.4.2 Implement OAuth authentication for Google Calendar
  - [x] 13.4.3 Implement pull events from Google Calendar
  - [x] 13.4.4 Implement push events to Google Calendar
  - [x] 13.4.5 Handle sync conflicts
  - [ ] 13.4.6 Write integration tests for sync

- [x] 13.5 Create UI screens
  - [x] 13.5.1 Create CalendarScreen with month/week/day views
  - [x] 13.5.2 Create EventListScreen (agenda view)
  - [x] 13.5.3 Create EventFormScreen
  - [x] 13.5.4 Create UnifiedTimelineScreen (all modules)
  - [x] 13.5.5 Create GoogleCalendarSyncScreen
  - [ ] 13.5.6 Write widget tests for screens

- [x] 13.6 Create UI widgets
  - [x] 13.6.1 Create CalendarGrid widget (month view)
  - [x] 13.6.2 Create EventCard widget
  - [x] 13.6.3 Create TimelineView widget (day view)
  - [x] 13.6.4 Create SyncStatusIndicator widget
  - [ ] 13.6.5 Write widget tests for components

- [x] 13.7 Implement event reminders
  - [x] 13.7.1 Schedule event reminders at configured reminderMinutes before event
  - [x] 13.7.2 Support multiple reminders per event
  - [x] 13.7.3 Handle notification taps to navigate to event
  - [ ] 13.7.4 Write integration tests for reminders

### 14. Security Vault Module (Requirement 10)

- [x] 14.1 Create data models
  - [x] 14.1.1 Implement Credential model extending BaseModel
  - [x] 14.1.2 Implement CredentialCategory model extending BaseModel
  - [ ] 14.1.3 Write unit tests for model toJson/fromJson

- [x] 14.2 Implement encryption
  - [x] 14.2.1 Integrate flutter_secure_storage package
  - [x] 14.2.2 Integrate encrypt package for AES-256
  - [x] 14.2.3 Generate and store encryption keys securely
  - [x] 14.2.4 Implement password encryption method
  - [x] 14.2.5 Implement password decryption method
  - [ ] 14.2.6 Write unit tests for encryption/decryption
  - [ ] 14.2.7 Write property-based test for Property 21 (Password Encryption Round Trip)

- [x] 14.3 Implement biometric authentication
  - [x] 14.3.1 Integrate local_auth package
  - [x] 14.3.2 Check biometric availability
  - [x] 14.3.3 Implement biometric authentication flow
  - [x] 14.3.4 Implement auto-lock after 5 minutes inactivity
  - [ ] 14.3.5 Write integration tests for biometric auth

- [x] 14.4 Create repository
  - [x] 14.4.1 Implement SecurityRepository interface
  - [x] 14.4.2 Implement SecurityRepositoryImpl extending BaseRepositoryImpl
  - [x] 14.4.3 Create database tables (credentials, credential_categories)
  - [x] 14.4.4 Create indexes on userId, title, website
  - [ ] 14.4.5 Write unit tests for repository methods

- [x] 14.5 Create service
  - [x] 14.5.1 Implement SecurityService extending BaseServiceImpl
  - [x] 14.5.2 Implement validate() method for credentials
  - [x] 14.5.3 Implement getStatistics() with vault metrics
  - [x] 14.5.4 Implement password strength calculation
  - [x] 14.5.5 Implement password generator
  - [x] 14.5.6 Implement auto-clear clipboard after 30 seconds
  - [ ] 14.5.7 Write unit tests for service methods
  - [ ] 14.5.8 Write property-based test for Property 22 (Password Strength Calculation)

- [x] 14.6 Create UI screens
  - [x] 14.6.1 Create BiometricLockScreen
  - [x] 14.6.2 Create CredentialListScreen with masked passwords
  - [x] 14.6.3 Create CredentialFormScreen
  - [x] 14.6.4 Create PasswordGeneratorScreen
  - [x] 14.6.5 Create CategoriesScreen
  - [ ] 14.6.6 Write widget tests for screens

- [x] 14.7 Create UI widgets
  - [x] 14.7.1 Create BiometricLockScreen widget
  - [x] 14.7.2 Create CredentialCard widget with reveal button
  - [x] 14.7.3 Create PasswordStrengthIndicator widget
  - [x] 14.7.4 Create PasswordGenerator widget
  - [ ] 14.7.5 Write widget tests for components

- [x] 14.8 Implement password expiry reminders
  - [x] 14.8.1 Send reminder 7 days before expiryDate
  - [x] 14.8.2 Handle notification taps to navigate to credential
  - [ ] 14.8.3 Write integration tests for reminders


### 15. Dashboard & Analytics Module (Requirement 11)

- [x] 15.1 Create dashboard UI
  - [x] 15.1.1 Create DashboardScreen with module cards
  - [x] 15.1.2 Create TodayAgendaCard with upcoming items
  - [x] 15.1.3 Implement pull-to-refresh functionality
  - [x] 15.1.4 Display app state indicators (offline, low battery)
  - [ ] 15.1.5 Write widget tests for dashboard

- [x] 15.2 Create module cards
  - [x] 15.2.1 Create ModuleCard widget with icon, title, stats
  - [x] 15.2.2 Implement tap navigation to module detail
  - [x] 15.2.3 Display key statistics for each module
  - [ ] 15.2.4 Write widget tests for module cards
  - [ ] 15.2.5 Write property-based test for Property 23 (Dashboard Statistics Display)

- [x] 15.3 Implement quick add functionality
  - [x] 15.3.1 Create QuickAddModal with tabs for each module
  - [x] 15.3.2 Implement quick forms with minimal fields
  - [x] 15.3.3 Use smart defaults (current time, today's date)
  - [x] 15.3.4 Implement save and continue option
  - [ ] 15.3.5 Write widget tests for quick add

- [x] 15.4 Create analytics engine
  - [x] 15.4.1 Implement AnalyticsEngine service
  - [x] 15.4.2 Calculate cross-module insights
  - [x] 15.4.3 Identify correlations (mood vs workout, spending vs income)
  - [x] 15.4.4 Generate insights and suggestions
  - [ ] 15.4.5 Write unit tests for analytics engine

- [x] 15.5 Create analytics UI
  - [x] 15.5.1 Create AnalyticsScreen with insights
  - [x] 15.5.2 Create InsightCard widget
  - [x] 15.5.3 Display cross-module correlations
  - [ ] 15.5.4 Write widget tests for analytics UI

- [x] 15.6 Implement achievement system
  - [x] 15.6.1 Define achievement milestones
  - [x] 15.6.2 Track achievement progress
  - [x] 15.6.3 Display achievement badges
  - [ ] 15.6.4 Write unit tests for achievement system

- [x] 15.7 Implement customization
  - [x] 15.7.1 Support customizable card order
  - [x] 15.7.2 Support card visibility preferences
  - [x] 15.7.3 Persist customization settings
  - [ ] 15.7.4 Write unit tests for customization

### 16. Reminder & Notification System (Requirement 12)

- [x] 16.1 Setup notification infrastructure
  - [x] 16.1.1 Integrate flutter_local_notifications package
  - [x] 16.1.2 Create NotificationService
  - [x] 16.1.3 Define notification channels for each module
  - [x] 16.1.4 Initialize notification channels
  - [x] 16.1.5 Request notification permissions
  - [ ] 16.1.6 Write unit tests for notification service

- [x] 16.2 Implement notification scheduling
  - [x] 16.2.1 Implement prayer reminders (10 minutes before)
  - [x] 16.2.2 Implement medication reminders (at scheduled times)
  - [x] 16.2.3 Implement habit reminders (at configured time)
  - [x] 16.2.4 Implement todo reminders (at reminderAt time)
  - [x] 16.2.5 Implement event reminders (reminderMinutes before)
  - [x] 16.2.6 Implement budget alerts (when threshold exceeded)
  - [x] 16.2.7 Implement medication refill reminders (3 days before)
  - [x] 16.2.8 Implement password expiry reminders (7 days before)
  - [ ] 16.2.9 Write integration tests for all reminder types

- [x] 16.3 Implement notification handling
  - [x] 16.3.1 Handle notification taps to navigate to relevant module
  - [x] 16.3.2 Implement snooze functionality
  - [x] 16.3.3 Respect Do Not Disturb settings
  - [ ] 16.3.4 Write integration tests for notification handling

- [x] 16.4 Implement notification settings
  - [x] 16.4.1 Add per-module notification enable/disable
  - [x] 16.4.2 Add notification sound customization
  - [x] 16.4.3 Add notification priority customization
  - [x] 16.4.4 Persist notification settings
  - [ ] 16.4.5 Write unit tests for notification settings


## Phase 4: Enhancement (Requirements 16, 17, 18, 19, 20)

### 17. Search & Filter Capabilities (Requirement 16)

- [ ] 17.1 Implement search infrastructure
  - [x] 17.1.1 Add search() method to all repositories
  - [ ] 17.1.2 Implement full-text search in SQLite
  - [x] 17.1.3 Implement search result highlighting
  - [x] 17.1.4 Implement search debouncing (300ms)
  - [ ] 17.1.5 Write unit tests for search functionality

- [ ] 17.2 Implement module-specific search
  - [x] 17.2.1 Implement notes search (title and content)
  - [ ] 17.2.2 Implement transactions search (description, category, tags)
  - [ ] 17.2.3 Implement credentials search (title, username, website)
  - [ ] 17.2.4 Write unit tests for module-specific search

- [ ] 17.3 Implement filter infrastructure
  - [x] 17.3.1 Add filter() method to all repositories
  - [x] 17.3.2 Implement date range filtering
  - [ ] 17.3.3 Implement category/tag filtering
  - [x] 17.3.4 Implement status filtering (active/deleted/completed)
  - [ ] 17.3.5 Write unit tests for filter functionality

- [ ] 17.4 Create search UI
  - [x] 17.4.1 Create SearchBar widget
  - [x] 17.4.2 Create SearchResultsScreen with highlighting
  - [x] 17.4.3 Create FilterSheet widget
  - [x] 17.4.4 Implement sorting options (date, name, amount, relevance)
  - [ ] 17.4.5 Write widget tests for search UI

### 18. Statistics & Analytics (Requirement 17)

- [ ] 18.1 Implement statistics calculation
  - [x] 18.1.1 Implement module-specific statistics in each service
  - [ ] 18.1.2 Implement time-based trends (daily, weekly, monthly, yearly)
  - [ ] 18.1.3 Implement comparison statistics (this month vs last month)
  - [x] 18.1.4 Implement pattern identification
  - [ ] 18.1.5 Write unit tests for statistics calculation
  - [ ] 18.1.6 Write property-based test for Property 29 (Module Statistics Accuracy)

- [ ] 18.2 Implement cross-module analytics
  - [x] 18.2.1 Calculate correlations between modules
  - [x] 18.2.2 Identify anomalies (unusual spending, missed habits)
  - [x] 18.2.3 Generate insights and suggestions
  - [ ] 18.2.4 Write unit tests for cross-module analytics

- [ ] 18.3 Create visualization widgets
  - [x] 18.3.1 Integrate fl_chart package
  - [x] 18.3.2 Create LineChart widget for trends
  - [x] 18.3.3 Create PieChart widget for distributions
  - [x] 18.3.4 Create BarChart widget for comparisons
  - [x] 18.3.5 Implement interactive charts (tap for details)
  - [ ] 18.3.6 Write widget tests for charts

- [ ] 18.4 Implement statistics export
  - [ ] 18.4.1 Export statistics as images
  - [ ] 18.4.2 Export statistics as PDF reports
  - [ ] 18.4.3 Write integration tests for export

- [ ] 18.5 Display statistics in UI
  - [ ] 18.5.1 Add statistics tab to each module
  - [x] 18.5.2 Display statistics on dashboard
  - [x] 18.5.3 Create dedicated analytics screen
  - [ ] 18.5.4 Write widget tests for statistics display

### 19. User Interface & Experience (Requirement 18)

- [ ] 19.1 Implement theme system
  - [x] 19.1.1 Create AppTheme with light and dark modes
  - [x] 19.1.2 Define module-specific colors
  - [x] 19.1.3 Define text styles (headline, title, subtitle, body, caption)
  - [x] 19.1.4 Support system theme following
  - [ ] 19.1.5 Write tests for theme switching

- [ ] 19.2 Implement navigation
  - [x] 19.2.1 Create bottom navigation with 4 tabs
  - [x] 19.2.2 Implement navigation routing
  - [ ] 19.2.3 Implement deep linking support
  - [ ] 19.2.4 Handle back navigation properly
  - [ ] 19.2.5 Write navigation tests

- [ ] 19.3 Implement common UI patterns
  - [x] 19.3.1 Implement swipe actions (edit left, delete right)
  - [x] 19.3.2 Implement pull-to-refresh on all lists
  - [x] 19.3.3 Implement floating action button for quick add
  - [x] 19.3.4 Implement skeleton screens for loading
  - [x] 19.3.5 Implement empty states with illustrations
  - [ ] 19.3.6 Write widget tests for UI patterns

- [ ] 19.4 Implement animations
  - [ ] 19.4.1 Add smooth page transitions (300ms)
  - [ ] 19.4.2 Add hero animations for images
  - [ ] 19.4.3 Add fade in for lists
  - [x] 19.4.4 Add slide up for modals
  - [ ] 19.4.5 Add success animations (checkmark, confetti)
  - [ ] 19.4.6 Add error shake animation
  - [ ] 19.4.7 Write animation tests

- [ ] 19.5 Implement accessibility
  - [ ] 19.5.1 Add semantic labels to all interactive elements
  - [ ] 19.5.2 Ensure 4.5:1 contrast ratio
  - [ ] 19.5.3 Support text scaling up to 200%
  - [ ] 19.5.4 Use minimum 44x44 touch targets
  - [ ] 19.5.5 Provide clear focus indicators
  - [ ] 19.5.6 Test with screen readers
  - [ ] 19.5.7 Write accessibility tests

- [ ] 19.6 Implement haptic feedback
  - [x] 19.6.1 Add haptic feedback on important actions
  - [ ] 19.6.2 Add haptic feedback on errors
  - [x] 19.6.3 Add haptic feedback on success
  - [ ] 19.6.4 Write tests for haptic feedback


### 20. Testing & Quality Assurance (Requirement 19)

- [ ] 20.1 Write unit tests for services
  - [ ] 20.1.1 Test all ReligiousService methods (>80% coverage)
  - [ ] 20.1.2 Test all FinancialService methods (>80% coverage)
  - [ ] 20.1.3 Test all HabitsService methods (>80% coverage)
  - [ ] 20.1.4 Test all SportsService methods (>80% coverage)
  - [ ] 20.1.5 Test all HealthService methods (>80% coverage)
  - [ ] 20.1.6 Test all NotesService methods (>80% coverage)
  - [ ] 20.1.7 Test all CalendarService methods (>80% coverage)
  - [ ] 20.1.8 Test all SecurityService methods (>80% coverage)
  - [ ] 20.1.9 Test ExportService and ImportService (>80% coverage)
  - [ ] 20.1.10 Test AnalyticsEngine (>80% coverage)

- [ ] 20.2 Write unit tests for repositories
  - [ ] 20.2.1 Test all repository CRUD methods (>80% coverage)
  - [ ] 20.2.2 Test all repository bulk methods (>80% coverage)
  - [ ] 20.2.3 Test all repository query methods (>80% coverage)
  - [ ] 20.2.4 Test all repository count methods (>80% coverage)

- [ ] 20.3 Write unit tests for models
  - [ ] 20.3.1 Test toJson/fromJson for all models (100% coverage)
  - [ ] 20.3.2 Test copyWith for all models
  - [ ] 20.3.3 Test equality operators for all models

- [ ] 20.4 Write unit tests for validation
  - [ ] 20.4.1 Test all validation utilities (100% coverage)
  - [ ] 20.4.2 Test validation in all services
  - [ ] 20.4.3 Test error message generation

- [ ] 20.5 Write widget tests
  - [ ] 20.5.1 Test all major screens
  - [ ] 20.5.2 Test all reusable widgets
  - [ ] 20.5.3 Test user interactions
  - [ ] 20.5.4 Test state changes
  - [ ] 20.5.5 Test navigation
  - [ ] 20.5.6 Test error display

- [ ] 20.6 Write integration tests
  - [ ] 20.6.1 Test prayer log creation flow
  - [ ] 20.6.2 Test transaction creation and budget alert flow
  - [ ] 20.6.3 Test habit completion and streak flow
  - [ ] 20.6.4 Test workout logging flow
  - [ ] 20.6.5 Test medication logging and adherence flow
  - [ ] 20.6.6 Test note creation and search flow
  - [ ] 20.6.7 Test event creation and reminder flow
  - [ ] 20.6.8 Test credential storage and retrieval flow
  - [ ] 20.6.9 Test export/import flow for all modules
  - [ ] 20.6.10 Test backup/restore flow

- [ ] 20.7 Write property-based tests
  - [ ] 20.7.1 Verify all 32 correctness properties
  - [ ] 20.7.2 Run minimum 100 iterations per property
  - [ ] 20.7.3 Tag tests with property numbers
  - [ ] 20.7.4 Document property test results

- [ ] 20.8 Setup continuous testing
  - [ ] 20.8.1 Configure test runner
  - [ ] 20.8.2 Setup code coverage reporting
  - [ ] 20.8.3 Verify >80% coverage for services and repositories
  - [ ] 20.8.4 Verify 100% coverage for models and validation

### 21. Performance & Optimization (Requirement 20)

- [ ] 21.1 Optimize list rendering
  - [ ] 21.1.1 Use ListView.builder for all lists
  - [ ] 21.1.2 Implement pagination for lists >100 items
  - [ ] 21.1.3 Use const constructors throughout
  - [ ] 21.1.4 Profile list performance with DevTools

- [ ] 21.2 Optimize data access
  - [ ] 21.2.1 Implement memory caching for frequently accessed data
  - [ ] 21.2.2 Optimize database queries with proper indexes
  - [ ] 21.2.3 Use database transactions for bulk operations
  - [ ] 21.2.4 Profile database performance

- [ ] 21.3 Optimize assets
  - [ ] 21.3.1 Compress exported data files
  - [ ] 21.3.2 Lazy load images and charts
  - [ ] 21.3.3 Optimize image sizes
  - [ ] 21.3.4 Profile asset loading

- [ ] 21.4 Optimize UI performance
  - [x] 21.4.1 Debounce search input (300ms)
  - [ ] 21.4.2 Minimize widget rebuilds
  - [ ] 21.4.3 Use RepaintBoundary for complex widgets
  - [ ] 21.4.4 Profile UI performance with DevTools
  - [ ] 21.4.5 Ensure 60fps on target devices

- [ ] 21.5 Optimize app size
  - [ ] 21.5.1 Enable code shrinking
  - [ ] 21.5.2 Enable resource shrinking
  - [ ] 21.5.3 Remove unused dependencies
  - [ ] 21.5.4 Measure app size


## Phase 5: Finalization (Requirements 21, 22, 23, 25)

### 22. Security & Privacy (Requirement 21)

- [ ] 22.1 Implement data security
  - [x] 22.1.1 Verify all data stored locally on device
  - [x] 22.1.2 Verify password encryption using AES-256
  - [x] 22.1.3 Verify encryption keys stored in flutter_secure_storage
  - [x] 22.1.4 Verify biometric authentication for Security Vault
  - [x] 22.1.5 Implement auto-lock after 5 minutes inactivity
  - [ ] 22.1.6 Write security tests

- [ ] 22.2 Implement logging security
  - [ ] 22.2.1 Verify no sensitive data logged (passwords, credentials)
  - [x] 22.2.2 Sanitize logs for PII
  - [ ] 22.2.3 Review all log statements
  - [ ] 22.2.4 Write tests for log sanitization

- [ ] 22.3 Implement export security
  - [x] 22.3.1 Warn user about sensitive data in exports
  - [x] 22.3.2 Require biometric auth for Security Vault export
  - [x] 22.3.3 Sanitize exported data option
  - [ ] 22.3.4 Write tests for export security

- [ ] 22.4 Implement network security
  - [ ] 22.4.1 Use HTTPS for all future network communications
  - [ ] 22.4.2 Implement certificate pinning
  - [ ] 22.4.3 Write tests for network security

- [ ] 22.5 Implement input security
  - [x] 22.5.1 Validate and sanitize all user input
  - [x] 22.5.2 Prevent SQL injection
  - [x] 22.5.3 Prevent XSS attacks
  - [ ] 22.5.4 Write security tests for input handling

- [ ] 22.6 Implement user isolation
  - [ ] 22.6.1 Verify all data operations scoped to current user
  - [ ] 22.6.2 Test multi-user data isolation
  - [ ] 22.6.3 Write tests for user isolation

### 23. Backup & Restore (Requirement 22)

- [ ] 23.1 Implement backup functionality
  - [x] 23.1.1 Implement full backup of all modules
  - [x] 23.1.2 Include metadata in backup (version, timestamp, checksum)
  - [x] 23.1.3 Implement selective backup by module
  - [x] 23.1.4 Implement selective backup by date range
  - [x] 23.1.5 Compress backup files
  - [ ] 23.1.6 Write unit tests for backup
  - [ ] 23.1.7 Write property-based test for Property 30 (Full Backup Completeness)

- [ ] 23.2 Implement backup storage
  - [x] 23.2.1 Save backup to device storage
  - [x] 23.2.2 Share backup via email, cloud, or other apps
  - [ ] 23.2.3 Write integration tests for backup storage

- [ ] 23.3 Implement restore functionality
  - [x] 23.3.1 Implement restore from backup file
  - [x] 23.3.2 Validate version compatibility
  - [x] 23.3.3 Verify checksum integrity
  - [x] 23.3.4 Support merge or replace strategy
  - [x] 23.3.5 Create automatic backup before restore
  - [ ] 23.3.6 Write unit tests for restore
  - [ ] 23.3.7 Write property-based test for Property 31 (Backup Version Compatibility)
  - [ ] 23.3.8 Write property-based test for Property 32 (Backup Checksum Verification)

- [ ] 23.4 Implement backup UI
  - [x] 23.4.1 Create BackupScreen with backup options
  - [x] 23.4.2 Create RestoreScreen with file picker
  - [x] 23.4.3 Display backup progress
  - [x] 23.4.4 Display restore progress
  - [ ] 23.4.5 Write widget tests for backup UI

- [ ] 23.5 Implement automatic backup
  - [x] 23.5.1 Schedule automatic backups
  - [x] 23.5.2 Configure backup frequency in settings
  - [ ] 23.5.3 Send backup reminder notifications
  - [ ] 23.5.4 Write tests for automatic backup

- [ ] 23.6 Implement backup logging
  - [x] 23.6.1 Log all backup operations
  - [x] 23.6.2 Log all restore operations
  - [x] 23.6.3 Log backup/restore errors
  - [ ] 23.6.4 Write tests for backup logging

### 24. Settings & Customization (Requirement 23)

- [ ] 24.1 Create settings infrastructure
  - [x] 24.1.1 Create SettingsService
  - [x] 24.1.2 Persist settings using StorageGateway
  - [x] 24.1.3 Provide default settings
  - [ ] 24.1.4 Write unit tests for settings service

- [ ] 24.2 Implement appearance settings
  - [x] 24.2.1 Add theme selection (light, dark, system)
  - [x] 24.2.2 Add language selection (English, Arabic)
  - [x] 24.2.3 Add first day of week selection
  - [ ] 24.2.4 Write tests for appearance settings

- [ ] 24.3 Implement notification settings
  - [x] 24.3.1 Add per-module notification enable/disable
  - [x] 24.3.2 Add notification sound customization
  - [x] 24.3.3 Add notification priority customization
  - [ ] 24.3.4 Write tests for notification settings

- [ ] 24.4 Implement module-specific settings
  - [x] 24.4.1 Add prayer time calculation method selection
  - [x] 24.4.2 Add currency selection for financial module
  - [x] 24.4.3 Add biometric auth enable/disable for Security Vault
  - [x] 24.4.4 Add auto-lock timeout configuration
  - [ ] 24.4.5 Write tests for module settings

- [ ] 24.5 Implement backup settings
  - [x] 24.5.1 Add backup reminder frequency configuration
  - [x] 24.5.2 Add automatic backup enable/disable
  - [ ] 24.5.3 Write tests for backup settings

- [ ] 24.6 Implement dashboard settings
  - [x] 24.6.1 Add dashboard card order customization
  - [x] 24.6.2 Add dashboard card visibility customization
  - [ ] 24.6.3 Write tests for dashboard settings

- [ ] 24.7 Create settings UI
  - [x] 24.7.1 Create SettingsScreen with sections
  - [x] 24.7.2 Create appearance settings section
  - [x] 24.7.3 Create notification settings section
  - [x] 24.7.4 Create module settings sections
  - [x] 24.7.5 Create backup settings section
  - [x] 24.7.6 Create dashboard settings section
  - [x] 24.7.7 Add reset to defaults option
  - [ ] 24.7.8 Write widget tests for settings UI


### 25. Future-Ready Architecture (Requirement 25)

- [ ] 25.1 Prepare for server integration
  - [x] 25.1.1 Use ApiClient from abdalsalam_logic_flutter
  - [ ] 25.1.2 Design services with sync capability (local-first, sync-later)
  - [ ] 25.1.3 Include userId in all data models
  - [x] 25.1.4 Structure exported data for AI consumption
  - [ ] 25.1.5 Write tests for future server integration

- [ ] 25.2 Implement versioning
  - [ ] 25.2.1 Add version to all data models
  - [ ] 25.2.2 Add version to export formats
  - [ ] 25.2.3 Support migration between versions
  - [ ] 25.2.4 Write tests for versioning

- [ ] 25.3 Implement repository pattern
  - [ ] 25.3.1 Verify all data access through repositories
  - [ ] 25.3.2 Abstract storage implementation
  - [ ] 25.3.3 Support easy storage replacement
  - [ ] 25.3.4 Write tests for repository abstraction

- [ ] 25.4 Implement dependency injection
  - [x] 25.4.1 Use Riverpod for dependency injection
  - [x] 25.4.2 Register all services and repositories
  - [ ] 25.4.3 Support easy testing with mocks
  - [ ] 25.4.4 Write tests for dependency injection

- [ ] 25.5 Implement pagination support
  - [x] 25.5.1 Add pagination to all list queries
  - [x] 25.5.2 Support page size configuration
  - [ ] 25.5.3 Support cursor-based pagination
  - [ ] 25.5.4 Write tests for pagination

- [ ] 25.6 Implement metadata tracking
  - [ ] 25.6.1 Include metadata in all operations
  - [x] 25.6.2 Track operation timestamps
  - [x] 25.6.3 Track operation user
  - [ ] 25.6.4 Support future audit trails
  - [ ] 25.6.5 Write tests for metadata tracking

- [ ] 25.7 Document architecture
  - [ ] 25.7.1 Document all data schemas
  - [ ] 25.7.2 Document all relationships
  - [ ] 25.7.3 Document API contracts
  - [ ] 25.7.4 Document migration strategy
  - [ ] 25.7.5 Create architecture diagrams

## Final Integration & Deployment

### 26. Final Integration

- [ ] 26.1 Integration testing
  - [ ] 26.1.1 Test all critical user flows end-to-end
  - [ ] 26.1.2 Test cross-module interactions
  - [ ] 26.1.3 Test offline/online transitions
  - [ ] 26.1.4 Test state-aware behavior
  - [ ] 26.1.5 Test export/import across all modules
  - [ ] 26.1.6 Test backup/restore with real data

- [ ] 26.2 Performance testing
  - [ ] 26.2.1 Profile app startup time
  - [ ] 26.2.2 Profile screen load times
  - [ ] 26.2.3 Profile database query performance
  - [ ] 26.2.4 Profile memory usage
  - [ ] 26.2.5 Verify 60fps UI performance

- [ ] 26.3 Security testing
  - [ ] 26.3.1 Test biometric authentication
  - [ ] 26.3.2 Test password encryption/decryption
  - [ ] 26.3.3 Test data isolation
  - [ ] 26.3.4 Test input validation
  - [ ] 26.3.5 Penetration testing

- [ ] 26.4 Accessibility testing
  - [ ] 26.4.1 Test with screen readers
  - [ ] 26.4.2 Test with text scaling
  - [ ] 26.4.3 Test contrast ratios
  - [ ] 26.4.4 Test touch target sizes
  - [ ] 26.4.5 Test keyboard navigation

- [ ] 26.5 Device testing
  - [ ] 26.5.1 Test on various Android devices
  - [ ] 26.5.2 Test on various iOS devices
  - [ ] 26.5.3 Test on different screen sizes
  - [ ] 26.5.4 Test on different OS versions
  - [ ] 26.5.5 Test in different locales

### 27. Documentation

- [ ] 27.1 Code documentation
  - [ ] 27.1.1 Document all public APIs
  - [ ] 27.1.2 Document complex logic
  - [ ] 27.1.3 Provide code examples
  - [ ] 27.1.4 Address all TODOs

- [ ] 27.2 User documentation
  - [ ] 27.2.1 Write feature guides for all modules
  - [ ] 27.2.2 Add screenshots and examples
  - [ ] 27.2.3 Document common issues and solutions
  - [ ] 27.2.4 Create FAQ

- [ ] 27.3 Developer documentation
  - [ ] 27.3.1 Document architecture and design decisions
  - [ ] 27.3.2 Document data schemas and relationships
  - [ ] 27.3.3 Document API contracts
  - [ ] 27.3.4 Document testing strategy
  - [ ] 27.3.5 Document deployment process

### 28. Deployment Preparation

- [ ] 28.1 Build configuration
  - [ ] 28.1.1 Configure version numbers
  - [ ] 28.1.2 Configure build variants (debug, release)
  - [ ] 28.1.3 Configure signing keys
  - [ ] 28.1.4 Configure ProGuard rules

- [ ] 28.2 Platform configuration
  - [ ] 28.2.1 Configure Android permissions
  - [ ] 28.2.2 Configure iOS permissions
  - [ ] 28.2.3 Configure app icons
  - [ ] 28.2.4 Configure splash screens
  - [ ] 28.2.5 Configure app metadata

- [ ] 28.3 Build verification
  - [ ] 28.3.1 Build debug APK
  - [ ] 28.3.2 Build release APK
  - [ ] 28.3.3 Build iOS debug build
  - [ ] 28.3.4 Build iOS release build
  - [ ] 28.3.5 Verify no debug code in release builds

- [ ] 28.4 Quality gates
  - [ ] 28.4.1 Run flutter analyze (no errors)
  - [ ] 28.4.2 Run flutter format (all files formatted)
  - [ ] 28.4.3 Run all tests (all passing)
  - [ ] 28.4.4 Verify >80% code coverage
  - [ ] 28.4.5 Verify no unused imports
  - [ ] 28.4.6 Verify no dead code

- [ ] 28.5 Monitoring setup
  - [ ] 28.5.1 Configure error tracking
  - [ ] 28.5.2 Configure analytics
  - [ ] 28.5.3 Configure performance monitoring
  - [ ] 28.5.4 Configure crash reporting

## Success Criteria Verification

### 29. Final Verification

- [ ] 29.1 Requirements verification
  - [ ] 29.1.1 Verify all 25 requirements implemented
  - [ ] 29.1.2 Verify all acceptance criteria met
  - [ ] 29.1.3 Verify all modules follow baseline requirements
  - [ ] 29.1.4 Document any deviations

- [ ] 29.2 Functionality verification
  - [ ] 29.2.1 Verify export/import works for all modules
  - [ ] 29.2.2 Verify all tests pass with >80% coverage
  - [ ] 29.2.3 Verify app works fully offline
  - [ ] 29.2.4 Verify all reminders function correctly
  - [ ] 29.2.5 Verify dashboard displays insights from all modules
  - [ ] 29.2.6 Verify Security Vault is biometrically protected
  - [ ] 29.2.7 Verify performance is acceptable (60fps)
  - [ ] 29.2.8 Verify documentation is complete

- [ ] 29.3 Baseline compliance verification
  - [ ] 29.3.1 Verify all models extend BaseModel
  - [ ] 29.3.2 Verify all repositories implement BaseRepository (24 methods)
  - [ ] 29.3.3 Verify all services implement BaseService (29 methods)
  - [ ] 29.3.4 Verify all operations return Result<T, Error>
  - [ ] 29.3.5 Verify all data is exportable with metadata
  - [ ] 29.3.6 Verify all imports are validated
  - [ ] 29.3.7 Verify all operations are logged
  - [ ] 29.3.8 Verify all data supports user isolation
  - [ ] 29.3.9 Verify all features work offline
  - [ ] 29.3.10 Verify all services are state-aware

- [ ] 29.4 Property-based testing verification
  - [ ] 29.4.1 Verify all 32 correctness properties tested
  - [ ] 29.4.2 Verify minimum 100 iterations per property
  - [ ] 29.4.3 Verify all property tests pass
  - [ ] 29.4.4 Document property test results

## Task Summary

**Phase 1 (Foundation)**: 6 major tasks, ~60 sub-tasks
**Phase 2 (Core Modules)**: 6 major tasks, ~90 sub-tasks
**Phase 3 (Integration)**: 4 major tasks, ~50 sub-tasks
**Phase 4 (Enhancement)**: 5 major tasks, ~60 sub-tasks
**Phase 5 (Finalization)**: 4 major tasks, ~50 sub-tasks
**Final Integration**: 4 major tasks, ~40 sub-tasks

**Total**: 29 major tasks, ~350 sub-tasks

## Notes

- All tasks must follow the implementation checklist (implementation-checklist.md)
- All implementations must comply with baseline requirements
- All code must pass flutter analyze with no errors
- All code must be formatted with flutter format
- All tests must pass before marking tasks complete
- Property-based tests require minimum 100 iterations
- Integration tests should use real data scenarios
- Performance profiling should be done with Flutter DevTools
- Security testing should include penetration testing
- Accessibility testing should include real screen readers

