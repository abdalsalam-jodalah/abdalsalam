# Financial Database Setup - Complete Guide

## Summary
The financial database tables ARE being created, but they're empty. I've added tools to help you see and populate them.

## What's Happening

### 1. Tables ARE Created ✅
When the app starts, these tables are created in SQLite:
- `transactions` - For all income/expense transactions
- `categories` - For expense and income categories
- `budgets` - For budget tracking

The tables are created in `main.dart` → `DatabaseSchemaInitializer.initialize()`

### 2. Why You Don't See Data
The tables exist but are EMPTY. That's why:
- Dashboard shows "No data"
- Transactions page shows "No transactions yet"
- Database viewer (before fix) didn't show empty tables

## Changes Made

### 1. Database Viewer Updated ✅
**File**: `lib/shared/widgets/database_viewer_screen.dart`

**Change**: Now shows ALL tables, even if they're empty

**Before**: Only showed tables with data
**After**: Shows all tables including empty ones

### 2. Data Seeder Created ✅
**File**: `lib/features/financial/services/financial_data_seeder.dart`

**Purpose**: Adds sample data for testing

**What it seeds**:
- 7 categories (Food, Transport, Shopping, Bills, Entertainment, Salary, Freelance)
- 4 sample transactions (1 salary, 3 expenses)
- 2 budgets (Food: 2000 ILS, Transport: 800 ILS)

### 3. Dev Tools Enhanced ✅
**File**: `lib/shared/widgets/dev_tools_overlay.dart`

**New button**: "Seed Financial Data"

**How to use**:
1. Tap purple dev tools button (bottom-right)
2. Tap "Seed Financial Data"
3. Wait for success message
4. Go to Financial Dashboard to see data!

## How to Test

### Step 1: View Empty Tables
1. Run the app: `flutter run`
2. Tap purple dev tools button
3. Tap "View Database"
4. You should see tables: `transactions`, `categories`, `budgets` (all empty)

### Step 2: Add Sample Data
1. Tap purple dev tools button
2. Tap "Seed Financial Data"
3. Wait for "Financial data seeded successfully!" message

### Step 3: Verify Data
1. Go to Financial Dashboard
2. You should now see:
   - Total Balance: 14,545 ILS (15,000 income - 455 expenses)
   - Chart with data points
   - 2 active budgets
   - 4 recent transactions
   - Categories with spending amounts

### Step 4: View in Database
1. Tap purple dev tools button
2. Tap "View Database"
3. Select `transactions` table → See 4 transactions
4. Select `categories` table → See 7 categories
5. Select `budgets` table → See 2 budgets

## Database Schema

### transactions table
```
id, user_id, created_at, updated_at, deleted_at, data
```

The `data` column contains JSON with:
- type (income/expense)
- amount
- currency (ILS/USD/JOD)
- categoryId
- date
- description
- paymentMethod
- tags
- isRecurring
- recurringPattern

### categories table
```
id, user_id, created_at, updated_at, deleted_at, data
```

The `data` column contains JSON with:
- name
- type (income/expense)
- icon (codePoint, fontFamily)
- color (ARGB value)
- parentCategoryId

### budgets table
```
id, user_id, created_at, updated_at, deleted_at, data
```

The `data` column contains JSON with:
- categoryId
- amount
- period (daily/weekly/monthly/yearly)
- startDate
- endDate
- alertThreshold
- isActive

## Files Modified/Created

### Created:
- ✅ `lib/features/financial/services/financial_data_seeder.dart`
- ✅ `lib/features/financial/services/currency_service.dart`

### Modified:
- ✅ `lib/shared/widgets/database_viewer_screen.dart` (show empty tables)
- ✅ `lib/shared/widgets/dev_tools_overlay.dart` (add seed button)
- ✅ `lib/features/financial/providers/financial_providers.dart` (add seeder provider)

## Next Steps

### To Add Real Data:
1. Use the transaction form to add transactions
2. Create categories through the UI
3. Set up budgets

### To Clear Test Data:
Currently no UI for this. You can:
1. Uninstall and reinstall the app
2. Or manually delete from database viewer (future feature)

## Important Notes

1. **Tables exist even when empty** - They're created on app startup
2. **Sample data uses ILS currency** - Israeli Shekel as base currency
3. **User ID is hardcoded** - Currently using 'user1' for all data
4. **Data persists** - Once seeded, data stays until app is uninstalled

## Troubleshooting

### "No tables found"
- Tables are created but query might be failing
- Check logs in dev tools → View Logs

### "Seed button doesn't work"
- Check logs for errors
- Make sure repositories are properly initialized

### "Data doesn't show in UI"
- Refresh the page (hot reload with 'r')
- Check if providers are watching the right data

---
**Status**: Complete and ready for testing
**Last Updated**: 2026-04-01
