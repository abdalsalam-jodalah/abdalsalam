# Data Models & Schema Guidelines

## Core Principles

1. **Exportability**: Every model must support `toJson()` and `fromJson()`
2. **Timestamps**: Include `createdAt` and `updatedAt` for all entities
3. **Soft Deletes**: Use `deletedAt` instead of hard deletes for data preservation
4. **UUIDs**: Use unique identifiers for all entities
5. **Versioning**: Include schema version for future migrations

## Base Model Structure

```dart
abstract class BaseModel {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  
  Map<String, dynamic> toJson();
  // fromJson in concrete classes
}
```

## Feature-Specific Models

### Religious Module
```dart
// Prayer log
- id, userId, prayerType (fajr/dhuhr/asr/maghrib/isha)
- performedAt, onTime (bool), inCongregation (bool)
- location (optional), notes

// Quran reading
- id, userId, surahNumber, ayahFrom, ayahTo
- readAt, duration, notes, memorized (bool)

// Spiritual progress
- id, userId, date, goodDeeds[], badDeeds[]
- reflectionNotes, mood, overallRating
```

### Financial Module
```dart
// Transaction
- id, userId, type (income/expense)
- amount, currency, category, subcategory
- date, description, tags[]
- paymentMethod, recurring (bool)

// Category
- id, name, type, icon, color
- parentCategoryId (for subcategories)

// Budget
- id, userId, categoryId, amount, period
- startDate, endDate, alertThreshold
```

### Habits Module
```dart
// Habit
- id, userId, name, description
- frequency (daily/weekly/custom), targetCount
- reminderTime, icon, color, category

// Habit log
- id, habitId, completedAt, value (for measurable habits)
- notes, mood, skipped (bool), skipReason

// Daily event
- id, userId, eventType, title, description
- occurredAt, duration, tags[], mood
- relatedHabits[], attachments[]
```

### Sports Module
```dart
// Workout
- id, userId, type, name, description
- startTime, endTime, duration
- caloriesBurned, intensity, location

// Exercise
- id, workoutId, exerciseName, sets, reps
- weight, distance, duration, notes

// Schedule
- id, userId, workoutType, scheduledFor
- completed (bool), completedAt, notes
```

### Health Module
```dart
// Medication
- id, userId, name, dosage, frequency
- startDate, endDate, reminderTimes[]
- prescribedBy, notes, refillDate

// Medication log
- id, medicationId, takenAt, skipped (bool)
- skipReason, sideEffects, notes

// Blood test
- id, userId, testType, scheduledDate
- completedDate, results (JSON), notes
- nextTestDate, facility

// Health metric
- id, userId, metricType (weight/bp/glucose/etc)
- value, unit, measuredAt, notes
```

### Notes Module
```dart
// Note
- id, userId, title, content (rich text)
- createdAt, updatedAt, tags[]
- categoryId, pinned (bool), archived (bool)
- attachments[], color

// Todo
- id, userId, title, description
- dueDate, priority, status (pending/done/cancelled)
- categoryId, tags[], reminderAt
- parentTodoId (for subtasks), order

// Category
- id, userId, name, icon, color
- type (note/todo), parentId
```

### Calendar Module
```dart
// Event
- id, userId, title, description
- startTime, endTime, allDay (bool)
- location, attendees[], reminderMinutes[]
- googleEventId (for sync), color, category

// Reminder
- id, eventId, reminderTime
- type (notification/email), sent (bool)
- snoozedUntil
```

### Security Module
```dart
// Password entry
- id, userId, title, username
- encryptedPassword, website, notes
- categoryId, tags[], favorite (bool)
- lastModified, strength, expiryDate

// Security category
- id, userId, name, icon, color
```

## Database Relationships

- Use foreign keys with CASCADE/SET NULL appropriately
- Index frequently queried fields (userId, date fields, status)
- Create composite indexes for common query patterns
- Use transactions for related operations

## Export Schema

```json
{
  "version": "1.0.0",
  "exportedAt": "ISO8601 timestamp",
  "userId": "user_id",
  "modules": {
    "religious": { "prayers": [], "quran": [], "progress": [] },
    "financial": { "transactions": [], "categories": [], "budgets": [] },
    "habits": { "habits": [], "logs": [], "events": [] },
    "sports": { "workouts": [], "exercises": [], "schedules": [] },
    "health": { "medications": [], "logs": [], "tests": [], "metrics": [] },
    "notes": { "notes": [], "todos": [], "categories": [] },
    "calendar": { "events": [], "reminders": [] },
    "security": { "entries": [] }
  }
}
```

## Migration Strategy

- Version all schema changes
- Write up and down migrations
- Test migrations with real data
- Backup before migration
- Support rollback capability
