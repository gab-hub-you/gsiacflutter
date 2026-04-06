import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'citizen_validation_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_card.dart';
import '../models/citizen.dart';
import 'register_screen.dart';
import '../widgets/error_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _emailController.text,
        _passwordController.text,
      );

      if (success) {
        if (mounted) {
          final user = authProvider.user;
          if (user?.verificationStatus == VerificationStatus.unverified) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const CitizenValidationScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          }
        }
      } else {
        if (mounted) {
          final error = authProvider.errorMessage ?? 'Invalid email or password';
          
          if (error == "No Internet Connection") {
            ErrorDialog.show(
              context,
              title: "No Internet Connection",
              message: "Please check your connectivity and try again.",
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Animated Gradient Background
          // Background Image
Positioned.fill(
  child: Image.asset(
    'lib/assets/image/bg.webp',
    fit: BoxFit.cover,
    alignment: Alignment.topCenter,
  ),
),

// Dark overlay
Positioned.fill(
  child: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withValues(alpha: 0.45),
          Colors.black.withValues(alpha: 0.25),
        ],
      ),
    ),
  ),
),

          // Decorative Circles
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: GlassCard(
                  opacity: 0.15,
                  blur: 20,
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo Section
                          Container(
  padding: const EdgeInsets.all(4),
  decoration: BoxDecoration(
    color: Colors.white.withValues(alpha: 0.9),
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 20,
        spreadRadius: 5,
      ),
    ],
  ),
  child: ClipOval(
    child: Image.asset(
      'lib/assets/image/lg.webp',
      width: 82,
      height: 82,
      fit: BoxFit.cover,
    ),
  ),
).animate().scale(delay: 200.ms, duration: 500.ms, curve: Curves.easeOutBack),
                          
                          const SizedBox(height: 24),
                          
                          Text(
                            'ULGDSP',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  offset: const Offset(0, 4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                          
                          Text(
                            'Citizen Digital Portal',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                              letterSpacing: 2,
                            ),
                          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
                          
                          const SizedBox(height: 48),

                          // Text Fields
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email Address',
                            icon: Icons.alternate_email_rounded,
                          ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1),
                          
                          const SizedBox(height: 20),
                          
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_outline_rounded,
                            isPassword: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.white70,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.1),
                          
                          const SizedBox(height: 32),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: context.watch<AuthProvider>().isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF0D47A1),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: context.watch<AuthProvider>().isLoading
                                  ? const CircularProgressIndicator(color: Color(0xFF0D47A1))
                                  : const Text(
                                      'Login to Portal',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ).animate().fadeIn(delay: 800.ms).scale(),
                          
                          const SizedBox(height: 24),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account?",
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                                ),
                                child: const Text(
                                  'Register',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 1000.ms),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Footer
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                '© 2026 Unified Local Government Platform',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 1200.ms),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorStyle: const TextStyle(color: Colors.orangeAccent),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'Field cannot be empty' : null,
    );
  }
}
