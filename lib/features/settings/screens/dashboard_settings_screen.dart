import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_providers.dart';
import '../widgets/settings_section_header.dart';

const _dashboardModules = <String>[
  'religious',
  'financial',
  'habits',
  'sports',
  'health',
  'notes',
  'calendar',
  'security',
  'analytics',
];

class DashboardSettingsScreen extends ConsumerStatefulWidget {
  static const routeName = '/settings/dashboard';

  const DashboardSettingsScreen({super.key});

  @override
  ConsumerState<DashboardSettingsScreen> createState() => _DashboardSettingsScreenState();
}

class _DashboardSettingsScreenState extends ConsumerState<DashboardSettingsScreen> {
  Map<String, dynamic> _settings = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final values = await ref.read(settingsServiceProvider).getSettings();
    if (mounted) {
      setState(() => _settings = values);
    }
  }

  Future<void> _update(String key, dynamic value) async {
    await ref.read(settingsServiceProvider).updateSetting(key, value);
    setState(() => _settings[key] = value);
  }

  @override
  Widget build(BuildContext context) {
    final dashboardHidden = (_settings['dashboardHiddenCards'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => item.toString())
        .toSet();
    final cardOrder = (_settings['dashboardCardOrder'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => item.toString())
        .toList(growable: false);
    final sidebarOrder = (_settings['sidebarOrder'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => item.toString())
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard & Analytics')),
      body: ListView(
        children: [
          const SettingsSectionHeader('Card visibility'),
          for (final moduleId in _dashboardModules)
            CheckboxListTile(
              title: Text('Show $moduleId card'),
              value: !dashboardHidden.contains(moduleId),
              onChanged: (value) {
                final next = {...dashboardHidden};
                if (value == true) {
                  next.remove(moduleId);
                } else {
                  next.add(moduleId);
                }
                _update('dashboardHiddenCards', next.toList(growable: false));
              },
            ),
          const SettingsSectionHeader('Card order'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Drag to reorder dashboard cards'),
          ),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cardOrder.length,
            itemBuilder: (context, index) => ListTile(
              key: ValueKey('card-${cardOrder[index]}'),
              title: Text(cardOrder[index]),
              trailing: const Icon(Icons.drag_handle),
            ),
            onReorderItem: (oldIndex, newIndex) {
              final reordered = [...cardOrder];
              final moved = reordered.removeAt(oldIndex);
              reordered.insert(newIndex, moved);
              _update('dashboardCardOrder', reordered);
            },
          ),
          const SettingsSectionHeader('Sidebar order'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Drag to reorder the navigation sidebar'),
          ),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sidebarOrder.length,
            itemBuilder: (context, index) => ListTile(
              key: ValueKey('sidebar-${sidebarOrder[index]}'),
              title: Text(sidebarOrder[index]),
              trailing: const Icon(Icons.drag_handle),
            ),
            onReorderItem: (oldIndex, newIndex) {
              final reordered = [...sidebarOrder];
              final moved = reordered.removeAt(oldIndex);
              reordered.insert(newIndex, moved);
              _update('sidebarOrder', reordered);
            },
          ),
        ],
      ),
    );
  }
}
