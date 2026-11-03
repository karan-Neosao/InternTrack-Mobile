import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/application_model.dart';
import '../../models/company_profile_model.dart';
import '../../models/internship_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_components.dart';
import '../auth/welcome_screen.dart';

class CompanyDashboardScreen extends StatefulWidget {
  const CompanyDashboardScreen({super.key});

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ApiService _apiService = ApiService();

  List<ApplicationModel> _applicants = [];
  List<InternshipModel> _myInternships = [];
  CompanyProfileModel? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
  }

  Future<void> _loadCompanyData() async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final applicantsFuture = _apiService.getCompanyApplicants(token);
      final profileFuture = _apiService.getCompanyProfile(token);
      final internshipsFuture = _apiService.getInternships();

      final results = await Future.wait([applicantsFuture, profileFuture, internshipsFuture]);

      if (!mounted) return;

      final appsRaw = results[0] as List<Map<String, dynamic>>;
      final profileRes = results[1] as Map<String, dynamic>;
      final internshipsRaw = results[2] as List<Map<String, dynamic>>;

      final user = context.read<AuthProvider>().user ?? {};
      final userId = user['id'];

      setState(() {
        _applicants = appsRaw.map((a) => ApplicationModel.fromJson(a)).toList();
        final profileMap = profileRes['profile'] is Map ? Map<String, dynamic>.from(profileRes['profile']) : <String, dynamic>{};
        _profile = CompanyProfileModel.fromJson(profileMap);

        // Filter internships posted by this company if user id matches
        _myInternships = internshipsRaw
            .map((item) => InternshipModel.fromJson(item))
            .where((item) => userId == null || item.companyId == userId || item.companyId == 0)
            .toList();

        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // Post new internship modal
  void _showPostInternshipSheet() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final skillsController = TextEditingController();
    final locationController = TextEditingController();
    final stipendController = TextEditingController();
    final durationController = TextEditingController();
    final deadlineController = TextEditingController();
    String workType = 'remote';
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
                      'Post New Internship',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Fill out details to publish a new internship opportunity.',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: titleController,
                      label: 'Internship Title',
                      hint: 'e.g. Flutter Mobile Developer Intern',
                      prefixIcon: Icons.title_rounded,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: descController,
                      label: 'Job Description',
                      hint: 'Describe key responsibilities and expectations...',
                      prefixIcon: Icons.description_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: skillsController,
                      label: 'Required Skills (comma-separated)',
                      hint: 'e.g. Flutter, Dart, REST APIs, Git',
                      prefixIcon: Icons.code_rounded,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: locationController,
                      label: 'Location (optional)',
                      hint: 'e.g. Pune, Maharashtra / Remote',
                      prefixIcon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 14),
                    const Text('Work Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['remote', 'onsite', 'hybrid'].map((type) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(type.toUpperCase()),
                              selected: workType == type,
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: workType == type ? Colors.white : AppColors.textDark,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setSheetState(() => workType = type);
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: stipendController,
                      label: 'Stipend (Monthly, in ₹)',
                      hint: 'e.g. 15000',
                      prefixIcon: Icons.payments_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: durationController,
                      label: 'Duration',
                      hint: 'e.g. 3 Months',
                      prefixIcon: Icons.calendar_today_outlined,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: deadlineController,
                      label: 'Application Deadline',
                      hint: 'YYYY-MM-DD (e.g. 2026-12-31)',
                      prefixIcon: Icons.event_outlined,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Publish Internship',
                      isLoading: isSaving,
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty || descController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter title and description.'),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                          return;
                        }

                        final token = context.read<AuthProvider>().token;
                        if (token == null) return;

                        setSheetState(() => isSaving = true);
                        try {
                          final data = {
                            'title': titleController.text.trim(),
                            'description': descController.text.trim(),
                            'skills': skillsController.text.trim().isEmpty ? null : skillsController.text.trim(),
                            'location': locationController.text.trim().isEmpty ? null : locationController.text.trim(),
                            'work_type': workType,
                            'stipend': stipendController.text.trim().isEmpty ? null : stipendController.text.trim(),
                            'duration': durationController.text.trim().isEmpty ? null : durationController.text.trim(),
                            'deadline': deadlineController.text.trim().isEmpty ? null : deadlineController.text.trim(),
                          };

                          await _apiService.createInternship(data: data, token: token);
                          if (!mounted) return;
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                          _loadCompanyData();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Internship published successfully!'),
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

  // Update applicant status (Accept/Reject)
  Future<void> _updateStatus(int applicationId, String status) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      await _apiService.updateApplicationStatus(
        applicationId: applicationId,
        status: status,
        token: token,
      );
      _loadCompanyData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Applicant marked as $status!'),
          backgroundColor: status == 'accepted' ? AppColors.success : AppColors.danger,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // Delete internship
  Future<void> _deleteInternship(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Internship'),
        content: const Text('Are you sure you want to delete this internship? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final token = context.read<AuthProvider>().token;
      if (token == null) return;

      try {
        await _apiService.deleteInternship(id: id, token: token);
        _loadCompanyData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Internship deleted successfully.')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  // Edit Company Profile modal
  void _showEditCompanyProfileSheet() {
    final companyNameController = TextEditingController(text: _profile?.companyName ?? '');
    final websiteController = TextEditingController(text: _profile?.website ?? '');
    final industryController = TextEditingController(text: _profile?.industry ?? '');
    final locationController = TextEditingController(text: _profile?.location ?? '');
    final descController = TextEditingController(text: _profile?.description ?? '');
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
                        decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text('Edit Company Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    const Text('Update your public company profile details', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: companyNameController,
                      label: 'Company Name',
                      hint: 'e.g. Acme Tech Solutions',
                      prefixIcon: Icons.business_outlined,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: websiteController,
                      label: 'Website URL',
                      hint: 'https://example.com',
                      prefixIcon: Icons.language,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: industryController,
                      label: 'Industry',
                      hint: 'e.g. Software Development & AI',
                      prefixIcon: Icons.category_outlined,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: locationController,
                      label: 'Headquarters / Location',
                      hint: 'e.g. Bengaluru, Karnataka',
                      prefixIcon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: descController,
                      label: 'About Company',
                      hint: 'Tell students about your company culture and mission...',
                      prefixIcon: Icons.description_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Save Company Profile',
                      isLoading: isSaving,
                      onPressed: () async {
                        final token = context.read<AuthProvider>().token;
                        if (token == null) return;

                        setSheetState(() => isSaving = true);
                        try {
                          final data = {
                            if (companyNameController.text.trim().isNotEmpty) 'company_name': companyNameController.text.trim(),
                            if (websiteController.text.trim().isNotEmpty) 'website': websiteController.text.trim(),
                            if (industryController.text.trim().isNotEmpty) 'industry': industryController.text.trim(),
                            if (locationController.text.trim().isNotEmpty) 'location': locationController.text.trim(),
                            if (descController.text.trim().isNotEmpty) 'description': descController.text.trim(),
                          };

                          final updated = await _apiService.updateCompanyProfile(token: token, companyData: data);
                          if (!mounted) return;
                          setState(() {
                            _profile = CompanyProfileModel.fromJson(updated);
                          });
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Company profile updated!'), backgroundColor: AppColors.success),
                            );
                          }
                        } catch (e) {
                          setSheetState(() => isSaving = false);
                          if (sheetContext.mounted) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.danger),
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
        content: const Text('Are you sure you want to log out of the Company Portal?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildOverviewTab(),
      _buildApplicantsTab(),
      _buildInternshipsTab(),
      _buildCompanyProfileTab(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // If drawer is open, close it
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          _scaffoldKey.currentState?.closeDrawer();
          return;
        }

        // If on another tab, return to Overview (index 0)
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }

        // If on Overview tab, confirm exit to avoid returning to WelcomeScreen
        final shouldExit = await _showExitDialog();
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _buildCompanyDrawer(context),
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: _currentIndex,
          children: tabs,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                elevation: 0,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: const Color(0xFF94A3B8),
                selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_outlined),
                    activeIcon: Icon(Icons.dashboard_rounded),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.people_outline_rounded),
                    activeIcon: Icon(Icons.people_rounded),
                    label: 'Applicants',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.work_outline_rounded),
                    activeIcon: Icon(Icons.work_rounded),
                    label: 'Internships',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.business_outlined),
                    activeIcon: Icon(Icons.business_rounded),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // TAB 1: Company Overview
  Widget _buildOverviewTab() {
    final user = context.watch<AuthProvider>().user ?? {};
    final companyName = _profile?.companyName ?? user['name']?.toString() ?? 'Company';
    final initials = companyName.isNotEmpty ? companyName.substring(0, 1).toUpperCase() : 'C';

    final totalApplicants = _applicants.length;
    final pendingCount = _applicants.where((a) => a.status.toLowerCase() == 'pending').length;
    final acceptedCount = _applicants.where((a) => a.status.toLowerCase() == 'accepted').length;
    final postedCount = _myInternships.length;

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadCompanyData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 42,
                        width: 42,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.menu_rounded, size: 22),
                          color: AppColors.textDark,
                          tooltip: 'Open Sidebar',
                          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                        ),
                      ),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          initials,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            companyName,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          const Text('Employer Portal', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: AppColors.textMuted),
                    onPressed: _logout,
                    tooltip: 'Log Out',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Overview Statistics Row
              const Text('Recruitment Overview', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _companyStatCard(
                      label: 'Applicants',
                      count: totalApplicants.toString(),
                      color: AppColors.primary,
                      icon: Icons.people_outline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _companyStatCard(
                      label: 'Pending',
                      count: pendingCount.toString(),
                      color: AppColors.warning,
                      icon: Icons.hourglass_top,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _companyStatCard(
                      label: 'Selected',
                      count: acceptedCount.toString(),
                      color: AppColors.success,
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _companyStatCard(
                      label: 'Active Roles',
                      count: postedCount.toString(),
                      color: AppColors.info,
                      icon: Icons.work_outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Action Banner
              PrimaryButton(
                label: 'Post New Internship',
                icon: Icons.add_circle_outline,
                onPressed: _showPostInternshipSheet,
              ),
              const SizedBox(height: 26),

              // Recent Applicants
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Applicants', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  GestureDetector(
                    onTap: () => setState(() => _currentIndex = 1),
                    child: const Text('View All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                const LoadingWidget(message: 'Loading applicants...')
              else if (_applicants.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.people_outline, size: 36, color: AppColors.textMuted),
                      SizedBox(height: 8),
                      Text('No Applicants Yet', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      SizedBox(height: 4),
                      Text('Applicants will appear here once students apply.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    ],
                  ),
                )
              else
                Column(
                  children: _applicants.take(3).map((app) => _applicantCard(app)).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // TAB 2: Applicants Listing & Status Management
  Widget _buildApplicantsTab() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppColors.textDark),
          tooltip: 'Open Menu',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Student Applicants', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading applicants...')
          : _applicants.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.people_outline_rounded,
                  title: 'No Applications Received',
                  message: 'When students apply for your posted internships, they will appear here.',
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadCompanyData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _applicants.length,
                    itemBuilder: (context, index) {
                      return _applicantCard(_applicants[index]);
                    },
                  ),
                ),
    );
  }

  // TAB 3: Internships Management
  Widget _buildInternshipsTab() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppColors.textDark),
          tooltip: 'Open Menu',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Posted Internships', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
            tooltip: 'Post Internship',
            onPressed: _showPostInternshipSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading internships...')
          : _myInternships.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.work_outline_rounded,
                  title: 'No Internships Posted',
                  message: 'You have not posted any internships yet. Click below to publish your first role.',
                  buttonLabel: 'Post an Internship',
                  onButtonPressed: _showPostInternshipSheet,
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadCompanyData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _myInternships.length,
                    itemBuilder: (context, index) {
                      final item = _myInternships[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                                  ),
                                ),
                                StatusBadge(status: item.status),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Stipend: ${item.formattedStipend} • ${item.workType.toUpperCase()}', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                                  label: const Text('Delete', style: TextStyle(color: AppColors.danger, fontSize: 13)),
                                  onPressed: () => _deleteInternship(item.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  // TAB 4: Company Profile
  Widget _buildCompanyProfileTab() {
    final user = context.watch<AuthProvider>().user ?? {};
    final companyName = _profile?.companyName ?? user['name']?.toString() ?? 'Company';
    final email = user['email']?.toString() ?? 'company@example.com';
    final initials = companyName.isNotEmpty ? companyName.substring(0, 1).toUpperCase() : 'C';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppColors.textDark),
          tooltip: 'Open Menu',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Company Profile', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            tooltip: 'Edit Profile',
            onPressed: _showEditCompanyProfileSheet,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      initials,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(companyName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('Verified Company Account', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
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
                  const Text('Company Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 14),
                  _detailRow('Industry', _profile?.industry ?? 'Not specified'),
                  const Divider(height: 20),
                  _detailRow('Location', _profile?.location ?? 'Not specified'),
                  const Divider(height: 20),
                  _detailRow('Website', _profile?.website ?? 'Not specified'),
                  const Divider(height: 20),
                  const Text('About Company', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    _profile?.description ?? 'No description added yet.',
                    style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Edit Profile',
              icon: Icons.edit_outlined,
              onPressed: _showEditCompanyProfileSheet,
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _companyStatCard({
    required String label,
    required String count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(count.padLeft(2, '0'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _applicantCard(ApplicationModel app) {
    final studentName = app.studentName ?? 'Candidate #${app.studentId}';
    final studentEmail = app.studentEmail ?? '';
    final role = app.internship?.title ?? 'Internship #${app.internshipId}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  studentName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
                    if (studentEmail.isNotEmpty)
                      Text(studentEmail, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              StatusBadge(status: app.status),
            ],
          ),
          const SizedBox(height: 10),
          Text('Applied for: $role', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primary)),
          if (app.coverLetter != null && app.coverLetter!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Cover Letter: "${app.coverLetter}"',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (app.status.toLowerCase() != 'rejected')
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger),
                    foregroundColor: AppColors.danger,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _updateStatus(app.id, 'rejected'),
                  child: const Text('Reject'),
                ),
              const SizedBox(width: 8),
              if (app.status.toLowerCase() != 'accepted')
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _updateStatus(app.id, 'accepted'),
                  child: const Text('Accept'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 110, child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 13))),
      ],
    );
  }

  Future<bool?> _showExitDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Exit InternTrack?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to exit the Company Portal?',
          style: TextStyle(fontSize: 14, color: AppColors.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exit App'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyDrawer(BuildContext context) {
    final user = context.watch<AuthProvider>().user ?? {};
    final companyName = _profile?.companyName ?? user['name']?.toString() ?? 'Company';
    final email = user['email']?.toString() ?? 'company@example.com';
    final initials = companyName.isNotEmpty ? companyName.substring(0, 1).toUpperCase() : 'C';

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.business_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'InternTrack',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'EMPLOYER',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'Recruiter & Management',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Company Profile Card in Drawer
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                companyName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'COMPANY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                children: [
                  _buildCompanyDrawerItem(
                    icon: Icons.dashboard_rounded,
                    title: 'Recruitment Overview',
                    index: 0,
                  ),
                  _buildCompanyDrawerItem(
                    icon: Icons.people_rounded,
                    title: 'Student Applicants',
                    index: 1,
                    badgeCount: _applicants.isNotEmpty ? _applicants.length : null,
                  ),
                  _buildCompanyDrawerItem(
                    icon: Icons.work_rounded,
                    title: 'Posted Internships',
                    index: 2,
                    badgeCount: _myInternships.isNotEmpty ? _myInternships.length : null,
                  ),
                  _buildCompanyDrawerItem(
                    icon: Icons.business_rounded,
                    title: 'Company Profile',
                    index: 3,
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: AppColors.border),
                  ),

                  // Quick Post Action
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 22),
                    title: const Text(
                      'Post New Internship',
                      style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onTap: () {
                      Navigator.pop(context);
                      _showPostInternshipSheet();
                    },
                  ),
                ],
              ),
            ),

            // Logout Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
                ),
                title: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyDrawerItem({
    required IconData icon,
    required String title,
    required int index,
    int? badgeCount,
  }) {
    final isSelected = _currentIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: AppColors.primaryLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textMuted,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        trailing: badgeCount != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textDark,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: () {
          Navigator.pop(context);
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}