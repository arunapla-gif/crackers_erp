import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Generate Idea 2 Mockup Picture', (tester) async {
    tester.view.physicalSize = const Size(960, 3800);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repaintKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF59E0B)),
          scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        ),
        home: RepaintBoundary(
          key: repaintKey,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Production Entry',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Idea 2: Department-Wise Sub-Grids',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.account_circle_outlined, color: Color(0xFF475569)),
                  onPressed: () {},
                ),
              ],
            ),
            body: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 90),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Date bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.chevron_left_rounded, color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
                            const Icon(Icons.calendar_today_rounded, size: 15, color: Color(0xFFD97706)),
                            const SizedBox(width: 8),
                            const Text(
                              'Mon, 16 Nov 2026',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'TODAY',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Card 1: Tape Department
                      _buildDepartmentCard(
                        role: 'Tape',
                        tamilName: 'டேப் பிரிவு',
                        workerCount: 14,
                        accentColor: const Color(0xFF004D40),
                        bgColor: const Color(0xFFE0F2F1),
                        borderColor: const Color(0xFF80CBC4),
                        icon: Icons.layers_rounded,
                        dropdownHint: 'Add Tape WIP Column...',
                        dropdownItems: const ['10 KVR 48 Tape', '12 KVR Tape', 'Bijili Roll Tape'],
                        columns: const ['10 KVR 48 Tape', '12 KVR Tape'],
                        workers: const [
                          ('மணிமேகலை', ['50', '40'], '90'),
                          ('ஜோதி', ['45', '50'], '95'),
                          ('பவித்தா', ['52', '35'], '87'),
                          ('சீதா', ['48', '42'], '90'),
                          ('காவியா', ['50', '50'], '100'),
                          ('அபி', ['46', '38'], '84'),
                          ('ராசம்மாள்', ['55', '45'], '100'),
                          ('... +7 more Tape workers', ['274', '220'], '494'),
                        ],
                        colTotals: const ['620 Pcs', '480 Pcs', '1,100 Pcs'],
                      ),
                      const SizedBox(height: 14),

                      // Card 2: Chemical Department
                      _buildDepartmentCard(
                        role: 'Chemical',
                        tamilName: 'கெமிக்கல் பிரிவு',
                        workerCount: 1,
                        accentColor: const Color(0xFFB45309),
                        bgColor: const Color(0xFFFFF8E1),
                        borderColor: const Color(0xFFFFE082),
                        icon: Icons.science_rounded,
                        dropdownHint: 'Add Chemical WIP Column...',
                        dropdownItems: const ['Red Dipping Chemical', 'Green Dipping', 'Chemical Mixing'],
                        columns: const ['Red Dipping', 'Green Dipping'],
                        workers: const [
                          ('முனியசாமி', ['35', '20'], '55'),
                        ],
                        colTotals: const ['35 Pcs', '20 Pcs', '55 Pcs'],
                      ),
                      const SizedBox(height: 14),

                      // Card 3: Valayam Contract
                      _buildDepartmentCard(
                        role: 'Valayam Contract',
                        tamilName: 'வளையம் ஒப்பந்தம்',
                        workerCount: 1,
                        accentColor: const Color(0xFF311B92),
                        bgColor: const Color(0xFFEDE7F6),
                        borderColor: const Color(0xFFD1C4E9),
                        icon: Icons.handshake_rounded,
                        dropdownHint: 'Add Valayam WIP Column...',
                        dropdownItems: const ['Valayam Ring Binding', 'Chakkar Valayam Joint'],
                        columns: const ['Valayam Ring Binding'],
                        workers: const [
                          ('வசந்த்', ['120'], '120'),
                        ],
                        colTotals: const ['120 Pcs', '120 Pcs'],
                      ),
                      const SizedBox(height: 14),

                      // Card 4: Box Packing
                      _buildDepartmentCard(
                        role: 'Box Packing',
                        tamilName: 'பேக்கிங் பிரிவு',
                        workerCount: 1,
                        accentColor: const Color(0xFF006064),
                        bgColor: const Color(0xFFE0F7FA),
                        borderColor: const Color(0xFF80DEEA),
                        icon: Icons.inventory_2_rounded,
                        dropdownHint: 'Add Packing WIP Column...',
                        dropdownItems: const ['10s Box Packing', 'Master Carton Packing'],
                        columns: const ['10s Box Packing'],
                        workers: const [
                          ('கார்த்தி அப்பா', ['80'], '80'),
                        ],
                        colTotals: const ['80 Pcs', '80 Pcs'],
                      ),
                    ],
                  ),
                ),

                // Sticky Bottom Save Bar
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Factory Total Entry',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                '17 Workers • 1,355 Pcs',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: const Text(
                            'Save All (17)',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final outPath = '/Users/arun_ap/.gemini/antigravity/brain/f7071202-34e1-4867-acdb-69999a14b709/idea2_mockup.png';
          File(outPath).writeAsBytesSync(byteData.buffer.asUint8List());
        }
      }
    });
  });
}

Widget _buildDepartmentCard({
  required String role,
  required String tamilName,
  required int workerCount,
  required Color accentColor,
  required Color bgColor,
  required Color borderColor,
  required IconData icon,
  required String dropdownHint,
  required List<String> dropdownItems,
  required List<String> columns,
  required List<(String name, List<String> qtys, String total)> workers,
  required List<String> colTotals,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Department Header Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              left: BorderSide(color: accentColor, width: 4),
              bottom: BorderSide(color: borderColor),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${role.toUpperCase()} • $tamilName ($workerCount)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Icon(Icons.expand_less_rounded, size: 20, color: accentColor),
            ],
          ),
        ),

        // Quick Add Column row for this department
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_chart_rounded, size: 15, color: Color(0xFFD97706)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          dropdownHint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 18, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '+ Add',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11.5),
                ),
              ),
            ],
          ),
        ),

        // Table for this department
        Table(
          columnWidths: {
            0: const FlexColumnWidth(1.4),
            for (int i = 0; i < columns.length; i++) (i + 1): const FlexColumnWidth(1.0),
            columns.length + 1: const FlexColumnWidth(0.8),
          },
          border: const TableBorder(
            horizontalInside: BorderSide(color: Color(0xFFF1F5F9)),
            verticalInside: BorderSide(color: Color(0xFFE2E8F0)),
          ),
          children: [
            // Table Header
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Text(
                    'WORKER',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF64748B)),
                  ),
                ),
                ...columns.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          c,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF3730A3)),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.close_rounded, size: 12, color: Color(0xFFEF4444)),
                    ],
                  ),
                )),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Text(
                    'TOTAL',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),

            // Worker Rows
            ...workers.map((w) {
              final isSubtotalRow = w.$1.startsWith('...');
              return TableRow(
                decoration: BoxDecoration(
                  color: isSubtotalRow ? const Color(0xFFF8FAFC) : Colors.white,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: Text(
                      w.$1,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSubtotalRow ? FontWeight.w600 : FontWeight.w800,
                        color: isSubtotalRow ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  ...w.$2.map((qty) => Padding(
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: isSubtotalRow ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isSubtotalRow ? Colors.transparent : const Color(0xFFCBD5E1)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        qty,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: isSubtotalRow ? const Color(0xFF64748B) : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  )),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                    child: Text(
                      w.$3,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                    ),
                  ),
                ],
              );
            }),

            // Department Totals Row
            TableRow(
              decoration: BoxDecoration(
                color: bgColor.withValues(alpha: 0.5),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Text(
                    'SUBTOTAL',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: accentColor),
                  ),
                ),
                ...colTotals.map((tot) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Text(
                    tot,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: accentColor),
                  ),
                )),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}
