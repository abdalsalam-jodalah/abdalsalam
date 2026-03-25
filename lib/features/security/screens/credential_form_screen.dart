import 'package:flutter/material.dart';

import '../widgets/security_widgets.dart';

class CredentialFormScreen extends StatefulWidget {
  static const routeName = '/security/new-credential';

  const CredentialFormScreen({super.key});

  @override
  State<CredentialFormScreen> createState() => _CredentialFormScreenState();
}

class _CredentialFormScreenState extends State<CredentialFormScreen> {
  final _titleController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  int get _strength {
    final value = _passController.text;
    var score = 0;
    if (value.length >= 8) score += 30;
    if (RegExp(r'[A-Z]').hasMatch(value)) score += 20;
    if (RegExp(r'[a-z]').hasMatch(value)) score += 20;
    if (RegExp(r'[0-9]').hasMatch(value)) score += 15;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score += 15;
    return score.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Credential')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 10),
          TextField(controller: _userController, decoration: const InputDecoration(labelText: 'Username')),
          const SizedBox(height: 10),
          TextField(
            controller: _passController,
            decoration: const InputDecoration(labelText: 'Password'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          PasswordStrengthIndicator(value: _strength),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
