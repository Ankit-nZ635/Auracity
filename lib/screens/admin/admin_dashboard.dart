import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/firestore_service.dart';
import '../../models/issue_model.dart';
import '../../theme.dart';
import '../../services/local_image_service.dart';
import '../../services/location_service.dart';
import '../../models/user_model.dart';
import '../../widgets/issue_image.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _aiPrioritized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Initialize Treasury for Admin
    context.read<FirestoreService>().initializeAdminBudget();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('Admin Center', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
      ),
      body: StreamBuilder<List<Issue>>(
        stream: context.read<FirestoreService>().getLiveIssues(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.dashboard_customize_outlined, size: 64, color: AppTheme.textLight.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  const Text('No issues reported yet', style: TextStyle(color: AppTheme.textLight)),
                ],
              ),
            );
          }

          List<Issue> allIssues = snapshot.data!;
          List<Issue> pendingIssues = allIssues.where((i) => i.status == 'open').toList();
          List<Issue> dispatchedIssues = allIssues.where((i) => i.status == 'in_progress').toList();
          List<Issue> resolvedIssues = allIssues.where((i) => i.status == 'resolved').toList();

          return Column(
            children: [
              // Modern Unified Sliding Stats Tabs
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final tabWidth = (constraints.maxWidth - 12) / 3;
                    return Container(
                      height: 90,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Stack(
                        children: [
                          // Sliding Pill
                          AnimatedBuilder(
                            animation: _tabController,
                            builder: (context, _) {
                              final statusColors = [AppTheme.priorityRed, AppTheme.priorityYellow, AppTheme.priorityGreen];
                              final activeColor = statusColors[_tabController.index];
                              return AnimatedPositioned(
                                duration: 450.ms,
                                curve: Curves.easeOutBack,
                                left: _tabController.index * tabWidth,
                                child: Container(
                                  width: tabWidth,
                                  height: 78,
                                  decoration: BoxDecoration(
                                    color: activeColor,
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        color: activeColor.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          // Tab Items
                          Row(
                            children: [
                              _buildModernTabItem(0, 'PENDING', pendingIssues.length.toString(), AppTheme.priorityRed),
                              _buildModernTabItem(1, 'ACTIVE', dispatchedIssues.length.toString(), AppTheme.priorityYellow),
                              _buildModernTabItem(2, 'FIXED', resolvedIssues.length.toString(), AppTheme.priorityGreen),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                ),
              ),

              // AI Prioritize Button (directly below tabs now)
              AnimatedBuilder(
                animation: _tabController,
                builder: (context, child) {
                  if (_tabController.index == 0 && pendingIssues.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: GestureDetector(
                        onTap: () => setState(() => _aiPrioritized = !_aiPrioritized),
                        child: AnimatedContainer(
                          duration: 300.ms,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          decoration: BoxDecoration(
                            gradient: _aiPrioritized 
                              ? LinearGradient(colors: [AppTheme.primaryBlue, AppTheme.accentCyan])
                              : null,
                            color: _aiPrioritized ? null : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, color: _aiPrioritized ? Colors.white : AppTheme.primaryBlue, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _aiPrioritized ? 'AI Sorting Active' : 'Sort by Priority (AI)',
                                style: TextStyle(color: _aiPrioritized ? Colors.white : AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms);
                  }
                  return const SizedBox.shrink();
                },
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDetailedIssueList(pendingIssues, isPendingView: true),
                    _buildDetailedIssueList(dispatchedIssues),
                    _buildDetailedIssueList(resolvedIssues),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailedIssueList(List<Issue> issues, {bool isPendingView = false}) {
    if (issues.isEmpty) {
      return Center(child: Text('Category empty', style: TextStyle(color: AppTheme.textLight.withOpacity(0.5))));
    }

    if (isPendingView && _aiPrioritized) {
      issues.sort((a, b) {
        int weight(String p) {
          final lp = p.toLowerCase();
          if (lp.contains('critical') || lp.contains('emergency')) return 4;
          if (lp.contains('high') || lp.contains('major')) return 3;
          if (lp.contains('medium')) return 2;
          return 1;
        }
        return weight(b.priority).compareTo(weight(a.priority));
      });
    } else {
      issues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    // LOCATION-BASED CONSOLIDATION
    final List<List<Issue>> clusteredIssues = LocationService.clusterItems<Issue>(
      issues, 
      (i) => i.latitude, 
      (i) => i.longitude,
      radius: 50.0 // 50m radius for Admin task grouping
    );

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      itemCount: clusteredIssues.length,
      itemBuilder: (context, index) {
        final group = clusteredIssues[index];
        final issue = group.first; // Representative issue
        final isCluster = group.length > 1;
        Color statusColor = issue.status == 'resolved' ? AppTheme.priorityGreen : AppTheme.priorityYellow;
        if (issue.status == 'open') statusColor = AppTheme.priorityRed;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.softShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                Text(issue.emoji, style: const TextStyle(fontSize: 32)),
                if (isCluster)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
                      child: Text('${group.length}', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            title: Text(
              isCluster ? 'Consolidated Project' : issue.title, 
              style: const TextStyle(fontWeight: FontWeight.bold)
            ),
            subtitle: Text(
              isCluster ? '${group.length} overlapping reports'.toUpperCase() : issue.department.toUpperCase(), 
              style: TextStyle(color: AppTheme.primaryBlue, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(issue.status == 'open' ? 'PENDING' : issue.status.replaceAll('_',' ').toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    if (issue.imageUrl.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: IssueImage(
                          imageUrl: issue.imageUrl,
                          height: 180,
                          width: double.infinity,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (isCluster) ...[
                      Text('CLUSTERED REPORTS', style: TextStyle(color: AppTheme.textLight, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...group.map((gi) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, size: 14, color: AppTheme.primaryBlue),
                            const SizedBox(width: 8),
                            Expanded(child: Text(gi.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                          ],
                        ),
                      )).toList(),
                    ] else ...[
                      Text('CITIZEN REPORT', style: TextStyle(color: AppTheme.textLight, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(issue.description, style: const TextStyle(height: 1.5)),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _buildAnalysisRow('Priority Level', issue.priority.toUpperCase()),
                          const SizedBox(height: 8),
                          _buildAnalysisRow('Smart ETA', issue.estimatedTime ?? 'Awaiting Data'),
                        ],
                      ),
                    ),
                    if (issue.status == 'open') ...[
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          minimumSize: const Size.fromHeight(54),
                        ),
                        onPressed: () => _showDispatchDialog(context, group),
                        child: Text(isCluster ? 'DISPATCH PROJECT' : 'DISPATCH RESOLVER'),
                      ),
                    ],
                    if (issue.status == 'resolved') ...[
                      const SizedBox(height: 16),
                      Text('RESOLUTION PROOF', style: TextStyle(color: AppTheme.priorityGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: IssueImage(imageUrl: issue.imageUrl, height: 100, width: double.infinity),
                                ),
                                const SizedBox(height: 4),
                                const Text('BEFORE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.textLight)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, color: AppTheme.textLight, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: IssueImage(
                                    imageUrl: issue.resolutionImage ?? '', 
                                    height: 100, width: double.infinity
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text('AFTER (PROOF)', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.priorityGreen)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (issue.paymentStatus == 'pending') ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppTheme.priorityYellow.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.priorityYellow.withOpacity(0.2))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.payment_rounded, color: AppTheme.priorityYellow, size: 16),
                                  const SizedBox(width: 8),
                                  Text('PAYMENT PENDING', style: TextStyle(color: AppTheme.priorityYellow, fontWeight: FontWeight.bold, fontSize: 10)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => _showManualPayDialog(context, issue),
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.priorityYellow, minimumSize: const Size.fromHeight(44)),
                                child: const Text('AUTHORIZE PAYOUT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ] else if (issue.paymentStatus == 'paid') ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('SALARY PAID', style: TextStyle(color: AppTheme.priorityGreen, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                                if (issue.workRating != null)
                                  Row(
                                    children: List.generate(5, (star) => Icon(
                                      star < issue.workRating! ? Icons.star_rounded : Icons.star_outline_rounded,
                                      size: 10,
                                      color: AppTheme.priorityYellow,
                                    )),
                                  ),
                              ],
                            ),
                            Text('₹${issue.payoutAmount}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textLight)),
                          ],
                        ),
                      ],
                      if (issue.resolutionNotes != null) ...[
                        const SizedBox(height: 12),
                        Text('Notes: ${issue.resolutionNotes}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                      ],
                    ],
                    if (issue.status == 'in_progress') ...[
                      const SizedBox(height: 16),
                      Center(child: Text('Assigned to: ${issue.resolverId}', style: const TextStyle(color: AppTheme.priorityYellow, fontWeight: FontWeight.bold, fontSize: 12))),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildModernTabItem(int index, String label, String value, Color statusColor) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _tabController.animateTo(index)),
        child: AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            final isSelected = _tabController.index == index;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? Colors.white : AppTheme.textDark,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: isSelected ? Colors.white.withOpacity(0.8) : AppTheme.textLight,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnalysisRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textLight, fontSize: 12, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  void _showDispatchDialog(BuildContext context, List<Issue> group) {
    final issue = group.first;
    String rId = 'roads_resolver';
    if (issue.department.toLowerCase().contains('water')) rId = 'water_resolver';
    if (issue.department.toLowerCase().contains('garbage') || issue.department.toLowerCase().contains('waste')) rId = 'garbage_resolver';
    if (issue.department.toLowerCase().contains('power')) rId = 'power_resolver';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          title: Text('Assign Department', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppTheme.primaryBlue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text('AI suggests: ${issue.department}', style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                tileColor: AppTheme.backgroundLight,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: const CircleAvatar(backgroundColor: AppTheme.primaryBlue, child: Icon(Icons.engineering, color: Colors.white)),
                title: Text(rId.toUpperCase().replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Department Lead Available'),
                trailing: const Icon(Icons.check_circle, color: AppTheme.priorityGreen),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('CANCEL', style: TextStyle(color: AppTheme.textLight))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
              onPressed: () {
                context.read<FirestoreService>().dispatchBatch(group, '${rId}_001');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppTheme.primaryBlue,
                  content: Text('Consolidated project dispatched to $rId team!'),
                ));
              },
              child: const Text('CONFIRM ASSIGNMENT'),
            )
          ],
        );
      }
    );
  }

  void _showManualPayDialog(BuildContext context, Issue issue) {
    TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Authorize Salary', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reviewing work for:', style: TextStyle(color: AppTheme.textLight, fontSize: 10, fontWeight: FontWeight.bold)),
            Text(issue.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: '₹ ',
                labelText: 'Payout Amount',
                hintText: 'e.g. 500',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              double? amt = double.tryParse(amountController.text);
              if (amt == null || amt <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
                return;
              }
              await context.read<FirestoreService>().processManualPayment(issue, amt);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppTheme.priorityGreen, content: Text('Payment of ₹$amt authorized.')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.priorityGreen),
            child: const Text('CONFIRM PAYOUT'),
          ),
        ],
      ),
    );
  }
}
