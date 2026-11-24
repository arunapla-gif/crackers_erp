import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/domain/models/packing_dispatch.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/core/erp_crud_widgets.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/features/auth/view_models/auth_view_model.dart';
import 'package:crackers_erp/ui/features/production/view_models/factory_dispatch_view_model.dart';
import 'factory_dispatch_pdf.dart';

class FactoryDispatchScreen extends StatefulWidget {
  const FactoryDispatchScreen({
    required this.viewModel,
    required this.authViewModel,
    super.key,
  });

  final FactoryDispatchViewModel viewModel;
  final AuthViewModel authViewModel;

  @override
  State<FactoryDispatchScreen> createState() => _FactoryDispatchScreenState();
}

class _FactoryDispatchScreenState extends State<FactoryDispatchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _customTransporterCtrl = TextEditingController();
  final TextEditingController _customerCtrl = TextEditingController();
  final TextEditingController _lrNumberCtrl = TextEditingController();
  final TextEditingController _vehicleCtrl = TextEditingController();
  final TextEditingController _driverCtrl = TextEditingController();
  final TextEditingController _remarksCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.viewModel.loadOverview();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customTransporterCtrl.dispose();
    _customerCtrl.dispose();
    _lrNumberCtrl.dispose();
    _vehicleCtrl.dispose();
    _driverCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final vm = widget.viewModel;
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (picked != null) {
      vm.setDate(picked);
    }
  }

  Future<void> _printGatePass(FactoryDispatchRecord record) async {
    try {
      final bytes = await buildFactoryGatePassPdf(record);
      await Printing.layoutPdf(
        name: 'GatePass_${record.challanNo}.pdf',
        onLayout: (_) async => bytes,
      );
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not generate Gate Pass PDF: $err')),
      );
    }
  }

  Future<void> _submitDispatch() async {
    final vm = widget.viewModel;
    final created = await vm.submitDispatch(
      vehicleNoInput: _vehicleCtrl.text,
      driverNameInput: _driverCtrl.text,
      customerNameInput: _customerCtrl.text,
      lrNumberInput: _lrNumberCtrl.text,
      remarksInput: _remarksCtrl.text,
      customTransporterInput: _customTransporterCtrl.text,
    );
    if (created != null && mounted) {
      _lrNumberCtrl.clear();
      _remarksCtrl.clear();
      _customerCtrl.clear();
      _tabController.animateTo(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmbedded = ErpShellScope.isEmbeddedShell(context);

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;

        return Scaffold(
          backgroundColor: ErpTheme.slate50,
          appBar: isEmbedded
              ? null
              : AppBar(
                  title: const Text('Factory Dispatch'),
                  actions: [
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: vm.isLoading ? null : vm.loadOverview,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                    AccountAppBarAction(authViewModel: widget.authViewModel),
                  ],
                ),
          body: Column(
            children: [
              if (isEmbedded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: ErpSectionHeaderBar(
                    title: 'Factory Dispatch & Gate Pass',
                    subtitle:
                        'Dispatch sealed Master Cartons to Own Godowns (Sivakasi / Injar) or Transporters with printable zero-rupee Gate Pass PDF.',
                    accentColor: ErpTheme.salesBlueDark,
                    actions: [
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: vm.isLoading ? null : vm.loadOverview,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                ),

              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: ErpTheme.salesBlueDark,
                  unselectedLabelColor: ErpTheme.slate500,
                  indicatorColor: ErpTheme.salesBlue,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  tabs: [
                    const Tab(text: 'New Dispatch'),
                    Tab(text: 'Gate Passes (${vm.dispatches.length})'),
                  ],
                ),
              ),
              const Divider(height: 1, color: ErpTheme.slate200),

              if (vm.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: ErpErrorBanner(
                    message: vm.errorMessage!,
                    onRetry: vm.loadOverview,
                    onDismiss: vm.clearMessages,
                  ),
                ),

              if (vm.successMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: ErpTheme.ordersEmeraldSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ErpTheme.ordersEmerald.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: ErpTheme.ordersEmerald,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            vm.successMessage!,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: ErpTheme.godownTealDark,
                            ),
                          ),
                        ),
                        if (vm.lastCreatedDispatch != null)
                          TextButton.icon(
                            onPressed: () =>
                                _printGatePass(vm.lastCreatedDispatch!),
                            icon: const Icon(Icons.print_rounded, size: 16),
                            label: const Text('Print'),
                          ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: vm.clearMessages,
                          icon: const Icon(Icons.close, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),

              Expanded(
                child: vm.isLoading && vm.overview == null
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildNewDispatchTab(vm),
                          _buildRecentDispatchesTab(vm),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNewDispatchTab(FactoryDispatchViewModel vm) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final stockList = vm.availableStockForSource;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
      children: [
        // 1. Destination Type Toggle Card
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '1. Dispatch Destination',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: ErpTheme.slate900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      icon: const Icon(Icons.calendar_today_rounded, size: 14),
                      label: Text(
                        dateFmt.format(vm.selectedDate),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  key: const ValueKey('dispatch-dest-toggle'),
                  segments: const [
                    ButtonSegment<String>(
                      value: 'GODOWN',
                      icon: Icon(Icons.warehouse_outlined, size: 17),
                      label: Text('Own Godown'),
                    ),
                    ButtonSegment<String>(
                      value: 'TRANSPORTER',
                      icon: Icon(Icons.local_shipping_outlined, size: 17),
                      label: Text('Transporter'),
                    ),
                  ],
                  selected: {vm.destinationType},
                  onSelectionChanged: (set) {
                    if (set.isNotEmpty) vm.setDestinationType(set.first);
                  },
                ),
                const SizedBox(height: 12),

                // From Godown
                DropdownButtonFormField<int>(
                  key: ValueKey('from-godown-${vm.fromGodownId}'),
                  initialValue: vm.fromGodownId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'From Godown (Source)',
                  ),
                  items: vm.godowns
                      .map(
                        (g) => DropdownMenuItem<int>(
                          value: g.id,
                          child: Text(
                            g.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: vm.setFromGodownId,
                ),
                const SizedBox(height: 10),

                if (vm.destinationType == 'GODOWN') ...[
                  DropdownButtonFormField<int>(
                    key: ValueKey('to-godown-${vm.toGodownId}'),
                    initialValue: vm.toGodownId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'To Own Godown (Sivakasi / Injar)',
                    ),
                    items: vm.destinationGodowns
                        .map(
                          (g) => DropdownMenuItem<int>(
                            value: g.id,
                            child: Text(
                              g.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: vm.setToGodownId,
                  ),
                ] else ...[
                  if (vm.transporters.isNotEmpty) ...[
                    DropdownButtonFormField<int?>(
                      initialValue: vm.selectedTransporterId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select Transporter',
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text(
                            '— Type Custom Transporter Below —',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ...vm.transporters.map(
                          (t) => DropdownMenuItem<int?>(
                            value: t.id,
                            child: Text(
                              t.city != null && t.city!.isNotEmpty
                                  ? '${t.name} (${t.city})'
                                  : t.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: vm.setSelectedTransporterId,
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (vm.selectedTransporterId == null) ...[
                    TextField(
                      key: const ValueKey('custom-transporter-field'),
                      controller: _customTransporterCtrl,
                      onChanged: vm.setCustomTransporterName,
                      decoration: const InputDecoration(
                        labelText: 'Transporter / Lorry Service Name *',
                        hintText: 'e.g. KPN Parcel / AKR Express',
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customerCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Party / Buyer Name',
                            hintText: 'Optional',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _lrNumberCtrl,
                          decoration: const InputDecoration(
                            labelText: 'LR / Booking No',
                            hintText: 'Optional',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),

                // Vehicle + Driver Row (with quick-pick chips from Vehicle Master)
                if (vm.vehicles.isNotEmpty) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text(
                          'Fleet: ',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: ErpTheme.slate500,
                          ),
                        ),
                        for (final v in vm.vehicles)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(v.no),
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                _vehicleCtrl.text = v.no;
                                if (v.drivers.isNotEmpty) {
                                  _driverCtrl.text = v.drivers.first;
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const ValueKey('dispatch-vehicle-field'),
                        controller: _vehicleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle No',
                          hintText: 'TN-67-XX-1234',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        key: const ValueKey('dispatch-driver-field'),
                        controller: _driverCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Driver Name',
                          hintText: 'Optional',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _remarksCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Gate Pass Remarks (Optional)',
                    hintText: 'Loading bay / seal notes',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 2. Select Sealed Master Cartons
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '2. Select Master Cartons',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: ErpTheme.slate900,
                        ),
                      ),
                    ),
                    if (vm.selectedItemCount > 0)
                      TextButton(
                        onPressed: vm.clearSelection,
                        child: const Text('Clear All'),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                if (stockList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: ErpEmptyState(
                      icon: Icons.all_inbox_outlined,
                      title: 'No Sealed Cartons Available Here',
                      subtitle:
                          'Seal Master Cartons in the Packing screen first to populate Factory Ready Stock.',
                    ),
                  )
                else
                  for (final item in stockList) ...[
                    _buildStockSelectorRow(vm, item),
                    const Divider(height: 14, color: ErpTheme.slate200),
                  ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Summary & Submit Bar
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ErpTheme.slate900,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 4,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(
                    'Selected: ${vm.totalSelectedCartons} Master Cartons',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${vm.totalSelectedBoxes} Inner Boxes',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                key: const ValueKey('confirm-dispatch-btn'),
                onPressed: vm.isSubmitting || vm.totalSelectedCartons <= 0
                    ? null
                    : _submitDispatch,
                style: FilledButton.styleFrom(
                  backgroundColor: vm.destinationType == 'GODOWN'
                      ? ErpTheme.godownTeal
                      : ErpTheme.salesBlue,
                ),
                icon: const Icon(Icons.local_shipping_rounded),
                label: Text(
                  vm.isSubmitting
                      ? 'Saving Dispatch...'
                      : vm.destinationType == 'GODOWN'
                      ? 'Transfer & Generate Gate Pass'
                      : 'Dispatch to Transporter & Gate Pass',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStockSelectorRow(
    FactoryDispatchViewModel vm,
    DispatchStockItem item,
  ) {
    final current = vm.selectedCartonsByProduct[item.productId] ?? 0;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: ErpTheme.slate900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Available: ${item.availableCartons} Cartons  •  ${item.boxesPerCase}/case',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: ErpTheme.godownTealDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: current > 0
                  ? () => vm.setCartonsForProduct(
                      item.productId,
                      current - 1,
                      item.availableCartons,
                    )
                  : null,
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
            SizedBox(
              width: 56,
              child: TextFormField(
                key: ValueKey('dispatch-qty-${item.code}-$current'),
                initialValue: current > 0 ? '$current' : '',
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: '0',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                ),
                onChanged: (val) {
                  final parsed = int.tryParse(val.trim()) ?? 0;
                  vm.setCartonsForProduct(
                    item.productId,
                    parsed,
                    item.availableCartons,
                  );
                },
              ),
            ),
            IconButton(
              key: ValueKey('dispatch-inc-${item.code}'),
              visualDensity: VisualDensity.compact,
              onPressed: current < item.availableCartons
                  ? () => vm.setCartonsForProduct(
                      item.productId,
                      current + 1,
                      item.availableCartons,
                    )
                  : null,
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: ErpTheme.salesBlueDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentDispatchesTab(FactoryDispatchViewModel vm) {
    final dispatches = vm.dispatches;
    final dateFmt = DateFormat('dd MMM yyyy');

    if (dispatches.isEmpty) {
      return RefreshIndicator(
        onRefresh: vm.loadOverview,
        child: ListView(
          children: const [
            SizedBox(height: 80),
            ErpEmptyState(
              icon: Icons.local_shipping_outlined,
              title: 'No Factory Dispatches Yet',
              subtitle:
                  'Dispatches to Own Godowns or Transporters will appear here with printable Gate Pass PDFs.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.loadOverview,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        itemCount: dispatches.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (ctx, idx) {
          final d = dispatches[idx];
          return Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              d.challanNo,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: ErpTheme.slate900,
                              ),
                            ),
                            ErpBadge(
                              label: d.isOwnGodown
                                  ? 'OWN GODOWN'
                                  : 'TRANSPORTER',
                              backgroundColor: d.isOwnGodown
                                  ? ErpTheme.godownTealSoft
                                  : ErpTheme.salesBlueSoft,
                              foregroundColor: d.isOwnGodown
                                  ? ErpTheme.godownTealDark
                                  : ErpTheme.salesBlueDark,
                            ),
                            Text(
                              dateFmt.format(d.date),
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: ErpTheme.slate500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonalIcon(
                        key: ValueKey('print-gatepass-${d.challanNo}'),
                        onPressed: () => _printGatePass(d),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        icon: const Icon(Icons.print_rounded, size: 16),
                        label: const Text('Gate Pass'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${d.fromGodownName}  →  ${d.destinationDisplay}',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: ErpTheme.slate800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      Text(
                        '${d.totalCartons} Cartons (${d.totalBoxes} Boxes)',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: ErpTheme.godownTealDark,
                        ),
                      ),
                      if ((d.vehicleNo ?? '').isNotEmpty)
                        Text(
                          'Vehicle: ${d.vehicleNo}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: ErpTheme.slate700,
                          ),
                        ),
                      if ((d.lrNumber ?? '').isNotEmpty)
                        Text(
                          'LR: ${d.lrNumber}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: ErpTheme.slate700,
                          ),
                        ),
                      if ((d.customerName ?? '').isNotEmpty)
                        Text(
                          'Party: ${d.customerName}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: ErpTheme.slate700,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ErpTheme.slate50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ErpTheme.slate200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final item in d.items)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.productName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: ErpTheme.slate800,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${item.cartons} Ctn (${item.totalBoxes} boxes)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: ErpTheme.slate700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
