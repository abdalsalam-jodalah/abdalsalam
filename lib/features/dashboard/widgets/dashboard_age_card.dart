import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/personal_profile.dart';
import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/icon_badge.dart';
import '../services/life_age.dart';

class DashboardAgeCard extends StatefulWidget {
  static const String label = 'My age';
  static const Duration _refreshInterval = Duration(seconds: 10);

  final DateTime Function() clock;

  const DashboardAgeCard({super.key, this.clock = DateTime.now});

  @override
  State<DashboardAgeCard> createState() => _DashboardAgeCardState();
}

class _DashboardAgeCardState extends State<DashboardAgeCard> {
  static final NumberFormat _numberFormat = NumberFormat.decimalPattern();

  late LifeAge _age = _currentAge();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(DashboardAgeCard._refreshInterval, (_) => setState(() => _age = _currentAge()));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  LifeAge _currentAge() => LifeAge.between(PersonalProfile.birthDate, widget.clock());

  String _format(int value) => _numberFormat.format(value);

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const IconBadge(icon: Icons.cake_rounded),
              SizedBox(width: spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DashboardAgeCard.label, style: textTheme.titleMedium),
                    Text('Born ${AppDateFormatter.dateTime(PersonalProfile.birthDate)}', style: textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.lg),
          _AgeFigures(
            figures: [
              _AgeFigure('Years', _format(_age.years)),
              _AgeFigure('Days', _format(_age.days)),
              _AgeFigure('Hours', _format(_age.hours)),
              _AgeFigure('Minutes', _format(_age.minutes)),
            ],
            valueStyle: textTheme.headlineSmall,
          ),
          Divider(height: spacing.xl),
          _AgeFigures(
            figures: [
              _AgeFigure('Total days', _format(_age.totalDays)),
              _AgeFigure('Total hours', _format(_age.totalHours)),
              _AgeFigure('Total minutes', _format(_age.totalMinutes)),
            ],
            valueStyle: textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _AgeFigure {
  final String label;
  final String value;

  const _AgeFigure(this.label, this.value);
}

class _AgeFigures extends StatelessWidget {
  final List<_AgeFigure> figures;
  final TextStyle? valueStyle;

  const _AgeFigures({required this.figures, required this.valueStyle});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final labelColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        for (final figure in figures)
          Expanded(
            child: Column(
              children: [
                FittedBox(fit: BoxFit.scaleDown, child: Text(figure.value, style: valueStyle)),
                Text(figure.label, style: textTheme.bodySmall?.copyWith(color: labelColor)),
              ],
            ),
          ),
      ],
    );
  }
}
