import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.borderRadius = 20,
    this.elevated = false,
    this.animate = true,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final double borderRadius;
  final bool elevated;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final content = Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: radius,
        border: Border.all(color: AppColors.border.withValues(alpha: .88)),
      ),
      child: Padding(padding: padding, child: child),
    );
    final interactive = onTap == null
        ? content
        : Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              child: content,
            ),
          );
    if (!animate) return interactive;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
      child: interactive,
    );
  }
}
