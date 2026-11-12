import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:crackers_erp/core/utils/inr_formatter.dart';
import 'package:crackers_erp/domain/models/billing.dart';
import 'package:crackers_erp/domain/models/customer.dart';

String _formatRatePct(double taxAmt, double subtotal) {
  if (subtotal <= 0 || taxAmt <= 0) return '';
  final pct = ((taxAmt / subtotal) * 100).round();
  return pct > 0 ? ' @ $pct%' : '';
}

Future<Uint8List> buildInvoicePdf(
  InvoiceRecord invoice, {
  Customer? matchedCustomer,
}) async {
  final doc = pw.Document();
  final profile = invoice.companyProfile;
  final companyName = profile?.name.isNotEmpty == true
      ? profile!.name
      : 'COMPANY NAME';
  final companyGstin = profile?.gstin.isNotEmpty == true ? profile!.gstin : 'URP';
  final dateStr = DateFormat('dd/MM/yyyy').format(invoice.date);
  final kindLabel = invoice.inferredDocKindLabel;
  final titleHeader = switch (kindLabel) {
    'ESTIMATE' => 'ESTIMATE',
    'PERFORMA' => 'PERFORMA INVOICE',
    _ => 'TAX INVOICE',
  };

  final custAddressLines = <String>[
    if ((matchedCustomer?.address ?? invoice.customerAddress ?? '').trim().isNotEmpty)
      (matchedCustomer?.address ?? invoice.customerAddress ?? '').trim(),
    if ((matchedCustomer?.city ?? '').trim().isNotEmpty)
      [
        matchedCustomer!.city!.trim(),
        if ((matchedCustomer.district ?? '').trim().isNotEmpty &&
            matchedCustomer.district!.trim() != matchedCustomer.city!.trim())
          matchedCustomer.district!.trim(),
      ].join(', '),
  ].join(', ');

  final custStateLine = [
    matchedCustomer?.state ?? invoice.state ?? '-',
    if ((matchedCustomer?.pincode ?? '').trim().isNotEmpty)
      matchedCustomer!.pincode!.trim(),
  ].join(' - ');

  final custGstin = (invoice.customer ?? '').toUpperCase().contains('URP')
      ? 'URP'
      : (matchedCustomer?.gstin ?? 'URP');

  const borderSide = pw.BorderSide(color: PdfColors.black, width: 1.2);
  const fullBox = pw.Border(
    top: borderSide,
    bottom: borderSide,
    left: borderSide,
    right: borderSide,
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (context) => [
        pw.Container(
          decoration: const pw.BoxDecoration(border: fullBox),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Title Bar
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: borderSide),
                ),
                child: pw.Stack(
                  children: [
                    pw.Center(
                      child: pw.Text(
                        titleHeader,
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    pw.Positioned(
                      right: 0,
                      bottom: 1,
                      child: pw.Text(
                        'Original for Recipient',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Company Info vs Document Metadata
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          right: borderSide,
                          bottom: borderSide,
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            companyName.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          if ((profile?.address ?? invoice.dispatchAddress ?? '')
                              .trim()
                              .isNotEmpty)
                            pw.Text(
                              (profile?.address ?? invoice.dispatchAddress ?? '')
                                  .trim(),
                              style: pw.TextStyle(
                                fontSize: 9.5,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          if ((profile?.city ?? '').trim().isNotEmpty)
                            pw.Text(
                              '${profile!.city}, ${profile.state} - ${profile.pincode ?? ''}',
                              style: pw.TextStyle(
                                fontSize: 9.5,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'GSTIN/UIN: $companyGstin',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      children: [
                        _metaRow(
                          'Invoice No.',
                          invoice.number,
                          'Dated',
                          dateStr,
                          borderSide,
                        ),
                        _metaRow(
                          'State',
                          invoice.state ?? '-',
                          'Transporter',
                          invoice.transporterId ?? '-',
                          borderSide,
                        ),
                        _metaRow(
                          'Vehicle No.',
                          invoice.vehicleNo ?? '-',
                          'E-Way Bill No.',
                          invoice.ewayBillNo ?? '-',
                          borderSide,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Billed To / Consignee
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: borderSide),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Billed To / Consignee:',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      (invoice.customer ?? '-').toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (custAddressLines.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        custAddressLines,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'State: $custStateLine',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if ((matchedCustomer?.mobile ?? '').trim().isNotEmpty)
                      pw.Text(
                        'Mobile: ${matchedCustomer!.mobile}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    pw.Text(
                      'GSTIN/UIN: $custGstin',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Line Items Table
              pw.Table(
                border: pw.TableBorder.symmetric(
                  inside: const pw.BorderSide(
                    color: PdfColors.black,
                    width: 0.9,
                  ),
                ),
                columnWidths: const {
                  0: pw.FlexColumnWidth(0.7),
                  1: pw.FlexColumnWidth(4.5),
                  2: pw.FlexColumnWidth(1.2),
                  3: pw.FlexColumnWidth(1.1),
                  4: pw.FlexColumnWidth(1.1),
                  5: pw.FlexColumnWidth(1.6),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                      border: pw.Border(bottom: borderSide),
                    ),
                    children: [
                      _th('S.No', align: pw.TextAlign.center),
                      _th('Description of Goods'),
                      _th('HSN/SAC', align: pw.TextAlign.center),
                      _th('Qty', align: pw.TextAlign.center),
                      _th('Rate', align: pw.TextAlign.right),
                      _th('Amount', align: pw.TextAlign.right),
                    ],
                  ),
                  ...invoice.items.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final item = entry.value;
                    return pw.TableRow(
                      children: [
                        _td('$idx', align: pw.TextAlign.center),
                        _td(item.product.toUpperCase()),
                        _td(
                          (item.hsn ?? '').isEmpty ? '-' : item.hsn!,
                          align: pw.TextAlign.center,
                        ),
                        _td('${item.qty} Nos', align: pw.TextAlign.center),
                        _td(
                          item.rate.toStringAsFixed(2),
                          align: pw.TextAlign.right,
                        ),
                        _td(
                          item.total.toStringAsFixed(2),
                          align: pw.TextAlign.right,
                        ),
                      ],
                    );
                  }),
                ],
              ),

              // Totals Split Section
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: borderSide,
                    bottom: borderSide,
                  ),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 65,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(right: borderSide),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Amount Chargeable (in words)',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              'INR ${numberToWordsInr(invoice.grandTotal)}',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 12),
                            pw.Text(
                              "Company's Bank Details",
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                decoration: pw.TextDecoration.underline,
                              ),
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              'Bank Name : -',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            pw.Text(
                              'A/c No.   : -',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            pw.Text(
                              'Branch    : -',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 35,
                      child: pw.Column(
                        children: [
                          _amountLine(
                            'Subtotal',
                            'Rs. ${invoice.subtotal.toStringAsFixed(2)}',
                            borderSide,
                          ),
                          if (invoice.cgst > 0)
                            _amountLine(
                              'Output CGST${_formatRatePct(invoice.cgst, invoice.subtotal)}',
                              'Rs. ${invoice.cgst.toStringAsFixed(2)}',
                              borderSide,
                            ),
                          if (invoice.sgst > 0)
                            _amountLine(
                              'Output SGST${_formatRatePct(invoice.sgst, invoice.subtotal)}',
                              'Rs. ${invoice.sgst.toStringAsFixed(2)}',
                              borderSide,
                            ),
                          if (invoice.igst > 0)
                            _amountLine(
                              'Output IGST${_formatRatePct(invoice.igst, invoice.subtotal)}',
                              'Rs. ${invoice.igst.toStringAsFixed(2)}',
                              borderSide,
                            ),
                          ...invoice.charges.map(
                            (c) => _amountLine(
                              c.name.isEmpty ? 'Additional Charge' : c.name,
                              'Rs. ${c.amount.toStringAsFixed(2)}',
                              borderSide,
                            ),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            color: PdfColors.grey100,
                            child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'TOTAL',
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.Text(
                                  'Rs. ${invoice.grandTotal.toStringAsFixed(2)}',
                                  style: pw.TextStyle(
                                    fontSize: 13,
                                    fontWeight: pw.FontWeight.bold,
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

              // Footer Declaration & Authorised Signatory
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 65,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(right: borderSide),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Declaration',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              decoration: pw.TextDecoration.underline,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'We declare that this invoice shows the actual price of the goods described and that all particulars are true and correct.',
                            style: const pw.TextStyle(fontSize: 8.5),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Text(
                            'SUBJECT TO SIVAKASI JURISDICTION',
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 35,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      height: 70,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'for $companyName',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'Authorised Signatory',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _metaRow(
  String leftLabel,
  String leftVal,
  String rightLabel,
  String rightVal,
  pw.BorderSide borderSide,
) {
  return pw.Container(
    decoration: pw.BoxDecoration(border: pw.Border(bottom: borderSide)),
    child: pw.Row(
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            decoration: pw.BoxDecoration(border: pw.Border(right: borderSide)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(leftLabel, style: const pw.TextStyle(fontSize: 8)),
                pw.Text(
                  leftVal,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(rightLabel, style: const pw.TextStyle(fontSize: 8)),
                pw.Text(
                  rightVal,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _th(String text, {pw.TextAlign align = pw.TextAlign.left}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
    ),
  );
}

pw.Widget _td(String text, {pw.TextAlign align = pw.TextAlign.left}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
    ),
  );
}

pw.Widget _amountLine(
  String label,
  String value,
  pw.BorderSide borderSide,
) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: pw.BoxDecoration(border: pw.Border(bottom: borderSide)),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );
}

