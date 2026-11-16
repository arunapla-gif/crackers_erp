import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/core/utils/tamil_transliteration.dart';
import 'package:crackers_erp/domain/models/daily_production.dart';
import 'package:crackers_erp/domain/models/employee.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/core/erp_crud_widgets.dart';
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
  bool _isMatrixFocusMode = false;
  WorkerNameDisplayMode _nameDisplayMode = WorkerNameDisplayMode.tamil;
  final Set<String> _collapsedItemRoles = <String>{};

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

  Future<void> _confirmClearMatrix() async {
    final confirm = await showErpConfirmDialog(
      context: context,
      title: 'Clear Matrix Quantities?',
      message:
          'Reset all unsaved piece quantities entered for ${widget.viewModel.selectedIsoDate}?',
      confirmLabel: 'Clear Grid',
      destructive: true,
    );
    if (confirm && mounted) {
      widget.viewModel.clearDayEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authViewModel.currentUser;
    final isEmbedded = ErpShellScope.isEmbeddedShell(context);

    if (user != null && !user.canViewProduction) {
      return Scaffold(
        appBar: isEmbedded
            ? null
            : AppBar(
                title: const Text('Daily Production'),
                actions: [
                  AccountAppBarAction(authViewModel: widget.authViewModel),
                ],
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
        final effectiveMode = vm.entryMode;
        final inFocusMatrix =
            !_showHistoryTab &&
            effectiveMode == ProductionEntryMode.matrix &&
            _isMatrixFocusMode;

        return Scaffold(
          appBar: isEmbedded
              ? null
              : AppBar(
                  title: const Text('Daily Production'),
                  actions: [
                    if (effectiveMode == ProductionEntryMode.matrix &&
                        !_showHistoryTab)
                      IconButton(
                        tooltip: _isMatrixFocusMode
                            ? 'Exit Focus Grid'
                            : 'Full Screen Matrix',
                        onPressed: () => setState(
                          () => _isMatrixFocusMode = !_isMatrixFocusMode,
                        ),
                        icon: Icon(
                          _isMatrixFocusMode
                              ? Icons.fullscreen_exit_rounded
                              : Icons.fullscreen_rounded,
                        ),
                      ),
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
              if (isEmbedded && !inFocusMatrix)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
                  child: ErpSectionHeaderBar(
                    title: 'Daily Production',
                    subtitle:
                        'Log daily WIP quantities by Item, Worker, or Role Matrix.',
                    accentColor: ErpTheme.productionAmber,
                    actions: [
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: vm.isLoading ? null : vm.refreshAll,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                ),
              if (!inFocusMatrix)
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
                            if (_showHistoryTab) {
                              _isMatrixFocusMode = false;
                            }
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
                    : inFocusMatrix
                    ? _buildMatrixFocusWorkspace(vm)
                    : _buildEntryWorkspace(vm, effectiveMode: effectiveMode),
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

  Widget _buildEntryWorkspace(
    DailyProductionViewModel vm, {
    required ProductionEntryMode effectiveMode,
  }) {
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
                            Flexible(
                              child: Text(
                                dateLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: ErpTheme.slate900,
                                ),
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
          // Entry mode + WIP Picker
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<ProductionEntryMode>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    padding: WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
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
                    ButtonSegment(
                      value: ProductionEntryMode.matrix,
                      icon: Icon(Icons.grid_on_rounded, size: 16),
                      label: Text('Matrix'),
                    ),
                  ],
                  selected: {effectiveMode},
                  onSelectionChanged: (sel) {
                    if (sel.first != ProductionEntryMode.matrix &&
                        _isMatrixFocusMode) {
                      setState(() => _isMatrixFocusMode = false);
                    }
                    vm.setEntryMode(sel.first);
                  },
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (effectiveMode != ProductionEntryMode.matrix)
                    SegmentedButton<WorkerNameDisplayMode>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                      ),
                    ),
                    segments: const [
                      ButtonSegment(
                        value: WorkerNameDisplayMode.tamil,
                        label: Text(
                          'தமிழ்',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      ButtonSegment(
                        value: WorkerNameDisplayMode.english,
                        label: Text(
                          'Eng',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      ButtonSegment(
                        value: WorkerNameDisplayMode.both,
                        label: Text(
                          'Both',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    selected: {_nameDisplayMode},
                    onSelectionChanged: (sel) =>
                        setState(() => _nameDisplayMode = sel.first),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _openWipItemPicker(),
                    icon: const Icon(Icons.playlist_add_rounded, size: 18),
                    label: const Text('Pick / Pin WIP'),
                  ),
                ],
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
          if (effectiveMode != ProductionEntryMode.matrix) ...[
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
                    (role) {
                      final count = vm.getWorkerCountForRole(role);
                      final tamil = DailyProductionViewModel.getRoleTamilName(role);
                      final label = role == 'All'
                          ? 'All Workers ($count)'
                          : (tamil.isNotEmpty ? '$role • $tamil ($count)' : '$role ($count)');
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: vm.selectedRoleFilter == role,
                          onSelected: (_) => vm.setRoleFilter(role),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (vm.filteredWorkers.isEmpty)
            const ErpEmptyState(
              icon: Icons.engineering_outlined,
              title: 'No Matching Active Workers',
              subtitle:
                  'Add Contractual workers in the Workers & Advances tab or clear filters.',
            )
          else if (effectiveMode == ProductionEntryMode.matrix)
            ..._buildMatrixWorkspace(vm)
          else if (effectiveMode == ProductionEntryMode.byItem)
            ..._buildByItemCards(vm)
          else
            ..._buildByWorkerCards(vm),
        ],
      ),
    );
  }

  Widget _buildRoleSectionHeader({
    required String role,
    required int count,
    required int subtotal,
    required String unit,
    required bool isCollapsed,
    required VoidCallback onToggleCollapse,
  }) {
    final cleanRole = role.trim().toLowerCase();
    final isTape = cleanRole == 'tape';
    final isChemical = cleanRole == 'chemical';
    final isValayam = cleanRole == 'valayam contract' || cleanRole == 'valayam';

    final IconData roleIcon;
    final Color roleColor;
    final Color roleBgColor;
    final String roleTamil;

    if (isTape) {
      roleIcon = Icons.view_week_rounded;
      roleColor = const Color(0xFF0F766E); // Teal 700
      roleBgColor = const Color(0xFFCCFBF1); // Teal 100
      roleTamil = 'டேப்';
    } else if (isChemical) {
      roleIcon = Icons.science_rounded;
      roleColor = const Color(0xFFB45309); // Amber 700
      roleBgColor = const Color(0xFFFEF3C7); // Amber 100
      roleTamil = 'கெமிக்கல்';
    } else if (isValayam) {
      roleIcon = Icons.all_inclusive_rounded;
      roleColor = const Color(0xFF4338CA); // Indigo 700
      roleBgColor = const Color(0xFFE0E7FF); // Indigo 100
      roleTamil = 'வளையம் ஒப்பந்தம்';
    } else {
      roleIcon = Icons.badge_outlined;
      roleColor = ErpTheme.slate700;
      roleBgColor = ErpTheme.slate100;
      roleTamil = DailyProductionViewModel.getRoleTamilName(role);
    }

    return InkWell(
      onTap: onToggleCollapse,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: roleBgColor.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: roleColor.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(roleIcon, size: 16, color: roleColor),
            const SizedBox(width: 6),
            Expanded(
              child: Row(
                children: [
                  Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: roleColor,
                    ),
                  ),
                  if (roleTamil.isNotEmpty) ...[
                    const SizedBox(width: 5),
                    Text(
                      '• $roleTamil',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: roleColor.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: roleColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: roleColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (subtotal > 0)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ErpBadge(
                  label: '$subtotal $unit',
                  backgroundColor: Colors.white,
                  foregroundColor: roleColor,
                ),
              ),
            Icon(
              isCollapsed
                  ? Icons.chevron_right_rounded
                  : Icons.expand_more_rounded,
              size: 16,
              color: roleColor,
            ),
          ],
        ),
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

    final groupedRoles = vm.filteredWorkersByRole;

    return vm.activeItemNames.asMap().entries.map((entry) {
      final index = entry.key;
      final itemName = entry.value;
      final product = vm.findWipProductByName(itemName);
      final itemTotal = vm.getItemTotalQuantity(itemName);
      final isPinned = vm.pinnedItemNames.contains(itemName);

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
              const SizedBox(height: 4),
              for (final roleEntry in groupedRoles.entries) ...[
                Builder(
                  builder: (context) {
                    final roleCollapseKey = '$itemName::${roleEntry.key}';
                    final isCollapsed =
                        _collapsedItemRoles.contains(roleCollapseKey);
                    final roleSubtotal = roleEntry.value.fold<int>(
                      0,
                      (sum, emp) => sum + vm.getQuantity(emp.id, itemName),
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildRoleSectionHeader(
                          role: roleEntry.key,
                          count: roleEntry.value.length,
                          subtotal: roleSubtotal,
                          unit: product?.unit ?? 'Pcs',
                          isCollapsed: isCollapsed,
                          onToggleCollapse: () {
                            setState(() {
                              if (isCollapsed) {
                                _collapsedItemRoles.remove(roleCollapseKey);
                              } else {
                                _collapsedItemRoles.add(roleCollapseKey);
                              }
                            });
                          },
                        ),
                        if (!isCollapsed)
                          ...roleEntry.value.map(
                            (emp) => _WorkerQtyRow(
                              employee: emp,
                              quantity: vm.getQuantity(emp.id, itemName),
                              onChanged: (q) =>
                                  vm.setQuantity(emp.id, itemName, q),
                              nameDisplayMode: _nameDisplayMode,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildByWorkerCards(DailyProductionViewModel vm) {
    final groupedRoles = vm.filteredWorkersByRole;
    final widgets = <Widget>[];

    for (final roleEntry in groupedRoles.entries) {
      final role = roleEntry.key;
      final roleWorkers = roleEntry.value;
      final roleTotal = roleWorkers.fold<int>(
        0,
        (sum, emp) => sum + vm.getWorkerTotalQuantity(emp.id),
      );
      final roleCollapseKey = 'worker_mode::$role';
      final isCollapsed = _collapsedItemRoles.contains(roleCollapseKey);

      widgets.add(
        _buildRoleSectionHeader(
          role: role,
          count: roleWorkers.length,
          subtotal: roleTotal,
          unit: 'Pcs',
          isCollapsed: isCollapsed,
          onToggleCollapse: () {
            setState(() {
              if (isCollapsed) {
                _collapsedItemRoles.remove(roleCollapseKey);
              } else {
                _collapsedItemRoles.add(roleCollapseKey);
              }
            });
          },
        ),
      );

      if (!isCollapsed) {
        for (final emp in roleWorkers) {
          final totalQty = vm.getWorkerTotalQuantity(emp.id);
          final enteredMap = vm.getWorkerEntries(emp.id);
          final primaryName = emp.formattedName(_nameDisplayMode);
          final parsed = emp.parsedNames;
          final subtitleParts = <String>[];
          if (_nameDisplayMode == WorkerNameDisplayMode.tamil &&
              parsed.english.isNotEmpty) {
            subtitleParts.add(parsed.english);
          } else if (_nameDisplayMode == WorkerNameDisplayMode.english &&
              parsed.tamil.isNotEmpty) {
            subtitleParts.add(parsed.tamil);
          }
          subtitleParts.add(emp.roleGroup);
          subtitleParts.add(emp.paymentType);
          if (emp.isTemporary) subtitleParts.add('TEMP');
          if (emp.unit != null && emp.unit!.isNotEmpty) {
            subtitleParts.add(emp.unit!);
          }

          widgets.add(
            Padding(
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
                                  primaryName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: ErpTheme.slate900,
                                  ),
                                ),
                                Text(
                                  subtitleParts.join(' • '),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: emp.isTemporary
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: emp.isTemporary
                                        ? ErpTheme.productionAmber
                                        : ErpTheme.slate500,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
            ),
          );
        }
      }
    }
    return widgets;
  }

  Widget _buildMatrixFocusWorkspace(DailyProductionViewModel vm) {
    final dateLabel = DateFormat('dd MMM').format(vm.selectedDate);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: ErpTheme.productionAmberSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: ErpTheme.productionAmber.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: ErpTheme.productionAmber,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: ErpTheme.slate900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: vm.availableRoles.map((role) {
                      final count = vm.getWorkerCountForRole(role);
                      final tamil = DailyProductionViewModel.getRoleTamilName(role);
                      final label = role == 'All'
                          ? 'All ($count)'
                          : (tamil.isNotEmpty ? '$role • $tamil ($count)' : '$role ($count)');
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            label,
                            style: const TextStyle(fontSize: 11),
                          ),
                          visualDensity: VisualDensity.compact,
                          selected: vm.selectedRoleFilter == role,
                          onSelected: (_) => vm.setRoleFilter(role),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Pick / Pin WIP',
                onPressed: () => _openWipItemPicker(),
                icon: const Icon(Icons.playlist_add_rounded),
              ),
              IconButton(
                tooltip: 'Exit Focus Grid',
                onPressed: () => setState(() => _isMatrixFocusMode = false),
                icon: const Icon(Icons.fullscreen_exit_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
            child: vm.filteredWorkers.isEmpty
                ? const ErpEmptyState(
                    icon: Icons.engineering_outlined,
                    title: 'No Matching Active Workers',
                    subtitle:
                        'Add Contractual workers in the Workers & Advances tab or clear filters.',
                  )
                : _ProductionMatrixCard(
                    viewModel: vm,
                    isFocusMode: true,
                    nameDisplayMode: _nameDisplayMode,
                    onNameDisplayModeChanged: (mode) =>
                        setState(() => _nameDisplayMode = mode),
                    onToggleFocusMode: () =>
                        setState(() => _isMatrixFocusMode = false),
                    onOpenWipPicker: () => _openWipItemPicker(),
                    onClearMatrix: _confirmClearMatrix,
                    onSaveMatrix: _handleSave,
                  ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMatrixWorkspace(DailyProductionViewModel vm) {
    return [
      _ProductionMatrixCard(
        viewModel: vm,
        isFocusMode: false,
        nameDisplayMode: _nameDisplayMode,
        onNameDisplayModeChanged: (mode) =>
            setState(() => _nameDisplayMode = mode),
        onToggleFocusMode: () => setState(() => _isMatrixFocusMode = true),
        onOpenWipPicker: () => _openWipItemPicker(),
        onClearMatrix: _confirmClearMatrix,
        onSaveMatrix: _handleSave,
      ),
    ];
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
    this.nameDisplayMode = WorkerNameDisplayMode.both,
  });

  final Employee employee;
  final int quantity;
  final ValueChanged<int> onChanged;
  final WorkerNameDisplayMode nameDisplayMode;

  @override
  Widget build(BuildContext context) {
    final parsed = employee.parsedNames;
    final primaryName = employee.formattedName(nameDisplayMode);
    final subtitleParts = <String>[];
    if (nameDisplayMode == WorkerNameDisplayMode.tamil &&
        parsed.english.isNotEmpty) {
      subtitleParts.add(parsed.english);
    } else if (nameDisplayMode == WorkerNameDisplayMode.english &&
        parsed.tamil.isNotEmpty) {
      subtitleParts.add(parsed.tamil);
    }
    subtitleParts.add(employee.roleGroup);
    subtitleParts.add(employee.paymentType);
    if (employee.isTemporary) subtitleParts.add('TEMP');
    if (employee.unit != null && employee.unit!.isNotEmpty) {
      subtitleParts.add(employee.unit!);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 370;
          final labelWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                primaryName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: ErpTheme.slate900,
                ),
              ),
              const SizedBox(height: 1.5),
              Text(
                subtitleParts.join(' • '),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: employee.isTemporary
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: employee.isTemporary
                      ? ErpTheme.productionAmber
                      : ErpTheme.slate500,
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

class _ProductionMatrixCard extends StatefulWidget {
  const _ProductionMatrixCard({
    required this.viewModel,
    required this.isFocusMode,
    required this.onToggleFocusMode,
    required this.onOpenWipPicker,
    required this.onClearMatrix,
    required this.onSaveMatrix,
    required this.nameDisplayMode,
    required this.onNameDisplayModeChanged,
  });

  final DailyProductionViewModel viewModel;
  final bool isFocusMode;
  final VoidCallback onToggleFocusMode;
  final VoidCallback onOpenWipPicker;
  final VoidCallback onClearMatrix;
  final VoidCallback onSaveMatrix;
  final WorkerNameDisplayMode nameDisplayMode;
  final ValueChanged<WorkerNameDisplayMode> onNameDisplayModeChanged;

  @override
  State<_ProductionMatrixCard> createState() => _ProductionMatrixCardState();
}

class _ProductionMatrixCardState extends State<_ProductionMatrixCard> {
  static const double _headerHeight = 56.0;
  static const double _workerRowHeight = 58.0;
  static const double _footerHeight = 46.0;

  final ScrollController _bodyVScroll = ScrollController();

  final Set<String> _collapsedRoles = <String>{};
  WorkerNameDisplayMode get _nameDisplayMode => widget.nameDisplayMode;
  final Map<String, FocusNode> _cellFocusNodes = <String, FocusNode>{};
  final Map<String, ({int empId, String empName, String itemName})> _cellMeta =
      <String, ({int empId, String empName, String itemName})>{};
  String? _focusedKey;
  String? _selectedWipProductToAdd;
  final Map<String, String?> _selectedWipByRole = <String, String?>{};

  ({Color bg, Color border, Color text, IconData icon}) _getRoleStyle(
    String role,
  ) {
    final clean = role.trim().toLowerCase();
    if (clean == 'tape') {
      return (
        bg: const Color(0xFFE0F2F1),
        border: const Color(0xFF80CBC4),
        text: const Color(0xFF004D40),
        icon: Icons.layers_rounded,
      );
    }
    if (clean == 'chemical') {
      return (
        bg: const Color(0xFFFFF8E1),
        border: const Color(0xFFFFE082),
        text: const Color(0xFFB45309),
        icon: Icons.science_rounded,
      );
    }
    if (clean == 'valayam contract' || clean == 'valayam') {
      return (
        bg: const Color(0xFFEDE7F6),
        border: const Color(0xFFD1C4E9),
        text: const Color(0xFF311B92),
        icon: Icons.handshake_rounded,
      );
    }
    if (clean == 'box packing' || clean == 'packing') {
      return (
        bg: const Color(0xFFE0F7FA),
        border: const Color(0xFF80DEEA),
        text: const Color(0xFF006064),
        icon: Icons.inventory_2_outlined,
      );
    }
    return (
      bg: ErpTheme.slate100,
      border: ErpTheme.slate400,
      text: ErpTheme.slate900,
      icon: Icons.work_outline_rounded,
    );
  }

  @override
  void initState() {
    super.initState();
  }

  String _cellKey(int empId, String itemName) => '$empId::$itemName';

  void _updateFocusedKey(String key, bool hasFocus) {
    final next = hasFocus ? key : (_focusedKey == key ? null : _focusedKey);
    if (next == _focusedKey) return;
    if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      setState(() => _focusedKey = next);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _focusedKey = next);
        }
      });
    }
  }

  FocusNode _focusNodeFor(String key) {
    return _cellFocusNodes.putIfAbsent(key, () {
      final node = FocusNode();
      node.addListener(() {
        if (!mounted) return;
        _updateFocusedKey(key, node.hasFocus);
      });
      return node;
    });
  }

  void _focusNextCell(String currentKey, List<String> columnMajorKeys) {
    final idx = columnMajorKeys.indexOf(currentKey);
    if (idx >= 0 && idx + 1 < columnMajorKeys.length) {
      final nextKey = columnMajorKeys[idx + 1];
      final nextNode = _cellFocusNodes[nextKey];
      if (nextNode != null) {
        nextNode.requestFocus();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = nextNode.context;
          if (ctx != null && ctx.mounted && _bodyVScroll.hasClients) {
            final ro = ctx.findRenderObject();
            if (ro != null) {
              _bodyVScroll.position.ensureVisible(
                ro,
                duration: const Duration(milliseconds: 140),
              );
            }
          }
        });
        return;
      }
    }
    _cellFocusNodes[currentKey]?.unfocus();
  }

  @override
  void dispose() {
    _bodyVScroll.dispose();
    for (final node in _cellFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final items = vm.activeItemNames;
    if (items.isEmpty) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: ErpTheme.productionAmberSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.view_column_rounded,
                  size: 32,
                  color: ErpTheme.productionAmber,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'No WIP Product Columns Added',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: ErpTheme.slate900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Select a WIP product below to add it as a column for all workers.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: ErpTheme.slate500,
                ),
              ),
              const SizedBox(height: 18),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: ErpTheme.slate50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: ErpTheme.slate400),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedWipProductToAdd,
                            hint: const Row(
                              children: [
                                Icon(
                                  Icons.add_chart_rounded,
                                  size: 16,
                                  color: ErpTheme.productionAmber,
                                ),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Select Product...',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: ErpTheme.slate500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            items: vm.wipProducts.map((p) {
                              return DropdownMenuItem<String>(
                                value: p.name,
                                child: Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedWipProductToAdd = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      key: const ValueKey('matrix-empty-add-column-button'),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        backgroundColor: ErpTheme.productionAmber,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _selectedWipProductToAdd == null
                          ? null
                          : () {
                              vm.addActiveItem(_selectedWipProductToAdd!);
                              setState(() => _selectedWipProductToAdd = null);
                            },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        '+ Add Column',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: widget.onOpenWipPicker,
                icon: const Icon(Icons.playlist_add_rounded, size: 18),
                label: const Text('Pick WIP Items'),
              ),
            ],
          ),
        ),
      );
    }

    final groupedRoles = vm.filteredWorkersByRole;
    final visibleWorkers = <Employee>[];
    for (final entry in groupedRoles.entries) {
      if (!_collapsedRoles.contains(entry.key)) {
        visibleWorkers.addAll(entry.value);
      }
    }

    _cellMeta.clear();
    final columnMajorKeys = <String>[];
    for (final itemName in items) {
      for (final emp in visibleWorkers) {
        final roleItems = vm.getActiveItemsForRole(emp.roleGroup);
        if (roleItems.contains(itemName)) {
          final key = _cellKey(emp.id, itemName);
          columnMajorKeys.add(key);
          _cellMeta[key] = (
            empId: emp.id,
            empName: emp.formattedName(_nameDisplayMode),
            itemName: itemName,
          );
        }
      }
    }
    final activeMeta = _focusedKey != null ? _cellMeta[_focusedKey] : null;
    final inrFormat = NumberFormat('#,##,##0', 'en_IN');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 600;
          final workerColWidth = isCompact ? 132.0 : 176.0;
          final baseItemWidth = isCompact ? 98.0 : 136.0;
          final totalColWidth = isCompact ? 72.0 : 92.0;

          final useBoundedExpand =
              widget.isFocusMode &&
              constraints.hasBoundedHeight &&
              constraints.maxHeight >= 260;

          final stackedCards = _buildDepartmentStackedCards(
            vm: vm,
            groupedRoles: groupedRoles,
            columnMajorKeys: columnMajorKeys,
            workerColWidth: workerColWidth,
            baseItemWidth: baseItemWidth,
            totalColWidth: totalColWidth,
            availableWidth: constraints.maxWidth,
            inrFormat: inrFormat,
            nameDisplayMode: _nameDisplayMode,
          );

          final bodyScroll = SingleChildScrollView(
            controller: _bodyVScroll,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: stackedCards,
          );

          final screenHeight = MediaQuery.sizeOf(context).height;
          final maxCardHeight =
              (screenHeight * (widget.isFocusMode ? 0.72 : 0.50))
                  .clamp(260.0, 700.0);
          final bodyWrapper = useBoundedExpand
              ? Expanded(child: bodyScroll)
              : ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: maxCardHeight,
                  ),
                  child: bodyScroll,
                );

          return Column(
            mainAxisSize: useBoundedExpand
                ? MainAxisSize.max
                : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildToolbar(vm, items),
              if (activeMeta != null && _focusedKey != null)
                _buildQuickEntryBar(
                  vm: vm,
                  cellKey: _focusedKey!,
                  empId: activeMeta.empId,
                  empName: activeMeta.empName,
                  itemName: activeMeta.itemName,
                  columnMajorKeys: columnMajorKeys,
                ),
              bodyWrapper,
              _buildStickyBottomBar(vm, inrFormat),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToolbar(DailyProductionViewModel vm, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Role category tabs
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: ErpTheme.slate200)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    avatar: const Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 14,
                      color: ErpTheme.slate500,
                    ),
                    label: const Text('Include Monthly'),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: vm.includeMonthlyWorkers
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: vm.includeMonthlyWorkers
                          ? ErpTheme.slate900
                          : ErpTheme.slate700,
                    ),
                    selected: vm.includeMonthlyWorkers,
                    onSelected: vm.toggleIncludeMonthlyWorkers,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                ...vm.availableRoles.map((role) {
                final count = vm.getWorkerCountForRole(role);
                final tamil = DailyProductionViewModel.getRoleTamilName(role);
                final isSelected = vm.selectedRoleFilter == role;
                final style = role == 'All'
                    ? (
                        bg: ErpTheme.slate100,
                        border: ErpTheme.slate400,
                        text: ErpTheme.slate900,
                        icon: Icons.groups_rounded,
                      )
                    : _getRoleStyle(role);
                final label = role == 'All'
                    ? 'All ($count)'
                    : (tamil.isNotEmpty ? '$role • $tamil ($count)' : '$role ($count)');
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    avatar: Icon(
                      style.icon,
                      size: 14,
                      color: isSelected ? style.text : ErpTheme.slate500,
                    ),
                    label: Text(label),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? style.text : ErpTheme.slate700,
                    ),
                    selected: isSelected,
                    selectedColor: style.bg,
                    checkmarkColor: style.text,
                    side: BorderSide(
                      color: isSelected ? style.border : ErpTheme.slate200,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    onSelected: (_) => vm.setRoleFilter(role),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
        // Action toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: ErpTheme.slate50,
            border: Border(bottom: BorderSide(color: ErpTheme.slate200)),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${vm.filteredWorkers.length} workers • ${items.length} WIP',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: ErpTheme.slate700,
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SegmentedButton<WorkerNameDisplayMode>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                      ),
                    ),
                    segments: const [
                      ButtonSegment(
                        value: WorkerNameDisplayMode.tamil,
                        label: Text(
                          'தமிழ்',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      ButtonSegment(
                        value: WorkerNameDisplayMode.english,
                        label: Text(
                          'Eng',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      ButtonSegment(
                        value: WorkerNameDisplayMode.both,
                        label: Text(
                          'Both',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    selected: {_nameDisplayMode},
                    onSelectionChanged: (sel) =>
                        widget.onNameDisplayModeChanged(sel.first),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                    onPressed: widget.onToggleFocusMode,
                    icon: Icon(
                      widget.isFocusMode
                          ? Icons.fullscreen_exit_rounded
                          : Icons.fullscreen_rounded,
                      size: 16,
                    ),
                    label: Text(widget.isFocusMode ? 'Exit Focus' : 'Focus Grid'),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                    onPressed: vm.isSaving || vm.totalPiecesEntered == 0
                        ? null
                        : widget.onClearMatrix,
                    icon: const Icon(Icons.clear_all_rounded, size: 16),
                    label: const Text('Clear'),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      backgroundColor: ErpTheme.productionAmber,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: vm.isSaving ? null : widget.onSaveMatrix,
                    icon: const Icon(Icons.save_rounded, size: 16),
                    label: Text(vm.isSaving ? 'Saving...' : 'Save Matrix'),
                  ),
                ],
              ),
            ],
          ),
        ),
        // React-style Quick Add Product Column Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: ErpTheme.slate200)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: ErpTheme.slate50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ErpTheme.slate400),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedWipProductToAdd,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: ErpTheme.slate500,
                      ),
                      hint: const Row(
                        children: [
                          Icon(
                            Icons.add_chart_rounded,
                            size: 16,
                            color: ErpTheme.productionAmber,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Add Product Column (e.g. 10 KVR 48)...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: ErpTheme.slate500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      items: vm.wipProducts.map((p) {
                        final alreadyAdded = items.contains(p.name);
                        return DropdownMenuItem<String>(
                          value: p.name,
                          enabled: !alreadyAdded,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: alreadyAdded
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                    color: alreadyAdded
                                        ? ErpTheme.slate400
                                        : ErpTheme.slate900,
                                  ),
                                ),
                              ),
                              if (alreadyAdded)
                                const Text(
                                  'Added',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: ErpTheme.slate400,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedWipProductToAdd = val);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                key: const ValueKey('matrix-add-column-button'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  backgroundColor: ErpTheme.productionAmber,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _selectedWipProductToAdd == null ||
                        items.contains(_selectedWipProductToAdd)
                    ? null
                    : () {
                        vm.addActiveItem(_selectedWipProductToAdd!);
                        setState(() => _selectedWipProductToAdd = null);
                      },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  '+ Add Column',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Pick / Pin WIP Items',
                onPressed: widget.onOpenWipPicker,
                icon: const Icon(
                  Icons.playlist_add_rounded,
                  color: ErpTheme.slate500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickEntryBar({
    required DailyProductionViewModel vm,
    required String cellKey,
    required int empId,
    required String empName,
    required String itemName,
    required List<String> columnMajorKeys,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ErpTheme.hrIndigoSoft.withValues(alpha: 0.7),
        border: const Border(bottom: BorderSide(color: ErpTheme.slate200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$empName • $itemName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: ErpTheme.hrIndigo,
              ),
            ),
          ),
          const SizedBox(width: 6),
          for (final delta in const [10, 25, 50]) ...[
            _QuickQtyPill(
              label: '+$delta',
              onTap: () => vm.incrementQuantity(empId, itemName, delta),
            ),
            const SizedBox(width: 4),
          ],
          _QuickQtyPill(
            label: '0',
            onTap: () => vm.setQuantity(empId, itemName, 0),
          ),
          const SizedBox(width: 4),
          _QuickQtyPill(
            label: 'Next ↓',
            highlighted: true,
            onTap: () => _focusNextCell(cellKey, columnMajorKeys),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentStackedCards({
    required DailyProductionViewModel vm,
    required Map<String, List<Employee>> groupedRoles,
    required List<String> columnMajorKeys,
    required double workerColWidth,
    required double baseItemWidth,
    required double totalColWidth,
    required double availableWidth,
    required NumberFormat inrFormat,
    required WorkerNameDisplayMode nameDisplayMode,
  }) {
    if (groupedRoles.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: ErpEmptyState(
          icon: Icons.engineering_outlined,
          title: 'No Matching Workers',
          subtitle:
              'No active contractual workers match the selected role filter or search query.',
        ),
      );
    }

    final cards = <Widget>[];
    var isFirst = true;

    for (final entry in groupedRoles.entries) {
      final role = entry.key;
      final roleWorkers = entry.value;
      final isCollapsed = _collapsedRoles.contains(role);
      final roleItems = vm.getActiveItemsForRole(role);
      final roleTotal = vm.getRoleTotalQuantity(role);
      final roleStyle = _getRoleStyle(role);
      final roleTamil = DailyProductionViewModel.getRoleTamilName(role);

      cards.add(
        _buildDepartmentCard(
          vm: vm,
          role: role,
          roleWorkers: roleWorkers,
          roleItems: roleItems,
          roleTotal: roleTotal,
          roleStyle: roleStyle,
          roleTamil: roleTamil,
          isCollapsed: isCollapsed,
          columnMajorKeys: columnMajorKeys,
          workerColWidth: workerColWidth,
          baseItemWidth: baseItemWidth,
          totalColWidth: totalColWidth,
          availableWidth: availableWidth,
          inrFormat: inrFormat,
          nameDisplayMode: nameDisplayMode,
          isFirstDepartment: isFirst,
        ),
      );
      isFirst = false;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: cards,
    );
  }

  Widget _buildDepartmentCard({
    required DailyProductionViewModel vm,
    required String role,
    required List<Employee> roleWorkers,
    required List<String> roleItems,
    required int roleTotal,
    required ({Color bg, Color border, Color text, IconData icon}) roleStyle,
    required String roleTamil,
    required bool isCollapsed,
    required List<String> columnMajorKeys,
    required double workerColWidth,
    required double baseItemWidth,
    required double totalColWidth,
    required double availableWidth,
    required NumberFormat inrFormat,
    required WorkerNameDisplayMode nameDisplayMode,
    required bool isFirstDepartment,
  }) {
    final availableRightWidth =
        (availableWidth - workerColWidth).clamp(0.0, double.infinity);
    final baseRightWidth = (baseItemWidth * roleItems.length) + totalColWidth;
    final itemColWidth =
        roleItems.isNotEmpty && baseRightWidth < availableRightWidth
            ? baseItemWidth +
                ((availableRightWidth - baseRightWidth) / roleItems.length)
            : baseItemWidth;
    final rightTrackWidth = (itemColWidth * roleItems.length) + totalColWidth;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ErpTheme.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Department Header Banner
          InkWell(
            onTap: () => setState(() {
              if (isCollapsed) {
                _collapsedRoles.remove(role);
              } else {
                _collapsedRoles.add(role);
              }
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: roleStyle.bg,
                border: Border(
                  left: BorderSide(color: roleStyle.border, width: 4),
                  bottom: BorderSide(color: roleStyle.border),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCollapsed
                            ? Icons.chevron_right_rounded
                            : Icons.expand_more_rounded,
                        size: 20,
                        color: roleStyle.text,
                      ),
                      const SizedBox(width: 6),
                      Icon(roleStyle.icon, size: 16, color: roleStyle.text),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          roleTamil.isNotEmpty
                              ? '${role.toUpperCase()} • $roleTamil (${roleWorkers.length})'
                              : '${role.toUpperCase()} (${roleWorkers.length})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: roleStyle.text,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: roleStyle.border),
                        ),
                        child: Text(
                          '${inrFormat.format(roleTotal)} pcs',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: roleStyle.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${role.toUpperCase()} • $roleTamil (${roleWorkers.length} workers) • Subtotal: ${inrFormat.format(roleTotal)} pcs',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: roleStyle.text.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (!isCollapsed) ...[
            // 2. Department Quick Add Column Bar
            _buildDepartmentAddColumnBar(vm, role, roleItems),

            // 3. Department Sub-Grid (or Empty State)
            if (roleItems.isEmpty)
              _buildDepartmentEmptyColumns(vm, role)
            else
              _buildDepartmentTable(
                vm: vm,
                role: role,
                roleWorkers: roleWorkers,
                roleItems: roleItems,
                roleTotal: roleTotal,
                roleStyle: roleStyle,
                workerColWidth: workerColWidth,
                itemColWidth: itemColWidth,
                totalColWidth: totalColWidth,
                rightTrackWidth: rightTrackWidth,
                inrFormat: inrFormat,
                nameDisplayMode: nameDisplayMode,
                columnMajorKeys: columnMajorKeys,
                isFirstDepartment: isFirstDepartment,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDepartmentAddColumnBar(
    DailyProductionViewModel vm,
    String role,
    List<String> roleItems,
  ) {
    final currentSelected = _selectedWipByRole[role];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: ErpTheme.slate200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ErpTheme.slate400),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: currentSelected,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: ErpTheme.slate500,
                  ),
                  hint: Row(
                    children: [
                      const Icon(
                        Icons.add_chart_rounded,
                        size: 15,
                        color: ErpTheme.productionAmber,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Add $role WIP Column...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: ErpTheme.slate500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  items: vm.wipProducts.map((p) {
                    final alreadyAdded = roleItems.contains(p.name);
                    return DropdownMenuItem<String>(
                      value: p.name,
                      enabled: !alreadyAdded,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: alreadyAdded
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                              color: alreadyAdded
                                  ? ErpTheme.slate400
                                  : ErpTheme.slate900,
                            ),
                          ),
                        ),
                        if (alreadyAdded)
                          const Text(
                            'Added',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: ErpTheme.slate400,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedWipByRole[role] = val);
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          key: ValueKey('matrix-add-column-button-$role'),
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            backgroundColor: ErpTheme.productionAmber,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: currentSelected == null ||
                  roleItems.contains(currentSelected)
              ? null
              : () {
                  vm.addActiveItemForRole(role, currentSelected);
                  setState(() => _selectedWipByRole[role] = null);
                },
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text(
            '+ Add',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildDepartmentEmptyColumns(
    DailyProductionViewModel vm,
    String role,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.add_chart_rounded,
            size: 32,
            color: ErpTheme.productionAmber,
          ),
          const SizedBox(height: 8),
          Text(
            'No WIP Product Columns for $role',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: ErpTheme.slate900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select a product from the dropdown above to add a column for $role workers.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              color: ErpTheme.slate500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentTable({
    required DailyProductionViewModel vm,
    required String role,
    required List<Employee> roleWorkers,
    required List<String> roleItems,
    required int roleTotal,
    required ({Color bg, Color border, Color text, IconData icon}) roleStyle,
    required double workerColWidth,
    required double itemColWidth,
    required double totalColWidth,
    required double rightTrackWidth,
    required NumberFormat inrFormat,
    required WorkerNameDisplayMode nameDisplayMode,
    required List<String> columnMajorKeys,
    required bool isFirstDepartment,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Frozen Left Worker Column (Worker Header, Rows, Subtotal Footer)
        SizedBox(
          width: workerColWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                height: _headerHeight,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                alignment: Alignment.centerLeft,
                decoration: const BoxDecoration(
                  color: ErpTheme.slate100,
                  border: Border(
                    right: BorderSide(color: ErpTheme.slate200, width: 1.5),
                    bottom: BorderSide(color: ErpTheme.slate200),
                  ),
                ),
                child: Text(
                  isFirstDepartment ? 'WORKERS\n(PINNED)' : 'WORKER',
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: ErpTheme.slate700,
                    letterSpacing: 0.4,
                    height: 1.2,
                  ),
                ),
              ),
              // Worker Rows
              for (final emp in roleWorkers) ...[
                Builder(
                  builder: (context) {
                    final empTotal = vm.getWorkerTotalQuantity(emp.id);
                    return Container(
                      height: _workerRowHeight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: empTotal > 0
                            ? ErpTheme.ordersEmeraldSoft.withValues(alpha: 0.35)
                            : Colors.white,
                        border: Border(
                          left: BorderSide(
                            color: roleStyle.border.withValues(alpha: 0.7),
                            width: 3.5,
                          ),
                          right: const BorderSide(
                            color: ErpTheme.slate200,
                            width: 1.5,
                          ),
                          bottom: const BorderSide(color: ErpTheme.slate200),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emp.formattedName(nameDisplayMode),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              color: ErpTheme.slate900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (nameDisplayMode ==
                                      WorkerNameDisplayMode.tamil &&
                                  emp.englishName.isNotEmpty)
                                emp.englishName
                              else if (nameDisplayMode ==
                                      WorkerNameDisplayMode.english &&
                                  emp.tamilName.isNotEmpty)
                                emp.tamilName,
                              emp.paymentType,
                              if (emp.isTemporary) 'TEMP',
                              if (emp.unit != null) emp.unit!,
                            ].join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: emp.isTemporary
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: emp.isTemporary
                                  ? ErpTheme.productionAmber
                                  : ErpTheme.slate500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              // Subtotal Footer for Worker Column
              Container(
                height: _footerHeight,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  color: roleStyle.bg.withValues(alpha: 0.5),
                  border: Border(
                    top: BorderSide(color: roleStyle.border, width: 1.5),
                    right: const BorderSide(
                      color: ErpTheme.slate200,
                      width: 1.5,
                    ),
                    bottom: const BorderSide(color: ErpTheme.slate200),
                  ),
                ),
                child: Text(
                  'SUBTOTAL',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 10.5,
                    color: roleStyle.text,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Horizontally Scrollable Product Track (Header, Input Rows, Subtotal Footer)
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: rightTrackWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Product Headers Row
                  Container(
                    height: _headerHeight,
                    color: ErpTheme.slate100,
                    child: Row(
                      children: [
                        for (final itemName in roleItems) ...[
                          Builder(
                            builder: (context) {
                              final product = vm.findWipProductByName(itemName);
                              final roleColTotal =
                                  vm.getRoleItemTotalQuantity(role, itemName);
                              final canRemove = roleItems.length > 1;
                              return Container(
                                width: itemColWidth,
                                height: _headerHeight,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 6,
                                ),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: ErpTheme.slate200,
                                    ),
                                    bottom: BorderSide(
                                      color: ErpTheme.slate200,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            itemName,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              color: ErpTheme.hrIndigo,
                                              height: 1.15,
                                            ),
                                          ),
                                        ),
                                        if (canRemove)
                                          InkWell(
                                            onTap: () async {
                                              if (roleColTotal > 0) {
                                                final confirm =
                                                    await showDialog<bool>(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: const Text(
                                                      'Remove Column?',
                                                    ),
                                                    content: Text(
                                                      'Remove "$itemName" column and clear entered quantities ($roleColTotal ${product?.unit ?? 'Pcs'}) for $role workers?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(ctx)
                                                                .pop(false),
                                                        child: const Text(
                                                          'Cancel',
                                                        ),
                                                      ),
                                                      FilledButton(
                                                        style:
                                                            FilledButton.styleFrom(
                                                          backgroundColor:
                                                              ErpTheme
                                                                  .dangerRose,
                                                        ),
                                                        onPressed: () =>
                                                            Navigator.of(ctx)
                                                                .pop(true),
                                                        child: const Text(
                                                          'Remove',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) {
                                                  vm.removeActiveItemForRole(
                                                    role,
                                                    itemName,
                                                    clearDraft: true,
                                                  );
                                                }
                                              } else {
                                                vm.removeActiveItemForRole(
                                                  role,
                                                  itemName,
                                                );
                                              }
                                            },
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: const Padding(
                                              padding: EdgeInsets.all(2),
                                              child: Icon(
                                                Icons.close_rounded,
                                                size: 13,
                                                color: ErpTheme.dangerRose,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    Text(
                                      product?.unit ?? 'Pcs',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: ErpTheme.slate500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                        // Worker Total Column Header
                        Container(
                          width: totalColWidth,
                          height: _headerHeight,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: ErpTheme.slate200),
                            ),
                          ),
                          child: Text(
                            isFirstDepartment ? 'WORKER\nTOTAL' : 'TOTAL',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: ErpTheme.slate700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Worker Rows
                  for (final emp in roleWorkers) ...[
                    Builder(
                      builder: (context) {
                        final empTotal = vm.getWorkerTotalQuantity(emp.id);
                        return Container(
                          height: _workerRowHeight,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(color: ErpTheme.slate200),
                            ),
                          ),
                          child: Row(
                            children: [
                              for (final itemName in roleItems) ...[
                                Builder(
                                  builder: (context) {
                                    final key = _cellKey(emp.id, itemName);
                                    final node = _focusNodeFor(key);
                                    return Container(
                                      width: itemColWidth,
                                      height: _workerRowHeight,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 8,
                                      ),
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          right: BorderSide(
                                            color: ErpTheme.slate200,
                                          ),
                                        ),
                                      ),
                                      child: _MatrixQtyCell(
                                        key: ValueKey(
                                          'matrix_${emp.id}_$itemName',
                                        ),
                                        focusNode: node,
                                        quantity: vm.getQuantity(
                                          emp.id,
                                          itemName,
                                        ),
                                        onChanged: (q) => vm.setQuantity(
                                          emp.id,
                                          itemName,
                                          q,
                                        ),
                                        onSubmitNext: () => _focusNextCell(
                                          key,
                                          columnMajorKeys,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                              Container(
                                width: totalColWidth,
                                height: _workerRowHeight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                alignment: Alignment.center,
                                child: Text(
                                  '$empTotal',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13.5,
                                    color: empTotal > 0
                                        ? ErpTheme.ordersEmerald
                                        : ErpTheme.slate500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  // Subtotal Footer Row
                  Container(
                    height: _footerHeight,
                    decoration: BoxDecoration(
                      color: roleStyle.bg.withValues(alpha: 0.5),
                      border: Border(
                        top: BorderSide(color: roleStyle.border, width: 1.5),
                        bottom: const BorderSide(color: ErpTheme.slate200),
                      ),
                    ),
                    child: Row(
                      children: [
                        for (final itemName in roleItems) ...[
                          Builder(
                            builder: (context) {
                              final colTotal = vm.getRoleItemTotalQuantity(
                                role,
                                itemName,
                              );
                              return Container(
                                width: itemColWidth,
                                height: _footerHeight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: ErpTheme.slate200,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  '${inrFormat.format(colTotal)} pcs',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    color: roleStyle.text,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                        Container(
                          width: totalColWidth,
                          height: _footerHeight,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.center,
                          child: Text(
                            '${inrFormat.format(roleTotal)} pcs',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: roleStyle.text,
                            ),
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
      ],
    );
  }

  Widget _buildStickyBottomBar(
    DailyProductionViewModel vm,
    NumberFormat inrFormat,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: ErpTheme.slate200, width: 1.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Factory Total Entry',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: ErpTheme.slate500,
                  ),
                ),
                Text(
                  '${vm.activeWorkersLoggedCount} Workers • ${inrFormat.format(vm.totalPiecesEntered)} Pcs',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: ErpTheme.slate900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            key: const ValueKey('matrix-save-button-bottom'),
            style: FilledButton.styleFrom(
              backgroundColor: ErpTheme.productionAmber,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: vm.isSaving ? null : widget.onSaveMatrix,
            icon: vm.isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 16),
            label: Text(
              vm.isSaving
                  ? 'Saving...'
                  : 'Save All (${vm.filteredWorkers.length})',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickQtyPill extends StatelessWidget {
  const _QuickQtyPill({
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? ErpTheme.hrIndigo : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        canRequestFocus: false,
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: highlighted ? ErpTheme.hrIndigo : ErpTheme.slate200,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: highlighted ? Colors.white : ErpTheme.slate900,
            ),
          ),
        ),
      ),
    );
  }
}

class _MatrixQtyCell extends StatefulWidget {
  const _MatrixQtyCell({
    required this.quantity,
    required this.onChanged,
    this.focusNode,
    this.onSubmitNext,
    super.key,
  });

  final int quantity;
  final ValueChanged<int> onChanged;
  final FocusNode? focusNode;
  final VoidCallback? onSubmitNext;

  @override
  State<_MatrixQtyCell> createState() => _MatrixQtyCellState();
}

class _MatrixQtyCellState extends State<_MatrixQtyCell> {
  late final TextEditingController _ctrl;
  late FocusNode _focus;
  bool _ownsFocusNode = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.quantity > 0 ? '${widget.quantity}' : '',
    );
    _ownsFocusNode = widget.focusNode == null;
    _focus = (widget.focusNode ?? FocusNode())..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant _MatrixQtyCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _focus.removeListener(_handleFocusChange);
      if (_ownsFocusNode) {
        _focus.dispose();
      }
      _ownsFocusNode = widget.focusNode == null;
      _focus = (widget.focusNode ?? FocusNode())
        ..addListener(_handleFocusChange);
    }
    if (oldWidget.quantity != widget.quantity) {
      final currentParsed = int.tryParse(_ctrl.text.trim()) ?? 0;
      if (!_focus.hasFocus || currentParsed != widget.quantity) {
        final next = widget.quantity > 0 ? '${widget.quantity}' : '';
        if (_ctrl.text != next) {
          _ctrl.value = TextEditingValue(
            text: next,
            selection: TextSelection.collapsed(offset: next.length),
          );
        }
      }
    }
  }

  void _handleFocusChange() {
    if (!_focus.hasFocus) {
      final parsed = int.tryParse(_ctrl.text.trim()) ?? 0;
      final normalized = parsed > 0 ? '$parsed' : '';
      if (_ctrl.text != normalized) {
        _ctrl.text = normalized;
      }
      if (parsed != widget.quantity) {
        widget.onChanged(parsed);
      }
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_handleFocusChange);
    if (_ownsFocusNode) {
      _focus.dispose();
    }
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      focusNode: _focus,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      textAlign: TextAlign.center,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      style: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 13.5,
        color: widget.quantity > 0 ? ErpTheme.hrIndigo : ErpTheme.slate700,
      ),
      decoration: InputDecoration(
        hintText: '0',
        hintStyle: const TextStyle(color: ErpTheme.slate500),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        fillColor: widget.quantity > 0
            ? ErpTheme.hrIndigoSoft.withValues(alpha: 0.45)
            : ErpTheme.slate50,
      ),
      onChanged: (raw) => widget.onChanged(int.tryParse(raw.trim()) ?? 0),
      onEditingComplete: widget.onSubmitNext ?? _focus.nextFocus,
    );
  }
}
