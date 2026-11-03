import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/application_model.dart';
import '../../models/internship_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../services/api_service.dart';
import '../../services/internship_service.dart';
import '../../widgets/app_components.dart';
import '../auth/welcome_screen.dart';
import 'internship_detail_screen.dart';
import 'internship_list_screen.dart';
import 'my_applications_screen.dart';
import 'saved_internships_screen.dart';
import 'student_profile_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ApiService _apiService = ApiService();
  final InternshipService _internshipService = InternshipService();

  List<ApplicationModel> _myApplications = [];
  List<InternshipModel> _recentInternships = [];
  bool _isLoadingOverview = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final token = context.read<AuthProvider>().token;
    setState(() => _isLoadingOverview = true);

    try {
      // Fetch recent internships
      final internshipsFuture = _internshipService.getInternships();

      // Fetch applications for stats if logged in
      Future<List<Map<String, dynamic>>> appsFuture = Future.value([]);
      if (token != null && token.isNotEmpty) {
        appsFuture = _apiService.getMyApplications(token);
      }

      final results = await Future.wait([internshipsFuture, appsFuture]);

      if (!mounted) return;
      setState(() {
        _recentInternships = results[0] as List<InternshipModel>;
        final rawApps = results[1] as List<Map<String, dynamic>>;
        _myApplications = rawApps.map((a) => ApplicationModel.fromJson(a)).toList();
        _isLoadingOverview = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingOverview = false);
    }
  }

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  Future<void> _toggleBookmark(BookmarkProvider provider, InternshipModel item) async {
    final nowSaved = await provider.toggleBookmark(item);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(nowSaved ? 'Saved to bookmarks' : 'Removed from bookmarks'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomeOverview(),
      InternshipListScreen(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      MyApplicationsScreen(
        onBrowseTapped: () => _navigateToTab(1),
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      SavedInternshipsScreen(
        onExploreTapped: () => _navigateToTab(1),
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      StudentProfileScreen(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
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

        // If on another tab, return to Home (index 0)
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }

        // If on Home tab, show exit confirmation dialog
        final shouldExit = await _showExitDialog();
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _buildSidebarDrawer(context),
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: _currentIndex,
          children: pages,
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
                onTap: _navigateToTab,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                elevation: 0,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: const Color(0xFF94A3B8),
                selectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.explore_outlined),
                    activeIcon: Icon(Icons.explore_rounded),
                    label: 'Explore',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.description_outlined),
                    activeIcon: Icon(Icons.description_rounded),
                    label: 'Applications',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.bookmark_outline_rounded),
                    activeIcon: Icon(Icons.bookmark_rounded),
                    label: 'Saved',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline_rounded),
                    activeIcon: Icon(Icons.person_rounded),
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

  Widget _buildHomeOverview() {
    final user = context.watch<AuthProvider>().user ?? {};
    final userName = user['name']?.toString() ?? 'Student';
    final initials = userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'S';

    // Calculate real stats from applications list
    final totalApps = _myApplications.length;
    final pendingApps = _myApplications.where((a) => a.status.toLowerCase() == 'pending').length;
    final acceptedApps = _myApplications.where((a) => a.status.toLowerCase() == 'accepted').length;
    final rejectedApps = _myApplications.where((a) => a.status.toLowerCase() == 'rejected').length;

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header: User Greeting, Hamburger Menu & Notifications
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Hamburger Menu Button
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
                      GestureDetector(
                        onTap: () => _navigateToTab(4),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $userName 👋',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Find your dream internship',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, size: 22),
                      color: AppColors.textDark,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No new notifications.'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Search Bar
              GestureDetector(
                onTap: () => _navigateToTab(1),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search_rounded, color: AppColors.textMuted, size: 22),
                      SizedBox(width: 12),
                      Text(
                        'Search internships, companies, roles...',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Application Statistics Card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Application Status',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _navigateToTab(2),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Responsive Stat Cards Row (no RenderFlex overflow)
              Row(
                children: [
                  Expanded(
                    child: _statPill(
                      label: 'Total',
                      count: totalApps.toString(),
                      color: AppColors.primary,
                      icon: Icons.assignment_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statPill(
                      label: 'Pending',
                      count: pendingApps.toString(),
                      color: AppColors.warning,
                      icon: Icons.hourglass_empty_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statPill(
                      label: 'Accepted',
                      count: acceptedApps.toString(),
                      color: AppColors.success,
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statPill(
                      label: 'Rejected',
                      count: rejectedApps.toString(),
                      color: AppColors.danger,
                      icon: Icons.cancel_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),

              // Popular Categories
              const Text(
                'Popular Categories',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'Flutter',
                    'Web Dev',
                    'UI/UX Design',
                    'Backend',
                    'Data Science',
                    'Python',
                  ]
                      .map(
                        (cat) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: CategoryChip(
                            label: cat,
                            isSelected: false,
                            onTap: () => _navigateToTab(1),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 26),

              // Recommended / Recent Internships
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Featured Internships',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _navigateToTab(1),
                    child: const Text(
                      'See All',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (_isLoadingOverview)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: LoadingWidget(message: 'Loading featured internships...'),
                )
              else if (_recentInternships.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.work_outline, size: 38, color: AppColors.textMuted),
                      const SizedBox(height: 10),
                      const Text(
                        'No Internships Active',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Check back soon for new openings.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: () {
                    final bookmarkProvider = context.watch<BookmarkProvider>();
                    return _recentInternships
                        .take(5)
                        .map(
                          (internship) => InternshipCard(
                            internship: internship,
                            isBookmarked: bookmarkProvider.isBookmarked(internship.id),
                            onBookmarkToggle: () => _toggleBookmark(bookmarkProvider, internship),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => InternshipDetailScreen(internship: internship),
                                ),
                              );
                            },
                          ),
                        )
                        .toList();
                  }(),
                ),

              const SizedBox(height: 20),

              // Recent Application Activity
              if (_myApplications.isNotEmpty) ...[
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  children: _myApplications.take(3).map((app) {
                    final title = app.internship?.title ?? 'Internship #${app.internshipId}';
                    final company = app.internship?.companyName ?? 'Company';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 38,
                            width: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.send_rounded, size: 18, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  company,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(status: app.status),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statPill({
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            count.padLeft(2, '0'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarDrawer(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user ?? {};
    final userName = user['name']?.toString() ?? 'Student';
    final userEmail = user['email']?.toString() ?? 'student@example.com';
    final initials = userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'S';

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header: Brand & Student Profile
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
                          Icons.rocket_launch_rounded,
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
                                  'PRO',
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
                            'Career & Internship Portal',
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

                  // Student Profile Card in Drawer
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
                                userName,
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
                                userEmail,
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
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'STUDENT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                children: [
                  _buildDrawerItem(
                    icon: Icons.dashboard_rounded,
                    title: 'Home Overview',
                    index: 0,
                  ),
                  _buildDrawerItem(
                    icon: Icons.explore_rounded,
                    title: 'Explore Internships',
                    index: 1,
                  ),
                  _buildDrawerItem(
                    icon: Icons.description_rounded,
                    title: 'My Applications',
                    index: 2,
                    badgeCount: _myApplications.isNotEmpty ? _myApplications.length : null,
                  ),
                  _buildDrawerItem(
                    icon: Icons.bookmark_rounded,
                    title: 'Saved Internships',
                    index: 3,
                    badgeCount: () {
                      final count = context.watch<BookmarkProvider>().count;
                      return count > 0 ? count : null;
                    }(),
                  ),
                  _buildDrawerItem(
                    icon: Icons.person_rounded,
                    title: 'My Profile',
                    index: 4,
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: AppColors.border),
                  ),

                  // Quick Links
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.notifications_none_rounded, color: AppColors.textMuted, size: 22),
                    title: const Text(
                      'Notifications',
                      style: TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No new notifications at this time.')),
                      );
                    },
                  ),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 22),
                    title: const Text(
                      'About InternTrack',
                      style: TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onTap: () {
                      Navigator.pop(context);
                      _showAboutDialog();
                    },
                  ),
                ],
              ),
            ),

            // Bottom Pro Banner & Logout
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Column(
                children: [
                  // Quick promo card
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3454D1), Color(0xFF5B7BF5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 26),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Build Your Future',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'Apply to top verified internships',
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Logout Button
                  ListTile(
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
                      Navigator.pop(context); // Close drawer
                      _confirmLogout();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
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
          Navigator.pop(context); // Close drawer
          _navigateToTab(index);
        },
      ),
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
          'Are you sure you want to exit the InternTrack application?',
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

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.rocket_launch_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('InternTrack', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('Version 1.0.0', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
        content: const Text(
          'InternTrack is a comprehensive platform connecting students with verified company internships, streamlined application tracking, and talent discovery.',
          style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textDark),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
