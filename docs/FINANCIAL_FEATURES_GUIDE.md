# Financial Module - Features Guide

## Dashboard Overview

### 1. Income vs Expenses Chart
- **Visual**: Line chart with green (income) and red (expense) lines
- **Interaction**: Select time period (Week/Month/Year)
- **Data**: Shows daily breakdown over selected period
- **Purpose**: Quick visual of spending patterns

### 2. Total Balance Widget
- **Display**: Large balance amount with trend indicator
- **Color**: Primary container color
- **Info**: Shows percentage change from last period
- **Action**: Tap to see detailed breakdown

### 3. Budgets Section
- **Layout**: Horizontal scrollable cards
- **Card Info**: 
  - Category icon and name
  - Progress percentage
  - Spent vs Budget amount
  - Progress bar (color changes if over budget)
- **Filter**: Day/Week/Month selector
- **Action**: "View More" → Full budgets page

### 4. Recent Transactions
- **Display**: Last 2 transactions
- **Info per transaction**:
  - Category icon
  - Description
  - Date and time
  - Amount (green for income, red for expense)
  - Payment method
- **Action**: "View More" → Full transactions page

### 5. Categories Section
- **Layout**: 2-column grid
- **Card Info**:
  - Category icon
  - Category name
  - Total spent this month
- **Action**: "View More" → Full categories page

## Transactions Page

### Features
- **List View**: All transactions sorted by date (newest first)
- **Filtering**: 
  - By category
  - By type (income/expense)
  - Multiple filters can be applied
- **Transaction Details**: Tap to see full details in modal
- **Actions**: Edit, Delete from details modal
- **Add New**: FAB or top action button

### Transaction Details Modal
Shows:
- Amount
- Type (Income/Expense)
- Description
- Date and time
- Payment method
- Tags
- Edit/Delete buttons

## Budgets Page

### Features
- **Period Filter**: Day/Week/Month selector
- **Budget Cards** show:
  - Category with icon
  - Period type
  - Spent percentage
  - Progress bar (color-coded)
  - Spent amount
  - Remaining amount
  - Total budget
  - Edit/Delete buttons

### Color Coding
- **Green**: Under budget
- **Orange**: Near limit (80%+)
- **Red**: Over budget

## Categories Page

### Features
- **Type Filter**: Expense/Income toggle
- **Grid View**: 2-column layout
- **Category Cards** show:
  - Icon with color
  - Category name
  - Total spent this month
- **Tap Card**: See category details

### Category Details
- Category name and type
- Statistics:
  - This month total
  - Last month total
  - Average spending
- Recent transactions in this category
- Scrollable list

## Transaction Form

### Creating a Transaction

**Step 1: Select Type**
- Choose Income or Expense
- Categories update based on type

**Step 2: Enter Amount**
- Large input field with $ prefix
- Decimal support
- Validation: Must be > 0

**Step 3: Add Description**
- What did you spend on?
- 2-line text field
- Validation: Required

**Step 4: Select Category**
- Dropdown with type-specific categories
- Can add custom categories later

**Step 5: Pick Date**
- Calendar picker
- Defaults to today
- Can select past dates

**Step 6: Choose Payment Method**
- Cash
- Credit Card
- Debit Card
- Bank Transfer
- Mobile Payment
- Check

**Step 7: Add Tags (Optional)**
- Type tag name
- Click "Add" button
- Remove by tapping X on chip
- Multiple tags supported

**Step 8: Save**
- Click "Create" or "Update"
- Validation runs
- Success message shown
- Returns to previous screen

## Navigation Flow

```
Dashboard
├── Chart → Period selector
├── Budgets → Budgets Page
│   └── Budget Card → Edit/Delete
├── Transactions → Transactions Page
│   ├── Transaction → Details Modal
│   │   └── Edit → Transaction Form
│   └── Add Button → Transaction Form
├── Categories → Categories Page
│   └── Category → Category Details
└── Add Button (FAB) → Transaction Form
```

## Color System

### Transaction Types
- **Income**: Green (#4CAF50)
- **Expense**: Red (#F44336)

### Budget Status
- **Under Budget**: Green
- **Near Limit**: Orange (#FF9800)
- **Over Budget**: Red

### Category Colors
- Food & Dining: Orange
- Transport: Blue
- Shopping: Purple
- Bills: Red
- Entertainment: Purple
- Health: Pink
- Education: Teal
- Salary: Green
- Freelance: Teal

## Keyboard Shortcuts & Gestures

- **Swipe Left**: Delete (on transaction cards)
- **Swipe Right**: Edit (on transaction cards)
- **Long Press**: Multi-select (future feature)
- **Pull to Refresh**: Reload data (future feature)

## Validation Rules

### Amount
- Must be a number
- Must be greater than 0
- Supports decimals

### Description
- Required field
- Minimum 1 character
- Maximum 500 characters

### Date
- Cannot be in future
- Can be any past date
- Defaults to today

### Category
- Must select from list
- Cannot be empty

## Tips for Users

1. **Quick Entry**: Use the FAB on dashboard for fastest transaction entry
2. **Filtering**: Use category filter to see spending by type
3. **Budget Alerts**: Set budgets to get alerts when near limit
4. **Tags**: Use tags to group related transactions
5. **Date Range**: Use period selector to analyze spending patterns
6. **Export**: Export transactions for external analysis (future feature)

## Accessibility

- All buttons have labels
- Color not the only indicator (icons used too)
- Touch targets are 44x44 minimum
- Text is readable at 200% zoom
- Screen reader support included
