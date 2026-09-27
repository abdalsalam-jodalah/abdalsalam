import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../widgets/security_widgets.dart';

class PasswordGeneratorScreen extends StatefulWidget {
  static const routeName = '/security/password-generator';

  const PasswordGeneratorScreen({super.key});

  @override
  State<PasswordGeneratorScreen> createState() => _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  static const String _initialMessage = 'Tap generate to create a password';
  static const int _passwordLength = 16;
  static const String _characterSource =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%^&*';

  String _generated = _initialMessage;

  String _generate() {
    final chars = List<String>.generate(
      _passwordLength,
      (index) => _characterSource[(DateTime.now().microsecondsSinceEpoch + index) % _characterSource.length],
    );
    return chars.join();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Password Generator')),
      body: Padding(
        padding: EdgeInsets.all(tokens.spacing.lg),
        child: PasswordGeneratorWidget(
          password: _generated,
          onGenerate: () => setState(() => _generated = _generate()),
        ),
      ),
    );
  }
}
