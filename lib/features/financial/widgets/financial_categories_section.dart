import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/ui/app_section_header.dart';
import '../../../shared/widgets/ui/stat_grid.dart';
import '../../../shared/widgets/ui/stat_tile.dart';
import '../providers/financial_providers.dart';
import '../screens/categories_page.dart';
import 'money_text.dart';

class FinancialCategoriesSection extends ConsumerWidget {
  static const String _title = 'Categories';
  static const String _viewMoreLabel = 'View More';
  static const String _emptyTitle = 'No categories yet';
  static const String _emptySubtitle = 'Add a category from the Categories tab to start tracking.';
  static const int _displayLimit = 4;

  final DateRange dateRange;

  const FinancialCategoriesSection({super.key, required this.dateRange});

  Future<void> _viewMore(BuildContext context, WidgetRef ref) async {
    await Navigator.pushNamed(context, CategoriesPage.routeName);
    if (!context.mounted) return;
    ref.invalidate(allCategoriesProvider);
    ref.invalidate(categoryTotalsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppThemeTokens.of(context);
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final categoryTotalsAsync = ref.watch(categoryTotalsProvider(dateRange));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: _title,
          padding: EdgeInsets.zero,
          action: TextButton(onPressed: () => _viewMore(context, ref), child: const Text(_viewMoreLabel)),
        ),
        SizedBox(height: tokens.spacing.sm),
        categoriesAsync.when(
          data: (categories) {
            if (categories.isEmpty) {
              return const EmptyState(
                title: _emptyTitle,
                subtitle: _emptySubtitle,
                icon: Icons.category_outlined,
                isCompact: true,
              );
            }
            return categoryTotalsAsync.when(
              data: (totals) => StatGrid(
                children: [
                  for (final category in categories.take(_displayLimit))
                    StatTile(
                      icon: category.icon,
                      label: category.name,
                      value: MoneyFormatter.format(totals[category.id] ?? 0, decimalDigits: 0),
                      accentColor: category.color,
                    ),
                ],
              ),
              loading: () => const LoadingSkeleton(lines: 2, isScrollable: false),
              error: (error, stack) => AsyncErrorView(
                error: error,
                isCompact: true,
                onRetry: () => ref.invalidate(categoryTotalsProvider(dateRange)),
              ),
            );
          },
          loading: () => const LoadingSkeleton(lines: 2, isScrollable: false),
          error: (error, stack) => AsyncErrorView(error: error, onRetry: () => ref.invalidate(allCategoriesProvider)),
        ),
      ],
    );
  }
}
