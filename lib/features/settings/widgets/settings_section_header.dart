import 'package:flutter/material.dart';

import '../../../shared/widgets/ui/app_section_header.dart';

class SettingsSectionHeader extends StatelessWidget {
  final String title;

  const SettingsSectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionHeader(title: title);
  }
}
