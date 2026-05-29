import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;

  void _showStaffLogins() {
    bool isAdminLogin = true;
    bool obscureStaffPass = true;
    final staffIdController = TextEditingController();
    final staffPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceColor,
              title: const Text('Authorized Access Only', style: TextStyle(color: AppTheme.priorityRed, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(color: AppTheme.backgroundLight.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() => isAdminLogin = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isAdminLogin ? AppTheme.accentCyan : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  'Admin', 
                                  style: TextStyle(
                                    color: isAdminLogin ? Colors.black : AppTheme.textLight, 
                                    fontWeight: FontWeight.bold
                                  )
                                )
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() => isAdminLogin = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !isAdminLogin ? AppTheme.accentCyan : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  'Resolver', 
                                  style: TextStyle(
                                    color: !isAdminLogin ? Colors.black : AppTheme.textLight, 
                                    fontWeight: FontWeight.bold
                                  )
                                )
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: staffIdController,
                    style: const TextStyle(color: AppTheme.textDark),
                    decoration: InputDecoration(
                      hintText: isAdminLogin ? 'Admin ID' : 'Resolver Dept ID',
                      hintStyle: const TextStyle(color: AppTheme.textLight),
                      prefixIcon: const Icon(Icons.badge, color: AppTheme.textLight),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: staffPassController,
                    obscureText: obscureStaffPass,
                    style: const TextStyle(color: AppTheme.textDark),
                    decoration: InputDecoration(
                      hintText: 'Passcode',
                      hintStyle: const TextStyle(color: AppTheme.textLight),
                      prefixIcon: const Icon(Icons.lock, color: AppTheme.textLight),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureStaffPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppTheme.textLight,
                          size: 20,
                        ),
                        onPressed: () => setDialogState(() => obscureStaffPass = !obscureStaffPass),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _emailController.text = staffIdController.text;
                      _passwordController.text = staffPassController.text;
                      _submit();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue, 
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('SYSTEM LOGIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter your email');
    }
    if (password.isEmpty) {
      setState(() => _passwordError = 'Please enter your password');
    }
    
    if (email.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      final db = context.read<FirestoreService>();

      if (_isSignUp) {
        final name = _nameController.text.trim();
        final username = _usernameController.text.trim().toLowerCase();

        if (name.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Full name is required')));
          setState(() => _isLoading = false);
          return;
        }
        if (username.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unique username is required')));
          setState(() => _isLoading = false);
          return;
        }
        if (username.length < 3) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username must be at least 3 characters')));
          setState(() => _isLoading = false);
          return;
        }

        // Uniqueness check
        final isUnique = await db.isUsernameUnique(username);
        if (!isUnique) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username already taken. Please try another.')));
          setState(() => _isLoading = false);
          return;
        }

        await authService.signUp(email, password, name, username);
      } else {
        await authService.signIn(email, password);
      }
      
      if (mounted) {
        context.go('/splash?onLogin=true');
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        setState(() {
          if (msg.contains('user-not-found') || msg.contains('invalid-email')) {
             _emailError = 'Identification not recognized';
          } else if (msg.contains('wrong-password') || msg.contains('invalid-credential')) {
             _passwordError = 'Security passcode incorrect';
          } else {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryBlue.withOpacity(0.05),
              Colors.white,
            ],
          )
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Branding
                  Hero(
                    tag: 'logo',
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 120,
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),
                  
                  const SizedBox(height: 12),
                  
                  Text('AuraCity', 
                    style: GoogleFonts.outfit(
                      fontSize: 42, 
                      fontWeight: FontWeight.w900, 
                      letterSpacing: -1,
                      foreground: Paint()..shader = LinearGradient(
                        colors: [AppTheme.primaryBlue, AppTheme.logoRed],
                      ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0))
                    )
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
                  
                  Text('Making Civic Action Effortless', 
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)
                  ).animate().fadeIn(delay: 500.ms),
                  
                  const SizedBox(height: 48),

                  // Auth Card
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _isSignUp ? 'Create Account' : 'Welcome Back',
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 24),
                              ),
                            ),
                            if (!_isSignUp)
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue.withOpacity(0.1),
                                    shape: BoxShape.circle
                                  ),
                                  child: const Icon(Icons.engineering_outlined, color: AppTheme.primaryBlue, size: 20)
                                ),
                                tooltip: 'Staff Terminal',
                                onPressed: _showStaffLogins,
                              )
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (_isSignUp) ...[
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Unique Username',
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                              hintText: 'e.g. citizen_kane',
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: const Icon(Icons.alternate_email),
                            errorText: _emailError,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Security Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            errorText: _passwordError,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppTheme.primaryBlue,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10)
                              )
                            ]
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              minimumSize: const Size.fromHeight(60),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            child: _isLoading 
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                              : Text(_isSignUp ? 'CREATE ACCOUNT' : 'SECURE SIGN IN', style: const TextStyle(letterSpacing: 1)),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () => setState(() => _isSignUp = !_isSignUp),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodyMedium,
                              children: [
                                TextSpan(text: _isSignUp ? 'Already a citizen? ' : "New here? "),
                                TextSpan(
                                  text: _isSignUp ? 'Login' : 'Join AuraCity',
                                  style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)
                                ),
                              ]
                            ),
                          ),
                        )
                      ],
                    ),
                  ).animate().slideY(begin: 0.1, end: 0, duration: 600.ms, curve: Curves.easeOutQuart).fadeIn(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
