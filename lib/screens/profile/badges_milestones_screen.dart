import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../theme.dart';
import 'package:go_router/go_router.dart';

class BadgesMilestonesScreen extends StatelessWidget {
  const BadgesMilestonesScreen({super.key});

  static const List<Map<String, dynamic>> badgeMilestones = [
    {'level': 'L1', 'label': 'Bronze Citizen', 'points': 10, 'desc': 'Recognized for your first contributions.'},
    {'level': 'L2', 'label': 'Silver Citizen', 'points': 50, 'desc': 'A reliable member of the AuraCity community.'},
    {'level': 'L3', 'label': 'Gold Citizen', 'points': 100, 'desc': 'An active contributor making a real difference.'},
    {'level': 'L4', 'label': 'Platinum Citizen', 'points': 250, 'desc': 'Respected for consistent and high-quality impact.'},
    {'level': 'L5', 'label': 'Diamond Citizen', 'points': 500, 'desc': 'A pillar of AuraCity, known by all.'},
    {'level': 'L6', 'label': 'City Hero', 'points': 1000, 'desc': 'The ultimate honor. You are the heart of AuraCity.'},
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final db = context.read<FirestoreService>();
    final userId = auth.currentUserId;

    return StreamBuilder<UserModel?>(
      stream: userId != null ? db.getUserProfile(userId) : Stream.value(null),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final points = user?.points ?? 0;

        // Calculate next milestone
        Map<String, dynamic>? nextMilestone;
        for (var m in badgeMilestones) {
          if (points < m['points']) {
            nextMilestone = m;
            break;
          }
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDark),
              onPressed: () => context.pop(),
            ),
            title: Text('Badges & Honors', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          ),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Next Milestone Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildProgressCard(points, nextMilestone),
                ),
              ),

              // Hero Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LEVELING UP', 
                        style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2, color: AppTheme.primaryBlue)
                      ),
                      const SizedBox(height: 8),
                      Text('Rank Thresholds', 
                        style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)
                      ),
                      const SizedBox(height: 4),
                      Text('Earn points by reporting issues, verification tasks, and community engagement.',
                        style: TextStyle(color: AppTheme.textLight, fontSize: 13, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),

              // Badges Grid/List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final m = badgeMilestones[index];
                      final isUnlocked = points >= m['points'];
                      return _buildBadgeTile(m, isUnlocked);
                    },
                    childCount: badgeMilestones.length,
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 60)),
            ],
          ),
        );
      }
    );
  }

  Widget _buildProgressCard(int currentPoints, Map<String, dynamic>? next) {
    double progress = 1.0;
    int pointsNeeded = 0;
    if (next != null) {
      // Find previous milestone points
      int prevPoints = 0;
      int nextIndex = badgeMilestones.indexOf(next);
      if (nextIndex > 0) {
        prevPoints = badgeMilestones[nextIndex - 1]['points'];
      }
      
      int totalNeeded = next['points'] - prevPoints;
      int currentInTier = currentPoints - prevPoints;
      progress = (currentInTier / totalNeeded).clamp(0.0, 1.0);
      pointsNeeded = next['points'] - currentPoints;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.accentCyan],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('YOUR SCORE', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text('$currentPoints PTS', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (next != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Next: ${next['label']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text('$pointsNeeded pts left', style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ] else ...[
             const Text('MAX LEVEL REACHED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
             const SizedBox(height: 4),
             const Text('You are a True Hero of AuraCity.', style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ],
      ),
    ).animate().fadeIn().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildBadgeTile(Map<String, dynamic> milestone, bool isUnlocked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isUnlocked ? AppTheme.primaryBlue.withOpacity(0.2) : Colors.transparent, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: isUnlocked ? AppTheme.primaryBlue.withOpacity(0.05) : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
              ),
              Image.asset(
                'assets/badges/${milestone['level']}.png',
                height: 40, width: 40,
                color: isUnlocked ? null : Colors.black.withOpacity(0.3),
                errorBuilder: (c, e, s) => Icon(Icons.stars_rounded, color: isUnlocked ? AppTheme.priorityYellow : Colors.grey[300], size: 30),
              ),
              if (!isUnlocked)
                 Icon(Icons.lock_rounded, size: 14, color: Colors.black.withOpacity(0.3)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(milestone['label'], style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: isUnlocked ? AppTheme.textDark : AppTheme.textLight)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUnlocked ? AppTheme.primaryBlue.withOpacity(0.1) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${milestone['points']} pts', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 10, color: isUnlocked ? AppTheme.primaryBlue : AppTheme.textLight)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(milestone['desc'], style: TextStyle(color: AppTheme.textLight, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (badgeMilestones.indexOf(milestone) * 50).ms).slideX(begin: 0.1, end: 0);
  }
}
