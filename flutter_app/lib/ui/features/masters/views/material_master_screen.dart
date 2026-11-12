import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/domain/models/product.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/core/erp_crud_widgets.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/features/masters/view_models/material_master_view_model.dart';
import 'package:crackers_erp/ui/features/masters/views/master_shared_widgets.dart';

class MaterialMasterScreen extends StatefulWidget {
  const MaterialMasterScreen({required this.viewModel, super.key});

  final MaterialMasterViewModel viewModel;

  @override
  State<MaterialMasterScreen> createState() => _MaterialMasterScreenState();
}

class _MaterialMasterScreenState extends State<MaterialMasterScreen> {
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _catCtrl = TextEditingController();
  final _hsnCtrl = TextEditingController();
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
    _hsnCtrl.dispose();
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
    syncMasterController(_hsnCtrl, vm.hsn);
    syncMasterController(_unitQtyCtrl, vm.unitQty);
    syncMasterController(_searchCtrl, vm.searchQuery);
  }

  void _handleEdit(Product m) {
    widget.viewModel.editMaterial(m);
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
        final rows = vm.filteredMaterials;

        return ErpScreenScaffold(
          title: 'Material Master',
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
                          accentColor: ErpTheme.productionAmber,
                          title: 'Material Master',
                          subtitle:
                              'Manage Raw Materials (RM), pricing units, and packing conversions.',
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
                              ? 'Edit Raw Material (${vm.code})'
                              : 'Material Master',
                          accentColor: ErpTheme.productionAmber,
                          trailing: const ErpBadge(
                            label: 'AUTO RM CODE',
                            backgroundColor: ErpTheme.productionAmberSoft,
                            foregroundColor: ErpTheme.productionAmberDark,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ErpResponsiveFormGrid(
                                minItemWidth: 210,
                                children: [
                                  TextField(
                                    controller: _codeCtrl,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    decoration: const InputDecoration(
                                      labelText: 'Material Code *',
                                      hintText: 'e.g. RM001',
                                    ),
                                    onChanged: (v) => vm.updateField(code: v),
                                  ),
                                  TextField(
                                    controller: _nameCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Material Name *',
                                      hintText: 'e.g. Gun Powder',
                                    ),
                                    onChanged: (v) => vm.updateField(name: v),
                                  ),
                                  TextField(
                                    controller: _catCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Category',
                                      hintText: 'e.g. Chemicals, Paper',
                                    ),
                                    onChanged: (v) =>
                                        vm.updateField(category: v),
                                  ),
                                  TextField(
                                    controller: _hsnCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'HSN Code',
                                    ),
                                    onChanged: (v) => vm.updateField(hsn: v),
                                  ),
                                  DropdownButtonFormField<String>(
                                    key: ValueKey('rm_tax_${vm.tax}'),
                                    initialValue: vm.tax,
                                    decoration: const InputDecoration(
                                      labelText: 'Tax (%)',
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: '0.00',
                                        child: Text('0% (Exempt)'),
                                      ),
                                      DropdownMenuItem(
                                        value: '5.00',
                                        child: Text('5%'),
                                      ),
                                      DropdownMenuItem(
                                        value: '12.00',
                                        child: Text('12%'),
                                      ),
                                      DropdownMenuItem(
                                        value: '18.00',
                                        child: Text('18%'),
                                      ),
                                      DropdownMenuItem(
                                        value: '28.00',
                                        child: Text('28%'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) vm.updateField(tax: v);
                                    },
                                  ),
                                  DropdownButtonFormField<String>(
                                    key: ValueKey('rm_unit_${vm.unit}'),
                                    initialValue: const [
                                      'Kg',
                                      'Ton',
                                      'Litre',
                                      'Meters',
                                      'Pcs',
                                    ].contains(vm.unit)
                                        ? vm.unit
                                        : 'Kg',
                                    decoration: const InputDecoration(
                                      labelText: 'Pricing Unit',
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Kg',
                                        child: Text('Kg'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Ton',
                                        child: Text('Ton'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Litre',
                                        child: Text('Litre'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Meters',
                                        child: Text('Meters'),
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
                                  DropdownButtonFormField<String>(
                                    key: ValueKey('rm_punit_${vm.packUnit}'),
                                    initialValue: const [
                                      'Bag',
                                      'Box',
                                      'Drum',
                                      'Roll',
                                      'Bundle',
                                      'Pkt',
                                      'Pcs',
                                    ].contains(vm.packUnit)
                                        ? vm.packUnit
                                        : 'Bag',
                                    decoration: const InputDecoration(
                                      labelText: 'Packing Unit',
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Bag',
                                        child: Text('Bag'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Box',
                                        child: Text('Box'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Drum',
                                        child: Text('Drum'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Roll',
                                        child: Text('Roll'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Bundle',
                                        child: Text('Bundle'),
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
                                      if (v != null) {
                                        vm.updateField(packUnit: v);
                                      }
                                    },
                                  ),
                                  TextField(
                                    controller: _unitQtyCtrl,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Qty per Pack',
                                    ),
                                    onChanged: (v) =>
                                        vm.updateField(unitQty: v),
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
                                          vm.isSaving ? null : vm.saveMaterial,
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            ErpTheme.productionAmberDark,
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
                                      label: const Text('Save Material'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        MasterFormCard(
                          title: 'Raw Materials (${rows.length})',
                          accentColor: ErpTheme.productionAmber,
                          trailing: SizedBox(
                            width: 240,
                            child: TextField(
                              controller: _searchCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Search raw materials...',
                                prefixIcon: Icon(Icons.search, size: 18),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              onChanged: vm.setSearchQuery,
                            ),
                          ),
                          child: rows.isEmpty
                              ? const ErpEmptyState(
                                  icon: Icons.science_outlined,
                                  title: 'No raw materials found',
                                  subtitle:
                                      'Add chemicals, paper, or packaging raw materials above.',
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    if (constraints.maxWidth >= 740) {
                                      return SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            minWidth: 720,
                                          ),
                                          child: DataTable(
                                            headingRowColor:
                                                WidgetStateProperty.all(
                                              ErpTheme.slate50,
                                            ),
                                            columns: const [
                                              DataColumn(label: Text('Code')),
                                              DataColumn(label: Text('Name')),
                                              DataColumn(
                                                label: Text('Category'),
                                              ),
                                              DataColumn(
                                                label: Text('Pricing Unit'),
                                              ),
                                              DataColumn(
                                                label: Text('Pack Info'),
                                              ),
                                              DataColumn(label: Text('Status')),
                                              DataColumn(
                                                label: Text('Actions'),
                                              ),
                                            ],
                                            rows: rows.map((m) {
                                              return DataRow(
                                                cells: [
                                                  DataCell(
                                                    Text(
                                                      m.code,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w900,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      m.name,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(m.category ?? '-'),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      m.unit,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      '${m.unitQty} ${m.unit} / ${m.packUnit ?? 'Pack'}',
                                                    ),
                                                  ),
                                                  DataCell(
                                                    MasterStatusBadge(
                                                      isActive: m.isActive,
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              _handleEdit(m),
                                                          child: const Text(
                                                            'Edit',
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () => vm
                                                              .toggleStatus(m),
                                                          style:
                                                              TextButton.styleFrom(
                                                            foregroundColor:
                                                                m.isActive
                                                                ? ErpTheme
                                                                      .dangerRose
                                                                : ErpTheme
                                                                      .ordersEmerald,
                                                          ),
                                                          child: Text(
                                                            m.isActive
                                                                ? 'Disable'
                                                                : 'Enable',
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
                                      children: rows.map((m) {
                                        return Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: ErpTheme.slate50,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            border: Border.all(
                                              color: ErpTheme.slate200,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    m.code,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: ErpTheme
                                                          .productionAmberDark,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      m.name,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                  MasterStatusBadge(
                                                    isActive: m.isActive,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${m.unitQty} ${m.unit} / ${m.packUnit ?? 'Pack'} • ${m.category ?? '-'}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: ErpTheme.slate500,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  OutlinedButton(
                                                    onPressed: () =>
                                                        _handleEdit(m),
                                                    child: const Text('Edit'),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  OutlinedButton(
                                                    onPressed: () =>
                                                        vm.toggleStatus(m),
                                                    style:
                                                        OutlinedButton.styleFrom(
                                                      foregroundColor:
                                                          m.isActive
                                                          ? ErpTheme.dangerRose
                                                          : ErpTheme
                                                                .ordersEmerald,
                                                    ),
                                                    child: Text(
                                                      m.isActive
                                                          ? 'Disable'
                                                          : 'Enable',
                                                    ),
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

