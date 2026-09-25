import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/dashboard_card_catalog.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../widgets/settings_section_header.dart';


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
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final values = await ref.read(settingsServiceProvider).getSettings();
      if (!mounted) return;
      setState(() => _settings = values);
    } catch (error, stackTrace) {
      final mapped = ref.read(errorHandlerProvider).mapException(
        error,
        context: '${widget.runtimeType}._load',
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      AppFeedback.showError(context, mapped);
    }
  }

  Future<void> _update(String key, dynamic value) async {
    if (!mounted) return;
    try {
      await ref.read(settingsServiceProvider).updateSetting(key, value);
      ref.invalidate(appSettingsProvider);
    } catch (error, stackTrace) {
      final mapped = ref.read(errorHandlerProvider).mapException(
        error,
        context: '${widget.runtimeType}._update',
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      AppFeedback.showError(context, mapped);
      return;
    }
    if (!mounted) return;
    setState(() => _settings[key] = value);
  }

  String _readableKey(String key) {
    final words = key.split('-');
    return words.map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final dashboardHidden = DashboardCardCatalog.resolveHidden(_settings[DashboardCardCatalog.hiddenCardsSetting]);
    final cardOrder = DashboardCardCatalog.resolveOrder(_settings[DashboardCardCatalog.cardOrderSetting]);
    final sidebarOrder = (_settings['sidebarOrder'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => item.toString())
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard & Analytics')),
      body: ListView(
        children: [
          const SettingsSectionHeader('Card visibility'),
          for (final cardId in DashboardCardCatalog.defaultOrder)
            SwitchListTile(
              title: Text(DashboardCardCatalog.labels[cardId]!),
              value: !dashboardHidden.contains(cardId),
              onChanged: (value) async {
                final next = {...dashboardHidden};
                if (value) {
                  next.remove(cardId);
                } else {
                  next.add(cardId);
                }
                await _update(DashboardCardCatalog.hiddenCardsSetting, next.toList(growable: false));
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
              title: Text(DashboardCardCatalog.labels[cardOrder[index]]!),
              trailing: const Icon(Icons.drag_handle),
            ),
            onReorderItem: (oldIndex, newIndex) async {
              final reordered = [...cardOrder];
              final moved = reordered.removeAt(oldIndex);
              reordered.insert(newIndex, moved);
              await _update(DashboardCardCatalog.cardOrderSetting, reordered);
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
              title: Text(_readableKey(sidebarOrder[index])),
              trailing: const Icon(Icons.drag_handle),
            ),
            onReorderItem: (oldIndex, newIndex) async {
              final reordered = [...sidebarOrder];
              final moved = reordered.removeAt(oldIndex);
              reordered.insert(newIndex, moved);
              await _update('sidebarOrder', reordered);
            },
          ),
        ],
      ),
    );
  }
}
