import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/core/utils/inr_formatter.dart';
import 'package:crackers_erp/domain/models/godown.dart';
import 'package:crackers_erp/domain/models/product.dart';
import 'package:crackers_erp/domain/models/vehicle.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/core/erp_crud_widgets.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/core/searchable_picker.dart';
import 'package:crackers_erp/ui/features/inventory/view_models/transfer_view_model.dart';

class StockTransferScreen extends StatefulWidget {
  const StockTransferScreen({required this.viewModel, super.key});

  final TransferViewModel viewModel;

  @override
  State<StockTransferScreen> createState() => _StockTransferScreenState();
}

class _StockTransferScreenState extends State<StockTransferScreen> {
  final TextEditingController _remarksCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.viewModel.loadAll();
    });
  }

  @override
  void dispose() {
    _remarksCtrl.dispose();
    super.dispose();
  }

  void _syncRemarks(String value) {
    if (_remarksCtrl.text != value) {
      _remarksCtrl.value = TextEditingValue(
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
    final ok = await widget.viewModel.saveTransfer();
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

  @override
  Widget build(BuildContext context) {
    return ErpScreenScaffold(
      title: 'Stock Transfer',
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final vm = widget.viewModel;
          _syncRemarks(vm.remarks);

          if (vm.isLoading && vm.godowns.isEmpty && vm.vehicles.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final vehicleOptions = vm.vehicles
              .map(
                (v) => SearchablePickerOption<Vehicle>(
                  value: v,
                  label: v.no,
                  subtitle: [
                    if (v.name != null && v.name!.isNotEmpty) v.name!,
                    '${v.drivers.length} driver(s)',
                  ].join(' • '),
                  badge: v.no,
                  badgeColor: ErpTheme.purchasesOrange,
                ),
              )
              .toList();

          return RefreshIndicator(
            onRefresh: vm.loadAll,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                ErpSectionHeaderBar(
                  title: 'Stock Transfer Entry',
                  subtitle:
                      'Move materials or stock between godowns with live stock validation.',
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
                      minItemWidth: 210,
                      children: [
                        InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Transfer No',
                            prefixIcon: Icon(Icons.tag_rounded, size: 18),
                          ),
                          child: Text(
                            vm.transferNumber,
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
                              labelText: 'Transfer Date',
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
                        SearchablePickerField<Vehicle>(
                          label: 'Vehicle *',
                          displayText: vm.selectedVehicle == null
                              ? ''
                              : '${vm.selectedVehicle!.no}${vm.selectedVehicle!.name != null ? ' (${vm.selectedVehicle!.name})' : ''}',
                          value: vm.selectedVehicle,
                          hintText: 'Select vehicle',
                          prefixIcon: Icons.local_shipping_outlined,
                          options: vehicleOptions,
                          onSelected: vm.selectVehicle,
                          onClear: () => vm.selectVehicle(null),
                        ),
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                            'driver-${vm.selectedVehicle?.id ?? 'none'}-${vm.driverName}',
                          ),
                          initialValue: vm.availableDrivers.any(
                                (d) => d.name == vm.driverName,
                              )
                              ? vm.driverName
                              : '',
                          decoration: const InputDecoration(
                            labelText: 'Driver',
                            prefixIcon: Icon(Icons.person_outline, size: 18),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: '',
                              child: Text('Select Driver'),
                            ),
                            ...vm.availableDrivers.map(
                              (d) => DropdownMenuItem<String>(
                                value: d.name,
                                child: Text(
                                  d.phone.isNotEmpty
                                      ? '${d.name} (${d.phone})'
                                      : d.name,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) => vm.setDriverName(val ?? ''),
                        ),
                        TextField(
                          controller: _remarksCtrl,
                          onChanged: vm.setRemarks,
                          decoration: const InputDecoration(
                            labelText: 'Remarks (Optional)',
                            hintText: 'Transfer notes...',
                            prefixIcon: Icon(Icons.notes_outlined, size: 18),
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
                                'Items To Transfer',
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
                              label: const Text('Add Row'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...vm.rows.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final row = entry.value;
                          final available = vm.availableQtyForRow(row);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TransferLineCard(
                              key: ValueKey(row.localId),
                              index: idx,
                              row: row,
                              availableQty: available,
                              products: vm.products,
                              godowns: vm.godowns,
                              onSelectFromGodown: (g) =>
                                  vm.selectFromGodown(row.localId, g),
                              onSelectToGodown: (g) =>
                                  vm.selectToGodown(row.localId, g),
                              onSelectProduct: (p) =>
                                  vm.selectProduct(row.localId, p),
                              onQtyChanged: (qty) =>
                                  vm.updateRowQty(row.localId, qty),
                              onRemove: () => vm.removeRow(row.localId),
                            ),
                          );
                        }),
                        OutlinedButton.icon(
                          onPressed: vm.addRow,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('+ Add Another Transfer Line'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 780;
                    final summary = Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ErpStatTile(
                              label: 'Total Transfer Qty',
                              value: formatIndianCount(vm.totalQty),
                              accentColor: ErpTheme.purchasesOrange,
                              icon: Icons.swap_horiz_rounded,
                            ),
                            ErpStatTile(
                              label: 'Line Items',
                              value: '${vm.rows.length}',
                              accentColor: ErpTheme.godownTeal,
                              icon: Icons.list_alt_rounded,
                            ),
                            ErpStatTile(
                              label: 'Est Stock Value',
                              value: formatInr(vm.totalValue),
                              accentColor: ErpTheme.slate700,
                              icon: Icons.currency_rupee_rounded,
                            ),
                          ],
                        ),
                      ),
                    );

                    final action = Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            ErpTheme.purchasesOrangeDark,
                            ErpTheme.purchasesOrange,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: FilledButton.icon(
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
                            : const Icon(Icons.swap_horiz_rounded),
                        label: const Text(
                          'CONFIRM & TRANSFER',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    );

                    if (!wide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          summary,
                          const SizedBox(height: 12),
                          action,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 7, child: summary),
                        const SizedBox(width: 12),
                        Expanded(flex: 4, child: action),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TransferLineCard extends StatefulWidget {
  const _TransferLineCard({
    required this.index,
    required this.row,
    required this.availableQty,
    required this.products,
    required this.godowns,
    required this.onSelectFromGodown,
    required this.onSelectToGodown,
    required this.onSelectProduct,
    required this.onQtyChanged,
    required this.onRemove,
    super.key,
  });

  final int index;
  final TransferLineDraft row;
  final int availableQty;
  final List<Product> products;
  final List<Godown> godowns;
  final ValueChanged<Godown> onSelectFromGodown;
  final ValueChanged<Godown> onSelectToGodown;
  final ValueChanged<Product> onSelectProduct;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onRemove;

  @override
  State<_TransferLineCard> createState() => _TransferLineCardState();
}

class _TransferLineCardState extends State<_TransferLineCard> {
  late final TextEditingController _qtyCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: '${widget.row.qty}');
  }

  @override
  void didUpdateWidget(covariant _TransferLineCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final parsed = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (parsed != widget.row.qty) {
      final next = '${widget.row.qty}';
      _qtyCtrl.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
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
    final row = widget.row;
    final hasSourceAndProduct =
        row.fromGodownId != null && row.productName.trim().isNotEmpty;
    final insufficient = hasSourceAndProduct && row.qty > widget.availableQty;

    final productOptions = widget.products
        .map(
          (p) => SearchablePickerOption<Product>(
            value: p,
            label: p.name,
            subtitle: '${p.code} • ${p.type}',
            badge: p.code,
            badgeColor: ErpTheme.godownTeal,
          ),
        )
        .toList();

    final selectedProduct = widget.products.cast<Product?>().firstWhere(
      (p) => p?.id == row.productId || p?.name == row.productName,
      orElse: () => null,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ErpTheme.slate50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: insufficient ? ErpTheme.dangerRose : ErpTheme.slate200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ErpBadge(
                label: 'Line #${widget.index + 1}',
                backgroundColor: ErpTheme.purchasesOrangeSoft,
                foregroundColor: ErpTheme.purchasesOrangeDark,
              ),
              const Spacer(),
              Text(
                'Value: ${formatInr(row.value)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: ErpTheme.slate900,
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
            minItemWidth: 200,
            spacing: 10,
            children: [
              DropdownButtonFormField<int?>(
                key: ValueKey('from-${row.localId}-${row.fromGodownId}'),
                initialValue: row.fromGodownId,
                decoration: const InputDecoration(
                  labelText: 'From Godown *',
                  prefixIcon: Icon(Icons.logout_rounded, size: 18),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Select Source'),
                  ),
                  ...widget.godowns.map(
                    (g) => DropdownMenuItem<int?>(
                      value: g.id,
                      child: Text(g.name),
                    ),
                  ),
                ],
                onChanged: (id) {
                  if (id == null) return;
                  final godown = widget.godowns.firstWhere((g) => g.id == id);
                  widget.onSelectFromGodown(godown);
                },
              ),
              DropdownButtonFormField<int?>(
                key: ValueKey('to-${row.localId}-${row.toGodownId}'),
                initialValue: row.toGodownId,
                decoration: const InputDecoration(
                  labelText: 'To Godown *',
                  prefixIcon: Icon(Icons.login_rounded, size: 18),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Select Destination'),
                  ),
                  ...widget.godowns.map(
                    (g) => DropdownMenuItem<int?>(
                      value: g.id,
                      child: Text(g.name),
                    ),
                  ),
                ],
                onChanged: (id) {
                  if (id == null) return;
                  final godown = widget.godowns.firstWhere((g) => g.id == id);
                  widget.onSelectToGodown(godown);
                },
              ),
              SearchablePickerField<Product>(
                label: 'Product *',
                displayText: row.productName,
                value: selectedProduct,
                hintText: 'Select product',
                prefixIcon: Icons.inventory_2_outlined,
                options: productOptions,
                onSelected: widget.onSelectProduct,
              ),
              TextField(
                controller: _qtyCtrl,
                keyboardType: TextInputType.number,
                onChanged: (val) =>
                    widget.onQtyChanged(int.tryParse(val.trim()) ?? 0),
                decoration: InputDecoration(
                  labelText: 'Qty *',
                  errorText: insufficient
                      ? 'Available: ${widget.availableQty}'
                      : null,
                  helperText: hasSourceAndProduct && !insufficient
                      ? 'Stock Available: ${widget.availableQty}'
                      : null,
                ),
              ),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Avg Rate'),
                child: Text(
                  formatInr(row.rate),
                  style: const TextStyle(
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
