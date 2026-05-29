import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/supabase_service.dart';
import '../../theme.dart';
import '../../services/location_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;
  late TextEditingController _occupationController;
  late TextEditingController _locationController;
  late TextEditingController _usernameController;
  
  String? _newPhotoUrl;
  bool _isUploading = false;
  bool _isSaving = false;
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _bioController = TextEditingController(text: widget.user.bio);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _occupationController = TextEditingController(text: widget.user.occupation);
    _locationController = TextEditingController(text: widget.user.location);
    _usernameController = TextEditingController(text: widget.user.username);
    _newPhotoUrl = widget.user.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _occupationController.dispose();
    _locationController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image != null) {
      setState(() => _isUploading = true);
      try {
        final bytes = await image.readAsBytes();
        final fileName = 'profile_${widget.user.id}_${DateTime.now().millisecondsSinceEpoch}';
        final url = await SupabaseService.uploadImage(fileName, bytes, folder: 'profiles');
        setState(() {
          _newPhotoUrl = url;
          _isUploading = false;
        });
      } catch (e) {
        setState(() => _isUploading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Upload failed: $e"), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final db = context.read<FirestoreService>();
      final newUsername = _usernameController.text.trim().toLowerCase();

      // Check for uniqueness if username changed
      if (newUsername != (widget.user.username ?? '')) {
        if (newUsername.isEmpty) {
          throw 'Username cannot be empty';
        }
        if (newUsername.length < 3) {
          throw 'Username must be at least 3 characters';
        }
        final isUnique = await db.isUsernameUnique(newUsername);
        if (!isUnique) {
          throw 'Username @$newUsername is already taken';
        }
      }

      final updatedUser = UserModel(
        id: widget.user.id,
        name: _nameController.text.trim(),
        username: newUsername,
        email: widget.user.email,
        points: widget.user.points,
        role: widget.user.role,
        badges: widget.user.badges,
        resolvedCount: widget.user.resolvedCount,
        department: widget.user.department,
        photoUrl: _newPhotoUrl,
        bio: _bioController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        occupation: _occupationController.text.trim(),
        location: _locationController.text.trim(),
      );

      await db.updateUserProfile(updatedUser);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Save failed: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _fetchLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      final position = await LocationService.getCurrentLocation();
      final address = await LocationService.getAddressFromLatLng(position.latitude, position.longitude);
      setState(() {
        _locationController.text = address;
        _isFetchingLocation = false;
      });
    } catch (e) {
      setState(() => _isFetchingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching location: $e"), backgroundColor: Colors.orangeAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('Edit Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          if (_isSaving)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            TextButton(
              onPressed: _saveProfile,
              child: Text('SAVE', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Photo Picker
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: AppTheme.softShadow,
                        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1), width: 4),
                      ),
                      child: ClipOval(
                        child: _isUploading 
                          ? const Center(child: CircularProgressIndicator())
                          : (_newPhotoUrl != null && _newPhotoUrl!.isNotEmpty)
                            ? Image.network(_newPhotoUrl!, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.person, size: 60))
                            : const Icon(Icons.person, size: 60, color: AppTheme.textLight),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              
              const SizedBox(height: 40),
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),
              _buildTextField('Full Name', _nameController, Icons.person_outline, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              _buildTextField('Unique Username', _usernameController, Icons.alternate_email_rounded, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              _buildTextField('Occupation', _occupationController, Icons.work_outline),
              const SizedBox(height: 16),
              _buildTextField(
                'Location', 
                _locationController, 
                Icons.location_on_outlined,
                suffixIcon: _isFetchingLocation 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : IconButton(
                      icon: const Icon(Icons.my_location, color: AppTheme.primaryBlue, size: 20),
                      onPressed: _fetchLocation,
                    ),
              ),
              
              const SizedBox(height: 32),
              _buildSectionTitle('Bio'),
              const SizedBox(height: 16),
              _buildTextField('Tell the city about yourself...', _bioController, Icons.chat_bubble_outline, maxLines: 4),
              
              const SizedBox(height: 32),
              _buildSectionTitle('Contact'),
              const SizedBox(height: 16),
              _buildTextField('Phone Number', _phoneController, Icons.phone_outlined, keyboardType: TextInputType.phone),
              
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue, letterSpacing: 1.5),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1, String? Function(String?)? validator, TextInputType? keyboardType, Widget? suffixIcon}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        keyboardType: keyboardType,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppTheme.textDark),
        decoration: InputDecoration(
          hintText: label,
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
          ),
          suffixIcon: suffixIcon != null 
            ? Padding(padding: const EdgeInsets.only(right: 12), child: suffixIcon)
            : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
