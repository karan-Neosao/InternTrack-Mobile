import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/application_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_components.dart';

class MyApplicationsScreen extends StatefulWidget {
  final VoidCallback? onBrowseTapped;
  final VoidCallback? onOpenDrawer;

  const MyApplicationsScreen({
    super.key,
    this.onBrowseTapped,
    this.onOpenDrawer,
  });

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<ApplicationModel>> _applicationsFuture;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  void _loadApplications() {
    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) {
      _applicationsFuture = Future.value([]);
      return;
    }

    _applicationsFuture = _apiService.getMyApplications(token).then((list) {
      return list.map((item) => ApplicationModel.fromJson(item)).toList();
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _loadApplications();
    });
    await _applicationsFuture;
  }

  void _showApplicationDetails(ApplicationModel app) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      app.internship?.title ?? 'Internship Application',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  StatusBadge(status: app.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                app.internship?.companyName ?? 'Company',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              _detailRow('Applied On', app.createdAt?.split('T').first ?? 'Recent'),
              if (app.internship?.location != null)
                _detailRow('Location', app.internship!.location!),
              if (app.internship?.workType != null)
                _detailRow('Work Mode', app.internship!.workType.toUpperCase()),
              if (app.internship?.formattedStipend != null)
                _detailRow('Stipend', app.internship!.formattedStipend),
              const SizedBox(height: 16),
              const Text(
                'Submitted Cover Letter',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  app.coverLetter != null && app.coverLetter!.isNotEmpty
                      ? app.coverLetter!
                      : 'No cover letter was submitted with this application.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Close',
                isOutlined: true,
                onPressed: () => Navigator.pop(ctx),
                height: 48,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'My Applications',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Pending', 'Accepted', 'Rejected']
                    .map(
                      (filter) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CategoryChip(
                          label: filter,
                          isSelected: _selectedFilter == filter,
                          onTap: () {
                            setState(() => _selectedFilter = filter);
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),

          // Applications List
          Expanded(
            child: FutureBuilder<List<ApplicationModel>>(
              future: _applicationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget(message: 'Loading your applications...');
                }

                if (snapshot.hasError) {
                  return EmptyStateWidget(
                    icon: Icons.error_outline_rounded,
                    title: 'Unable to Load Applications',
                    message: snapshot.error.toString().replaceFirst('Exception: ', ''),
                    buttonLabel: 'Try Again',
                    onButtonPressed: _refresh,
                  );
                }

                final allApps = snapshot.data ?? [];

                final filtered = allApps.where((app) {
                  if (_selectedFilter == 'All') return true;
                  return app.status.toLowerCase() == _selectedFilter.toLowerCase();
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.description_outlined,
                    title: 'No Applications Found',
                    message: _selectedFilter == 'All'
                        ? 'You have not applied for any internships yet. Start exploring opportunities now!'
                        : 'No applications found with status "$_selectedFilter".',
                    buttonLabel: widget.onBrowseTapped != null ? 'Explore Internships' : null,
                    onButtonPressed: widget.onBrowseTapped,
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final app = filtered[index];
                      final title = app.internship?.title ?? 'Internship #${app.internshipId}';
                      final company = app.internship?.companyName ?? 'Company';
                      final initials = company.isNotEmpty ? company.substring(0, 1).toUpperCase() : 'C';

                      return GestureDetector(
                        onTap: () => _showApplicationDetails(app),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
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
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        initials,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
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
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          company,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  StatusBadge(status: app.status),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 14,
                                        color: AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Applied: ${app.createdAt?.split('T').first ?? 'Recent'}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Row(
                                    children: [
                                      Text(
                                        'Details',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
