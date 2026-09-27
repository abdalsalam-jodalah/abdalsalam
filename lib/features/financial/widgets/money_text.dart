import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';

class MoneyFormatter {
  static const String defaultSymbol = '₪';

  const MoneyFormatter._();

  static String format(
    double amount, {
    String symbol = defaultSymbol,
    int decimalDigits = 2,
    bool showPlusSign = false,
  }) {
    final isNegative = amount < 0;
    final prefix = isNegative ? '-' : (showPlusSign ? '+' : '');
    return '$prefix$symbol${amount.abs().toStringAsFixed(decimalDigits)}';
  }
}

class MoneyText extends StatelessWidget {
  final double amount;
  final String symbol;
  final int decimalDigits;
  final bool showPlusSign;
  final bool colorByAmount;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const MoneyText(
    this.amount, {
    super.key,
    this.symbol = MoneyFormatter.defaultSymbol,
    this.decimalDigits = 2,
    this.showPlusSign = false,
    this.colorByAmount = false,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final text = MoneyFormatter.format(
      amount,
      symbol: symbol,
      decimalDigits: decimalDigits,
      showPlusSign: showPlusSign,
    );
    var resolvedStyle = style;
    if (colorByAmount) {
      final colors = AppThemeTokens.of(context).colors;
      final amountColor = amount < 0 ? colors.expense : colors.income;
      resolvedStyle = (resolvedStyle ?? DefaultTextStyle.of(context).style).copyWith(color: amountColor);
    }
    return Text(text, style: resolvedStyle, maxLines: maxLines, overflow: overflow);
  }
}
