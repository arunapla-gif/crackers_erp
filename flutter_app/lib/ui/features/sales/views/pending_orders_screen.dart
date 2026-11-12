import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/core/utils/inr_formatter.dart';
import 'package:crackers_erp/domain/models/sales_order.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/core/erp_crud_widgets.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/features/factory_orders/views/factory_order_pdf.dart';
import 'package:crackers_erp/ui/features/sales/view_models/billing_view_model.dart';
import 'package:crackers_erp/ui/features/sales/view_models/pending_orders_view_model.dart';

class PendingOrdersScreen extends StatefulWidget {
  const PendingOrdersScreen({
    required this.viewModel,
    required this.billingViewModel,
    super.key,
  });

  final PendingOrdersViewModel viewModel;
  final BillingViewModel billingViewModel;

  @override
  State<PendingOrdersScreen> createState() => _PendingOrdersScreenState();
}

class _PendingOrdersScreenState extends State<PendingOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.viewModel.fetchOrders();
    });
  }

  Future<void> _approveLead(SalesOrder order) async {
    final ok = await showErpConfirmDialog(
      context: context,
      title: 'Approve Lead Customer?',
      message:
          'Convert "${order.displayCustomerName}" from a lead into a Master Customer?',
      confirmLabel: 'Approve Lead',
    );
    if (ok && mounted) {
      await widget.viewModel.approveLeadCustomer(order.id);
    }
  }

  Future<void> _approveAndCreatePerforma(SalesOrder order) async {
    final ok = await showErpConfirmDialog(
      context: context,
      title: 'Approve & Create Performa?',
      message:
          'Approve Order #${order.id} for ${order.displayCustomerName} and preload into Performa Billing?',
      confirmLabel: 'Approve & Load',
    );
    if (!ok || !mounted) return;
    final success = await widget.viewModel.approveOrderForPerforma(order);
    if (!success || !mounted) return;
    await widget.billingViewModel.initialize();
    widget.billingViewModel.loadSalesOrder(order);
    if (mounted) context.go('/billing');
  }

  Future<void> _rejectOrder(SalesOrder order) async {
    final ok = await showErpConfirmDialog(
      context: context,
      title: 'Reject Order #${order.id}?',
      message: 'This sales order will be marked as REJECTED.',
      confirmLabel: 'Reject Order',
      destructive: true,
    );
    if (ok && mounted) {
      await widget.viewModel.rejectOrder(order.id);
    }
  }

  Future<void> _printFactorySlip(SalesOrder order) async {
    final factoryOrder = await widget.viewModel.fetchFactorySlip(order.id);
    if (!mounted || factoryOrder == null) return;
    await Printing.layoutPdf(
      name: 'Factory_Order_${order.id}.pdf',
      onLayout: (_) => buildFactoryOrderPackingPdf(factoryOrder),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        return ErpScreenScaffold(
          title: 'Pending Sales Orders',
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: ErpSectionHeaderBar(
                      accentColor: ErpTheme.salesBlue,
                      title: 'Pending & Approved Orders',
                      subtitle:
                          'Review Sales Representative orders, verify leads, or open Performa Billing.',
                      actions: [
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'PENDING',
                              label: Text('PENDING'),
                            ),
                            ButtonSegment(
                              value: 'APPROVED',
                              label: Text('APPROVED'),
                            ),
                          ],
                          selected: {vm.activeTab},
                          onSelectionChanged: (sel) {
                            if (sel.isNotEmpty) vm.setTab(sel.first);
                          },
                        ),
                        OutlinedButton.icon(
                          onPressed: vm.isLoading ? null : vm.fetchOrders,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Refresh'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (vm.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: ErpErrorBanner(
                      message: vm.errorMessage!,
                      onRetry: vm.fetchOrders,
                    ),
                  ),
                ),
              if (vm.successMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: ErpSuccessBanner(
                      message: vm.successMessage!,
                      onDismiss: vm.clearMessages,
                    ),
                  ),
                ),
              Expanded(
                child: vm.isLoading && vm.orders.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : vm.orders.isEmpty
                    ? Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: const ErpEmptyState(
                            icon: Icons.thumb_up_alt_outlined,
                            title: 'All Caught Up!',
                            subtitle:
                                'There are no orders in this queue right now.',
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: vm.fetchOrders,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: vm.orders.length,
                          itemBuilder: (context, index) {
                            final order = vm.orders[index];
                            return Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 1120),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _OrderCard(
                                    order: order,
                                    isPendingTab: vm.activeTab == 'PENDING',
                                    isBusy: vm.isBusyAction,
                                    onApproveLead: () => _approveLead(order),
                                    onVerifyLeadInMaster: () {
                                      if (order.newCustomerData != null) {
                                        context.go(
                                          '/customers',
                                          extra: VerifyCustomerLeadArgs(
                                            orderId: order.id,
                                            leadData: order.newCustomerData!,
                                          ),
                                        );
                                      }
                                    },
                                    onApproveAndCreatePerforma: () =>
                                        _approveAndCreatePerforma(order),
                                    onReject: () => _rejectOrder(order),
                                    onPrintFactory: () =>
                                        _printFactorySlip(order),
                                  ),
                                ),
                              ),
                            );
                          },
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

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.isPendingTab,
    required this.isBusy,
    required this.onApproveLead,
    required this.onVerifyLeadInMaster,
    required this.onApproveAndCreatePerforma,
    required this.onReject,
    required this.onPrintFactory,
  });

  final SalesOrder order;
  final bool isPendingTab;
  final bool isBusy;
  final VoidCallback onApproveLead;
  final VoidCallback onVerifyLeadInMaster;
  final VoidCallback onApproveAndCreatePerforma;
  final VoidCallback onReject;
  final VoidCallback onPrintFactory;

  @override
  Widget build(BuildContext context) {
    final lead = order.newCustomerData;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: ErpTheme.slate50,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ErpBadge(
                            label: isPendingTab
                                ? 'PENDING APPROVAL'
                                : 'APPROVED',
                            backgroundColor: isPendingTab
                                ? ErpTheme.productionAmberSoft
                                : ErpTheme.ordersEmeraldSoft,
                            foregroundColor: isPendingTab
                                ? ErpTheme.productionAmber
                                : ErpTheme.ordersEmerald,
                          ),
                          if (order.isNewLead)
                            const ErpBadge(
                              label: 'NEW LEAD',
                              backgroundColor: ErpTheme.salesBlueSoft,
                              foregroundColor: ErpTheme.salesBlueDark,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        order.displayCustomerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: ErpTheme.slate900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Submitted by ${order.repUsername ?? 'Rep'} • ${DateFormat('dd MMM yyyy').format(order.createdAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ErpTheme.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'ORDER SUBTOTAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: ErpTheme.slate400,
                      ),
                    ),
                    Text(
                      formatInr(order.subtotal),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: ErpTheme.slate900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (order.isNewLead && lead != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ErpTheme.salesBlueSoft.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: ErpTheme.salesBlue.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'LEAD INFORMATION',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: ErpTheme.salesBlueDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 20,
                          runSpacing: 8,
                          children: [
                            _kv('Mobile', lead.mobile),
                            _kv('GSTIN', lead.gstin.toUpperCase()),
                            _kv('Aadhaar/PAN', lead.idNumber),
                            _kv('City', lead.city),
                            _kv('Pincode', lead.pincode),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: isBusy ? null : onApproveLead,
                            style: FilledButton.styleFrom(
                              backgroundColor: ErpTheme.salesBlue,
                            ),
                            child: const Text('Approve Lead & Add to Master'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                const Text(
                  'REQUESTED ITEMS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: ErpTheme.slate400,
                  ),
                ),
                const SizedBox(height: 8),
                for (final item in order.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.product,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: ErpTheme.slate800,
                            ),
                          ),
                        ),
                        Text(
                          '${item.qty} cs  ×  ${formatInr(item.rate)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: ErpTheme.slate500,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          formatInr(item.total),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: ErpTheme.slate900,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: ErpTheme.slate50,
            child: isPendingTab
                ? Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 8,
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton(
                        onPressed: isBusy ? null : onReject,
                        style: TextButton.styleFrom(
                          foregroundColor: ErpTheme.dangerRose,
                        ),
                        child: const Text(
                          'REJECT ORDER',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      if (order.isNewLead)
                        FilledButton.icon(
                          onPressed: isBusy ? null : onVerifyLeadInMaster,
                          style: FilledButton.styleFrom(
                            backgroundColor: ErpTheme.productionAmber,
                          ),
                          icon: const Icon(Icons.warning_amber_rounded, size: 18),
                          label: const Text('Verify Lead in Master'),
                        )
                      else
                        FilledButton(
                          onPressed: isBusy ? null : onApproveAndCreatePerforma,
                          style: FilledButton.styleFrom(
                            backgroundColor: ErpTheme.salesBlueDark,
                          ),
                          child: const Text('Approve & Create Performa'),
                        ),
                    ],
                  )
                : Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: onPrintFactory,
                      style: FilledButton.styleFrom(
                        backgroundColor: ErpTheme.ordersEmerald,
                      ),
                      icon: const Icon(Icons.print_rounded, size: 18),
                      label: const Text('Print Factory Order'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: ErpTheme.slate500,
          ),
        ),
        Text(
          val.trim().isEmpty ? '-' : val,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: ErpTheme.slate900,
          ),
        ),
      ],
    );
  }
}
