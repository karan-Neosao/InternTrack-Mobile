import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/internship_model.dart';
import '../../providers/bookmark_provider.dart';
import '../../services/internship_service.dart';
import '../../widgets/app_components.dart';
import 'internship_detail_screen.dart';

class InternshipListScreen extends StatefulWidget {
  final String? initialCategory;
  final VoidCallback? onOpenDrawer;

  const InternshipListScreen({
    super.key,
    this.initialCategory,
    this.onOpenDrawer,
  });

  @override
  State<InternshipListScreen> createState() => _InternshipListScreenState();
}

class _InternshipListScreenState extends State<InternshipListScreen> {
  final InternshipService _internshipService = InternshipService();
  final TextEditingController _searchController = TextEditingController();

  late Future<List<InternshipModel>> _internshipsFuture;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedWorkType = 'All';

  final List<String> _categories = [
    'All',
    'Flutter',
    'Web Dev',
    'Mobile',
    'Backend',
    'UI/UX',
    'Python',
    'Data Science',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
    _loadInternships();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadInternships() {
    _internshipsFuture = _internshipService.getInternships();
  }

  Future<void> _refreshInternships() async {
    setState(() {
      _loadInternships();
    });
    await _internshipsFuture;
  }

  void _openDetails(InternshipModel internship) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InternshipDetailScreen(internship: internship),
      ),
    );
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
          'Browse Internships',
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
          // Search & Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: Column(
              children: [
                // Search Field
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() => _searchQuery = val.trim());
                    },
                    decoration: InputDecoration(
                      hintText: 'Search title, company, skills, location...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CategoryChip(
                          label: cat,
                          isSelected: _selectedCategory == cat,
                          onTap: () {
                            setState(() => _selectedCategory = cat);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Work Type Quick Filter Bar (Scrollable to prevent overflow)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  const Text(
                    'Work Mode:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                  ),
                  const SizedBox(width: 8),
                  ...['All', 'Remote', 'Hybrid', 'Onsite'].map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(
                          type,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _selectedWorkType == type ? Colors.white : AppColors.textDark,
                          ),
                        ),
                        selected: _selectedWorkType == type,
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(
                          color: _selectedWorkType == type ? AppColors.primary : AppColors.border,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedWorkType = type);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Results List
          Expanded(
            child: FutureBuilder<List<InternshipModel>>(
              future: _internshipsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget(message: 'Fetching internships...');
                }

                if (snapshot.hasError) {
                  return EmptyStateWidget(
                    icon: Icons.wifi_off_rounded,
                    title: 'Unable to Load Internships',
                    message: snapshot.error.toString().replaceFirst('Exception: ', ''),
                    buttonLabel: 'Try Again',
                    onButtonPressed: _refreshInternships,
                  );
                }

                final allInternships = snapshot.data ?? [];

                // Client-side filtering across live search, category, and work mode
                final filtered = allInternships.where((item) {
                  // Search query filter
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    final matchTitle = item.title.toLowerCase().contains(q);
                    final matchCompany = item.companyName.toLowerCase().contains(q);
                    final matchSkills = item.skills?.toLowerCase().contains(q) ?? false;
                    final matchLocation = item.location?.toLowerCase().contains(q) ?? false;
                    if (!matchTitle && !matchCompany && !matchSkills && !matchLocation) {
                      return false;
                    }
                  }

                  // Category filter
                  if (_selectedCategory != 'All') {
                    final cat = _selectedCategory.toLowerCase();
                    final matchTitle = item.title.toLowerCase().contains(cat);
                    final matchSkills = item.skills?.toLowerCase().contains(cat) ?? false;
                    final matchDesc = item.description.toLowerCase().contains(cat);
                    if (!matchTitle && !matchSkills && !matchDesc) {
                      return false;
                    }
                  }

                  // Work type filter
                  if (_selectedWorkType != 'All') {
                    if (item.workType.toLowerCase() != _selectedWorkType.toLowerCase()) {
                      return false;
                    }
                  }

                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.search_off_rounded,
                    title: 'No Internships Found',
                    message: allInternships.isEmpty
                        ? 'No active internships are available right now. Please check back later!'
                        : 'No internships match your current search and filter criteria.',
                    buttonLabel: (_searchQuery.isNotEmpty || _selectedCategory != 'All' || _selectedWorkType != 'All')
                        ? 'Reset Filters'
                        : 'Refresh',
                    onButtonPressed: () {
                      if (_searchQuery.isNotEmpty || _selectedCategory != 'All' || _selectedWorkType != 'All') {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _selectedCategory = 'All';
                          _selectedWorkType = 'All';
                        });
                      } else {
                        _refreshInternships();
                      }
                    },
                  );
                }

                final bookmarkProvider = context.watch<BookmarkProvider>();

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _refreshInternships,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final internship = filtered[index];
                      final isSaved = bookmarkProvider.isBookmarked(internship.id);
                      return InternshipCard(
                        internship: internship,
                        isBookmarked: isSaved,
                        onBookmarkToggle: () => _toggleBookmark(bookmarkProvider, internship),
                        onTap: () => _openDetails(internship),
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
}
