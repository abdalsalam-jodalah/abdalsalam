import 'package:flutter/material.dart';

class CredentialCard extends StatelessWidget {
  final String title;
  final String username;
  final String maskedPassword;
  final VoidCallback onReveal;

  const CredentialCard({
    super.key,
    required this.title,
    required this.username,
    required this.maskedPassword,
    required this.onReveal,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text('$username\n$maskedPassword'),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.visibility_outlined),
          onPressed: onReveal,
        ),
      ),
    );
  }
}

class PasswordStrengthIndicator extends StatelessWidget {
  final int value;

  const PasswordStrengthIndicator({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = value >= 70
        ? Colors.green
        : value >= 40
            ? Colors.orange
            : Colors.red;
    final label = value >= 70
        ? 'Strong'
        : value >= 40
            ? 'Medium'
            : 'Weak';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(value: value / 100, color: color),
        const SizedBox(height: 4),
        Text('$label ($value/100)'),
      ],
    );
  }
}

class PasswordGeneratorWidget extends StatelessWidget {
  final String password;
  final VoidCallback onGenerate;

  const PasswordGeneratorWidget({
    super.key,
    required this.password,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Generated Password'),
            const SizedBox(height: 8),
            SelectableText(password, style: const TextStyle(fontFamily: 'monospace')),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.casino_outlined),
              label: const Text('Generate Again'),
            ),
          ],
        ),
      ),
    );
  }
}
