import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/domain/models/daily_production.dart';
import 'package:crackers_erp/domain/models/employee.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/features/auth/view_models/auth_view_model.dart';
import 'package:crackers_erp/ui/features/production/view_models/daily_production_view_model.dart';

class DailyProductionScreen extends StatefulWidget {
  const DailyProductionScreen({
    required this.viewModel,
    required this.authViewModel,
    super.key,
  });

  final DailyProductionViewModel viewModel;
  final AuthViewModel authViewModel;

  @override
  State<DailyProductionScreen> createState() => _DailyProductionScreenState();
}

class _DailyProductionScreenState extends State<DailyProductionScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showHistoryTab = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.authViewModel.currentUser?.canViewProduction == true) {
        widget.viewModel.loadInitialData();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.viewModel.selectedDate.isAfter(now)
          ? now
          : widget.viewModel.selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked != null && mounted) {
      await widget.viewModel.selectDate(picked);
    }
  }

  Future<void> _handleSave() async {
    final ok = await widget.viewModel.saveAll();
    if (!mounted) return;
    if (ok && widget.viewModel.statusMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.viewModel.statusMessage!),
          backgroundColor: ErpTheme.ordersEmerald,
        ),
      );
    }
  }

  Future<void> _openWipItemPicker({int? forEmployeeId, String? workerName}) async {
    final searchController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return ListenableBuilder(
              listenable: widget.viewModel,
              builder: (ctx, _) {
                final vm = widget.viewModel;
                final q = searchController.text.trim().toLowerCase();
                final items = vm.wipProducts.where((p) {
                  if (q.isEmpty) return true;
                  return p.name.toLowerCase().contains(q) ||
                      p.displayGroup.toLowerCase().contains(q) ||
                      p.code.toLowerCase().contains(q);
                }).toList();

                return DraggableScrollableSheet(
                  expand: false,
                  initialChildSize: 0.78,
                  minChildSize: 0.5,
                  maxChildSize: 0.94,
                  builder: (ctx, scrollController) {
                    return Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: ErpTheme.slate200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  forEmployeeId != null
                                      ? 'Add WIP Item for $workerName'
                                      : 'Select / Pin WIP Items',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: ErpTheme.slate900,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.of(ctx).pop(),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: searchController,
                            onChanged: (_) => setSheetState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Search WIP product name or group...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        searchController.clear();
                                        setSheetState(() {});
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: items.isEmpty
                              ? const ErpEmptyState(
                                  icon: Icons.inventory_2_outlined,
                                  title: 'No matching WIP items',
                                  subtitle:
                                      'Create WIP products in Web Admin Product Master to log factory production.',
                                )
                              : ListView.separated(
                                  controller: scrollController,
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    4,
                                    16,
                                    24,
                                  ),
                                  itemCount: items.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (ctx, idx) {
                                    final prod = items[idx];
                                    final isActive = vm.activeItemNames.contains(
                                      prod.name,
                                    );
                                    final isPinned = vm.pinnedItemNames.contains(
                                      prod.name,
                                    );
                                    final currentWorkerQty =
                                        forEmployeeId != null
                                        ? vm.getQuantity(
                                            forEmployeeId,
                                            prod.name,
                                          )
                                        : 0;

                                    return Material(
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        side: BorderSide(
                                          color: (forEmployeeId != null
                                                  ? currentWorkerQty > 0
                                                  : isActive)
                                              ? ErpTheme.productionAmber
                                              : ErpTheme.slate200,
                                        ),
                                      ),
                                      child: ListTile(
                                        onTap: () {
                                          if (forEmployeeId != null) {
                                            if (currentWorkerQty == 0) {
                                              vm.setQuantity(
                                                forEmployeeId,
                                                prod.name,
                                                1,
                                              );
                                            }
                                            Navigator.of(ctx).pop();
                                          } else {
                                            if (isActive &&
                                                vm.getItemTotalQuantity(
                                                      prod.name,
                                                    ) ==
                                                    0) {
                                              vm.removeActiveItem(prod.name);
                                            } else {
                                              vm.addActiveItem(prod.name);
                                            }
                                          }
                                        },
                                        title: Text(
                                          prod.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${prod.displayGroup} • Unit: ${prod.unit}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: ErpTheme.slate500,
                                          ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              tooltip: isPinned
                                                  ? 'Unpin from favorites'
                                                  : 'Pin for daily use',
                                              icon: Icon(
                                                isPinned
                                                    ? Icons.star_rounded
                                                    : Icons.star_outline_rounded,
                                                color: isPinned
                                                    ? ErpTheme.productionAmber
                                                    : ErpTheme.slate500,
                                              ),
                                              onPressed: () => vm
                                                  .togglePinnedItem(prod.name),
                                            ),
                                            if (forEmployeeId != null)
                                              Icon(
                                                currentWorkerQty > 0
                                                    ? Icons.check_circle
                                                    : Icons.add_circle_outline,
                                                color: currentWorkerQty > 0
                                                    ? ErpTheme.ordersEmerald
                                                    : ErpTheme.productionAmber,
                                              )
                                            else
                                              Icon(
                                                isActive
                                                    ? Icons.check_box_rounded
                                                    : Icons
                                                          .check_box_outline_blank_rounded,
                                                color: isActive
                                                    ? ErpTheme.productionAmber
                                                    : ErpTheme.slate500,
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
    searchController.dispose();
  }

  Future<void> _confirmDeleteRecord(DailyProductionRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Production Entry?'),
        content: Text(
          'Remove ${record.employeeName}\'s production log for ${record.isoDate} (${record.totalPieces} pcs)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: ErpTheme.dangerRose),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final ok = await widget.viewModel.deleteHistoryRecord(record);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Production entry deleted.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authViewModel.currentUser;
    if (user != null && !user.canViewProduction) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Daily Production'),
          actions: [AccountAppBarAction(authViewModel: widget.authViewModel)],
        ),
        body: const ErpEmptyState(
          icon: Icons.lock_outline,
          title: 'Production Access Not Enabled',
          subtitle:
              'Ask an Admin to grant Daily Production view access for your account.',
        ),
      );
    }

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Daily Production'),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: vm.isLoading ? null : vm.refreshAll,
                icon: const Icon(Icons.refresh_rounded),
              ),
              AccountAppBarAction(
                authViewModel: widget.authViewModel,
                hasUnsavedProduction: vm.hasUnsavedChanges,
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            icon: Icon(Icons.edit_note_rounded, size: 18),
                            label: Text('Log Entry'),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            icon: Icon(Icons.history_rounded, size: 18),
                            label: Text('Saved Logs'),
                          ),
                        ],
                        selected: {_showHistoryTab},
                        onSelectionChanged: (sel) => setState(() {
                          _showHistoryTab = sel.first;
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              if (vm.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: ErpErrorBanner(
                    message: vm.errorMessage!,
                    onRetry: vm.refreshAll,
                    onDismiss: vm.clearMessages,
                  ),
                ),
              Expanded(
                child: vm.isLoading && vm.employees.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _showHistoryTab
                    ? _buildHistoryList(vm)
                    : _buildEntryWorkspace(vm),
              ),
            ],
          ),
          bottomNavigationBar: !_showHistoryTab && vm.hasUnsavedChanges
              ? SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: ErpTheme.slate200)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Unsaved Local Changes',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: ErpTheme.slate900,
                                ),
                              ),
                              Text(
                                '${vm.activeWorkersLoggedCount} workers • ${vm.totalPiecesEntered} total pcs',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: ErpTheme.slate500,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: vm.isSaving ? null : vm.discardDraft,
                          child: const Text('Discard'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: vm.isSaving ? null : _handleSave,
                          style: FilledButton.styleFrom(
                            backgroundColor: ErpTheme.productionAmber,
                            foregroundColor: Colors.white,
                          ),
                          icon: vm.isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_rounded, size: 18),
                          label: Text(vm.isSaving ? 'Saving...' : 'Save Log'),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildEntryWorkspace(DailyProductionViewModel vm) {
    final now = DateTime.now();
    final todayNormalized = DateTime(now.year, now.month, now.day);
    final selectedNormalized = DateTime(
      vm.selectedDate.year,
      vm.selectedDate.month,
      vm.selectedDate.day,
    );
    final isToday = selectedNormalized == todayNormalized;
    final dateLabel = DateFormat('EEE, dd MMM yyyy').format(vm.selectedDate);

    return RefreshIndicator(
      onRefresh: vm.refreshAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [
          // Date switcher card
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Previous Day',
                    onPressed: () => vm.selectDate(
                      vm.selectedDate.subtract(const Duration(days: 1)),
                    ),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: ErpTheme.productionAmber,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dateLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: ErpTheme.slate900,
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(width: 8),
                              const ErpBadge(
                                label: 'TODAY',
                                backgroundColor: ErpTheme.productionAmberSoft,
                                foregroundColor: ErpTheme.productionAmber,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next Day',
                    onPressed: isToday
                        ? null
                        : () => vm.selectDate(
                            vm.selectedDate.add(const Duration(days: 1)),
                          ),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
          ),
          if (vm.hasRestoredLocalDraft) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: ErpTheme.productionAmberSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: ErpTheme.productionAmber.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.offline_pin_outlined,
                    size: 18,
                    color: ErpTheme.productionAmber,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Restored unsaved offline draft for this date. Tap Save Log to sync.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ErpTheme.slate900,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: vm.discardDraft,
                    child: const Text('Discard'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          // Stats strip (zero rupee numbers)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ErpStatTile(
                label: 'Workers Logged',
                value: '${vm.activeWorkersLoggedCount}',
                accentColor: ErpTheme.hrIndigo,
                icon: Icons.groups_rounded,
              ),
              ErpStatTile(
                label: 'Total Pieces',
                value: NumberFormat('#,##,##0', 'en_IN').format(
                  vm.totalPiecesEntered,
                ),
                accentColor: ErpTheme.productionAmber,
                icon: Icons.layers_rounded,
              ),
              ErpStatTile(
                label: 'Active WIP Items',
                value: '${vm.activeItemNames.length}',
                accentColor: ErpTheme.ordersEmerald,
                icon: Icons.category_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Entry mode + WIP Picker
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              SegmentedButton<ProductionEntryMode>(
                segments: const [
                  ButtonSegment(
                    value: ProductionEntryMode.byItem,
                    icon: Icon(Icons.view_list_rounded, size: 16),
                    label: Text('By Item'),
                  ),
                  ButtonSegment(
                    value: ProductionEntryMode.byWorker,
                    icon: Icon(Icons.person_search_rounded, size: 16),
                    label: Text('By Worker'),
                  ),
                ],
                selected: {vm.entryMode},
                onSelectionChanged: (sel) => vm.setEntryMode(sel.first),
              ),
              OutlinedButton.icon(
                onPressed: () => _openWipItemPicker(),
                icon: const Icon(Icons.playlist_add_rounded, size: 18),
                label: const Text('Pick / Pin WIP'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Worker search & Role filter
          TextField(
            controller: _searchController,
            onChanged: vm.setWorkerSearch,
            decoration: InputDecoration(
              hintText: 'Filter worker name, role or unit...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        vm.setWorkerSearch('');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Include Monthly'),
                  selected: vm.includeMonthlyWorkers,
                  onSelected: vm.toggleIncludeMonthlyWorkers,
                ),
                const SizedBox(width: 8),
                ...vm.availableRoles.map(
                  (role) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(role),
                      selected: vm.selectedRoleFilter == role,
                      onSelected: (_) => vm.setRoleFilter(role),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (vm.filteredWorkers.isEmpty)
            const ErpEmptyState(
              icon: Icons.engineering_outlined,
              title: 'No Matching Active Workers',
              subtitle:
                  'Add Contractual workers in the Workers & Advances tab or clear filters.',
            )
          else if (vm.entryMode == ProductionEntryMode.byItem)
            ..._buildByItemCards(vm)
          else
            ..._buildByWorkerCards(vm),
        ],
      ),
    );
  }

  List<Widget> _buildByItemCards(DailyProductionViewModel vm) {
    if (vm.activeItemNames.isEmpty) {
      return [
        ErpEmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'No WIP Items Selected',
          subtitle:
              'Tap Pick / Pin WIP to choose factory items produced today.',
          actionLabel: 'Pick WIP Items',
          onAction: () => _openWipItemPicker(),
        ),
      ];
    }

    return vm.activeItemNames.asMap().entries.map((entry) {
      final index = entry.key;
      final itemName = entry.value;
      final product = vm.findWipProductByName(itemName);
      final itemTotal = vm.getItemTotalQuantity(itemName);
      final isPinned = vm.pinnedItemNames.contains(itemName);
      final workers = vm.filteredWorkers;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            initiallyExpanded: index == 0 || itemTotal > 0,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: ErpTheme.slate900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        product != null
                            ? '${product.displayGroup} • ${product.unit}'
                            : 'WIP Production Item',
                        style: const TextStyle(
                          fontSize: 12,
                          color: ErpTheme.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ErpBadge(
                  label: '$itemTotal ${product?.unit ?? 'Pcs'}',
                  backgroundColor: itemTotal > 0
                      ? ErpTheme.productionAmberSoft
                      : ErpTheme.slate100,
                  foregroundColor: itemTotal > 0
                      ? ErpTheme.productionAmber
                      : ErpTheme.slate700,
                ),
                IconButton(
                  tooltip: isPinned ? 'Unpin' : 'Pin item',
                  icon: Icon(
                    isPinned ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 20,
                    color: isPinned
                        ? ErpTheme.productionAmber
                        : ErpTheme.slate500,
                  ),
                  onPressed: () => vm.togglePinnedItem(itemName),
                ),
                if (itemTotal == 0 && vm.activeItemNames.length > 1)
                  IconButton(
                    tooltip: 'Hide from list',
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: ErpTheme.slate500,
                    ),
                    onPressed: () => vm.removeActiveItem(itemName),
                  ),
              ],
            ),
            children: [
              const Divider(height: 1, color: ErpTheme.slate200),
              const SizedBox(height: 8),
              ...workers.map(
                (emp) => _WorkerQtyRow(
                  employee: emp,
                  quantity: vm.getQuantity(emp.id, itemName),
                  onChanged: (q) => vm.setQuantity(emp.id, itemName, q),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildByWorkerCards(DailyProductionViewModel vm) {
    final workers = vm.filteredWorkers;
    return workers.map((emp) {
      final totalQty = vm.getWorkerTotalQuantity(emp.id);
      final enteredMap = vm.getWorkerEntries(emp.id);

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: ErpTheme.hrIndigoSoft,
                      child: Text(
                        emp.name.isNotEmpty
                            ? emp.name[0].toUpperCase()
                            : 'W',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: ErpTheme.hrIndigo,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emp.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: ErpTheme.slate900,
                            ),
                          ),
                          Text(
                            '${emp.roleGroup} • ${emp.paymentType}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: ErpTheme.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ErpBadge(
                      label: '$totalQty Pcs',
                      backgroundColor: totalQty > 0
                          ? ErpTheme.productionAmberSoft
                          : ErpTheme.slate100,
                      foregroundColor: totalQty > 0
                          ? ErpTheme.productionAmber
                          : ErpTheme.slate700,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (enteredMap.isEmpty)
                  const Text(
                    'No WIP items logged yet for this worker.',
                    style: TextStyle(fontSize: 12, color: ErpTheme.slate500),
                  )
                else
                  ...enteredMap.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: LayoutBuilder(
                        builder: (ctx, c) {
                          final narrow = c.maxWidth < 360;
                          if (narrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                QuantityStepperField(
                                  quantity: e.value,
                                  onChanged: (q) =>
                                      vm.setQuantity(emp.id, e.key, q),
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(
                                child: Text(
                                  e.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: ErpTheme.slate900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              QuantityStepperField(
                                quantity: e.value,
                                onChanged: (q) =>
                                    vm.setQuantity(emp.id, e.key, q),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _openWipItemPicker(
                      forEmployeeId: emp.id,
                      workerName: emp.name,
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Add WIP Item'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildHistoryList(DailyProductionViewModel vm) {
    if (vm.recentHistory.isEmpty) {
      return RefreshIndicator(
        onRefresh: vm.refreshAll,
        child: ListView(
          children: const [
            SizedBox(height: 80),
            ErpEmptyState(
              icon: Icons.history_toggle_off,
              title: 'No Production Logs Yet',
              subtitle:
                  'Saved daily production sheets appear here (quantities only).',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.refreshAll,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: vm.recentHistory.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (ctx, idx) {
          final rec = vm.recentHistory[idx];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ErpBadge(
                        label: rec.isoDate,
                        backgroundColor: ErpTheme.slate100,
                        foregroundColor: ErpTheme.slate700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rec.employeeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: ErpTheme.slate900,
                          ),
                        ),
                      ),
                      ErpBadge(
                        label: '${rec.totalPieces} Pcs',
                        backgroundColor: ErpTheme.productionAmberSoft,
                        foregroundColor: ErpTheme.productionAmber,
                      ),
                    ],
                  ),
                  if (rec.employeeRole != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      rec.employeeRole!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ErpTheme.slate500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: rec.items
                        .map(
                          (item) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: ErpTheme.slate50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: ErpTheme.slate200),
                            ),
                            child: Text(
                              '${item.itemName}: ${item.quantity}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: ErpTheme.slate700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          await vm.selectDate(rec.date);
                          if (mounted) {
                            setState(() => _showHistoryTab = false);
                          }
                        },
                        icon: const Icon(Icons.edit_calendar_outlined, size: 16),
                        label: const Text('Open Date'),
                      ),
                      const SizedBox(width: 6),
                      TextButton.icon(
                        onPressed: () => _confirmDeleteRecord(rec),
                        style: TextButton.styleFrom(
                          foregroundColor: ErpTheme.dangerRose,
                        ),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Delete'),
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
  }
}

class _WorkerQtyRow extends StatelessWidget {
  const _WorkerQtyRow({
    required this.employee,
    required this.quantity,
    required this.onChanged,
  });

  final Employee employee;
  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 370;
          final labelWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                employee.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: ErpTheme.slate900,
                ),
              ),
              Text(
                employee.unit != null
                    ? '${employee.roleGroup} • ${employee.unit}'
                    : employee.roleGroup,
                style: const TextStyle(
                  fontSize: 11,
                  color: ErpTheme.slate500,
                ),
              ),
            ],
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                labelWidget,
                const SizedBox(height: 6),
                QuantityStepperField(
                  quantity: quantity,
                  onChanged: onChanged,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: labelWidget),
              const SizedBox(width: 8),
              QuantityStepperField(
                quantity: quantity,
                onChanged: onChanged,
              ),
            ],
          );
        },
      ),
    );
  }
}
