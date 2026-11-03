import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/internship_model.dart';
import '../../providers/bookmark_provider.dart';
import '../../widgets/app_components.dart';
import 'internship_detail_screen.dart';

class SavedInternshipsScreen extends StatelessWidget {
  final VoidCallback? onExploreTapped;
  final VoidCallback? onOpenDrawer;

  const SavedInternshipsScreen({
    super.key,
    this.onExploreTapped,
    this.onOpenDrawer,
  });

  void _openDetails(BuildContext context, InternshipModel internship) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InternshipDetailScreen(internship: internship),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkProvider = context.watch<BookmarkProvider>();
    final savedList = bookmarkProvider.savedInternships;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: onOpenDrawer != null
            ? IconButton(
                icon: const Icon(Icons.menu_rounded, color: AppColors.textDark),
                tooltip: 'Open Menu',
                onPressed: onOpenDrawer,
              )
            : null,
        title: Row(
          children: [
            const Text(
              'Saved Internships',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            if (savedList.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${savedList.length}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (savedList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.textMuted),
              tooltip: 'Clear All',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear All Saved?'),
                    content: const Text('Are you sure you want to remove all saved internships?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await bookmarkProvider.clearAll();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All bookmarks cleared'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                }
              },
            ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: savedList.isEmpty
          ? EmptyStateWidget(
              icon: Icons.bookmark_border_rounded,
              title: 'No Saved Internships',
              message:
                  'Keep track of internships you are interested in by tapping the bookmark icon on any internship card.',
              buttonLabel: onExploreTapped != null ? 'Explore Opportunities' : null,
              onButtonPressed: onExploreTapped,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: savedList.length,
              itemBuilder: (context, index) {
                final item = savedList[index];
                return InternshipCard(
                  internship: item,
                  isBookmarked: true,
                  onBookmarkToggle: () async {
                    await bookmarkProvider.removeBookmark(item.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Removed from saved internships'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  onTap: () => _openDetails(context, item),
                );
              },
            ),
    );
  }
}
