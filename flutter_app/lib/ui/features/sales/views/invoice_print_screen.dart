import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/data/repositories/billing_repository.dart';
import 'package:crackers_erp/data/repositories/master_repository.dart';
import 'package:crackers_erp/domain/models/billing.dart';
import 'package:crackers_erp/domain/models/customer.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'invoice_pdf.dart';

class InvoicePrintScreen extends StatefulWidget {
  const InvoicePrintScreen({
    required this.invoiceNumber,
    required this.billingRepository,
    required this.masterRepository,
    super.key,
  });

  final String invoiceNumber;
  final BillingRepository billingRepository;
  final MasterRepository masterRepository;

  @override
  State<InvoicePrintScreen> createState() => _InvoicePrintScreenState();
}

class _InvoicePrintScreenState extends State<InvoicePrintScreen> {
  InvoiceRecord? _invoice;
  Customer? _matchedCustomer;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.billingRepository.fetchInvoice(widget.invoiceNumber),
        widget.masterRepository.fetchCustomers().catchError((_) => <Customer>[]),
      ]);
      final inv = results[0] as InvoiceRecord;
      final customers = results[1] as List<Customer>;
      Customer? matched;
      for (final c in customers) {
        if (c.name == inv.customer) {
          matched = c;
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        _invoice = inv;
        _matchedCustomer = matched;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load invoice ${widget.invoiceNumber}: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErpTheme.slate50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/billing-history');
            }
          },
        ),
        title: Text('Print • ${widget.invoiceNumber}'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ErpErrorBanner(message: _error!, onRetry: _load),
              ),
            )
          : PdfPreview(
              pdfFileName: '${widget.invoiceNumber}.pdf',
              canChangeOrientation: false,
              canChangePageFormat: false,
              build: (_) => buildInvoicePdf(
                _invoice!,
                matchedCustomer: _matchedCustomer,
              ),
            ),
    );
  }
}

