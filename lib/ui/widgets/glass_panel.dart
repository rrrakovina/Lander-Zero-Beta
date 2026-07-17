import 'dart:ui';
import 'package:flutter/material.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final double borderRadius;
  final double padding;
  final Color bgColor;

  const GlassPanel({
    super.key,
    required this.child,
    this.borderColor = Colors.white10,
    this.borderRadius = 16.0,
    this.padding = 20.0,
    this.bgColor = const Color(0xCC0C0C12), // Слегка темнее для лучшего контраста текста
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0), // Более глубокое размытие для премиального стекла
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor.withOpacity(0.35), // Тонкая интерактивная рамка
              width: 1.5,
            ),
            boxShadow: [
              // Многослойные неоновые тени
              BoxShadow(
                color: borderColor.withOpacity(0.08),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
