import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  void _navigateToLogin() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D47A1),
              Color(0xFF1976D2),
              Color(0xFF00B0FF),
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Floating background elements
            Positioned(
              top: -50,
              left: -50,
              child: _buildBlurCircle(Colors.white10),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveY(begin: 0, end: 50, duration: 3.seconds, curve: Curves.easeInOut),
            
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo using asset image
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'lib/assets/image/lg.webp',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ).animate()
                 .scale(duration: 800.ms, curve: Curves.easeOutBack)
                 .shimmer(delay: 1.seconds, duration: 1500.ms),
                
                const SizedBox(height: 40),
                
                // Portal Name
                Text(
                  'ULGDSP',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
                
                Text(
                  'Unified Local Government Platform',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 1.5,
                  ),
                ).animate().fadeIn(delay: 800.ms),
                
                const SizedBox(height: 80),
                
                // Modern Loading Indicator
                SizedBox(
                  width: 200,
                  height: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ).animate().fadeIn(delay: 1200.ms).scaleX(begin: 0),
                
                const SizedBox(height: 16),
                
                Text(
                  'SECURE INITIALIZATION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white54,
                    letterSpacing: 2,
                  ),
                ).animate().fadeIn(delay: 1500.ms),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlurCircle(Color color) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
