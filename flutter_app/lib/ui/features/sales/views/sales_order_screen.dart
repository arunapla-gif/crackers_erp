import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/core/utils/inr_formatter.dart';
import 'package:crackers_erp/domain/models/customer.dart';
import 'package:crackers_erp/domain/models/product.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/core/erp_crud_widgets.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/core/searchable_picker.dart';
import 'package:crackers_erp/ui/features/auth/view_models/auth_view_model.dart';
import 'package:crackers_erp/ui/features/sales/view_models/sales_order_view_model.dart';

class SalesOrderScreen extends StatefulWidget {
  const SalesOrderScreen({
    required this.viewModel,
    required this.authViewModel,
    super.key,
  });

  final SalesOrderViewModel viewModel;
  final AuthViewModel authViewModel;

  @override
  State<SalesOrderScreen> createState() => _SalesOrderScreenState();
}

class _SalesOrderScreenState extends State<SalesOrderScreen> {
  final TextEditingController _gstinCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _idCtrl = TextEditingController();
  final TextEditingController _pinCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _syncLeadControllers();
    widget.viewModel.addListener(_syncLeadControllers);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.viewModel.initialize(user: widget.authViewModel.currentUser);
      }
    });
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_syncLeadControllers);
    _gstinCtrl.dispose();
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _cityCtrl.dispose();
    _idCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _syncCtrl(TextEditingController c, String val) {
    if (c.text != val) {
      c.value = c.value.copyWith(
        text: val,
        selection: TextSelection.collapsed(offset: val.length),
      );
    }
  }

  void _syncLeadControllers() {
    final l = widget.viewModel.lead;
    _syncCtrl(_gstinCtrl, l.gstin);
    _syncCtrl(_nameCtrl, l.name);
    _syncCtrl(_mobileCtrl, l.mobile);
    _syncCtrl(_cityCtrl, l.city);
    _syncCtrl(_idCtrl, l.idNumber);
    _syncCtrl(_pinCtrl, l.pincode);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final catalog = vm.groupedCatalog;

        return ErpScreenScaffold(
          title: 'Sales Order Entry',
          body: Column(
            children: [
              // Top Tabs + Refresh
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 840),
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'NEW_ORDER',
                          label: Text('New Order'),
                          icon: Icon(Icons.add_shopping_cart_rounded, size: 18),
                        ),
                        ButtonSegment(
                          value: 'HISTORY',
                          label: Text('My History'),
                          icon: Icon(Icons.history_rounded, size: 18),
                        ),
                      ],
                      selected: {vm.activeTab},
                      onSelectionChanged: (sel) {
                        if (sel.isNotEmpty) vm.setTab(sel.first);
                      },
                    ),
                  ),
                ),
              ),
              Expanded(
                child: vm.activeTab == 'HISTORY'
                    ? _buildHistoryTab(vm)
                    : _buildOrderEntryTab(vm, catalog),
              ),
              if (vm.activeTab == 'NEW_ORDER') _buildStickyOrderFooter(vm),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab(SalesOrderViewModel vm) {
    if (vm.isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.recentOrders.isEmpty) {
      return const ErpEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No Recent Orders',
        subtitle: 'Submitted orders will appear here with approval status.',
      );
    }
    return RefreshIndicator(
      onRefresh: vm.loadHistory,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: ErpTheme.slate200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'RECENT ORDERS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: ErpTheme.slate700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final o in vm.recentOrders) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ErpTheme.slate50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: ErpTheme.slate200),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    o.customerName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: ErpTheme.slate900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(o.date),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: ErpTheme.slate500,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formatInr(o.subtotal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: ErpTheme.slate900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                ErpBadge(
                                  label: o.status,
                                  backgroundColor: o.status == 'APPROVED'
                                      ? ErpTheme.ordersEmeraldSoft
                                      : o.status == 'REJECTED'
                                      ? ErpTheme.dangerRoseSoft
                                      : ErpTheme.productionAmberSoft,
                                  foregroundColor: o.status == 'APPROVED'
                                      ? ErpTheme.ordersEmerald
                                      : o.status == 'REJECTED'
                                      ? ErpTheme.dangerRose
                                      : ErpTheme.productionAmber,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderEntryTab(
    SalesOrderViewModel vm,
    Map<String, Map<String, List<Product>>> catalog,
  ) {
    if (vm.isLoading && vm.epProducts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (vm.errorMessage != null) ...[
                  ErpErrorBanner(
                    message: vm.errorMessage!,
                    onRetry: vm.clearMessages,
                  ),
                  const SizedBox(height: 12),
                ],
                if (vm.successMessage != null) ...[
                  ErpSuccessBanner(
                    message: vm.successMessage!,
                    onDismiss: vm.clearMessages,
                  ),
                  const SizedBox(height: 12),
                ],
                // Customer Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: ErpTheme.slate200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'CREATE NEW SALES ORDER',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: ErpTheme.salesBlue,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () =>
                                vm.toggleNewCustomer(!vm.isNewCustomer),
                            child: Text(
                              vm.isNewCustomer
                                  ? 'Select Existing'
                                  : '+ Add New Customer',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (!vm.isNewCustomer)
                        SearchablePickerField<Customer>(
                          label: 'Select Customer',
                          hintText: 'Search Customer...',
                          displayText: vm.selectedCustomer != null
                              ? '${vm.selectedCustomer!.name} - ${vm.selectedCustomer!.city?.isNotEmpty == true ? vm.selectedCustomer!.city : 'N/A'}'
                              : '',
                          value: vm.selectedCustomer,
                          options: vm.customers
                              .map(
                                (c) => SearchablePickerOption<Customer>(
                                  value: c,
                                  label:
                                      '${c.name} - ${c.city?.isNotEmpty == true ? c.city : 'N/A'}',
                                  subtitle: c.mobile ?? c.gstin ?? '',
                                ),
                              )
                              .toList(),
                          onSelected: vm.selectCustomer,
                          onClear: vm.selectedCustomerId == null
                              ? null
                              : () => vm.selectCustomer(null),
                        )
                      else
                        _buildNewLeadPanel(vm),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Product Menu
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: ErpTheme.slate200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'PRODUCT MENU (CASES)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: ErpTheme.slate800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (catalog.isEmpty)
                        const ErpEmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'No Products Found',
                          subtitle:
                              'No EP catalog items found for your assigned categories.',
                        )
                      else
                        for (final catEntry in catalog.entries) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: ErpTheme.salesBlue,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              catEntry.key.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: ErpTheme.slate900,
                              ),
                            ),
                          ),
                          for (final subEntry in catEntry.value.entries) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  const Expanded(child: Divider()),
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ErpTheme.slate100,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: ErpTheme.slate200,
                                      ),
                                    ),
                                    child: Text(
                                      subEntry.key.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                        color: ErpTheme.slate700,
                                      ),
                                    ),
                                  ),
                                  const Expanded(child: Divider()),
                                ],
                              ),
                            ),
                            for (final p in subEntry.value)
                              _SalesOrderProductTile(
                                key: ValueKey('so_prod_${p.id}'),
                                product: p,
                                rate: vm.rateForProduct(p),
                                qty: vm.quantityFor(p.id),
                                onChanged: (q) => vm.setCartQty(p.id, q),
                                onDelta: (d) => vm.incrementCartQty(p.id, d),
                              ),
                          ],
                          const SizedBox(height: 12),
                        ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewLeadPanel(SalesOrderViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ErpTheme.salesBlueSoft.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ErpTheme.salesBlue.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'GST', label: Text('GST Registered')),
              ButtonSegment(
                value: 'UNREGISTERED',
                label: Text('Unregistered / Cash'),
              ),
            ],
            selected: {vm.newCustomerType},
            onSelectionChanged: (sel) {
              if (sel.isNotEmpty) vm.setNewCustomerType(sel.first);
            },
          ),
          if (vm.newCustomerType == 'GST') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _gstinCtrl,
                    maxLength: 15,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (v) => vm.updateLead(gstin: v.toUpperCase()),
                    decoration: const InputDecoration(
                      labelText: 'GSTIN (15 Digits) *',
                      hintText: '33ABCDE1234F1Z5',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: vm.isVerifyingGstin ? null : vm.verifyGstin,
                  style: FilledButton.styleFrom(
                    backgroundColor: ErpTheme.salesBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                  ),
                  child: Text(vm.isVerifyingGstin ? 'Fetching...' : 'Fetch'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            onChanged: (v) => vm.updateLead(name: v),
            decoration: const InputDecoration(
              labelText: 'Shop / Customer Name *',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _mobileCtrl,
                  keyboardType: TextInputType.phone,
                  onChanged: (v) => vm.updateLead(mobile: v),
                  decoration: const InputDecoration(labelText: 'Mobile'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _cityCtrl,
                  onChanged: (v) => vm.updateLead(city: v),
                  decoration: const InputDecoration(labelText: 'City'),
                ),
              ),
            ],
          ),
          if (vm.newCustomerType == 'UNREGISTERED') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _idCtrl,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (v) => vm.updateLead(idNumber: v.toUpperCase()),
                    decoration: const InputDecoration(
                      labelText: 'Aadhaar / PAN *',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _pinCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    onChanged: (v) => vm.updateLead(pincode: v),
                    decoration: const InputDecoration(
                      labelText: 'Pincode *',
                      counterText: '',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStickyOrderFooter(SalesOrderViewModel vm) {
    final items = vm.cartItems;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ErpTheme.salesBlueDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'ORDER SUBTOTAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        formatInr(vm.subtotal),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: vm.isSubmitting || items.isEmpty
                      ? null
                      : vm.submitOrder,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: ErpTheme.salesBlueDark,
                    disabledBackgroundColor: Colors.white24,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  child: Text(
                    vm.isSubmitting
                        ? 'SUBMITTING...'
                        : 'SUBMIT ORDER (${items.length} ITEMS)',
                    style: const TextStyle(fontWeight: FontWeight.w900),
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

class _SalesOrderProductTile extends StatefulWidget {
  const _SalesOrderProductTile({
    required this.product,
    required this.rate,
    required this.qty,
    required this.onChanged,
    required this.onDelta,
    super.key,
  });

  final Product product;
  final double rate;
  final int qty;
  final void Function(int qty) onChanged;
  final void Function(int delta) onDelta;

  @override
  State<_SalesOrderProductTile> createState() => _SalesOrderProductTileState();
}

class _SalesOrderProductTileState extends State<_SalesOrderProductTile> {
  late final TextEditingController _qtyCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(
      text: widget.qty > 0 ? '${widget.qty}' : '',
    );
  }

  @override
  void didUpdateWidget(covariant _SalesOrderProductTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final desired = widget.qty > 0 ? '${widget.qty}' : '';
    final parsedCurrent = int.tryParse(_qtyCtrl.text) ?? 0;
    if (parsedCurrent != widget.qty) {
      _qtyCtrl.value = _qtyCtrl.value.copyWith(
        text: desired,
        selection: TextSelection.collapsed(offset: desired.length),
      );
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.qty > 0;
    final totalBoxes = widget.qty * widget.product.boxesPerCase;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: active
            ? ErpTheme.salesBlueSoft.withValues(alpha: 0.45)
            : Colors.transparent,
        border: const Border(bottom: BorderSide(color: ErpTheme.slate100)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: ErpTheme.slate900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatInr(widget.rate)} / box  •  ${widget.product.boxesPerCase} boxes/case',
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.filledTonal(
                    onPressed: widget.qty > 0 ? () => widget.onDelta(-1) : null,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove_rounded, size: 16),
                  ),
                  SizedBox(
                    width: 54,
                    child: TextField(
                      controller: _qtyCtrl,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      onChanged: (v) =>
                          widget.onChanged(int.tryParse(v) ?? 0),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                      decoration: const InputDecoration(
                        hintText: '0',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => widget.onDelta(1),
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add_rounded, size: 16),
                  ),
                ],
              ),
              if (active) ...[
                const SizedBox(height: 3),
                Text(
                  '$totalBoxes BXS',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: ErpTheme.salesBlueDark,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
