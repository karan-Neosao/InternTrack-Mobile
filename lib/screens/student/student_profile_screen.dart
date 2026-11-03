import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/student_profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_components.dart';
import '../auth/welcome_screen.dart';

class StudentProfileScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const StudentProfileScreen({super.key, this.onOpenDrawer});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final ApiService _apiService = ApiService();
  StudentProfileModel? _profile;
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await _apiService.getStudentProfile(token);
      final userMap = res['user'] is Map ? Map<String, dynamic>.from(res['user']) : null;
      final profileMap = res['profile'] is Map ? Map<String, dynamic>.from(res['profile']) : <String, dynamic>{};

      if (!mounted) return;
      setState(() {
        _user = userMap ?? context.read<AuthProvider>().user;
        _profile = StudentProfileModel.fromJson(profileMap);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _user = context.read<AuthProvider>().user;
        _profile = StudentProfileModel();
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadResume() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );
      if (files.isEmpty || files.first.path == null) {
        return;
      }
      final file = files.first;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading resume...'), duration: Duration(seconds: 1)),
      );

      final res = await _apiService.uploadStudentResume(
        token: token,
        filePath: file.path!,
        fileName: file.name,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Resume uploaded successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadProfile();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _showEditProfileSheet() {
    final phoneController = TextEditingController(text: _profile?.phone ?? '');
    final collegeController = TextEditingController(text: _profile?.college ?? '');
    final courseController = TextEditingController(text: _profile?.course ?? '');
    final gradYearController = TextEditingController(
      text: _profile?.graduationYear != null ? _profile!.graduationYear.toString() : '',
    );
    final skillsController = TextEditingController(text: _profile?.skills ?? '');
    final linkedinController = TextEditingController(text: _profile?.linkedinUrl ?? '');

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        height: 4,
                        width: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Edit Student Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Update your educational details and technical skills',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: phoneController,
                      label: 'Phone Number',
                      hint: '+91 9876543210',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: collegeController,
                      label: 'College / University',
                      hint: 'e.g. Pune Institute of Technology',
                      prefixIcon: Icons.school_outlined,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: courseController,
                      label: 'Degree / Course',
                      hint: 'e.g. B.Tech Computer Engineering',
                      prefixIcon: Icons.menu_book_outlined,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: gradYearController,
                      label: 'Graduation Year',
                      hint: 'e.g. 2026',
                      prefixIcon: Icons.event_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: skillsController,
                      label: 'Technical Skills (comma-separated)',
                      hint: 'e.g. Flutter, Dart, Laravel, REST APIs, Git',
                      prefixIcon: Icons.code_rounded,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: linkedinController,
                      label: 'LinkedIn Profile URL',
                      hint: 'https://linkedin.com/in/username',
                      prefixIcon: Icons.link_rounded,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Save Changes',
                      isLoading: isSaving,
                      onPressed: () async {
                        final token = context.read<AuthProvider>().token;
                        if (token == null) return;

                        setSheetState(() => isSaving = true);
                        try {
                          final data = {
                            if (phoneController.text.trim().isNotEmpty)
                              'phone': phoneController.text.trim(),
                            if (collegeController.text.trim().isNotEmpty)
                              'college': collegeController.text.trim(),
                            if (courseController.text.trim().isNotEmpty)
                              'course': courseController.text.trim(),
                            if (gradYearController.text.trim().isNotEmpty)
                              'graduation_year': int.tryParse(gradYearController.text.trim()),
                            if (skillsController.text.trim().isNotEmpty)
                              'skills': skillsController.text.trim(),
                            if (linkedinController.text.trim().isNotEmpty)
                              'linkedin_url': linkedinController.text.trim(),
                          };

                          final updated = await _apiService.updateStudentProfile(
                            token: token,
                            profileData: data,
                          );

                          if (!mounted) return;
                          setState(() {
                            _profile = StudentProfileModel.fromJson(updated);
                          });

                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile updated successfully!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          setSheetState(() => isSaving = false);
                          if (sheetContext.mounted) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              SnackBar(
                                content: Text(e.toString().replaceFirst('Exception: ', '')),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of InternTrack?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: LoadingWidget(message: 'Loading profile...'),
      );
    }

    final user = _user ?? context.watch<AuthProvider>().user ?? {};
    final name = user['name']?.toString() ?? 'Student';
    final email = user['email']?.toString() ?? 'student@example.com';
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'S';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: widget.onOpenDrawer != null
            ? IconButton(
                icon: const Icon(Icons.menu_rounded, color: AppColors.textDark),
                tooltip: 'Open Menu',
                onPressed: widget.onOpenDrawer,
              )
            : null,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            tooltip: 'Edit Profile',
            onPressed: _showEditProfileSheet,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showEditProfileSheet,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Student Candidate',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Educational Information
              _infoCard(
                title: 'Education',
                icon: Icons.school_outlined,
                children: [
                  _infoItem(
                    'College / University',
                    _profile?.college ?? 'Not specified yet',
                  ),
                  const Divider(height: 20),
                  _infoItem(
                    'Course / Degree',
                    _profile?.course ?? 'Not specified yet',
                  ),
                  const Divider(height: 20),
                  _infoItem(
                    'Graduation Year',
                    _profile?.graduationYear?.toString() ?? 'Not specified yet',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Technical Skills
              _infoCard(
                title: 'Technical Skills',
                icon: Icons.code_rounded,
                children: [
                  if (_profile != null && _profile!.skillsList.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _profile!.skillsList
                          .map(
                            (s) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                s,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    )
                  else
                    const Text(
                      'No skills added yet. Tap edit to add your skills.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Contact & Links
              _infoCard(
                title: 'Contact Details',
                icon: Icons.contacts_outlined,
                children: [
                  _infoItem(
                    'Phone',
                    _profile?.phone ?? 'Not specified yet',
                  ),
                  const Divider(height: 20),
                  _infoItem(
                    'LinkedIn',
                    _profile?.linkedinUrl ?? 'Not specified yet',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Resume / CV Document Card
              _infoCard(
                title: 'Resume / CV Document',
                icon: Icons.description_outlined,
                children: [
                  if (_profile?.resumePath != null && _profile!.resumePath!.isNotEmpty) ...[
                    Row(
                      children: [
                        Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _profile!.resumePath!.split('/').last,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                              ),
                              const SizedBox(height: 2),
                              const Text('Attached to all job applications', style: TextStyle(fontSize: 11, color: AppColors.success)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    const Text('No resume uploaded yet. Upload a PDF/DOC so employers can review your profile.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    const SizedBox(height: 12),
                  ],
                  OutlinedButton.icon(
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    label: Text(_profile?.resumePath != null ? 'Replace Resume' : 'Upload Resume (PDF, DOC)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _pickAndUploadResume,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Edit & Logout Buttons
              PrimaryButton(
                label: 'Edit Profile Information',
                icon: Icons.edit_outlined,
                onPressed: _showEditProfileSheet,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Log Out',
                icon: Icons.logout_rounded,
                isOutlined: true,
                backgroundColor: AppColors.danger,
                textColor: AppColors.danger,
                onPressed: _logout,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}
