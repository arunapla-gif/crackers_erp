import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:crackers_erp/domain/models/packing_dispatch.dart';
import 'daily_production_pdf.dart';

/// Generates a zero-rupee Factory Gate Pass / Delivery Challan PDF for any
/// factory dispatch (either Own Godown transfer or Transporter outward load).
Future<Uint8List> buildFactoryGatePassPdf(
  FactoryDispatchRecord dispatch, {
  String companyTitle = 'ARUNACHALA AGENCIES',
}) async {
  final theme = await loadTamilPdfTheme();
  final doc = pw.Document(theme: theme);
  final dateFmt = DateFormat('dd MMM yyyy');
  final timeFmt = DateFormat('dd MMM yyyy, hh:mm a');

  final headerBg = PdfColor.fromHex('#0F172A');
  final softBg = PdfColor.fromHex('#F8FAFC');
  final borderCol = PdfColor.fromHex('#CBD5E1');
  final accentCol = dispatch.isOwnGodown
      ? PdfColor.fromHex('#047857')
      : PdfColor.fromHex('#1D4ED8');
  final accentSoft = dispatch.isOwnGodown
      ? PdfColor.fromHex('#ECFDF5')
      : PdfColor.fromHex('#EFF6FF');

  String t(String s) => shapeTamilForPdf(s);

  pw.Widget metaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 82,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#475569'),
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              t(value.isEmpty ? '-' : value),
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(26, 24, 26, 24),
      build: (context) => [
        // Top Header Banner
        pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            color: headerBg,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    t(companyTitle),
                    style: pw.TextStyle(
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'FACTORY GATE PASS / DELIVERY CHALLAN (NON-FINANCIAL)',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#CBD5E1'),
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  color: accentSoft,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      dispatch.challanNo,
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: accentCol,
                      ),
                    ),
                    pw.Text(
                      dispatch.isOwnGodown
                          ? 'OWN GODOWN TRANSFER'
                          : 'TRANSPORTER DISPATCH',
                      style: pw.TextStyle(
                        fontSize: 7.5,
                        fontWeight: pw.FontWeight.bold,
                        color: accentCol,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),

        // Movement & Transport Details Grid
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: softBg,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: borderCol, width: 0.7),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DISPATCH ROUTE',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: accentCol,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    metaRow('Dispatch Date:', dateFmt.format(dispatch.date)),
                    metaRow('From Godown:', dispatch.fromGodownName),
                    metaRow(
                      dispatch.isOwnGodown ? 'To Godown:' : 'Transporter:',
                      dispatch.destinationDisplay,
                    ),
                    if (!dispatch.isOwnGodown &&
                        (dispatch.customerName ?? '').isNotEmpty)
                      metaRow('Party / Buyer:', dispatch.customerName!),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: softBg,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: borderCol, width: 0.7),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'VEHICLE & GATE INFO',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: accentCol,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    metaRow('Vehicle No:', dispatch.vehicleNo ?? '-'),
                    metaRow('Driver Name:', dispatch.driverName ?? '-'),
                    if (!dispatch.isOwnGodown)
                      metaRow('LR / Slip No:', dispatch.lrNumber ?? '-'),
                    metaRow('Prepared By:', dispatch.createdBy),
                  ],
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 14),

        // Itemized Master Cartons Table
        pw.Table(
          border: pw.TableBorder.all(color: borderCol, width: 0.6),
          columnWidths: const {
            0: pw.FixedColumnWidth(32),
            1: pw.FlexColumnWidth(3.2),
            2: pw.FlexColumnWidth(1.5),
            3: pw.FixedColumnWidth(68),
            4: pw.FixedColumnWidth(64),
            5: pw.FixedColumnWidth(72),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('#E2E8F0')),
              children: [
                _cell('S.No', bold: true, align: pw.TextAlign.center),
                _cell('Finished Product', bold: true),
                _cell('Category', bold: true),
                _cell('Boxes / Case', bold: true, align: pw.TextAlign.right),
                _cell('Cartons', bold: true, align: pw.TextAlign.right),
                _cell('Total Boxes', bold: true, align: pw.TextAlign.right),
              ],
            ),
            for (var i = 0; i < dispatch.items.length; i++)
              pw.TableRow(
                decoration: i.isOdd
                    ? pw.BoxDecoration(color: softBg)
                    : null,
                children: [
                  _cell('${i + 1}', align: pw.TextAlign.center),
                  _cell(t(dispatch.items[i].productName), bold: true),
                  _cell(t(dispatch.items[i].subCategory ?? '-')),
                  _cell(
                    '${dispatch.items[i].boxesPerCase}',
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    '${dispatch.items[i].cartons}',
                    bold: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    '${dispatch.items[i].totalBoxes}',
                    align: pw.TextAlign.right,
                  ),
                ],
              ),
            pw.TableRow(
              decoration: pw.BoxDecoration(color: accentSoft),
              children: [
                _cell('', bold: true),
                _cell('TOTAL LOAD', bold: true),
                _cell('${dispatch.items.length} item(s)', bold: true),
                _cell('', bold: true),
                _cell(
                  '${dispatch.totalCartons}',
                  bold: true,
                  align: pw.TextAlign.right,
                  color: accentCol,
                ),
                _cell(
                  '${dispatch.totalBoxes}',
                  bold: true,
                  align: pw.TextAlign.right,
                  color: accentCol,
                ),
              ],
            ),
          ],
        ),

        if ((dispatch.remarks ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: softBg,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: borderCol, width: 0.6),
            ),
            child: pw.Text(
              'Remarks: ${t(dispatch.remarks!)}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
        ],

        pw.SizedBox(height: 38),

        // Signature Strip
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _signatureBox('Prepared By (Supervisor)'),
            pw.SizedBox(width: 18),
            _signatureBox('Driver / Carrier Signature'),
            pw.SizedBox(width: 18),
            _signatureBox('Security / Receiver Sign'),
          ],
        ),

        pw.SizedBox(height: 18),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Generated on ${timeFmt.format(DateTime.now())}  •  Quantity Gate Pass Only (No Pricing)',
            style: pw.TextStyle(
              fontSize: 7.5,
              color: PdfColor.fromHex('#64748B'),
            ),
          ),
        ),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _cell(
  String text, {
  bool bold = false,
  pw.TextAlign align = pw.TextAlign.left,
  PdfColor? color,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color ?? PdfColors.black,
      ),
    ),
  );
}

pw.Widget _signatureBox(String title) {
  return pw.Expanded(
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          height: 1,
          color: PdfColor.fromHex('#64748B'),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          title,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#334155'),
          ),
        ),
      ],
    ),
  );
}

