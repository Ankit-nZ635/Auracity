import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';
import 'package:go_router/go_router.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();

  static String? _getHighestLevelBadge(List<String> badges) {
    var levels = badges.where((b) => RegExp(r'^L[1-6]$').hasMatch(b)).toList();
    if (levels.isEmpty) return null;
    levels.sort((a, b) => b.compareTo(a)); // Sort descending: L6, L5...
    return levels.first;
  }
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _showResolvers = false;

  @override
  Widget build(BuildContext context) {
    final db = context.watch<FirestoreService>();
    final auth = context.watch<AuthService>();
    final isAdmin = auth.isAdmin;
    final isResolver = auth.isResolver;

    bool displayResolvers = _showResolvers;
    if (!isAdmin) {
      displayResolvers = isResolver;
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Stack(
        children: [
          // Mesh Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.backgroundLight,
                  AppTheme.primaryBlue.withOpacity(0.05),
                  AppTheme.accentCyan.withOpacity(0.02),
                ],
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 32),
                  child: Column(
                    children: [
                      Text(displayResolvers ? 'HONOR ROLL' : 'LEADERBOARD', 
                        style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 4, color: AppTheme.primaryBlue)
                      ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                      const SizedBox(height: 8),
                      Text(displayResolvers ? 'Top Resolvers' : 'Active Citizens', 
                        style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textDark)
                      ),
                      const SizedBox(height: 32),
                      if (isAdmin) _buildTabSwitcher(),
                    ],
                  ),
                ),
              ),
              StreamBuilder<List<UserModel>>(
                stream: displayResolvers ? db.getTopResolvers() : db.getTopUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(child: Center(child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    )));
                  }
                  final users = snapshot.data ?? [];
                  if (users.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: Text('Finding the heroes of AuraCity...', style: TextStyle(color: AppTheme.textLight))
                      )
                    );
                  }

                  final top3 = users.take(3).toList();
                  final theRest = users.skip(3).toList();

                  return SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: PodiumView(top3: top3, isResolvers: displayResolvers),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final user = theRest[index];
                              final actualRank = index + 4;
                              return _buildLeaderboardTile(user, actualRank, displayResolvers);
                            },
                            childCount: theRest.length,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/profile/badges'),
        backgroundColor: Colors.white,
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 28),
      ).animate().scale(delay: 500.ms, duration: 400.ms, curve: Curves.easeOutBack),
      floatingActionButtonLocation: const _CustomFabLocation(),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          _buildTabItem(0, 'Citizens', Icons.person_search_rounded),
          _buildTabItem(1, 'Resolvers', Icons.build_circle_rounded),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    bool selected = (index == 0 && !_showResolvers) || (index == 1 && _showResolvers);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _showResolvers = index == 1),
        child: AnimatedContainer(
          duration: 300.ms,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? Colors.white : AppTheme.textLight, size: 18),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: selected ? Colors.white : AppTheme.textLight, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardTile(UserModel user, int rank, bool displayResolvers) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: AppTheme.backgroundLight, borderRadius: BorderRadius.circular(12)),
          child: Center(
            child: Text('#$rank', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppTheme.textLight, fontSize: 14)),
          ),
        ),
        title: Text(user.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Row(
          children: user.badges.take(3).map((b) {
             bool isLevel = b.startsWith('L') && b.length <= 2;
             return Padding(
               padding: const EdgeInsets.only(right: 4, top: 4),
               child: isLevel 
                ? Image.asset('assets/badges/$b.png', height: 18, errorBuilder: (c,e,s) => const Icon(Icons.stars, size: 14, color: Colors.amber))
                : const Icon(Icons.verified, size: 12, color: AppTheme.primaryBlue),
             );
          }).toList(),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Text('${user.points} pts', style: GoogleFonts.outfit(color: AppTheme.primaryBlue, fontWeight: FontWeight.w900, fontSize: 14)),
        ),
      ),
    ).animate().fadeIn(delay: (rank * 30).ms).slideX(begin: 0.1, end: 0);
  }
}

class PodiumView extends StatelessWidget {
  final List<UserModel> top3;
  final bool isResolvers;
  const PodiumView({super.key, required this.top3, required this.isResolvers});

  @override
  Widget build(BuildContext context) {
    if (top3.isEmpty) return const SizedBox();
    
    // Layout indices for Podium: [1st, 2nd, 3rd] -> UI mapping: [2nd, 1st, 3rd]
    List<UserModel?> ordered = [
       top3.length > 1 ? top3[1] : null,
       top3[0],
       top3.length > 2 ? top3[2] : null,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (index) {
          final user = ordered[index];
          if (user == null) return const Expanded(child: SizedBox());
          
          bool isFirst = index == 1;
          double height = isFirst ? 180 : 140;
          Color accentColor = isFirst ? const Color(0xFFFFD700) : (index == 0 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));

          return Expanded(
            child: Column(
              children: [
                if (isFirst) Icon(Icons.workspace_premium, color: accentColor, size: 32).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(12),
                  height: height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, AppTheme.backgroundLight],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                       BoxShadow(color: accentColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                    ],
                    border: Border.all(color: accentColor.withOpacity(0.5), width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       CircleAvatar(
                         radius: isFirst ? 28 : 22,
                         backgroundColor: accentColor.withOpacity(0.1),
                         child: LeaderboardScreen._getHighestLevelBadge(user.badges) != null
                          ? Image.asset('assets/badges/${LeaderboardScreen._getHighestLevelBadge(user.badges)}.png', height: isFirst ? 40 : 30, errorBuilder: (c,e,s) => Text(user.name[0], style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)))
                          : Text(user.name[0], style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                       ),
                       const SizedBox(height: 8),
                       Text(user.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
                       const SizedBox(height: 2),
                       Text('${user.points} pts', style: GoogleFonts.outfit(color: AppTheme.primaryBlue, fontWeight: FontWeight.w900, fontSize: 11)),
                    ],
                  ),
                ).animate().slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOutBack),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _CustomFabLocation extends FloatingActionButtonLocation {
  const _CustomFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Standard endFloat position
    final double x = scaffoldGeometry.scaffoldSize.width - 
                    scaffoldGeometry.floatingActionButtonSize.width - 20;
    // Offset by roughly the Navbar height (75) + Bottom Margin (24) + spacing
    final double y = scaffoldGeometry.scaffoldSize.height - 
                    scaffoldGeometry.floatingActionButtonSize.height - 110;
    return Offset(x, y);
  }
}
