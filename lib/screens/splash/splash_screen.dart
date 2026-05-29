import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  final bool isLoginTransition;
  
  const SplashScreen({super.key, this.isLoginTransition = false});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() async {
    // Show splash for 2-3 seconds for maximum visual impact as requested
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (mounted) {
      if (widget.isLoginTransition) {
        // If it's a login transition, navigate to the dashboard
        context.go('/');
      } else {
        // If it's initial boot, check auth state
        final auth = context.read<AuthService>();
        if (auth.isAuthenticated) {
          context.go('/');
        } else {
          context.go('/auth');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryBlue.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with scale and fade animation
            Hero(
              tag: 'logo',
              child: Image.asset(
                'assets/images/logo.png',
                height: 140,
              ),
            ).animate()
              .scale(duration: 800.ms, curve: Curves.easeOutBack)
              .fadeIn(duration: 600.ms),
            
            const SizedBox(height: 24),
            
            // App Name with specialized shader
            Text(
              'AuraCity', 
              style: GoogleFonts.outfit(
                fontSize: 48, 
                fontWeight: FontWeight.w900, 
                letterSpacing: -1,
                foreground: Paint()..shader = LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.logoRed],
                ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0))
              )
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 8),
            
            // Subtitle
            Text(
              widget.isLoginTransition ? 'AUTHENTICATING SECURELY...' : 'PREPARING YOUR CITY...',
              style: GoogleFonts.inter(
                color: AppTheme.textLight, 
                fontWeight: FontWeight.w900, 
                fontSize: 12, 
                letterSpacing: 2
              )
            ).animate().fadeIn(delay: 600.ms),
            
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
