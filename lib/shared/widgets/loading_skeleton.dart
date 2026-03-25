import 'package:flutter/material.dart';

class LoadingSkeleton extends StatelessWidget {
  final int lines;

  const LoadingSkeleton({super.key, this.lines = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: lines,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) => Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
