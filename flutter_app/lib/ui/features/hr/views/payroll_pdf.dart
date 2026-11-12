import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:crackers_erp/ui/features/hr/view_models/payroll_view_model.dart';

String _rs(num amount) {
  final fmt = NumberFormat('#,##,##0.00', 'en_IN').format(amount);
  return 'Rs. $fmt';
}

Future<Uint8List> buildConsolidatedPayrollPdf(PayrollViewModel vm) async {
  final doc = pw.Document();
  final periodStr = (vm.startDate != null && vm.endDate != null)
      ? '${DateFormat('dd MMM yyyy').format(vm.startDate!)} to ${DateFormat('dd MMM yyyy').format(vm.endDate!)}'
      : (vm.payoutDate != null
            ? DateFormat('dd MMM yyyy').format(vm.payoutDate!)
            : DateFormat('dd MMM yyyy').format(DateTime.now()));

  final rolesMap = vm.employeesByRole;
  final products = vm.uniqueProducts;
  final grand = vm.grandTotals;

  pw.Widget cell(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? color,
    PdfColor? fill,
    double fontSize = 8,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
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

  final rows = <pw.TableRow>[
    pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        cell('Employee', bold: true),
        cell('Type', bold: true, align: pw.TextAlign.center),
        ...products.map(
          (p) => cell(p, bold: true, align: pw.TextAlign.center, fontSize: 7),
        ),
        cell('Base Wage', bold: true, align: pw.TextAlign.right),
        cell('Allowances', bold: true, align: pw.TextAlign.right),
        cell('Deductions', bold: true, align: pw.TextAlign.right),
        cell('Net Salary', bold: true, align: pw.TextAlign.right),
        cell('Status', bold: true, align: pw.TextAlign.center),
      ],
    ),
  ];

  final totalCols = 7 + products.length;

  for (final roleEntry in rolesMap.entries) {
    final role = roleEntry.key;
    final emps = roleEntry.value;
    final roleTotals = vm.totalsForRole(role);

    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.indigo50),
        children: [
          cell(role.toUpperCase(), bold: true, color: PdfColors.indigo900),
          for (var i = 1; i < totalCols; i++) cell(''),
        ],
      ),
    );

    for (final emp in emps) {
      final r = vm.rowFor(emp.id);
      if (r == null) continue;
      rows.add(
        pw.TableRow(
          children: [
            cell(emp.name, bold: true),
            cell(emp.paymentType, align: pw.TextAlign.center, fontSize: 7),
            ...products.map((p) {
              final q = r.productQuantities[p] ?? 0;
              return cell(
                q > 0 ? '$q' : '-',
                align: pw.TextAlign.center,
              );
            }),
            cell(_rs(r.basicSalary), align: pw.TextAlign.right),
            cell(_rs(r.allowance), align: pw.TextAlign.right),
            cell(_rs(r.deduction), align: pw.TextAlign.right),
            cell(_rs(r.netSalary), bold: true, align: pw.TextAlign.right),
            cell(r.status, align: pw.TextAlign.center),
          ],
        ),
      );
    }

    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
        children: [
          cell('$role TOTAL', bold: true, align: pw.TextAlign.right),
          cell(''),
          ...products.map((p) {
            final q = roleTotals.productTotals[p] ?? 0;
            return cell(
              q > 0 ? '$q' : '-',
              bold: true,
              align: pw.TextAlign.center,
            );
          }),
          cell(_rs(roleTotals.basic), bold: true, align: pw.TextAlign.right),
          cell(_rs(roleTotals.allowance), bold: true, align: pw.TextAlign.right),
          cell(_rs(roleTotals.deduction), bold: true, align: pw.TextAlign.right),
          cell(_rs(roleTotals.net), bold: true, align: pw.TextAlign.right),
          cell(''),
        ],
      ),
    );
  }

  rows.add(
    pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey800),
      children: [
        cell('GRAND TOTAL', bold: true, color: PdfColors.white, align: pw.TextAlign.right),
        cell('', color: PdfColors.white),
        ...products.map((p) {
          final q = grand.productTotals[p] ?? 0;
          return cell(
            q > 0 ? '$q' : '-',
            bold: true,
            color: PdfColors.white,
            align: pw.TextAlign.center,
          );
        }),
        cell(_rs(grand.basic), bold: true, color: PdfColors.white, align: pw.TextAlign.right),
        cell(_rs(grand.allowance), bold: true, color: PdfColors.white, align: pw.TextAlign.right),
        cell(_rs(grand.deduction), bold: true, color: PdfColors.white, align: pw.TextAlign.right),
        cell(_rs(grand.net), bold: true, color: PdfColors.white, align: pw.TextAlign.right),
        cell('', color: PdfColors.white),
      ],
    ),
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(20),
      header: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'CONSOLIDATED PAYROLL',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'Period: $periodStr',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 10),
        ],
      ),
      build: (context) => [
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.6),
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: rows,
        ),
      ],
    ),
  );

  return doc.save();
}

