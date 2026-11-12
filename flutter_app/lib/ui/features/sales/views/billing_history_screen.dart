import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/core/utils/inr_formatter.dart';
import 'package:crackers_erp/domain/models/billing.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/core/erp_crud_widgets.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/features/sales/view_models/billing_history_view_model.dart';

class BillingHistoryScreen extends StatefulWidget {
  const BillingHistoryScreen({required this.viewModel, super.key});

  final BillingHistoryViewModel viewModel;

  @override
  State<BillingHistoryScreen> createState() => _BillingHistoryScreenState();
}

class _BillingHistoryScreenState extends State<BillingHistoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.viewModel.loadHistory();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmPrint(InvoiceRecord record) async {
    final ok = await showErpConfirmDialog(
      context: context,
      title: 'Print Document',
      message: 'Generate A4 PDF and print ${record.number}?',
      confirmLabel: 'Confirm Print',
    );
    if (ok && mounted) {
      unawaited(
        context.push('/print/invoice/${Uri.encodeComponent(record.number)}'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final list = vm.filteredRecords;

        return ErpScreenScaffold(
          title: 'Billing History',
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: ErpSectionHeaderBar(
                      accentColor: ErpTheme.hrPurple,
                      title: 'Billing History',
                      subtitle:
                          'Search past Tax Invoices, Estimates & Performa invoices.',
                      actions: [
                        SizedBox(
                          width: 260,
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: vm.setSearchQuery,
                            decoration: InputDecoration(
                              hintText: 'Invoice No / Customer...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        vm.setSearchQuery('');
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        IconButton.outlined(
                          onPressed: vm.isLoading ? null : vm.loadHistory,
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (vm.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ErpErrorBanner(
                    message: vm.errorMessage!,
                    onRetry: vm.loadHistory,
                  ),
                ),
              Expanded(
                child: vm.isLoading && list.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : list.isEmpty
                    ? const ErpEmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No Billing Documents',
                        subtitle:
                            'Saved invoices, estimates and performas appear here.',
                      )
                    : RefreshIndicator(
                        onRefresh: vm.loadHistory,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final item = list[index];
                            final kind = item.inferredDocKindLabel;
                            final badgeColors = switch (kind) {
                              'ESTIMATE' => (
                                ErpTheme.dangerRoseSoft,
                                ErpTheme.dangerRose,
                              ),
                              'PERFORMA' => (
                                const Color(0xFFF5F3FF),
                                ErpTheme.hrPurple,
                              ),
                              _ => (
                                ErpTheme.salesBlueSoft,
                                ErpTheme.salesBlueDark,
                              ),
                            };
                            final typeLabel = kind == 'TAX INVOICE'
                                ? (item.series?.isNotEmpty == true
                                      ? item.series!
                                      : 'INVOICE')
                                : kind;

                            return Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 1180),
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 88,
                                          child: Text(
                                            DateFormat('dd/MM/yy')
                                                .format(item.date),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: ErpTheme.slate500,
                                            ),
                                          ),
                                        ),
                                        ErpBadge(
                                          label: typeLabel,
                                          backgroundColor: badgeColors.$1,
                                          foregroundColor: badgeColors.$2,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.number,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 14,
                                                  color: ErpTheme.slate900,
                                                ),
                                              ),
                                              Text(
                                                '${item.customer ?? 'Walk-in'} • ${item.items.length} items',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: ErpTheme.slate500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          formatInr(item.grandTotal),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 15,
                                            color: ErpTheme.hrPurple,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        FilledButton.tonalIcon(
                                          onPressed: () => _confirmPrint(item),
                                          icon: const Icon(
                                            Icons.print_rounded,
                                            size: 16,
                                          ),
                                          label: const Text('Print'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
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
