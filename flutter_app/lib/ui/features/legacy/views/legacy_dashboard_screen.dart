import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/core/utils/inr_formatter.dart';
import 'package:crackers_erp/domain/models/json_helpers.dart';
import 'package:crackers_erp/domain/models/legacy.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/features/legacy/view_models/legacy_view_model.dart';
import 'package:crackers_erp/ui/features/masters/views/master_shared_widgets.dart';

class LegacyDashboardScreen extends StatefulWidget {
  const LegacyDashboardScreen({required this.viewModel, super.key});

  final LegacyViewModel viewModel;

  @override
  State<LegacyDashboardScreen> createState() => _LegacyDashboardScreenState();
}

class _LegacyDashboardScreenState extends State<LegacyDashboardScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_syncSearch);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.viewModel.initialize();
    });
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_syncSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _syncSearch() {
    syncMasterController(_searchCtrl, widget.viewModel.searchTerm);
  }

  String _initials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return '?';
    return clean.length >= 2
        ? clean.substring(0, 2).toUpperCase()
        : clean.toUpperCase();
  }

  String _shortDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$d-$m-$y';
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final vm = widget.viewModel;
    final current = isFrom ? vm.dateFrom : vm.dateTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(2024, 1, 1),
      firstDate: DateTime(2005),
      lastDate: DateTime(2030),
    );
    if (picked == null || !mounted) return;
    if (isFrom) {
      vm.setDateFrom(picked);
    } else {
      vm.setDateTo(picked);
    }
  }

  Future<void> _handleExportCsv() async {
    final vm = widget.viewModel;
    final csv = vm.buildCsvForCurrentTab();
    if (csv.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No records available to export.')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied ${vm.totalCount} ${vm.activeTab.title} CSV rows to clipboard.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    return ErpScreenScaffold(
      title: 'Old ERP Portal',
      actions: [
        IconButton(
          onPressed: vm.isLoading ? null : vm.refreshCurrentTab,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh',
        ),
      ],
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          return RefreshIndicator(
            onRefresh: vm.refreshCurrentTab,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPortalHeader(vm),
                const SizedBox(height: 16),
                if (vm.errorMessage != null) ...[
                  ErpErrorBanner(
                    message: vm.errorMessage!,
                    onDismiss: vm.dismissError,
                  ),
                  const SizedBox(height: 14),
                ],
                if (vm.activeTab == LegacyTab.menu)
                  _buildMenuBody(vm)
                else ...[
                  _buildFilterBar(vm),
                  const SizedBox(height: 14),
                  if (vm.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 64),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    _buildResultsSummaryBar(vm),
                    const SizedBox(height: 12),
                    _buildActiveTabContent(vm),
                    if (vm.totalPages > 1) ...[
                      const SizedBox(height: 16),
                      _buildPaginationFooter(vm),
                    ],
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPortalHeader(LegacyViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ErpTheme.slate200),
      ),
      child: Row(
        children: [
          if (vm.activeTab != LegacyTab.menu) ...[
            IconButton.filledTonal(
              onPressed: () => vm.setActiveTab(LegacyTab.menu),
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Back to Portal Menu',
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ErpTheme.slate800,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'LEGACY ARCHIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Text(
                      'READ-ONLY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                        color: ErpTheme.slate400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  vm.activeTab.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: ErpTheme.slate900,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: vm.isLoading ? null : vm.refreshCurrentTab,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload Data',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(LegacyViewModel vm) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 240,
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  suffixIcon: vm.searchTerm.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () => vm.setSearchTerm(''),
                        )
                      : null,
                ),
                onChanged: vm.setSearchTerm,
              ),
            ),
            if (vm.activeTab.hasDateFilter) ...[
              OutlinedButton.icon(
                onPressed: () => _pickDate(isFrom: true),
                icon: const Icon(Icons.date_range_outlined, size: 16),
                label: Text(
                  vm.dateFrom == null ? 'From Date' : _shortDate(vm.dateFrom!),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickDate(isFrom: false),
                icon: const Icon(Icons.event_outlined, size: 16),
                label: Text(
                  vm.dateTo == null ? 'To Date' : _shortDate(vm.dateTo!),
                ),
              ),
              if (vm.dateFrom != null || vm.dateTo != null)
                TextButton(
                  onPressed: vm.clearDates,
                  child: const Text('Clear Dates'),
                ),
            ],
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<LegacySortOption>(
                initialValue: vm.sortBy,
                isDense: true,
                decoration: const InputDecoration(labelText: 'Sort Order'),
                items: LegacySortOption.values.where((opt) {
                  if (!vm.activeTab.hasDateFilter &&
                      (opt == LegacySortOption.dateDesc ||
                          opt == LegacySortOption.dateAsc)) {
                    // Keep newest/oldest order as default fallback
                    return true;
                  }
                  return true;
                }).map((opt) {
                  return DropdownMenuItem(value: opt, child: Text(opt.label));
                }).toList(),
                onChanged: (val) {
                  if (val != null) vm.setSortBy(val);
                },
              ),
            ),
            OutlinedButton.icon(
              onPressed: _handleExportCsv,
              style: OutlinedButton.styleFrom(
                foregroundColor: ErpTheme.ordersEmerald,
                side: BorderSide(
                  color: ErpTheme.ordersEmerald.withValues(alpha: 0.35),
                ),
                backgroundColor: ErpTheme.ordersEmeraldSoft.withValues(
                  alpha: 0.45,
                ),
              ),
              icon: const Icon(Icons.copy_all_outlined, size: 18),
              label: const Text('Copy CSV'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSummaryBar(LegacyViewModel vm) {
    final total = vm.totalCount;
    final start = total == 0
        ? 0
        : (vm.currentPage - 1) * LegacyViewModel.itemsPerPage + 1;
    final end = (vm.currentPage * LegacyViewModel.itemsPerPage).clamp(0, total);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Text(
          'Showing $start - $end of $total records',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: ErpTheme.slate500,
          ),
        ),
        if (vm.totalPages > 1)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: vm.currentPage > 1
                    ? () => vm.setCurrentPage(vm.currentPage - 1)
                    : null,
                child: const Text('Prev'),
              ),
              const SizedBox(width: 8),
              Text(
                '${vm.currentPage} / ${vm.totalPages}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: ErpTheme.slate700,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: vm.currentPage < vm.totalPages
                    ? () => vm.setCurrentPage(vm.currentPage + 1)
                    : null,
                child: const Text('Next'),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPaginationFooter(LegacyViewModel vm) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ErpTheme.slate200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: vm.currentPage > 1 ? () => vm.setCurrentPage(1) : null,
              icon: const Icon(Icons.first_page),
            ),
            IconButton(
              onPressed: vm.currentPage > 1
                  ? () => vm.setCurrentPage(vm.currentPage - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Page ${vm.currentPage} of ${vm.totalPages}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: ErpTheme.slate800,
                ),
              ),
            ),
            IconButton(
              onPressed: vm.currentPage < vm.totalPages
                  ? () => vm.setCurrentPage(vm.currentPage + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
            IconButton(
              onPressed: vm.currentPage < vm.totalPages
                  ? () => vm.setCurrentPage(vm.totalPages)
                  : null,
              icon: const Icon(Icons.last_page),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuBody(LegacyViewModel vm) {
    final analytics = vm.analytics;
    if (vm.isLoading && analytics == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (analytics != null) ...[
          const Text(
            'HISTORICAL FINANCIAL OVERVIEW',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: ErpTheme.slate500,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 980
                  ? 4
                  : constraints.maxWidth >= 560
                  ? 2
                  : 1;
              const spacing = 12.0;
              final w = (constraints.maxWidth - spacing * (cols - 1)) / cols;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: w,
                    child: _GradientKpiCard(
                      title: 'TOTAL SALES (ESTIMATES)',
                      value: formatInr(
                        analytics.totalEstimates,
                        decimals: false,
                      ),
                      subtitle:
                          '${formatIndianCount(analytics.estimatesCount)} historical bills',
                      colors: const [Color(0xFF6366F1), Color(0xFF4338CA)],
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: _GradientKpiCard(
                      title: 'TOTAL PURCHASES',
                      value: formatInr(
                        analytics.totalPurchases,
                        decimals: false,
                      ),
                      subtitle:
                          '${formatIndianCount(analytics.purchasesCount)} inward bills',
                      colors: const [Color(0xFF10B981), Color(0xFF047857)],
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: _GradientKpiCard(
                      title: 'TOTAL FACTORY WAGES',
                      value: formatInr(analytics.totalWages, decimals: false),
                      subtitle:
                          '${formatIndianCount(analytics.workentriesCount)} production logs',
                      colors: const [Color(0xFFF59E0B), Color(0xFFB45309)],
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: _GradientKpiCard(
                      title: 'TOTAL PAYMENTS SENT',
                      value: formatInr(
                        analytics.totalPayments,
                        decimals: false,
                      ),
                      subtitle:
                          '${formatIndianCount(analytics.suppliersCount)} total suppliers',
                      colors: const [Color(0xFF06B6D4), Color(0xFF0E7490)],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
        ],
        if (vm.trendProducts.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Raw Material Price Trends',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: ErpTheme.slate900,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Track historical purchase price inflation for any item',
                            style: TextStyle(
                              fontSize: 12,
                              color: ErpTheme.slate500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: 280,
                        child: DropdownButtonFormField<String>(
                          initialValue: vm.selectedProduct.isEmpty
                              ? ''
                              : vm.selectedProduct,
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('-- Select Material to Analyze --'),
                            ),
                            ...vm.trendProducts.map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(
                                  p,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) => vm.selectTrendProduct(val ?? ''),
                        ),
                      ),
                    ],
                  ),
                  if (vm.selectedProduct.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    if (vm.isTrendsLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (vm.priceTrends.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No purchase history found for this item.',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: ErpTheme.slate400,
                            ),
                          ),
                        ),
                      )
                    else
                      _PriceTrendsList(trends: vm.priceTrends),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
        ],
        const Text(
          'BILLING & ACCOUNTS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: ErpTheme.slate500,
          ),
        ),
        const SizedBox(height: 10),
        _buildModuleLaunchGrid([
          _LegacyModuleTileData(
            title: 'Estimates',
            subtitle: 'Historical sales & quotes',
            icon: Icons.description_outlined,
            color: ErpTheme.hrIndigo,
            bgColor: ErpTheme.hrIndigoSoft,
            tab: LegacyTab.estimates,
          ),
          _LegacyModuleTileData(
            title: 'Purchases',
            subtitle: 'Historical inward bills',
            icon: Icons.fact_check_outlined,
            color: ErpTheme.ordersEmerald,
            bgColor: ErpTheme.ordersEmeraldSoft,
            tab: LegacyTab.purchases,
          ),
          _LegacyModuleTileData(
            title: 'Payments',
            subtitle: 'Vouchers & ledgers',
            icon: Icons.payments_outlined,
            color: const Color(0xFF0891B2),
            bgColor: const Color(0xFFECFEFF),
            tab: LegacyTab.payments,
          ),
          _LegacyModuleTileData(
            title: 'Profiles',
            subtitle: 'Customers & Suppliers',
            icon: Icons.groups_outlined,
            color: ErpTheme.salesBlue,
            bgColor: ErpTheme.salesBlueSoft,
            tab: LegacyTab.customers,
          ),
        ]),
        const SizedBox(height: 22),
        const Text(
          'PAYROLL & FACTORY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: ErpTheme.slate500,
          ),
        ),
        const SizedBox(height: 10),
        _buildModuleLaunchGrid([
          _LegacyModuleTileData(
            title: 'Employees',
            subtitle: 'Historical staff directory',
            icon: Icons.badge_outlined,
            color: ErpTheme.dangerRose,
            bgColor: ErpTheme.dangerRoseSoft,
            tab: LegacyTab.employees,
          ),
          _LegacyModuleTileData(
            title: 'Work Logs',
            subtitle: 'Daily production & wages',
            icon: Icons.assignment_outlined,
            color: ErpTheme.productionAmber,
            bgColor: ErpTheme.productionAmberSoft,
            tab: LegacyTab.workentries,
          ),
        ]),
      ],
    );
  }

  Widget _buildModuleLaunchGrid(List<_LegacyModuleTileData> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 980
            ? 4
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        const spacing = 12.0;
        final w = (constraints.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map(
                (item) => SizedBox(
                  width: w,
                  child: Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => widget.viewModel.setActiveTab(item.tab),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: item.bgColor,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(item.icon, color: item.color),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: ErpTheme.slate900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.subtitle,
                              style: const TextStyle(
                                fontSize: 13,
                                color: ErpTheme.slate500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildActiveTabContent(LegacyViewModel vm) {
    final rows = vm.pagedRecords;
    switch (vm.activeTab) {
      case LegacyTab.customers:
      case LegacyTab.suppliers:
        final isCust = vm.activeTab == LegacyTab.customers;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Customers'),
                  selected: isCust,
                  onSelected: (_) => vm.setActiveTab(LegacyTab.customers),
                ),
                ChoiceChip(
                  label: const Text('Suppliers'),
                  selected: !isCust,
                  onSelected: (_) => vm.setActiveTab(LegacyTab.suppliers),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (rows.isEmpty)
              const ErpEmptyState(
                icon: Icons.groups_outlined,
                title: 'No Records Found',
                subtitle: 'Try clearing search filters.',
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final cols = constraints.maxWidth >= 980
                      ? 3
                      : constraints.maxWidth >= 600
                      ? 2
                      : 1;
                  const spacing = 12.0;
                  final w =
                      (constraints.maxWidth - spacing * (cols - 1)) / cols;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: rows.map((p) {
                      final name =
                          '${isCust ? p['Customername'] : p['Suppliername'] ?? ''}'
                              .trim();
                      final idStr =
                          '${isCust ? p['CustomerID'] : p['SupplierID'] ?? ''}';
                      final fullAddress = [
                        p['Address1'],
                        p['Address2'],
                        p['Address3'],
                      ].where((e) => e != null && '$e'.trim().isNotEmpty).join(', ');
                      final contacts = [
                        p['Contactnumber'],
                        p['Contactnumber2'],
                      ].where((e) => e != null && '$e'.trim().isNotEmpty).join(' / ');
                      final emailOrWa = '${p['Email'] ?? p['Whatsapp'] ?? ''}'
                          .trim();
                      final bal = parseDouble(p['Openingbalance']);
                      final isActive =
                          '${p['Status'] ?? ''}'.toLowerCase() == 'active';

                      return SizedBox(
                        width: w,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: isCust
                                            ? ErpTheme.salesBlueSoft
                                            : const Color(0xFFF3E8FF),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        _initials(name),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          color: isCust
                                              ? ErpTheme.salesBlueDark
                                              : ErpTheme.hrPurpleDark,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name.isEmpty ? 'Unknown' : name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: ErpTheme.slate900,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              ErpBadge(
                                                label: 'ID: $idStr',
                                                backgroundColor:
                                                    ErpTheme.slate100,
                                                foregroundColor:
                                                    ErpTheme.slate700,
                                              ),
                                              if (isActive) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: ErpTheme
                                                            .ordersEmerald,
                                                        shape: BoxShape.circle,
                                                      ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: ErpTheme.slate400,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        fullAddress.isEmpty
                                            ? 'No address provided'
                                            : fullAddress,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: ErpTheme.slate700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone_outlined,
                                      size: 16,
                                      color: ErpTheme.slate400,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        contacts.isEmpty ? '-' : contacts,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: ErpTheme.slate700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (emailOrWa.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.mail_outline,
                                        size: 16,
                                        color: ErpTheme.slate400,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          emailOrWa,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: ErpTheme.slate700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'OPENING BAL',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: ErpTheme.slate400,
                                      ),
                                    ),
                                    Text(
                                      formatInr(bal),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: ErpTheme.slate900,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
          ],
        );

      case LegacyTab.employees:
        if (rows.isEmpty) {
          return const ErpEmptyState(
            icon: Icons.badge_outlined,
            title: 'No Employees Found',
            subtitle: 'Try adjusting the search query.',
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth >= 980
                ? 4
                : constraints.maxWidth >= 560
                ? 2
                : 1;
            const spacing = 12.0;
            final w = (constraints.maxWidth - spacing * (cols - 1)) / cols;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: rows.map((e) {
                final name = '${e['EmployeeName'] ?? ''}'.trim();
                final active = '${e['Status'] ?? ''}'.toLowerCase() == 'active';
                return SizedBox(
                  width: w,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: ErpTheme.dangerRoseSoft,
                                child: Text(
                                  _initials(name),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: ErpTheme.dangerRose,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 2,
                                bottom: 2,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: active
                                        ? ErpTheme.ordersEmerald
                                        : ErpTheme.slate400,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            name.isEmpty ? 'Unknown' : name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: ErpTheme.slate900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ErpBadge(
                            label: 'EMP ID: ${e['EmployeeID'] ?? '-'}',
                            backgroundColor: ErpTheme.slate100,
                            foregroundColor: ErpTheme.slate700,
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'City',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ErpTheme.slate400,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${e['City'] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: ErpTheme.slate800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );

      case LegacyTab.payments:
        if (rows.isEmpty) {
          return const ErpEmptyState(
            icon: Icons.payments_outlined,
            title: 'No Payments Found',
            subtitle: 'Try adjusting filters or date range.',
          );
        }
        return Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: ErpTheme.slate100),
            itemBuilder: (context, idx) {
              final p = rows[idx];
              final supName = '${p['SupplierNameStr'] ?? 'Supplier'}';
              final method = '${p['Paymenttype'] ?? 'Cash'}';
              final amt = parseDouble(p['Paymentamount']);
              return Padding(
                padding: const EdgeInsets.all(14),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: ErpTheme.slate100,
                          child: Text(
                            _initials(supName),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: ErpTheme.slate700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              supName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: ErpTheme.slate900,
                              ),
                            ),
                            Text(
                              '${p['Paymentdate'] ?? '-'} • Ref: ${p['Invoiceno'] ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: ErpTheme.slate500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ErpBadge(
                          label: method,
                          backgroundColor: const Color(0xFFECFEFF),
                          foregroundColor: const Color(0xFF0E7490),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          formatInr(amt),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0891B2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );

      case LegacyTab.estimates:
        if (rows.isEmpty) {
          return const ErpEmptyState(
            icon: Icons.description_outlined,
            title: 'No Estimates Found',
            subtitle: 'Try adjusting filters or date range.',
          );
        }
        return Column(
          children: rows.map((e) {
            final salesId = parseInt(e['SalesID']);
            final expanded = vm.expandedEstimateId == salesId;
            final details = vm.estimateDetailsFor(salesId);
            final net = parseDouble(e['Netamount']);
            final particulars = details?['particulars'] is List
                ? (details!['particulars'] as List)
                      .whereType<Map<String, dynamic>>()
                      .toList()
                : const <Map<String, dynamic>>[];
            final charges = details?['charges'] is List
                ? (details!['charges'] as List)
                      .whereType<Map<String, dynamic>>()
                      .toList()
                : const <Map<String, dynamic>>[];

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => vm.toggleEstimateExpand(salesId),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${e['CustomerName'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: ErpTheme.slate900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${e['Salesdate'] ?? '-'} • Est #$salesId',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: ErpTheme.slate500,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ErpBadge(
                                label: '${e['Salestype'] ?? 'EST'}',
                                backgroundColor: ErpTheme.slate100,
                                foregroundColor: ErpTheme.slate700,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                formatInr(net),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: ErpTheme.hrIndigo,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                expanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: ErpTheme.slate500,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (expanded)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: ErpTheme.slate50,
                        border: Border(
                          top: BorderSide(color: ErpTheme.slate200),
                        ),
                      ),
                      child: vm.isDetailsLoading && !vm.hasEstimateDetails(salesId)
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'LINE ITEMS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: ErpTheme.slate500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (particulars.isEmpty)
                                  const Text(
                                    'No line items found.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ErpTheme.slate400,
                                    ),
                                  )
                                else
                                  ...particulars.map((item) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: ErpTheme.slate200,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${item['Productname'] ?? ''}',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: ErpTheme.slate900,
                                                  ),
                                                ),
                                                Text(
                                                  'Qty: ${item['Quantity']} × ${formatInr(parseDouble(item['Salesrate']))}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: ErpTheme.slate500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            formatInr(
                                              parseDouble(item['Totalamount']),
                                            ),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                              color: ErpTheme.hrIndigo,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                if (charges.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  const Text(
                                    'CHARGES & SUMMARY',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: ErpTheme.slate500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ...charges.map(
                                    (c) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${c['ChargeName'] ?? ''}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: ErpTheme.slate700,
                                            ),
                                          ),
                                          Text(
                                            formatInr(
                                              parseDouble(c['ChargeAmount2']),
                                            ),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                ],
              ),
            );
          }).toList(),
        );

      case LegacyTab.purchases:
        if (rows.isEmpty) {
          return const ErpEmptyState(
            icon: Icons.fact_check_outlined,
            title: 'No Purchases Found',
            subtitle: 'Try adjusting filters or date range.',
          );
        }
        return Column(
          children: rows.map((p) {
            final purchaseId = parseInt(p['PurchaseID']);
            final expanded = vm.expandedPurchaseId == purchaseId;
            final items = vm.purchaseItemsFor(purchaseId);
            final charges = vm.purchaseChargesFor(purchaseId);
            final net = parseDouble(p['Netamount']);

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => vm.togglePurchaseExpand(purchaseId),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${p['Suppliername'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: ErpTheme.slate900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${p['Purchasedate'] ?? '-'} • Inv: ${p['Invoiceno'] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: ErpTheme.slate500,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ErpBadge(
                                label: '${p['Purchasetype'] ?? 'PUR'}',
                                backgroundColor: ErpTheme.slate100,
                                foregroundColor: ErpTheme.slate700,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                formatInr(net),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: ErpTheme.ordersEmerald,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                expanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: ErpTheme.slate500,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (expanded)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: ErpTheme.slate50,
                        border: Border(
                          top: BorderSide(color: ErpTheme.slate200),
                        ),
                      ),
                      child:
                          vm.isDetailsLoading && !vm.hasPurchaseDetails(purchaseId)
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'PURCHASED ITEMS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: ErpTheme.slate500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (items.isEmpty)
                                  const Text(
                                    'No items found.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ErpTheme.slate400,
                                    ),
                                  )
                                else
                                  ...items.map((item) {
                                    final hsn = '${item['HSNCode'] ?? ''}'.trim();
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: ErpTheme.slate200,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${item['Productname'] ?? ''}',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: ErpTheme.slate900,
                                                  ),
                                                ),
                                                if (hsn.isNotEmpty)
                                                  Text(
                                                    'HSN: $hsn',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: ErpTheme.slate400,
                                                    ),
                                                  ),
                                                Text(
                                                  'Qty: ${item['Qty']} ${item['UOM'] ?? ''} × ${formatInr(parseDouble(item['Purchaserate']))}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: ErpTheme.slate500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            formatInr(
                                              parseDouble(item['TotalAmount']),
                                            ),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                              color: ErpTheme.ordersEmerald,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                if (charges.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  const Text(
                                    'CHARGES & SUMMARY',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: ErpTheme.slate500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ...charges.map(
                                    (c) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${c['ChargeName'] ?? ''}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: ErpTheme.slate700,
                                            ),
                                          ),
                                          Text(
                                            formatInr(
                                              parseDouble(c['ChargeAmount2']),
                                            ),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                ],
              ),
            );
          }).toList(),
        );

      case LegacyTab.workentries:
        if (rows.isEmpty) {
          return const ErpEmptyState(
            icon: Icons.assignment_outlined,
            title: 'No Work Logs Found',
            subtitle: 'Try adjusting filters or date range.',
          );
        }
        return Column(
          children: rows.map((w) {
            final workId = parseInt(w['ID']);
            final expanded = vm.expandedWorkId == workId;
            final items = vm.workItemsFor(workId);
            final adv = parseDouble(w['AdvanceReceive']);
            final net = parseDouble(w['Netamount']);

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => vm.toggleWorkExpand(workId),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${w['EmployeeName'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: ErpTheme.slate900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${w['Workerdate'] ?? '-'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: ErpTheme.slate500,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (adv > 0) ...[
                                ErpBadge(
                                  label: 'Adv: ${formatInr(adv)}',
                                  backgroundColor: ErpTheme.dangerRoseSoft,
                                  foregroundColor: ErpTheme.dangerRose,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                formatInr(net),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: ErpTheme.productionAmberDark,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                expanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: ErpTheme.slate500,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (expanded)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: ErpTheme.slate50,
                        border: Border(
                          top: BorderSide(color: ErpTheme.slate200),
                        ),
                      ),
                      child: vm.isDetailsLoading && !vm.hasWorkDetails(workId)
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'DETAILED PRODUCTION LOG',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: ErpTheme.slate500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (items.isEmpty)
                                  const Text(
                                    'No piece-rate items recorded.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ErpTheme.slate400,
                                    ),
                                  )
                                else
                                  ...items.map(
                                    (item) => Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: ErpTheme.slate200,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${item['ProductName'] ?? ''}',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: ErpTheme.slate900,
                                                  ),
                                                ),
                                                Text(
                                                  'Qty: ${item['Qty']} × ${formatInr(parseDouble(item['Rate']))}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: ErpTheme.slate500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            formatInr(
                                              parseDouble(item['Netamount']),
                                            ),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                              color:
                                                  ErpTheme.productionAmberDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                ],
              ),
            );
          }).toList(),
        );

      case LegacyTab.menu:
        return const SizedBox.shrink();
    }
  }
}

class _GradientKpiCard extends StatelessWidget {
  const _GradientKpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.colors,
  });

  final String title;
  final String value;
  final String subtitle;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceTrendsList extends StatelessWidget {
  const _PriceTrendsList({required this.trends});

  final List<PriceTrendPoint> trends;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ErpTheme.slate200),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: trends.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: ErpTheme.slate100),
        itemBuilder: (context, idx) {
          final point = trends[idx];
          final pct = point.pctChange;
          final color = pct > 0
              ? ErpTheme.dangerRose
              : pct < 0
              ? ErpTheme.ordersEmerald
              : ErpTheme.slate400;
          final arrow = pct > 0 ? '↑' : (pct < 0 ? '↓' : '-');
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        point.date,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: ErpTheme.slate800,
                        ),
                      ),
                      Text(
                        'Qty: ${point.qty}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: ErpTheme.slate500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatInr(point.rate),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: ErpTheme.slate900,
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 72,
                  child: Text(
                    pct == 0 ? '-' : '$arrow ${pct.abs().toStringAsFixed(1)}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LegacyModuleTileData {
  const _LegacyModuleTileData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.tab,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final LegacyTab tab;
}

