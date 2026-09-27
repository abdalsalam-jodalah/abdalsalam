import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../data/models/religious/athkar_content.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/app_form_dialog.dart';
import '../../../shared/widgets/ui/page_header.dart';
import '../../../shared/widgets/ui/progress_bar.dart';
import '../providers/athkar_providers.dart';
import '../providers/prayer_providers.dart';
import 'athkar_history_screen.dart';

class AthkarScreen extends ConsumerStatefulWidget {
  /// When true, renders without its own [Scaffold]/[AppBar]/FAB for
  /// embedding inside the tabbed [ReligiousScreen] shell.
  final bool embedded;

  const AthkarScreen({super.key, this.embedded = false});

  static const String routeName = '/religious/athkar';

  @override
  ConsumerState<AthkarScreen> createState() => _AthkarScreenState();
}

class _AthkarScreenState extends ConsumerState<AthkarScreen> with SingleTickerProviderStateMixin {
  static const double _historyTabIconSize = 18;

  late final TabController _tabController;

  static const _categories = AthkarCategory.values;

  @override
  void initState() {
    super.initState();
    // +1 tab for the History view, appended after the category tabs.
    _tabController = TabController(length: _categories.length + 1, vsync: this);
    unawaited(Future.microtask(
      () => ref.read(athkarServiceProvider).scheduleSuggestionReminders(userId: demoUserId),
    ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabBar = TabBar(
      controller: _tabController,
      isScrollable: true,
      tabs: [
        ..._categories.map((c) => Tab(text: athkarCategoryLabel(c))),
        const Tab(text: 'History', icon: Icon(Icons.history, size: _historyTabIconSize)),
      ],
    );
    final tabBarView = TabBarView(
      controller: _tabController,
      children: [
        ..._categories.map((c) => _CategoryTab(category: c)),
        const AthkarHistoryView(),
      ],
    );

    if (widget.embedded) {
      return Column(
        children: [
          PageHeader(
            title: 'Athkar',
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add Custom Athkar',
                onPressed: () => _showAddCustomDialog(context, ref),
              ),
            ],
          ),
          tabBar,
          Expanded(child: tabBarView),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Athkar'),
        bottom: tabBar,
      ),
      body: tabBarView,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Custom Athkar'),
      ),
    );
  }

  Future<void> _showAddCustomDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _CustomAthkarDialogContent(ref: ref),
    );
  }
}

class _CustomAthkarDialogContent extends StatefulWidget {
  const _CustomAthkarDialogContent({required this.ref});

  final WidgetRef ref;

  @override
  State<_CustomAthkarDialogContent> createState() => _CustomAthkarDialogContentState();
}

class _CustomAthkarDialogContentState extends State<_CustomAthkarDialogContent> {
  static const String _arabicTextFieldKey = 'arabicText';
  static const String _targetCountFieldKey = 'targetCount';

  final _formKey = GlobalKey<FormState>();
  final arabicController = TextEditingController();
  final transliterationController = TextEditingController();
  final translationController = TextEditingController();
  final targetCountController = TextEditingController(text: '1');
  var selectedCategory = AthkarCategory.custom;
  var isSaving = false;
  Map<String, String> fieldErrors = const <String, String>{};

  static const _categories = AthkarCategory.values;

  @override
  void dispose() {
    arabicController.dispose();
    transliterationController.dispose();
    translationController.dispose();
    targetCountController.dispose();
    super.dispose();
  }

  String? _validateArabicText(String? value) {
    final requiredError = ValidationUtils.requiredField(value, 'Arabic text');
    return requiredError ?? fieldErrors[_arabicTextFieldKey];
  }

  String? _validateTargetCount(String? value) {
    final requiredError = ValidationUtils.requiredField(value, 'Target count');
    if (requiredError != null) return requiredError;
    final parsed = int.tryParse(value!.trim());
    if (parsed == null) return 'Target count must be a whole number';
    final positiveError = ValidationUtils.positiveNumber(value: parsed, fieldName: 'Target count');
    return positiveError ?? fieldErrors[_targetCountFieldKey];
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSaving = true;
      fieldErrors = const <String, String>{};
    });

    final error = await widget.ref.read(athkarLogsControllerProvider.notifier).addCustomAthkar(
          arabicText: arabicController.text.trim(),
          transliteration:
              transliterationController.text.trim().isEmpty ? null : transliterationController.text.trim(),
          translation: translationController.text.trim().isEmpty ? null : translationController.text.trim(),
          category: selectedCategory,
          targetCount: int.parse(targetCountController.text.trim()),
        );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        isSaving = false;
        fieldErrors = error is ValidationError ? error.fieldErrors : const <String, String>{};
      });
      _formKey.currentState!.validate();
      AppFeedback.showError(context, error);
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return AppFormDialog(
      title: 'Add Custom Athkar',
      submitLabel: 'Save',
      isSubmitting: isSaving,
      onSubmit: _save,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: arabicController,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(labelText: 'Arabic text'),
              maxLines: 3,
              validator: _validateArabicText,
            ),
            SizedBox(height: tokens.spacing.md),
            TextField(
              controller: transliterationController,
              decoration: const InputDecoration(labelText: 'Transliteration (optional)'),
            ),
            SizedBox(height: tokens.spacing.md),
            TextField(
              controller: translationController,
              decoration: const InputDecoration(labelText: 'Translation (optional)'),
            ),
            SizedBox(height: tokens.spacing.md),
            TextFormField(
              controller: targetCountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Target count'),
              validator: _validateTargetCount,
            ),
            SizedBox(height: tokens.spacing.md),
            DropdownButtonFormField<AthkarCategory>(
              initialValue: selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(athkarCategoryLabel(c)))).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedCategory = value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTab extends ConsumerWidget {
  const _CategoryTab({required this.category});

  final AthkarCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppThemeTokens.of(context);
    final entriesAsync = ref.watch(athkarCategoryProvider(category));

    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return const EmptyState(
            title: 'No athkar in this category yet',
            subtitle: 'Use the Add Custom Athkar button to create one.',
          );
        }
        return ListView.builder(
          padding: EdgeInsets.all(tokens.spacing.lg),
          itemCount: entries.length,
          itemBuilder: (context, index) => Padding(
            padding: EdgeInsets.only(bottom: tokens.spacing.md),
            child: _AthkarCard(content: entries[index]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => AsyncErrorView(
        error: err,
        onRetry: () => ref.invalidate(athkarCategoryProvider(category)),
      ),
    );
  }
}

class _AthkarCard extends ConsumerStatefulWidget {
  const _AthkarCard({required this.content});

  final AthkarContent content;

  @override
  ConsumerState<_AthkarCard> createState() => _AthkarCardState();
}

class _AthkarCardState extends ConsumerState<_AthkarCard> {
  static const double _arabicLineHeight = 1.6;
  static const String _loggedMessage = 'Athkar logged';

  int _done = 0;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final content = widget.content;
    final completed = _done >= content.targetCount;
    final scheme = theme.colorScheme;
    final progress = content.targetCount == 0 ? 0.0 : (_done / content.targetCount).clamp(0, 1).toDouble();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            content.arabicText,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyLarge?.copyWith(height: _arabicLineHeight),
          ),
          if (content.transliteration != null) ...[
            SizedBox(height: tokens.spacing.sm),
            Text(
              content.transliteration!,
              style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
          if (content.translation != null) ...[
            SizedBox(height: tokens.spacing.xs),
            Text(content.translation!, style: theme.textTheme.bodySmall),
          ],
          SizedBox(height: tokens.spacing.md),
          ProgressBar(value: progress, color: completed ? scheme.primary : scheme.tertiary),
          SizedBox(height: tokens.spacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$_done / ${content.targetCount}'
                  '${content.reference != null ? ' • ${content.reference}' : ''}',
                  style: theme.textTheme.labelMedium,
                ),
              ),
              IconButton.filledTonal(
                onPressed: completed ? null : () => setState(() => _done = _done + 1),
                icon: const Icon(Icons.add),
                tooltip: 'Count one',
              ),
              SizedBox(width: tokens.spacing.xs),
              IconButton.filledTonal(
                onPressed: !completed
                    ? null
                    : () async {
                        final error = await ref
                            .read(athkarLogsControllerProvider.notifier)
                            .logCompletion(content: content, countDone: _done);
                        if (!context.mounted) return;
                        if (error != null) {
                          AppFeedback.showError(context, error);
                        } else {
                          AppFeedback.showSuccess(context, _loggedMessage);
                          setState(() => _done = 0);
                        }
                      },
                icon: const Icon(Icons.check),
                tooltip: 'Log completion',
                style: completed
                    ? IconButton.styleFrom(backgroundColor: scheme.primary, foregroundColor: scheme.onPrimary)
                    : null,
              ),
              if (content.isCustom) ...[
                SizedBox(width: tokens.spacing.xs),
                IconButton(
                  onPressed: () async {
                    final error =
                        await ref.read(athkarLogsControllerProvider.notifier).deleteCustomAthkar(content.id);
                    if (error != null && context.mounted) {
                      AppFeedback.showError(context, error);
                    }
                  },
                  icon: Icon(Icons.delete_outline, color: tokens.colors.danger),
                  tooltip: 'Delete',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
