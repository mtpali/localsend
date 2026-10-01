import 'package:flutter/material.dart';
import 'package:localsend_app/widget/static_controls.dart';

class CustomProgressBar extends StatelessWidget {
  final double? progress;
  final double borderRadius;
  final Color? color;
  const CustomProgressBar({required this.progress, this.borderRadius = 10, this.color});
  @override
  Widget build(BuildContext context) {
    if (progress == null) return const StaticBusyIndicator();
    final value = progress!.clamp(0.0, 1.0);
    return Semantics(
      value: '${(value * 100).round()}%',
      child: Container(
        height: 10,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value,
            heightFactor: 1,
            child: const ColoredBox(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
