import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/planning/review.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/app_form_dialog.dart';
import '../providers/planning_providers.dart';

class ReviewsScreen extends ConsumerStatefulWidget {
  static const routeName = '/planning/reviews';

  const ReviewsScreen({super.key});

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  static const String _reviewSavedMessage = 'Review saved';
  static const String _emptySubtitle = 'Tap + to add one.';

  final _uuid = const Uuid();
  ReviewPeriod _selectedPeriod = ReviewPeriod.daily;

  String _periodLabel(ReviewPeriod period) {
    switch (period) {
      case ReviewPeriod.daily:
        return 'Daily';
      case ReviewPeriod.weekly:
        return 'Weekly';
      case ReviewPeriod.monthly:
        return 'Monthly';
      case ReviewPeriod.quarterly:
        return 'Quarterly';
    }
  }

  ({DateTime start, DateTime end}) _rangeForPeriod(ReviewPeriod period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (period) {
      case ReviewPeriod.daily:
        return (start: today, end: today.add(const Duration(days: 1)));
      case ReviewPeriod.weekly:
        final start = today.subtract(Duration(days: today.weekday - 1));
        return (start: start, end: start.add(const Duration(days: 7)));
      case ReviewPeriod.monthly:
        return (start: DateTime(now.year, now.month, 1), end: DateTime(now.year, now.month + 1, 1));
      case ReviewPeriod.quarterly:
        final quarterStartMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        return (
          start: DateTime(now.year, quarterStartMonth, 1),
          end: DateTime(now.year, quarterStartMonth + 3, 1),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final reviewsAsync = ref.watch(reviewsByPeriodProvider(_selectedPeriod));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showReviewDialog),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(tokens.spacing.lg),
            child: SegmentedButton<ReviewPeriod>(
              segments: ReviewPeriod.values
                  .map((period) => ButtonSegment(value: period, label: Text(_periodLabel(period))))
                  .toList(),
              selected: {_selectedPeriod},
              onSelectionChanged: (selection) => setState(() => _selectedPeriod = selection.first),
            ),
          ),
          Expanded(
            child: reviewsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => AsyncErrorView(
                error: error,
                onRetry: () => ref.invalidate(reviewsByPeriodProvider(_selectedPeriod)),
              ),
              data: (reviews) {
                if (reviews.isEmpty) {
                  return EmptyState(
                    title: 'No ${_selectedPeriod.name} reviews yet',
                    subtitle: _emptySubtitle,
                    icon: Icons.rate_review_rounded,
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(tokens.spacing.lg),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: tokens.spacing.md),
                      child: _ReviewCard(review: review, periodStartLabel: _formatDate(review.periodStart), periodEndLabel: _formatDate(review.periodEnd)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => AppDateFormatter.date(date);

  Future<void> _showReviewDialog() async {
    final result = await showDialog<_ReviewDialogResult>(
      context: context,
      builder: (_) => _ReviewDialogContent(initialPeriod: _selectedPeriod, periodLabel: _periodLabel),
    );

    if (result == null) return;

    final range = _rangeForPeriod(result.period);
    final service = ref.read(reviewServiceProvider);
    final now = DateTime.now();

    final saveResult = await service.create(
      Review(
        id: _uuid.v4(),
        createdAt: now,
        updatedAt: now,
        userId: planningUserId,
        period: result.period,
        periodStart: range.start,
        periodEnd: range.end,
        wins: result.wins.isEmpty ? null : result.wins,
        challenges: result.challenges.isEmpty ? null : result.challenges,
        lessonsLearned: result.lessons.isEmpty ? null : result.lessons,
        nextFocus: result.nextFocus.isEmpty ? null : result.nextFocus,
        rating: result.rating,
      ),
    );

    if (!mounted) return;
    if (saveResult.isFailure) {
      AppFeedback.showError(context, saveResult.error!);
      return;
    }
    AppFeedback.showSuccess(context, _reviewSavedMessage);
    ref.invalidate(reviewsByPeriodProvider(result.period));
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  final String periodStartLabel;
  final String periodEndLabel;

  const _ReviewCard({required this.review, required this.periodStartLabel, required this.periodEndLabel});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final accent = AppModuleAccents.forModule('planning');
    return AppCard(
      accentColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$periodStartLabel - $periodEndLabel', style: theme.textTheme.titleMedium),
          if (review.rating != null) ...[
            SizedBox(height: tokens.spacing.xs),
            Text('Rating: ${review.rating}/5', style: theme.textTheme.bodyMedium),
          ],
          if (review.wins != null && review.wins!.isNotEmpty) ..._section(context, 'Wins', review.wins!),
          if (review.challenges != null && review.challenges!.isNotEmpty)
            ..._section(context, 'Challenges', review.challenges!),
          if (review.lessonsLearned != null && review.lessonsLearned!.isNotEmpty)
            ..._section(context, 'Lessons learned', review.lessonsLearned!),
          if (review.nextFocus != null && review.nextFocus!.isNotEmpty)
            ..._section(context, 'Next focus', review.nextFocus!),
        ],
      ),
    );
  }

  List<Widget> _section(BuildContext context, String label, String value) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    return [
      SizedBox(height: tokens.spacing.sm),
      Text(label, style: theme.textTheme.labelLarge),
      Text(value, style: theme.textTheme.bodyMedium),
    ];
  }
}

class _ReviewDialogResult {
  _ReviewDialogResult({
    required this.period,
    required this.wins,
    required this.challenges,
    required this.lessons,
    required this.nextFocus,
    required this.rating,
  });

  final ReviewPeriod period;
  final String wins;
  final String challenges;
  final String lessons;
  final String nextFocus;
  final int? rating;
}

class _ReviewDialogContent extends StatefulWidget {
  const _ReviewDialogContent({required this.initialPeriod, required this.periodLabel});

  final ReviewPeriod initialPeriod;
  final String Function(ReviewPeriod period) periodLabel;

  @override
  State<_ReviewDialogContent> createState() => _ReviewDialogContentState();
}

class _ReviewDialogContentState extends State<_ReviewDialogContent> {
  static const String _atLeastOneFieldRequiredMessage = 'Fill in at least one field below before saving';

  final formKey = GlobalKey<FormState>();
  final winsController = TextEditingController();
  final challengesController = TextEditingController();
  final lessonsController = TextEditingController();
  final nextFocusController = TextEditingController();
  late ReviewPeriod selectedPeriod;
  int? rating = 3;

  @override
  void initState() {
    super.initState();
    selectedPeriod = widget.initialPeriod;
  }

  @override
  void dispose() {
    winsController.dispose();
    challengesController.dispose();
    lessonsController.dispose();
    nextFocusController.dispose();
    super.dispose();
  }

  String? _validateReflectionField(String? value) {
    final allFieldsEmpty = winsController.text.trim().isEmpty &&
        challengesController.text.trim().isEmpty &&
        lessonsController.text.trim().isEmpty &&
        nextFocusController.text.trim().isEmpty;
    return allFieldsEmpty ? _atLeastOneFieldRequiredMessage : null;
  }

  void _submit() {
    if (formKey.currentState?.validate() ?? false) {
      Navigator.pop(
        context,
        _ReviewDialogResult(
          period: selectedPeriod,
          wins: winsController.text.trim(),
          challenges: challengesController.text.trim(),
          lessons: lessonsController.text.trim(),
          nextFocus: nextFocusController.text.trim(),
          rating: rating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    return AppFormDialog(
      title: 'New Review',
      submitLabel: 'Save',
      onSubmit: _submit,
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<ReviewPeriod>(
              initialValue: selectedPeriod,
              items: ReviewPeriod.values
                  .map((period) => DropdownMenuItem(value: period, child: Text(widget.periodLabel(period))))
                  .toList(),
              onChanged: (value) => setState(() => selectedPeriod = value ?? selectedPeriod),
              decoration: const InputDecoration(labelText: 'Period'),
            ),
            SizedBox(height: spacing.md),
            TextFormField(
              controller: winsController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Wins'),
              validator: _validateReflectionField,
            ),
            SizedBox(height: spacing.md),
            TextFormField(
              controller: challengesController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Challenges'),
              validator: _validateReflectionField,
            ),
            SizedBox(height: spacing.md),
            TextFormField(
              controller: lessonsController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Lessons learned'),
              validator: _validateReflectionField,
            ),
            SizedBox(height: spacing.md),
            TextFormField(
              controller: nextFocusController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Next focus'),
              validator: _validateReflectionField,
            ),
            SizedBox(height: spacing.md),
            DropdownButtonFormField<int>(
              initialValue: rating,
              items: [1, 2, 3, 4, 5]
                  .map((value) => DropdownMenuItem(value: value, child: Text('$value / 5')))
                  .toList(),
              onChanged: (value) => setState(() => rating = value),
              decoration: const InputDecoration(labelText: 'Self rating'),
            ),
          ],
        ),
      ),
    );
  }
}
