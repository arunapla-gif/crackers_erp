import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/domain/models/vehicle.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/core/erp_crud_widgets.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/features/masters/view_models/vehicle_master_view_model.dart';
import 'package:crackers_erp/ui/features/masters/views/master_shared_widgets.dart';

class VehicleMasterScreen extends StatefulWidget {
  const VehicleMasterScreen({required this.viewModel, super.key});

  final VehicleMasterViewModel viewModel;

  @override
  State<VehicleMasterScreen> createState() => _VehicleMasterScreenState();
}

class _VehicleMasterScreenState extends State<VehicleMasterScreen> {
  final _noCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _ownerPhoneCtrl = TextEditingController();
  final _driverNameCtrl = TextEditingController();
  final _driverPhoneCtrl = TextEditingController();
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
    _noCtrl.dispose();
    _nameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _ownerPhoneCtrl.dispose();
    _driverNameCtrl.dispose();
    _driverPhoneCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _syncControllers() {
    final vm = widget.viewModel;
    syncMasterController(_noCtrl, vm.no);
    syncMasterController(_nameCtrl, vm.name);
    syncMasterController(_ownerNameCtrl, vm.ownerName);
    syncMasterController(_ownerPhoneCtrl, vm.ownerPhone);
    syncMasterController(_driverNameCtrl, vm.driverDraftName);
    syncMasterController(_driverPhoneCtrl, vm.driverDraftPhone);
  }

  void _handleEdit(Vehicle v) {
    widget.viewModel.editVehicle(v);
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
          title: 'Vehicle Master',
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
                          accentColor: ErpTheme.godownTeal,
                          title: 'Vehicle Master',
                          subtitle:
                              'Create vehicles and attach drivers used for stock transfers between godowns.',
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
                              ? 'Edit Vehicle Details'
                              : 'Vehicle Master',
                          accentColor: ErpTheme.godownTeal,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ErpResponsiveFormGrid(
                                minItemWidth: 210,
                                children: [
                                  TextField(
                                    controller: _noCtrl,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    decoration: const InputDecoration(
                                      labelText: 'Vehicle Number *',
                                      hintText: 'TN67AB1234',
                                    ),
                                    onChanged: (v) => vm.updateField(no: v),
                                  ),
                                  TextField(
                                    controller: _nameCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Vehicle Name',
                                      hintText: 'Mini Truck / Van',
                                    ),
                                    onChanged: (v) => vm.updateField(name: v),
                                  ),
                                  TextField(
                                    controller: _ownerNameCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Owner Name',
                                      hintText: 'Owner name',
                                    ),
                                    onChanged: (v) =>
                                        vm.updateField(ownerName: v),
                                  ),
                                  TextField(
                                    controller: _ownerPhoneCtrl,
                                    keyboardType: TextInputType.phone,
                                    maxLength: 10,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Owner Phone',
                                      counterText: '',
                                      hintText: '10 digit phone',
                                    ),
                                    onChanged: (v) =>
                                        vm.updateField(ownerPhone: v),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 10),
                              const Text(
                                'Attach Drivers to this Vehicle',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: ErpTheme.slate500,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ErpResponsiveFormGrid(
                                minItemWidth: 200,
                                children: [
                                  TextField(
                                    controller: _driverNameCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Driver Name',
                                      hintText: 'Driver Name',
                                    ),
                                    onChanged: (v) =>
                                        vm.updateField(driverDraftName: v),
                                  ),
                                  TextField(
                                    controller: _driverPhoneCtrl,
                                    keyboardType: TextInputType.phone,
                                    maxLength: 10,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Driver Phone',
                                      counterText: '',
                                      hintText: 'Driver Phone',
                                    ),
                                    onChanged: (v) =>
                                        vm.updateField(driverDraftPhone: v),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomLeft,
                                    child: FilledButton.icon(
                                      onPressed: vm.addDriver,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: ErpTheme.slate800,
                                      ),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add Driver'),
                                    ),
                                  ),
                                ],
                              ),
                              if (vm.drivers.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: List.generate(vm.drivers.length, (
                                    i,
                                  ) {
                                    final d = vm.drivers[i];
                                    return InputChip(
                                      label: Text(
                                        d.phone.isEmpty
                                            ? d.name
                                            : '${d.name} (${d.phone})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                      onDeleted: () => vm.removeDriver(i),
                                    );
                                  }),
                                ),
                              ],
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  if (vm.editingId != null) ...[
                                    OutlinedButton(
                                      onPressed:
                                          vm.isSaving ? null : vm.clearForm,
                                      child: const Text('Clear'),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed:
                                          vm.isSaving ? null : vm.saveVehicle,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: ErpTheme.godownTeal,
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
                                      label: const Text('SAVE VEHICLE'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        MasterFormCard(
                          title: 'Saved Vehicles (${vm.vehicles.length})',
                          accentColor: ErpTheme.godownTeal,
                          child: vm.vehicles.isEmpty
                              ? const ErpEmptyState(
                                  icon: Icons.directions_car_outlined,
                                  title: 'No vehicles added yet',
                                  subtitle:
                                      'Add a vehicle above to assign drivers and track transfers.',
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    if (constraints.maxWidth >= 700) {
                                      return SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            minWidth: 680,
                                          ),
                                          child: DataTable(
                                            headingRowColor:
                                                WidgetStateProperty.all(
                                              ErpTheme.slate50,
                                            ),
                                            columns: const [
                                              DataColumn(
                                                label: Text('Vehicle No'),
                                              ),
                                              DataColumn(label: Text('Name')),
                                              DataColumn(label: Text('Owner')),
                                              DataColumn(
                                                label: Text('Drivers'),
                                              ),
                                              DataColumn(label: Text('Action')),
                                            ],
                                            rows: vm.vehicles.map((v) {
                                              final driversText =
                                                  v.drivers.isEmpty
                                                  ? '-'
                                                  : v.drivers
                                                        .map(
                                                          (d) => d.phone.isEmpty
                                                              ? d.name
                                                              : '${d.name} (${d.phone})',
                                                        )
                                                        .join(', ');
                                              return DataRow(
                                                cells: [
                                                  DataCell(
                                                    Text(
                                                      v.no,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color: ErpTheme
                                                            .godownTealDark,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(v.name ?? '-'),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      [
                                                        v.ownerName ?? '',
                                                        v.ownerPhone ?? '',
                                                      ]
                                                          .where(
                                                            (s) => s.isNotEmpty,
                                                          )
                                                          .join(' • '),
                                                    ),
                                                  ),
                                                  DataCell(Text(driversText)),
                                                  DataCell(
                                                    OutlinedButton(
                                                      onPressed: () =>
                                                          _handleEdit(v),
                                                      child: const Text('Edit'),
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
                                      children: vm.vehicles.map((v) {
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
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      v.no,
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color: ErpTheme
                                                            .godownTealDark,
                                                      ),
                                                    ),
                                                    if ((v.name ?? '')
                                                        .isNotEmpty)
                                                      Text(
                                                        v.name!,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    if (v.drivers.isNotEmpty)
                                                      Text(
                                                        'Drivers: ${v.drivers.map((d) => d.name).join(', ')}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: ErpTheme
                                                              .slate500,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              OutlinedButton(
                                                onPressed: () => _handleEdit(v),
                                                child: const Text('Edit'),
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

