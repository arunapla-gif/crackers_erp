import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/core/utils/inr_formatter.dart';
import 'package:crackers_erp/domain/models/employee.dart';
import 'package:crackers_erp/domain/models/payroll.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/core/erp_crud_widgets.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/features/hr/view_models/payroll_view_model.dart';
import 'payroll_pdf.dart';

class PayrollEntryScreen extends StatefulWidget {
  const PayrollEntryScreen({required this.viewModel, super.key});

  final PayrollViewModel viewModel;

  @override
  State<PayrollEntryScreen> createState() => _PayrollEntryScreenState();
}

class _PayrollEntryScreenState extends State<PayrollEntryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.viewModel.loadAll();
    });
  }

  Future<void> _pickPayoutDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.viewModel.payoutDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null && mounted) {
      widget.viewModel.setPayoutDate(picked);
    }
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.viewModel.startDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null && mounted) {
      widget.viewModel.setStartDate(picked);
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.viewModel.endDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null && mounted) {
      widget.viewModel.setEndDate(picked);
    }
  }

  Future<void> _handleSaveAll() async {
    final ok = await widget.viewModel.saveBulkPayroll();
    if (!mounted) return;
    if (ok && widget.viewModel.statusMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.viewModel.statusMessage!),
          backgroundColor: ErpTheme.ordersEmerald,
        ),
      );
    }
  }

  Future<void> _printReport() async {
    final nameDate =
        widget.viewModel.isoPayoutDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    await Printing.layoutPdf(
      name: 'Consolidated_Payroll_$nameDate.pdf',
      onLayout: (_) => buildConsolidatedPayrollPdf(widget.viewModel),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErpScreenScaffold(
      title: 'Payroll Entry',
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final vm = widget.viewModel;
          if (vm.isLoading && vm.employees.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final rolesMap = vm.employeesByRole;
          final grand = vm.grandTotals;

          return RefreshIndicator(
            onRefresh: vm.loadAll,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                ErpSectionHeaderBar(
                  title: 'Consolidated Payroll Entry',
                  subtitle:
                      'Weekly Friday-to-Thursday piece-rate wages, monthly salaries, allowances & advance recovery.',
                  accentColor: ErpTheme.hrPurple,
                  actions: [
                    OutlinedButton.icon(
                      onPressed: vm.employees.isEmpty ? null : _printReport,
                      icon: const Icon(Icons.print_outlined, size: 18),
                      label: const Text('Print Report'),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: vm.isLoading ? null : vm.loadAll,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (vm.errorMessage != null) ...[
                  ErpErrorBanner(
                    message: vm.errorMessage!,
                    onDismiss: vm.clearMessages,
                  ),
                  const SizedBox(height: 10),
                ],
                if (vm.statusMessage != null) ...[
                  ErpSuccessBanner(
                    message: vm.statusMessage!,
                    onDismiss: vm.clearMessages,
                  ),
                  const SizedBox(height: 10),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ErpResponsiveFormGrid(
                          minItemWidth: 210,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  onTap: _pickPayoutDate,
                                  borderRadius: BorderRadius.circular(14),
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Payout Date (Saturday) *',
                                      prefixIcon: Icon(
                                        Icons.event_available_outlined,
                                        size: 18,
                                      ),
                                    ),
                                    child: Text(
                                      vm.payoutDate != null
                                          ? DateFormat('EEE, dd MMM yyyy')
                                                .format(vm.payoutDate!)
                                          : 'Select Saturday Date',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: vm.payoutDate != null
                                            ? ErpTheme.slate900
                                            : ErpTheme.slate500,
                                      ),
                                    ),
                                  ),
                                ),
                                if (vm.payoutDate != null &&
                                    !vm.isPayoutSaturday) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ErpTheme.dangerRose.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Warning: Selected date is not a Saturday!',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: ErpTheme.dangerRose,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            InkWell(
                              onTap: _pickStartDate,
                              borderRadius: BorderRadius.circular(14),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'From Date (Fri)',
                                  prefixIcon: Icon(
                                    Icons.calendar_today_outlined,
                                    size: 18,
                                  ),
                                ),
                                child: Text(
                                  vm.startDate != null
                                      ? DateFormat('EEE, dd MMM yyyy')
                                            .format(vm.startDate!)
                                      : '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: ErpTheme.hrIndigo,
                                  ),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: _pickEndDate,
                              borderRadius: BorderRadius.circular(14),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'To Date (Thu)',
                                  prefixIcon: Icon(
                                    Icons.calendar_today_outlined,
                                    size: 18,
                                  ),
                                ),
                                child: Text(
                                  vm.endDate != null
                                      ? DateFormat('EEE, dd MMM yyyy')
                                            .format(vm.endDate!)
                                      : '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: ErpTheme.hrIndigo,
                                  ),
                                ),
                              ),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: (vm.isCalculating ||
                                      vm.startDate == null ||
                                      vm.endDate == null)
                                  ? null
                                  : vm.calculateContractualWages,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 16,
                                ),
                                backgroundColor: ErpTheme.hrIndigoSoft,
                                foregroundColor: ErpTheme.hrIndigo,
                              ),
                              icon: vm.isCalculating
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.calculate_outlined),
                              label: Text(
                                vm.isCalculating
                                    ? 'Calculating...'
                                    : 'Calculate Wages',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ErpStatTile(
                      label: 'Active Employees',
                      value: '${vm.employees.length}',
                      accentColor: ErpTheme.hrIndigo,
                      icon: Icons.groups_rounded,
                    ),
                    ErpStatTile(
                      label: 'Base / Piece Wages',
                      value: formatInr(grand.basic),
                      accentColor: ErpTheme.slate700,
                      icon: Icons.payments_outlined,
                    ),
                    ErpStatTile(
                      label: 'Allowances (+)',
                      value: formatInr(grand.allowance),
                      accentColor: ErpTheme.ordersEmerald,
                      icon: Icons.add_circle_outline_rounded,
                    ),
                    ErpStatTile(
                      label: 'Deductions (-)',
                      value: formatInr(grand.deduction),
                      accentColor: ErpTheme.dangerRose,
                      icon: Icons.remove_circle_outline_rounded,
                    ),
                    ErpStatTile(
                      label: 'Grand Net Payout',
                      value: formatInr(grand.net),
                      accentColor: ErpTheme.hrPurple,
                      icon: Icons.account_balance_wallet_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (vm.employees.isEmpty)
                  const ErpEmptyState(
                    icon: Icons.payments_outlined,
                    title: 'No Active Employees Found',
                    subtitle: 'Add active workers in Employee Master first.',
                  )
                else
                  ...rolesMap.entries.map((entry) {
                    final role = entry.key;
                    final list = entry.value;
                    final roleTotals = vm.totalsForRole(role);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            color: ErpTheme.slate100,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${role.toUpperCase()} (${list.length})',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: ErpTheme.slate700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Subtotal: ${formatInr(roleTotals.net)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: ErpTheme.hrPurple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...list.map((emp) {
                            final row = vm.rowFor(emp.id);
                            if (row == null) return const SizedBox.shrink();
                            return _PayrollWorkerCard(
                              key: ValueKey('pay-${emp.id}'),
                              employee: emp,
                              row: row,
                              uniqueProducts: vm.uniqueProducts,
                              isExpanded: vm.isExpanded(emp.id),
                              onToggleExpand: () => vm.toggleExpanded(emp.id),
                              onUpdate: ({
                                double? basicSalary,
                                double? allowance,
                                double? deduction,
                                String? status,
                              }) => vm.updateRow(
                                emp.id,
                                basicSalary: basicSalary,
                                allowance: allowance,
                                deduction: deduction,
                                status: status,
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                Card(
                  color: ErpTheme.slate900,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'GRAND TOTAL PAYOUT',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            Text(
                              formatInr(grand.net),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: vm.employees.isEmpty
                                  ? null
                                  : _printReport,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white30),
                              ),
                              icon: const Icon(Icons.print_outlined, size: 18),
                              label: const Text('Print Report PDF'),
                            ),
                            OutlinedButton(
                              onPressed: vm.isSaving ? null : vm.clearGrid,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white30),
                              ),
                              child: const Text('Clear Grid'),
                            ),
                            FilledButton.icon(
                              onPressed: vm.isSaving ? null : _handleSaveAll,
                              style: FilledButton.styleFrom(
                                backgroundColor: ErpTheme.hrPurple,
                                foregroundColor: Colors.white,
                              ),
                              icon: vm.isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_rounded, size: 18),
                              label: const Text('Save Bulk Payroll'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildRecentPayrollsSection(vm),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentPayrollsSection(PayrollViewModel vm) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history_rounded, color: ErpTheme.hrPurple),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Recent Payrolls History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: ErpTheme.slate900,
                    ),
                  ),
                ),
                Text(
                  '${vm.payrolls.length} records',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ErpTheme.slate500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (vm.payrolls.isEmpty)
              const ErpEmptyState(
                icon: Icons.payments_outlined,
                title: 'No Payroll Records Yet',
                subtitle: 'Saved weekly and monthly payouts appear here.',
              )
            else
              ...vm.payrolls.take(40).map(
                (p) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ErpTheme.slate50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ErpTheme.slate200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.employeeName ?? 'Employee #${p.employeeId}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: ErpTheme.slate900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${p.month} • ${p.paymentType} • Base ${formatInr(p.basicSalary)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: ErpTheme.slate500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatInr(p.netSalary),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: ErpTheme.hrPurple,
                            ),
                          ),
                          ErpBadge(
                            label: p.status,
                            backgroundColor: p.status == 'Pending'
                                ? ErpTheme.productionAmberSoft
                                : ErpTheme.ordersEmeraldSoft,
                            foregroundColor: p.status == 'Pending'
                                ? ErpTheme.productionAmber
                                : ErpTheme.ordersEmerald,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PayrollWorkerCard extends StatefulWidget {
  const _PayrollWorkerCard({
    required this.employee,
    required this.row,
    required this.uniqueProducts,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onUpdate,
    super.key,
  });

  final Employee employee;
  final PayrollWorksheetRow row;
  final List<String> uniqueProducts;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final void Function({
    double? basicSalary,
    double? allowance,
    double? deduction,
    String? status,
  }) onUpdate;

  @override
  State<_PayrollWorkerCard> createState() => _PayrollWorkerCardState();
}

class _PayrollWorkerCardState extends State<_PayrollWorkerCard> {
  late final TextEditingController _basicCtrl;
  late final TextEditingController _allowCtrl;
  late final TextEditingController _deductCtrl;

  @override
  void initState() {
    super.initState();
    _basicCtrl = TextEditingController(
      text: widget.row.basicSalary > 0
          ? widget.row.basicSalary.toStringAsFixed(2)
          : '',
    );
    _allowCtrl = TextEditingController(
      text: widget.row.allowance > 0
          ? widget.row.allowance.toStringAsFixed(2)
          : '',
    );
    _deductCtrl = TextEditingController(
      text: widget.row.deduction > 0
          ? widget.row.deduction.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void didUpdateWidget(covariant _PayrollWorkerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncCtrl(_basicCtrl, widget.row.basicSalary);
    _syncCtrl(_allowCtrl, widget.row.allowance);
    _syncCtrl(_deductCtrl, widget.row.deduction);
  }

  void _syncCtrl(TextEditingController ctrl, double val) {
    final parsed = double.tryParse(ctrl.text.trim()) ?? 0;
    if ((parsed - val).abs() > 0.001) {
      final next = val == 0 ? '' : val.toStringAsFixed(2);
      ctrl.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
  }

  @override
  void dispose() {
    _basicCtrl.dispose();
    _allowCtrl.dispose();
    _deductCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emp = widget.employee;
    final row = widget.row;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ErpTheme.slate200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: widget.onToggleExpand,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    widget.isExpanded
                        ? Icons.expand_more_rounded
                        : Icons.chevron_right_rounded,
                    color: ErpTheme.hrIndigo,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          emp.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: ErpTheme.slate900,
                          ),
                        ),
                        ErpBadge(
                          label: emp.paymentType,
                          backgroundColor: emp.isContractual
                              ? ErpTheme.hrIndigoSoft
                              : ErpTheme.slate100,
                          foregroundColor: emp.isContractual
                              ? ErpTheme.hrIndigo
                              : ErpTheme.slate700,
                        ),
                        if (row.advanceBalance > 0)
                          ErpBadge(
                            label: 'ADV BAL: ${formatInr(row.advanceBalance)}',
                            backgroundColor: ErpTheme.dangerRose.withValues(
                              alpha: 0.1,
                            ),
                            foregroundColor: ErpTheme.dangerRose,
                          ),
                      ],
                    ),
                  ),
                  Text(
                    formatInr(row.netSalary),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: ErpTheme.hrPurple,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.uniqueProducts.isNotEmpty &&
              row.productQuantities.entries.any((e) => e.value > 0)) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.uniqueProducts
                  .where((p) => (row.productQuantities[p] ?? 0) > 0)
                  .map(
                    (p) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ErpTheme.hrIndigoSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$p: ${row.productQuantities[p]}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: ErpTheme.hrIndigo,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 10),
          ErpResponsiveFormGrid(
            minItemWidth: 165,
            spacing: 10,
            children: [
              TextField(
                controller: _basicCtrl,
                readOnly: emp.isContractual,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: emp.isContractual
                    ? null
                    : (val) => widget.onUpdate(
                        basicSalary: double.tryParse(val.trim()) ?? 0,
                      ),
                decoration: InputDecoration(
                  labelText: emp.isContractual
                      ? 'Piece Wages (Auto)'
                      : 'Basic Salary (₹)',
                  prefixText: '₹',
                  filled: emp.isContractual,
                ),
              ),
              TextField(
                controller: _allowCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (val) => widget.onUpdate(
                  allowance: double.tryParse(val.trim()) ?? 0,
                ),
                decoration: const InputDecoration(
                  labelText: 'Allowance (+)',
                  prefixText: '₹',
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _deductCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (val) => widget.onUpdate(
                      deduction: double.tryParse(val.trim()) ?? 0,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Deduction / Adv Rec (-)',
                      prefixText: '₹',
                    ),
                  ),
                  if (row.advanceBalance > 0)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          final maxDeduct = row.advanceBalance <=
                                  (row.basicSalary + row.allowance)
                              ? row.advanceBalance
                              : (row.basicSalary + row.allowance);
                          widget.onUpdate(deduction: maxDeduct);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Recover Adv (${formatInr(row.advanceBalance)})',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: ErpTheme.dangerRose,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              DropdownButtonFormField<String>(
                key: ValueKey('status-${emp.id}-${row.status}'),
                initialValue: row.status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                ],
                onChanged: (val) {
                  if (val != null) widget.onUpdate(status: val);
                },
              ),
            ],
          ),
          if (widget.isExpanded) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ErpTheme.slate50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ErpTheme.slate200),
              ),
              child: row.dailyLogs.isEmpty
                  ? const Text(
                      'No daily production logs found for this period.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: ErpTheme.slate500,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DAILY PRODUCTION BREAKDOWN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: ErpTheme.hrIndigo,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...row.dailyLogs.map(
                          (log) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 96,
                                  child: Text(
                                    DateFormat('EEE, dd MMM').format(log.date),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: ErpTheme.slate700,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: log.items
                                        .map(
                                          (item) => Text(
                                            '${item.itemName}: ${item.quantity}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: ErpTheme.slate900,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  formatInr(log.totalAmount),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: ErpTheme.hrIndigo,
                                  ),
                                ),
                              ],
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
  }
}
