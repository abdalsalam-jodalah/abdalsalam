class DashboardCardCatalog {
  const DashboardCardCatalog._();

  static const String cardOrderSetting = 'dashboardCardOrder';
  static const String hiddenCardsSetting = 'dashboardHiddenCards';

  static const String today = 'today';
  static const String weather = 'weather';
  static const String currency = 'currency';
  static const String goals = 'goals';
  static const String agenda = 'agenda';

  static const List<String> defaultOrder = <String>[today, weather, goals, currency, agenda];

  static const Map<String, String> labels = <String, String>{
    today: 'Today at a glance',
    weather: 'Weather',
    currency: 'Exchange rates',
    goals: "Today's goals",
    agenda: "Today's agenda",
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
