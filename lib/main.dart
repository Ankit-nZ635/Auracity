import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'services/firestore_service.dart';
import 'services/auth_service.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/map_screen.dart';
import 'screens/report/report_issue_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/resolver/resolver_dashboard.dart';
import 'screens/profile/profile_screen.dart';
import 'dart:ui';
import 'screens/profile/leaderboard_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/badges_milestones_screen.dart';
import 'screens/support/chat_screen.dart';
import 'models/user_model.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase not initialized yet. Skipping... ${e}");
  }
  
  await Supabase.initialize(
    url: 'https://lhioonsszljukhynoabf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxoaW9vbnNzemxqdWtoeW5vYWJmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU5ODk0NzAsImV4cCI6MjA5MTU2NTQ3MH0.LDweTGUd5QljrEayI85dxdmRg_ox87PQdXX7SWTuRnI',
  );

  // Create AuthService singleton instance early for GoRouter
  final authService = AuthService();

  final GoRouter router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: authService,
    redirect: (context, state) {
      final isAuth = authService.isAuthenticated;
      final isAuthRoute = state.uri.path == '/auth';
      final isSplashRoute = state.uri.path == '/splash';

      if (isSplashRoute) return null; // Let the splash screen handle navigation

      if (!isAuth && !isAuthRoute) return '/auth';
      if (isAuth && isAuthRoute) return '/';
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) {
          final isLogin = state.uri.queryParameters['onLogin'] == 'true';
          return SplashScreen(isLoginTransition: isLogin);
        },
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const AppNavigationScaffold(),
      ),
      GoRoute(
        path: '/report',
        builder: (context, state) {
          final loc = state.extra as Map<String, double>?;
          return ReportIssueScreen(
            latitude: loc?['lat'] ?? 0.0,
            longitude: loc?['lng'] ?? 0.0,
          );
        },
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) {
          final user = state.extra as UserModel;
          return EditProfileScreen(user: user);
        },
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: '/profile/badges',
        builder: (context, state) => const BadgesMilestonesScreen(),
      ),
    ],
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
      ],
      child: AuraCityApp(router: router),
    ),
  );
}

class AuraCityApp extends StatelessWidget {
  final GoRouter router;
  
  const AuraCityApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AuraCity',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppNavigationScaffold extends StatefulWidget {
  const AppNavigationScaffold({super.key});

  @override
  State<AppNavigationScaffold> createState() => _AppNavigationScaffoldState();
}

class _AppNavigationScaffoldState extends State<AppNavigationScaffold> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isAdmin = auth.isAdmin;
    final isResolver = auth.isResolver;

    final List<Widget> pages = [
      const MapScreen(),
      const ProfileScreen(),
      const LeaderboardScreen(),
      if (isAdmin) const AdminDashboard(),
      if (isResolver) const ResolverDashboard(),
    ];

    final List<Map<String, dynamic>> items = [
      {'icon': Icons.explore_outlined, 'active': Icons.explore, 'label': 'Explore'},
      {'icon': Icons.person_outline, 'active': Icons.person, 'label': 'Profile'},
      {'icon': Icons.military_tech_outlined, 'active': Icons.military_tech, 'label': 'Honors'},
      if (isAdmin) {'icon': Icons.admin_panel_settings_outlined, 'active': Icons.admin_panel_settings, 'label': 'Admin'},
      if (isResolver) {'icon': Icons.engineering_outlined, 'active': Icons.engineering, 'label': 'Tasks'},
    ];

    if (_currentIndex >= pages.length) {
      _currentIndex = 0; 
    }

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(bottom: 24, left: 20, right: 20),
        height: 75,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Premium High-fidelity Active Indicator
              if (items.isNotEmpty)
                AnimatedAlign(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutQuart,
                  alignment: Alignment(
                    -1.0 + (_currentIndex * (2.0 / (items.length - 1))),
                    0.0, // Centered vertically
                  ),
                  child: FractionallySizedBox(
                    widthFactor: 1 / items.length,
                    child: Center(
                      child: Container(
                        width: 90,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(40), // More rounded than navbar (32)
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.12),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (index) {
                  bool isSelected = _currentIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentIndex = index),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSelected ? items[index]['active'] : items[index]['icon'],
                            color: isSelected ? AppTheme.primaryBlue : AppTheme.textDark.withOpacity(0.4),
                            size: 28,
                          ).animate(target: isSelected ? 1 : 0)
                           .scale(begin: const Offset(1,1), end: const Offset(1.15, 1.15), duration: 250.ms, curve: Curves.easeOutBack),
                          
                          const SizedBox(height: 4),
                          if (isSelected)
                            Text(
                              items[index]['label'],
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryBlue,
                                letterSpacing: 0.5,
                              ),
                            ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.2, end: 0),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
}
}
