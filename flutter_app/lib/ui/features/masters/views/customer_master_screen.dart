import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/domain/models/customer.dart';
import 'package:crackers_erp/domain/models/erp_user.dart';
import 'package:crackers_erp/domain/models/sales_order.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/core/erp_crud_widgets.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/core/searchable_picker.dart';
import 'package:crackers_erp/ui/features/masters/view_models/customer_master_view_model.dart';
import 'package:crackers_erp/ui/features/masters/views/master_shared_widgets.dart';

class CustomerMasterScreen extends StatefulWidget {
  const CustomerMasterScreen({
    required this.viewModel,
    this.initialLeadArgs,
    super.key,
  });

  final CustomerMasterViewModel viewModel;
  final VerifyCustomerLeadArgs? initialLeadArgs;

  @override
  State<CustomerMasterScreen> createState() => _CustomerMasterScreenState();
}

class _CustomerMasterScreenState extends State<CustomerMasterScreen> {
  final _gstinCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
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
      if (mounted) {
        widget.viewModel.initialize(leadArgs: widget.initialLeadArgs);
      }
    });
  }

  @override
  void didUpdateWidget(covariant CustomerMasterScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLeadArgs != oldWidget.initialLeadArgs &&
        widget.initialLeadArgs != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.viewModel.beginLeadVerification(widget.initialLeadArgs!);
        }
      });
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_syncControllers);
    _gstinCtrl.dispose();
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _referenceCtrl.dispose();
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
    syncMasterController(_gstinCtrl, vm.isUnregistered ? '' : vm.gstin);
    syncMasterController(_nameCtrl, vm.name);
    syncMasterController(_mobileCtrl, vm.mobile);
    syncMasterController(_referenceCtrl, vm.reference);
    syncMasterController(_addressCtrl, vm.address);
    syncMasterController(_pincodeCtrl, vm.pincode);
    syncMasterController(_cityCtrl, vm.city);
    syncMasterController(_districtCtrl, vm.district);
    syncMasterController(_idCtrl, vm.idNumber);
    syncMasterController(_searchCtrl, vm.searchQuery);
  }

  Future<void> _handleSave() async {
    final wasLeadMode = widget.viewModel.isLeadVerificationMode;
    final ok = await widget.viewModel.saveCustomer();
    if (!mounted || !ok) return;
    if (wasLeadMode) {
      context.go('/pending-orders');
    }
  }

  void _handleEdit(Customer c) {
    widget.viewModel.editCustomer(c);
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
        final rows = vm.filteredCustomers;
        ErpUser? selectedRep;
        if (vm.repId != null) {
          for (final r in vm.reps) {
            if (r.id == vm.repId) {
              selectedRep = r;
              break;
            }
          }
        }

        return ErpScreenScaffold(
          title: 'Customer Master',
          body: RefreshIndicator(
            onRefresh: () => vm.initialize(),
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
                          title: 'Customer Master',
                          subtitle:
                              'Manage GST registered & URP customers, GSTIN auto-lookup, and Sales Rep assignment.',
                          actions: [
                            OutlinedButton.icon(
                              onPressed: vm.isLoading
                                  ? null
                                  : () => vm.initialize(),
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
                              ? 'Edit Customer Details'
                              : 'Customer Details Master',
                          accentColor: ErpTheme.salesBlue,
                          trailing: vm.isLeadVerificationMode
                              ? ErpBadge(
                                  label:
                                      'LEAD VERIFICATION #${vm.pendingOrderId ?? ''}',
                                  backgroundColor: ErpTheme.salesBlueSoft,
                                  foregroundColor: ErpTheme.salesBlueDark,
                                )
                              : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ErpResponsiveFormGrid(
                                minItemWidth: 230,
                                children: [
                                  DropdownButtonFormField<bool>(
                                    key: ValueKey('reg_${vm.isUnregistered}'),
                                    initialValue: vm.isUnregistered,
                                    decoration: const InputDecoration(
                                      labelText: 'GST Reg. Type',
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: false,
                                        child: Text('Registered (GSTIN)'),
                                      ),
                                      DropdownMenuItem(
                                        value: true,
                                        child: Text('Unregistered (URP)'),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        vm.setRegistrationType(val);
                                      }
                                    },
                                  ),
                                  TextField(
                                    controller: _gstinCtrl,
                                    enabled: !vm.isUnregistered,
                                    maxLength: 15,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    decoration: InputDecoration(
                                      labelText: 'GSTIN Lookup',
                                      counterText: '',
                                      hintText: vm.isUnregistered
                                          ? 'URP Defaulted'
                                          : '15-char GSTIN',
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
                                      labelText: 'Customer / Business Name *',
                                      hintText: 'Customer name',
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
                                  SearchablePickerField<ErpUser>(
                                    label: 'Sales Rep Assignment',
                                    value: selectedRep,
                                    displayText: selectedRep?.username ?? '',
                                    hintText: '-- No Rep Assigned --',
                                    options: vm.reps
                                        .map(
                                          (r) => SearchablePickerOption(
                                            value: r,
                                            label: r.username,
                                          ),
                                        )
                                        .toList(),
                                    onSelected: (r) =>
                                        vm.updateField(repId: r.id),
                                    onClear: vm.repId == null
                                        ? null
                                        : () => vm.updateField(clearRep: true),
                                  ),
                                  TextField(
                                    controller: _referenceCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Reference / Notes',
                                      hintText: 'Other reference',
                                    ),
                                    onChanged: (v) =>
                                        vm.updateField(reference: v),
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
                                  hintText: 'Full customer address',
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
                                      hintText: 'Optional ID number',
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
                                      onPressed: vm.isSaving
                                          ? null
                                          : () => vm.clearForm(),
                                      child: const Text('Clear'),
                                    ),
                                    FilledButton.icon(
                                      onPressed: vm.isSaving
                                          ? null
                                          : _handleSave,
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
                                      label: Text(
                                        vm.isLeadVerificationMode
                                            ? 'Save & Approve Lead'
                                            : 'Save Customer',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        MasterFormCard(
                          title: 'Saved Customers (${rows.length})',
                          accentColor: ErpTheme.salesBlue,
                          trailing: SizedBox(
                            width: 240,
                            child: TextField(
                              controller: _searchCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Search customers...',
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
                          child: vm.isLoading && vm.customers.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : rows.isEmpty
                              ? const ErpEmptyState(
                                  icon: Icons.people_outline_rounded,
                                  title: 'No customers found',
                                  subtitle:
                                      'Add a customer above or adjust your search filter.',
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    if (constraints.maxWidth >= 780) {
                                      return _CustomerDesktopTable(
                                        customers: rows,
                                        repNameFor: vm.repNameFor,
                                        onEdit: _handleEdit,
                                        onToggleStatus: vm.toggleStatus,
                                      );
                                    }
                                    return Column(
                                      children: rows
                                          .map(
                                            (c) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 10,
                                              ),
                                              child: _CustomerMobileCard(
                                                customer: c,
                                                repName: vm.repNameFor(c),
                                                onEdit: () => _handleEdit(c),
                                                onToggleStatus: () =>
                                                    vm.toggleStatus(c),
                                              ),
                                            ),
                                          )
                                          .toList(),
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

class _CustomerDesktopTable extends StatelessWidget {
  const _CustomerDesktopTable({
    required this.customers,
    required this.repNameFor,
    required this.onEdit,
    required this.onToggleStatus,
  });

  final List<Customer> customers;
  final String Function(Customer) repNameFor;
  final ValueChanged<Customer> onEdit;
  final ValueChanged<Customer> onToggleStatus;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 760),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(ErpTheme.slate50),
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Mobile')),
            DataColumn(label: Text('City / District')),
            DataColumn(label: Text('Sales Rep')),
            DataColumn(label: Text('GSTIN')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: customers.map((c) {
            final cityDist = [
              c.city ?? '',
              c.district ?? '',
            ].where((s) => s.trim().isNotEmpty).join(', ');
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    c.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                DataCell(Text(c.mobile ?? '-')),
                DataCell(Text(cityDist.isEmpty ? '-' : cityDist)),
                DataCell(Text(repNameFor(c))),
                DataCell(Text((c.gstin ?? '-').toUpperCase())),
                DataCell(MasterStatusBadge(isActive: c.isActive)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => onEdit(c),
                        child: const Text('Edit'),
                      ),
                      TextButton(
                        onPressed: () => onToggleStatus(c),
                        style: TextButton.styleFrom(
                          foregroundColor: c.isActive
                              ? ErpTheme.dangerRose
                              : ErpTheme.ordersEmerald,
                        ),
                        child: Text(c.isActive ? 'Disable' : 'Enable'),
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
}

class _CustomerMobileCard extends StatelessWidget {
  const _CustomerMobileCard({
    required this.customer,
    required this.repName,
    required this.onEdit,
    required this.onToggleStatus,
  });

  final Customer customer;
  final String repName;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  customer.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: ErpTheme.slate900,
                  ),
                ),
              ),
              MasterStatusBadge(isActive: customer.isActive),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [
              if ((customer.mobile ?? '').isNotEmpty) customer.mobile!,
              if ((customer.city ?? '').isNotEmpty) customer.city!,
              if ((customer.gstin ?? '').isNotEmpty)
                customer.gstin!.toUpperCase(),
            ].join(' • '),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ErpTheme.slate700,
            ),
          ),
          if (repName != '-') ...[
            const SizedBox(height: 4),
            Text(
              'Rep: $repName',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: ErpTheme.salesBlueDark,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(onPressed: onEdit, child: const Text('Edit')),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onToggleStatus,
                style: OutlinedButton.styleFrom(
                  foregroundColor: customer.isActive
                      ? ErpTheme.dangerRose
                      : ErpTheme.ordersEmerald,
                ),
                child: Text(customer.isActive ? 'Disable' : 'Enable'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

