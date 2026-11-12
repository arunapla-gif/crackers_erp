import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/core/erp_crud_widgets.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/features/admin/view_models/eway_bill_report_view_model.dart';

class EwayBillReportScreen extends StatefulWidget {
  const EwayBillReportScreen({required this.viewModel, super.key});

  final EwayBillReportViewModel viewModel;

  @override
  State<EwayBillReportScreen> createState() => _EwayBillReportScreenState();
}

class _EwayBillReportScreenState extends State<EwayBillReportScreen> {
  static const JsonEncoder _prettyEncoder = JsonEncoder.withIndent('  ');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.viewModel.initialize();
    });
  }

  String _formatPayload(Object? payload) {
    if (payload == null) return 'null';
    if (payload is String) return payload;
    try {
      return _prettyEncoder.convert(payload);
    } catch (_) {
      return payload.toString();
    }
  }

  Future<void> _copyJson(String label, String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label copied to clipboard.')));
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final embedded = ErpShellScope.isEmbeddedShell(context);

    return ErpScreenScaffold(
      title: 'E-Way Bill Fetcher',
      actions: [
        IconButton(
          onPressed: vm.isLoading ? null : vm.fetchReport,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh',
        ),
      ],
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          final report = vm.report;
          return RefreshIndicator(
            onRefresh: vm.fetchReport,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (embedded) ...[
                  ErpSectionHeaderBar(
                    title: 'E-Way Bill Auto-Fetcher',
                    subtitle:
                        'Automatically sync past E-way bills directly from government servers.',
                    accentColor: ErpTheme.ordersEmerald,
                    actions: const [
                      ErpBadge(
                        label: 'GOV.IN PORTAL',
                        backgroundColor: ErpTheme.ordersEmeraldSoft,
                        foregroundColor: ErpTheme.ordersEmerald,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: ErpBadge(
                      label: 'GOV.IN PORTAL',
                      backgroundColor: ErpTheme.ordersEmeraldSoft,
                      foregroundColor: ErpTheme.ordersEmerald,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Timeframe:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: ErpTheme.slate700,
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 175,
                              child: DropdownButtonFormField<int>(
                                initialValue: vm.days,
                                isExpanded: true,
                                isDense: true,
                                items: EwayBillReportViewModel
                                    .availableDayRanges
                                    .map(
                                      (d) => DropdownMenuItem(
                                        value: d,
                                        child: Text('Last $d Days'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: vm.isLoading
                                    ? null
                                    : (val) {
                                        if (val != null) vm.setDays(val);
                                      },
                              ),
                            ),
                          ],
                        ),
                        FilledButton.icon(
                          onPressed: vm.isLoading ? null : vm.fetchReport,
                          style: FilledButton.styleFrom(
                            backgroundColor: ErpTheme.hrIndigo,
                          ),
                          icon: vm.isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.sync_rounded),
                          label: Text(vm.isLoading ? 'Syncing...' : 'Refresh'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (vm.errorMessage != null) ...[
                  ErpErrorBanner(
                    message:
                        'API Connection Error: ${vm.errorMessage!}\nThe Whitebooks / NIC servers may be experiencing downtime or rate limits. Try again in a few minutes.',
                    onRetry: vm.fetchReport,
                  ),
                  const SizedBox(height: 14),
                ],
                if (vm.isLoading && report == null)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 48,
                        horizontal: 20,
                      ),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Contacting Government Servers',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: ErpTheme.slate900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Authenticating via Whitebooks and retrieving multi-day ledgers...',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: ErpTheme.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (report != null) ...[
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth >= 700 ? 3 : 1;
                      const spacing = 10.0;
                      final w =
                          (constraints.maxWidth - spacing * (cols - 1)) / cols;
                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          SizedBox(
                            width: w,
                            child: ErpStatTile(
                              label: 'TOTAL DAYS SCANNED',
                              value: '${vm.days}',
                              accentColor: ErpTheme.adminSlate,
                              icon: Icons.calendar_today_outlined,
                            ),
                          ),
                          SizedBox(
                            width: w,
                            child: ErpStatTile(
                              label: 'SUCCESSFUL PULLS',
                              value: '${report.totalDaysSuccess}',
                              accentColor: ErpTheme.ordersEmerald,
                              icon: Icons.check_circle_outline_rounded,
                            ),
                          ),
                          SizedBox(
                            width: w,
                            child: ErpStatTile(
                              label: 'FAILED PULLS',
                              value: '${report.totalDaysFailed}',
                              accentColor: ErpTheme.dangerRose,
                              icon: Icons.error_outline_rounded,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Raw Data Feeds by Date',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: ErpTheme.slate900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'If standard NIC encryption is required by the API, data objects may appear encrypted or throw errors below.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ErpTheme.slate500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: ErpTheme.slate200),
                        ...report.results.map((dayObj) {
                          final formatted = _formatPayload(dayObj.data);
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: ErpTheme.slate100),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    ErpBadge(
                                      label: 'Date: ${dayObj.date}',
                                      backgroundColor: ErpTheme.hrIndigoSoft,
                                      foregroundColor: ErpTheme.hrIndigo,
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check_rounded,
                                          size: 16,
                                          color: ErpTheme.ordersEmerald,
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'Successful Connection',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: ErpTheme.ordersEmerald,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () => _copyJson(
                                            dayObj.date,
                                            formatted,
                                          ),
                                          icon: const Icon(
                                            Icons.copy,
                                            size: 16,
                                          ),
                                          tooltip: 'Copy JSON',
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: ErpTheme.slate900,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SelectableText(
                                      formatted,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                        color: Color(0xFF34D399),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        ...report.errors.map((errObj) {
                          final formatted = _formatPayload(errObj.error);
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: ErpTheme.dangerRoseSoft.withValues(
                                alpha: 0.35,
                              ),
                              border: const Border(
                                bottom: BorderSide(color: ErpTheme.slate100),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    ErpBadge(
                                      label: 'Date: ${errObj.date}',
                                      backgroundColor: ErpTheme.slate100,
                                      foregroundColor: ErpTheme.slate700,
                                    ),
                                    const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.close_rounded,
                                          size: 16,
                                          color: ErpTheme.dangerRose,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Fetch Failed',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: ErpTheme.dangerRose,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF881337),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SelectableText(
                                      formatted,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                        color: Color(0xFFFECDD3),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (report.results.isEmpty && report.errors.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                'No data processed.',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: ErpTheme.slate400,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
