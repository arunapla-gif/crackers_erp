import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/domain/models/daily_production.dart';
import 'package:crackers_erp/domain/models/wip_product.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/core/erp_crud_widgets.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/features/auth/view_models/auth_view_model.dart';
import 'package:crackers_erp/ui/features/production/view_models/daily_production_view_model.dart';
import 'daily_production_matrix_page.dart';
import 'daily_production_pdf.dart';
import 'quick_temp_worker_sheet.dart';

/// Screen 1: Daily Production Hub
///
/// Preparation & Overview page:
/// 1. Date selection & status summary.
/// 2. Active WIP Products picker & checklist.
/// 3. Department breakdown cards.
/// 4. Quick actions (Copy Yesterday, Print PDF, Export CSV).
/// 5. Prominent [Open Matrix Entry Workspace] CTA leading to Screen 2.
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

  Future<void> _openMatrixPage({String roleFilter = 'All'}) async {
    widget.viewModel.setWorkerSearch('');
    widget.viewModel.setRoleFilter(roleFilter);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DailyProductionMatrixPage(
          viewModel: widget.viewModel,
          authViewModel: widget.authViewModel,
          initialRoleFilter: roleFilter,
        ),
      ),
    );
    if (mounted) {
      widget.viewModel.setWorkerSearch('');
      widget.viewModel.setRoleFilter('All');
    }
  }

  Future<void> _handleSaveFromHub() async {
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

  Future<void> _handleCopyYesterday() async {
    final vm = widget.viewModel;
    if (vm.hasUnsavedChanges) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
            'You have unsaved changes on the current worksheet. Copying yesterday will replace unsaved values. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: ErpTheme.productionAmber,
              ),
              child: const Text('Copy Yesterday'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    final success = await vm.copyFromPreviousDay();
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.statusMessage ?? 'Yesterday prefilled successfully.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } else if (vm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage!),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _handlePrintWorksheet() async {
    final vm = widget.viewModel;
    await Printing.layoutPdf(
      name: 'Daily_Production_${vm.selectedIsoDate}.pdf',
      onLayout: (_) => buildDailyProductionPdf(vm),
    );
  }

  void _handleExportCsv() {
    final vm = widget.viewModel;
    final csvData = vm.generateCsv();
    Clipboard.setData(ClipboardData(text: csvData));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Production CSV copied to clipboard (${vm.totalPiecesEntered} pcs).',
        ),
        backgroundColor: Colors.indigo.shade700,
        action: SnackBarAction(
          label: 'Print PDF',
          textColor: Colors.amber,
          onPressed: _handlePrintWorksheet,
        ),
      ),
    );
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
        var selectedCategory = 'All';
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return ListenableBuilder(
              listenable: widget.viewModel,
              builder: (ctx, _) {
                final vm = widget.viewModel;
                final q = searchController.text.trim().toLowerCase();
                final allSorted = vm.sortedWipProducts;
                final categories = <String>{
                  for (final p in allSorted)
                    if ((p.category ?? '').trim().isNotEmpty)
                      p.category!.trim(),
                }.toList()
                  ..sort(DailyProductionViewModel.compareRoles);

                final items = allSorted.where((p) {
                  if (selectedCategory != 'All' &&
                      (p.category ?? '').trim().toLowerCase() !=
                          selectedCategory.toLowerCase()) {
                    return false;
                  }
                  if (q.isEmpty) return true;
                  return p.name.toLowerCase().contains(q) ||
                      (p.category ?? '').toLowerCase().contains(q) ||
                      (p.subCategory ?? '').toLowerCase().contains(q) ||
                      p.displayGroup.toLowerCase().contains(q) ||
                      p.code.toLowerCase().contains(q);
                }).toList();

                final entries = <Object>[];
                String? lastGroupKey;
                for (final prod in items) {
                  final cat = (prod.category ?? '').trim();
                  final sub = (prod.subCategory ?? '').trim();
                  final groupLabel = selectedCategory != 'All'
                      ? (sub.isNotEmpty ? sub : 'General')
                      : [
                          if (cat.isNotEmpty) cat,
                          if (sub.isNotEmpty) sub,
                        ].isEmpty
                          ? 'General WIP'
                          : [
                              if (cat.isNotEmpty) cat,
                              if (sub.isNotEmpty) sub,
                            ].join(' • ');
                  if (groupLabel != lastGroupKey) {
                    entries.add(groupLabel);
                    lastGroupKey = groupLabel;
                  }
                  entries.add(prod);
                }

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
                                      : 'Select / Pin WIP Items for Today',
                                  style: const TextStyle(
                                    fontSize: 16,
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
                              hintText:
                                  'Search WIP product, count, or category...',
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
                        if (categories.length > 1) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 34,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text('All (${allSorted.length})'),
                                    selected: selectedCategory == 'All',
                                    visualDensity: VisualDensity.compact,
                                    onSelected: (_) => setSheetState(
                                      () => selectedCategory = 'All',
                                    ),
                                  ),
                                ),
                                for (final cat in categories)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text(cat),
                                      selected: selectedCategory == cat,
                                      visualDensity: VisualDensity.compact,
                                      onSelected: (_) => setSheetState(
                                        () => selectedCategory = cat,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
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
                                  itemCount: entries.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 6),
                                  itemBuilder: (ctx, idx) {
                                    final entry = entries[idx];
                                    if (entry is String) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          top: idx == 0 ? 2 : 8,
                                          bottom: 2,
                                          left: 2,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: ErpTheme.hrIndigoSoft,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                entry.toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w900,
                                                  color: ErpTheme.hrIndigo,
                                                  letterSpacing: 0.4,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Expanded(
                                              child: Divider(
                                                height: 1,
                                                color: ErpTheme.slate200,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    final prod = entry as WipProduct;
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
                                                    : Icons
                                                          .star_outline_rounded,
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

  Future<void> _confirmRemoveWipItem(
    String itemName,
    int itemTotal,
    String unit,
  ) async {
    if (itemTotal <= 0) {
      widget.viewModel.removeActiveItem(itemName);
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove WIP Product?'),
        content: Text(
          'Remove "$itemName" and clear its entered quantities ($itemTotal $unit) for ${widget.viewModel.selectedIsoDate}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: ErpTheme.dangerRose),
            child: const Text('Remove & Clear'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      widget.viewModel.removeActiveItem(itemName, clearDraft: true);
    }
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
        final now = DateTime.now();
        final todayNormalized = DateTime(now.year, now.month, now.day);
        final selectedNormalized = DateTime(
          vm.selectedDate.year,
          vm.selectedDate.month,
          vm.selectedDate.day,
        );
        final isToday = selectedNormalized == todayNormalized;
        final dateLabel = DateFormat(
          'EEE, dd MMM yyyy',
        ).format(vm.selectedDate);

        return Scaffold(
          backgroundColor: ErpTheme.slate50,
          appBar: isEmbedded
              ? null
              : AppBar(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Daily Production Hub',
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
                              Flexible(
                                child: Text(
                                  isToday ? 'Today ($dateLabel)' : dateLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: ErpTheme.slate700,
                                  ),
                                ),
                              ),
                              const Icon(
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
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: _showHistoryTab
                          ? 'Back to Setup Hub'
                          : 'Saved Logs',
                      onPressed: () =>
                          setState(() => _showHistoryTab = !_showHistoryTab),
                      icon: Badge(
                        isLabelVisible:
                            vm.recentHistory.isNotEmpty && !_showHistoryTab,
                        label: Text('${vm.recentHistory.length}'),
                        child: Icon(
                          _showHistoryTab
                              ? Icons.dashboard_customize_rounded
                              : Icons.history_rounded,
                        ),
                      ),
                    ),
                    if (MediaQuery.sizeOf(context).width >= 500)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Refresh',
                        onPressed: vm.isLoading ? null : vm.refreshAll,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    PopupMenuButton<String>(
                      tooltip: 'Worksheet Actions',
                      icon: const Icon(Icons.more_vert_rounded),
                      onSelected: (val) {
                        if (val == 'refresh') {
                          if (!vm.isLoading) vm.refreshAll();
                        } else if (val == 'copy_yesterday') {
                          _handleCopyYesterday();
                        } else if (val == 'print') {
                          _handlePrintWorksheet();
                        } else if (val == 'csv') {
                          _handleExportCsv();
                        }
                      },
                      itemBuilder: (ctx) => [
                        if (MediaQuery.sizeOf(context).width < 500)
                          const PopupMenuItem(
                            value: 'refresh',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.refresh_rounded,
                                  size: 18,
                                  color: ErpTheme.slate700,
                                ),
                                SizedBox(width: 10),
                                Text('Refresh Worksheet'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'copy_yesterday',
                          child: Row(
                            children: [
                              Icon(
                                Icons.content_copy_rounded,
                                size: 18,
                                color: ErpTheme.productionAmber,
                              ),
                              SizedBox(width: 10),
                              Text('Copy Yesterday\'s Worksheet'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'print',
                          child: Row(
                            children: [
                              Icon(
                                Icons.print_rounded,
                                size: 18,
                                color: ErpTheme.hrIndigo,
                              ),
                              SizedBox(width: 10),
                              Text('Print Production Sheet (PDF)'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'csv',
                          child: Row(
                            children: [
                              Icon(
                                Icons.table_chart_rounded,
                                size: 18,
                                color: ErpTheme.ordersEmerald,
                              ),
                              SizedBox(width: 10),
                              Text('Export CSV Data'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    AccountAppBarAction(
                      authViewModel: widget.authViewModel,
                      hasUnsavedProduction: vm.hasUnsavedChanges,
                    ),
                  ],
                ),
          body: Column(
            children: [
              if (isEmbedded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
                  child: ErpSectionHeaderBar(
                    title: 'Daily Production Hub',
                    subtitle:
                        'Prepare WIP items, review day summary, and launch dedicated Matrix.',
                    accentColor: ErpTheme.productionAmber,
                    actions: [
                      OutlinedButton.icon(
                        key: const ValueKey('embedded-date-picker-button'),
                        onPressed: _pickDate,
                        icon: const Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                        ),
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
                    : _buildHubWorkspace(vm),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHubWorkspace(DailyProductionViewModel vm) {
    final inrFormat = NumberFormat('#,##,##0', 'en_IN');
    final activeItems = vm.activeItemNames;
    final totalWorkers = vm.filteredWorkers.length;
    final loggedWorkers = vm.activeWorkersLoggedCount;
    final now = DateTime.now();
    final todayNormalized = DateTime(now.year, now.month, now.day);
    final selectedNormalized = DateTime(
      vm.selectedDate.year,
      vm.selectedDate.month,
      vm.selectedDate.day,
    );
    final isToday = !selectedNormalized.isBefore(todayNormalized);
    final friendlyDate = DateFormat('EEE, dd MMM yyyy').format(vm.selectedDate);

    return RefreshIndicator(
      onRefresh: vm.refreshAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
        children: [
          // 1. Unsaved / Offline Draft Banner with Direct Save Now
          if (vm.hasUnsavedChanges || vm.hasRestoredLocalDraft)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: ErpTheme.productionAmberSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ErpTheme.productionAmber.withValues(alpha: 0.45),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.offline_pin_rounded,
                        size: 20,
                        color: ErpTheme.productionAmber,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vm.hasRestoredLocalDraft
                                  ? 'Unsaved Offline Draft Available'
                                  : 'Unsaved Production Draft',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: ErpTheme.slate900,
                              ),
                            ),
                            Text(
                              '${inrFormat.format(vm.totalPiecesEntered)} pcs waiting to sync for ${vm.selectedIsoDate}.',
                              style: const TextStyle(
                                fontSize: 11,
                                color: ErpTheme.slate700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        key: const ValueKey('hub-discard-draft-button'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: ErpTheme.slate700,
                        ),
                        onPressed: vm.isSaving ? null : vm.discardDraft,
                        child: const Text('Discard'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        key: const ValueKey('hub-save-draft-button'),
                        style: FilledButton.styleFrom(
                          backgroundColor: ErpTheme.ordersEmerald,
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: vm.isSaving ? null : _handleSaveFromHub,
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
                          vm.isSaving ? 'Saving...' : 'Save Now',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // 2. Day Summary KPI Card
          Card(
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: ErpTheme.slate200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        key: const ValueKey('hub-prev-day-button'),
                        tooltip: 'Previous Day',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: ErpTheme.slate100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: vm.isLoading
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                vm.selectDate(
                                  selectedNormalized.subtract(
                                    const Duration(days: 1),
                                  ),
                                );
                              },
                        icon: const Icon(
                          Icons.chevron_left_rounded,
                          size: 20,
                          color: ErpTheme.slate700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isToday ? 'Today • $friendlyDate' : friendlyDate,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    color: ErpTheme.slate900,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      vm.selectedIsoDate,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: ErpTheme.slate500,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (vm.hasUnsavedChanges) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: Colors.amber.shade300,
                                          ),
                                        ),
                                        child: Text(
                                          'Draft',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.amber.shade900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        key: const ValueKey('hub-next-day-button'),
                        tooltip: 'Next Day',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: isToday
                              ? ErpTheme.slate50
                              : ErpTheme.slate100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: vm.isLoading || isToday
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                vm.selectDate(
                                  selectedNormalized.add(
                                    const Duration(days: 1),
                                  ),
                                );
                              },
                        icon: Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: isToday
                              ? ErpTheme.slate400
                              : ErpTheme.slate700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryKpiPill(
                          title: 'Pieces Entered',
                          value: inrFormat.format(vm.totalPiecesEntered),
                          subtitle: 'Total pieces logged',
                          accentColor: ErpTheme.ordersEmerald,
                          icon: Icons.check_circle_outline_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryKpiPill(
                          title: 'Workers Active',
                          value: '$loggedWorkers / $totalWorkers',
                          subtitle: 'Workers with pieces',
                          accentColor: ErpTheme.hrIndigo,
                          icon: Icons.people_outline_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. THE PRIMARY ACTION: Open or Edit Dedicated Fullscreen Matrix Page
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              key: const ValueKey('open-matrix-entry-button'),
              style: FilledButton.styleFrom(
                backgroundColor: vm.dateRecords.isNotEmpty
                    ? ErpTheme.hrIndigo
                    : ErpTheme.productionAmber,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => _openMatrixPage(),
              icon: Icon(
                vm.dateRecords.isNotEmpty
                    ? Icons.edit_rounded
                    : Icons.grid_on_rounded,
                size: 22,
              ),
              label: Text(
                vm.dateRecords.isNotEmpty
                    ? 'Edit Worksheet (${vm.dateRecords.length} Saved)'
                    : (activeItems.isEmpty
                        ? 'Open Matrix Entry Workspace'
                        : 'Open Worksheet Entry (${activeItems.length} Products)'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 4. Active WIP Products Section (Configure what products are in production today)
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: ErpTheme.slate200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 18,
                        color: ErpTheme.hrIndigo,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'WIP Products for Today (${activeItems.length})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: ErpTheme.slate900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        key: const ValueKey('hub-add-wip-button'),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                        ),
                        onPressed: _openWipItemPicker,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text(
                          'Pick',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Selected products appear as columns for workers in the Matrix workspace.',
                    style: TextStyle(fontSize: 11.5, color: ErpTheme.slate500),
                  ),
                  const SizedBox(height: 12),
                  if (activeItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 14,
                      ),
                      decoration: BoxDecoration(
                        color: ErpTheme.slate50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ErpTheme.slate200),
                      ),
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
                          const Text(
                            'No WIP Products Selected Yet',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: ErpTheme.slate900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap "+ Pick Products" above to select products being produced today.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: ErpTheme.slate500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: activeItems.map((itemName) {
                        final product = vm.findWipProductByName(itemName);
                        final itemTotal = vm.getItemTotalQuantity(itemName);
                        final isPinned = vm.pinnedItemNames.contains(itemName);

                        return Container(
                          padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: itemTotal > 0
                                  ? ErpTheme.ordersEmerald
                                  : ErpTheme.slate200,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isPinned)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: ErpTheme.productionAmber,
                                  ),
                                ),
                              Flexible(
                                child: Text(
                                  itemName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: ErpTheme.slate900,
                                  ),
                                ),
                              ),
                              if (itemTotal > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ErpTheme.ordersEmeraldSoft,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '$itemTotal ${product?.unit ?? 'Pcs'}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: ErpTheme.ordersEmerald,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 4),
                              InkWell(
                                key: ValueKey('hub-remove-wip-$itemName'),
                                onTap: () => _confirmRemoveWipItem(
                                  itemName,
                                  itemTotal,
                                  product?.unit ?? 'Pcs',
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: const Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: ErpTheme.slate400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),

          // 5. Department Quick-Access Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Departments in Production',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: ErpTheme.slate700,
                    ),
                  ),
                ),
                if (vm.temporaryPoolCount > 0 ||
                    widget.authViewModel.currentUser?.canAdd('employees') ==
                        true) ...[
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    key: const ValueKey('hub-quick-add-temp-worker-button'),
                    style: FilledButton.styleFrom(
                      backgroundColor: ErpTheme.hrIndigoSoft,
                      foregroundColor: ErpTheme.hrIndigo,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                    ),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final canAdd =
                          widget.authViewModel.currentUser?.canAdd(
                            'employees',
                          ) ==
                          true;
                      final result = await showTempRosterSheet(
                        context,
                        viewModel: vm,
                        canCreateNew: canAdd,
                      );
                      if (result == null || !mounted) return;
                      if (result.createdWorker != null) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Added temporary worker ${result.createdWorker!.displayEnglishName} (${result.createdWorker!.roleGroup}).',
                            ),
                            backgroundColor: ErpTheme.ordersEmerald,
                          ),
                        );
                      } else if (result.rosterUpdated) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              "Updated today's temp roster (${result.selectedCount} checked in).",
                            ),
                            backgroundColor: ErpTheme.ordersEmerald,
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      vm.temporaryPoolCount > 0
                          ? Icons.how_to_reg_rounded
                          : Icons.person_add_alt_1_rounded,
                      size: 15,
                    ),
                    label: Text(
                      vm.temporaryPoolCount > 0
                          ? 'Temp (${vm.selectedTempCountForDate}/${vm.temporaryPoolCount})'
                          : '+ Temp Worker',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          for (final role in vm.availableRoles.where((r) => r != 'All')) ...[
            Builder(
              builder: (ctx) {
                final count = vm.getWorkerCountForRole(role);
                final pcs = vm.getRoleTotalQuantity(role);
                final roleStyle = _getRoleStyle(role);
                final roleTamil = DailyProductionViewModel.getRoleTamilName(
                  role,
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ErpTheme.slate200),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: roleStyle.bg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        roleStyle.icon,
                        size: 20,
                        color: roleStyle.text,
                      ),
                    ),
                    title: Text(
                      roleTamil.isNotEmpty
                          ? '${role.toUpperCase()} • $roleTamil'
                          : role.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: ErpTheme.slate900,
                      ),
                    ),
                    subtitle: Text(
                      '$count Workers • ${inrFormat.format(pcs)} Pcs logged',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: pcs > 0
                            ? ErpTheme.ordersEmerald
                            : ErpTheme.slate500,
                      ),
                    ),
                    trailing: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _openMatrixPage(roleFilter: role),
                      icon: Icon(
                        pcs > 0
                            ? Icons.edit_rounded
                            : Icons.arrow_forward_rounded,
                        size: 14,
                      ),
                      label: Text(
                        pcs > 0 ? 'Edit' : 'Enter',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 12),

          // 6. Quick Utility Buttons (Copy Yesterday, Print PDF, Export CSV)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: ErpTheme.slate200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _handleCopyYesterday,
                      icon: const Icon(
                        Icons.content_copy_rounded,
                        size: 15,
                        color: ErpTheme.productionAmber,
                      ),
                      label: const Text(
                        'Copy Prev',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _handlePrintWorksheet,
                      icon: const Icon(
                        Icons.print_rounded,
                        size: 15,
                        color: ErpTheme.hrIndigo,
                      ),
                      label: const Text(
                        'Print PDF',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _handleExportCsv,
                      icon: const Icon(
                        Icons.table_chart_rounded,
                        size: 15,
                        color: ErpTheme.ordersEmerald,
                      ),
                      label: const Text(
                        'Export CSV',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
                      FilledButton.tonalIcon(
                        key: ValueKey('history-edit-record-${rec.id}'),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: ErpTheme.hrIndigoSoft,
                          foregroundColor: ErpTheme.hrIndigo,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          await vm.selectDate(rec.date);
                          if (!mounted) return;
                          setState(() => _showHistoryTab = false);
                          final roleTarget =
                              rec.employeeRole != null &&
                                      vm.availableRoles.contains(
                                        rec.employeeRole,
                                      )
                                  ? rec.employeeRole!
                                  : 'All';
                          await _openMatrixPage(roleFilter: roleTarget);
                        },
                        icon: const Icon(Icons.edit_rounded, size: 15),
                        label: const Text(
                          'Edit',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 8),
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

class _SummaryKpiPill extends StatelessWidget {
  const _SummaryKpiPill({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ErpTheme.slate50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ErpTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ErpTheme.slate500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: ErpTheme.slate500),
          ),
        ],
      ),
    );
  }
}
