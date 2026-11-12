import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/core/utils/inr_formatter.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/core/erp_crud_widgets.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/features/inventory/view_models/inventory_history_view_model.dart';

class InventoryHistoryScreen extends StatefulWidget {
  const InventoryHistoryScreen({required this.viewModel, super.key});

  final InventoryHistoryViewModel viewModel;

  @override
  State<InventoryHistoryScreen> createState() => _InventoryHistoryScreenState();
}

class _InventoryHistoryScreenState extends State<InventoryHistoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.viewModel.loadAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ErpScreenScaffold(
      title: 'Inventory History',
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final vm = widget.viewModel;
          if (_searchCtrl.text != vm.searchQuery &&
              vm.searchQuery.isEmpty &&
              _searchCtrl.text.isNotEmpty) {
            _searchCtrl.clear();
          }

          if (vm.isLoading && vm.purchases.isEmpty && vm.transfers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: vm.loadAll,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                ErpSectionHeaderBar(
                  title: 'Inventory History',
                  subtitle:
                      'Unified audit trail of raw material purchases and inter-godown transfers.',
                  accentColor: ErpTheme.purchasesOrange,
                  actions: [
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: vm.isLoading ? null : vm.loadAll,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (vm.errorMessage != null) ...[
                  ErpErrorBanner(
                    message: vm.errorMessage!,
                    onRetry: vm.loadAll,
                  ),
                  const SizedBox(height: 10),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SegmentedButton<InventoryHistoryTab>(
                          segments: [
                            ButtonSegment<InventoryHistoryTab>(
                              value: InventoryHistoryTab.purchases,
                              icon: const Icon(
                                Icons.shopping_cart_checkout_outlined,
                                size: 18,
                              ),
                              label: Text('Purchases (${vm.purchases.length})'),
                            ),
                            ButtonSegment<InventoryHistoryTab>(
                              value: InventoryHistoryTab.transfers,
                              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                              label: Text(
                                'Stock Transfers (${vm.transfers.length})',
                              ),
                            ),
                          ],
                          selected: {vm.activeTab},
                          onSelectionChanged: (sel) => vm.setTab(sel.first),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _searchCtrl,
                          onChanged: vm.setSearchQuery,
                          decoration: InputDecoration(
                            hintText: vm.activeTab ==
                                    InventoryHistoryTab.purchases
                                ? 'Search by Purchase No, Supplier or Bill No...'
                                : 'Search by Transfer No, Vehicle or Driver...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      vm.setSearchQuery('');
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (vm.activeTab == InventoryHistoryTab.purchases)
                  ..._buildPurchaseList(vm)
                else
                  ..._buildTransferList(vm),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildPurchaseList(InventoryHistoryViewModel vm) {
    final list = vm.filteredPurchases;
    if (list.isEmpty) {
      return const [
        ErpEmptyState(
          icon: Icons.shopping_cart_outlined,
          title: 'No Purchases Found',
          subtitle: 'No purchase records match your search.',
        ),
      ];
    }

    return list.map((p) {
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ErpBadge(
                label: p.number,
                backgroundColor: ErpTheme.purchasesOrangeSoft,
                foregroundColor: ErpTheme.purchasesOrangeDark,
              ),
              Text(
                p.supplier,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: ErpTheme.slate900,
                ),
              ),
              ErpBadge(
                label: p.status,
                backgroundColor: p.isActive
                    ? ErpTheme.ordersEmeraldSoft
                    : ErpTheme.dangerRose.withValues(alpha: 0.12),
                foregroundColor: p.isActive
                    ? ErpTheme.ordersEmerald
                    : ErpTheme.dangerRose,
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              [
                DateFormat('dd MMM yyyy').format(p.date),
                if (p.billNo.isNotEmpty) 'Bill: ${p.billNo}',
                'Qty: ${formatIndianCount(p.qty)}',
              ].join(' • '),
              style: const TextStyle(fontSize: 12, color: ErpTheme.slate500),
            ),
          ),
          trailing: Text(
            formatInr(p.value),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: ErpTheme.purchasesOrangeDark,
            ),
          ),
          children: [
            const Divider(height: 1, color: ErpTheme.slate200),
            const SizedBox(height: 8),
            ...p.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.product}${item.godownName != null ? ' -> ${item.godownName}' : ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${item.qty} ${item.pricingUnit ?? ''} • ${formatInr(item.netAmount > 0 ? item.netAmount : item.amount)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ErpTheme.slate700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildTransferList(InventoryHistoryViewModel vm) {
    final list = vm.filteredTransfers;
    if (list.isEmpty) {
      return const [
        ErpEmptyState(
          icon: Icons.swap_horiz_rounded,
          title: 'No Stock Transfers Found',
          subtitle: 'No transfer records match your search.',
        ),
      ];
    }

    return list.map((t) {
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ErpBadge(
                label: t.number,
                backgroundColor: ErpTheme.godownTealSoft,
                foregroundColor: ErpTheme.godownTealDark,
              ),
              Text(
                t.vehicle?.no ?? 'Vehicle #${t.vehicleId ?? '-'}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: ErpTheme.slate900,
                ),
              ),
              if (t.driverName != null && t.driverName!.isNotEmpty)
                Text(
                  '(${t.driverName})',
                  style: const TextStyle(
                    fontSize: 13,
                    color: ErpTheme.slate500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${DateFormat('dd MMM yyyy').format(t.date)} • ${t.items.length} item(s)',
              style: const TextStyle(fontSize: 12, color: ErpTheme.slate500),
            ),
          ),
          trailing: ErpBadge(
            label: '${formatIndianCount(t.qty)} Qty',
            backgroundColor: ErpTheme.purchasesOrangeSoft,
            foregroundColor: ErpTheme.purchasesOrangeDark,
          ),
          children: [
            const Divider(height: 1, color: ErpTheme.slate200),
            const SizedBox(height: 8),
            ...t.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${item.fromGodownName ?? 'Godown #${item.fromGodownId}'} -> ${item.toGodownName ?? 'Godown #${item.toGodownId}'}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: ErpTheme.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${item.qty} Qty • ${formatInr(item.value)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ErpTheme.slate700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

