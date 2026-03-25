# UI/UX Guidelines

## Design Philosophy

### Personal & Functional
- Clean, minimal interface focused on data entry and insights
- Quick access to frequently used features
- Efficient workflows for daily logging
- Dashboard-first approach with module deep-dives

### Data Visualization
- Charts and graphs for trends and patterns
- Color-coded indicators for progress
- Visual feedback for achievements
- Statistics prominently displayed

## Navigation Structure

### Bottom Navigation (Primary)
```
1. Dashboard (Home icon)
2. Quick Add (Plus icon) - Modal for quick logging
3. Calendar (Calendar icon)
4. More (Menu icon) - Access to all modules
```

### Module Access
- Dashboard shows overview cards for each module
- Tap card to enter module detail view
- Each module has consistent structure:
  - List/Timeline view
  - Add button (FAB)
  - Filter/Search
  - Stats/Charts tab
  - Settings

## Color System

### Semantic Colors
- Success: Green (completed tasks, good habits)
- Warning: Orange (upcoming deadlines, reminders)
- Error: Red (missed prayers, overbudget)
- Info: Blue (neutral information)

### Module Colors (for visual distinction)
- Religious: Purple/Indigo
- Financial: Green
- Habits: Blue
- Sports: Orange
- Health: Red/Pink
- Notes: Yellow
- Calendar: Teal
- Security: Dark Blue/Gray

### Theme Support
- Light mode (default)
- Dark mode (AMOLED-friendly)
- System theme following
- Consistent contrast ratios

## Typography

```dart
// Text Styles
- Headline: 24sp, Bold (Module titles)
- Title: 20sp, SemiBold (Card titles)
- Subtitle: 16sp, Medium (Section headers)
- Body: 14sp, Regular (Content)
- Caption: 12sp, Regular (Metadata, timestamps)
```

## Common UI Patterns

### Dashboard Cards
```dart
ModuleCard(
  icon: Icons.mosque,
  title: 'Religious',
  color: Colors.purple,
  stats: [
    Stat('Today', '4/5 prayers'),
    Stat('Streak', '12 days'),
  ],
  onTap: () => navigate to module,
)
```

### Quick Add Modal
- Bottom sheet with tabs for each module
- Quick forms with minimal required fields
- Smart defaults (current time, today's date)
- Save and continue option

### List Items
- Swipe actions: Edit (left), Delete (right)
- Long press for multi-select
- Pull to refresh
- Infinite scroll with pagination

### Forms
- Floating labels
- Validation on blur
- Clear error messages
- Save button always visible (sticky)
- Auto-save drafts for long forms

### Date/Time Pickers
- Use native pickers
- Quick select options (Today, Yesterday, This Week)
- Calendar view for date ranges

### Charts & Graphs
- Line charts for trends over time
- Bar charts for comparisons
- Pie charts for distributions
- Interactive (tap for details)
- Export chart as image option

## Feature-Specific UI

### Religious Module
- Prayer time widget on dashboard
- Quick log with single tap
- Quran reader with bookmark
- Progress calendar heatmap

### Financial Module
- Running balance display
- Category breakdown pie chart
- Monthly spending graph
- Quick expense entry with recent categories

### Habits Module
- Habit cards with streak counter
- Check-in button prominent
- Weekly view with completion dots
- Mood tracking with emoji selector

### Sports Module
- Active workout timer
- Exercise library with animations
- Rest timer between sets
- Progress photos gallery

### Health Module
- Medication schedule timeline
- Pill reminder notifications
- Health metrics graphs
- Test results document viewer

### Notes Module
- Rich text editor (bold, italic, lists)
- Tag chips for filtering
- Search with highlighting
- Pin important notes to top

### Calendar Module
- Month/Week/Day views
- Color-coded events by module
- Agenda list view
- Integration indicator for Google Calendar

### Security Module
- Biometric lock screen
- Password strength indicator
- Search with masked results
- Copy with auto-clear clipboard
- Password generator

## Interactions & Animations

### Transitions
- Smooth page transitions (300ms)
- Hero animations for images
- Fade in for lists
- Slide up for modals

### Feedback
- Haptic feedback on important actions
- Loading indicators for async operations
- Success animations (checkmark, confetti)
- Error shake animation

### Gestures
- Swipe to dismiss modals
- Pull to refresh lists
- Pinch to zoom images/charts
- Long press for context menu

## Accessibility

### Screen Reader Support
- Semantic labels on all interactive elements
- Announce state changes
- Logical focus order
- Skip navigation option

### Visual Accessibility
- Minimum 4.5:1 contrast ratio
- Support text scaling up to 200%
- No color-only indicators
- Clear focus indicators

### Motor Accessibility
- Minimum 44x44 touch targets
- Adequate spacing between elements
- No time-based interactions
- Alternative to complex gestures

## Empty States

- Friendly illustrations
- Clear call-to-action
- Onboarding hints for first-time users
- Example data option

## Error States

- Clear error messages
- Suggested actions to resolve
- Retry button when applicable
- Contact support option (future)

## Loading States

- Skeleton screens for content
- Progress indicators for operations
- Optimistic UI updates
- Background sync indicator

## Notifications

### In-App
- Snackbar for quick feedback
- Banner for important messages
- Modal for critical actions

### Push Notifications
- Prayer reminders
- Medication alerts
- Habit check-ins
- Budget warnings
- Calendar events
- Customizable per module
