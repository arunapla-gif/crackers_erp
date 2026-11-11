import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/erp_theme.dart';
import '../features/auth/view_models/auth_view_model.dart';
import '../features/production/view_models/daily_production_view_model.dart';

class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({
    required this.navigationShell,
    required this.authViewModel,
    required this.productionViewModel,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final AuthViewModel authViewModel;
  final DailyProductionViewModel productionViewModel;

  void _onSelectBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    if (productionViewModel.hasUnsavedChanges) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Unsaved Production Entries'),
          content: const Text(
            'You have unsaved production entries stored as a local draft. Sign out anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Stay'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(backgroundColor: ErpTheme.dangerRose),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }
    await authViewModel.logout();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([authViewModel, productionViewModel]),
      builder: (context, _) {
        final user = authViewModel.currentUser;
        final hasUnsaved = productionViewModel.hasUnsavedChanges;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;

            if (isWide) {
              return Scaffold(
                body: Row(
                  children: [
                    NavigationRail(
                      selectedIndex: navigationShell.currentIndex,
                      onDestinationSelected: _onSelectBranch,
                      extended: constraints.maxWidth >= 1000,
                      backgroundColor: Colors.white,
                      indicatorColor: ErpTheme.productionAmberSoft,
                      leading: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 12,
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: ErpTheme.productionAmber,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.local_fire_department_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            if (constraints.maxWidth >= 1000) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Crackers ERP',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: ErpTheme.slate900,
                                ),
                              ),
                              if (user != null)
                                Text(
                                  '${user.username} (${user.role})',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: ErpTheme.slate500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                      trailing: Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: IconButton(
                              onPressed: () => _confirmLogout(context),
                              tooltip: 'Sign Out',
                              icon: const Icon(Icons.logout_rounded),
                              color: ErpTheme.dangerRose,
                            ),
                          ),
                        ),
                      ),
                      destinations: [
                        NavigationRailDestination(
                          icon: Badge(
                            isLabelVisible: hasUnsaved,
                            child: const Icon(Icons.precision_manufacturing_outlined),
                          ),
                          selectedIcon: Badge(
                            isLabelVisible: hasUnsaved,
                            child: const Icon(
                              Icons.precision_manufacturing,
                              color: ErpTheme.productionAmber,
                            ),
                          ),
                          label: const Text('Production'),
                        ),
                        const NavigationRailDestination(
                          icon: Icon(Icons.groups_outlined),
                          selectedIcon: Icon(
                            Icons.groups,
                            color: ErpTheme.hrIndigo,
                          ),
                          label: Text('Workers & Adv'),
                        ),
                        const NavigationRailDestination(
                          icon: Icon(Icons.inventory_2_outlined),
                          selectedIcon: Icon(
                            Icons.inventory_2,
                            color: ErpTheme.ordersEmerald,
                          ),
                          label: Text('Factory Orders'),
                        ),
                      ],
                    ),
                    const VerticalDivider(width: 1, color: ErpTheme.slate200),
                    Expanded(child: navigationShell),
                  ],
                ),
              );
            }

            return Scaffold(
              body: navigationShell,
              bottomNavigationBar: NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: _onSelectBranch,
                backgroundColor: Colors.white,
                indicatorColor: ErpTheme.productionAmberSoft,
                destinations: [
                  NavigationDestination(
                    icon: Badge(
                      isLabelVisible: hasUnsaved,
                      child: const Icon(Icons.precision_manufacturing_outlined),
                    ),
                    selectedIcon: Badge(
                      isLabelVisible: hasUnsaved,
                      child: const Icon(
                        Icons.precision_manufacturing,
                        color: ErpTheme.productionAmber,
                      ),
                    ),
                    label: 'Production',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.groups_outlined),
                    selectedIcon: Icon(
                      Icons.groups,
                      color: ErpTheme.hrIndigo,
                    ),
                    label: 'Workers & Adv',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.inventory_2_outlined),
                    selectedIcon: Icon(
                      Icons.inventory_2,
                      color: ErpTheme.ordersEmerald,
                    ),
                    label: 'Orders',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class AccountAppBarAction extends StatelessWidget {
  const AccountAppBarAction({
    required this.authViewModel,
    this.hasUnsavedProduction = false,
    super.key,
  });

  final AuthViewModel authViewModel;
  final bool hasUnsavedProduction;

  @override
  Widget build(BuildContext context) {
    final user = authViewModel.currentUser;
    if (user == null) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      tooltip: 'Account & Server',
      onSelected: (value) async {
        if (value == 'logout') {
          if (hasUnsavedProduction) {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Sign Out?'),
                content: const Text(
                  'Unsaved production changes stay stored locally in your draft for this date.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: ErpTheme.dangerRose,
                    ),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            );
            if (confirm != true) return;
          }
          await authViewModel.logout();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.username,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: ErpTheme.slate900,
                ),
              ),
              Text(
                'Role: ${user.role}',
                style: const TextStyle(fontSize: 12, color: ErpTheme.slate500),
              ),
              const SizedBox(height: 4),
              Text(
                authViewModel.apiBaseUrl,
                style: const TextStyle(fontSize: 10, color: ErpTheme.slate500),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18, color: ErpTheme.dangerRose),
              SizedBox(width: 8),
              Text(
                'Sign Out',
                style: TextStyle(
                  color: ErpTheme.dangerRose,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: ErpTheme.slate100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ErpTheme.slate200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_circle_outlined,
                size: 18,
                color: ErpTheme.slate700,
              ),
              const SizedBox(width: 6),
              Text(
                user.username,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: ErpTheme.slate900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

