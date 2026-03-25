class AchievementService {
  final Map<String, int> _progress = <String, int>{
    '30_day_prayer_streak': 0,
    '100_workouts_logged': 0,
    '90_todo_completion': 0,
  };

  Map<String, int> get progress => Map<String, int>.from(_progress);

  void increment(String id, {int by = 1}) {
    _progress[id] = (_progress[id] ?? 0) + by;
  }

  List<Map<String, dynamic>> milestones() {
    return <Map<String, dynamic>>[
      {
        'id': '30_day_prayer_streak',
        'title': '30-Day Prayer Streak',
        'target': 30,
        'current': _progress['30_day_prayer_streak'] ?? 0,
      },
      {
        'id': '100_workouts_logged',
        'title': '100 Workouts Logged',
        'target': 100,
        'current': _progress['100_workouts_logged'] ?? 0,
      },
      {
        'id': '90_todo_completion',
        'title': '90% Todo Completion',
        'target': 90,
        'current': _progress['90_todo_completion'] ?? 0,
      },
    ];
  }
}
