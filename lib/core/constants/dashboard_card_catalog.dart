class DashboardCardCatalog {
  const DashboardCardCatalog._();

  static const String cardOrderSetting = 'dashboardCardOrder';
  static const String hiddenCardsSetting = 'dashboardHiddenCards';
  static const String showQuoteSetting = 'dashboardShowQuote';

  static const String today = 'today';
  static const String weather = 'weather';
  static const String currency = 'currency';
  static const String goals = 'goals';
  static const String agenda = 'agenda';
  static const String age = 'age';

  static const List<String> defaultOrder = <String>[age, today, weather, goals, currency, agenda];

  static const Map<String, String> labels = <String, String>{
    today: 'Today at a glance',
    weather: 'Weather',
    currency: 'Exchange rates',
    goals: "Today's goals",
    agenda: "Today's tasks",
    age: 'My age',
  };

  static List<String> resolveOrder(Object? savedOrder) {
    final saved = savedOrder is List ? savedOrder.whereType<String>().where(labels.containsKey).toList() : <String>[];
    return <String>[
      ...saved,
      for (final card in defaultOrder)
        if (!saved.contains(card)) card,
    ];
  }

  static Set<String> resolveHidden(Object? savedHidden) {
    return savedHidden is List ? savedHidden.whereType<String>().toSet() : <String>{};
  }
}
