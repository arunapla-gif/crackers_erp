import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/domain/models/supplier.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/core/erp_crud_widgets.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/features/masters/view_models/supplier_master_view_model.dart';
import 'package:crackers_erp/ui/features/masters/views/master_shared_widgets.dart';

class SupplierMasterScreen extends StatefulWidget {
  const SupplierMasterScreen({required this.viewModel, super.key});

  final SupplierMasterViewModel viewModel;

  @override
  State<SupplierMasterScreen> createState() => _SupplierMasterScreenState();
}

class _SupplierMasterScreenState extends State<SupplierMasterScreen> {
  final _gstinCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
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
    _gstinCtrl.dispose();
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _addressCtrl.dispose();
    _pincodeCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _idCtrl.dispose();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _syncControllers() {
    final vm = widget.viewModel;
    syncMasterController(_gstinCtrl, vm.gstin);
    syncMasterController(_nameCtrl, vm.name);
    syncMasterController(_mobileCtrl, vm.mobile);
    syncMasterController(_addressCtrl, vm.address);
    syncMasterController(_pincodeCtrl, vm.pincode);
    syncMasterController(_cityCtrl, vm.city);
    syncMasterController(_districtCtrl, vm.district);
    syncMasterController(_idCtrl, vm.idNumber);
    syncMasterController(_searchCtrl, vm.searchQuery);
  }

  void _handleEdit(Supplier s) {
    widget.viewModel.editSupplier(s);
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
        return ErpScreenScaffold(
          title: 'Supplier Master',
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
                          accentColor: ErpTheme.purchasesOrange,
                          title: 'Supplier Master',
                          subtitle:
                              'Maintain Raw Material & Finished Goods suppliers with GSTIN lookup.',
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
                              ? 'Edit Supplier Details'
                              : 'Supplier Details Master',
                          accentColor: ErpTheme.purchasesOrange,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ErpResponsiveFormGrid(
                                minItemWidth: 230,
                                children: [
                                  TextField(
                                    controller: _gstinCtrl,
                                    maxLength: 15,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    decoration: InputDecoration(
                                      labelText: 'GSTIN Lookup',
                                      counterText: '',
                                      hintText: 'Enter 15 char GSTIN',
                                      suffixIcon: vm.isLookingUpGstin
                                          ? const Padding(
                                              padding: EdgeInsets.all(12),
                                              child: SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                    onChanged: (v) =>
                                        vm.updateField(gstin: v),
                                  ),
                                  TextField(
                                    controller: _nameCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Supplier / Business Name *',
                                      hintText: 'Supplier name',
                                    ),
                                    onChanged: (v) => vm.updateField(name: v),
                                  ),
                                  TextField(
                                    controller: _mobileCtrl,
                                    keyboardType: TextInputType.phone,
                                    maxLength: 10,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Mobile',
                                      counterText: '',
                                      hintText: '10 digit mobile',
                                    ),
                                    onChanged: (v) =>
                                        vm.updateField(mobile: v),
                                  ),
                                  DropdownButtonFormField<String>(
                                    key: ValueKey('sup_type_${vm.type}'),
                                    initialValue: vm.type,
                                    decoration: const InputDecoration(
                                      labelText: 'Supplier Type',
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Raw Material',
                                        child: Text('Raw Material'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Finished Goods',
                                        child: Text('Finished Goods'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) vm.updateField(type: v);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _addressCtrl,
                                minLines: 2,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  labelText: 'Address',
                                  hintText: 'Full supplier address',
                                ),
                                onChanged: (v) => vm.updateField(address: v),
                              ),
                              if (vm.addresses.length > 1) ...[
                                const SizedBox(height: 10),
                                AdditionalAddressesBox(addresses: vm.addresses),
                              ],
                              const SizedBox(height: 12),
                              ErpResponsiveFormGrid(
                                minItemWidth: 200,
                                children: [
                                  IndianStatePickerField(
                                    value: vm.state,
                                    onChanged: (s) => vm.updateField(state: s),
                                  ),
                                  TextField(
                                    controller: _pincodeCtrl,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: InputDecoration(
                                      labelText: 'Pincode',
                                      counterText: '',
                                      hintText: '6 digits',
                                      suffixIcon: vm.isLookingUpPincode
                                          ? const Padding(
                                              padding: EdgeInsets.all(12),
                                              child: SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                    onChanged: (v) =>
                                        vm.updateField(pincode: v),
                                  ),
                                  TextField(
                                    controller: _cityCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'City',
                                      hintText: 'City name',
                                    ),
                                    onChanged: (v) => vm.updateField(city: v),
                                  ),
                                  TextField(
                                    controller: _districtCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'District',
                                      hintText: 'District name',
                                    ),
                                    onChanged: (v) =>
                                        vm.updateField(district: v),
                                  ),
                                  TextField(
                                    controller: _idCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Aadhaar / ID',
                                    ),
                                    onChanged: (v) =>
                                        vm.updateField(idNumber: v),
                                  ),
                                ],
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
                                          vm.isSaving ? null : vm.saveSupplier,
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
                                      label: const Text('Save Supplier'),
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
                            hintText: 'Filter saved suppliers...',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: vm.setSearchQuery,
                        ),
                        const SizedBox(height: 14),
                        _SupplierCategorySection(
                          title: 'Raw Material Suppliers',
                          items: vm.rawMaterialSuppliers,
                          onEdit: _handleEdit,
                          onToggleStatus: vm.toggleStatus,
                        ),
                        const SizedBox(height: 14),
                        _SupplierCategorySection(
                          title: 'Finished Goods Suppliers',
                          items: vm.finishedGoodsSuppliers,
                          onEdit: _handleEdit,
                          onToggleStatus: vm.toggleStatus,
                        ),
                        const SizedBox(height: 14),
                        _SupplierCategorySection(
                          title: 'Other Suppliers',
                          items: vm.otherSuppliers,
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

class _SupplierCategorySection extends StatelessWidget {
  const _SupplierCategorySection({
    required this.title,
    required this.items,
    required this.onEdit,
    required this.onToggleStatus,
  });

  final String title;
  final List<Supplier> items;
  final ValueChanged<Supplier> onEdit;
  final ValueChanged<Supplier> onToggleStatus;

  @override
  Widget build(BuildContext context) {
    return MasterFormCard(
      title: '$title (${items.length})',
      accentColor: ErpTheme.purchasesOrange,
      child: items.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'No suppliers found in this category.',
                textAlign: TextAlign.center,
                style: TextStyle(color: ErpTheme.slate500),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 780) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 760),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          ErpTheme.slate50,
                        ),
                        columns: const [
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Mobile')),
                          DataColumn(label: Text('City / District')),
                          DataColumn(label: Text('State')),
                          DataColumn(label: Text('GSTIN')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: items.map((s) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  s.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              DataCell(Text(s.mobile ?? '-')),
                              DataCell(
                                Text(
                                  [
                                    s.city ?? '',
                                    s.district ?? '',
                                  ].where((e) => e.isNotEmpty).join(', '),
                                ),
                              ),
                              DataCell(Text(s.state ?? '-')),
                              DataCell(Text((s.gstin ?? '-').toUpperCase())),
                              DataCell(
                                MasterStatusBadge(isActive: s.isActive),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton(
                                      onPressed: () => onEdit(s),
                                      child: const Text('Edit'),
                                    ),
                                    TextButton(
                                      onPressed: () => onToggleStatus(s),
                                      style: TextButton.styleFrom(
                                        foregroundColor: s.isActive
                                            ? ErpTheme.dangerRose
                                            : ErpTheme.ordersEmerald,
                                      ),
                                      child: Text(
                                        s.isActive ? 'Disable' : 'Enable',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                }
                return Column(
                  children: items.map((s) {
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
                              Expanded(
                                child: Text(
                                  s.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              MasterStatusBadge(isActive: s.isActive),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              if ((s.mobile ?? '').isNotEmpty) s.mobile!,
                              if ((s.city ?? '').isNotEmpty) s.city!,
                              if ((s.gstin ?? '').isNotEmpty)
                                s.gstin!.toUpperCase(),
                            ].join(' • '),
                            style: const TextStyle(
                              fontSize: 12,
                              color: ErpTheme.slate700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => onEdit(s),
                                child: const Text('Edit'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () => onToggleStatus(s),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: s.isActive
                                      ? ErpTheme.dangerRose
                                      : ErpTheme.ordersEmerald,
                                ),
                                child: Text(s.isActive ? 'Disable' : 'Enable'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
    );
  }
}

