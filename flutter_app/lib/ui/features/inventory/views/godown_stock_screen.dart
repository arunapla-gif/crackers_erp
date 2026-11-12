import 'package:flutter/material.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/core/utils/inr_formatter.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/core/erp_crud_widgets.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/features/inventory/view_models/stock_view_model.dart';

class GodownStockScreen extends StatefulWidget {
  const GodownStockScreen({required this.viewModel, super.key});

  final StockViewModel viewModel;

  @override
  State<GodownStockScreen> createState() => _GodownStockScreenState();
}

class _GodownStockScreenState extends State<GodownStockScreen> {
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
      title: 'Godown Stock Ledger',
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final vm = widget.viewModel;
          final filtered = vm.filteredEntries;

          if (vm.isLoading && vm.entries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: vm.loadAll,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                ErpSectionHeaderBar(
                  title: 'Godown Stock Ledger',
                  subtitle:
                      'Live inventory balances and weighted average valuation per godown.',
                  accentColor: ErpTheme.godownTeal,
                  actions: [
                    IconButton(
                      tooltip: 'Refresh Stock',
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
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ErpStatTile(
                      label: 'Stock Lines',
                      value: '${filtered.length}',
                      accentColor: ErpTheme.godownTeal,
                      icon: Icons.inventory_2_outlined,
                    ),
                    ErpStatTile(
                      label: 'Total Qty',
                      value: formatIndianCount(vm.totalStockQty),
                      accentColor: ErpTheme.productionAmber,
                      icon: Icons.layers_outlined,
                    ),
                    ErpStatTile(
                      label: 'Total Stock Value',
                      value: formatInr(vm.totalStockValue),
                      accentColor: ErpTheme.ordersEmerald,
                      icon: Icons.currency_rupee_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: ErpResponsiveFormGrid(
                      minItemWidth: 250,
                      children: [
                        DropdownButtonFormField<int?>(
                          initialValue: vm.selectedGodownId,
                          decoration: const InputDecoration(
                            labelText: 'Filter Godown',
                            prefixIcon: Icon(Icons.warehouse_outlined),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('All Godowns'),
                            ),
                            ...vm.godowns.map(
                              (g) => DropdownMenuItem<int?>(
                                value: g.id,
                                child: Text(g.name),
                              ),
                            ),
                          ],
                          onChanged: vm.setGodownFilter,
                        ),
                        TextField(
                          controller: _searchCtrl,
                          onChanged: vm.setSearchQuery,
                          decoration: InputDecoration(
                            labelText: 'Search Product / Godown',
                            hintText: 'Type product name...',
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
                if (filtered.isEmpty)
                  const ErpEmptyState(
                    icon: Icons.warehouse_outlined,
                    title: 'No Stock Available',
                    subtitle:
                        'Stock balances appear once purchases or inward transfers are recorded.',
                  )
                else
                  ...filtered.map(
                    (item) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              backgroundColor: ErpTheme.godownTealSoft,
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                color: ErpTheme.godownTeal,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: ErpTheme.slate900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      ErpBadge(
                                        label: item.godown?.name ??
                                            'Godown #${item.godownId}',
                                        backgroundColor: ErpTheme.godownTealSoft,
                                        foregroundColor: ErpTheme.godownTealDark,
                                      ),
                                      Text(
                                        'Avg Rate: ${formatInr(item.avgRate)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: ErpTheme.slate500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                ErpBadge(
                                  label: 'Qty: ${formatIndianCount(item.qty)}',
                                  backgroundColor: ErpTheme.slate100,
                                  foregroundColor: ErpTheme.slate900,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatInr(item.value),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: ErpTheme.godownTealDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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

