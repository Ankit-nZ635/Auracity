import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/ai_service.dart';
import '../../models/issue_model.dart';
import '../../theme.dart';
import '../../services/local_image_service.dart';
import '../../services/supabase_service.dart';

class ReportIssueScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  const ReportIssueScreen({super.key, required this.latitude, required this.longitude});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _descriptionController = TextEditingController();
  final FocusNode _descriptionFocusNode = FocusNode();
  XFile? _image;
  bool _isAnalyzing = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  Map<String, String>? _aiAnalysis;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Handle image picker data if activity was killed in the background
    _retrieveLostData();
  }

  Future<void> _retrieveLostData() async {
    if (kIsWeb || !Platform.isAndroid) return;
    
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty) return;
      if (response.file != null && mounted) {
        setState(() {
          _image = response.file;
        });
      } else if (response.exception != null) {
        debugPrint("LostData error: ${response.exception}");
      }
    } catch (e) {
      debugPrint("Error retrieving lost data: $e");
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  Future<void> _showImageSourcePicker() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add Photo Evidence', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryBlue),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Select an existing photo', style: TextStyle(fontSize: 12)),
                onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.accentCyan.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.camera_alt_outlined, color: AppTheme.accentCyan),
                ),
                title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Use camera (may be slow on some devices)', style: TextStyle(fontSize: 12)),
                onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Clear before to free memory for camera process
      PaintingBinding.instance.imageCache.clear();
      
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      // Clear unused memory textures immediately
      PaintingBinding.instance.imageCache.clear();
      
      if (photo != null && mounted) {
        setState(() {
          _image = photo;
          _aiAnalysis = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to pick image: $e";
        });
      }
    }
  }


  Future<void> _analyzeImage() async {
    if (_image == null || _descriptionController.text.trim().isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _aiAnalysis = null;
      _errorMessage = null;
    });
    
    try {
      final analysis = await AiService.analyzeIssue(_descriptionController.text, _image);
      setState(() {
        _aiAnalysis = analysis;
        _isAnalyzing = false;
        if (analysis.containsKey('analysisError')) {
          _errorMessage = "AI analysis failed (Simulation used). Error: ${analysis['analysisError']}";
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = "AI Analysis Failed: $e";
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _submitIssue() async {
    if (_aiAnalysis == null) return;
    
    setState(() => _isSubmitting = true);

    try {
      final String issueId = const Uuid().v4();
      String imageUrl = 'placeholder_url';
      if (_image != null) {
        final bytes = await _image!.readAsBytes();
        imageUrl = await SupabaseService.uploadImage(issueId, bytes);
      }
      
      final issue = Issue(
        id: issueId,
        title: _aiAnalysis!["detailedType"] ?? 'Civic Issue',
        description: _descriptionController.text,
        latitude: widget.latitude,
        longitude: widget.longitude,
        imageUrl: imageUrl, 
        priority: _aiAnalysis!["priority"] ?? 'General',
        status: 'open',
        upvotes: 1,
        reporterId: context.read<AuthService>().currentUserId ?? 'anonymous_user',
        createdAt: DateTime.now(),
        department: _aiAnalysis!["department"] ?? 'General',
        emoji: _aiAnalysis!["suggestedEmoji"] ?? '📍',
        detailedType: _aiAnalysis!["detailedType"],
        estimatedTime: _aiAnalysis!["estimatedTime"],
        aiSummary: _aiAnalysis!["summary"],
      );

      await context.read<FirestoreService>().addIssue(issue);
      if (mounted) {
        // Dismiss keyboard and unfocus before navigation to prevent
        // EditableTextState.didChangeMetrics on a deactivated widget
        _descriptionFocusNode.unfocus();
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Issue reported successfully!")));
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Submission Failed: $e";
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isInputComplete = _image != null && _descriptionController.text.trim().isNotEmpty;
    bool isAnalysisDone = _aiAnalysis != null && !_isAnalyzing;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('New Report', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Evidence Slot
            GestureDetector(
              onTap: (_isAnalyzing || _isSubmitting) ? null : _showImageSourcePicker,
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: AppTheme.softShadow,
                  image: _image != null ? DecorationImage(
                    image: kIsWeb 
                      ? NetworkImage(_image!.path) 
                      : ResizeImage(FileImage(File(_image!.path)), width: 400) as ImageProvider, 
                    fit: BoxFit.cover
                  ) : null,
                ),
                child: _image == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.05), shape: BoxShape.circle),
                            child: const Icon(Icons.campaign_rounded, size: 40, color: AppTheme.primaryBlue),
                          ),
                          const SizedBox(height: 16),
                          const Text("STRIKE A PHOTO", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2))
                        ],
                      )
                    : Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.primaryBlue),
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Description input
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.softShadow,
              ),
              child: TextField(
                controller: _descriptionController,
                focusNode: _descriptionFocusNode,
                maxLines: 4,
                style: const TextStyle(fontWeight: FontWeight.w500),
                enabled: !_isAnalyzing && !_isSubmitting,
                decoration: InputDecoration(
                  hintText: 'Describe the situation...',
                  hintStyle: TextStyle(color: AppTheme.textLight.withOpacity(0.5)),
                  contentPadding: const EdgeInsets.all(24),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _aiAnalysis = null),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // AI Analysis Status or Result
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                ),
              ),

            if (_isAnalyzing)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: AppTheme.primaryBlue, strokeWidth: 3),
                    const SizedBox(height: 20),
                    Text("AuraAI is analyzing...", style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.primaryBlue, letterSpacing: 1)),
                  ],
                ),
              ).animate().fadeIn(),

            if (_isSubmitting)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: AppTheme.priorityGreen, strokeWidth: 3),
                    const SizedBox(height: 20),
                    Text("Uploading to Grid...", style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.priorityGreen, letterSpacing: 1)),
                  ],
                ),
              ).animate().fadeIn(),

            if (isAnalysisDone && !_isSubmitting)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.softShadow,
                  border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1)),
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
                            Text('AURA AI CLASSIFICATION', style: GoogleFonts.inter(color: AppTheme.primaryBlue, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                            Text('High Confidence Result', style: TextStyle(color: AppTheme.textLight, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text(_aiAnalysis!["suggestedEmoji"] ?? '📍', style: const TextStyle(fontSize: 32)),
                      ],
                    ),
                    const Divider(height: 32),
                    _buildAnalysisRow('Estimated Type', _aiAnalysis!["detailedType"] ?? 'General'),
                    const SizedBox(height: 12),
                    _buildAnalysisRow('Suggested Dept', _aiAnalysis!["department"] ?? 'Municipal'),
                    const SizedBox(height: 12),
                    _buildAnalysisRow('Fix Complexity', _aiAnalysis!["priority"]?.toUpperCase() ?? 'NORMAL'),
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
                              Text('AI INSIGHT', style: GoogleFonts.inter(color: AppTheme.primaryBlue, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _aiAnalysis!["summary"] ?? 'Analyzing situation...',
                            style: const TextStyle(color: AppTheme.textDark, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack).fadeIn(),

            const SizedBox(height: 48),

            SizedBox(
              height: 64,
              child: ElevatedButton(
                onPressed: (!isInputComplete || _isAnalyzing || _isSubmitting) 
                  ? null 
                  : (isAnalysisDone ? _submitIssue : _analyzeImage),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAnalysisDone ? AppTheme.priorityGreen : AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 5,
                  shadowColor: (isAnalysisDone ? AppTheme.priorityGreen : AppTheme.primaryBlue).withOpacity(0.4),
                ),
                child: Text(
                  isAnalysisDone ? 'POST REPORT' : 'ANALYZE WITH AI',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
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
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
