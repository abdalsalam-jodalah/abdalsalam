import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../services/daily_quote.dart';
import '../services/daily_quote_category.dart';
import '../services/daily_quote_selector.dart';

class DashboardQuoteCard extends StatefulWidget {
  static const String title = 'Quote of the day';
  static const double _maxTextWidth = 880;
  static const double _quoteMarkSize = 56;
  static const double _quoteMarkOpacity = 0.18;
  static const double _secondaryOpacity = 0.82;
  static const Duration _switchDuration = Duration(milliseconds: 300);

  final bool prefersArabic;
  final DateTime Function() clock;

  const DashboardQuoteCard({super.key, this.prefersArabic = false, this.clock = DateTime.now});

  @override
  State<DashboardQuoteCard> createState() => _DashboardQuoteCardState();
}

class _DashboardQuoteCardState extends State<DashboardQuoteCard> {
  int _shift = 0;
  late bool _isArabicFirst = widget.prefersArabic;

  static IconData _iconFor(DailyQuoteCategory category) => switch (category) {
    DailyQuoteCategory.faith => Icons.mosque_rounded,
    DailyQuoteCategory.time => Icons.hourglass_bottom_rounded,
    DailyQuoteCategory.motivation => Icons.bolt_rounded,
  };

  @override
  void didUpdateWidget(DashboardQuoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prefersArabic != widget.prefersArabic) {
      _isArabicFirst = widget.prefersArabic;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final colors = Theme.of(context).colorScheme;
    final quote = DailyQuoteSelector.forDate(widget.clock(), shift: _shift);
    final isAnimated = !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

    return ClipRRect(
      borderRadius: tokens.radius.extraLargeBorder,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.primary, Color.lerp(colors.primary, colors.tertiary, 0.55)!],
          ),
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              end: tokens.spacing.lg,
              top: tokens.spacing.md,
              child: Icon(
                Icons.format_quote_rounded,
                size: DashboardQuoteCard._quoteMarkSize,
                color: colors.onPrimary.withValues(alpha: DashboardQuoteCard._quoteMarkOpacity),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(tokens.spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, quote),
                  SizedBox(height: tokens.spacing.md),
                  AnimatedSwitcher(
                    duration: isAnimated ? DashboardQuoteCard._switchDuration : Duration.zero,
                    child: KeyedSubtree(
                      key: ValueKey('quote-${quote.sourceEnglish}-${quote.english.hashCode}-$_isArabicFirst'),
                      child: _buildQuoteBody(context, quote),
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

  Widget _buildHeader(BuildContext context, DailyQuote quote) {
    final tokens = AppThemeTokens.of(context);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Flexible(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.onPrimary.withValues(alpha: 0.18),
              borderRadius: tokens.radius.pillBorder,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spacing.md, vertical: tokens.spacing.xs + 1),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_iconFor(quote.category), size: 16, color: colors.onPrimary),
                  SizedBox(width: tokens.spacing.xs),
                  Flexible(
                    child: Text(
                      DashboardQuoteCard.title,
                      key: const ValueKey('quote-title'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium?.copyWith(color: colors.onPrimary, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      ' · ${quote.category.label}',
                      key: const ValueKey('quote-category'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium?.copyWith(color: colors.onPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          key: const ValueKey('quote-translate'),
          tooltip: _isArabicFirst ? 'Show English first' : 'عرض العربية أولًا',
          color: colors.onPrimary,
          icon: const Icon(Icons.translate_rounded),
          onPressed: () => setState(() => _isArabicFirst = !_isArabicFirst),
        ),
        IconButton(
          key: const ValueKey('quote-next'),
          tooltip: 'Next quote',
          color: colors.onPrimary,
          icon: const Icon(Icons.autorenew_rounded),
          onPressed: () => setState(() => _shift += 1),
        ),
      ],
    );
  }

  Widget _buildQuoteBody(BuildContext context, DailyQuote quote) {
    final tokens = AppThemeTokens.of(context);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final primaryStyle = textTheme.titleLarge?.copyWith(color: colors.onPrimary, fontWeight: FontWeight.w700, height: 1.55);
    final secondaryStyle = textTheme.bodyLarge?.copyWith(
      color: colors.onPrimary.withValues(alpha: DashboardQuoteCard._secondaryOpacity),
      height: 1.5,
    );
    final sourceStyle = textTheme.labelLarge?.copyWith(color: colors.onPrimary, fontWeight: FontWeight.w600);

    final arabic = _LocalizedText(
      key: const ValueKey('quote-arabic'),
      text: quote.arabic,
      direction: TextDirection.rtl,
      style: _isArabicFirst ? primaryStyle : secondaryStyle,
    );
    final english = _LocalizedText(
      key: const ValueKey('quote-english'),
      text: quote.english,
      direction: TextDirection.ltr,
      style: _isArabicFirst ? secondaryStyle : primaryStyle,
    );
    final source = _LocalizedText(
      key: const ValueKey('quote-source'),
      text: _isArabicFirst ? quote.sourceArabic : quote.sourceEnglish,
      direction: _isArabicFirst ? TextDirection.rtl : TextDirection.ltr,
      style: sourceStyle,
      prefix: '— ',
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: DashboardQuoteCard._maxTextWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _isArabicFirst ? arabic : english,
          SizedBox(height: tokens.spacing.sm),
          _isArabicFirst ? english : arabic,
          SizedBox(height: tokens.spacing.md),
          source,
        ],
      ),
    );
  }
}

class _LocalizedText extends StatelessWidget {
  final String text;
  final TextDirection direction;
  final TextStyle? style;
  final String prefix;

  const _LocalizedText({super.key, required this.text, required this.direction, required this.style, this.prefix = ''});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: direction,
      child: Text('$prefix$text', style: style, textAlign: TextAlign.start),
    );
  }
}
