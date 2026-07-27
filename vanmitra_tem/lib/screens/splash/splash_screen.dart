import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_router.dart';
import '../../providers/auth_provider.dart';

/// Splash Screen — Maharashtra emblem + VanMitra-AI branding
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _scaleUp = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)),
    );
    _controller.forward();

    // Check auth and navigate after delay
    Future.delayed(const Duration(seconds: 3), () {
      _navigate();
    });
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    await ref.read(authProvider.notifier).checkAuth();
    final auth = ref.read(authProvider);

    if (!mounted) return;
    if (auth.isAuthenticated && auth.currentUser != null) {
      final route = auth.currentUser!.role.name == 'admin'
          ? AppRouter.adminHome
          : AppRouter.villagerHome;
      Navigator.pushReplacementNamed(context, route);
    } else {
      Navigator.pushReplacementNamed(context, AppRouter.languageSelection);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              Color(0xFF0F2444),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeIn,
          child: ScaleTransition(
            scale: _scaleUp,
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Maharashtra Ashoka emblem placeholder
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                  border: Border.all(color: AppColors.secondary, width: 3),
                ),
                child: const Icon(
                  Icons.account_balance,
                  size: 48,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 24),

              // App name in Devanagari
              const Text(
                'वनमित्र',
                style: TextStyle(
                  fontFamily: 'NotoSansDevanagari',
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),

              // English subtitle
              Text(
                'VanMitra-AI',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 16),

              // Divider line
              Container(
                width: 60,
                height: 2,
                color: AppColors.secondary,
              ),
              const SizedBox(height: 16),

              // Tagline
              Text(
                'ग्रामसभा पारदर्शकता प्रणाली',
                style: TextStyle(
                  fontFamily: 'NotoSansDevanagari',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Gram Sabha Transparency System',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.5),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 48),

              // Loading indicator
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.secondary.withOpacity(0.6),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
