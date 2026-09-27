import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/sports/exercise_category.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ui/app_section_header.dart';
import '../providers/sports_providers.dart';
import '../widgets/sports_category_name_dialog.dart';
import '../widgets/sports_category_section.dart';

const _uuid = Uuid();

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  static const routeName = '/sports/library';
  static const String title = 'Exercise Library';

  /// When true, renders without its own [Scaffold]/[AppBar] for embedding
  /// inside the tabbed [SportsScreen] shell.
  final bool embedded;

  const ExerciseLibraryScreen({super.key, this.embedded = false});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  static const String _emptyTitle = 'No categories yet';
  static const String _emptySubtitle = 'Tap + to add your first category (e.g. Chest, Back, Cardio)';
  static const String _addCategoryTooltip = 'Add category';

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final categoriesAsync = ref.watch(exerciseCategoriesProvider);

    final body = categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => AsyncErrorView(
        error: error,
        onRetry: () => ref.invalidate(exerciseCategoriesProvider),
      ),
      data: (categories) {
        if (categories.isEmpty) {
          return const EmptyState(
            title: _emptyTitle,
            subtitle: _emptySubtitle,
            icon: Icons.category_outlined,
          );
        }
        return ListView(
          padding: EdgeInsets.all(tokens.spacing.lg),
          children: [
            for (final category in categories)
              Padding(
                padding: EdgeInsets.only(bottom: tokens.spacing.lg),
                child: SportsCategorySection(key: ValueKey(category.id), category: category),
              ),
          ],
        );
      },
    );

    final addAction = IconButton(
      icon: const Icon(Icons.add),
      tooltip: _addCategoryTooltip,
      onPressed: _showCategoryDialog,
    );

    if (widget.embedded) {
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(tokens.spacing.lg, tokens.spacing.lg, tokens.spacing.sm, 0),
            child: AppSectionHeader(title: ExerciseLibraryScreen.title, padding: EdgeInsets.zero, action: addAction),
          ),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text(ExerciseLibraryScreen.title), actions: [addAction]),
      body: body,
    );
  }

  Future<void> _showCategoryDialog() async {
    final name = await showSportsCategoryNameDialog(context);

    if (name == null) return;

    if (!mounted) {
      return;
    }
    final service = ref.read(exerciseCategoryServiceProvider);
    final now = DateTime.now();
    final existing = ref.read(exerciseCategoriesProvider).maybeWhen(
          data: (list) => list,
          orElse: () => const <ExerciseCategory>[],
        );
    final createResult = await service.create(
      ExerciseCategory(
        id: _uuid.v4(),
        createdAt: now,
        updatedAt: now,
        userId: sportUserId,
        name: name,
        order: existing.length,
      ),
    );
    if (!mounted) {
      return;
    }
    if (createResult.isFailure) {
      AppFeedback.showError(context, createResult.error!);
    }
    ref.invalidate(exerciseCategoriesProvider);
  }
}
