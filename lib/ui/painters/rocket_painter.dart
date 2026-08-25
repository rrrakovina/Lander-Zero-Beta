import 'dart:math';
import 'package:flutter/material.dart';
import 'ship_mesh_renderer.dart';

/// Flutter [CustomPainter] wrapping [ShipMeshRenderer] for menus, garage, map select, and HUD previews.
class RocketPainter extends CustomPainter {
  final String rocketId;
  final double animationTime;
  final Color? glowColor;
  final bool isSelected;

  /// Exact model bounding boxes enclosing hull, landing gear/skis/feet, nozzles, and antenna tips.
  static const Map<String, Rect> modelBounds = ShipMeshRenderer.modelBounds;

  /// Safety margin ensuring hover/tilt dynamics, strokes, and glows fit comfortably without clipping.
  static const double safetyMargin = ShipMeshRenderer.safetyMargin;

  static Rect getBounds(String id) => ShipMeshRenderer.getModelBounds(id);
  static Offset getCenterOffset(String id) => ShipMeshRenderer.getCenterOffset(id);
  static double calculateScale(String id, Size size, {double margin = safetyMargin}) =>
      ShipMeshRenderer.calculateScale(id, size, margin: margin);

  RocketPainter({
    required this.rocketId,
    this.animationTime = 0.0,
    this.glowColor,
    this.isSelected = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final bounds = getBounds(rocketId);
    final double centerX = bounds.center.dx;
    final double centerY = bounds.center.dy;
    final double maxDimension = max(bounds.width, bounds.height);

    final double scale = min(size.width, size.height) / (maxDimension * safetyMargin);

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);

    if (animationTime > 0) {
      canvas.translate(0, sin(animationTime) * 0.04 * scale);
    }

    canvas.scale(scale, scale);
    // Center the actual model's visual bounding box
    canvas.translate(-centerX, -centerY);

    if (glowColor != null) {
      final Paint glowPaint = Paint()
        ..color = glowColor!.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.4);
      canvas.drawOval(bounds.inflate(0.15), glowPaint);
    }

    ShipMeshRenderer.renderShip(
      canvas: canvas,
      shipId: rocketId,
      scale: 1.0,
      engineThrust: 0.0,
      rcsThrust: 0.0,
      pilotHeadOffset: null,
      pilotLookDirection: null,
      pilotGStrain: 0.0,
      isPanicking: false,
      isBlinking: false,
      showLandingGear: true,
      animationTime: animationTime,
      legsCompression: 0.0,
      showDecals: true,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RocketPainter oldDelegate) {
    return oldDelegate.rocketId != rocketId ||
        oldDelegate.animationTime != animationTime ||
        oldDelegate.glowColor != glowColor ||
        oldDelegate.isSelected != isSelected;
  }
}
