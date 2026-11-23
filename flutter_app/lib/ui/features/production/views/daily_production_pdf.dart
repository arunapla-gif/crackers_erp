import 'dart:collection';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:crackers_erp/core/utils/tamil_transliteration.dart';
import 'package:crackers_erp/domain/models/daily_production.dart';
import 'package:crackers_erp/domain/models/employee.dart';
import 'package:crackers_erp/domain/models/json_helpers.dart';
import '../view_models/daily_production_view_model.dart';

pw.Font? _cachedTamilRegular;
pw.Font? _cachedTamilBold;

/// Loads bundled NotoSansTamil fonts so Tamil worker & department names render
/// cleanly in offline PDFs on both Android and Web.
Future<pw.ThemeData> loadTamilPdfTheme() async {
  if (_cachedTamilRegular == null) {
    try {
      final regData = await rootBundle.load(
        'assets/fonts/NotoSansTamil-Regular.ttf',
      );
      _cachedTamilRegular = pw.Font.ttf(regData);
    } catch (_) {
      _cachedTamilRegular = null;
    }
  }
  if (_cachedTamilBold == null) {
    try {
      final boldData = await rootBundle.load(
        'assets/fonts/NotoSansTamil-Bold.ttf',
      );
      _cachedTamilBold = pw.Font.ttf(boldData);
    } catch (_) {
      _cachedTamilBold = _cachedTamilRegular;
    }
  }

  final baseFont = _cachedTamilRegular ?? pw.Font.helvetica();
  final boldFont =
      _cachedTamilBold ?? _cachedTamilRegular ?? pw.Font.helveticaBold();

  return pw.ThemeData.withFont(
    base: baseFont,
    bold: boldFont,
    fontFallback: [pw.Font.helvetica()],
  );
}

bool _isTamilConsonant(int codeUnit) =>
    codeUnit >= 0x0B95 && codeUnit <= 0x0BB9;

/// Visually reorders Tamil pre-base (`ெ`, `ே`, `ை`) and split (`ொ`, `ோ`, `ௌ`)
/// vowel signs for `package:pdf`, which lays out glyphs left-to-right without
/// HarfBuzz complex script shaping.
String shapeTamilForPdf(String input) {
  if (input.isEmpty) return input;
  final runes = input.codeUnits;
  final out = StringBuffer();
  var i = 0;

  while (i < runes.length) {
    final c = runes[i];
    if (_isTamilConsonant(c)) {
      // Check for க்ஷ (U+0B95 + U+0BCD + U+0BB7) conjunct
      var clusterEnd = i + 1;
      if (c == 0x0B95 &&
          i + 2 < runes.length &&
          runes[i + 1] == 0x0BCD &&
          runes[i + 2] == 0x0BB7) {
        clusterEnd = i + 3;
      }

      final cluster = String.fromCharCodes(runes.sublist(i, clusterEnd));
      if (clusterEnd < runes.length) {
        final next = runes[clusterEnd];
        // Pre-base single signs: ெ (0BC6), ே (0BC7), ை (0BC8)
        if (next == 0x0BC6 || next == 0x0BC7 || next == 0x0BC8) {
          out.writeCharCode(next);
          out.write(cluster);
          i = clusterEnd + 1;
          continue;
        }
        // Split signs: ொ (0BCA) -> ெ + C + ா, ோ (0BCB) -> ே + C + ா, ௌ (0BCC) -> ெ + C + ௗ
        if (next == 0x0BCA) {
          out.writeCharCode(0x0BC6);
          out.write(cluster);
          out.writeCharCode(0x0BBE);
          i = clusterEnd + 1;
          continue;
        }
        if (next == 0x0BCB) {
          out.writeCharCode(0x0BC7);
          out.write(cluster);
          out.writeCharCode(0x0BBE);
          i = clusterEnd + 1;
          continue;
        }
        if (next == 0x0BCC) {
          out.writeCharCode(0x0BC6);
          out.write(cluster);
          out.writeCharCode(0x0BD7);
          i = clusterEnd + 1;
          continue;
        }
      }

      out.write(cluster);
      i = clusterEnd;
    } else {
      out.writeCharCode(c);
      i++;
    }
  }

  return out.toString();
}

String _formatPdfItemHeader(DailyProductionViewModel vm, String itemName) {
  final prod = vm.findWipProductByName(itemName);
  final sub = (prod?.subCategory ?? '').trim();
  if (sub.isNotEmpty) {
    return shapeTamilForPdf('$sub\n$itemName');
  }
  return shapeTamilForPdf(itemName);
}

String _formatPdfDepartmentTitle(String role) {
  final tamil = DailyProductionViewModel.getRoleTamilName(role);
  if (tamil.isNotEmpty) {
    return shapeTamilForPdf('${role.toUpperCase()} • $tamil');
  }
  return shapeTamilForPdf(role.toUpperCase());
}

String _formatPdfWorkerName(Employee emp) {
  final formatted = emp.formattedName(WorkerNameDisplayMode.both);
  final suffix = emp.isTemporary ? ' [TEMP]' : '';
  return shapeTamilForPdf('$formatted$suffix');
}

/// Builds a clean printable daily production sheet without any wage/rupee information.
Future<Uint8List> buildDailyProductionPdf(DailyProductionViewModel vm) async {
  final theme = await loadTamilPdfTheme();
  final doc = pw.Document(theme: theme);
  final dateStr = DateFormat('EEE, dd MMM yyyy').format(vm.selectedDate);
  final groupedRoles = vm.filteredWorkersByRole;
  final numFmt = NumberFormat('#,##,##0', 'en_IN');

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
                    'Total Pieces: ${numFmt.format(vm.totalPiecesEntered)}',
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
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'Confidential - Factory Floor Production Copy (No Rates)',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
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
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'DEPARTMENT: ${_formatPdfDepartmentTitle(role)} (${workers.length} Workers)',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.Text(
                    'Dept Total: ${numFmt.format(roleTotal)} Pcs',
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

          final tableHeaders = [
            'Worker',
            ...roleItems.map((item) => _formatPdfItemHeader(vm, item)),
            'Total Pcs',
          ];

          final tableRows = <List<String>>[];
          for (final emp in workers) {
            final empEntries = vm.getWorkerEntries(emp.id);
            final empTotal = vm.getWorkerTotalQuantity(emp.id);
            final row = <String>[
              _formatPdfWorkerName(emp),
              ...roleItems.map((item) {
                final qty = empEntries[item] ?? 0;
                return qty > 0 ? numFmt.format(qty) : '-';
              }),
              empTotal > 0 ? numFmt.format(empTotal) : '0',
            ];
            tableRows.add(row);
          }

          final colTotalsRow = <String>[
            'Subtotal',
            ...roleItems.map((item) {
              var sum = 0;
              for (final emp in workers) {
                sum += vm.getQuantity(emp.id, item);
              }
              return sum > 0 ? numFmt.format(sum) : '-';
            }),
            numFmt.format(roleTotal),
          ];
          tableRows.add(colTotalsRow);

          content.add(
            pw.TableHelper.fromTextArray(
              headers: tableHeaders,
              data: tableRows,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey900,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.center,
              cellAlignments: {0: pw.Alignment.centerLeft},
              headerAlignment: pw.Alignment.center,
              headerAlignments: {0: pw.Alignment.centerLeft},
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 3,
              ),
            ),
          );

          content.add(
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 3,
              ),
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
                    '${numFmt.format(roleTotal)} Pcs',
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

        if (content.isEmpty) {
          content.add(
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 24),
              child: pw.Center(
                child: pw.Text(
                  'No WIP items selected or logged for $dateStr.',
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey600,
                  ),
                ),
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

/// Builds a Landscape A4 Weekly Production Summary PDF (zero-rupee safe)
/// with Tamil names, Day-by-Day worker totals, and Item-Wise weekly breakdown
/// in strict sub-category order (400 / 600 / 700 / 800 COUNT).
Future<Uint8List> buildWeeklyProductionPdf({
  required DailyProductionViewModel vm,
  required DateTime startDate,
  required DateTime endDate,
  required List<DailyProductionRecord> records,
}) async {
  final theme = await loadTamilPdfTheme();
  final doc = pw.Document(theme: theme);
  final numFmt = NumberFormat('#,##,##0', 'en_IN');

  final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
  final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
  final dates = <DateTime>[];
  var cursor = startOnly;
  while (!cursor.isAfter(endOnly) && dates.length < 14) {
    dates.add(cursor);
    cursor = cursor.add(const Duration(days: 1));
  }
  final isoDates = dates.map(toIsoCalendarDate).toList();

  final employeeById = <int, Employee>{
    for (final emp in vm.employees) emp.id: emp,
  };

  // Aggregate: empId -> isoDate -> qty, and empId -> itemName -> qty
  final dayTotalsByEmp = <int, Map<String, int>>{};
  final itemTotalsByEmp = <int, Map<String, int>>{};
  final workerInfoById = <int, ({String name, String role, bool isTemp})>{};
  var grandTotalPieces = 0;

  for (final rec in records) {
    final recDate = rec.isoDate;
    if (!isoDates.contains(recDate)) continue;
    final emp = employeeById[rec.employeeId];
    final role = emp?.roleGroup ??
        ((rec.employeeRole == null || rec.employeeRole!.trim().isEmpty)
            ? 'Unassigned'
            : rec.employeeRole!.trim());
    final displayName = emp != null
        ? _formatPdfWorkerName(emp)
        : shapeTamilForPdf(
            TamilTransliteration.formatForDisplay(
              rec.employeeName,
              mode: WorkerNameDisplayMode.both,
            ),
          );

    workerInfoById[rec.employeeId] = (
      name: displayName,
      role: role,
      isTemp: emp?.isTemporary ?? false,
    );

    final dayMap = dayTotalsByEmp.putIfAbsent(
      rec.employeeId,
      () => <String, int>{},
    );
    final itemMap = itemTotalsByEmp.putIfAbsent(
      rec.employeeId,
      () => <String, int>{},
    );

    for (final item in rec.items) {
      if (item.quantity <= 0 || item.itemName.trim().isEmpty) continue;
      dayMap[recDate] = (dayMap[recDate] ?? 0) + item.quantity;
      itemMap[item.itemName] = (itemMap[item.itemName] ?? 0) + item.quantity;
      grandTotalPieces += item.quantity;
    }
  }

  // Group worker IDs by department in canonical factory order
  final workersByRole = SplayTreeMap<String, List<int>>(
    DailyProductionViewModel.compareRoles,
  );
  for (final entry in workerInfoById.entries) {
    final totalForEmp = (dayTotalsByEmp[entry.key]?.values ?? const <int>[])
        .fold(0, (sum, q) => sum + q);
    if (totalForEmp <= 0) continue;
    workersByRole.putIfAbsent(entry.value.role, () => <int>[]).add(entry.key);
  }
  for (final list in workersByRole.values) {
    list.sort((a, b) {
      final nameA = employeeById[a]?.name ?? workerInfoById[a]!.name;
      final nameB = employeeById[b]?.name ?? workerInfoById[b]!.name;
      return nameA.toLowerCase().compareTo(nameB.toLowerCase());
    });
  }

  final periodLabel =
      '${DateFormat('EEE, dd MMM yyyy').format(startOnly)}  to  ${DateFormat('EEE, dd MMM yyyy').format(endOnly)}';
  final totalWorkersActive = workersByRole.values.fold<int>(
    0,
    (sum, list) => sum + list.length,
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(20),
      header: (context) {
        return pw.Container(
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
                    'WEEKLY PRODUCTION SUMMARY',
                    style: pw.TextStyle(
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey900,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Period: $periodLabel  |  Generated from Crackers ERP',
                    style: const pw.TextStyle(
                      fontSize: 9.5,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total Week Output: ${numFmt.format(grandTotalPieces)} Pcs',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey900,
                    ),
                  ),
                  pw.Text(
                    'Workers Active: $totalWorkersActive  |  Days: ${dates.length}',
                    style: const pw.TextStyle(
                      fontSize: 9,
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
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'Confidential - Factory Floor Weekly Summary (No Rates)',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        );
      },
      build: (context) {
        final content = <pw.Widget>[];

        if (workersByRole.isEmpty) {
          content.add(
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 28),
              child: pw.Center(
                child: pw.Text(
                  'No production records found for $periodLabel.',
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ),
          );
          return content;
        }

        for (final roleEntry in workersByRole.entries) {
          final role = roleEntry.key;
          final empIds = roleEntry.value;

          var deptTotal = 0;
          final roleItemSet = <String>{};
          for (final empId in empIds) {
            final items = itemTotalsByEmp[empId] ?? const <String, int>{};
            for (final entry in items.entries) {
              if (entry.value > 0) {
                roleItemSet.add(entry.key);
                deptTotal += entry.value;
              }
            }
          }
          final sortedRoleItems = roleItemSet.toList();
          vm.sortItemNamesByCategoryOrder(sortedRoleItems);

          // Department Header Banner
          content.add(
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 8, bottom: 4),
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'DEPARTMENT: ${_formatPdfDepartmentTitle(role)} (${empIds.length} Workers)',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey900,
                    ),
                  ),
                  pw.Text(
                    'Dept Week Total: ${numFmt.format(deptTotal)} Pcs',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey900,
                    ),
                  ),
                ],
              ),
            ),
          );

          // 1) DAY-BY-DAY SUMMARY TABLE
          content.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2, bottom: 3),
              child: pw.Text(
                '1) Day-by-Day Attendance & Output',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          );

          final dayHeaders = <String>[
            'Worker',
            ...dates.map((d) => DateFormat('EEE\ndd').format(d)),
            'Days',
            'Week Total',
          ];

          final dayRows = <List<String>>[];
          final dayColumnSums = List<int>.filled(isoDates.length, 0);

          for (final empId in empIds) {
            final info = workerInfoById[empId]!;
            final dayMap = dayTotalsByEmp[empId] ?? const <String, int>{};
            var empWeekTotal = 0;
            var daysWorked = 0;
            final dayCells = <String>[];

            for (var i = 0; i < isoDates.length; i++) {
              final qty = dayMap[isoDates[i]] ?? 0;
              if (qty > 0) {
                daysWorked++;
                empWeekTotal += qty;
                dayColumnSums[i] += qty;
                dayCells.add(numFmt.format(qty));
              } else {
                dayCells.add('-');
              }
            }

            dayRows.add([
              info.name,
              ...dayCells,
              '$daysWorked',
              numFmt.format(empWeekTotal),
            ]);
          }

          dayRows.add([
            'DAY TOTAL',
            ...dayColumnSums.map((s) => s > 0 ? numFmt.format(s) : '-'),
            '',
            numFmt.format(deptTotal),
          ]);

          content.add(
            pw.TableHelper.fromTextArray(
              headers: dayHeaders,
              data: dayRows,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey900,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
              ),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              cellAlignment: pw.Alignment.center,
              cellAlignments: {0: pw.Alignment.centerLeft},
              headerAlignment: pw.Alignment.center,
              headerAlignments: {0: pw.Alignment.centerLeft},
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 3,
              ),
            ),
          );

          // 2) ITEM-WISE WEEKLY BREAKDOWN TABLE (400 / 600 / 700 / 800 COUNT order)
          if (sortedRoleItems.isNotEmpty) {
            content.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 8, bottom: 3),
                child: pw.Text(
                  '2) Item-Wise Weekly Breakdown (Sub-Category Order)',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            );

            final itemHeaders = <String>[
              'Worker',
              ...sortedRoleItems.map(
                (item) => _formatPdfItemHeader(vm, item),
              ),
              'Week Total',
            ];

            final itemRows = <List<String>>[];
            final itemColumnSums = List<int>.filled(sortedRoleItems.length, 0);

            for (final empId in empIds) {
              final info = workerInfoById[empId]!;
              final items = itemTotalsByEmp[empId] ?? const <String, int>{};
              var empTotal = 0;
              final itemCells = <String>[];

              for (var i = 0; i < sortedRoleItems.length; i++) {
                final qty = items[sortedRoleItems[i]] ?? 0;
                if (qty > 0) {
                  empTotal += qty;
                  itemColumnSums[i] += qty;
                  itemCells.add(numFmt.format(qty));
                } else {
                  itemCells.add('-');
                }
              }

              itemRows.add([
                info.name,
                ...itemCells,
                numFmt.format(empTotal),
              ]);
            }

            itemRows.add([
              'ITEM TOTAL',
              ...itemColumnSums.map((s) => s > 0 ? numFmt.format(s) : '-'),
              numFmt.format(deptTotal),
            ]);

            content.add(
              pw.TableHelper.fromTextArray(
                headers: itemHeaders,
                data: itemRows,
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                headerStyle: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                ),
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                cellAlignment: pw.Alignment.center,
                cellAlignments: {0: pw.Alignment.centerLeft},
                headerAlignment: pw.Alignment.center,
                headerAlignments: {0: pw.Alignment.centerLeft},
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 3,
                ),
              ),
            );
          }

          content.add(pw.SizedBox(height: 10));
        }

        return content;
      },
    ),
  );

  return doc.save();
}
