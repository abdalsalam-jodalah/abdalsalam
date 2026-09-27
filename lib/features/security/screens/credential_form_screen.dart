import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../widgets/security_widgets.dart';

class CredentialFormScreen extends StatefulWidget {
  static const routeName = '/security/new-credential';

  const CredentialFormScreen({super.key});

  @override
  State<CredentialFormScreen> createState() => _CredentialFormScreenState();
}

class _CredentialFormScreenState extends State<CredentialFormScreen> {
  static const int _lengthScore = 30;
  static const int _uppercaseScore = 20;
  static const int _lowercaseScore = 20;
  static const int _digitScore = 15;
  static const int _symbolScore = 15;
  static const int _minimumPasswordLength = 8;

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
    if (value.length >= _minimumPasswordLength) score += _lengthScore;
    if (RegExp(r'[A-Z]').hasMatch(value)) score += _uppercaseScore;
    if (RegExp(r'[a-z]').hasMatch(value)) score += _lowercaseScore;
    if (RegExp(r'[0-9]').hasMatch(value)) score += _digitScore;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score += _symbolScore;
    return score.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Add Credential')),
      body: ListView(
        padding: EdgeInsets.all(tokens.spacing.lg),
        children: [
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
          SizedBox(height: tokens.spacing.sm),
          TextField(controller: _userController, decoration: const InputDecoration(labelText: 'Username')),
          SizedBox(height: tokens.spacing.sm),
          TextField(
            controller: _passController,
            decoration: const InputDecoration(labelText: 'Password'),
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: tokens.spacing.sm),
          PasswordStrengthIndicator(value: _strength),
          SizedBox(height: tokens.spacing.lg),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
