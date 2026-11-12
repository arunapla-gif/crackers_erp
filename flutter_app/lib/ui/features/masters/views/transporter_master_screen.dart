import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/domain/models/transporter.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/core/erp_crud_widgets.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/features/masters/view_models/transporter_master_view_model.dart';
import 'package:crackers_erp/ui/features/masters/views/master_shared_widgets.dart';

class TransporterMasterScreen extends StatefulWidget {
  const TransporterMasterScreen({required this.viewModel, super.key});

  final TransporterMasterViewModel viewModel;

  @override
  State<TransporterMasterScreen> createState() =>
      _TransporterMasterScreenState();
}

class _TransporterMasterScreenState extends State<TransporterMasterScreen> {
  final _gstinCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
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
    _addressCtrl.dispose();
    _pincodeCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _syncControllers() {
    final vm = widget.viewModel;
    syncMasterController(_gstinCtrl, vm.gstin);
    syncMasterController(_nameCtrl, vm.name);
    syncMasterController(_addressCtrl, vm.address);
    syncMasterController(_pincodeCtrl, vm.pincode);
    syncMasterController(_cityCtrl, vm.city);
    syncMasterController(_districtCtrl, vm.district);
    syncMasterController(_searchCtrl, vm.searchQuery);
  }

  void _handleEdit(Transporter t) {
    widget.viewModel.editTransporter(t);
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
        final rows = vm.filteredTransporters;

        return ErpScreenScaffold(
          title: 'Transporter Master',
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
                          title: 'Transporter Master',
                          subtitle:
                              'Configure GST-registered freight transporters for billing & E-Way Bills.',
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
                              ? 'Edit Transporter Details'
                              : 'Transporter Details Master',
                          accentColor: ErpTheme.salesBlue,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ErpResponsiveFormGrid(
                                minItemWidth: 250,
                                children: [
                                  TextField(
                                    controller: _gstinCtrl,
                                    maxLength: 15,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    decoration: InputDecoration(
                                      labelText: 'GSTIN Lookup *',
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
                                      labelText: 'Transporter Name *',
                                      hintText: 'Transporter name',
                                    ),
                                    onChanged: (v) => vm.updateField(name: v),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _addressCtrl,
                                minLines: 2,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  labelText: 'Full Address',
                                  hintText: 'Transporter full address',
                                ),
                                onChanged: (v) => vm.updateField(address: v),
                              ),
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
                                      onPressed: vm.isSaving
                                          ? null
                                          : vm.saveTransporter,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: ErpTheme.salesBlue,
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
                                      label: const Text('Save Transporter'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        MasterFormCard(
                          title: 'Saved Transporters (${rows.length})',
                          accentColor: ErpTheme.salesBlue,
                          trailing: SizedBox(
                            width: 240,
                            child: TextField(
                              controller: _searchCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Search transporters...',
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
                                  icon: Icons.local_shipping_outlined,
                                  title: 'No transporters found',
                                  subtitle:
                                      'Add a transporter above to select in billing dispatch.',
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    if (constraints.maxWidth >= 720) {
                                      return SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            minWidth: 700,
                                          ),
                                          child: DataTable(
                                            headingRowColor:
                                                WidgetStateProperty.all(
                                              ErpTheme.slate50,
                                            ),
                                            columns: const [
                                              DataColumn(label: Text('GSTIN')),
                                              DataColumn(label: Text('Name')),
                                              DataColumn(label: Text('City')),
                                              DataColumn(
                                                label: Text('District'),
                                              ),
                                              DataColumn(label: Text('Status')),
                                              DataColumn(
                                                label: Text('Actions'),
                                              ),
                                            ],
                                            rows: rows.map((t) {
                                              return DataRow(
                                                cells: [
                                                  DataCell(
                                                    Text(
                                                      t.gstin,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      t.name,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(Text(t.city ?? '-')),
                                                  DataCell(
                                                    Text(t.district ?? '-'),
                                                  ),
                                                  DataCell(
                                                    MasterStatusBadge(
                                                      isActive: t.isActive,
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              _handleEdit(t),
                                                          child: const Text(
                                                            'Edit',
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () => vm
                                                              .toggleStatus(t),
                                                          style:
                                                              TextButton.styleFrom(
                                                            foregroundColor:
                                                                t.isActive
                                                                ? ErpTheme
                                                                      .dangerRose
                                                                : ErpTheme
                                                                      .ordersEmerald,
                                                          ),
                                                          child: Text(
                                                            t.isActive
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
                                      children: rows.map((t) {
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
                                                  Expanded(
                                                    child: Text(
                                                      t.name,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ),
                                                  MasterStatusBadge(
                                                    isActive: t.isActive,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${t.gstin} • ${t.city ?? '-'}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: ErpTheme.slate700,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  OutlinedButton(
                                                    onPressed: () =>
                                                        _handleEdit(t),
                                                    child: const Text('Edit'),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  OutlinedButton(
                                                    onPressed: () =>
                                                        vm.toggleStatus(t),
                                                    style:
                                                        OutlinedButton.styleFrom(
                                                      foregroundColor:
                                                          t.isActive
                                                          ? ErpTheme.dangerRose
                                                          : ErpTheme
                                                                .ordersEmerald,
                                                    ),
                                                    child: Text(
                                                      t.isActive
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

