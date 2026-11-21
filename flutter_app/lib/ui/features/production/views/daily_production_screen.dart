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
  bool _isSearching = false;
  bool _showHistoryTab = false;
  bool _isMatrixFocusMode = false;
  WorkerNameDisplayMode _nameDisplayMode = WorkerNameDisplayMode.tamil;

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
        final inFocusMatrix = !_showHistoryTab && _isMatrixFocusMode;
        final now = DateTime.now();
        final todayNormalized = DateTime(now.year, now.month, now.day);
        final selectedNormalized = DateTime(
          vm.selectedDate.year,
          vm.selectedDate.month,
          vm.selectedDate.day,
        );
        final isToday = selectedNormalized == todayNormalized;
        final dateLabel = DateFormat('EEE, dd MMM yyyy').format(vm.selectedDate);

        final isLandscape =
            MediaQuery.orientationOf(context) == Orientation.landscape;
        final screenHeight = MediaQuery.sizeOf(context).height;
        final isLandscapePhone = isLandscape && screenHeight < 550;

        return Scaffold(
          appBar: isEmbedded
              ? null
              : AppBar(
                  toolbarHeight: isLandscapePhone ? 42.0 : null,
                  title: _isSearching
                      ? TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: vm.setWorkerSearch,
                          style: const TextStyle(fontSize: 14, color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Filter worker name, role or unit...',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                            border: InputBorder.none,
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.white70,
                              size: 18,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white70,
                                size: 18,
                              ),
                              onPressed: () {
                                setState(() => _isSearching = false);
                                _searchController.clear();
                                vm.setWorkerSearch('');
                              },
                            ),
                          ),
                        )
                      : isLandscapePhone
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Daily Production',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  '•',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: InkWell(
                                    key: const ValueKey(
                                        'daily-production-date-picker'),
                                    onTap: _pickDate,
                                    borderRadius: BorderRadius.circular(4),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.calendar_today_rounded,
                                            size: 11,
                                            color: ErpTheme.productionAmber,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              isToday
                                                  ? 'Today ($dateLabel)'
                                                  : dateLabel,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: ErpTheme.slate700,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_drop_down,
                                            size: 14,
                                            color: ErpTheme.slate700,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Daily Production',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                InkWell(
                                  key: const ValueKey('daily-production-date-picker'),
                                  onTap: _pickDate,
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 1),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_rounded,
                                          size: 11,
                                          color: ErpTheme.productionAmber,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isToday ? 'Today ($dateLabel)' : dateLabel,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: ErpTheme.slate700,
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          size: 14,
                                          color: ErpTheme.slate700,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                  actions: [
                    if (!_isSearching && !_showHistoryTab)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Search Workers',
                        icon: const Icon(Icons.search_rounded),
                        onPressed: () => setState(() => _isSearching = true),
                      ),
                    if (!_showHistoryTab)
                      IconButton(
                        visualDensity: VisualDensity.compact,
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
                      visualDensity: VisualDensity.compact,
                      tooltip: _showHistoryTab ? 'Back to Matrix' : 'Saved Logs',
                      onPressed: () => setState(() {
                        _showHistoryTab = !_showHistoryTab;
                        if (_showHistoryTab) {
                          _isMatrixFocusMode = false;
                        }
                      }),
                      icon: Badge(
                        isLabelVisible:
                            vm.recentHistory.isNotEmpty && !_showHistoryTab,
                        label: Text('${vm.recentHistory.length}'),
                        child: Icon(
                          _showHistoryTab
                              ? Icons.grid_on_rounded
                              : Icons.history_rounded,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
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
                        'Log daily WIP quantities across departments in Production Matrix.',
                    accentColor: ErpTheme.productionAmber,
                    actions: [
                      OutlinedButton.icon(
                        key: const ValueKey('embedded-date-picker-button'),
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today_rounded, size: 14),
                        label: Text(
                          isToday ? 'Today ($dateLabel)' : dateLabel,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: vm.isLoading ? null : vm.refreshAll,
                        icon: const Icon(Icons.refresh_rounded),
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
                    : _buildEntryWorkspace(vm),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEntryWorkspace(DailyProductionViewModel vm) {
    if (vm.filteredWorkers.isEmpty) {
      return RefreshIndicator(
        onRefresh: vm.refreshAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            ErpEmptyState(
              icon: Icons.engineering_outlined,
              title: 'No Matching Active Workers',
              subtitle:
                  'Add Contractual workers in the Workers & Advances tab.',
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      child: Column(
        children: [
          if (vm.hasRestoredLocalDraft) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: ErpTheme.productionAmberSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ErpTheme.productionAmber.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.offline_pin_outlined,
                    size: 16,
                    color: ErpTheme.productionAmber,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Restored unsaved offline draft for this date. Tap Save to sync.',
                      style: TextStyle(
                        fontSize: 11.5,
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
          Expanded(
            child: _ProductionMatrixCard(
              viewModel: vm,
              isFocusMode: false,
              nameDisplayMode: _nameDisplayMode,
              onNameDisplayModeChanged: (mode) =>
                  setState(() => _nameDisplayMode = mode),
              onToggleFocusMode: () =>
                  setState(() => _isMatrixFocusMode = true),
              onOpenWipPicker: () => _openWipItemPicker(),
              onClearMatrix: _confirmClearMatrix,
              onSaveMatrix: _handleSave,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixFocusWorkspace(DailyProductionViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: vm.filteredWorkers.isEmpty
          ? const ErpEmptyState(
              icon: Icons.engineering_outlined,
              title: 'No Matching Active Workers',
              subtitle:
                  'Add Contractual workers in the Workers & Advances tab.',
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
    );
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

  bool _isNewFocusDigit = true;

  String _cellKey(int empId, String itemName) => '$empId::$itemName';

  void _updateFocusedKey(String key, bool hasFocus) {
    final next = hasFocus ? key : (_focusedKey == key ? null : _focusedKey);
    if (next == _focusedKey) return;
    _isNewFocusDigit = true;
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

  void _unfocusCurrentCell() {
    if (_focusedKey != null) {
      _cellFocusNodes[_focusedKey]?.unfocus();
      setState(() => _focusedKey = null);
    }
  }

  void _onKeypadDigit(
    int digit,
    int empId,
    String itemName,
    DailyProductionViewModel vm,
  ) {
    final current = vm.getQuantity(empId, itemName);
    final int next;
    if (_isNewFocusDigit) {
      next = digit;
      _isNewFocusDigit = false;
    } else {
      final str = '$current$digit';
      if (str.length > 6) return;
      next = int.tryParse(str) ?? current;
    }
    vm.setQuantity(empId, itemName, next);
  }

  void _onKeypadDoubleZero(
    int empId,
    String itemName,
    DailyProductionViewModel vm,
  ) {
    final current = vm.getQuantity(empId, itemName);
    if (_isNewFocusDigit || current == 0) {
      vm.setQuantity(empId, itemName, 0);
      _isNewFocusDigit = false;
      return;
    }
    final str = '${current}00';
    if (str.length > 6) return;
    final next = int.tryParse(str) ?? current;
    vm.setQuantity(empId, itemName, next);
  }

  void _onKeypadBackspace(
    int empId,
    String itemName,
    DailyProductionViewModel vm,
  ) {
    final current = vm.getQuantity(empId, itemName);
    final next = current ~/ 10;
    _isNewFocusDigit = false;
    vm.setQuantity(empId, itemName, next);
  }

  void _onKeypadClear(
    int empId,
    String itemName,
    DailyProductionViewModel vm,
  ) {
    _isNewFocusDigit = true;
    vm.setQuantity(empId, itemName, 0);
  }

  void _onKeypadDelta(
    int delta,
    int empId,
    String itemName,
    DailyProductionViewModel vm,
  ) {
    _isNewFocusDigit = false;
    vm.incrementQuantity(empId, itemName, delta);
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
          final isLandscape =
              MediaQuery.orientationOf(context) == Orientation.landscape;
          final hasKeypad = activeMeta != null && _focusedKey != null;
          final useSideBySideKeypad =
              hasKeypad && (isLandscape || constraints.maxWidth >= 600);

          if (useSideBySideKeypad) {
            final sideKeypadWidth =
                (constraints.maxWidth * 0.38).clamp(275.0, 340.0);
            final leftPaneWidth = constraints.maxWidth - sideKeypadWidth - 1.0;
            final isLeftCompact = leftPaneWidth < 500;
            final workerColWidth = isLeftCompact ? 130.0 : 160.0;
            final baseItemWidth = isLeftCompact ? 94.0 : 120.0;
            final totalColWidth = isLeftCompact ? 70.0 : 86.0;

            final stackedCards = _buildDepartmentStackedCards(
              vm: vm,
              groupedRoles: groupedRoles,
              columnMajorKeys: columnMajorKeys,
              workerColWidth: workerColWidth,
              baseItemWidth: baseItemWidth,
              totalColWidth: totalColWidth,
              availableWidth: leftPaneWidth,
              inrFormat: inrFormat,
              nameDisplayMode: _nameDisplayMode,
            );

            final bodyScroll = SingleChildScrollView(
              controller: _bodyVScroll,
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: stackedCards,
            );

            final rightKeypad = SizedBox(
              width: sideKeypadWidth,
              child: _buildDockedKeypad(
                vm: vm,
                cellKey: _focusedKey!,
                empId: activeMeta.empId,
                empName: activeMeta.empName,
                itemName: activeMeta.itemName,
                columnMajorKeys: columnMajorKeys,
                inrFormat: inrFormat,
                isSideBySide: true,
              ),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildToolbar(
                  vm,
                  items,
                  isLandscape: isLandscape || constraints.maxWidth >= 600,
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: bodyScroll),
                      const VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: ErpTheme.slate200,
                      ),
                      rightKeypad,
                    ],
                  ),
                ),
              ],
            );
          }

          final isCompact = constraints.maxWidth < 600;
          final workerColWidth = isCompact ? 132.0 : 176.0;
          final baseItemWidth = isCompact ? 98.0 : 136.0;
          final totalColWidth = isCompact ? 72.0 : 92.0;

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

          final useBoundedExpand = constraints.hasBoundedHeight &&
              constraints.maxHeight >= 240;
          final screenHeight = MediaQuery.sizeOf(context).height;
          final maxCardHeight = (screenHeight *
                  (widget.isFocusMode ? 0.72 : (hasKeypad ? 0.30 : 0.50)))
              .clamp(hasKeypad ? 160.0 : 260.0, 700.0);
          final bodyWrapper = useBoundedExpand
              ? Expanded(child: bodyScroll)
              : ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: maxCardHeight,
                  ),
                  child: bodyScroll,
                );

          return Column(
            mainAxisSize:
                useBoundedExpand ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildToolbar(
                vm,
                items,
                isLandscape: isLandscape || constraints.maxWidth >= 600,
              ),
              bodyWrapper,
              if (hasKeypad)
                _buildDockedKeypad(
                  vm: vm,
                  cellKey: _focusedKey!,
                  empId: activeMeta.empId,
                  empName: activeMeta.empName,
                  itemName: activeMeta.itemName,
                  columnMajorKeys: columnMajorKeys,
                  inrFormat: inrFormat,
                  isSideBySide: false,
                )
              else
                _buildStickyBottomBar(vm, inrFormat),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToolbar(
    DailyProductionViewModel vm,
    List<String> items, {
    bool isLandscape = false,
  }) {
    final addColumnDropdown = Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ErpTheme.slate200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedWipProductToAdd,
          icon: const Icon(
            Icons.arrow_drop_down,
            size: 18,
            color: ErpTheme.slate500,
          ),
          hint: const Row(
            children: [
              Icon(
                Icons.add_chart_rounded,
                size: 14,
                color: ErpTheme.productionAmber,
              ),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Add Product Column (e.g. 10 KVR 48)...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
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
                        fontWeight:
                            alreadyAdded ? FontWeight.w500 : FontWeight.w700,
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
    );

    final addColumnButton = FilledButton.icon(
      key: const ValueKey('matrix-add-column-button'),
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        backgroundColor: ErpTheme.productionAmber,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: _selectedWipProductToAdd == null ||
              items.contains(_selectedWipProductToAdd)
          ? null
          : () {
              vm.addActiveItem(_selectedWipProductToAdd!);
              setState(() => _selectedWipProductToAdd = null);
            },
      icon: const Icon(Icons.add_rounded, size: 15),
      label: const Text(
        '+ Add Column',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    final focusButton = OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: widget.onToggleFocusMode,
      icon: Icon(
        widget.isFocusMode
            ? Icons.fullscreen_exit_rounded
            : Icons.fullscreen_rounded,
        size: 14,
      ),
      label: Text(
        widget.isFocusMode ? 'Exit Focus' : 'Focus Grid',
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    final saveButton = FilledButton.icon(
      key: const ValueKey('matrix-save-button-top'),
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        backgroundColor: ErpTheme.productionAmber,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: vm.isSaving ? null : widget.onSaveMatrix,
      icon: vm.isSaving
          ? const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.save_rounded, size: 14),
      label: Text(
        vm.isSaving ? 'Saving...' : 'Save Worksheet',
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

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
                      : (tamil.isNotEmpty
                          ? '$role • $tamil ($count)'
                          : '$role ($count)');
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
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
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
        // Action & Quick Add Column Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: const BoxDecoration(
            color: ErpTheme.slate50,
            border: Border(bottom: BorderSide(color: ErpTheme.slate200)),
          ),
          child: isLandscape
              ? Row(
                  children: [
                    focusButton,
                    const SizedBox(width: 8),
                    Expanded(child: addColumnDropdown),
                    const SizedBox(width: 6),
                    addColumnButton,
                    const SizedBox(width: 8),
                    saveButton,
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        focusButton,
                        const SizedBox(width: 6),
                        saveButton,
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(child: addColumnDropdown),
                        const SizedBox(width: 6),
                        addColumnButton,
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }
  Widget _buildDockedKeypad({
    required DailyProductionViewModel vm,
    required String cellKey,
    required int empId,
    required String empName,
    required String itemName,
    required List<String> columnMajorKeys,
    required NumberFormat inrFormat,
    bool isSideBySide = false,
  }) {
    final currentQty = vm.getQuantity(empId, itemName);
    final btnHeight = isSideBySide ? 28.0 : 32.0;
    final stepperHeight = isSideBySide ? 24.0 : 28.0;
    final btnFontSize = isSideBySide ? 13.0 : 14.0;
    final spacing = isSideBySide ? 3.0 : 4.0;

    final keypadContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 2. Quick Stepper Pills (+10, +25, +50, +100, 0)
        Row(
          children: [
            for (final delta in const [10, 25, 50, 100])
              _KeypadButton(
                label: '+$delta',
                height: stepperHeight,
                fontSize: isSideBySide ? 10.0 : 11.0,
                backgroundColor: ErpTheme.hrIndigoSoft,
                foregroundColor: ErpTheme.hrIndigo,
                onTap: () => _onKeypadDelta(delta, empId, itemName, vm),
              ),
            _KeypadButton(
              label: 'Clear',
              height: stepperHeight,
              fontSize: isSideBySide ? 10.0 : 10.5,
              backgroundColor: ErpTheme.slate100,
              foregroundColor: ErpTheme.slate700,
              onTap: () => _onKeypadClear(empId, itemName, vm),
            ),
          ],
        ),
        SizedBox(height: spacing),

        // 3. Number Row 1: 1, 2, 3, ⌫
        Row(
          children: [
            _KeypadButton(
              label: '1',
              height: btnHeight,
              fontSize: btnFontSize,
              onTap: () => _onKeypadDigit(1, empId, itemName, vm),
            ),
            _KeypadButton(
              label: '2',
              height: btnHeight,
              fontSize: btnFontSize,
              onTap: () => _onKeypadDigit(2, empId, itemName, vm),
            ),
            _KeypadButton(
              label: '3',
              height: btnHeight,
              fontSize: btnFontSize,
              onTap: () => _onKeypadDigit(3, empId, itemName, vm),
            ),
            _KeypadButton(
              label: '⌫',
              height: btnHeight,
              fontSize: btnFontSize,
              icon: Icons.backspace_outlined,
              backgroundColor: ErpTheme.slate100,
              foregroundColor: ErpTheme.slate700,
              onTap: () => _onKeypadBackspace(empId, itemName, vm),
            ),
          ],
        ),
        SizedBox(height: spacing),

        // 4. Number Row 2: 4, 5, 6, 00
        Row(
          children: [
            _KeypadButton(
              label: '4',
              height: btnHeight,
              fontSize: btnFontSize,
              onTap: () => _onKeypadDigit(4, empId, itemName, vm),
            ),
            _KeypadButton(
              label: '5',
              height: btnHeight,
              fontSize: btnFontSize,
              onTap: () => _onKeypadDigit(5, empId, itemName, vm),
            ),
            _KeypadButton(
              label: '6',
              height: btnHeight,
              fontSize: btnFontSize,
              onTap: () => _onKeypadDigit(6, empId, itemName, vm),
            ),
            _KeypadButton(
              label: '00',
              height: btnHeight,
              fontSize: btnFontSize,
              backgroundColor: ErpTheme.slate50,
              onTap: () => _onKeypadDoubleZero(empId, itemName, vm),
            ),
          ],
        ),
        SizedBox(height: spacing),

        // 5. Number Row 3: 7, 8, 9, 0
        Row(
          children: [
            _KeypadButton(
              label: '7',
              height: btnHeight,
              fontSize: btnFontSize,
              onTap: () => _onKeypadDigit(7, empId, itemName, vm),
            ),
            _KeypadButton(
              label: '8',
              height: btnHeight,
              fontSize: btnFontSize,
              onTap: () => _onKeypadDigit(8, empId, itemName, vm),
            ),
            _KeypadButton(
              label: '9',
              height: btnHeight,
              fontSize: btnFontSize,
              onTap: () => _onKeypadDigit(9, empId, itemName, vm),
            ),
            _KeypadButton(
              label: '0',
              height: btnHeight,
              fontSize: btnFontSize,
              onTap: () => _onKeypadDigit(0, empId, itemName, vm),
            ),
          ],
        ),
        SizedBox(height: spacing),

        // 6. Action Bar: Next Worker ↓
        Row(
          children: [
            Container(
              height: isSideBySide ? 30 : 34,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: ErpTheme.slate100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ErpTheme.slate200),
              ),
              alignment: Alignment.center,
              child: Text(
                '${inrFormat.format(vm.totalPiecesEntered)} pcs',
                style: TextStyle(
                  fontSize: isSideBySide ? 10.5 : 11,
                  fontWeight: FontWeight.w800,
                  color: ErpTheme.slate700,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: SizedBox(
                height: isSideBySide ? 30 : 34,
                child: FilledButton.icon(
                  key: const ValueKey('matrix-next-worker-button'),
                  style: FilledButton.styleFrom(
                    backgroundColor: ErpTheme.productionAmber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    _isNewFocusDigit = true;
                    _focusNextCell(cellKey, columnMajorKeys);
                  },
                  icon: const Icon(Icons.arrow_downward_rounded, size: 15),
                  label: Text(
                    'Next ↓',
                    style: TextStyle(
                      fontSize: isSideBySide ? 11 : 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    return Container(
      key: const ValueKey('matrix-docked-keypad'),
      decoration: BoxDecoration(
        color: Colors.white,
        border: isSideBySide
            ? const Border(left: BorderSide(color: ErpTheme.slate200, width: 1.5))
            : const Border(top: BorderSide(color: ErpTheme.slate200, width: 1.5)),
      ),
      child: Column(
        mainAxisSize: isSideBySide ? MainAxisSize.max : MainAxisSize.min,
        children: [
          // 1. Context Strip: Worker Name • WIP Item = Qty
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: const BoxDecoration(
              color: ErpTheme.slate50,
              border: Border(bottom: BorderSide(color: ErpTheme.slate200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        empName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: ErpTheme.slate900,
                        ),
                      ),
                      Text(
                        itemName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: ErpTheme.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ErpTheme.hrIndigoSoft,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: ErpTheme.hrIndigo.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${inrFormat.format(currentQty)} pcs',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: ErpTheme.hrIndigo,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  tooltip: 'Done / Close Keypad',
                  onPressed: _unfocusCurrentCell,
                ),
              ],
            ),
          ),

          if (isSideBySide)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                child: keypadContent,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
              child: keypadContent,
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
                  'Worksheet Summary',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: ErpTheme.slate500,
                  ),
                ),
                Text(
                  '${vm.activeWorkersLoggedCount} Workers • ${inrFormat.format(vm.totalPiecesEntered)} Pcs',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              visualDensity: VisualDensity.compact,
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
                  : 'Save Whole Sheet',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.backgroundColor = Colors.white,
    this.foregroundColor = ErpTheme.slate900,
    this.height = 32.0,
    this.fontSize = 14.0,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(7),
          child: InkWell(
            canRequestFocus: false,
            borderRadius: BorderRadius.circular(7),
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: ErpTheme.slate200),
              ),
              alignment: Alignment.center,
              child: icon != null
                  ? Icon(icon, size: fontSize + 1, color: foregroundColor)
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w800,
                        color: foregroundColor,
                      ),
                    ),
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
      readOnly: true,
      showCursor: true,
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
            : (_focus.hasFocus
                ? ErpTheme.hrIndigoSoft.withValues(alpha: 0.25)
                : ErpTheme.slate50),
      ),
      onChanged: (raw) => widget.onChanged(int.tryParse(raw.trim()) ?? 0),
      onEditingComplete: widget.onSubmitNext ?? _focus.nextFocus,
    );
  }
}
