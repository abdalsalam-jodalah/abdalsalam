import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/financial/category_model.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/ui/app_section_header.dart';
import '../providers/financial_providers.dart';
import '../screens/budgets_page.dart';
import 'financial_budget_tile.dart';

class FinancialBudgetsSection extends ConsumerWidget {
  static const String _title = 'Budgets';
  static const String _viewMoreLabel = 'View More';
  static const String _emptyTitle = 'No active budgets';
  static const String _emptySubtitle = 'Set a budget from the Budgets tab to track your spending.';
  static const double _listHeight = 148;

  const FinancialBudgetsSection({super.key});

  Future<void> _viewMore(BuildContext context, WidgetRef ref) async {
    await Navigator.pushNamed(context, BudgetsPage.routeName);
    if (!context.mounted) return;
    ref.invalidate(activeBudgetsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppThemeTokens.of(context);
    final budgetsAsync = ref.watch(activeBudgetsProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: _title,
          padding: EdgeInsets.zero,
          action: TextButton(onPressed: () => _viewMore(context, ref), child: const Text(_viewMoreLabel)),
        ),
        SizedBox(height: tokens.spacing.sm),
        budgetsAsync.when(
          data: (budgets) {
            if (budgets.isEmpty) {
              return const EmptyState(title: _emptyTitle, subtitle: _emptySubtitle, icon: Icons.savings_outlined, isCompact: true);
            }
            return SizedBox(
              height: _listHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: budgets.length,
                itemBuilder: (context, index) {
                  final budget = budgets[index];
                  return Padding(
                    padding: EdgeInsets.only(right: tokens.spacing.md),
                    child: categoriesAsync.when(
                      data: (categories) {
                        final category = categories.firstWhere(
                          (c) => c.id == budget.categoryId,
                          orElse: CategoryModel.unknown,
                        );
                        final progressAsync = ref.watch(budgetProgressProvider(budget));
                        return progressAsync.when(
                          data: (progress) => FinancialBudgetTile(
                            categoryName: category.name,
                            categoryIcon: category.icon,
                            accentColor: category.color,
                            budgetAmount: budget.amount,
                            spentAmount: (progress['spent'] as double?) ?? 0,
                          ),
                          loading: () => FinancialBudgetTile(
                            categoryName: category.name,
                            categoryIcon: category.icon,
                            accentColor: category.color,
                            budgetAmount: budget.amount,
                            spentAmount: 0,
                          ),
                          error: (error, stack) => FinancialBudgetTile(
                            categoryName: category.name,
                            categoryIcon: category.icon,
                            accentColor: category.color,
                            budgetAmount: budget.amount,
                            error: error,
                            onRetry: () => ref.invalidate(budgetProgressProvider(budget)),
                          ),
                        );
                      },
                      loading: () => const SizedBox(
                        width: FinancialBudgetTile.width,
                        child: LoadingSkeleton(lines: 1, isScrollable: false),
                      ),
                      error: (error, stack) => SizedBox(
                        width: FinancialBudgetTile.width,
                        child: AsyncErrorView(
                          error: error,
                          isCompact: true,
                          onRetry: () => ref.invalidate(allCategoriesProvider),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const LoadingSkeleton(lines: 2, isScrollable: false),
          error: (error, stack) => AsyncErrorView(error: error, onRetry: () => ref.invalidate(activeBudgetsProvider)),
        ),
      ],
    );
  }
}
