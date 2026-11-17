import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class SivanyaLoader extends StatefulWidget {
  final double size;
  final String? message;
  final Color? backgroundColor;

  const SivanyaLoader({
    super.key,
    this.size = 64,
    this.message,
    this.backgroundColor,
  });

  @override
  State<SivanyaLoader> createState() => _SivanyaLoaderState();
}

class _SivanyaLoaderState extends State<SivanyaLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _pulseGlowAnimation;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    // Gentle breathing scale: 0.94 -> 1.06 -> 0.94
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.94, end: 1.06)
            .chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.06, end: 0.94)
            .chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 50,
      ),
    ]).animate(_controller);

    // Glow opacity pulse: 0.25 -> 0.65 -> 0.25
    _pulseGlowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.25, end: 0.65)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.65, end: 0.25)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    // Subtle slow needle-thread orbit
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loaderCore = Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Delicate rotating sewing-thread accent ring
                  Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Container(
                      width: widget.size + 18,
                      height: widget.size + 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.peachAccent.withValues(
                            alpha: _pulseGlowAnimation.value * 0.7,
                          ),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  // 2. Subtle peach pulse glow backdrop
                  Container(
                    width: widget.size + 6,
                    height: widget.size + 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.peachAccent.withValues(
                            alpha: _pulseGlowAnimation.value * 0.5,
                          ),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),

                  // 3. Original Brand Logo with breathing scale
                  Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/brand/sivanya_logo.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.message != null && widget.message!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  widget.message!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                    color: AppColors.textMuted.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );

    if (widget.backgroundColor != null) {
      return Container(
        color: widget.backgroundColor,
        child: loaderCore,
      );
    }

    return loaderCore;
  }
}
