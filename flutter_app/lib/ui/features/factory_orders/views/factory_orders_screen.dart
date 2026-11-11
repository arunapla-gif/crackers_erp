import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/domain/models/factory_order.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/features/auth/view_models/auth_view_model.dart';
import 'package:crackers_erp/ui/features/factory_orders/view_models/factory_orders_view_model.dart';
import 'factory_order_pdf.dart';

class FactoryOrdersScreen extends StatefulWidget {
  const FactoryOrdersScreen({
    required this.viewModel,
    required this.authViewModel,
    super.key,
  });

  final FactoryOrdersViewModel viewModel;
  final AuthViewModel authViewModel;

  @override
  State<FactoryOrdersScreen> createState() => _FactoryOrdersScreenState();
}

class _FactoryOrdersScreenState extends State<FactoryOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.authViewModel.currentUser?.canViewFactoryOrders == true) {
        widget.viewModel.loadOrders();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _printPackingSlip(FactoryOrder order) async {
    await Printing.layoutPdf(
      name: 'Factory_Order_${order.id}_PackingSlip.pdf',
      onLayout: (_) => buildFactoryOrderPackingPdf(order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authViewModel.currentUser;
    if (user != null && !user.canViewFactoryOrders) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Factory Orders'),
          actions: [AccountAppBarAction(authViewModel: widget.authViewModel)],
        ),
        body: const ErpEmptyState(
          icon: Icons.lock_outline,
          title: 'Factory Orders Restricted',
          subtitle: 'Available to Supervisor and Admin accounts.',
        ),
      );
    }

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final filtered = vm.filteredOrders;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Approved Factory Orders'),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: vm.isLoading ? null : vm.loadOrders,
                icon: const Icon(Icons.refresh_rounded),
              ),
              AccountAppBarAction(authViewModel: widget.authViewModel),
            ],
          ),
          body: Column(
            children: [
              if (vm.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: ErpErrorBanner(
                    message: vm.errorMessage!,
                    onRetry: vm.loadOrders,
                  ),
                ),
              Expanded(
                child: vm.isLoading && vm.orders.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: vm.loadOrders,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                ErpStatTile(
                                  label: 'Approved Orders',
                                  value: '${filtered.length}',
                                  accentColor: ErpTheme.ordersEmerald,
                                  icon: Icons.verified_rounded,
                                ),
                                ErpStatTile(
                                  label: 'Total Cases',
                                  value: '${vm.totalCasesAcrossFiltered}',
                                  accentColor: ErpTheme.productionAmber,
                                  icon: Icons.inventory_2_rounded,
                                ),
                                ErpStatTile(
                                  label: 'Total Boxes',
                                  value: '${vm.totalBoxesAcrossFiltered}',
                                  accentColor: ErpTheme.hrIndigo,
                                  icon: Icons.all_inbox_rounded,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _searchController,
                              onChanged: vm.setSearchQuery,
                              decoration: InputDecoration(
                                hintText:
                                    'Search Order #, customer, city, rep or item...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          vm.setSearchQuery('');
                                        },
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (filtered.isEmpty)
                              const ErpEmptyState(
                                icon: Icons.inventory_outlined,
                                title: 'No Approved Factory Orders',
                                subtitle:
                                    'Orders approved by Admin appear here with box quantities only.',
                              )
                            else
                              ...filtered.map(
                                (order) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _FactoryOrderCard(
                                    order: order,
                                    onPrintPdf: () => _printPackingSlip(order),
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
      },
    );
  }
}

class _FactoryOrderCard extends StatelessWidget {
  const _FactoryOrderCard({
    required this.order,
    required this.onPrintPdf,
  });

  final FactoryOrder order;
  final VoidCallback onPrintPdf;

  @override
  Widget build(BuildContext context) {
    final totalBoxes = order.items.fold(0, (s, item) => s + item.totalBoxes);
    final updatedStr = DateFormat('dd MMM, hh:mm a').format(order.updatedAt);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ErpBadge(
                  label: '#${order.id}',
                  backgroundColor: ErpTheme.ordersEmeraldSoft,
                  foregroundColor: ErpTheme.ordersEmerald,
                ),
                Text(
                  order.customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: ErpTheme.slate900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              [
                if (order.locationLabel.isNotEmpty) order.locationLabel,
                if (order.repUsername != null) 'Rep: ${order.repUsername}',
                updatedStr,
              ].join(' • '),
              style: const TextStyle(
                fontSize: 12,
                color: ErpTheme.slate500,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${order.totalCases} Cases',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: ErpTheme.slate900,
              ),
            ),
            Text(
              '$totalBoxes Boxes',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: ErpTheme.ordersEmerald,
              ),
            ),
          ],
        ),
        children: [
          const Divider(height: 1, color: ErpTheme.slate200),
          const SizedBox(height: 10),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: ErpTheme.slate900,
                          ),
                        ),
                        Text(
                          '${item.boxesPerCase} boxes/case${item.unit != null ? ' • ${item.unit}' : ''}',
                          style: const TextStyle(
                            fontSize: 11,
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
                        label: '${item.qty} Cases',
                        backgroundColor: ErpTheme.productionAmberSoft,
                        foregroundColor: ErpTheme.productionAmber,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${item.totalBoxes} Boxes',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: ErpTheme.slate700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onPrintPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('Packing Slip PDF'),
            ),
          ),
        ],
      ),
    );
  }
}
