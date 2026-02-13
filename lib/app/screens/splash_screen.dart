import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    if (authProvider.isLoggedIn) {
      context.go('/dashboard');
    } else if (authProvider.hasSeenOnboarding) {
      context.go('/login');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E7F5C),
              Color(0xFF4ECDC4),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),

              // Logo with animation
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.home,
                      size: 48,
                      color: Color(0xFF1E7F5C),
                    ),
                  )
                      .animate()
                      .scale(duration: 500.ms, begin: const Offset(0.5, 0.5))
                      .fadeIn(),
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFC857),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.wifi,
                        size: 16,
                        color: Colors.white,
                      ),
                    )
                        .animate()
                        .rotate(duration: 2000.ms)
                        .scale(duration: 500.ms, begin: const Offset(0.5, 0.5)),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // App name
              const Text(
                'SmartHome',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              )
                  .animate()
                  .slideY(begin: 0.2, end: 0, duration: 300.ms, delay: 300.ms)
                  .fadeIn(delay: 300.ms),

              const SizedBox(height: 8),

              // Tagline
              const Text(
                'Smart Control. Safe Living.',
                style: TextStyle(
                  color: Color(0xCCFFFFFF),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .slideY(begin: 0.2, end: 0, duration: 300.ms, delay: 500.ms)
                  .fadeIn(delay: 500.ms),

              const SizedBox(height: 48),

              // Loading indicator
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8),
                  ),
                ).animate().scale(
                    duration: 1500.ms,
                    begin: const Offset(1, 1),
                    end: const Offset(1.2, 1.2)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
