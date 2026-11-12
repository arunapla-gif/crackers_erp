import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:crackers_erp/core/constants/indian_states.dart';
import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/core/utils/inr_formatter.dart';
import 'package:crackers_erp/domain/models/billing.dart';
import 'package:crackers_erp/domain/models/company_profile.dart';
import 'package:crackers_erp/domain/models/customer.dart';
import 'package:crackers_erp/domain/models/product.dart';
import 'package:crackers_erp/domain/models/transporter.dart';
import 'package:crackers_erp/domain/models/vehicle.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/core/erp_crud_widgets.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/core/searchable_picker.dart';
import 'package:crackers_erp/ui/features/sales/view_models/billing_view_model.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({
    required this.viewModel,
    this.onNavigateToPrint,
    super.key,
  });

  final BillingViewModel viewModel;
  final void Function(String invoiceNumber)? onNavigateToPrint;

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final TextEditingController _dateCtrl = TextEditingController();
  final TextEditingController _numberCtrl = TextEditingController();
  final TextEditingController _custAddressCtrl = TextEditingController();
  final TextEditingController _vehicleCtrl = TextEditingController();
  final TextEditingController _distanceCtrl = TextEditingController();
  final TextEditingController _ewayCtrl = TextEditingController();

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
    _dateCtrl.dispose();
    _numberCtrl.dispose();
    _custAddressCtrl.dispose();
    _vehicleCtrl.dispose();
    _distanceCtrl.dispose();
    _ewayCtrl.dispose();
    super.dispose();
  }

  void _syncCtrl(TextEditingController ctrl, String value) {
    if (ctrl.text != value) {
      ctrl.value = ctrl.value.copyWith(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  void _syncControllers() {
    final h = widget.viewModel.header;
    _syncCtrl(_dateCtrl, h.date);
    _syncCtrl(_numberCtrl, h.number);
    _syncCtrl(_custAddressCtrl, h.customerAddress);
    _syncCtrl(_vehicleCtrl, h.vehicleNo);
    _syncCtrl(_distanceCtrl, h.distance);
    _syncCtrl(_ewayCtrl, h.ewayBillNo);
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_dateCtrl.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && mounted) {
      final iso =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      widget.viewModel.updateHeader(date: iso);
    }
  }

  Future<void> _handleSave({bool openPrint = false}) async {
    final savedNo = await widget.viewModel.saveDocument();
    if (!mounted || savedNo == null) return;
    if (openPrint) {
      if (widget.onNavigateToPrint != null) {
        widget.onNavigateToPrint!(savedNo);
      } else {
        unawaited(context.push('/print/invoice/${Uri.encodeComponent(savedNo)}'));
      }
    }
  }

  Future<void> _handleClearDraft() async {
    final confirmed = await showErpConfirmDialog(
      context: context,
      title: 'Clear Billing Draft?',
      message:
          'All unsaved line items, charges, and party details in this draft will be cleared.',
      confirmLabel: 'Clear Draft',
      destructive: true,
    );
    if (confirmed && mounted) {
      await widget.viewModel.clearDraft();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final docMeta = BillingDocType.fromCode(vm.docType);

        if (vm.isGatewayOpen) {
          return ErpScreenScaffold(
            title: 'Select Billing Company',
            body: _CompanyGatewayView(
              docTypeLabel: docMeta.title,
              profiles: vm.profiles,
              canCancel: vm.header.companyProfileId != null,
              onSelect: vm.selectGatewayProfile,
              onCancel: vm.closeGateway,
            ),
          );
        }

        final headerCards = LayoutBuilder(
          builder: (context, c) {
            final width = c.maxWidth;
            final cols = width >= 960 ? 3 : (width >= 620 ? 2 : 1);
            const spacing = 14.0;
            final cardW =
                cols == 1 ? width : (width - spacing * (cols - 1)) / cols;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                SizedBox(width: cardW, child: _buildPartyCard(vm)),
                SizedBox(width: cardW, child: _buildDocumentCard(vm)),
                SizedBox(width: cardW, child: _buildLogisticsCard(vm)),
              ],
            );
          },
        );

        final leftColumn = Column(
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
            headerCards,
            const SizedBox(height: 16),
            _buildItemsCard(vm),
            const SizedBox(height: 16),
            _buildChargesCard(vm),
          ],
        );

        final totalsCard = _BillingTotalsCard(
          vm: vm,
          onSaveOnly: () => _handleSave(openPrint: false),
          onSaveAndPrint: () => _handleSave(openPrint: true),
        );

        return ErpScreenScaffold(
          title: '${docMeta.title} • ${vm.header.series}${vm.header.number}',
          body: vm.isLoading && vm.products.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth >= 1080) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 8, child: leftColumn),
                                const SizedBox(width: 18),
                                SizedBox(width: 340, child: totalsCard),
                              ],
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              leftColumn,
                              const SizedBox(height: 18),
                              totalsCard,
                              const SizedBox(height: 24),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildPartyCard(BillingViewModel vm) {
    final stateOptions = indianStatesAndUts.contains(vm.billState)
        ? indianStatesAndUts
        : [vm.billState, ...indianStatesAndUts];
    final selectedProf = vm.selectedProfile;
    final selectedCust = vm.selectedCustomer;

    return _SectionCard(
      title: 'Party Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchablePickerField<CompanyProfile>(
            label: 'Billing Branch',
            hintText: 'Select Branch...',
            displayText: selectedProf != null
                ? '${selectedProf.name} - ${selectedProf.gstin}'
                : vm.header.companyProfileName,
            value: selectedProf,
            options: vm.profiles
                .map(
                  (p) => SearchablePickerOption<CompanyProfile>(
                    value: p,
                    label: '${p.name} - ${p.gstin}',
                    subtitle: '${p.city ?? ''}, ${p.state}',
                  ),
                )
                .toList(),
            onSelected: vm.selectGatewayProfile,
            onClear: selectedProf == null
                ? null
                : () => vm.selectGatewayProfile(null),
          ),
          const SizedBox(height: 12),
          SearchablePickerField<Customer>(
            label: 'Customer',
            hintText: 'Search Customer...',
            displayText: selectedCust?.name ?? vm.header.customer,
            value: selectedCust,
            options: vm.customers
                .map(
                  (c) => SearchablePickerOption<Customer>(
                    value: c,
                    label: c.name,
                    subtitle: [
                      if ((c.city ?? '').isNotEmpty) c.city!,
                      if ((c.gstin ?? '').isNotEmpty) c.gstin!,
                    ].join(' • '),
                  ),
                )
                .toList(),
            onSelected: (Customer c) => unawaited(vm.selectCustomer(c)),
            onClear: vm.header.customer.isEmpty
                ? null
                : () => unawaited(vm.selectCustomer(null)),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: vm.billState,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'State of Supply'),
            items: stateOptions
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) {
              if (v != null) vm.setBillState(v);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _custAddressCtrl,
            maxLines: 2,
            onChanged: (v) => vm.updateHeader(customerAddress: v),
            decoration: const InputDecoration(
              labelText: 'Billing Address',
              hintText: 'Auto-filled from Customer Master',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(BillingViewModel vm) {
    final seriesList = vm.availableSeries;
    final hasSeries = seriesList.any((s) => s.prefix == vm.header.series);

    return _SectionCard(
      title: 'Document Info',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'INV', label: Text('INV')),
              ButtonSegment(value: 'EST', label: Text('EST')),
              ButtonSegment(value: 'PRO', label: Text('PRO')),
            ],
            selected: {vm.docType},
            onSelectionChanged: (sel) {
              if (sel.isNotEmpty) vm.setDocType(sel.first);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dateCtrl,
            readOnly: true,
            onTap: _pickDate,
            decoration: const InputDecoration(
              labelText: 'Date',
              suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: DropdownButtonFormField<String>(
                  initialValue: hasSeries ? vm.header.series : '',
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Series'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('-')),
                    ...seriesList.map(
                      (s) => DropdownMenuItem(
                        value: s.prefix,
                        child: Text(s.prefix),
                      ),
                    ),
                  ],
                  onChanged: (v) => vm.updateHeader(series: v ?? ''),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 6,
                child: TextField(
                  controller: _numberCtrl,
                  onChanged: (v) => vm.updateHeader(number: v),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                  decoration: const InputDecoration(labelText: 'Doc No *'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (vm.profiles.length > 1)
                TextButton.icon(
                  onPressed: vm.openGateway,
                  icon: const Icon(Icons.apartment_rounded, size: 16),
                  label: const Text('Switch Branch'),
                )
              else
                const SizedBox.shrink(),
              TextButton.icon(
                onPressed: _handleClearDraft,
                style: TextButton.styleFrom(
                  foregroundColor: ErpTheme.dangerRose,
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Clear Draft'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogisticsCard(BillingViewModel vm) {
    Transporter? selectedTransporter;
    for (final t in vm.transporters) {
      if (t.gstin == vm.header.transporterId) {
        selectedTransporter = t;
        break;
      }
    }

    return _SectionCard(
      title: 'Logistics & E-Way Bill',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                flex: 6,
                child: TextField(
                  controller: _vehicleCtrl,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (v) =>
                      vm.updateHeader(vehicleNo: v.toUpperCase()),
                  decoration: InputDecoration(
                    labelText: 'Vehicle No',
                    hintText: 'TN-67-XX-0000',
                    suffixIcon: vm.vehicles.isNotEmpty
                        ? IconButton(
                            tooltip: 'Pick Vehicle',
                            icon: const Icon(
                              Icons.local_shipping_outlined,
                              size: 18,
                            ),
                            onPressed: () async {
                              final picked =
                                  await showSearchablePickerSheet<Vehicle>(
                                context: context,
                                title: 'Select Vehicle',
                                options: vm.vehicles
                                    .map(
                                      (v) => SearchablePickerOption<Vehicle>(
                                        value: v,
                                        label: v.no,
                                        subtitle: v.name,
                                      ),
                                    )
                                    .toList(),
                              );
                              if (picked != null && mounted) {
                                vm.updateHeader(vehicleNo: picked.no);
                              }
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _distanceCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => vm.updateHeader(distance: v),
                  decoration: const InputDecoration(
                    labelText: 'Dist (Km)',
                    hintText: '0',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SearchablePickerField<Transporter>(
            label: 'Transporter',
            hintText: 'Select Transporter...',
            displayText: selectedTransporter != null
                ? '${selectedTransporter.name} (${selectedTransporter.gstin})'
                : vm.header.transporterId,
            value: selectedTransporter,
            options: vm.transporters
                .map(
                  (t) => SearchablePickerOption<Transporter>(
                    value: t,
                    label: '${t.name} (${t.gstin})',
                    subtitle: [
                      if ((t.city ?? '').isNotEmpty) t.city!,
                      if ((t.state ?? '').isNotEmpty) t.state!,
                    ].join(', '),
                  ),
                )
                .toList(),
            onSelected: (Transporter t) =>
                vm.updateHeader(transporterId: t.gstin),
            onClear: vm.header.transporterId.isEmpty
                ? null
                : () => vm.updateHeader(transporterId: ''),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ewayCtrl,
            maxLength: 12,
            onChanged: (v) => vm.updateHeader(ewayBillNo: v),
            style: const TextStyle(fontWeight: FontWeight.w800),
            decoration: const InputDecoration(
              labelText: 'E-Way Bill No',
              hintText: '12-digit EWB No',
              counterText: '',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: vm.isGeneratingEway
                      ? null
                      : () => vm.generateEwayBill('PART_A'),
                  child: const Text('Part A EWB'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: vm.isGeneratingEway
                      ? null
                      : () => vm.generateEwayBill('FULL'),
                  style: FilledButton.styleFrom(
                    backgroundColor: ErpTheme.salesBlue,
                  ),
                  child: const Text('Full EWB'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(BillingViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ErpTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'PRODUCTS / ITEMS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: ErpTheme.slate700,
                ),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: vm.addRow,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Row'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final entry in vm.rows.asMap().entries) ...[
            _BillingItemRowWidget(
              key: ValueKey('bill_row_${entry.value.id}'),
              index: entry.key,
              row: entry.value,
              products: vm.products,
              showTaxPct: vm.docType == 'INV',
              onSelectProduct: (p) => vm.selectProductForRow(entry.value.id, p),
              onUpdate: ({product, hsn, qty, rate, tax}) => vm.updateRow(
                entry.value.id,
                product: product,
                hsn: hsn,
                qty: qty,
                rate: rate,
                tax: tax,
              ),
              onAddBelow: vm.addRow,
              onRemove: () => vm.removeRow(entry.value.id),
            ),
            if (entry.key < vm.rows.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildChargesCard(BillingViewModel vm) {
    if (vm.docType == 'INV') {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: ErpTheme.slate200),
        ),
        child: const Column(
          children: [
            Icon(Icons.lock_outline_rounded, color: ErpTheme.slate400, size: 28),
            SizedBox(height: 6),
            Text(
              'TAX DOCUMENT LOCKED',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: ErpTheme.slate500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Estimates and Performa invoices support custom additional charges & past invoice tax lookup.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: ErpTheme.slate500),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ErpTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'ADDITIONAL CHARGES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: ErpTheme.salesBlue,
                ),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: vm.addChargeRow,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Charge'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final entry in vm.chargeRows.asMap().entries) ...[
            _BillingChargeRowWidget(
              key: ValueKey('charge_row_${entry.value.id}'),
              index: entry.key,
              row: entry.value,
              seriesOptions: vm.availableSeries.map((s) => s.prefix).toList(),
              onUpdate: ({name, mode, type, value, series, number}) =>
                  vm.updateChargeRow(
                    entry.value.id,
                    name: name,
                    mode: mode,
                    type: type,
                    value: value,
                    series: series,
                    number: number,
                  ),
              onFetchPastTax: () =>
                  vm.fetchInvoiceTaxForChargeRow(entry.value.id),
              onRemove: () => vm.removeChargeRow(entry.value.id),
            ),
            if (entry.key < vm.chargeRows.length - 1)
              const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ErpTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
              color: ErpTheme.slate500,
            ),
          ),
          const Divider(height: 18, color: ErpTheme.slate100),
          child,
        ],
      ),
    );
  }
}

class _CompanyGatewayView extends StatelessWidget {
  const _CompanyGatewayView({
    required this.docTypeLabel,
    required this.profiles,
    required this.canCancel,
    required this.onSelect,
    required this.onCancel,
  });

  final String docTypeLabel;
  final List<CompanyProfile> profiles;
  final bool canCancel;
  final void Function(CompanyProfile profile) onSelect;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: ErpTheme.salesBlueSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      Icons.apartment_rounded,
                      color: ErpTheme.salesBlue,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Select Billing Company',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: ErpTheme.slate900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Which company profile are you generating this $docTypeLabel from?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ErpTheme.slate500,
                    ),
                  ),
                  const SizedBox(height: 22),
                  LayoutBuilder(
                    builder: (context, c) {
                      final cols = c.maxWidth >= 560 ? 2 : 1;
                      final cardW =
                          cols == 1 ? c.maxWidth : (c.maxWidth - 14) / 2;
                      return Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: profiles.map((p) {
                          return SizedBox(
                            width: cardW,
                            child: OutlinedButton(
                              onPressed: () => onSelect(p),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.all(18),
                                alignment: Alignment.centerLeft,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                side: const BorderSide(
                                  color: ErpTheme.slate200,
                                  width: 1.5,
                                ),
                                backgroundColor: Colors.white,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: ErpTheme.slate900,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ErpBadge(
                                    label: 'GSTIN: ${p.gstin}',
                                    backgroundColor: ErpTheme.slate100,
                                    foregroundColor: ErpTheme.slate700,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    p.fullDispatchAddress,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: ErpTheme.slate500,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (p.billingSeries.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Default Series: ${p.billingSeries.first.prefix}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: ErpTheme.salesBlue,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  if (canCancel) ...[
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: onCancel,
                      child: const Text('Cancel & return to draft'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BillingItemRowWidget extends StatefulWidget {
  const _BillingItemRowWidget({
    required this.index,
    required this.row,
    required this.products,
    required this.showTaxPct,
    required this.onSelectProduct,
    required this.onUpdate,
    required this.onAddBelow,
    required this.onRemove,
    super.key,
  });

  final int index;
  final BillingRow row;
  final List<Product> products;
  final bool showTaxPct;
  final void Function(Product product) onSelectProduct;
  final void Function({
    String? product,
    String? hsn,
    int? qty,
    double? rate,
    double? tax,
  })
  onUpdate;
  final VoidCallback onAddBelow;
  final VoidCallback onRemove;

  @override
  State<_BillingItemRowWidget> createState() => _BillingItemRowWidgetState();
}

class _BillingItemRowWidgetState extends State<_BillingItemRowWidget> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _hsnCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _rateCtrl;
  late final TextEditingController _taxCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.row.product);
    _hsnCtrl = TextEditingController(text: widget.row.hsn);
    _qtyCtrl = TextEditingController(text: '${widget.row.qty}');
    _rateCtrl = TextEditingController(
      text: widget.row.rate == 0 ? '' : _fmtNum(widget.row.rate),
    );
    _taxCtrl = TextEditingController(text: _fmtNum(widget.row.tax));
  }

  String _fmtNum(double v) =>
      v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(2);

  void _syncIfExternal(TextEditingController c, String val) {
    if (c.text != val) {
      c.value = c.value.copyWith(
        text: val,
        selection: TextSelection.collapsed(offset: val.length),
      );
    }
  }

  @override
  void didUpdateWidget(covariant _BillingItemRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.row.product != widget.row.product) {
      _syncIfExternal(_nameCtrl, widget.row.product);
    }
    if (oldWidget.row.hsn != widget.row.hsn) {
      _syncIfExternal(_hsnCtrl, widget.row.hsn);
    }
    if (oldWidget.row.qty != widget.row.qty &&
        (int.tryParse(_qtyCtrl.text) ?? 0) != widget.row.qty) {
      _syncIfExternal(_qtyCtrl, '${widget.row.qty}');
    }
    if (oldWidget.row.rate != widget.row.rate &&
        (double.tryParse(_rateCtrl.text) ?? 0) != widget.row.rate) {
      _syncIfExternal(
        _rateCtrl,
        widget.row.rate == 0 ? '' : _fmtNum(widget.row.rate),
      );
    }
    if (oldWidget.row.tax != widget.row.tax &&
        (double.tryParse(_taxCtrl.text) ?? 0) != widget.row.tax) {
      _syncIfExternal(_taxCtrl, _fmtNum(widget.row.tax));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hsnCtrl.dispose();
    _qtyCtrl.dispose();
    _rateCtrl.dispose();
    _taxCtrl.dispose();
    super.dispose();
  }

  Future<void> _openProductPicker() async {
    final picked = await showSearchablePickerSheet<Product>(
      context: context,
      title: 'Select Product (Row #${widget.index + 1})',
      options: widget.products
          .map(
            (p) => SearchablePickerOption<Product>(
              value: p,
              label: '${p.code} — ${p.name}',
              subtitle:
                  '${p.type} • HSN ${p.hsn} • ₹${p.rate.toStringAsFixed(2)}',
            ),
          )
          .toList(),
    );
    if (picked != null && mounted) {
      widget.onSelectProduct(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ErpTheme.slate50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ErpTheme.slate200),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 860;
          final pickerButton = OutlinedButton.icon(
            onPressed: _openProductPicker,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              backgroundColor: Colors.white,
            ),
            icon: const Icon(Icons.search_rounded, size: 16),
            label: Text(
              widget.row.productId != null ? 'Change Code' : 'Pick Product',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          );

          final rowActions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Add Row',
                onPressed: widget.onAddBelow,
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: ErpTheme.salesBlue,
                ),
              ),
              IconButton(
                tooltip: 'Remove Row',
                onPressed: widget.onRemove,
                icon: const Icon(
                  Icons.remove_circle_outline_rounded,
                  color: ErpTheme.dangerRose,
                ),
              ),
            ],
          );

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    '${widget.index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: ErpTheme.slate500,
                    ),
                  ),
                ),
                pickerButton,
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _nameCtrl,
                    onChanged: (v) => widget.onUpdate(product: v),
                    decoration: const InputDecoration(
                      labelText: 'Product Description',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 82,
                  child: TextField(
                    controller: _hsnCtrl,
                    onChanged: (v) => widget.onUpdate(hsn: v),
                    decoration: const InputDecoration(labelText: 'HSN'),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 74,
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        widget.onUpdate(qty: int.tryParse(v) ?? 0),
                    decoration: const InputDecoration(labelText: 'Qty'),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 92,
                  child: TextField(
                    controller: _rateCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (v) =>
                        widget.onUpdate(rate: double.tryParse(v) ?? 0),
                    decoration: const InputDecoration(labelText: 'Rate'),
                  ),
                ),
                if (widget.showTaxPct) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 68,
                    child: TextField(
                      controller: _taxCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (v) =>
                          widget.onUpdate(tax: double.tryParse(v) ?? 0),
                      decoration: const InputDecoration(labelText: 'GST %'),
                    ),
                  ),
                ],
                const SizedBox(width: 10),
                SizedBox(
                  width: 96,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Amount',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: ErpTheme.slate500,
                        ),
                      ),
                      Text(
                        formatInr(widget.row.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: ErpTheme.slate900,
                        ),
                      ),
                    ],
                  ),
                ),
                rowActions,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'ITEM #${widget.index + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: ErpTheme.slate500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  pickerButton,
                  const Spacer(),
                  rowActions,
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                onChanged: (v) => widget.onUpdate(product: v),
                decoration: const InputDecoration(
                  labelText: 'Product Description',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _qtyCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (v) =>
                          widget.onUpdate(qty: int.tryParse(v) ?? 0),
                      decoration: const InputDecoration(labelText: 'Qty'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _rateCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (v) =>
                          widget.onUpdate(rate: double.tryParse(v) ?? 0),
                      decoration: const InputDecoration(labelText: 'Rate'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _hsnCtrl,
                      onChanged: (v) => widget.onUpdate(hsn: v),
                      decoration: const InputDecoration(labelText: 'HSN'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.showTaxPct)
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _taxCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (v) =>
                            widget.onUpdate(tax: double.tryParse(v) ?? 0),
                        decoration: const InputDecoration(labelText: 'GST %'),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Text(
                    'Amount: ${formatInr(widget.row.amount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: ErpTheme.slate900,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BillingChargeRowWidget extends StatefulWidget {
  const _BillingChargeRowWidget({
    required this.index,
    required this.row,
    required this.seriesOptions,
    required this.onUpdate,
    required this.onFetchPastTax,
    required this.onRemove,
    super.key,
  });

  final int index;
  final AdditionalChargeRow row;
  final List<String> seriesOptions;
  final void Function({
    String? name,
    String? mode,
    String? type,
    double? value,
    String? series,
    String? number,
  })
  onUpdate;
  final VoidCallback onFetchPastTax;
  final VoidCallback onRemove;

  @override
  State<_BillingChargeRowWidget> createState() =>
      _BillingChargeRowWidgetState();
}

class _BillingChargeRowWidgetState extends State<_BillingChargeRowWidget> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _valCtrl;
  late final TextEditingController _invNoCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.row.name);
    _valCtrl = TextEditingController(
      text: widget.row.value == 0 ? '' : widget.row.value.toString(),
    );
    _invNoCtrl = TextEditingController(text: widget.row.number);
  }

  void _syncIfExternal(TextEditingController c, String val) {
    if (c.text != val) {
      c.value = c.value.copyWith(
        text: val,
        selection: TextSelection.collapsed(offset: val.length),
      );
    }
  }

  @override
  void didUpdateWidget(covariant _BillingChargeRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.row.name != widget.row.name) {
      _syncIfExternal(_nameCtrl, widget.row.name);
    }
    if (oldWidget.row.value != widget.row.value &&
        (double.tryParse(_valCtrl.text) ?? 0) != widget.row.value) {
      _syncIfExternal(
        _valCtrl,
        widget.row.value == 0 ? '' : widget.row.value.toString(),
      );
    }
    if (oldWidget.row.number != widget.row.number) {
      _syncIfExternal(_invNoCtrl, widget.row.number);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _valCtrl.dispose();
    _invNoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ErpTheme.slate50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ErpTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'CHARGE #${widget.index + 1}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: ErpTheme.slate500,
                ),
              ),
              const Spacer(),
              Text(
                formatInr(widget.row.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: ErpTheme.slate900,
                ),
              ),
              IconButton(
                onPressed: widget.onRemove,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: ErpTheme.dangerRose,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _nameCtrl,
                  onChanged: (v) => widget.onUpdate(name: v),
                  decoration: const InputDecoration(
                    labelText: 'Charge Name',
                    hintText: 'Packing / Loading / Freight...',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 72,
                child: DropdownButtonFormField<String>(
                  initialValue: widget.row.mode,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: '+/-'),
                  items: const [
                    DropdownMenuItem(value: 'ADD', child: Text('+')),
                    DropdownMenuItem(value: 'DEDUCT', child: Text('-')),
                  ],
                  onChanged: (v) => widget.onUpdate(mode: v ?? 'ADD'),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 72,
                child: DropdownButtonFormField<String>(
                  initialValue: widget.row.type,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'AMOUNT', child: Text('₹')),
                    DropdownMenuItem(value: 'PERCENT', child: Text('%')),
                  ],
                  onChanged: (v) => widget.onUpdate(type: v ?? 'AMOUNT'),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 92,
                child: TextField(
                  controller: _valCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (v) =>
                      widget.onUpdate(value: double.tryParse(v) ?? 0),
                  decoration: const InputDecoration(labelText: 'Value'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _invNoCtrl,
                  onChanged: (v) => widget.onUpdate(number: v),
                  decoration: const InputDecoration(
                    labelText: 'Fetch Past Invoice Tax (e.g. SGFI0001)',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: widget.onFetchPastTax,
                child: const Text('GET TAX'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillingTotalsCard extends StatelessWidget {
  const _BillingTotalsCard({
    required this.vm,
    required this.onSaveOnly,
    required this.onSaveAndPrint,
  });

  final BillingViewModel vm;
  final VoidCallback onSaveOnly;
  final VoidCallback onSaveAndPrint;

  @override
  Widget build(BuildContext context) {
    final t = vm.totals;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [ErpTheme.salesBlueDark, ErpTheme.salesBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: ErpTheme.salesBlue.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TotalLine(label: 'Subtotal', value: formatInr(t.subtotal)),
          const Divider(color: Colors.white24, height: 22),
          if (vm.docType == 'INV') ...[
            if (t.igst > 0) ...[
              _TotalLine(label: 'IGST', value: formatInr(t.igst)),
            ] else ...[
              _TotalLine(label: 'CGST', value: formatInr(t.cgst)),
              const SizedBox(height: 8),
              _TotalLine(label: 'SGST', value: formatInr(t.sgst)),
            ],
            const Divider(color: Colors.white24, height: 22),
          ] else ...[
            _TotalLine(label: 'Addl. Charges', value: formatInr(t.charges)),
            const Divider(color: Colors.white24, height: 22),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                formatInr(t.grandTotal),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: vm.isSaving ? null : onSaveOnly,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: ErpTheme.salesBlueDark,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: vm.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'SAVE DOCUMENT',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: vm.isSaving ? null : onSaveAndPrint,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.print_rounded, size: 18),
            label: const Text(
              'SAVE & PRINT A4',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalLine extends StatelessWidget {
  const _TotalLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
