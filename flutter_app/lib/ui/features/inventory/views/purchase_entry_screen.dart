import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/core/utils/inr_formatter.dart';
import 'package:crackers_erp/domain/models/godown.dart';
import 'package:crackers_erp/domain/models/product.dart';
import 'package:crackers_erp/domain/models/purchase.dart';
import 'package:crackers_erp/domain/models/supplier.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/core/erp_crud_widgets.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/core/searchable_picker.dart';
import 'package:crackers_erp/ui/features/inventory/view_models/purchase_view_model.dart';

class PurchaseEntryScreen extends StatefulWidget {
  const PurchaseEntryScreen({required this.viewModel, super.key});

  final PurchaseViewModel viewModel;

  @override
  State<PurchaseEntryScreen> createState() => _PurchaseEntryScreenState();
}

class _PurchaseEntryScreenState extends State<PurchaseEntryScreen> {
  final TextEditingController _billNoCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.viewModel.loadAll();
    });
  }

  @override
  void dispose() {
    _billNoCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _syncBillNo(String value) {
    if (_billNoCtrl.text != value) {
      _billNoCtrl.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.viewModel.date,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null && mounted) {
      widget.viewModel.setDate(picked);
    }
  }

  Future<void> _handleSave() async {
    final ok = await widget.viewModel.savePurchase();
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

  Future<void> _confirmToggleStatus(PurchaseRecord purchase) async {
    final actionVerb = purchase.isActive ? 'disable' : 'enable';
    final stockEffect = purchase.isActive ? 'decrease' : 'increase';
    final confirmed = await showErpConfirmDialog(
      context: context,
      title: '${purchase.isActive ? 'Disable' : 'Enable'} Purchase?',
      message:
          'Are you sure you want to $actionVerb ${purchase.number}? This will $stockEffect godown stock.',
      confirmLabel: purchase.isActive ? 'Disable' : 'Enable',
      destructive: purchase.isActive,
    );
    if (!confirmed || !mounted) return;
    final ok = await widget.viewModel.togglePurchaseStatus(purchase);
    if (ok && mounted && widget.viewModel.statusMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.viewModel.statusMessage!),
          backgroundColor: ErpTheme.ordersEmerald,
        ),
      );
    }
  }

  void _startEdit(PurchaseRecord purchase) {
    widget.viewModel.editPurchase(purchase);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErpScreenScaffold(
      title: 'Purchase Entry',
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final vm = widget.viewModel;
          _syncBillNo(vm.billNo);

          if (vm.isLoading && vm.rawMaterials.isEmpty && vm.history.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final supplierOptions = vm.suppliers
              .where((s) => s.isActive)
              .map(
                (s) => SearchablePickerOption<Supplier>(
                  value: s,
                  label: s.name,
                  subtitle: [
                    s.type,
                    if (s.state != null && s.state!.isNotEmpty) s.state!,
                    if (s.gstin != null && s.gstin!.isNotEmpty) s.gstin!,
                  ].join(' • '),
                  badge: s.type == 'Raw Material' ? 'RM' : s.type,
                  badgeColor: ErpTheme.purchasesOrange,
                  searchTerms: '${s.city ?? ''} ${s.mobile ?? ''}',
                ),
              )
              .toList();

          final matchedSupplier = vm.suppliers.cast<Supplier?>().firstWhere(
            (s) => s?.name.toLowerCase() == vm.supplierName.toLowerCase(),
            orElse: () => null,
          );

          return RefreshIndicator(
            onRefresh: vm.loadAll,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                ErpSectionHeaderBar(
                  title: vm.isEditing
                      ? 'Edit Purchase (${vm.purchaseNumber})'
                      : 'Purchase Entry (Inward Stock)',
                  subtitle:
                      'Record raw material purchases directly into godown stock ledger.',
                  accentColor: ErpTheme.purchasesOrange,
                  actions: [
                    if (vm.isEditing)
                      OutlinedButton.icon(
                        onPressed: vm.cancelEdit,
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Cancel Edit'),
                      ),
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
                    onDismiss: vm.clearMessages,
                  ),
                  const SizedBox(height: 10),
                ],
                if (vm.statusMessage != null) ...[
                  ErpSuccessBanner(
                    message: vm.statusMessage!,
                    onDismiss: vm.clearMessages,
                  ),
                  const SizedBox(height: 10),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ErpResponsiveFormGrid(
                      minItemWidth: 230,
                      children: [
                        InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Purchase No',
                            prefixIcon: Icon(Icons.tag_rounded, size: 18),
                          ),
                          child: Text(
                            vm.purchaseNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: ErpTheme.slate900,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(14),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Purchase Date',
                              prefixIcon: Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                              ),
                            ),
                            child: Text(
                              DateFormat('dd MMM yyyy').format(vm.date),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: ErpTheme.slate900,
                              ),
                            ),
                          ),
                        ),
                        SearchablePickerField<Supplier>(
                          label: 'Supplier *',
                          displayText: vm.supplierName,
                          value: matchedSupplier,
                          hintText: 'Select supplier',
                          prefixIcon: Icons.factory_outlined,
                          options: supplierOptions,
                          customActionLabel: 'Use custom supplier',
                          onCustomAction: (custom) => Supplier(
                            id: -1,
                            name: custom,
                            type: 'Raw Material',
                            status: 'Active',
                          ),
                          onSelected: (sup) {
                            if (sup.id == -1) {
                              vm.setCustomSupplierName(sup.name);
                            } else {
                              vm.selectSupplier(sup);
                            }
                          },
                          onClear: () => vm.setCustomSupplierName(''),
                        ),
                        TextField(
                          controller: _billNoCtrl,
                          onChanged: vm.setBillNo,
                          decoration: const InputDecoration(
                            labelText: 'Supplier Bill No',
                            hintText: 'e.g. INV-442',
                            prefixIcon: Icon(Icons.receipt_outlined, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Raw Material Line Items',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: ErpTheme.slate900,
                                ),
                              ),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: vm.addRow,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Item'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...vm.rows.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final row = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PurchaseLineCard(
                              key: ValueKey(row.localId),
                              index: idx,
                              row: row,
                              rawMaterials: vm.rawMaterials,
                              godowns: vm.godowns,
                              onSelectProduct: (p) =>
                                  vm.selectRowProduct(row.localId, p),
                              onSelectGodown: (g) =>
                                  vm.selectRowGodown(row.localId, g),
                              onUpdateNumbers: ({
                                int? packs,
                                double? rate,
                                double? discount,
                                double? taxRate,
                              }) => vm.updateRowNumbers(
                                row.localId,
                                packs: packs,
                                rate: rate,
                                discount: discount,
                                taxRate: taxRate,
                              ),
                              onRemove: () => vm.removeRow(row.localId),
                            ),
                          );
                        }),
                        OutlinedButton.icon(
                          onPressed: vm.addRow,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('+ Add Another Material Row'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 820;
                    final summaryCard = _buildSummaryCard(vm);
                    final actionCard = _buildGrandTotalCard(vm);
                    if (!wide) {
                      return Column(
                        children: [
                          summaryCard,
                          const SizedBox(height: 12),
                          actionCard,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: summaryCard),
                        const SizedBox(width: 12),
                        Expanded(flex: 5, child: actionCard),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildHistorySection(vm),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(PurchaseViewModel vm) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Purchase Summary',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: ErpTheme.slate500,
                    letterSpacing: 0.6,
                  ),
                ),
                ErpBadge(
                  label: vm.isIntraState
                      ? 'Intra-State (${PurchaseViewModel.companyState})'
                      : 'Inter-State (${vm.supplierState})',
                  backgroundColor: ErpTheme.purchasesOrangeSoft,
                  foregroundColor: ErpTheme.purchasesOrangeDark,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ErpStatTile(
                  label: 'Subtotal',
                  value: formatInr(vm.subtotal),
                  accentColor: ErpTheme.slate700,
                  icon: Icons.calculate_outlined,
                ),
                ErpStatTile(
                  label: 'Discount',
                  value: '-${formatInr(vm.totalDiscount)}',
                  accentColor: ErpTheme.dangerRose,
                  icon: Icons.discount_outlined,
                ),
                if (vm.isIntraState) ...[
                  ErpStatTile(
                    label: 'CGST',
                    value: formatInr(vm.cgst),
                    accentColor: ErpTheme.purchasesOrange,
                    icon: Icons.percent_rounded,
                  ),
                  ErpStatTile(
                    label: 'SGST',
                    value: formatInr(vm.sgst),
                    accentColor: ErpTheme.purchasesOrange,
                    icon: Icons.percent_rounded,
                  ),
                ] else
                  ErpStatTile(
                    label: 'IGST',
                    value: formatInr(vm.igst),
                    accentColor: ErpTheme.purchasesOrange,
                    icon: Icons.percent_rounded,
                  ),
                ErpStatTile(
                  label: 'Total Qty',
                  value: formatIndianCount(vm.totalQty),
                  accentColor: ErpTheme.godownTeal,
                  icon: Icons.layers_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrandTotalCard(PurchaseViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ErpTheme.purchasesOrangeDark, ErpTheme.purchasesOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ErpTheme.purchasesOrange.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'GRAND TOTAL',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatInr(vm.grandTotal),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: vm.isSaving ? null : _handleSave,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: ErpTheme.purchasesOrangeDark,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: vm.isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(
              vm.isEditing ? 'UPDATE PURCHASE' : 'SAVE & ADD STOCK',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(PurchaseViewModel vm) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  color: ErpTheme.purchasesOrange,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Recent Purchases Log',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: ErpTheme.slate900,
                    ),
                  ),
                ),
                Text(
                  '${vm.history.length} records',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ErpTheme.slate500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (vm.history.isEmpty)
              const ErpEmptyState(
                icon: Icons.shopping_cart_outlined,
                title: 'No Purchases Recorded Yet',
                subtitle: 'Saved inward purchases will appear here.',
              )
            else
              ...vm.history.map((purchase) {
                final taxLabel = purchase.igst > 0
                    ? 'IGST: ${formatInr(purchase.igst)}'
                    : 'C+S: ${formatInr(purchase.cgst + purchase.sgst)}';
                final busyToggle = vm.togglingPurchaseId == purchase.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ErpTheme.slate50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ErpTheme.slate200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ErpBadge(
                            label: purchase.number,
                            backgroundColor: ErpTheme.purchasesOrangeSoft,
                            foregroundColor: ErpTheme.purchasesOrangeDark,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              purchase.supplier,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: ErpTheme.slate900,
                              ),
                            ),
                          ),
                          ErpBadge(
                            label: purchase.status,
                            backgroundColor: purchase.isActive
                                ? ErpTheme.ordersEmeraldSoft
                                : ErpTheme.dangerRose.withValues(alpha: 0.12),
                            foregroundColor: purchase.isActive
                                ? ErpTheme.ordersEmerald
                                : ErpTheme.dangerRose,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            DateFormat('dd MMM yyyy').format(purchase.date),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: ErpTheme.slate500,
                            ),
                          ),
                          if (purchase.billNo.isNotEmpty)
                            Text(
                              'Bill: ${purchase.billNo}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: ErpTheme.slate700,
                              ),
                            ),
                          Text(
                            'Qty: ${purchase.qty}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: ErpTheme.slate700,
                            ),
                          ),
                          Text(
                            taxLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color: ErpTheme.slate500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            formatInr(purchase.value),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: ErpTheme.slate900,
                            ),
                          ),
                          const Spacer(),
                          OutlinedButton.icon(
                            onPressed: () => _startEdit(purchase),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: busyToggle
                                ? null
                                : () => _confirmToggleStatus(purchase),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: purchase.isActive
                                  ? ErpTheme.dangerRose
                                  : ErpTheme.ordersEmerald,
                            ),
                            icon: busyToggle
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    purchase.isActive
                                        ? Icons.power_settings_new_rounded
                                        : Icons.check_circle_outline_rounded,
                                    size: 16,
                                  ),
                            label: Text(
                              purchase.isActive ? 'Disable' : 'Enable',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _PurchaseLineCard extends StatefulWidget {
  const _PurchaseLineCard({
    required this.index,
    required this.row,
    required this.rawMaterials,
    required this.godowns,
    required this.onSelectProduct,
    required this.onSelectGodown,
    required this.onUpdateNumbers,
    required this.onRemove,
    super.key,
  });

  final int index;
  final PurchaseLineDraft row;
  final List<Product> rawMaterials;
  final List<Godown> godowns;
  final ValueChanged<Product> onSelectProduct;
  final ValueChanged<Godown> onSelectGodown;
  final void Function({
    int? packs,
    double? rate,
    double? discount,
    double? taxRate,
  }) onUpdateNumbers;
  final VoidCallback onRemove;

  @override
  State<_PurchaseLineCard> createState() => _PurchaseLineCardState();
}

class _PurchaseLineCardState extends State<_PurchaseLineCard> {
  late final TextEditingController _packsCtrl;
  late final TextEditingController _rateCtrl;
  late final TextEditingController _discountCtrl;
  late final TextEditingController _taxRateCtrl;

  @override
  void initState() {
    super.initState();
    _packsCtrl = TextEditingController(text: '${widget.row.packs}');
    _rateCtrl = TextEditingController(
      text: widget.row.rate > 0 ? widget.row.rate.toStringAsFixed(2) : '',
    );
    _discountCtrl = TextEditingController(
      text: widget.row.discount > 0
          ? widget.row.discount.toStringAsFixed(2)
          : '',
    );
    _taxRateCtrl = TextEditingController(
      text: widget.row.taxRate.toStringAsFixed(0),
    );
  }

  @override
  void didUpdateWidget(covariant _PurchaseLineCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncInt(_packsCtrl, widget.row.packs);
    _syncDouble(_rateCtrl, widget.row.rate);
    _syncDouble(_discountCtrl, widget.row.discount, emptyWhenZero: true);
    _syncDouble(_taxRateCtrl, widget.row.taxRate);
  }

  void _syncInt(TextEditingController ctrl, int value) {
    final parsed = int.tryParse(ctrl.text.trim()) ?? 0;
    if (parsed != value) {
      final next = '$value';
      ctrl.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
  }

  void _syncDouble(
    TextEditingController ctrl,
    double value, {
    bool emptyWhenZero = false,
  }) {
    final parsed = double.tryParse(ctrl.text.trim()) ?? 0;
    if ((parsed - value).abs() > 0.001) {
      final next = value == 0 && emptyWhenZero
          ? ''
          : (value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2));
      ctrl.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
  }

  @override
  void dispose() {
    _packsCtrl.dispose();
    _rateCtrl.dispose();
    _discountCtrl.dispose();
    _taxRateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;

    final materialOptions = widget.rawMaterials
        .map(
          (p) => SearchablePickerOption<Product>(
            value: p,
            label: p.name,
            subtitle:
                '${p.code} • ${p.unitQty} ${p.unit}/${p.packUnit ?? 'Pack'} • Tax ${p.tax.toStringAsFixed(0)}%',
            badge: formatInr(p.rate),
            badgeColor: ErpTheme.purchasesOrange,
          ),
        )
        .toList();

    final godownOptions = widget.godowns
        .map(
          (g) => SearchablePickerOption<Godown>(
            value: g,
            label: g.name,
            badge: 'GODOWN',
            badgeColor: ErpTheme.godownTeal,
          ),
        )
        .toList();

    final selectedProduct = widget.rawMaterials.cast<Product?>().firstWhere(
      (p) => p?.id == row.productId || p?.name == row.productName,
      orElse: () => null,
    );
    final selectedGodown = widget.godowns.cast<Godown?>().firstWhere(
      (g) => g?.id == row.godownId,
      orElse: () => null,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ErpTheme.slate50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ErpTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ErpBadge(
                label: 'Item #${widget.index + 1}',
                backgroundColor: ErpTheme.purchasesOrangeSoft,
                foregroundColor: ErpTheme.purchasesOrangeDark,
              ),
              const Spacer(),
              Text(
                'Net: ${formatInr(row.netAmt)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: ErpTheme.ordersEmerald,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Remove Row',
                onPressed: widget.onRemove,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: ErpTheme.dangerRose,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ErpResponsiveFormGrid(
            minItemWidth: 210,
            spacing: 10,
            children: [
              SearchablePickerField<Product>(
                label: 'Raw Material *',
                displayText: row.productName,
                value: selectedProduct,
                hintText: 'Select RM item',
                prefixIcon: Icons.inventory_2_outlined,
                options: materialOptions,
                onSelected: widget.onSelectProduct,
              ),
              SearchablePickerField<Godown>(
                label: 'Dest Godown *',
                displayText: row.godownName,
                value: selectedGodown,
                hintText: 'Select godown',
                prefixIcon: Icons.warehouse_outlined,
                options: godownOptions,
                onSelected: widget.onSelectGodown,
              ),
              TextField(
                controller: _packsCtrl,
                keyboardType: TextInputType.number,
                onChanged: (val) =>
                    widget.onUpdateNumbers(packs: int.tryParse(val.trim()) ?? 0),
                decoration: InputDecoration(
                  labelText: 'Packs (${row.packUnit})',
                  suffixText: row.packUnit,
                ),
              ),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Total Qty (${row.pricingUnit})',
                ),
                child: Text(
                  '${row.qty} ${row.pricingUnit}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: ErpTheme.slate900,
                  ),
                ),
              ),
              TextField(
                controller: _rateCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (val) => widget.onUpdateNumbers(
                  rate: double.tryParse(val.trim()) ?? 0,
                ),
                decoration: const InputDecoration(
                  labelText: 'Rate (₹)',
                  prefixText: '₹',
                ),
              ),
              TextField(
                controller: _discountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (val) => widget.onUpdateNumbers(
                  discount: double.tryParse(val.trim()) ?? 0,
                ),
                decoration: const InputDecoration(
                  labelText: 'Discount (₹)',
                  prefixText: '₹',
                ),
              ),
              TextField(
                controller: _taxRateCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (val) => widget.onUpdateNumbers(
                  taxRate: double.tryParse(val.trim()) ?? 0,
                ),
                decoration: const InputDecoration(
                  labelText: 'Tax %',
                  suffixText: '%',
                ),
              ),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Line Amount / Tax'),
                child: Text(
                  '${formatInr(row.amount)} + ${formatInr(row.taxAmt)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ErpTheme.slate700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
