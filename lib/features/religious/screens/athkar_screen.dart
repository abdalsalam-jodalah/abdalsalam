import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/religious/athkar_content.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/athkar_providers.dart';
import '../providers/prayer_providers.dart';
import 'athkar_history_screen.dart';

class AthkarScreen extends ConsumerStatefulWidget {
  const AthkarScreen({super.key});

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Athkar'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            ..._categories.map((c) => Tab(text: athkarCategoryLabel(c))),
            const Tab(text: 'History', icon: Icon(Icons.history, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ..._categories.map((c) => _CategoryTab(category: c)),
          const AthkarHistoryView(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Custom Athkar'),
      ),
    );
  }

  Future<void> _showAddCustomDialog(BuildContext context, WidgetRef ref) async {
    final arabicController = TextEditingController();
    final transliterationController = TextEditingController();
    final translationController = TextEditingController();
    final targetCountController = TextEditingController(text: '1');
    var selectedCategory = AthkarCategory.custom;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        String? arabicError;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
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
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(athkarCategoryLabel(c))))
                        .toList(),
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
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  setState(() {
                    arabicError =
                        arabicController.text.trim().isEmpty ? 'Arabic text is required' : null;
                  });
                  if (arabicError == null) {
                    Navigator.of(context).pop(true);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );

    if (shouldSave != true || !context.mounted) {
      return;
    }

    final targetCount = int.tryParse(targetCountController.text.trim()) ?? 1;
    final message = await ref.read(athkarLogsControllerProvider.notifier).addCustomAthkar(
          arabicText: arabicController.text.trim(),
          transliteration: transliterationController.text.trim().isEmpty
              ? null
              : transliterationController.text.trim(),
          translation: translationController.text.trim().isEmpty
              ? null
              : translationController.text.trim(),
          category: selectedCategory,
          targetCount: targetCount,
        );

    if (message != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$_done / ${content.targetCount}'
                    '${content.reference != null ? ' • ${content.reference}' : ''}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                IconButton(
                  onPressed: completed
                      ? null
                      : () => setState(() => _done = _done + 1),
                  icon: const Icon(Icons.add_circle_outline),
                ),
                IconButton(
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
                  icon: const Icon(Icons.check_circle),
                  color: completed ? Theme.of(context).colorScheme.primary : null,
                ),
                if (content.isCustom)
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
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
