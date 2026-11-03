import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/welcome_screen.dart';

class DashboardShell extends StatelessWidget {
  final String title;
  final String role;
  final String userName;
  final int selectedIndex;
  final List<DashboardMenuItem> menuItems;
  final ValueChanged<int> onMenuSelected;
  final Widget child;

  const DashboardShell({
    super.key,
    required this.title,
    required this.role,
    required this.userName,
    required this.selectedIndex,
    required this.menuItems,
    required this.onMenuSelected,
    required this.child,
  });

  static const Color primary = Color(0xFF3454D1);
  static const Color background = Color(0xFFF6F8FC);

  Future<void> _confirmLogout(BuildContext context) async {
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
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 850;

        if (isWide) {
          return Scaffold(
            backgroundColor: background,
            body: Row(
              children: [
                _buildSidebar(context),
                Expanded(
                  child: Column(
                    children: [
                      _buildHeader(context, false),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF172554),
                fontWeight: FontWeight.bold,
              ),
            ),
            iconTheme: const IconThemeData(color: primary),
            actions: [
              IconButton(
                tooltip: 'Logout',
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFFE8EDFF),
                  child: Icon(Icons.person, color: primary, size: 19),
                ),
              ),
            ],
          ),
          drawer: Drawer(
            child: _buildSidebar(context),
          ),
          body: child,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: onMenuSelected,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: primary,
            unselectedItemColor: Colors.blueGrey,
            backgroundColor: Colors.white,
            items: menuItems
                .map(
                  (item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                label: item.label,
              ),
            )
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 260,
      color: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.work_outline,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'InternTrack',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF172554),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(0xFFE8EDFF),
                    child: Icon(Icons.person, color: primary),
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
                          ),
                        ),
                        Text(
                          role,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'MAIN MENU',
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  final selected = selectedIndex == index;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      selected: selected,
                      selectedTileColor: const Color(0xFFEFF2FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: Icon(
                        item.icon,
                        color: selected ? primary : Colors.blueGrey,
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          color: selected
                              ? primary
                              : const Color(0xFF475569),
                          fontWeight:
                          selected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      onTap: () => onMenuSelected(index),
                    ),
                  );
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3454D1), Color(0xFF6684F0)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.workspace_premium, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    'Build your future!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Explore opportunities and grow your career.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: const Icon(Icons.logout, color: Color(0xFFEF4444)),
                title: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context); // Close drawer if open
                  }
                  _confirmLogout(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool mobile) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172554),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 250,
            height: 42,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: DashboardShell.background,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            backgroundColor: Color(0xFFE8EDFF),
            child: Icon(Icons.person, color: primary),
          ),
        ],
      ),
    );
  }
}

class DashboardMenuItem {
  final String label;
  final IconData icon;

  const DashboardMenuItem(this.label, this.icon);
}