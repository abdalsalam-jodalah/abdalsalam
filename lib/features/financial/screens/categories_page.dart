import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/financial/category_model.dart';
import '../providers/financial_providers.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  static const routeName = '/financial/categories';

  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  CategoryType _selectedType = CategoryType.expense;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddCategoryDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTypeFilter(),
          Expanded(
            child: _buildCategoriesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SegmentedButton<CategoryType>(
        segments: const [
          ButtonSegment(
            value: CategoryType.expense,
            label: Text('Expenses'),
            icon: Icon(Icons.arrow_upward),
          ),
          ButtonSegment(
            value: CategoryType.income,
            label: Text('Income'),
            icon: Icon(Icons.arrow_downward),
          ),
        ],
        selected: {_selectedType},
        onSelectionChanged: (Set<CategoryType> newSelection) {
          setState(() {
            _selectedType = newSelection.first;
          });
        },
      ),
    );
  }

  Widget _buildCategoriesList() {
    final categories = _getSampleCategories()
        .where((cat) => cat.type == _selectedType)
        .toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    // Sample spending amount - replace with real data
    final amount = 450.0;

    return Card(
      child: InkWell(
        onTap: () => _showCategoryDetails(category),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      category.icon,
                      color: category.color,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editCategory(category);
                      } else if (value == 'delete') {
                        _deleteCategory(category);
                      }
                    },
                  ),
                ],
              ),
              const Spacer(),
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'This month',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryDetails(CategoryModel category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        category.icon,
                        color: category.color,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            category.type.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatCard('This Month', '\$450.00', Colors.blue),
                _buildStatCard('Last Month', '\$380.00', Colors.green),
                _buildStatCard('Average', '\$415.00', Colors.orange),
                const SizedBox(height: 24),
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildTransactionItem('Grocery Store', 85.50, DateTime.now()),
                      _buildTransactionItem('Supermarket', 120.00, DateTime.now().subtract(const Duration(days: 2))),
                      _buildTransactionItem('Local Market', 45.00, DateTime.now().subtract(const Duration(days: 5))),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(String description, double amount, DateTime date) {
    return ListTile(
      leading: const Icon(Icons.receipt),
      title: Text(description),
      subtitle: Text(
        '${date.day}/${date.month}/${date.year}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Text(
        '\$${amount.toStringAsFixed(2)}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CategoryType>(
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                initialValue: CategoryType.expense,
                items: const [
                  DropdownMenuItem(
                    value: CategoryType.expense,
                    child: Text('Expense'),
                  ),
                  DropdownMenuItem(
                    value: CategoryType.income,
                    child: Text('Income'),
                  ),
                ],
                onChanged: (value) {},
              ),
              const SizedBox(height: 16),
              const Text('Select Icon'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildIconOption(Icons.shopping_cart),
                  _buildIconOption(Icons.restaurant),
                  _buildIconOption(Icons.directions_car),
                  _buildIconOption(Icons.home),
                  _buildIconOption(Icons.movie),
                  _buildIconOption(Icons.fitness_center),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Actually save category to database
              Navigator.pop(context);
              
              // Refresh categories list
              ref.invalidate(allCategoriesProvider);
              ref.invalidate(categoryTotalsProvider);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Category created successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _buildIconOption(IconData icon) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon),
      ),
    );
  }

  void _editCategory(CategoryModel category) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit category coming soon')),
    );
  }

  void _deleteCategory(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Actually delete category from database
              Navigator.pop(context);
              
              // Refresh categories list
              ref.invalidate(allCategoriesProvider);
              ref.invalidate(categoryTotalsProvider);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Category deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  List<CategoryModel> _getSampleCategories() {
    final now = DateTime.now();
    return [
      CategoryModel(
        id: 'cat1',
        userId: 'user1',
        name: 'Food & Dining',
        type: CategoryType.expense,
        icon: Icons.restaurant,
        color: Colors.orange,
        createdAt: now,
        updatedAt: now,
      ),
      CategoryModel(
        id: 'cat2',
        userId: 'user1',
        name: 'Transport',
        type: CategoryType.expense,
        icon: Icons.directions_car,
        color: Colors.blue,
        createdAt: now,
        updatedAt: now,
      ),
      CategoryModel(
        id: 'cat3',
        userId: 'user1',
        name: 'Shopping',
        type: CategoryType.expense,
        icon: Icons.shopping_bag,
        color: Colors.purple,
        createdAt: now,
        updatedAt: now,
      ),
      CategoryModel(
        id: 'cat4',
        userId: 'user1',
        name: 'Bills',
        type: CategoryType.expense,
        icon: Icons.receipt,
        color: Colors.red,
        createdAt: now,
        updatedAt: now,
      ),
      CategoryModel(
        id: 'cat5',
        userId: 'user1',
        name: 'Salary',
        type: CategoryType.income,
        icon: Icons.attach_money,
        color: Colors.green,
        createdAt: now,
        updatedAt: now,
      ),
      CategoryModel(
        id: 'cat6',
        userId: 'user1',
        name: 'Freelance',
        type: CategoryType.income,
        icon: Icons.work,
        color: Colors.teal,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
