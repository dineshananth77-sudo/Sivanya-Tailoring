import 'package:flutter/material.dart';

/// Luxury fashion page route with a smooth fade, subtle upward slide, and gentle scale transition.
/// Designed for Sivanya Tailoring to deliver a boutique feel.
class LuxuryPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  LuxuryPageRoute({
    required this.page,
    super.settings,
    Duration duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Smooth custom luxury curve
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            // Subtle fade transition
            final fade = FadeTransition(
              opacity: curvedAnimation,
              child: child,
            );

            // Subtle micro-slide from bottom (only 4% offset)
            final slide = SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.04),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: fade,
            );

            // Micro-scale (from 0.985 to 1.0)
            return ScaleTransition(
              scale: Tween<double>(begin: 0.985, end: 1.0).animate(curvedAnimation),
              child: slide,
            );
          },
        );
}
