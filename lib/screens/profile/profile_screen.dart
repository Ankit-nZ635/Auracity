import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/issue_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';
import '../../services/local_image_service.dart';
import '../../models/transaction_model.dart';
import '../../widgets/issue_image.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final db = context.read<FirestoreService>();
    final userId = authService.currentUserId;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text("Access Denied")));
    }

    return StreamBuilder<UserModel?>(
      stream: db.getUserProfile(userId),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final user = userSnapshot.data;
        if (user == null) {
          return const Scaffold(body: Center(child: Text("Portal unreachable")));
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  clipBehavior: ui.Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Base Gradient
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                      // Mesh Points (reusing positioning)
                      Positioned(
                        top: -100,
                        right: -50,
                        child: Container(
                          width: 300, height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [AppTheme.accentCyan.withOpacity(0.4), AppTheme.accentCyan.withOpacity(0.0)],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -50,
                        left: -50,
                        child: Container(
                          width: 250, height: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [AppTheme.logoGreen.withOpacity(0.3), AppTheme.logoGreen.withOpacity(0.0)],
                            ),
                          ),
                        ),
                      ),
                       // Noise Texture removed due to external host issues
                      // Floating Actions
                      Positioned(
                        top: 40,
                        right: 16,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
                              onPressed: () => context.push('/profile/edit', extra: user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 24),
                              onPressed: () => context.read<AuthService>().signOut(),
                            ),
                          ],
                        ),
                      ),
                      // Content Column
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 85, 24, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row: Avatar + Name
                            Row(
                              children: [
                                // Mini Premium Halo Avatar
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 80, height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                                        boxShadow: [
                                          BoxShadow(color: AppTheme.accentCyan.withOpacity(0.2), blurRadius: 20, spreadRadius: 2)
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 72, height: 72,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.1)],
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: Container(
                                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                                        child: CircleAvatar(
                                          radius: 34,
                                          backgroundColor: AppTheme.backgroundLight.withOpacity(0.8),
                                          backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                                            ? NetworkImage(user.photoUrl!) : null,
                                          child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                                            ? Icon(user.role == 'admin' ? Icons.admin_panel_settings_rounded : Icons.person_rounded, size: 34, color: AppTheme.primaryBlue)
                                            : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name.toUpperCase(),
                                        style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                                      ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.2, end: 0),
                                      if (user.username != null)
                                        Text(
                                          '@${user.username}',
                                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.7), letterSpacing: 0.5),
                                        ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.2, end: 0),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        margin: const EdgeInsets.only(top: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                                        ),
                                        child: Text(
                                          user.role == 'admin' ? 'CITY ADMIN' : 'ELITE CITIZEN',
                                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 8, letterSpacing: 1.5),
                                        ),
                                      ).animate().fadeIn(delay: 400.ms),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (user.bio != null && user.bio!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Text(
                                  user.bio!,
                                  style: GoogleFonts.outfit(fontSize: 14, height: 1.5, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ).animate().fadeIn(delay: 500.ms),
                            Wrap(
                              spacing: 16, runSpacing: 10,
                              children: [
                                if (user.occupation != null) _buildCompactDetail(Icons.work_rounded, user.occupation!),
                                if (user.location != null) _buildCompactDetail(Icons.location_on_rounded, user.location!),
                                if (user.phoneNumber != null) _buildCompactDetail(Icons.phone_rounded, user.phoneNumber!),
                                _buildCompactDetail(Icons.email_rounded, user.email),
                              ],
                            ).animate().fadeIn(delay: 600.ms),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
                      SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Glassmorphism Stats Dashboard
                      ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryBlue.withOpacity(0.1), 
                                  blurRadius: 30, 
                                  offset: const Offset(0, 15)
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                if (user.role == 'admin') ...[
                                  _buildStatItem('₹${(user.budget / 1000).toStringAsFixed(1)}K', 'TREASURY', Icons.account_balance_rounded, AppTheme.primaryBlue),
                                  Container(width: 1, height: 40, color: AppTheme.textLight.withOpacity(0.2)),
                                  _buildStatItem('${user.resolvedCount}', 'TOTAL FIXES', Icons.auto_graph_rounded, AppTheme.priorityGreen),
                                ] else if (user.role == 'resolver') ...[
                                  _buildStatItem('₹${user.walletBalance.toStringAsFixed(0)}', 'WALLET', Icons.account_balance_wallet_rounded, AppTheme.priorityGreen),
                                  Container(width: 1, height: 40, color: AppTheme.textLight.withOpacity(0.2)),
                                  _buildStatItem(
                                    user.totalRatings > 0 
                                      ? '${((user.totalRatingValue / (user.totalRatings * 5)) * 100).toStringAsFixed(0)}%' 
                                      : '100%', 
                                    'TRUST', 
                                    Icons.verified_user_rounded, 
                                    AppTheme.primaryBlue
                                  ),
                                ] else ...[
                                  _buildStatItem('${user.points}', 'POINTS', Icons.bolt_rounded, AppTheme.priorityYellow),
                                  Container(width: 1, height: 40, color: AppTheme.textLight.withOpacity(0.2)),
                                  _buildStatItem('${user.resolvedCount}', 'FIXED', Icons.check_circle_rounded, AppTheme.priorityGreen),
                                ],
                                Container(width: 1, height: 40, color: AppTheme.textLight.withOpacity(0.2)),
                                _buildStatItem(user.role == 'admin' ? 'Active' : '${user.badges.length}', user.role == 'admin' ? 'SYSTEM' : 'BADGES', user.role == 'admin' ? Icons.verified_user_rounded : Icons.military_tech_rounded, AppTheme.primaryBlue),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 32),

                       if (user.role != 'admin') ...[
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionHeader(user.role == 'resolver' ? 'Credibility & Achievements' : 'Achievements'),
                            const Text('VIEW ALL', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 120,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              if (user.role == 'resolver')
                                Container(
                                  margin: const EdgeInsets.only(right: 16),
                                  width: 160,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [AppTheme.primaryBlue, AppTheme.accentCyan],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryBlue.withOpacity(0.3), 
                                        blurRadius: 15, 
                                        offset: const Offset(0, 8)
                                      )
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.stars_rounded, color: Colors.white, size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              'EXPERT RATING',
                                              style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5, color: Colors.white.withOpacity(0.8)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          user.totalRatings > 0 
                                            ? (user.totalRatingValue / user.totalRatings).toStringAsFixed(1) 
                                            : '5.0',
                                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
                                        ),
                                        Row(
                                          children: List.generate(5, (star) {
                                            double avg = user.totalRatings > 0 ? (user.totalRatingValue / user.totalRatings) : 5.0;
                                            return Icon(
                                              star < avg.floor() ? Icons.star_rounded : Icons.star_outline_rounded,
                                              size: 14,
                                              color: Colors.white,
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ...user.badges.map((b) {
                                bool isLevelBadge = b.startsWith('L') && b.length <= 2;
                                return Container(
                                  margin: const EdgeInsets.only(right: 16),
                                  width: 140,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03), 
                                        blurRadius: 20, 
                                        offset: const Offset(0, 8)
                                      )
                                    ],
                                    border: Border.all(color: AppTheme.backgroundLight, width: 2),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          top: -20,
                                          right: -20,
                                          child: Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppTheme.primaryBlue.withOpacity(0.03),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              if (isLevelBadge)
                                                Image.asset('assets/badges/$b.png', height: 40, width: 40, errorBuilder: (c, e, s) => const Icon(Icons.stars_rounded, color: AppTheme.priorityYellow, size: 40))
                                              else
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
                                                  child: const Icon(Icons.verified_rounded, color: AppTheme.primaryBlue, size: 24),
                                                ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      isLevelBadge ? 'TIER $b' : b.toUpperCase(),
                                                      style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5, color: AppTheme.textDark),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      'ACHIEVED',
                                                      style: TextStyle(color: AppTheme.logoGreen, fontWeight: FontWeight.bold, fontSize: 8),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.1, end: 0),
                      ],
                      const SizedBox(height: 40),
                      Text(user.role == 'admin' ? 'City Expense Audit' : 'Recent Activity', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ),
              ),

              if (user.role == 'admin')
                StreamBuilder<List<TransactionModel>>(
                  stream: db.getTransactions(),
                  builder: (context, transSnap) {
                    if (transSnap.connectionState == ConnectionState.waiting) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                    final trans = transSnap.data ?? [];
                    if (trans.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No expenditures recorded yet', style: TextStyle(color: AppTheme.textLight)))),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final t = trans[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: AppTheme.softShadow,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: (t.type == 'ai' ? AppTheme.primaryBlue : AppTheme.priorityYellow).withOpacity(0.1), shape: BoxShape.circle),
                                    child: Icon(t.type == 'ai' ? Icons.auto_awesome_rounded : Icons.person_search_rounded, color: t.type == 'ai' ? AppTheme.primaryBlue : AppTheme.priorityYellow, size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        Text('${t.timestamp.toLocal().toString().substring(0, 16)} • ${t.type.toUpperCase()} AUTH', style: const TextStyle(color: AppTheme.textLight, fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                  Text('-₹${t.amount}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.priorityRed, fontSize: 16)),
                                ],
                              ),
                            );
                          },
                          childCount: trans.length,
                        ),
                      ),
                    );
                  }
                )
              else
                StreamBuilder<List<Issue>>(
                stream: authService.isResolver 
                  ? db.getLiveIssues() 
                  : db.getIssuesByUser(userId),
                builder: (context, issueSnapshot) {
                  if (issueSnapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                  }
                  
                  List<Issue> issues = issueSnapshot.data ?? [];
                  if (authService.isResolver) {
                    issues = issues.where((i) => i.resolverId == userId && i.status == 'resolved').toList();
                  }

                  if (issues.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.history_rounded, size: 48, color: AppTheme.textLight.withOpacity(0.2)),
                              const SizedBox(height: 12),
                              Text("No activity found yet", style: TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.bold)),
                            ],
                          )
                        ),
                      )
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final issue = issues[index];
                          Color statusColor = issue.status == 'resolved' ? AppTheme.priorityGreen : AppTheme.priorityYellow;
                          
                          return InkWell(
                            onTap: () => _showIssueDetails(context, issue, authService, db),
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04), 
                                    blurRadius: 20, 
                                    offset: const Offset(0, 10)
                                  )
                                ],
                                border: Border.all(color: AppTheme.backgroundLight, width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(issue.emoji, style: const TextStyle(fontSize: 28)),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          issue.title, 
                                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: statusColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                issue.status.toUpperCase(), 
                                                style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5)
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              issue.department.toUpperCase(),
                                              style: TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.bold, fontSize: 9, letterSpacing: 0.5),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: AppTheme.textLight),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
                        },
                        childCount: issues.length,
                      ),
                    ),
                  );
                },
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalysisRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textLight, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value, 
            style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 12),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  void _showIssueDetails(BuildContext context, Issue issue, AuthService auth, FirestoreService db) {
    Color statusColor = issue.status == 'resolved' ? AppTheme.priorityGreen : AppTheme.priorityYellow;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  issue.status.toUpperCase(),
                                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1),
                                ),
                              ),
                              Text(issue.emoji, style: const TextStyle(fontSize: 40)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(issue.title, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: AppTheme.textLight),
                              const SizedBox(width: 4),
                              Text(issue.department, style: const TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(width: 16),
                              const Icon(Icons.calendar_today, size: 14, color: AppTheme.textLight),
                              const SizedBox(width: 4),
                              const Text('Today', style: TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          const Divider(height: 48),
                          Text('DESCRIPTION', style: GoogleFonts.inter(color: AppTheme.textLight, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                          const SizedBox(height: 12),
                          Text(issue.description, style: const TextStyle(fontSize: 15, height: 1.6, color: AppTheme.textDark)),
                          const SizedBox(height: 24),
                          if (issue.imageUrl.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: issue.imageUrl.startsWith('local://')
                                ? Builder(
                                    builder: (context) {
                                      final bytes = LocalImageService.getImage(issue.imageUrl);
                                      if (bytes == null) {
                                        return Container(
                                          height: 240, 
                                          width: double.infinity,
                                          color: Colors.grey[200], 
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: const [
                                              Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                                              SizedBox(height: 8),
                                              Text('Image not cached', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                            ],
                                          )
                                        );
                                      }
                                      return Image.memory(
                                        bytes,
                                        height: 240,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  )
                                : IssueImage(
                                    imageUrl: issue.imageUrl,
                                    height: 240,
                                    width: double.infinity,
                                  ),
                            ),
                            if (issue.status == 'resolved' && issue.resolutionImage != null) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Icon(Icons.verified_rounded, color: AppTheme.priorityGreen, size: 16),
                                  const SizedBox(width: 8),
                                  Text('RESOLUTION PROOF', style: GoogleFonts.outfit(color: AppTheme.priorityGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: IssueImage(
                                  imageUrl: issue.resolutionImage!,
                                  height: 200,
                                  width: double.infinity,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Center(child: Text('Work Verified & Evidence Locked', style: TextStyle(fontSize: 10, color: AppTheme.priorityGreen, fontWeight: FontWeight.bold))),
                            ],
                            const SizedBox(height: 24),
                          ],
                          if (issue.aiSummary != null && issue.aiSummary!.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.auto_awesome, size: 14, color: AppTheme.primaryBlue),
                                      const SizedBox(width: 8),
                                      Text('AI SUMMARY', style: GoogleFonts.inter(color: AppTheme.primaryBlue, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    issue.aiSummary!,
                                    style: const TextStyle(color: AppTheme.textDark, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundLight,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              children: [
                                _buildAnalysisRow('Estimated Time to Resolve', issue.estimatedTime ?? 'TBD'),
                                if (issue.resolutionNotes != null) ...[
                                  const Divider(height: 24),
                                  _buildAnalysisRow('Resolution', issue.resolutionNotes!),
                                ],
                              ],
                            ),
                          ),
                           if (issue.status == 'open' && !auth.isResolver) ...[
                            const SizedBox(height: 40),
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton.icon(
                                onPressed: () => _confirmWithdraw(context, db, issue.id),
                                icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
                                label: const Text('WITHDRAW FROM GRID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Center(
                              child: Text(
                                'Once a resolver starts working, you cannot withdraw.',
                                style: TextStyle(color: AppTheme.textLight, fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmWithdraw(BuildContext context, FirestoreService db, String issueId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Withdraw Report?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text('This will permanently remove the report from the city grid. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close bottom sheet
              try {
                await db.withdrawIssue(issueId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Report withdrawn successfully")),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('WITHDRAW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDetail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white.withOpacity(0.6)),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textDark)),
        Text(label, style: const TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w900, fontSize: 8, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.textLight, letterSpacing: 1)),
            Text(value, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          ],
        ),
      ],
    );
  }
}

class GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    const spacing = 40.0;
    for (double i = 0; i < size.width + size.height; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(0, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
