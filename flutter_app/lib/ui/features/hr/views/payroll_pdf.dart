import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:crackers_erp/core/utils/tamil_transliteration.dart';
import 'package:crackers_erp/domain/models/employee.dart';
import 'package:crackers_erp/domain/models/json_helpers.dart';
import 'package:crackers_erp/domain/models/payroll.dart';
import 'package:crackers_erp/ui/features/hr/view_models/payroll_view_model.dart';
import 'package:crackers_erp/ui/features/production/view_models/daily_production_view_model.dart';
import 'package:crackers_erp/ui/features/production/views/daily_production_pdf.dart';

String _amt(num amount) => amount.toStringAsFixed(2);

String _qty(num value) => NumberFormat('#,##0', 'en_IN').format(value);

String _workerHeaderLabel(Employee emp) {
  final bilingual = emp.formattedName(WorkerNameDisplayMode.both);
  final role = emp.roleGroup;
  final tempTag = emp.isTemporary ? ' [TEMP]' : '';
  return shapeTamilForPdf('$bilingual ($role)$tempTag');
}

/// Builds the Landscape A4 **WAGES ITEMIZED REPORT** matching Arunachala Agencies'
/// weekly ledger layout:
/// - Columns: `#` | `Employee name / Product name` | `Day 1..Day 7` |
///   `Wages / Qty` | `Deduct / Rate/Per` | `Amount / Amount` | `Signature`
/// - When [showItemRates] is `false` (Standard Payout Sheet): product rows show
///   daily quantities and weekly Qty only, keeping Rate/Per & line Amount blank.
/// - When [showItemRates] is `true` (Detailed Audit Sheet): product rows also
///   show each item's Rate/Per and rupee Amount subtotal.
/// - Offline NotoSansTamil font + Tamil vowel-sign shaping; keeps each worker's
///   rows together on one page; auto-hides absent Temporary workers.
Future<Uint8List> buildConsolidatedPayrollPdf(
  PayrollViewModel vm, {
  bool showItemRates = false,
  String companyName = 'ARUNACHALA AGENCIES',
}) async {
  final theme = await loadTamilPdfTheme();
  final doc = pw.Document(theme: theme);

  // Build exact date columns from startDate..endDate (up to 7-10 days; default 7-day cycle)
  final DateTime rangeEnd = vm.endDate ?? vm.payoutDate ?? DateTime.now();
  final DateTime rangeStart =
      vm.startDate ?? rangeEnd.subtract(const Duration(days: 6));
  final startOnly = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
  final endOnly = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);

  final dates = <DateTime>[];
  var cursor = startOnly;
  while (!cursor.isAfter(endOnly) && dates.length < 10) {
    dates.add(cursor);
    cursor = cursor.add(const Duration(days: 1));
  }
  if (dates.isEmpty) {
    dates.add(startOnly);
  }
  final isoDates = dates.map(toIsoCalendarDate).toList();

  final fromStr = DateFormat('dd-MM-yyyy').format(startOnly);
  final toStr = DateFormat('dd-MM-yyyy').format(endOnly);
  final reportTitle = showItemRates
      ? 'WAGES ITEMIZED REPORT (WITH ITEM RATES) FROM $fromStr - TO $toStr'
      : 'WAGES ITEMIZED REPORT FROM $fromStr - TO $toStr';

  // Sort employees canonically by department then name; filter out absent temp workers
  final visibleRows = <({Employee emp, PayrollWorksheetRow row})>[];
  final sortedEmps = List<Employee>.from(vm.employees)
    ..sort((a, b) {
      final roleCmp = DailyProductionViewModel.compareRoles(
        a.roleGroup,
        b.roleGroup,
      );
      if (roleCmp != 0) return roleCmp;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

  for (final emp in sortedEmps) {
    final row = vm.rowFor(emp.id);
    if (row == null) continue;
    final hasQty =
        row.productQuantities.values.any((q) => q > 0) ||
        row.dailyLogs.any((d) => d.items.any((i) => i.quantity > 0));
    final hasMoney =
        row.basicSalary != 0 ||
        row.allowance != 0 ||
        row.deduction != 0 ||
        row.netSalary != 0;
    if (emp.isTemporary && !hasQty && !hasMoney) continue;
    visibleRows.add((emp: emp, row: row));
  }

  // Fixed proportional column widths shared by header, every worker block, and grand total
  final colWidths = <int, pw.TableColumnWidth>{
    0: const pw.FixedColumnWidth(24), // Serial #
    1: const pw.FlexColumnWidth(3.0), // Employee / Product name
  };
  for (var i = 0; i < dates.length; i++) {
    colWidths[2 + i] = const pw.FixedColumnWidth(42);
  }
  final summaryStart = 2 + dates.length;
  colWidths[summaryStart] = const pw.FixedColumnWidth(58); // Wages / Qty
  colWidths[summaryStart + 1] = const pw.FixedColumnWidth(56); // Deduct / Rate
  colWidths[summaryStart + 2] = const pw.FixedColumnWidth(62); // Amount
  colWidths[summaryStart + 3] = const pw.FlexColumnWidth(1.55); // Signature

  const gridBorder = pw.BorderSide(color: PdfColors.grey600, width: 0.6);
  const innerLine = pw.BorderSide(color: PdfColors.grey400, width: 0.4);

  pw.Widget cell(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
    double fontSize = 8,
    PdfColor? color,
    pw.EdgeInsets padding = const pw.EdgeInsets.symmetric(
      horizontal: 4,
      vertical: 2.5,
    ),
  }) {
    return pw.Padding(
      padding: padding,
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }

  pw.Widget buildTableHeader() {
    return pw.Table(
      columnWidths: colWidths,
      border: const pw.TableBorder(
        top: gridBorder,
        bottom: gridBorder,
        left: gridBorder,
        right: gridBorder,
        verticalInside: gridBorder,
      ),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            cell('', bold: true, align: pw.TextAlign.center),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Employee name',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Product name',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
              ),
            ),
            ...dates.map(
              (d) => cell(
                DateFormat('dd-MM').format(d),
                bold: true,
                align: pw.TextAlign.center,
                fontSize: 8,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Wages',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Qty',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Deduct',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Rate/Per',
                    style: const pw.TextStyle(
                      fontSize: 7.5,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Amount',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Amount',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
              ),
            ),
            cell(
              'Signature',
              bold: true,
              align: pw.TextAlign.center,
              fontSize: 8.5,
            ),
          ],
        ),
      ],
    );
  }

  var grandWages = 0.0;
  var grandDeduction = 0.0;
  var grandNet = 0.0;

  final workerBlocks = <pw.Widget>[];

  for (var idx = 0; idx < visibleRows.length; idx++) {
    final entry = visibleRows[idx];
    final emp = entry.emp;
    final row = entry.row;
    final serialNo = idx + 1;

    final totalWages = double.parse(
      (row.basicSalary + row.allowance).toStringAsFixed(2),
    );
    grandWages += totalWages;
    grandDeduction += row.deduction;
    grandNet += row.netSalary;

    // Build per-product breakdown across dates from dailyLogs (or fallback to productQuantities)
    final itemDayQtys = <String, Map<String, int>>{};
    final itemWeekQty = <String, int>{};
    final itemWeekAmount = <String, double>{};
    final itemRate = <String, double>{};

    for (final dayLog in row.dailyLogs) {
      for (final item in dayLog.items) {
        if (item.quantity <= 0 || item.itemName.trim().isEmpty) continue;
        final name = item.itemName.trim();
        final dayMap = itemDayQtys.putIfAbsent(name, () => <String, int>{});
        dayMap[dayLog.isoDate] = (dayMap[dayLog.isoDate] ?? 0) + item.quantity;
        itemWeekQty[name] = (itemWeekQty[name] ?? 0) + item.quantity;
        itemWeekAmount[name] = (itemWeekAmount[name] ?? 0.0) + item.total;
        if (item.pieceRate > 0) {
          itemRate[name] = item.pieceRate;
        }
      }
    }

    // Fallback if productQuantities has entries without dailyLogs
    for (final pq in row.productQuantities.entries) {
      if (pq.value > 0 && !itemWeekQty.containsKey(pq.key)) {
        itemWeekQty[pq.key] = pq.value;
        itemDayQtys[pq.key] = <String, int>{};
      }
    }

    final sortedItems = itemWeekQty.keys.toList()
      ..sort(DailyProductionViewModel.compareNatural);

    final blockRows = <pw.TableRow>[
      // Bold Employee Summary Row
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: innerLine),
        ),
        children: [
          cell(
            '$serialNo',
            bold: true,
            align: pw.TextAlign.center,
            fontSize: 8.5,
            padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          ),
          cell(
            _workerHeaderLabel(emp),
            bold: true,
            fontSize: 8.5,
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          ),
          for (var i = 0; i < dates.length; i++) cell(''),
          cell(
            _amt(totalWages),
            bold: true,
            align: pw.TextAlign.right,
            fontSize: 8.5,
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          ),
          cell(
            _amt(row.deduction),
            bold: true,
            align: pw.TextAlign.right,
            fontSize: 8.5,
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          ),
          cell(
            _amt(row.netSalary),
            bold: true,
            align: pw.TextAlign.right,
            fontSize: 8.5,
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          ),
          cell(''),
        ],
      ),
    ];

    if (sortedItems.isEmpty && !emp.isContractual) {
      blockRows.add(
        pw.TableRow(
          children: [
            cell(''),
            cell(
              row.allowance > 0
                  ? 'Monthly Salary (+ Allow. ${_amt(row.allowance)})'
                  : 'Monthly Salary',
              fontSize: 7.5,
              color: PdfColors.grey700,
              padding: const pw.EdgeInsets.fromLTRB(10, 2, 4, 3),
            ),
            for (var i = 0; i < dates.length; i++) cell(''),
            cell(''),
            cell(''),
            cell(''),
            cell(''),
          ],
        ),
      );
    }

    for (final itemName in sortedItems) {
      final dayMap = itemDayQtys[itemName] ?? const <String, int>{};
      final weekQ = itemWeekQty[itemName] ?? 0;
      final weekAmt = itemWeekAmount[itemName] ?? 0.0;
      final rateVal = itemRate[itemName] ?? (weekQ > 0 ? weekAmt / weekQ : 0.0);

      blockRows.add(
        pw.TableRow(
          children: [
            cell(''),
            cell(
              shapeTamilForPdf(itemName),
              fontSize: 8,
              padding: const pw.EdgeInsets.fromLTRB(10, 2, 4, 2),
            ),
            ...isoDates.map((iso) {
              final q = dayMap[iso] ?? 0;
              return cell(
                q > 0 ? _qty(q) : '',
                align: pw.TextAlign.center,
                fontSize: 8,
              );
            }),
            cell(
              weekQ > 0 ? _qty(weekQ) : '',
              align: pw.TextAlign.right,
              fontSize: 8,
            ),
            cell(
              showItemRates && rateVal > 0 ? _amt(rateVal) : '',
              align: pw.TextAlign.right,
              fontSize: 7.5,
              color: PdfColors.grey800,
            ),
            cell(
              showItemRates && weekAmt > 0 ? _amt(weekAmt) : '',
              align: pw.TextAlign.right,
              fontSize: 7.5,
              color: PdfColors.grey800,
            ),
            cell(''),
          ],
        ),
      );
    }

    // Also note allowance line if worker has both pieces and extra allowance
    if (sortedItems.isNotEmpty && row.allowance > 0) {
      blockRows.add(
        pw.TableRow(
          children: [
            cell(''),
            cell(
              'Allowance / Bonus',
              fontSize: 7.5,
              color: PdfColors.grey700,
              padding: const pw.EdgeInsets.fromLTRB(10, 1.5, 4, 2),
            ),
            for (var i = 0; i < dates.length; i++) cell(''),
            cell(''),
            cell(''),
            cell(
              showItemRates ? _amt(row.allowance) : '',
              align: pw.TextAlign.right,
              fontSize: 7.5,
              color: PdfColors.grey700,
            ),
            cell(''),
          ],
        ),
      );
    }

    // Wrap each employee block so a worker never splits awkwardly across two pages
    workerBlocks.add(
      pw.Table(
        columnWidths: colWidths,
        border: const pw.TableBorder(
          bottom: gridBorder,
          left: gridBorder,
          right: gridBorder,
          verticalInside: gridBorder,
        ),
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: blockRows,
      ),
    );
  }

  final grandTotalTable = pw.Table(
    columnWidths: colWidths,
    border: const pw.TableBorder(
      top: gridBorder,
      bottom: gridBorder,
      left: gridBorder,
      right: gridBorder,
      verticalInside: gridBorder,
    ),
    defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
        children: [
          cell(''),
          cell(
            'Total (${visibleRows.length} Workers)',
            bold: true,
            fontSize: 9,
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          ),
          for (var i = 0; i < dates.length; i++) cell(''),
          cell(
            _amt(grandWages),
            bold: true,
            align: pw.TextAlign.right,
            fontSize: 9,
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          ),
          cell(
            _amt(grandDeduction),
            bold: true,
            align: pw.TextAlign.right,
            fontSize: 9,
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          ),
          cell(
            _amt(grandNet),
            bold: true,
            align: pw.TextAlign.right,
            fontSize: 9,
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          ),
          cell(''),
        ],
      ),
    ],
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.fromLTRB(18, 18, 18, 22),
      header: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Center(
            child: pw.Text(
              companyName.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 12.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Center(
            child: pw.Text(
              reportTitle,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
          ),
          pw.SizedBox(height: 6),
          buildTableHeader(),
        ],
      ),
      footer: (ctx) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 6),
        child: pw.Center(
          child: pw.Text(
            'Page ${ctx.pageNumber}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
          ),
        ),
      ),
      build: (ctx) => [
        if (workerBlocks.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 28),
            child: pw.Center(
              child: pw.Text(
                'No payroll entries to print for this period.',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          )
        else ...[
          ...workerBlocks,
          grandTotalTable,
        ],
      ],
    ),
  );

  return doc.save();
}
