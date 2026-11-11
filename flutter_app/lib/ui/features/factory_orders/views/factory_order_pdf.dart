import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:crackers_erp/domain/models/factory_order.dart';

Future<Uint8List> buildFactoryOrderPackingPdf(FactoryOrder order) async {
  final doc = pw.Document();
  final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(order.updatedAt);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) {
        final totalCases = order.totalCases;
        final totalBoxes = order.items.fold(0, (s, i) => s + i.totalBoxes);

        return [
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'FACTORY PACKING SLIP',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Order #${order.id}  |  Approved: $dateStr'),
                    if (order.repUsername != null)
                      pw.Text('Booked By Rep: ${order.repUsername}'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      order.customerName,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (order.locationLabel.isNotEmpty)
                      pw.Text(order.locationLabel),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            headers: const [
              '#',
              'Factory Physical Box / Item',
              'Cases',
              'Boxes / Case',
              'Total Boxes',
              'Done',
            ],
            data: [
              ...order.items.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final item = entry.value;
                return [
                  '$idx',
                  item.product,
                  '${item.qty}',
                  '${item.boxesPerCase}',
                  '${item.totalBoxes}',
                  '[   ]',
                ];
              }),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'TOTAL: $totalCases Cases  ($totalBoxes Boxes)',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ];
      },
    ),
  );

  return doc.save();
}
