import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/domain/models/packing_dispatch.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/core/erp_crud_widgets.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/features/auth/view_models/auth_view_model.dart';
import 'package:crackers_erp/ui/features/production/view_models/packing_view_model.dart';

class PackingScreen extends StatefulWidget {
  const PackingScreen({
    required this.viewModel,
    required this.authViewModel,
    super.key,
  });

  final PackingViewModel viewModel;
  final AuthViewModel authViewModel;

  @override
  State<PackingScreen> createState() => _PackingScreenState();
}

class _PackingScreenState extends State<PackingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.viewModel.loadSummary();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final vm = widget.viewModel;
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (picked != null) {
      vm.setSelectedDate(picked);
    }
  }

  Future<void> _openInnerBoxSheet(PackingProductStatus product) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => _InnerBoxPackingSheet(
        product: product,
        viewModel: widget.viewModel,
      ),
    );
  }

  Future<void> _openSealCartonsSheet(PackingProductStatus product) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => _SealMasterCartonsSheet(
        product: product,
        viewModel: widget.viewModel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEmbedded = ErpShellScope.isEmbeddedShell(context);
    final dateFmt = DateFormat('dd MMM yyyy');

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;

        return Scaffold(
          backgroundColor: ErpTheme.slate50,
          appBar: isEmbedded
              ? null
              : AppBar(
                  title: const Text('Packing & Master Cartons'),
                  actions: [
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: vm.isLoading ? null : vm.loadSummary,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                    AccountAppBarAction(authViewModel: widget.authViewModel),
                  ],
                ),
          body: Column(
            children: [
              if (isEmbedded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: ErpSectionHeaderBar(
                    title: 'Packing & Master Cartons',
                    subtitle:
                        'Step 2A: Pack Inner Boxes (with carry-forward) → Step 2B: Seal Master Cartons into Factory Ready Stock.',
                    accentColor: ErpTheme.productionAmber,
                    actions: [
                      OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today_rounded, size: 15),
                        label: Text(dateFmt.format(vm.selectedDate)),
                      ),
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: vm.isLoading ? null : vm.loadSummary,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                ),

              // Date bar on mobile + Tabs
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    if (!isEmbedded)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickDate,
                                icon: const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 15,
                                ),
                                label: Text(
                                  'Packing Date: ${dateFmt.format(vm.selectedDate)}',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    TabBar(
                      controller: _tabController,
                      labelColor: ErpTheme.productionAmberDark,
                      unselectedLabelColor: ErpTheme.slate500,
                      indicatorColor: ErpTheme.productionAmber,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                      tabs: const [
                        Tab(text: 'Products & Carry-Forward'),
                        Tab(text: 'Recent Packing Log'),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: ErpTheme.slate200),

              if (vm.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: ErpErrorBanner(
                    message: vm.errorMessage!,
                    onRetry: vm.loadSummary,
                    onDismiss: vm.clearMessages,
                  ),
                ),

              if (vm.successMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: ErpTheme.ordersEmeraldSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ErpTheme.ordersEmerald.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: ErpTheme.ordersEmerald,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            vm.successMessage!,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: ErpTheme.godownTealDark,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: vm.clearMessages,
                          icon: const Icon(Icons.close, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),

              Expanded(
                child: vm.isLoading && vm.summary == null
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildProductsTab(vm),
                          _buildRecentLogTab(vm),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductsTab(PackingViewModel vm) {
    final products = vm.filteredProducts;
    return RefreshIndicator(
      onRefresh: vm.loadSummary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
        children: [
          // KPI Summary Strip
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = constraints.maxWidth >= 600
                  ? (constraints.maxWidth - 16) / 3
                  : (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: tileWidth,
                    child: ErpStatTile(
                      label: 'Factory Cartons',
                      value: '${vm.totalFactoryCartons}',
                      accentColor: ErpTheme.godownTealDark,
                      icon: Icons.warehouse_rounded,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: ErpStatTile(
                      label: 'Loose Inner Boxes',
                      value: '${vm.totalLooseInnerBoxes}',
                      accentColor: ErpTheme.productionAmber,
                      icon: Icons.inventory_2_rounded,
                    ),
                  ),
                  SizedBox(
                    width: constraints.maxWidth >= 600
                        ? tileWidth
                        : constraints.maxWidth,
                    child: ErpStatTile(
                      label: 'Ready to Seal',
                      value: '${vm.totalReadyToSealCartons} Cartons',
                      accentColor: ErpTheme.salesBlueDark,
                      icon: Icons.all_inbox_rounded,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          // Search + Ready-to-Seal filter
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: vm.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Search finished garland (e.g. 1000, Core)...',
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: vm.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              vm.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Ready Only'),
                selected: vm.showOnlyReadyToSeal,
                onSelected: vm.toggleReadyToSealOnly,
                selectedColor: ErpTheme.godownTealSoft,
                visualDensity: VisualDensity.compact,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: vm.showOnlyReadyToSeal
                      ? ErpTheme.godownTealDark
                      : ErpTheme.slate700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Sub-category filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final sub in vm.subCategories)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(sub),
                      selected: vm.selectedSubCategory == sub,
                      onSelected: (_) => vm.setSubCategory(sub),
                      selectedColor: ErpTheme.productionAmberSoft,
                      visualDensity: VisualDensity.compact,
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: vm.selectedSubCategory == sub
                            ? ErpTheme.productionAmberDark
                            : ErpTheme.slate700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: ErpEmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'No Matching Finished Products',
                subtitle: 'Clear filters or search to view all 23 Garland SKUs.',
              ),
            )
          else
            for (final product in products) ...[
              _buildProductCard(product),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  Widget _buildProductCard(PackingProductStatus p) {
    final canSeal = p.readyToSealCartons > 0;
    final otherGodowns = p.godownCartons.entries
        .where(
          (e) =>
              e.value > 0 &&
              e.key.trim().toLowerCase() != 'factory ready stock',
        )
        .toList();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: ErpTheme.slate900,
                            ),
                          ),
                          ErpBadge(
                            label: '${p.boxesPerCase} / Case',
                            backgroundColor: ErpTheme.slate100,
                            foregroundColor: ErpTheme.slate700,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${p.code}${p.subCategory != null ? '  •  ${p.subCategory}' : ''}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: ErpTheme.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ErpBadge(
                      label: 'Factory: ${p.factoryCartons} Ctn',
                      backgroundColor: p.factoryCartons > 0
                          ? ErpTheme.godownTealSoft
                          : ErpTheme.slate100,
                      foregroundColor: p.factoryCartons > 0
                          ? ErpTheme.godownTealDark
                          : ErpTheme.slate500,
                    ),
                    if (otherGodowns.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          otherGodowns
                              .map((e) => '${e.key.split(' ').first}: ${e.value}')
                              .join(' • '),
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: ErpTheme.slate500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Carry-forward loose inner box meter
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ErpTheme.slate50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ErpTheme.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Loose Inner Boxes: ${p.looseInnerBoxes}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: ErpTheme.slate800,
                          ),
                        ),
                      ),
                      if (canSeal)
                        ErpBadge(
                          label: '${p.readyToSealCartons} Cartons Ready',
                          backgroundColor: ErpTheme.salesBlueSoft,
                          foregroundColor: ErpTheme.salesBlueDark,
                        )
                      else
                        Text(
                          '${p.neededForNextCarton} more for 1 carton',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: ErpTheme.slate500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      minHeight: 7,
                      value: canSeal ? 1.0 : p.progressToNextCarton,
                      backgroundColor: ErpTheme.slate200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        canSeal
                            ? ErpTheme.godownTeal
                            : ErpTheme.productionAmber,
                      ),
                    ),
                  ),
                  if (canSeal && p.remainderLooseBoxes > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        'Sealing all ${p.readyToSealCartons} cartons leaves ${p.remainderLooseBoxes} boxes carried forward.',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ErpTheme.slate500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: ValueKey('inner-pack-btn-${p.code}'),
                    onPressed: () => _openInnerBoxSheet(p),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ErpTheme.productionAmberDark,
                      side: BorderSide(
                        color: ErpTheme.productionAmber.withValues(alpha: 0.45),
                      ),
                      minimumSize: const Size(0, 42),
                    ),
                    icon: const Icon(Icons.add_box_outlined, size: 17),
                    label: const Text('+ Inner Pack'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    key: ValueKey('seal-carton-btn-${p.code}'),
                    onPressed: canSeal ? () => _openSealCartonsSheet(p) : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: ErpTheme.godownTealDark,
                      minimumSize: const Size(0, 42),
                    ),
                    icon: const Icon(Icons.all_inbox_rounded, size: 17),
                    label: Text(
                      canSeal
                          ? 'Seal (${p.readyToSealCartons})'
                          : 'Seal Cartons',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLogTab(PackingViewModel vm) {
    final entries = vm.recentEntries;
    final dateFmt = DateFormat('dd MMM yyyy');

    if (entries.isEmpty) {
      return RefreshIndicator(
        onRefresh: vm.loadSummary,
        child: ListView(
          children: const [
            SizedBox(height: 80),
            ErpEmptyState(
              icon: Icons.history_rounded,
              title: 'No Packing Activity Yet',
              subtitle:
                  'Record Inner Box Packing or Seal Master Cartons to see the live trail here.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.loadSummary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (ctx, idx) {
          final e = entries[idx];
          return Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ErpBadge(
                        label: e.isMasterCarton
                            ? 'SEALED CARTONS'
                            : 'INNER PACKED',
                        backgroundColor: e.isMasterCarton
                            ? ErpTheme.godownTealSoft
                            : ErpTheme.productionAmberSoft,
                        foregroundColor: e.isMasterCarton
                            ? ErpTheme.godownTealDark
                            : ErpTheme.productionAmberDark,
                      ),
                      Text(
                        dateFmt.format(e.date),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: ErpTheme.slate500,
                        ),
                      ),
                      Text(
                        '• By ${e.createdBy}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: ErpTheme.slate500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${e.productName} (${e.productCode})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: ErpTheme.slate900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    e.isMasterCarton
                        ? 'Sealed ${e.masterCartonsSealed} Master Cartons (${e.innerBoxesConsumed} boxes @ ${e.boxesPerCase}/case) → ${e.targetGodownName ?? 'Factory Ready Stock'}  •  Loose left: ${e.looseRemainingAfter}'
                        : 'Packed +${e.innerBoxesPacked} inner boxes${e.damagedBoxes > 0 ? ' (${e.damagedBoxes} damaged)' : ''}  •  Loose balance: ${e.looseRemainingAfter}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: ErpTheme.slate700,
                    ),
                  ),
                  if ((e.remarks ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Note: ${e.remarks}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: ErpTheme.slate500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InnerBoxPackingSheet extends StatefulWidget {
  const _InnerBoxPackingSheet({
    required this.product,
    required this.viewModel,
  });

  final PackingProductStatus product;
  final PackingViewModel viewModel;

  @override
  State<_InnerBoxPackingSheet> createState() => _InnerBoxPackingSheetState();
}

class _InnerBoxPackingSheetState extends State<_InnerBoxPackingSheet> {
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _damagedCtrl = TextEditingController(text: '0');
  final TextEditingController _remarksCtrl = TextEditingController();
  bool _autoSeal = false;
  String? _formError;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _damagedCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final vm = widget.viewModel;
    final packed = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    final damaged = int.tryParse(_damagedCtrl.text.trim()) ?? 0;
    final totalLoose = product.looseInnerBoxes + packed;
    final autoCartons = _autoSeal && product.boxesPerCase > 0
        ? totalLoose ~/ product.boxesPerCase
        : 0;
    final leftover = _autoSeal
        ? totalLoose - (autoCartons * product.boxesPerCase)
        : totalLoose;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        14,
        18,
        MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ErpTheme.slate200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: ErpTheme.productionAmberSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.inventory_rounded,
                    color: ErpTheme.productionAmber,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Step 2A: Inner Box Packing',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: ErpTheme.slate900,
                        ),
                      ),
                      Text(
                        '${product.name}  •  ${product.boxesPerCase} Boxes / Master Carton',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ErpTheme.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: ErpTheme.slate50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ErpTheme.slate200),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Loose Boxes: ${product.looseInnerBoxes}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: ErpTheme.slate800,
                    ),
                  ),
                  Text(
                    'Factory Stock: ${product.factoryCartons} Cartons',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ErpTheme.godownTealDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    key: const ValueKey('inner-boxes-qty-field'),
                    controller: _qtyCtrl,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() => _formError = null),
                    decoration: const InputDecoration(
                      labelText: 'Good Inner Boxes Packed *',
                      hintText: 'e.g. 1000',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _damagedCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Damaged',
                      hintText: '0',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SwitchListTile.adaptive(
              key: const ValueKey('auto-seal-cartons-switch'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 6),
              value: _autoSeal,
              onChanged: (v) => setState(() => _autoSeal = v),
              title: const Text(
                'Auto-seal full Master Cartons now',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: ErpTheme.slate900,
                ),
              ),
              subtitle: Text(
                'Automatically converts multiples of ${product.boxesPerCase} boxes into Factory Ready Stock and carries forward leftovers.',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: ErpTheme.slate500,
                ),
              ),
            ),
            if (packed > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _autoSeal && autoCartons > 0
                      ? ErpTheme.godownTealSoft
                      : ErpTheme.productionAmberSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _autoSeal && autoCartons > 0
                        ? ErpTheme.godownTeal.withValues(alpha: 0.35)
                        : ErpTheme.productionAmber.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _autoSeal && autoCartons > 0
                          ? 'Preview: $totalLoose ÷ ${product.boxesPerCase} = $autoCartons Master Cartons + $leftover Loose Boxes'
                          : 'Preview: New Loose Balance = $totalLoose boxes (${totalLoose ~/ product.boxesPerCase} full cartons ready to seal)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: _autoSeal && autoCartons > 0
                            ? ErpTheme.godownTealDark
                            : ErpTheme.productionAmberDark,
                      ),
                    ),
                    if (damaged > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          'Damaged / Rejected recorded: $damaged boxes',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: ErpTheme.dangerRose,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: _remarksCtrl,
              decoration: const InputDecoration(
                labelText: 'Remarks (Optional)',
                hintText: 'Batch / shift note',
              ),
            ),
            if (_formError != null) ...[
              const SizedBox(height: 8),
              Text(
                _formError!,
                style: const TextStyle(
                  color: ErpTheme.dangerRose,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const ValueKey('save-inner-pack-btn'),
              onPressed: vm.isSubmitting
                  ? null
                  : () async {
                      if (packed <= 0) {
                        setState(() {
                          _formError = 'Enter a valid inner box count (> 0).';
                        });
                        return;
                      }
                      final ok = await vm.recordInnerBoxPacking(
                        product: product,
                        innerBoxesPacked: packed,
                        damagedBoxes: damaged,
                        autoSealCartons: _autoSeal,
                        remarks: _remarksCtrl.text,
                      );
                      if (!context.mounted) return;
                      if (ok) {
                        Navigator.of(context).pop();
                      } else {
                        setState(() {
                          _formError = vm.errorMessage ?? 'Could not save.';
                        });
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: ErpTheme.productionAmber,
              ),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: Text(
                _autoSeal && autoCartons > 0
                    ? 'Save & Seal $autoCartons Cartons'
                    : 'Save Inner Box Packing',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SealMasterCartonsSheet extends StatefulWidget {
  const _SealMasterCartonsSheet({
    required this.product,
    required this.viewModel,
  });

  final PackingProductStatus product;
  final PackingViewModel viewModel;

  @override
  State<_SealMasterCartonsSheet> createState() =>
      _SealMasterCartonsSheetState();
}

class _SealMasterCartonsSheetState extends State<_SealMasterCartonsSheet> {
  late final TextEditingController _cartonsCtrl;
  final TextEditingController _remarksCtrl = TextEditingController();
  int? _selectedGodownId;
  String? _formError;

  @override
  void initState() {
    super.initState();
    final maxCartons = widget.product.readyToSealCartons;
    _cartonsCtrl = TextEditingController(
      text: maxCartons > 0 ? '$maxCartons' : '',
    );
    _selectedGodownId = widget.viewModel.factoryGodownId ??
        (widget.viewModel.godowns.isNotEmpty
            ? widget.viewModel.godowns.first.id
            : null);
  }

  @override
  void dispose() {
    _cartonsCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final vm = widget.viewModel;
    final maxCartons = product.readyToSealCartons;
    final cartons = int.tryParse(_cartonsCtrl.text.trim()) ?? 0;
    final consumed = cartons * product.boxesPerCase;
    final leftover = product.looseInnerBoxes - consumed;
    final overLimit = cartons > maxCartons;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        14,
        18,
        MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ErpTheme.slate200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: ErpTheme.godownTealSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.all_inbox_rounded,
                    color: ErpTheme.godownTealDark,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Step 2B: Seal Master Cartons',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: ErpTheme.slate900,
                        ),
                      ),
                      Text(
                        '${product.name}  •  ${product.boxesPerCase} Boxes / Carton',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ErpTheme.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ErpTheme.slate50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ErpTheme.slate200),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 6,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Available Loose: ${product.looseInnerBoxes} boxes',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: ErpTheme.slate800,
                    ),
                  ),
                  ErpBadge(
                    label: 'Max $maxCartons Cartons',
                    backgroundColor: ErpTheme.godownTealSoft,
                    foregroundColor: ErpTheme.godownTealDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('seal-cartons-qty-field'),
              controller: _cartonsCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() => _formError = null),
              decoration: InputDecoration(
                labelText: 'Master Cartons to Seal *',
                helperText:
                    'Each carton consumes ${product.boxesPerCase} inner boxes',
              ),
            ),
            if (vm.godowns.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _selectedGodownId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Receive Into Godown',
                ),
                items: vm.godowns
                    .map(
                      (g) => DropdownMenuItem<int>(
                        value: g.id,
                        child: Text(
                          g.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedGodownId = val),
              ),
            ],
            if (cartons > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: overLimit
                      ? ErpTheme.dangerRoseSoft
                      : ErpTheme.godownTealSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: overLimit
                        ? ErpTheme.dangerRose.withValues(alpha: 0.4)
                        : ErpTheme.godownTeal.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  overLimit
                      ? 'Not enough loose boxes! Need $consumed boxes, available ${product.looseInnerBoxes}.'
                      : 'Consumes $consumed boxes → $leftover loose boxes carried forward.',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: overLimit
                        ? ErpTheme.dangerRose
                        : ErpTheme.godownTealDark,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: _remarksCtrl,
              decoration: const InputDecoration(
                labelText: 'Remarks (Optional)',
                hintText: 'Carton batch / sealing note',
              ),
            ),
            if (_formError != null) ...[
              const SizedBox(height: 8),
              Text(
                _formError!,
                style: const TextStyle(
                  color: ErpTheme.dangerRose,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const ValueKey('confirm-seal-cartons-btn'),
              onPressed: vm.isSubmitting || overLimit
                  ? null
                  : () async {
                      if (cartons <= 0) {
                        setState(() {
                          _formError = 'Enter Master Carton count (> 0).';
                        });
                        return;
                      }
                      final ok = await vm.sealMasterCartons(
                        product: product,
                        masterCartonsSealed: cartons,
                        targetGodownId: _selectedGodownId,
                        remarks: _remarksCtrl.text,
                      );
                      if (!context.mounted) return;
                      if (ok) {
                        Navigator.of(context).pop();
                      } else {
                        setState(() {
                          _formError = vm.errorMessage ?? 'Could not seal.';
                        });
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: ErpTheme.godownTealDark,
              ),
              icon: const Icon(Icons.verified_rounded),
              label: Text(
                cartons > 0
                    ? 'Seal $cartons Master Cartons'
                    : 'Seal Master Cartons',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
