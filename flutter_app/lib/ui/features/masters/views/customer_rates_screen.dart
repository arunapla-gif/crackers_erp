import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/core/utils/inr_formatter.dart';
import 'package:crackers_erp/domain/models/customer.dart';
import 'package:crackers_erp/domain/models/product.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/core/erp_crud_widgets.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/core/searchable_picker.dart';
import 'package:crackers_erp/ui/features/masters/view_models/customer_rates_view_model.dart';
import 'package:crackers_erp/ui/features/masters/views/master_shared_widgets.dart';

class CustomerRatesScreen extends StatefulWidget {
  const CustomerRatesScreen({required this.viewModel, super.key});

  final CustomerRatesViewModel viewModel;

  @override
  State<CustomerRatesScreen> createState() => _CustomerRatesScreenState();
}

class _CustomerRatesScreenState extends State<CustomerRatesScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.viewModel.initialize();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        syncMasterController(_searchCtrl, vm.searchQuery);
        final groups = vm.groupedProducts;
        final customer = vm.selectedCustomer;

        return ErpScreenScaffold(
          title: 'Customer Rates',
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ErpSectionHeaderBar(
                              accentColor: ErpTheme.salesBlue,
                              title: 'Customer Rates',
                              subtitle:
                                  'Manage negotiated product rates for specific customers.',
                              actions: [
                                if (customer != null)
                                  ErpBadge(
                                    label:
                                        '${vm.customRateCount} CUSTOM OVERRIDES',
                                    backgroundColor: ErpTheme.salesBlueSoft,
                                    foregroundColor: ErpTheme.salesBlueDark,
                                  ),
                                OutlinedButton.icon(
                                  onPressed: vm.isLoading
                                      ? null
                                      : vm.initialize,
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    size: 18,
                                  ),
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
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ErpResponsiveFormGrid(
                                      minItemWidth: 260,
                                      children: [
                                        SearchablePickerField<Customer>(
                                          label: 'Select Customer',
                                          value: customer,
                                          displayText: customer?.name ?? '',
                                          hintText: '-- Choose a customer --',
                                          options: vm.customers
                                              .map(
                                                (c) => SearchablePickerOption(
                                                  value: c,
                                                  label: c.name,
                                                  subtitle:
                                                      '${c.city ?? ''} ${(c.gstin ?? '').toUpperCase()}'
                                                          .trim(),
                                                ),
                                              )
                                              .toList(),
                                          onSelected: vm.selectCustomer,
                                          onClear: customer == null
                                              ? null
                                              : () => vm.selectCustomer(null),
                                        ),
                                        if (customer != null)
                                          TextField(
                                            controller: _searchCtrl,
                                            decoration: const InputDecoration(
                                              labelText: 'Search Products',
                                              hintText:
                                                  'Search by name, code or category...',
                                              prefixIcon: Icon(Icons.search),
                                            ),
                                            onChanged: vm.setSearchQuery,
                                          ),
                                      ],
                                    ),
                                    if (customer != null) ...[
                                      const SizedBox(height: 16),
                                      if (vm.isLoadingRates)
                                        const Padding(
                                          padding: EdgeInsets.all(24),
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        )
                                      else if (groups.isEmpty)
                                        const ErpEmptyState(
                                          icon: Icons.inventory_2_outlined,
                                          title: 'No products found',
                                          subtitle:
                                              'Try clearing the search query.',
                                        )
                                      else
                                        Column(
                                          children: groups.entries.map((entry) {
                                            return _RateCategoryGroup(
                                              customerId: customer.id,
                                              groupName: entry.key,
                                              products: entry.value,
                                              rateLookup: vm.rateTextFor,
                                              onRateChanged: vm.setCustomRate,
                                            );
                                          }).toList(),
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (customer != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: ErpTheme.slate200)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${customer.name} • ${vm.customRateCount} custom rate(s)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: ErpTheme.slate700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: vm.isSaving ? null : vm.saveRates,
                              style: FilledButton.styleFrom(
                                backgroundColor: ErpTheme.salesBlueDark,
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
                                vm.isSaving
                                    ? 'Saving...'
                                    : 'Save Customer Rates',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RateCategoryGroup extends StatelessWidget {
  const _RateCategoryGroup({
    required this.customerId,
    required this.groupName,
    required this.products,
    required this.rateLookup,
    required this.onRateChanged,
  });

  final int customerId;
  final String groupName;
  final List<Product> products;
  final String Function(int productId) rateLookup;
  final void Function(int productId, String value) onRateChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ErpTheme.slate200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: const BoxDecoration(
              color: Color(0xFFB4D2A5),
              border: Border(
                bottom: BorderSide(color: Color(0xFF9BB88D)),
              ),
            ),
            child: Text(
              groupName.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: ErpTheme.slate900,
              ),
            ),
          ),
          ...products.map((p) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: ErpTheme.slate100)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: ErpTheme.slate100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                p.code,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: ErpTheme.slate700,
                                ),
                              ),
                            ),
                            if ((p.category ?? '').isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  p.category!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: ErpTheme.slate500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: ErpTheme.slate900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Standard: ${formatInr(p.rate)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ErpTheme.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 132,
                    child: _RateInputField(
                      key: ValueKey('rate_${customerId}_${p.id}'),
                      value: rateLookup(p.id),
                      onChanged: (val) => onRateChanged(p.id, val),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _RateInputField extends StatefulWidget {
  const _RateInputField({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_RateInputField> createState() => _RateInputFieldState();
}

class _RateInputFieldState extends State<_RateInputField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _RateInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      syncMasterController(_controller, widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.right,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: ErpTheme.salesBlueDark,
      ),
      decoration: const InputDecoration(
        hintText: 'Standard',
        prefixText: '₹ ',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      onChanged: widget.onChanged,
    );
  }
}

