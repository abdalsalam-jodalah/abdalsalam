import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/services/reminder_service.dart';
import '../../financial/screens/accounts_page.dart';
import '../../financial/screens/categories_page.dart';
import '../widgets/module_reminder_toggle_list.dart';
import '../../../shared/widgets/ui/picker_list_tile.dart';
import '../widgets/settings_section_header.dart';

class FinancialSettingsScreen extends ConsumerStatefulWidget {
  static const routeName = '/settings/financial';

  const FinancialSettingsScreen({super.key});

  @override
  ConsumerState<FinancialSettingsScreen> createState() => _FinancialSettingsScreenState();
}

class _FinancialSettingsScreenState extends ConsumerState<FinancialSettingsScreen> {
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

  @override
  Widget build(BuildContext context) {
    final currency = (_settings['currency'] as String?) ?? 'USD';
    final budgetThreshold = (_settings['financialDefaultBudgetAlertThreshold'] as num?)?.toDouble() ?? 80.0;
    final exportFormat = (_settings['financialDefaultExportFormat'] as String?) ?? 'csv';

    return Scaffold(
      appBar: AppBar(title: const Text('Financial')),
      body: ListView(
        children: [
          const SettingsSectionHeader('Reminders'),
          const ModuleReminderToggleList(module: ReminderModule.financial, label: 'Enable financial reminders'),
          const SettingsSectionHeader('Currency & budgets'),
          PickerListTile<String>(
            title: 'Default currency',
            value: currency,
            icon: Icons.attach_money,
            options: const [
              PickerOption('ILS', 'Israeli Shekel (₪)'),
              PickerOption('USD', 'US Dollar (\$)'),
              PickerOption('JOD', 'Jordanian Dinar (JD)'),
            ],
            onChanged: (value) => _update('currency', value),
          ),
          PickerListTile<double>(
            title: 'Default budget alert threshold',
            value: budgetThreshold,
            icon: Icons.warning_amber_outlined,
            options: const [
              PickerOption(60.0, '60% of budget'),
              PickerOption(70.0, '70% of budget'),
              PickerOption(80.0, '80% of budget'),
              PickerOption(90.0, '90% of budget'),
            ],
            onChanged: (value) => _update('financialDefaultBudgetAlertThreshold', value),
          ),
          PickerListTile<String>(
            title: 'Default export format',
            value: exportFormat,
            icon: Icons.ios_share_outlined,
            options: const [
              PickerOption('csv', 'CSV'),
              PickerOption('pdf', 'PDF'),
            ],
            onChanged: (value) => _update('financialDefaultExportFormat', value),
          ),
          const SettingsSectionHeader('Manage'),
          ListTile(
            title: const Text('Categories'),
            subtitle: const Text('Manage income and expense categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed(CategoriesPage.routeName),
          ),
          ListTile(
            title: const Text('Accounts'),
            subtitle: const Text('Manage accounts and payment sources'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed(AccountsPage.routeName),
          ),
        ],
      ),
    );
  }
}
