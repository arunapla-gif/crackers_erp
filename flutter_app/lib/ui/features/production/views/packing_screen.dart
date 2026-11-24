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
    _tabController = TabController(length: 3, vsync: this);
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

  Future<void> _openInnerBoxSheet(TapeWipPackingItem tapeItem) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => _InnerBoxPackingSheet(
        tapeItem: tapeItem,
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
        final pendingTapeCount = vm.pendingTapeItems.length;
        final looseStylesCount = vm.looseMasterCartonQueue.length;

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
                        '1. Tape Production Output → 2. Pack Into Inner Box Style → 3. Seal Master Cartons.',
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

              // Date bar on mobile + 3-Step Tabs
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
                      key: const ValueKey('packing-tabs'),
                      controller: _tabController,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                      labelColor: ErpTheme.productionAmberDark,
                      unselectedLabelColor: ErpTheme.slate500,
                      indicatorColor: ErpTheme.productionAmber,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                      tabs: [
                        Tab(text: 'Inner Pack ($pendingTapeCount)'),
                        Tab(text: 'Cartons ($looseStylesCount)'),
                        const Tab(text: 'Stock & Log'),
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
                          _buildInnerPackingQueueTab(vm),
                          _buildMasterCartonQueueTab(vm),
                          _buildReadyStockAndLogTab(vm),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiStrip(PackingViewModel vm) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 720 ? 4 : 2;
        final tileWidth = (constraints.maxWidth - (cols - 1) * 8) / cols;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: tileWidth,
              child: ErpStatTile(
                label: 'Unpacked Tape',
                value: '${vm.totalUnpackedTapeUnits}',
                accentColor: ErpTheme.productionAmberDark,
                icon: Icons.precision_manufacturing_rounded,
              ),
            ),
            SizedBox(
              width: tileWidth,
              child: ErpStatTile(
                label: 'Loose Inner Boxes',
                value: '${vm.totalLooseInnerBoxes}',
                accentColor: ErpTheme.hrIndigo,
                icon: Icons.inventory_2_rounded,
              ),
            ),
            SizedBox(
              width: tileWidth,
              child: ErpStatTile(
                label: 'Ready to Seal',
                value: '${vm.totalReadyToSealCartons} Ctn',
                accentColor: ErpTheme.salesBlueDark,
                icon: Icons.all_inbox_rounded,
              ),
            ),
            SizedBox(
              width: tileWidth,
              child: ErpStatTile(
                label: 'Factory Cartons',
                value: '${vm.totalFactoryCartons}',
                accentColor: ErpTheme.godownTealDark,
                icon: Icons.warehouse_rounded,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterControls(
    PackingViewModel vm, {
    bool includeReadyToggle = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: vm.setSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search item or style (e.g. 400, 800, Core)...',
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
            if (includeReadyToggle) ...[
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Full Cartons Only'),
                selected: vm.showOnlyReadyToSeal,
                onSelected: vm.toggleReadyToSealOnly,
                selectedColor: ErpTheme.godownTealSoft,
                visualDensity: VisualDensity.compact,
                labelStyle: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: vm.showOnlyReadyToSeal
                      ? ErpTheme.godownTealDark
                      : ErpTheme.slate700,
                ),
              ),
            ],
          ],
        ),
        if (vm.subCategories.length > 1) ...[
          const SizedBox(height: 8),
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
        ],
      ],
    );
  }

  Widget _buildInnerPackingQueueTab(PackingViewModel vm) {
    final pendingItems = vm.pendingTapeItems;
    return RefreshIndicator(
      onRefresh: vm.loadSummary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
        children: [
          _buildKpiStrip(vm),
          const SizedBox(height: 12),
          _buildFilterControls(vm),
          const SizedBox(height: 10),
          if (pendingItems.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 36),
              child: ErpEmptyState(
                icon: Icons.precision_manufacturing_outlined,
                title: 'No Unpacked Tape Production',
                subtitle:
                    'Items appear here automatically as soon as Tape department entries are saved in Daily Production.',
              ),
            )
          else
            for (final tapeItem in pendingItems) ...[
              _buildTapeQueueCard(tapeItem),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  Widget _buildTapeQueueCard(TapeWipPackingItem item) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            item.wipName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: ErpTheme.slate900,
                            ),
                          ),
                          if (item.subCategory != null)
                            ErpBadge(
                              label: item.subCategory!,
                              backgroundColor: ErpTheme.productionAmberSoft,
                              foregroundColor: ErpTheme.productionAmberDark,
                            ),
                          ErpBadge(
                            label: 'TAPE OUTPUT',
                            backgroundColor: ErpTheme.slate100,
                            foregroundColor: ErpTheme.slate700,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tape Produced: ${item.totalProducedUnits}  •  Already Packed: ${item.totalPackedUnits}'
                        '${item.totalDamagedUnits > 0 ? '  •  Damaged: ${item.totalDamagedUnits}' : ''}',
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: ErpTheme.ordersEmeraldSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: ErpTheme.ordersEmerald.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.unpackedUnits}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: ErpTheme.godownTealDark,
                        ),
                      ),
                      const Text(
                        'Ready to Box',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: ErpTheme.godownTealDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.styleOptions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ErpTheme.slate50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ErpTheme.slate200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.styleOptions.length > 1
                          ? 'Can be packed into ${item.styleOptions.length} Box Styles:'
                          : 'Packing Box Style:',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: ErpTheme.slate500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final s in item.styleOptions)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: ErpTheme.slate200),
                            ),
                            child: Text(
                              '${s.name} (${s.boxesPerCase}/case)',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: ErpTheme.slate800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            FilledButton.icon(
              key: ValueKey('inner-pack-wip-${item.wipName}'),
              onPressed: item.styleOptions.isEmpty
                  ? null
                  : () => _openInnerBoxSheet(item),
              style: FilledButton.styleFrom(
                backgroundColor: ErpTheme.productionAmber,
                minimumSize: const Size(0, 44),
              ),
              icon: const Icon(Icons.inventory_rounded, size: 18),
              label: Text(
                item.styleOptions.length > 1
                    ? 'Choose Style & Pack Inner Boxes'
                    : 'Pack Into ${item.styleOptions.first.name}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterCartonQueueTab(PackingViewModel vm) {
    final queue = vm.looseMasterCartonQueue;
    return RefreshIndicator(
      onRefresh: vm.loadSummary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
        children: [
          _buildKpiStrip(vm),
          const SizedBox(height: 12),
          _buildFilterControls(vm, includeReadyToggle: true),
          const SizedBox(height: 10),
          if (queue.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 36),
              child: ErpEmptyState(
                icon: Icons.all_inbox_outlined,
                title: 'No Loose Inner Boxes in Queue',
                subtitle:
                    'Pack produced Tape items in Tab 1 (Inner Packing) first — packed inner boxes will appear here for Master Carton sealing.',
              ),
            )
          else
            for (final product in queue) ...[
              _buildMasterCartonCard(product),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  Widget _buildMasterCartonCard(PackingProductStatus p) {
    final canSeal = p.readyToSealCartons > 0;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              fontSize: 15.5,
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
                        '${p.wipName != null ? 'From Tape ${p.wipName}  •  ' : ''}${p.subCategory ?? p.code}',
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
                ErpBadge(
                  label: 'Factory: ${p.factoryCartons} Ctn',
                  backgroundColor: p.factoryCartons > 0
                      ? ErpTheme.godownTealSoft
                      : ErpTheme.slate100,
                  foregroundColor: p.factoryCartons > 0
                      ? ErpTheme.godownTealDark
                      : ErpTheme.slate500,
                ),
              ],
            ),
            const SizedBox(height: 10),
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Loose Inner Boxes: ${p.looseInnerBoxes}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: ErpTheme.slate800,
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
                          'Carry-forward (${p.neededForNextCarton} more for 1 carton)',
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
                        'Sealing ${p.readyToSealCartons} cartons leaves ${p.remainderLooseBoxes} loose boxes carried forward.',
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
            FilledButton.icon(
              key: ValueKey('seal-carton-btn-${p.code}'),
              onPressed: canSeal ? () => _openSealCartonsSheet(p) : null,
              style: FilledButton.styleFrom(
                backgroundColor: ErpTheme.godownTealDark,
                minimumSize: const Size(0, 42),
              ),
              icon: const Icon(Icons.all_inbox_rounded, size: 17),
              label: Text(
                canSeal
                    ? 'Seal ${p.readyToSealCartons} Master Cartons'
                    : 'Waiting for ${p.neededForNextCarton} More Boxes',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadyStockAndLogTab(PackingViewModel vm) {
    final readyStock = vm.readyStockProducts;
    final entries = vm.recentEntries;
    final dateFmt = DateFormat('dd MMM yyyy');

    return RefreshIndicator(
      onRefresh: vm.loadSummary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
        children: [
          const Text(
            'Sealed Master Cartons in Stock',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: ErpTheme.slate900,
            ),
          ),
          const SizedBox(height: 8),
          if (readyStock.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ErpTheme.slate200),
              ),
              child: const Text(
                'No sealed Master Cartons in stock yet.',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: ErpTheme.slate500,
                ),
              ),
            )
          else
            for (final p in readyStock)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: ErpTheme.slate900,
                              ),
                            ),
                            Text(
                              '${p.boxesPerCase} boxes/case  •  ${p.godownCartons.entries.where((e) => e.value > 0).map((e) => '${e.key}: ${e.value}').join(' • ')}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: ErpTheme.slate500,
                              ),
                            ),
                          ],
                        ),
                        ErpBadge(
                          label: 'Factory Ready: ${p.factoryCartons} Ctn',
                          backgroundColor: ErpTheme.godownTealSoft,
                          foregroundColor: ErpTheme.godownTealDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 16),
          const Text(
            'Recent Packing Activity Log',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: ErpTheme.slate900,
            ),
          ),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: ErpEmptyState(
                icon: Icons.history_rounded,
                title: 'No Packing Activity Yet',
                subtitle:
                    'Inner box packing and Master Carton sealing entries will appear here.',
              ),
            )
          else
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
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
                          '${e.wipName != null && !e.isMasterCarton ? 'Tape ${e.wipName} → ' : ''}${e.productName} (${e.productCode})',
                          style: const TextStyle(
                            fontSize: 13.5,
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
                ),
              ),
        ],
      ),
    );
  }
}

class _InnerBoxPackingSheet extends StatefulWidget {
  const _InnerBoxPackingSheet({
    required this.tapeItem,
    required this.viewModel,
  });

  final TapeWipPackingItem tapeItem;
  final PackingViewModel viewModel;

  @override
  State<_InnerBoxPackingSheet> createState() => _InnerBoxPackingSheetState();
}

class _InnerBoxPackingSheetState extends State<_InnerBoxPackingSheet> {
  late int _selectedStyleId;
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _damagedCtrl = TextEditingController(text: '0');
  final TextEditingController _remarksCtrl = TextEditingController();
  bool _autoSeal = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _selectedStyleId = widget.tapeItem.styleOptions.first.id;
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _damagedCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  PackingStyleOption get _selectedStyle => widget.tapeItem.styleOptions
      .firstWhere((s) => s.id == _selectedStyleId);

  @override
  Widget build(BuildContext context) {
    final tape = widget.tapeItem;
    final vm = widget.viewModel;
    final style = _selectedStyle;

    final packed = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    final damaged = int.tryParse(_damagedCtrl.text.trim()) ?? 0;
    final totalFromTape = packed + damaged;
    final exceedsTape = totalFromTape > tape.unpackedUnits;

    final totalLoose = style.looseInnerBoxes + packed;
    final autoCartons = _autoSeal && style.boxesPerCase > 0
        ? totalLoose ~/ style.boxesPerCase
        : 0;
    final leftover = _autoSeal
        ? totalLoose - (autoCartons * style.boxesPerCase)
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
                      Text(
                        'Pack Tape Item: ${tape.wipName}',
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          color: ErpTheme.slate900,
                        ),
                      ),
                      Text(
                        'Available from Tape Production: ${tape.unpackedUnits} units (1 unit = 1 box)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ErpTheme.godownTealDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 1. Style / Box Type Selector
            Text(
              tape.styleOptions.length > 1
                  ? '1. Choose Packing Style / Box Type *'
                  : 'Packing Style / Box Type',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: ErpTheme.slate800,
              ),
            ),
            const SizedBox(height: 6),
            for (final opt in tape.styleOptions)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  key: ValueKey('style-option-${opt.code}'),
                  onTap: () => setState(() => _selectedStyleId = opt.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: opt.id == _selectedStyleId
                          ? ErpTheme.productionAmberSoft
                          : ErpTheme.slate50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: opt.id == _selectedStyleId
                            ? ErpTheme.productionAmber
                            : ErpTheme.slate200,
                        width: opt.id == _selectedStyleId ? 1.6 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          opt.id == _selectedStyleId
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          size: 18,
                          color: opt.id == _selectedStyleId
                              ? ErpTheme.productionAmberDark
                              : ErpTheme.slate500,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                opt.name,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: ErpTheme.slate900,
                                ),
                              ),
                              Text(
                                '${opt.boxesPerCase} Boxes / Master Carton  •  Loose Balance: ${opt.looseInnerBoxes}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: ErpTheme.slate500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  '2. Enter Inner Boxes Packed',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: ErpTheme.slate800,
                  ),
                ),
                ActionChip(
                  key: const ValueKey('pack-all-available-chip'),
                  label: Text('Pack All (${tape.unpackedUnits})'),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    setState(() {
                      _qtyCtrl.text = '${tape.unpackedUnits}';
                      _damagedCtrl.text = '0';
                      _formError = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
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
                    decoration: InputDecoration(
                      labelText: 'Good Inner Boxes *',
                      hintText: 'Max ${tape.unpackedUnits}',
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
                'Converts multiples of ${style.boxesPerCase} boxes into Factory Ready Stock and keeps leftovers in Master Cartons queue.',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: ErpTheme.slate500,
                ),
              ),
            ),
            if (packed > 0 || exceedsTape) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: exceedsTape
                      ? ErpTheme.dangerRoseSoft
                      : _autoSeal && autoCartons > 0
                      ? ErpTheme.godownTealSoft
                      : ErpTheme.productionAmberSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: exceedsTape
                        ? ErpTheme.dangerRose.withValues(alpha: 0.4)
                        : _autoSeal && autoCartons > 0
                        ? ErpTheme.godownTeal.withValues(alpha: 0.35)
                        : ErpTheme.productionAmber.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  exceedsTape
                      ? 'Exceeds available Tape production! Entered $totalFromTape units, only ${tape.unpackedUnits} available.'
                      : _autoSeal && autoCartons > 0
                      ? 'Preview (${style.name}): $totalLoose ÷ ${style.boxesPerCase} = $autoCartons Master Cartons + $leftover Loose Boxes'
                      : 'Preview (${style.name}): $totalLoose Loose Boxes (${totalLoose ~/ style.boxesPerCase} full cartons ready) • ${tape.unpackedUnits - totalFromTape} Tape units left unpacked',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: exceedsTape
                        ? ErpTheme.dangerRose
                        : _autoSeal && autoCartons > 0
                        ? ErpTheme.godownTealDark
                        : ErpTheme.productionAmberDark,
                  ),
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
              onPressed: vm.isSubmitting || exceedsTape
                  ? null
                  : () async {
                      if (packed <= 0) {
                        setState(() {
                          _formError = 'Enter a valid inner box count (> 0).';
                        });
                        return;
                      }
                      final ok = await vm.recordInnerBoxPacking(
                        styleProductId: style.id,
                        styleName: style.name,
                        wipName: tape.wipName,
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
                    ? 'Pack into ${style.name} & Seal $autoCartons Ctn'
                    : 'Pack into ${style.name}',
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
                        'Seal Master Cartons',
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
