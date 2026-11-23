import 'dart:collection';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:crackers_erp/core/utils/tamil_transliteration.dart';
import 'package:crackers_erp/domain/models/employee.dart';
import 'package:crackers_erp/ui/features/hr/view_models/payroll_view_model.dart';
import 'package:crackers_erp/ui/features/production/view_models/daily_production_view_model.dart';
import 'package:crackers_erp/ui/features/production/views/daily_production_pdf.dart';

String _rs(num amount) {
  final fmt = NumberFormat('#,##,##0.00', 'en_IN').format(amount);
  return 'Rs. $fmt';
}

String _num(num value) => NumberFormat('#,##,##0', 'en_IN').format(value);

String _deptTitle(String role) {
  final tamil = DailyProductionViewModel.getRoleTamilName(role);
  if (tamil.isNotEmpty) {
    return shapeTamilForPdf('${role.toUpperCase()} • $tamil');
  }
  return shapeTamilForPdf(role.toUpperCase());
}

String _workerLabel(Employee emp) {
  final bilingual = emp.formattedName(WorkerNameDisplayMode.both);
  final suffix = emp.isTemporary ? ' [TEMP]' : '';
  return shapeTamilForPdf('$bilingual$suffix');
}

/// Builds a Landscape A4 Admin Weekly Wage & Payout Report PDF with:
/// - Offline NotoSansTamil font + Tamil vowel-sign shaping
/// - Separate clean tables per department (Tape, Chemical, Valayam Contract, etc.)
/// - Department-scoped WIP product columns in natural numeric order (400/600/700/800 COUNT)
/// - Absent Temporary workers (0 pieces & 0 wages) automatically hidden
/// - Dedicated Signature column for Saturday cash disbursement
Future<Uint8List> buildConsolidatedPayrollPdf(PayrollViewModel vm) async {
  final theme = await loadTamilPdfTheme();
  final doc = pw.Document(theme: theme);
  final periodStr = (vm.startDate != null && vm.endDate != null)
      ? '${DateFormat('EEE, dd MMM yyyy').format(vm.startDate!)} to ${DateFormat('EEE, dd MMM yyyy').format(vm.endDate!)}'
      : (vm.payoutDate != null
            ? DateFormat('EEE, dd MMM yyyy').format(vm.payoutDate!)
            : DateFormat('EEE, dd MMM yyyy').format(DateTime.now()));
  final payoutStr = vm.payoutDate != null
      ? DateFormat('EEE, dd MMM yyyy').format(vm.payoutDate!)
      : DateFormat('EEE, dd MMM yyyy').format(DateTime.now());

  // Order departments canonically (Tape -> Chemical -> Valayam Contract -> others)
  final orderedRoles = SplayTreeMap<String, List<Employee>>(
    DailyProductionViewModel.compareRoles,
  );
  for (final entry in vm.employeesByRole.entries) {
    orderedRoles[entry.key] = List<Employee>.from(entry.value)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  pw.Widget cell(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? color,
    PdfColor? fill,
    double fontSize = 7.5,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      color: fill,
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.grey900,
        ),
      ),
    );
  }

  var grandBasic = 0.0;
  var grandAllowance = 0.0;
  var grandDeduction = 0.0;
  var grandNet = 0.0;
  var grandWorkersCount = 0;

  final departmentWidgets = <pw.Widget>[];

  for (final roleEntry in orderedRoles.entries) {
    final role = roleEntry.key;
    final allEmps = roleEntry.value;

    // Hide absent Temporary workers with 0 pieces and 0 wages/deductions
    final visibleEmps = <Employee>[];
    for (final emp in allEmps) {
      final row = vm.rowFor(emp.id);
      if (row == null) continue;
      final hasQty = row.productQuantities.values.any((q) => q > 0);
      final hasMoney =
          row.basicSalary != 0 ||
          row.allowance != 0 ||
          row.deduction != 0 ||
          row.netSalary != 0;
      if (emp.isTemporary && !hasQty && !hasMoney) {
        continue;
      }
      visibleEmps.add(emp);
    }

    if (visibleEmps.isEmpty) continue;

    // Only include WIP products produced in THIS department (natural numeric order)
    final deptProductSet = <String>{};
    for (final emp in visibleEmps) {
      final row = vm.rowFor(emp.id);
      if (row == null) continue;
      for (final entry in row.productQuantities.entries) {
        if (entry.value > 0) {
          deptProductSet.add(entry.key);
        }
      }
    }
    final deptProducts = deptProductSet.toList()
      ..sort(DailyProductionViewModel.compareNatural);

    var deptBasic = 0.0;
    var deptAllowance = 0.0;
    var deptDeduction = 0.0;
    var deptNet = 0.0;
    final deptProdTotals = <String, int>{};

    final tableRows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          cell('Worker', bold: true),
          cell('Type', bold: true, align: pw.TextAlign.center),
          ...deptProducts.map(
            (p) => cell(
              shapeTamilForPdf(p),
              bold: true,
              align: pw.TextAlign.center,
              fontSize: 7,
            ),
          ),
          cell('Base Wage', bold: true, align: pw.TextAlign.right),
          cell('Allow.', bold: true, align: pw.TextAlign.right),
          cell('Deduct.', bold: true, align: pw.TextAlign.right),
          cell('Net Pay', bold: true, align: pw.TextAlign.right),
          cell('Signature', bold: true, align: pw.TextAlign.center),
        ],
      ),
    ];

    for (final emp in visibleEmps) {
      final r = vm.rowFor(emp.id)!;
      deptBasic += r.basicSalary;
      deptAllowance += r.allowance;
      deptDeduction += r.deduction;
      deptNet += r.netSalary;
      grandWorkersCount++;

      tableRows.add(
        pw.TableRow(
          children: [
            cell(_workerLabel(emp), bold: true),
            cell(
              emp.isContractual ? 'Piece' : 'Monthly',
              align: pw.TextAlign.center,
              fontSize: 7,
            ),
            ...deptProducts.map((p) {
              final q = r.productQuantities[p] ?? 0;
              if (q > 0) {
                deptProdTotals[p] = (deptProdTotals[p] ?? 0) + q;
              }
              return cell(
                q > 0 ? _num(q) : '-',
                align: pw.TextAlign.center,
              );
            }),
            cell(_rs(r.basicSalary), align: pw.TextAlign.right),
            cell(
              r.allowance > 0 ? _rs(r.allowance) : '-',
              align: pw.TextAlign.right,
            ),
            cell(
              r.deduction > 0 ? _rs(r.deduction) : '-',
              align: pw.TextAlign.right,
            ),
            cell(_rs(r.netSalary), bold: true, align: pw.TextAlign.right),
            cell('', align: pw.TextAlign.center),
          ],
        ),
      );
    }

    grandBasic += deptBasic;
    grandAllowance += deptAllowance;
    grandDeduction += deptDeduction;
    grandNet += deptNet;

    tableRows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
        children: [
          cell(
            '${role.toUpperCase()} SUBTOTAL',
            bold: true,
            align: pw.TextAlign.right,
          ),
          cell('${visibleEmps.length}', bold: true, align: pw.TextAlign.center),
          ...deptProducts.map((p) {
            final q = deptProdTotals[p] ?? 0;
            return cell(
              q > 0 ? _num(q) : '-',
              bold: true,
              align: pw.TextAlign.center,
            );
          }),
          cell(_rs(deptBasic), bold: true, align: pw.TextAlign.right),
          cell(_rs(deptAllowance), bold: true, align: pw.TextAlign.right),
          cell(_rs(deptDeduction), bold: true, align: pw.TextAlign.right),
          cell(_rs(deptNet), bold: true, align: pw.TextAlign.right),
          cell(''),
        ],
      ),
    );

    // Give Worker and Signature columns comfortable horizontal room
    final colWidths = <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(2.6), // Worker name
      1: const pw.FlexColumnWidth(0.9), // Type
    };
    for (var i = 0; i < deptProducts.length; i++) {
      colWidths[2 + i] = const pw.FlexColumnWidth(1.1);
    }
    final moneyStart = 2 + deptProducts.length;
    colWidths[moneyStart] = const pw.FlexColumnWidth(1.3); // Base Wage
    colWidths[moneyStart + 1] = const pw.FlexColumnWidth(1.1); // Allow
    colWidths[moneyStart + 2] = const pw.FlexColumnWidth(1.1); // Deduct
    colWidths[moneyStart + 3] = const pw.FlexColumnWidth(1.35); // Net Pay
    colWidths[moneyStart + 4] = const pw.FlexColumnWidth(1.6); // Signature

    departmentWidgets.add(
      pw.Container(
        margin: const pw.EdgeInsets.only(top: 6, bottom: 4),
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: pw.BoxDecoration(
          color: PdfColors.indigo50,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'DEPARTMENT: ${_deptTitle(role)} (${visibleEmps.length} Workers)',
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo900,
              ),
            ),
            pw.Text(
              'Dept Net Payout: ${_rs(deptNet)}',
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo900,
              ),
            ),
          ],
        ),
      ),
    );

    departmentWidgets.add(
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
        columnWidths: colWidths,
        children: tableRows,
      ),
    );
    departmentWidgets.add(pw.SizedBox(height: 8));
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(20),
      header: (ctx) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 10),
        padding: const pw.EdgeInsets.only(bottom: 6),
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
                  'WEEKLY WAGE & PAYROLL DISBURSEMENT REPORT',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey900,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Wage Period: $periodStr  |  Payout Date: $payoutStr',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'GRAND NET PAYOUT: ${_rs(grandNet)}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo900,
                  ),
                ),
                pw.Text(
                  'Workers Included: $grandWorkersCount  |  Admin Confidential',
                  style: const pw.TextStyle(
                    fontSize: 8.5,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      footer: (ctx) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 6),
        padding: const pw.EdgeInsets.only(top: 5),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
          ),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated by Crackers ERP (Admin Only - Confidential)',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
            pw.Text(
              'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
      ),
      build: (ctx) => [
        if (departmentWidgets.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 28),
            child: pw.Center(
              child: pw.Text(
                'No payroll entries to print for this period.',
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          )
        else ...[
          ...departmentWidgets,
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey800,
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'GRAND TOTAL ($grandWorkersCount Workers)',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.Row(
                  children: [
                    pw.Text(
                      'Base: ${_rs(grandBasic)}   ',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      'Allow: ${_rs(grandAllowance)}   ',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      'Deduct: ${_rs(grandDeduction)}   ',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      'NET PAYOUT: ${_rs(grandNet)}',
                      style: pw.TextStyle(
                        fontSize: 10.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.amber200,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );

  return doc.save();
}
