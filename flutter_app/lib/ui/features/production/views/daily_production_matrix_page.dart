import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/core/utils/tamil_transliteration.dart';
import 'package:crackers_erp/domain/models/employee.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/features/auth/view_models/auth_view_model.dart';
import 'package:crackers_erp/ui/features/production/view_models/daily_production_view_model.dart';
import 'quick_temp_worker_sheet.dart';

/// Screen 2: Dedicated Fullscreen Matrix Workspace
/// 
/// Maximum vertical space dedicated exclusively to worker rows and the docked keypad.
/// No headers, no date pickers, no bulky dropdown clutter.
class DailyProductionMatrixPage extends StatefulWidget {
  const DailyProductionMatrixPage({
    required this.viewModel,
    required this.authViewModel,
    this.initialRoleFilter,
    super.key,
  });

  final DailyProductionViewModel viewModel;
  final AuthViewModel authViewModel;
  final String? initialRoleFilter;

  @override
  State<DailyProductionMatrixPage> createState() =>
      _DailyProductionMatrixPageState();
}

class _DailyProductionMatrixPageState extends State<DailyProductionMatrixPage> {
  static const double _bannerHeight = 36.0;
  static const double _headerHeight = 48.0;
  static const double _workerRowHeight = 54.0;
  static const double _footerHeight = 44.0;

  final ScrollController _bodyVScroll = ScrollController();
  final Map<String, ScrollController> _headerHScrolls =
      <String, ScrollController>{};
  final Map<String, ScrollController> _bodyHScrolls =
      <String, ScrollController>{};
  bool _isSyncingHScroll = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _pendingOnly = false;

  final Set<String> _collapsedRoles = <String>{};
  WorkerNameDisplayMode _nameDisplayMode = WorkerNameDisplayMode.tamil;

  final Map<String, FocusNode> _cellFocusNodes = <String, FocusNode>{};
  final Map<String, ({int empId, String empName, String itemName})> _cellMeta =
      <String, ({int empId, String empName, String itemName})>{};
  String? _focusedKey;
  bool _isNewFocusDigit = true;

  ({ScrollController header, ScrollController body}) _getSyncedHScrolls(
    String role,
  ) {
    if (!_headerHScrolls.containsKey(role)) {
      final headerCtrl = ScrollController();
      final bodyCtrl = ScrollController();

      headerCtrl.addListener(() {
        if (_isSyncingHScroll || !bodyCtrl.hasClients || !headerCtrl.hasClients) {
          return;
        }
        _isSyncingHScroll = true;
        final target = headerCtrl.offset.clamp(
          0.0,
          bodyCtrl.position.maxScrollExtent,
        );
        if ((bodyCtrl.offset - target).abs() > 0.5) {
          bodyCtrl.jumpTo(target);
        }
        _isSyncingHScroll = false;
      });

      bodyCtrl.addListener(() {
        if (_isSyncingHScroll || !headerCtrl.hasClients || !bodyCtrl.hasClients) {
          return;
        }
        _isSyncingHScroll = true;
        final target = bodyCtrl.offset.clamp(
          0.0,
          headerCtrl.position.maxScrollExtent,
        );
        if ((headerCtrl.offset - target).abs() > 0.5) {
          headerCtrl.jumpTo(target);
        }
        _isSyncingHScroll = false;
      });

      _headerHScrolls[role] = headerCtrl;
      _bodyHScrolls[role] = bodyCtrl;
    }
    return (header: _headerHScrolls[role]!, body: _bodyHScrolls[role]!);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.initialRoleFilter != null &&
          widget.viewModel.selectedRoleFilter != widget.initialRoleFilter) {
        widget.viewModel.setRoleFilter(widget.initialRoleFilter!);
      }
      if (widget.authViewModel.currentUser?.canViewProduction == true) {
        if (widget.viewModel.employees.isEmpty) {
          widget.viewModel.loadInitialData();
        }
      }
    });
  }

  @override
  void dispose() {
    _bodyVScroll.dispose();
    for (final ctrl in _headerHScrolls.values) {
      ctrl.dispose();
    }
    for (final ctrl in _bodyHScrolls.values) {
      ctrl.dispose();
    }
    _searchController.dispose();
    for (final node in _cellFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
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
    HapticFeedback.lightImpact();
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
    HapticFeedback.lightImpact();
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
    HapticFeedback.mediumImpact();
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
    HapticFeedback.mediumImpact();
    _isNewFocusDigit = true;
    vm.setQuantity(empId, itemName, 0);
  }

  void _onKeypadDelta(
    int delta,
    int empId,
    String itemName,
    DailyProductionViewModel vm,
  ) {
    HapticFeedback.selectionClick();
    _isNewFocusDigit = false;
    vm.incrementQuantity(empId, itemName, delta);
  }

  void _scrollNodeIntoView(FocusNode node) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = node.context;
      if (ctx == null || !ctx.mounted) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.45,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
      );
    });
  }

  FocusNode _focusNodeFor(String key) {
    return _cellFocusNodes.putIfAbsent(key, () {
      final node = FocusNode();
      node.addListener(() {
        if (!mounted) return;
        _updateFocusedKey(key, node.hasFocus);
        if (node.hasFocus) {
          _scrollNodeIntoView(node);
        }
      });
      return node;
    });
  }

  void _focusNextCell(String currentKey, List<String> columnMajorKeys) {
    HapticFeedback.selectionClick();
    final idx = columnMajorKeys.indexOf(currentKey);
    if (idx >= 0 && idx + 1 < columnMajorKeys.length) {
      final nextKey = columnMajorKeys[idx + 1];
      final nextNode = _cellFocusNodes[nextKey];
      if (nextNode != null) {
        nextNode.requestFocus();
        _scrollNodeIntoView(nextNode);
        return;
      }
    }
    _cellFocusNodes[currentKey]?.unfocus();
  }

  void _focusPrevCell(String currentKey, List<String> columnMajorKeys) {
    HapticFeedback.selectionClick();
    final idx = columnMajorKeys.indexOf(currentKey);
    if (idx > 0) {
      final prevKey = columnMajorKeys[idx - 1];
      final prevNode = _cellFocusNodes[prevKey];
      if (prevNode != null) {
        prevNode.requestFocus();
        _scrollNodeIntoView(prevNode);
        return;
      }
    }
    _cellFocusNodes[currentKey]?.unfocus();
  }

  KeyEventResult _handleHardwareKeyEvent(
    KeyEvent event,
    List<String> columnMajorKeys,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (_focusedKey == null) return KeyEventResult.ignored;
    final meta = _cellMeta[_focusedKey];
    if (meta == null) return KeyEventResult.ignored;
    final vm = widget.viewModel;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
      _onKeypadDigit(0, meta.empId, meta.itemName, vm);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      _onKeypadDigit(1, meta.empId, meta.itemName, vm);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
      _onKeypadDigit(2, meta.empId, meta.itemName, vm);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
      _onKeypadDigit(3, meta.empId, meta.itemName, vm);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
      _onKeypadDigit(4, meta.empId, meta.itemName, vm);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) {
      _onKeypadDigit(5, meta.empId, meta.itemName, vm);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) {
      _onKeypadDigit(6, meta.empId, meta.itemName, vm);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) {
      _onKeypadDigit(7, meta.empId, meta.itemName, vm);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) {
      _onKeypadDigit(8, meta.empId, meta.itemName, vm);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) {
      _onKeypadDigit(9, meta.empId, meta.itemName, vm);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.backspace) {
      _onKeypadBackspace(meta.empId, meta.itemName, vm);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.delete || key == LogicalKeyboardKey.escape) {
      _onKeypadClear(meta.empId, meta.itemName, vm);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.tab) {
      _isNewFocusDigit = true;
      _focusNextCell(_focusedKey!, columnMajorKeys);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _isNewFocusDigit = true;
      _focusPrevCell(_focusedKey!, columnMajorKeys);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
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

  Future<void> _openQuickWipPicker() async {
    _unfocusCurrentCell();
    final searchController = TextEditingController();
    final activeRole = widget.viewModel.selectedRoleFilter;
    final isRoleScoped = activeRole != 'All';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                final currentActive = isRoleScoped
                    ? vm.getActiveItemsForRole(activeRole)
                    : vm.activeItemNames;

                return DraggableScrollableSheet(
                  expand: false,
                  initialChildSize: 0.72,
                  minChildSize: 0.45,
                  maxChildSize: 0.92,
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
                          padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isRoleScoped
                                      ? 'WIP Columns for $activeRole'
                                      : 'Add / Select WIP Columns',
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: ErpTheme.slate900,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text(
                                  'Done',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
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
                              isDense: true,
                              prefixIcon: const Icon(Icons.search, size: 18),
                              suffixIcon: searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
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
                                      'Create WIP products in Product Master.',
                                )
                              : ListView.separated(
                                  controller: scrollController,
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    4,
                                    16,
                                    20,
                                  ),
                                  itemCount: items.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (ctx, idx) {
                                    final prod = items[idx];
                                    final isActive =
                                        currentActive.contains(prod.name);
                                    final isPinned =
                                        vm.pinnedItemNames.contains(prod.name);
                                    final qty = isRoleScoped
                                        ? vm.getRoleItemTotalQuantity(
                                            activeRole,
                                            prod.name,
                                          )
                                        : vm.getItemTotalQuantity(prod.name);

                                    return Material(
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: isActive
                                              ? ErpTheme.productionAmber
                                              : ErpTheme.slate200,
                                        ),
                                      ),
                                      child: ListTile(
                                        dense: true,
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          if (isActive) {
                                            if (qty == 0) {
                                              if (isRoleScoped) {
                                                vm.removeActiveItemForRole(
                                                  activeRole,
                                                  prod.name,
                                                );
                                              } else {
                                                vm.removeActiveItem(prod.name);
                                              }
                                            }
                                          } else {
                                            if (isRoleScoped) {
                                              vm.addActiveItemForRole(
                                                activeRole,
                                                prod.name,
                                              );
                                            } else {
                                              vm.addActiveItem(prod.name);
                                            }
                                          }
                                        },
                                        title: Text(
                                          prod.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        subtitle: Text(
                                          qty > 0
                                              ? '${prod.displayGroup} • $qty ${prod.unit} entered'
                                              : '${prod.displayGroup} • Unit: ${prod.unit}',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: qty > 0
                                                ? ErpTheme.ordersEmerald
                                                : ErpTheme.slate500,
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
                                                size: 20,
                                                color: isPinned
                                                    ? ErpTheme.productionAmber
                                                    : ErpTheme.slate500,
                                              ),
                                              onPressed: () =>
                                                  vm.togglePinnedItem(prod.name),
                                            ),
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

  Future<bool> _onWillPop() async {
    if (widget.viewModel.hasUnsavedChanges) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
            'You have unsaved production quantities entered. Your changes will remain in local draft, or you can save now.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Leave (Keep Draft)'),
            ),
            FilledButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                Navigator.of(ctx).pop(false);
                await _handleSave();
                if (mounted) {
                  nav.pop();
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: ErpTheme.productionAmber,
              ),
              child: const Text('Save & Exit'),
            ),
          ],
        ),
      );
      return leave ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final items = vm.activeItemNames;
        final rawGroupedRoles = vm.filteredWorkersByRole;
        final focusedEmpId = _focusedKey != null
            ? int.tryParse(_focusedKey!.split('::').first)
            : null;
        var pendingCount = 0;
        for (final workers in rawGroupedRoles.values) {
          for (final emp in workers) {
            if (vm.getWorkerTotalQuantity(emp.id) == 0) {
              pendingCount++;
            }
          }
        }
        final groupedRoles = _pendingOnly
            ? <String, List<Employee>>{
                for (final entry in rawGroupedRoles.entries)
                  if (entry.value.any(
                    (emp) =>
                        vm.getWorkerTotalQuantity(emp.id) == 0 ||
                        emp.id == focusedEmpId,
                  ))
                    entry.key: entry.value
                        .where(
                          (emp) =>
                              vm.getWorkerTotalQuantity(emp.id) == 0 ||
                              emp.id == focusedEmpId,
                        )
                        .toList(),
              }
            : rawGroupedRoles;
        final inrFormat = NumberFormat('#,##,##0', 'en_IN');
        final dateLabel = DateFormat('dd MMM').format(vm.selectedDate);

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

        return PopScope(
          canPop: !vm.hasUnsavedChanges,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              final nav = Navigator.of(context);
              _onWillPop().then((canLeave) {
                if (canLeave && mounted) {
                  nav.pop();
                }
              });
            }
          },
          child: Scaffold(
            backgroundColor: ErpTheme.slate50,
            appBar: AppBar(
              toolbarHeight: 44.0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                tooltip: 'Back to Hub',
                onPressed: () async {
                  final nav = Navigator.of(context);
                  final canLeave = await _onWillPop();
                  if (canLeave && mounted) {
                    nav.pop();
                  }
                },
              ),
              titleSpacing: 0,
              title: _isSearching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: vm.setWorkerSearch,
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Filter worker name or role...',
                        hintStyle: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white70,
                          size: 16,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: 16,
                          ),
                          onPressed: () {
                            setState(() => _isSearching = false);
                            _searchController.clear();
                            vm.setWorkerSearch('');
                          },
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            '$dateLabel Worksheet',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: ErpTheme.productionAmberSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${inrFormat.format(vm.totalPiecesEntered)} pcs',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: ErpTheme.productionAmber,
                            ),
                          ),
                        ),
                      ],
                    ),
              actions: [
                if (!_isSearching)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Search Workers',
                    icon: const Icon(Icons.search_rounded, size: 19),
                    onPressed: () => setState(() => _isSearching = true),
                  ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: _nameDisplayMode == WorkerNameDisplayMode.tamil
                      ? 'Showing Tamil (Tap for English)'
                      : 'Showing English (Tap for Tamil)',
                  icon: const Icon(Icons.translate_rounded, size: 19),
                  onPressed: () {
                    setState(() {
                      _nameDisplayMode =
                          _nameDisplayMode == WorkerNameDisplayMode.tamil
                              ? WorkerNameDisplayMode.english
                              : WorkerNameDisplayMode.tamil;
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8, left: 4),
                  child: FilledButton.icon(
                    key: const ValueKey('matrix-fullscreen-save-button'),
                    style: FilledButton.styleFrom(
                      backgroundColor: ErpTheme.productionAmber,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: vm.isSaving ? null : _handleSave,
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
                      vm.isSaving ? 'Saving...' : 'Save',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: Focus(
              onKeyEvent: (node, event) =>
                  _handleHardwareKeyEvent(event, columnMajorKeys),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isLandscape =
                      MediaQuery.orientationOf(context) ==
                          Orientation.landscape;
                  final hasKeypad = activeMeta != null && _focusedKey != null;
                  final useSideBySideKeypad =
                      hasKeypad && (isLandscape || constraints.maxWidth >= 600);

                  final roleTabBar = Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: ErpTheme.slate200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Material(
                          color: ErpTheme.productionAmberSoft,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            key: const ValueKey('matrix-quick-add-wip-button'),
                            onTap: _openQuickWipPicker,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 28,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: ErpTheme.productionAmber
                                      .withValues(alpha: 0.45),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_rounded,
                                    size: 14,
                                    color: ErpTheme.productionAmber,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    'WIP',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      color: ErpTheme.productionAmber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (vm.temporaryPoolCount > 0 ||
                            widget.authViewModel.currentUser?.canAdd(
                                  'employees',
                                ) ==
                                true) ...[
                          const SizedBox(width: 6),
                          Material(
                            color: ErpTheme.hrIndigoSoft,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              key: const ValueKey(
                                'matrix-quick-add-temp-worker-button',
                              ),
                              onTap: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final currentFilter = vm.selectedRoleFilter;
                                final canAdd =
                                    widget.authViewModel.currentUser?.canAdd(
                                      'employees',
                                    ) ==
                                    true;
                                final result = await showTempRosterSheet(
                                  context,
                                  viewModel: vm,
                                  initialRole: currentFilter == 'All'
                                      ? null
                                      : currentFilter,
                                  canCreateNew: canAdd,
                                );
                                if (result == null || !mounted) return;
                                setState(() {
                                  for (final role in result.selectedRoles) {
                                    _collapsedRoles.remove(role);
                                  }
                                  _pendingOnly = false;
                                });
                                if (result.createdWorker != null) {
                                  final created = result.createdWorker!;
                                  if (vm.selectedRoleFilter != 'All' &&
                                      vm.selectedRoleFilter.toLowerCase() !=
                                          created.roleGroup.toLowerCase()) {
                                    vm.setRoleFilter(created.roleGroup);
                                  }
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Added ${created.displayEnglishName} (TEMP) to ${created.roleGroup}. Ready for entry.',
                                      ),
                                      backgroundColor: ErpTheme.ordersEmerald,
                                    ),
                                  );
                                } else if (result.rosterUpdated) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Today's temp roster updated (${result.selectedCount} checked in).",
                                      ),
                                      backgroundColor: ErpTheme.ordersEmerald,
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                height: 28,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: ErpTheme.hrIndigo.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      vm.temporaryPoolCount > 0
                                          ? Icons.how_to_reg_rounded
                                          : Icons.person_add_alt_1_rounded,
                                      size: 13,
                                      color: ErpTheme.hrIndigo,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      vm.temporaryPoolCount > 0
                                          ? 'Temp (${vm.selectedTempCountForDate}/${vm.temporaryPoolCount})'
                                          : 'Temp',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w900,
                                        color: ErpTheme.hrIndigo,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 6),
                        Container(
                          width: 1,
                          height: 20,
                          color: ErpTheme.slate200,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: FilterChip(
                                    key: const ValueKey(
                                      'matrix-pending-only-chip',
                                    ),
                                    avatar: Icon(
                                      Icons.pending_actions_rounded,
                                      size: 13,
                                      color: _pendingOnly
                                          ? ErpTheme.productionAmber
                                          : ErpTheme.slate500,
                                    ),
                                    label: Text('Pending ($pendingCount)'),
                                    labelStyle: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: _pendingOnly
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: _pendingOnly
                                          ? ErpTheme.productionAmber
                                          : ErpTheme.slate700,
                                    ),
                                    selected: _pendingOnly,
                                    selectedColor: ErpTheme.productionAmberSoft,
                                    checkmarkColor: ErpTheme.productionAmber,
                                    side: BorderSide(
                                      color: _pendingOnly
                                          ? ErpTheme.productionAmber
                                          : ErpTheme.slate200,
                                      width: _pendingOnly ? 1.5 : 1.0,
                                    ),
                                    onSelected: (val) =>
                                        setState(() => _pendingOnly = val),
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: FilterChip(
                                    avatar: const Icon(
                                      Icons.person_add_alt_1_rounded,
                                      size: 13,
                                      color: ErpTheme.slate500,
                                    ),
                                    label: const Text('Monthly'),
                                    labelStyle: TextStyle(
                                      fontSize: 10.5,
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                  ),
                                ),
                                ...vm.availableRoles.map((role) {
                                  final count = vm.getWorkerCountForRole(role);
                                  final tamil =
                                      DailyProductionViewModel.getRoleTamilName(
                                    role,
                                  );
                                  final isSelected =
                                      vm.selectedRoleFilter == role;
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
                                        size: 13,
                                        color: isSelected
                                            ? style.text
                                            : ErpTheme.slate500,
                                      ),
                                      label: Text(label),
                                      labelStyle: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? style.text
                                            : ErpTheme.slate700,
                                      ),
                                      selected: isSelected,
                                      selectedColor: style.bg,
                                      checkmarkColor: style.text,
                                      side: BorderSide(
                                        color: isSelected
                                            ? style.border
                                            : ErpTheme.slate200,
                                        width: isSelected ? 1.5 : 1.0,
                                      ),
                                      onSelected: (_) => vm.setRoleFilter(role),
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (useSideBySideKeypad) {
                    final sideKeypadWidth =
                        (constraints.maxWidth * 0.38).clamp(275.0, 340.0);
                    final leftPaneWidth =
                        constraints.maxWidth - sideKeypadWidth - 1.0;
                    final isLeftCompact = leftPaneWidth < 500;
                    final workerColWidth = isLeftCompact ? 130.0 : 160.0;
                    final baseItemWidth = isLeftCompact ? 94.0 : 120.0;
                    final totalColWidth = isLeftCompact ? 70.0 : 86.0;

                    final bodyScroll = _buildDepartmentSliverBody(
                      vm: vm,
                      groupedRoles: groupedRoles,
                      columnMajorKeys: columnMajorKeys,
                      workerColWidth: workerColWidth,
                      baseItemWidth: baseItemWidth,
                      totalColWidth: totalColWidth,
                      availableWidth: leftPaneWidth - 14.0,
                      inrFormat: inrFormat,
                      nameDisplayMode: _nameDisplayMode,
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
                        roleTabBar,
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

                  final bodyScroll = _buildDepartmentSliverBody(
                    vm: vm,
                    groupedRoles: groupedRoles,
                    columnMajorKeys: columnMajorKeys,
                    workerColWidth: workerColWidth,
                    baseItemWidth: baseItemWidth,
                    totalColWidth: totalColWidth,
                    availableWidth: constraints.maxWidth - 14.0,
                    inrFormat: inrFormat,
                    nameDisplayMode: _nameDisplayMode,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      roleTabBar,
                      Expanded(child: bodyScroll),
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
            ),
          ),
        );
      },
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
        // Stepper pills
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

        // 1, 2, 3, ⌫
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

        // 4, 5, 6, 00
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

        // 7, 8, 9, 0
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

        // Bottom row: piece counter + Prev ↑ + Next Worker ↓
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
            SizedBox(
              height: isSideBySide ? 30 : 34,
              child: OutlinedButton.icon(
                key: const ValueKey('matrix-prev-worker-button'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ErpTheme.slate800,
                  side: const BorderSide(color: ErpTheme.slate200),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSideBySide ? 7 : 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: columnMajorKeys.indexOf(cellKey) > 0
                    ? () {
                        _isNewFocusDigit = true;
                        _focusPrevCell(cellKey, columnMajorKeys);
                      }
                    : null,
                icon: const Icon(Icons.arrow_upward_rounded, size: 14),
                label: Text(
                  'Prev',
                  style: TextStyle(
                    fontSize: isSideBySide ? 10.5 : 11.5,
                    fontWeight: FontWeight.w800,
                  ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: isSideBySide ? MainAxisSize.max : MainAxisSize.min,
        children: [
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

  Widget _buildDepartmentSliverBody({
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
      return CustomScrollView(
        controller: _bodyVScroll,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
              child: _pendingOnly
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const ErpEmptyState(
                          icon: Icons.check_circle_outline_rounded,
                          title: 'All Workers Logged!',
                          subtitle:
                              'Every worker in this view already has production pieces entered.',
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _pendingOnly = false),
                          icon: const Icon(Icons.groups_rounded, size: 16),
                          label: const Text('Show All Workers'),
                        ),
                      ],
                    )
                  : const ErpEmptyState(
                      icon: Icons.engineering_outlined,
                      title: 'No Matching Workers',
                      subtitle:
                          'No active contractual workers match the selected role filter or search query.',
                    ),
            ),
          ),
        ],
      );
    }

    final slivers = <Widget>[
      const SliverToBoxAdapter(child: SizedBox(height: 4)),
    ];
    var isFirst = true;

    for (final entry in groupedRoles.entries) {
      final role = entry.key;
      final roleWorkers = entry.value;
      final isCollapsed = _collapsedRoles.contains(role);
      final roleItems = vm.getActiveItemsForRole(role);
      final roleTotal = vm.getRoleTotalQuantity(role);
      final roleStyle = _getRoleStyle(role);
      final roleTamil = DailyProductionViewModel.getRoleTamilName(role);
      final hScrolls = _getSyncedHScrolls(role);

      final availableRightWidth =
          (availableWidth - workerColWidth).clamp(0.0, double.infinity);
      final baseRightWidth = (baseItemWidth * roleItems.length) + totalColWidth;
      final itemColWidth =
          roleItems.isNotEmpty && baseRightWidth < availableRightWidth
              ? baseItemWidth +
                  ((availableRightWidth - baseRightWidth) / roleItems.length)
              : baseItemWidth;
      final rightTrackWidth = (itemColWidth * roleItems.length) + totalColWidth;

      final showColumnHeader = !isCollapsed && roleItems.isNotEmpty;
      final headerTotalHeight = _bannerHeight +
          (showColumnHeader ? _headerHeight : 0.0) +
          (isCollapsed ? 2.0 : 1.0);

      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
          sliver: SliverMainAxisGroup(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyMatrixHeaderDelegate(
                  height: headerTotalHeight,
                  child: _buildPinnedDepartmentHeader(
                    vm: vm,
                    role: role,
                    roleWorkers: roleWorkers,
                    roleItems: roleItems,
                    roleTotal: roleTotal,
                    roleStyle: roleStyle,
                    roleTamil: roleTamil,
                    isCollapsed: isCollapsed,
                    showColumnHeader: showColumnHeader,
                    headerHScroll: hScrolls.header,
                    workerColWidth: workerColWidth,
                    itemColWidth: itemColWidth,
                    totalColWidth: totalColWidth,
                    rightTrackWidth: rightTrackWidth,
                    inrFormat: inrFormat,
                    isFirstDepartment: isFirst,
                  ),
                ),
              ),
              if (!isCollapsed)
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(14),
                      ),
                      border: Border(
                        left: BorderSide(color: ErpTheme.slate200),
                        right: BorderSide(color: ErpTheme.slate200),
                        bottom: BorderSide(color: ErpTheme.slate200),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: roleItems.isEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 16,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'No WIP items active for $role. Select items in the Hub.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: ErpTheme.slate500,
                              ),
                            ),
                          )
                        : _buildDepartmentBodyRows(
                            vm: vm,
                            role: role,
                            roleWorkers: roleWorkers,
                            roleItems: roleItems,
                            roleTotal: roleTotal,
                            roleStyle: roleStyle,
                            bodyHScroll: hScrolls.body,
                            workerColWidth: workerColWidth,
                            itemColWidth: itemColWidth,
                            totalColWidth: totalColWidth,
                            rightTrackWidth: rightTrackWidth,
                            inrFormat: inrFormat,
                            nameDisplayMode: nameDisplayMode,
                            columnMajorKeys: columnMajorKeys,
                          ),
                  ),
                ),
            ],
          ),
        ),
      );
      isFirst = false;
    }

    return CustomScrollView(
      controller: _bodyVScroll,
      slivers: slivers,
    );
  }

  Widget _buildPinnedDepartmentHeader({
    required DailyProductionViewModel vm,
    required String role,
    required List<Employee> roleWorkers,
    required List<String> roleItems,
    required int roleTotal,
    required ({Color bg, Color border, Color text, IconData icon}) roleStyle,
    required String roleTamil,
    required bool isCollapsed,
    required bool showColumnHeader,
    required ScrollController headerHScroll,
    required double workerColWidth,
    required double itemColWidth,
    required double totalColWidth,
    required double rightTrackWidth,
    required NumberFormat inrFormat,
    required bool isFirstDepartment,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isCollapsed
            ? BorderRadius.circular(14)
            : const BorderRadius.vertical(top: Radius.circular(14)),
        border: isCollapsed
            ? Border.all(color: ErpTheme.slate200)
            : const Border(
                top: BorderSide(color: ErpTheme.slate200),
                left: BorderSide(color: ErpTheme.slate200),
                right: BorderSide(color: ErpTheme.slate200),
              ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Department Banner
          Material(
            color: roleStyle.bg,
            child: InkWell(
              onTap: () => setState(() {
                if (isCollapsed) {
                  _collapsedRoles.remove(role);
                } else {
                  _collapsedRoles.add(role);
                }
              }),
              child: Container(
                height: _bannerHeight,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: roleStyle.border, width: 4),
                    bottom: BorderSide(color: roleStyle.border),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCollapsed
                          ? Icons.chevron_right_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                      color: roleStyle.text,
                    ),
                    const SizedBox(width: 4),
                    Icon(roleStyle.icon, size: 15, color: roleStyle.text),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        roleTamil.isNotEmpty
                            ? '${role.toUpperCase()} • $roleTamil (${roleWorkers.length})'
                            : '${role.toUpperCase()} (${roleWorkers.length})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: roleStyle.text,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
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
              ),
            ),
          ),

          // 2. Pinned Product Column Headers Row
          if (showColumnHeader)
            SizedBox(
              height: _headerHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: workerColWidth,
                    height: _headerHeight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
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
                  Expanded(
                    child: SingleChildScrollView(
                      controller: headerHScroll,
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        width: rightTrackWidth,
                        height: _headerHeight,
                        color: ErpTheme.slate100,
                        child: Row(
                          children: [
                            for (final itemName in roleItems) ...[
                              Builder(
                                builder: (context) {
                                  final product =
                                      vm.findWipProductByName(itemName);
                                  return Container(
                                    width: itemColWidth,
                                    height: _headerHeight,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 4,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          itemName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w900,
                                            color: ErpTheme.hrIndigo,
                                            height: 1.15,
                                          ),
                                        ),
                                        Text(
                                          product?.unit ?? 'Pcs',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 8.5,
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
                            Container(
                              width: totalColWidth,
                              height: _headerHeight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
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
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: ErpTheme.slate700,
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
            ),
        ],
      ),
    );
  }

  Widget _buildDepartmentBodyRows({
    required DailyProductionViewModel vm,
    required String role,
    required List<Employee> roleWorkers,
    required List<String> roleItems,
    required int roleTotal,
    required ({Color bg, Color border, Color text, IconData icon}) roleStyle,
    required ScrollController bodyHScroll,
    required double workerColWidth,
    required double itemColWidth,
    required double totalColWidth,
    required double rightTrackWidth,
    required NumberFormat inrFormat,
    required WorkerNameDisplayMode nameDisplayMode,
    required List<String> columnMajorKeys,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Frozen Left Worker Column
        SizedBox(
          width: workerColWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                              fontSize: 12,
                              color: ErpTheme.slate900,
                            ),
                          ),
                          const SizedBox(height: 1),
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
                              fontSize: 9.5,
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
              Container(
                height: _footerHeight,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  color: roleStyle.bg.withValues(alpha: 0.5),
                  border: Border(
                    top: BorderSide(color: roleStyle.border, width: 1.5),
                    right: const BorderSide(
                      color: ErpTheme.slate200,
                      width: 1.5,
                    ),
                  ),
                ),
                child: Text(
                  'SUBTOTAL',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    color: roleStyle.text,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Horizontally Scrollable Product Track (synced with pinned header)
        Expanded(
          child: SingleChildScrollView(
            controller: bodyHScroll,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: rightTrackWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                                        horizontal: 5,
                                        vertical: 6,
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
                                    const EdgeInsets.symmetric(horizontal: 4),
                                alignment: Alignment.center,
                                child: Text(
                                  '$empTotal',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12.5,
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
                                    fontSize: 11,
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
                              fontSize: 11,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: ErpTheme.slate200, width: 1.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${vm.activeWorkersLoggedCount} Workers Logged • ${inrFormat.format(vm.totalPiecesEntered)} Pcs',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: ErpTheme.slate800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            key: const ValueKey('matrix-save-button-bottom'),
            style: FilledButton.styleFrom(
              backgroundColor: ErpTheme.productionAmber,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: vm.isSaving ? null : _handleSave,
            icon: vm.isSaving
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 15),
            label: Text(
              vm.isSaving ? 'Saving...' : 'Save Worksheet',
              style: const TextStyle(
                fontSize: 11.5,
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
        fontSize: 13,
        color: widget.quantity > 0 ? ErpTheme.hrIndigo : ErpTheme.slate700,
      ),
      decoration: InputDecoration(
        hintText: '0',
        hintStyle: const TextStyle(color: ErpTheme.slate500),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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

class _StickyMatrixHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _StickyMatrixHeaderDelegate({
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _StickyMatrixHeaderDelegate oldDelegate) => true;
}

