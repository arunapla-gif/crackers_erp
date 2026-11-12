import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/core/utils/inr_formatter.dart';
import 'package:crackers_erp/domain/models/product.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/core/erp_crud_widgets.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/core/searchable_picker.dart';
import 'package:crackers_erp/ui/features/masters/view_models/product_master_view_model.dart';
import 'package:crackers_erp/ui/features/masters/views/master_shared_widgets.dart';

class ProductMasterScreen extends StatefulWidget {
  const ProductMasterScreen({required this.viewModel, super.key});

  final ProductMasterViewModel viewModel;

  @override
  State<ProductMasterScreen> createState() => _ProductMasterScreenState();
}

class _ProductMasterScreenState extends State<ProductMasterScreen> {
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _catCtrl = TextEditingController();
  final _subCatCtrl = TextEditingController();
  final _hsnCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _boxesCtrl = TextEditingController();
  final _unitQtyCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _syncControllers();
    widget.viewModel.addListener(_syncControllers);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.viewModel.initialize();
    });
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_syncControllers);
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _catCtrl.dispose();
    _subCatCtrl.dispose();
    _hsnCtrl.dispose();
    _taxCtrl.dispose();
    _rateCtrl.dispose();
    _boxesCtrl.dispose();
    _unitQtyCtrl.dispose();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _syncControllers() {
    final vm = widget.viewModel;
    syncMasterController(_codeCtrl, vm.code);
    syncMasterController(_nameCtrl, vm.name);
    syncMasterController(_catCtrl, vm.category);
    syncMasterController(_subCatCtrl, vm.subCategory);
    syncMasterController(_hsnCtrl, vm.hsn);
    syncMasterController(_taxCtrl, vm.tax);
    syncMasterController(_rateCtrl, vm.rate);
    syncMasterController(_boxesCtrl, vm.boxesPerCase);
    syncMasterController(_unitQtyCtrl, vm.unitQty);
    syncMasterController(_searchCtrl, vm.searchQuery);
  }

  void _handleEdit(Product p) {
    widget.viewModel.editProduct(p);
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final alias = vm.selectedAlias;

        return ErpScreenScaffold(
          title: 'Product Master',
          body: RefreshIndicator(
            onRefresh: vm.initialize,
            child: ListView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ErpSectionHeaderBar(
                          accentColor: ErpTheme.salesBlue,
                          title: 'Product Master',
                          subtitle:
                              'Configure Invoice (INV), Estimate (EP), and Factory Processing (WIP) products.',
                          actions: [
                            OutlinedButton.icon(
                              onPressed: vm.isLoading ? null : vm.initialize,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Refresh'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (vm.errorMessage != null) ...[
                          ErpErrorBanner(
                            message: vm.errorMessage!,
                            onDismiss: vm.clearMessages,
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
                        MasterFormCard(
                          title: vm.editingId != null
                              ? 'Edit Product (${vm.code})'
                              : 'Product Details Master',
                          accentColor: ErpTheme.salesBlue,
                          trailing: const ErpBadge(
                            label: 'AUTO CODE',
                            backgroundColor: ErpTheme.salesBlueSoft,
                            foregroundColor: ErpTheme.salesBlueDark,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ErpResponsiveFormGrid(
                                minItemWidth: 200,
                                children: [
                                  DropdownButtonFormField<String>(
                                    key: ValueKey('ptype_${vm.type}'),
                                    initialValue: const [
                                      'INV',
                                      'EP',
                                      'WIP',
                                    ].contains(vm.type.toUpperCase())
                                        ? vm.type.toUpperCase()
                                        : 'INV',
                                    decoration: const InputDecoration(
                                      labelText: 'Type',
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'INV',
                                        child: Text('Invoice Item (INV)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'EP',
                                        child: Text('Estimate Only (EP)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'WIP',
                                        child: Text('Factory Processing (WIP)'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) vm.setType(v);
                                    },
                                  ),
                                  TextField(
                                    controller: _codeCtrl,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    decoration: const InputDecoration(
                                      labelText: 'Product Code *',
                                      hintText: 'e.g. INV001',
                                    ),
                                    onChanged: (v) => vm.updateField(code: v),
                                  ),
                                  TextField(
                                    controller: _nameCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Product Name *',
                                      hintText: 'e.g. 1000 Wala',
                                    ),
                                    onChanged: (v) => vm.updateField(name: v),
                                  ),
                                  TextField(
                                    controller: _catCtrl,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    decoration: const InputDecoration(
                                      labelText: 'Product Category',
                                      hintText: 'e.g. STANDARD WALAS',
                                    ),
                                    onChanged: (v) =>
                                        vm.updateField(category: v),
                                  ),
                                  TextField(
                                    controller: _subCatCtrl,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    decoration: const InputDecoration(
                                      labelText: 'Sub-Category',
                                      hintText: 'e.g. 400 COUNT',
                                    ),
                                    onChanged: (v) =>
                                        vm.updateField(subCategory: v),
                                  ),
                                  TextField(
                                    controller: _hsnCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'HSN Code',
                                    ),
                                    onChanged: (v) => vm.updateField(hsn: v),
                                  ),
                                  TextField(
                                    controller: _taxCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Tax (%)',
                                    ),
                                    onChanged: (v) => vm.updateField(tax: v),
                                  ),
                                  TextField(
                                    controller: _rateCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Rate (₹)',
                                    ),
                                    onChanged: (v) => vm.updateField(rate: v),
                                  ),
                                  TextField(
                                    controller: _boxesCtrl,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Boxes / Case',
                                    ),
                                    onChanged: (v) =>
                                        vm.updateField(boxesPerCase: v),
                                  ),
                                  TextField(
                                    controller: _unitQtyCtrl,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Unit Qty',
                                    ),
                                    onChanged: (v) =>
                                        vm.updateField(unitQty: v),
                                  ),
                                  DropdownButtonFormField<String>(
                                    key: ValueKey('punit_${vm.unit}'),
                                    initialValue: const [
                                      'Case',
                                      'Box',
                                      'Pkt',
                                      'Pcs',
                                    ].contains(vm.unit)
                                        ? vm.unit
                                        : 'Case',
                                    decoration: const InputDecoration(
                                      labelText: 'Unit Type',
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Case',
                                        child: Text('Case'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Box',
                                        child: Text('Box'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Pkt',
                                        child: Text('Pkt'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Pcs',
                                        child: Text('Pcs'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) vm.updateField(unit: v);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Divider(),
                              const SizedBox(height: 8),
                              const Text(
                                'Factory Dispatch Mapping (Optional)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: ErpTheme.productionAmberDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'If selected, selling this product internally generates a factory order for the mapped product instead.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: ErpTheme.slate500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SearchablePickerField<Product>(
                                label: 'Mapped Factory / WIP Product',
                                value: alias,
                                displayText: alias == null
                                    ? ''
                                    : '${alias.name} (${alias.code})',
                                hintText:
                                    '-- No Mapping (Deduct Own Stock) --',
                                options: vm.aliasCandidates
                                    .map(
                                      (p) => SearchablePickerOption(
                                        value: p,
                                        label: '${p.name} (${p.code})',
                                        subtitle:
                                            '${p.type} • ${p.displaySubCategory}',
                                      ),
                                    )
                                    .toList(),
                                onSelected: (p) =>
                                    vm.updateField(factoryAliasId: p.id),
                                onClear: vm.factoryAliasId == null
                                    ? null
                                    : () => vm.updateField(
                                          clearFactoryAlias: true,
                                        ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: ErpTheme.slate50,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: ErpTheme.slate200),
                                ),
                                child: Wrap(
                                  alignment: WrapAlignment.end,
                                  spacing: 10,
                                  runSpacing: 8,
                                  children: [
                                    OutlinedButton(
                                      onPressed:
                                          vm.isSaving ? null : vm.clearForm,
                                      child: const Text('Clear'),
                                    ),
                                    FilledButton.icon(
                                      onPressed:
                                          vm.isSaving ? null : vm.saveProduct,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: ErpTheme.ordersEmerald,
                                      ),
                                      icon: vm.isSaving
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.save_rounded),
                                      label: const Text('Save Product'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _searchCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Search all products by code, name or category...',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: vm.setSearchQuery,
                        ),
                        const SizedBox(height: 14),
                        _ProductGroupSection(
                          title: 'Invoice Items (INV)',
                          grouped: vm.groupedByType('INV'),
                          onEdit: _handleEdit,
                          onToggleStatus: vm.toggleStatus,
                        ),
                        const SizedBox(height: 14),
                        _ProductGroupSection(
                          title: 'Estimate Items (EP)',
                          grouped: vm.groupedByType('EP'),
                          onEdit: _handleEdit,
                          onToggleStatus: vm.toggleStatus,
                        ),
                        const SizedBox(height: 14),
                        _ProductGroupSection(
                          title: 'Factory Processing (WIP)',
                          grouped: vm.groupedByType('WIP'),
                          onEdit: _handleEdit,
                          onToggleStatus: vm.toggleStatus,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProductGroupSection extends StatelessWidget {
  const _ProductGroupSection({
    required this.title,
    required this.grouped,
    required this.onEdit,
    required this.onToggleStatus,
  });

  final String title;
  final Map<String, List<Product>> grouped;
  final ValueChanged<Product> onEdit;
  final ValueChanged<Product> onToggleStatus;

  @override
  Widget build(BuildContext context) {
    final total = grouped.values.fold<int>(0, (s, list) => s + list.length);
    return MasterFormCard(
      title: '$title ($total)',
      accentColor: ErpTheme.salesBlue,
      child: total == 0
          ? const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'No products found in this category.',
                textAlign: TextAlign.center,
                style: TextStyle(color: ErpTheme.slate500),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: grouped.entries.map((entry) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ErpTheme.slate200),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFB4D2A5),
                          border: Border(
                            bottom: BorderSide(color: Color(0xFF9BB88D)),
                          ),
                        ),
                        child: Text(
                          entry.key.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: ErpTheme.slate900,
                          ),
                        ),
                      ),
                      ...entry.value.map((p) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: ErpTheme.slate100),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          p.code,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: ErpTheme.slate900,
                                          ),
                                        ),
                                        if ((p.category ?? '').isNotEmpty)
                                          ErpBadge(
                                            label: p.category!,
                                            backgroundColor:
                                                ErpTheme.salesBlueSoft,
                                            foregroundColor:
                                                ErpTheme.salesBlueDark,
                                          ),
                                        MasterStatusBadge(isActive: p.isActive),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      p.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: ErpTheme.slate800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'HSN ${p.hsn} • Rate: ${formatInr(p.rate)} • Pack: ${p.boxesPerCase} Bxs/Case',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: ErpTheme.slate500,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  OutlinedButton(
                                    onPressed: () => onEdit(p),
                                    child: const Text('Edit'),
                                  ),
                                  OutlinedButton(
                                    onPressed: () => onToggleStatus(p),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: p.isActive
                                          ? ErpTheme.dangerRose
                                          : ErpTheme.ordersEmerald,
                                    ),
                                    child: Text(
                                      p.isActive ? 'Disable' : 'Enable',
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
                );
              }).toList(),
            ),
    );
  }
}

