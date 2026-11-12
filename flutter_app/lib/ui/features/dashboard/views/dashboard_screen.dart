import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/domain/models/user_session.dart';
import 'package:crackers_erp/ui/features/auth/view_models/auth_view_model.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.authViewModel,
    this.onSelectDocType,
    this.onNavigateOverride,
    super.key,
  });

  final AuthViewModel authViewModel;
  final void Function(String docType)? onSelectDocType;
  final void Function(String path)? onNavigateOverride;

  void _go(BuildContext context, String path, {String? docType}) {
    if (docType != null) {
      onSelectDocType?.call(docType);
    }
    if (onNavigateOverride != null) {
      onNavigateOverride!(path);
    } else {
      context.go(path);
    }
  }

  String _firstSalesRoute(UserAccount user) {
    if (user.isRep) return '/sales-order';
    if (user.canView('billing')) return '/billing';
    if (user.canView('customers')) return '/customers';
    if (user.canView('transporters')) return '/transporters';
    if (user.canView('vehicles')) return '/vehicles';
    return '/billing-history';
  }

  String _firstPurchasesRoute(UserAccount user) {
    if (user.canView('purchase')) return '/purchase';
    if (user.canView('suppliers')) return '/suppliers';
    return '/materials';
  }

  String _firstGodownRoute(UserAccount user) {
    if (user.canView('stock')) return '/stock';
    if (user.canView('transfers')) return '/transfers';
    if (user.canView('godowns')) return '/godowns';
    if (user.canView('products')) return '/products';
    if (user.canView('materials')) return '/materials';
    return '/vehicles';
  }

  String _firstProductionRoute(UserAccount user) {
    if (user.canView('production')) return '/production';
    return '/machines';
  }

  String _firstHrRoute(UserAccount user) {
    if (user.canView('employees')) return '/employees';
    return '/payroll';
  }

  String _firstAdminRoute(UserAccount user) {
    if (user.isAdmin) return '/company-profiles';
    return '/eway-bills';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authViewModel,
      builder: (context, _) {
        final user = authViewModel.currentUser;
        if (user == null) return const SizedBox.shrink();

        final cards = <_DashboardModuleCardData>[
          if (user.showSalesSection)
            _DashboardModuleCardData(
              title: user.isRep ? 'Sales Order' : 'Sales',
              subtitle: user.isRep
                  ? 'Draft a new customer order'
                  : 'Invoices, Estimates & Customers',
              icon: Icons.receipt_long_rounded,
              gradientColors: const [Color(0xFF3B82F6), Color(0xFF4F46E5)],
              shadowColor: const Color(0xFF4F46E5),
              onTap: () => _go(
                context,
                _firstSalesRoute(user),
                docType: 'INV',
              ),
            ),
          if (user.showPurchasesSection)
            _DashboardModuleCardData(
              title: 'Purchases',
              subtitle: 'Inward Stock & Suppliers',
              icon: Icons.shopping_cart_checkout_rounded,
              gradientColors: const [Color(0xFFFB923C), Color(0xFFEF4444)],
              shadowColor: const Color(0xFFEA580C),
              onTap: () => _go(context, _firstPurchasesRoute(user)),
            ),
          if (user.showGodownSection)
            _DashboardModuleCardData(
              title: 'Godown',
              subtitle: 'Inventory, Transfers & Items',
              icon: Icons.warehouse_rounded,
              gradientColors: const [Color(0xFF34D399), Color(0xFF0D9488)],
              shadowColor: const Color(0xFF059669),
              onTap: () => _go(context, _firstGodownRoute(user)),
            ),
          if (user.showProductionSection)
            _DashboardModuleCardData(
              title: 'Production',
              subtitle: 'Factory Output & Processing',
              icon: Icons.precision_manufacturing_rounded,
              gradientColors: const [Color(0xFFFBBF24), Color(0xFFEAB308)],
              shadowColor: const Color(0xFFD97706),
              onTap: () => _go(context, _firstProductionRoute(user)),
            ),
          if (user.showHrSection)
            _DashboardModuleCardData(
              title: 'HR & Payroll',
              subtitle: 'Staff & Salary Management',
              icon: Icons.groups_rounded,
              gradientColors: const [Color(0xFF818CF8), Color(0xFF9333EA)],
              shadowColor: const Color(0xFF7C3AED),
              onTap: () => _go(context, _firstHrRoute(user)),
            ),
          if (user.showAdminSection)
            _DashboardModuleCardData(
              title: 'Admin',
              subtitle: 'Settings & System Tools',
              icon: Icons.admin_panel_settings_rounded,
              gradientColors: const [Color(0xFF475569), Color(0xFF1E293B)],
              shadowColor: const Color(0xFF334155),
              onTap: () => _go(context, _firstAdminRoute(user)),
            ),
        ];

        return Scaffold(
          backgroundColor: ErpTheme.slate50,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: ErpTheme.slate200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_user_rounded,
                                  size: 15,
                                  color: ErpTheme.salesBlue,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${user.username.toUpperCase()} • ${user.role}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: ErpTheme.slate700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => authViewModel.logout(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ErpTheme.dangerRose,
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                color: ErpTheme.dangerRose
                                    .withValues(alpha: 0.25),
                              ),
                              shape: const StadiumBorder(),
                            ),
                            icon: const Icon(Icons.logout_rounded, size: 16),
                            label: const Text('Logout'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Welcome back, ${user.username}!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: ErpTheme.slate900,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Select a module below to begin your work. Your dashboard is customized based on your role access.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ErpTheme.slate500,
                        ),
                      ),
                      if (user.isAdmin) ...[
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          onPressed: () => _go(context, '/pending-orders'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFEF3C7),
                            foregroundColor: const Color(0xFF92400E),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 14,
                            ),
                            side: const BorderSide(color: Color(0xFFFDE68A)),
                          ),
                          icon: const Icon(
                            Icons.notifications_active_rounded,
                            size: 20,
                          ),
                          label: const Text(
                            'Review Pending Sales Orders',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final cols = width >= 940
                              ? 3
                              : (width >= 600 ? 2 : 1);
                          const spacing = 18.0;
                          final cardWidth =
                              (width - spacing * (cols - 1)) / cols;
                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: cards
                                .map(
                                  (data) => SizedBox(
                                    width: cardWidth,
                                    height: 200,
                                    child: _DashboardModuleCard(data: data),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardModuleCardData {
  const _DashboardModuleCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.shadowColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final Color shadowColor;
  final VoidCallback onTap;
}

class _DashboardModuleCard extends StatelessWidget {
  const _DashboardModuleCard({required this.data});

  final _DashboardModuleCardData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: data.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: data.shadowColor.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -12,
                top: -12,
                child: Icon(
                  data.icon,
                  size: 132,
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(data.icon, size: 28, color: Colors.white),
                    ),
                    const Spacer(),
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

