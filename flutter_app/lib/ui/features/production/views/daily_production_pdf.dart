import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:crackers_erp/core/utils/tamil_transliteration.dart';
import '../view_models/daily_production_view_model.dart';

/// Builds a clean printable daily production sheet without any wage/rupee information.
Future<Uint8List> buildDailyProductionPdf(DailyProductionViewModel vm) async {
  final doc = pw.Document();
  final dateStr = DateFormat('EEE, dd MMM yyyy').format(vm.selectedDate);
  final groupedRoles = vm.filteredWorkersByRole;

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      header: (context) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.8),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'DAILY PRODUCTION WORKSHEET',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey900,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Date: $dateStr  |  Generated from Crackers ERP',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total Pieces: ${NumberFormat('#,##,##0').format(vm.totalPiecesEntered)}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey900,
                    ),
                  ),
                  pw.Text(
                    'Workers Logged: ${vm.activeWorkersLoggedCount} / ${vm.activeWorkers.length}',
                    style: const pw.TextStyle(
                      fontSize: 9.5,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      footer: (context) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(top: 8),
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                'Confidential - Factory Floor Production Copy (No Rates)',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
        );
      },
      build: (context) {
        final content = <pw.Widget>[];

        for (final roleEntry in groupedRoles.entries) {
          final role = roleEntry.key;
          final workers = roleEntry.value;
          final roleItems = vm.getActiveItemsForRole(role);
          final roleTotal = vm.getRoleTotalQuantity(role);

          if (roleItems.isEmpty) continue;

          content.add(
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 8, bottom: 4),
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'DEPARTMENT: ${role.toUpperCase()} (${workers.length} Workers)',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.Text(
                    'Dept Total: ${NumberFormat('#,##,##0').format(roleTotal)} Pcs',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
              ),
            ),
          );

          // Table of workers & items
          final tableHeaders = [
            'Worker',
            ...roleItems,
            'Total Pcs',
          ];

          final tableRows = <List<String>>[];
          for (final emp in workers) {
            final empEntries = vm.getWorkerEntries(emp.id);
            final empTotal = vm.getWorkerTotalQuantity(emp.id);
            final row = <String>[
              emp.formattedName(WorkerNameDisplayMode.both),
              ...roleItems.map((item) {
                final qty = empEntries[item] ?? 0;
                return qty > 0 ? NumberFormat('#,##,##0').format(qty) : '-';
              }),
              empTotal > 0 ? NumberFormat('#,##,##0').format(empTotal) : '0',
            ];
            tableRows.add(row);
          }

          // Summary row for column totals
          final colTotalsRow = <String>[
            'Subtotal',
            ...roleItems.map((item) {
              var sum = 0;
              for (final emp in workers) {
                sum += vm.getQuantity(emp.id, item);
              }
              return sum > 0 ? NumberFormat('#,##,##0').format(sum) : '-';
            }),
            NumberFormat('#,##,##0').format(roleTotal),
          ];
          tableRows.add(colTotalsRow);

          content.add(
            pw.TableHelper.fromTextArray(
              headers: tableHeaders,
              data: tableRows,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey900,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.center,
              cellAlignments: {0: pw.Alignment.centerLeft},
              headerAlignment: pw.Alignment.center,
              headerAlignments: {0: pw.Alignment.centerLeft},
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            ),
          );

          // Add Subtotal banner
          content.add(
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border(
                  left: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  right: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'SUBTOTAL ${role.toUpperCase()}',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.Text(
                    '${NumberFormat('#,##,##0').format(roleTotal)} Pcs',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey900,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return content;
      },
    ),
  );

  return doc.save();
}

