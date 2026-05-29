import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/firestore_service.dart';
import '../../models/issue_model.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';
import '../../services/local_image_service.dart';
import '../../services/supabase_service.dart';
import '../../services/ai_service.dart';
import '../../services/location_service.dart';
import '../../widgets/issue_image.dart';
import 'dart:typed_data';

class ResolverDashboard extends StatefulWidget {
  const ResolverDashboard({super.key});

  @override
  State<ResolverDashboard> createState() => _ResolverDashboardState();
}

class _ResolverDashboardState extends State<ResolverDashboard> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthService>().currentUserId;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 28),
            const SizedBox(width: 8),
            Text('Resolver HQ', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
      body: StreamBuilder<List<Issue>>(
        stream: context.read<FirestoreService>().getLiveIssues(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          List<Issue> myTasks = snapshot.data!
              .where((i) => i.resolverId == userId && i.status == 'in_progress')
              .toList();

          if (myTasks.isEmpty) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Text('🎯', style: TextStyle(fontSize: 64)),
                   const SizedBox(height: 16),
                   Text('All clear!', style: Theme.of(context).textTheme.displayMedium),
                   const Text('No assigned tasks pending at the moment.', style: TextStyle(color: AppTheme.textLight)),
                 ],
               ),
             ).animate().fadeIn();
          }

          // LOCATION-BASED CONSOLIDATION
          final List<List<Issue>> clusteredTasks = LocationService.clusterItems<Issue>(
            myTasks, 
            (i) => i.latitude, 
            (i) => i.longitude,
            radius: 50.0 // 50m radius for task grouping
          );

          return ListView.builder(
            itemCount: clusteredTasks.length,
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            itemBuilder: (context, index) {
              final group = clusteredTasks[index];
              final issue = group.first;
              final isCluster = group.length > 1;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.softShadow,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Reporter Evidence Header
                    Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 16/9,
                          child: IssueImage(
                            imageUrl: issue.imageUrl, 
                          ),
                        ),
                        if (isCluster)
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: AppTheme.primaryBlue, borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.layers, color: Colors.white, size: 14),
                                  const SizedBox(width: 8),
                                  Text('${group.length} Reports Merged', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isCluster ? 'Consolidated Project' : issue.title, 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                                    ),
                                    Text('ID: ${issue.id.substring(0, 8)}', style: const TextStyle(color: AppTheme.textLight, fontSize: 10, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    if (issue.workRating != null) 
                                      Row(
                                        children: List.generate(5, (star) => Icon(
                                          star < issue.workRating! ? Icons.star_rounded : Icons.star_outline_rounded,
                                          size: 14,
                                          color: AppTheme.priorityYellow,
                                        )),
                                      ),
                                  ],
                                ),
                              ),
                              Text(issue.emoji, style: const TextStyle(fontSize: 32)),
                            ],
                          ),
                          const Divider(height: 32),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.primaryBlue),
                              const SizedBox(width: 8),
                              Expanded(child: Text('GPS: ${issue.latitude.toStringAsFixed(4)}, ${issue.longitude.toStringAsFixed(4)}', style: const TextStyle(color: AppTheme.textLight, fontSize: 12))),
                            ],
                          ),
                          if (isCluster) ...[
                             const SizedBox(height: 16),
                             Container(
                               padding: const EdgeInsets.all(12),
                               decoration: BoxDecoration(color: AppTheme.backgroundLight, borderRadius: BorderRadius.circular(12)),
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text('CONSOLIDATED DESCRIPTIONS', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 9)),
                                   const SizedBox(height: 8),
                                   ...group.map((gi) => Padding(
                                     padding: const EdgeInsets.only(bottom: 4.0),
                                     child: Text('• ${gi.description}', style: const TextStyle(fontSize: 12, height: 1.4)),
                                   )).toList(),
                                 ],
                               ),
                             ),
                          ] else ...[
                            const SizedBox(height: 16),
                            Text('DESCRIPTION', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
                            const SizedBox(height: 4),
                            Text(issue.description, style: const TextStyle(fontSize: 15, height: 1.4)),
                          ],
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _showResolveDialog(group),
                            icon: const Icon(Icons.check_circle_outline),
                            label: Text(isCluster ? 'SUBMIT BATCH RESOLUTION' : 'SUBMIT RESOLUTION'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.priorityGreen, 
                              minimumSize: const Size.fromHeight(54),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
            },
          );
        },
      ),
    );
  }

  void _showResolveDialog(List<Issue> group) {
    final issue = group.first;
    final isCluster = group.length > 1;
    TextEditingController notesController = TextEditingController();
    String? localImagePath;
    Uint8List? imageBytes;
    bool isVerifying = false;
    String? aiFeedback;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              title: Text('Complete Task', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (localImagePath == null)
                      GestureDetector(
                        onTap: () async {
                          final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
                          if (photo != null) {
                            final bytes = await photo.readAsBytes();
                            String path = await LocalImageService.saveImage('resolved_${issue.id}', bytes);
                            setState(() {
                              imageBytes = bytes;
                              localImagePath = path;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1), width: 2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo_outlined, color: AppTheme.primaryBlue, size: 32),
                              const SizedBox(height: 8),
                              Text('Capture Evidence', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(color: AppTheme.priorityGreen.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: AppTheme.priorityGreen),
                            SizedBox(width: 8),
                            Text('Evidence Locked', style: TextStyle(color: AppTheme.priorityGreen, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Resolution Summary',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                    if (isVerifying) ...[
                      const SizedBox(height: 24),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      const Text('AI Auditor verifying work...', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                    if (aiFeedback != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.priorityRed.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.priorityRed.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: AppTheme.priorityRed, size: 16),
                                SizedBox(width: 8),
                                Text('REJECTION FEEDBACK', style: TextStyle(color: AppTheme.priorityRed, fontWeight: FontWeight.bold, fontSize: 10)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(aiFeedback!, style: const TextStyle(fontSize: 12, height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text('BACK', style: TextStyle(color: AppTheme.textLight))
                ),
                ElevatedButton(
                  onPressed: isVerifying ? null : () async {
                    if (localImagePath == null || imageBytes == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo evidence required')));
                      return;
                    }
                    
                    setState(() {
                      isVerifying = true;
                      aiFeedback = null;
                    });

                    try {
                      // 1. AI Verification
                      final audit = await AiService.verifyResolution(
                        issue.title, 
                        issue.description, 
                        issue.imageUrl, 
                        imageBytes!
                      );

                      if (audit['isResolved'] == true) {
                        // 2. Upload to Supabase for permanent storage
                        final String fileName = 'res_${issue.id}_${DateTime.now().millisecondsSinceEpoch}';
                        final String remoteUrl = await SupabaseService.uploadImage(fileName, imageBytes!, folder: 'resolutions');

                        // 3. Finalize in Firestore (Batch with Salary & Rating)
                        final double payout = (audit['payoutReward'] ?? 0.0).toDouble();
                        final int rating = audit['workRating'] ?? 3;
                        await context.read<FirestoreService>().finalizeResolutionBatch(group, remoteUrl, notesController.text, payout, rating);
                        
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppTheme.priorityGreen,
                          content: Text(payout > 0 ? 'Work verified! [Rating: $rating/5] Payout of ₹$payout processed.' : 'Work verified! Payout pending Admin review.'),
                        ));
                      } else {
                        // Reject based on AI feedback
                        setState(() {
                          isVerifying = false;
                          aiFeedback = audit['feedback'];
                        });
                      }
                    } catch (e) {
                      setState(() => isVerifying = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed: $e')));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.priorityGreen),
                  child: Text(isVerifying ? 'AUDITING...' : 'FINALIZE'),
                )
              ],
            );
          }
        );
      }
    );
  }
}

