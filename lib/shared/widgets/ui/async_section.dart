import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_motion.dart';
import '../async_error_view.dart';
import '../loading_skeleton.dart';
import 'app_section_header.dart';

class AsyncSection<T> extends StatelessWidget {
  static const int _defaultSkeletonLines = 2;

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final String? title;
  final String? subtitle;
  final Widget? action;
  final VoidCallback? onRetry;
  final int skeletonLines;

  const AsyncSection({
    super.key,
    required this.value,
    required this.builder,
    this.title,
    this.subtitle,
    this.action,
    this.onRetry,
    this.skeletonLines = _defaultSkeletonLines,
  });

  @override
  Widget build(BuildContext context) {
    final isAnimated = !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    final content = value.when(
      data: (data) => KeyedSubtree(key: const ValueKey<String>('data'), child: builder(data)),
      loading: () => LoadingSkeleton(
        key: const ValueKey<String>('loading'),
        lines: skeletonLines,
        isScrollable: false,
      ),
      error: (error, _) => AsyncErrorView(
        key: const ValueKey<String>('error'),
        error: error,
        onRetry: onRetry,
        isCompact: true,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) AppSectionHeader(title: title!, subtitle: subtitle, action: action),
        AnimatedSwitcher(
          duration: isAnimated ? AppMotion.normal : Duration.zero,
          switchInCurve: AppMotion.standard,
          child: content,
        ),
      ],
    );
  }
}
