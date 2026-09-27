import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/app_form_dialog.dart';
import '../../../shared/widgets/ui/entity_tile.dart';
import '../providers/quran_providers.dart';

class QuranProgressScreen extends ConsumerWidget {
  const QuranProgressScreen({super.key});

  static const String routeName = '/religious/quran';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppThemeTokens.of(context);
    final state = ref.watch(quranProgressControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quran Progress')),
      body: state.when(
        data: (logs) {
          if (logs.isEmpty) {
            return EmptyState(
              title: 'No Quran logs yet',
              subtitle: 'Add your first progress entry to start tracking.',
              actionLabel: 'Add Progress',
              onAction: () => _showAddDialog(context, ref),
            );
          }

          final totalPages = logs.fold<int>(0, (sum, item) => sum + item.pagesRead);
          final totalMinutes = logs.fold<int>(0, (sum, item) => sum + item.minutesSpent);
          final scheme = Theme.of(context).colorScheme;

          return ListView(
            padding: EdgeInsets.all(tokens.spacing.lg),
            children: [
              AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.menu_book_outlined, color: scheme.secondary),
                        SizedBox(width: tokens.spacing.sm),
                        const Text('Today total'),
                      ],
                    ),
                    Text(
                      '$totalPages pages / $totalMinutes min',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              SizedBox(height: tokens.spacing.md),
              for (final log in logs)
                Padding(
                  padding: EdgeInsets.only(bottom: tokens.spacing.sm),
                  child: EntityTile(
                    icon: Icons.menu_book_outlined,
                    accentColor: scheme.secondary,
                    title: '${log.pagesRead} pages',
                    subtitle: '${log.minutesSpent} min - ${AppDateFormatter.time(log.loggedAt)}',
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AsyncErrorView(
          error: err,
          onRetry: () => ref.invalidate(quranProgressControllerProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        label: const Text('Add Progress'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _QuranProgressDialogContent(ref: ref),
    );
  }
}

class _QuranProgressDialogContent extends StatefulWidget {
  const _QuranProgressDialogContent({required this.ref});

  final WidgetRef ref;

  @override
  State<_QuranProgressDialogContent> createState() => _QuranProgressDialogContentState();
}

class _QuranProgressDialogContentState extends State<_QuranProgressDialogContent> {
  static const String _pagesFieldKey = 'pagesRead';
  static const String _minutesFieldKey = 'minutesSpent';

  final _formKey = GlobalKey<FormState>();
  final pagesController = TextEditingController();
  final minutesController = TextEditingController();
  var isSaving = false;
  Map<String, String> fieldErrors = const <String, String>{};

  @override
  void dispose() {
    pagesController.dispose();
    minutesController.dispose();
    super.dispose();
  }

  String? _validatePages(String? value) {
    final requiredError = ValidationUtils.requiredField(value, 'Pages read');
    if (requiredError != null) return requiredError;
    final parsed = int.tryParse(value!.trim());
    if (parsed == null) return 'Pages read must be a whole number';
    final positiveError = ValidationUtils.positiveNumber(value: parsed, fieldName: 'Pages read');
    return positiveError ?? fieldErrors[_pagesFieldKey];
  }

  String? _validateMinutes(String? value) {
    final requiredError = ValidationUtils.requiredField(value, 'Minutes spent');
    if (requiredError != null) return requiredError;
    final parsed = int.tryParse(value!.trim());
    if (parsed == null) return 'Minutes spent must be a whole number';
    final positiveError = ValidationUtils.positiveNumber(value: parsed, fieldName: 'Minutes spent');
    return positiveError ?? fieldErrors[_minutesFieldKey];
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSaving = true;
      fieldErrors = const <String, String>{};
    });

    final error = await widget.ref.read(quranProgressControllerProvider.notifier).addProgress(
          pagesRead: int.parse(pagesController.text.trim()),
          minutesSpent: int.parse(minutesController.text.trim()),
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
      title: 'Add Quran Progress',
      submitLabel: 'Save',
      isSubmitting: isSaving,
      onSubmit: _save,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: pagesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Pages read'),
              validator: _validatePages,
            ),
            SizedBox(height: tokens.spacing.md),
            TextFormField(
              controller: minutesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Minutes spent'),
              validator: _validateMinutes,
            ),
          ],
        ),
      ),
    );
  }
}
