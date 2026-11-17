import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_colors.dart';
import '../../navigation/main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Stage 1 & 2: Logo Fade-In and Smooth Scale Down (Zoom-Out)
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;

  // Stage 3: SIVANYA Brand Name Reveal (Fade in & upward movement)
  late final Animation<double> _brandNameOpacity;
  late final Animation<Offset> _brandNameSlide;

  // Stage 4: TAILORING Subtitle Reveal
  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _subtitleSlide;

  // Stage 5: Final Graceful Fade Transition out
  late final Animation<double> _finalContentOpacity;

  @override
  void initState() {
    super.initState();

    // Total duration: 6 seconds
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    );

    // Stage 1: Logo Fade-in (0% to 22% of timeline)
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.22, curve: Curves.easeOut),
      ),
    );

    // Stage 2: Logo Scale Down from slightly enlarged (1.35) to elegant resting size (1.0)
    // Runs from 12% to 48% of timeline with luxury ease-in-out curve
    _logoScale = Tween<double>(begin: 1.35, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.12, 0.48, curve: Curves.easeInOutCubic),
      ),
    );

    // Stage 3: "SIVANYA" Brand Name Reveal (42% to 68% of timeline)
    _brandNameOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.42, 0.68, curve: Curves.easeOut),
      ),
    );

    _brandNameSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.42, 0.68, curve: Curves.easeOutCubic),
      ),
    );

    // Stage 4: "TAILORING" Subtitle Reveal (60% to 82% of timeline)
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 0.82, curve: Curves.easeOut),
      ),
    );

    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 0.82, curve: Curves.easeOutCubic),
      ),
    );

    // Stage 5: Exit transition (95% to 100%) - gives over 1 second of holding the final composition!
    _finalContentOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.95, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToHome();
      }
    });

    _controller.forward();
  }

  void _navigateToHome() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainNavigation(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _finalContentOpacity.value,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- STAGE 1 & 2: ORIGINAL BRAND LOGO ---
                    Transform.scale(
                      scale: _logoScale.value,
                      child: Opacity(
                        opacity: _logoOpacity.value,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.secondary.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
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
                    ),

                    const SizedBox(height: 28),

                    // --- STAGE 3: BRAND NAME "SIVANYA" (Cormorant Garamond) ---
                    SlideTransition(
                      position: _brandNameSlide,
                      child: Opacity(
                        opacity: _brandNameOpacity.value,
                        child: Text(
                          'SIVANYA',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 34,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 6.0,
                            color: AppColors.secondary,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // --- STAGE 4: SUBTITLE "TAILORING" (DM Sans) ---
                    SlideTransition(
                      position: _subtitleSlide,
                      child: Opacity(
                        opacity: _subtitleOpacity.value,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 24,
                              height: 1,
                              color: AppColors.secondary.withValues(alpha: 0.5),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                'TAILORING',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 4.5,
                                  color: AppColors.secondary.withValues(alpha: 0.85),
                                ),
                              ),
                            ),
                            Container(
                              width: 24,
                              height: 1,
                              color: AppColors.secondary.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
