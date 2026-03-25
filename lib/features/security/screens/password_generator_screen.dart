import 'package:flutter/material.dart';

import '../widgets/security_widgets.dart';

class PasswordGeneratorScreen extends StatefulWidget {
  static const routeName = '/security/password-generator';

  const PasswordGeneratorScreen({super.key});

  @override
  State<PasswordGeneratorScreen> createState() => _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  String _generated = 'Tap generate to create a password';

  String _generate() {
    const source = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%^&*';
    final chars = List<String>.generate(16, (index) => source[(DateTime.now().microsecondsSinceEpoch + index) % source.length]);
    return chars.join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Password Generator')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: PasswordGeneratorWidget(
          password: _generated,
          onGenerate: () => setState(() => _generated = _generate()),
        ),
      ),
    );
  }
}
