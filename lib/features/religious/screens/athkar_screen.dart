import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/religious/athkar_content.dart';
import '../../../shared/widgets/empty_state.dart';
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

class _AthkarScreenState extends ConsumerState<AthkarScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _categories = AthkarCategory.values;

  @override
  void initState() {
    super.initState();
    // +1 tab for the History view, appended after the category tabs.
    _tabController = TabController(length: _categories.length + 1, vsync: this);
    Future.microtask(
      () => ref.read(athkarServiceProvider).scheduleSuggestionReminders(userId: demoUserId),
    );
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
        const Tab(text: 'History', icon: Icon(Icons.history, size: 18)),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              children: [
                Text(
                  'Athkar',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Add Custom Athkar',
                  onPressed: () => _showAddCustomDialog(context, ref),
                ),
              ],
            ),
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
    final result = await showDialog<_CustomAthkarResult>(
      context: context,
      builder: (_) => const _CustomAthkarDialogContent(),
    );

    if (result == null) return;

    final message = await ref.read(athkarLogsControllerProvider.notifier).addCustomAthkar(
          arabicText: result.arabicText,
          transliteration: result.transliteration,
          translation: result.translation,
          category: result.category,
          targetCount: result.targetCount,
        );

    if (message != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _CustomAthkarResult {
  _CustomAthkarResult({
    required this.arabicText,
    required this.transliteration,
    required this.translation,
    required this.category,
    required this.targetCount,
  });

  final String arabicText;
  final String? transliteration;
  final String? translation;
  final AthkarCategory category;
  final int targetCount;
}

class _CustomAthkarDialogContent extends StatefulWidget {
  const _CustomAthkarDialogContent();

  @override
  State<_CustomAthkarDialogContent> createState() => _CustomAthkarDialogContentState();
}

class _CustomAthkarDialogContentState extends State<_CustomAthkarDialogContent> {
  final arabicController = TextEditingController();
  final transliterationController = TextEditingController();
  final translationController = TextEditingController();
  final targetCountController = TextEditingController(text: '1');
  var selectedCategory = AthkarCategory.custom;
  String? arabicError;

  static const _categories = AthkarCategory.values;

  @override
  void dispose() {
    arabicController.dispose();
    transliterationController.dispose();
    translationController.dispose();
    targetCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Custom Athkar'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: arabicController,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: 'Arabic text',
                errorText: arabicError,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: transliterationController,
              decoration: const InputDecoration(labelText: 'Transliteration (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: translationController,
              decoration: const InputDecoration(labelText: 'Translation (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetCountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Target count'),
            ),
            const SizedBox(height: 12),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            setState(() {
              arabicError = arabicController.text.trim().isEmpty ? 'Arabic text is required' : null;
            });
            if (arabicError == null) {
              Navigator.of(context).pop(
                _CustomAthkarResult(
                  arabicText: arabicController.text.trim(),
                  transliteration: transliterationController.text.trim().isEmpty
                      ? null
                      : transliterationController.text.trim(),
                  translation:
                      translationController.text.trim().isEmpty ? null : translationController.text.trim(),
                  category: selectedCategory,
                  targetCount: int.tryParse(targetCountController.text.trim()) ?? 1,
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _CategoryTab extends ConsumerWidget {
  const _CategoryTab({required this.category});

  final AthkarCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) => _AthkarCard(content: entries[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
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
  int _done = 0;

  @override
  Widget build(BuildContext context) {
    final content = widget.content;
    final completed = _done >= content.targetCount;
    final scheme = Theme.of(context).colorScheme;
    final progress = content.targetCount == 0 ? 0.0 : (_done / content.targetCount).clamp(0, 1).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              content.arabicText,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (content.transliteration != null) ...[
              const SizedBox(height: 8),
              Text(
                content.transliteration!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
            if (content.translation != null) ...[
              const SizedBox(height: 4),
              Text(content.translation!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: scheme.surfaceContainerHighest,
                color: completed ? scheme.primary : scheme.tertiary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$_done / ${content.targetCount}'
                    '${content.reference != null ? ' • ${content.reference}' : ''}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: completed
                      ? null
                      : () => setState(() => _done = _done + 1),
                  icon: const Icon(Icons.add),
                  tooltip: 'Count one',
                ),
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  onPressed: !completed
                      ? null
                      : () async {
                          final message = await ref
                              .read(athkarLogsControllerProvider.notifier)
                              .logCompletion(content: content, countDone: _done);
                          if (message != null && context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(message)));
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Athkar logged')),
                            );
                            setState(() => _done = 0);
                          }
                        },
                  icon: const Icon(Icons.check),
                  tooltip: 'Log completion',
                  style: completed
                      ? IconButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                        )
                      : null,
                ),
                if (content.isCustom) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: () async {
                      final message = await ref
                          .read(athkarLogsControllerProvider.notifier)
                          .deleteCustomAthkar(content.id);
                      if (message != null && context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(message)));
                      }
                    },
                    icon: Icon(Icons.delete_outline, color: scheme.error),
                    tooltip: 'Delete',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
