import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/dashboard_card_catalog.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/app_section_header.dart';
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

    final spacing = AppThemeTokens.of(context).spacing;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard & Analytics')),
      body: ListView(
        padding: EdgeInsets.all(spacing.lg),
        children: [
          const SettingsSectionHeader('Card visibility'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Quote of the day'),
                  subtitle: const Text('Shown at the top of the dashboard'),
                  value: _settings[DashboardCardCatalog.showQuoteSetting] != false,
                  onChanged: (value) => _update(DashboardCardCatalog.showQuoteSetting, value),
                ),
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
              ],
            ),
          ),
          const AppSectionHeader(title: 'Card order', subtitle: 'Drag to reorder dashboard cards'),
          AppCard(
            padding: EdgeInsets.zero,
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cardOrder.length,
              itemBuilder: (context, index) => ListTile(
                key: ValueKey('card-${cardOrder[index]}'),
                title: Text(DashboardCardCatalog.labels[cardOrder[index]]!),
                trailing: const Icon(Icons.drag_handle_rounded),
              ),
              onReorderItem: (oldIndex, newIndex) async {
                final reordered = [...cardOrder];
                final moved = reordered.removeAt(oldIndex);
                reordered.insert(newIndex, moved);
                await _update(DashboardCardCatalog.cardOrderSetting, reordered);
              },
            ),
          ),
          const AppSectionHeader(title: 'Sidebar order', subtitle: 'Drag to reorder the navigation sidebar'),
          AppCard(
            padding: EdgeInsets.zero,
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sidebarOrder.length,
              itemBuilder: (context, index) => ListTile(
                key: ValueKey('sidebar-${sidebarOrder[index]}'),
                title: Text(_readableKey(sidebarOrder[index])),
                trailing: const Icon(Icons.drag_handle_rounded),
              ),
              onReorderItem: (oldIndex, newIndex) async {
                final reordered = [...sidebarOrder];
                final moved = reordered.removeAt(oldIndex);
                reordered.insert(newIndex, moved);
                await _update('sidebarOrder', reordered);
              },
            ),
          ),
        ],
      ),
    );
  }
}
