import 'package:flutter/material.dart';

class SecurityCategoriesScreen extends StatelessWidget {
  static const routeName = '/security/categories';

  const SecurityCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const categories = ['Banking', 'Email', 'Social Media', 'Work', 'Personal'];
    return Scaffold(
      appBar: AppBar(title: const Text('Credential Categories')),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(categories[index]),
          );
        },
      ),
    );
  }
}
