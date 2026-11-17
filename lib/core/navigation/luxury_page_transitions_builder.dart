import 'package:flutter/material.dart';

class LuxuryPageTransitionsBuilder extends PageTransitionsBuilder {
  const LuxuryPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final fade = FadeTransition(
      opacity: curvedAnimation,
      child: child,
    );

    final slide = SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 0.04),
        end: Offset.zero,
      ).animate(curvedAnimation),
      child: fade,
    );

    return ScaleTransition(
      scale: Tween<double>(begin: 0.985, end: 1.0).animate(curvedAnimation),
      child: slide,
    );
  }
}
