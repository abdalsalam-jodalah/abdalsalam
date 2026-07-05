import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/planning/review.dart';
import '../providers/planning_providers.dart';

class ReviewsScreen extends ConsumerStatefulWidget {
  static const routeName = '/planning/reviews';

  const ReviewsScreen({super.key});

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
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
            padding: const EdgeInsets.all(16),
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
              error: (error, stack) => const Center(child: Text('Failed to load reviews')),
              data: (reviews) {
                if (reviews.isEmpty) {
                  return Center(child: Text('No ${_selectedPeriod.name} reviews yet. Tap + to add one.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_formatDate(review.periodStart)} - ${_formatDate(review.periodEnd)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (review.rating != null) ...[
                              const SizedBox(height: 4),
                              Text('Rating: ${review.rating}/5'),
                            ],
                            if (review.wins != null && review.wins!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('Wins', style: Theme.of(context).textTheme.labelLarge),
                              Text(review.wins!),
                            ],
                            if (review.challenges != null && review.challenges!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('Challenges', style: Theme.of(context).textTheme.labelLarge),
                              Text(review.challenges!),
                            ],
                            if (review.lessonsLearned != null && review.lessonsLearned!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('Lessons learned', style: Theme.of(context).textTheme.labelLarge),
                              Text(review.lessonsLearned!),
                            ],
                            if (review.nextFocus != null && review.nextFocus!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('Next focus', style: Theme.of(context).textTheme.labelLarge),
                              Text(review.nextFocus!),
                            ],
                          ],
                        ),
                      ),
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

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _showReviewDialog() async {
    final formKey = GlobalKey<FormState>();
    final winsController = TextEditingController();
    final challengesController = TextEditingController();
    final lessonsController = TextEditingController();
    final nextFocusController = TextEditingController();
    ReviewPeriod selectedPeriod = _selectedPeriod;
    int? rating = 3;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('New Review'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<ReviewPeriod>(
                    initialValue: selectedPeriod,
                    items: ReviewPeriod.values
                        .map((period) => DropdownMenuItem(value: period, child: Text(_periodLabel(period))))
                        .toList(),
                    onChanged: (value) => setDialogState(() => selectedPeriod = value ?? selectedPeriod),
                    decoration: const InputDecoration(labelText: 'Period', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: winsController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Wins', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: challengesController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Challenges', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: lessonsController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Lessons learned', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nextFocusController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Next focus', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: rating,
                    items: [1, 2, 3, 4, 5]
                        .map((value) => DropdownMenuItem(value: value, child: Text('$value / 5')))
                        .toList(),
                    onChanged: (value) => setDialogState(() => rating = value),
                    decoration: const InputDecoration(labelText: 'Self rating', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) {
      winsController.dispose();
      challengesController.dispose();
      lessonsController.dispose();
      nextFocusController.dispose();
      return;
    }

    final wins = winsController.text.trim();
    final challenges = challengesController.text.trim();
    final lessons = lessonsController.text.trim();
    final nextFocus = nextFocusController.text.trim();
    winsController.dispose();
    challengesController.dispose();
    lessonsController.dispose();
    nextFocusController.dispose();

    final range = _rangeForPeriod(selectedPeriod);
    final repo = ref.read(reviewRepositoryProvider);
    final now = DateTime.now();

    final result = await repo.create(
      Review(
        id: _uuid.v4(),
        createdAt: now,
        updatedAt: now,
        userId: planningUserId,
        period: selectedPeriod,
        periodStart: range.start,
        periodEnd: range.end,
        wins: wins.isEmpty ? null : wins,
        challenges: challenges.isEmpty ? null : challenges,
        lessonsLearned: lessons.isEmpty ? null : lessons,
        nextFocus: nextFocus.isEmpty ? null : nextFocus,
        rating: rating,
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.isSuccess ? 'Review saved' : 'Something went wrong'),
        backgroundColor: result.isSuccess ? Colors.green : Colors.red,
      ),
    );
    ref.invalidate(reviewsByPeriodProvider(selectedPeriod));
  }
}
