import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/domain/models/employee.dart';
import 'package:crackers_erp/domain/models/json_helpers.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/core/erp_crud_widgets.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/features/auth/view_models/auth_view_model.dart';
import 'package:crackers_erp/ui/features/employees/view_models/employees_advances_view_model.dart';

class EmployeesAdvancesScreen extends StatefulWidget {
  const EmployeesAdvancesScreen({
    required this.viewModel,
    required this.authViewModel,
    super.key,
  });

  final EmployeesAdvancesViewModel viewModel;
  final AuthViewModel authViewModel;

  @override
  State<EmployeesAdvancesScreen> createState() =>
      _EmployeesAdvancesScreenState();
}

class _EmployeesAdvancesScreenState extends State<EmployeesAdvancesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showRecentAdvancesTab = false;
  final NumberFormat _inrFormat = NumberFormat('#,##,##0.##', 'en_IN');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.authViewModel.currentUser?.canViewEmployees == true) {
        widget.viewModel.loadAll();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _canManageRates {
    final user = widget.authViewModel.currentUser;
    return user != null && !user.isSupervisor;
  }

  bool get _canDeleteEmployee {
    final user = widget.authViewModel.currentUser;
    return user != null && !user.isSupervisor && user.canDelete('employees');
  }

  Future<void> _confirmDeleteEmployee(Employee emp) async {
    final confirmed = await showErpConfirmDialog(
      context: context,
      title: 'Delete Employee?',
      message: 'Remove "${emp.name}" permanently? Employees with existing history may need to be marked Inactive instead.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final ok = await widget.viewModel.deleteEmployee(emp);
    if (ok && mounted && widget.viewModel.statusMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.viewModel.statusMessage!),
          backgroundColor: ErpTheme.ordersEmerald,
        ),
      );
    }
  }

  Future<void> _openEmployeeForm({Employee? existing}) async {
    final canManageRates = _canManageRates;
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final mobileCtrl = TextEditingController(text: existing?.mobile ?? '');
    final roleCtrl = TextEditingController(text: existing?.role ?? '');
    final unitCtrl = TextEditingController(text: existing?.unit ?? '');
    final salaryCtrl = TextEditingController(
      text: existing?.salary != null && existing!.salary! > 0
          ? existing.salary!.toStringAsFixed(
              existing.salary! == existing.salary!.roundToDouble() ? 0 : 2,
            )
          : '',
    );
    var paymentType = existing?.paymentType ?? 'Contractual';
    var status = existing?.status ?? 'Active';

    const rolePresets = [
      'Rolling',
      'Filling',
      'Packing',
      'Bundle Maker',
      'Dispatch',
      'Helper',
    ];

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        existing == null
                            ? (canManageRates
                                  ? 'Add Employee'
                                  : 'Add Factory Worker')
                            : (canManageRates
                                  ? 'Edit Employee'
                                  : 'Edit Worker'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: ErpTheme.slate900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        canManageRates
                            ? 'Configure role, work type, and salary or contractual piece rate.'
                            : 'Wage rates & monthly salaries remain hidden and managed by Admin.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: ErpTheme.slate500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Worker Full Name *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Worker name is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: mobileCtrl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(12),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number (Optional)',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: roleCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Department / Role (e.g. Rolling, Packing)',
                          prefixIcon: Icon(Icons.work_outline),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: rolePresets
                            .map(
                              (preset) => ActionChip(
                                label: Text(preset),
                                onPressed: () => setSheetState(
                                  () => roleCtrl.text = preset,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: paymentType,
                              decoration: const InputDecoration(
                                labelText: 'Work Type',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Contractual',
                                  child: Text('Contractual'),
                                ),
                                DropdownMenuItem(
                                  value: 'Monthly',
                                  child: Text('Monthly'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setSheetState(() => paymentType = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: status,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Active',
                                  child: Text('Active'),
                                ),
                                DropdownMenuItem(
                                  value: 'Inactive',
                                  child: Text('Inactive'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setSheetState(() => status = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      if (canManageRates) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: salaryCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: paymentType == 'Contractual'
                                ? 'Piece Rate (₹)'
                                : 'Basic Salary (₹)',
                            prefixIcon: const Icon(
                              Icons.currency_rupee_rounded,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: unitCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Unit / Shed (Optional, e.g. Unit 1)',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: ErpTheme.hrIndigo,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                if (!(formKey.currentState?.validate() ??
                                    false)) {
                                  return;
                                }
                                final ok = await widget.viewModel.saveEmployee(
                                  id: existing?.id,
                                  name: nameCtrl.text,
                                  mobile: mobileCtrl.text,
                                  role: roleCtrl.text,
                                  paymentType: paymentType,
                                  unit: unitCtrl.text,
                                  status: status,
                                  salary: canManageRates
                                      ? (double.tryParse(
                                              salaryCtrl.text.trim(),
                                            ) ??
                                            0)
                                      : null,
                                  includeSalary: canManageRates,
                                );
                                if (ok && ctx.mounted) {
                                  Navigator.of(ctx).pop(true);
                                }
                              },
                              child: Text(
                                existing == null ? 'Create Worker' : 'Update',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    mobileCtrl.dispose();
    roleCtrl.dispose();
    unitCtrl.dispose();
    salaryCtrl.dispose();

    if (saved == true && mounted && widget.viewModel.statusMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.viewModel.statusMessage!),
          backgroundColor: ErpTheme.ordersEmerald,
        ),
      );
    }
  }

  Future<void> _openGiveAdvanceSheet(Employee employee) async {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController(text: 'Cash Advance');
    var selectedDate = DateTime.now();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final entered = double.tryParse(amountCtrl.text.trim()) ?? 0;
            final projectedBalance = employee.advanceBalance + entered;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Issue Cash Advance',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: ErpTheme.slate900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${employee.name} • ${employee.roleGroup}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: ErpTheme.hrIndigo,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ErpTheme.slate50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: ErpTheme.slate200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Current Balance',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: ErpTheme.slate500,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '₹${_inrFormat.format(employee.advanceBalance)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: ErpTheme.slate900,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: ErpTheme.slate500,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'After Advance',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: ErpTheme.slate500,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '₹${_inrFormat.format(projectedBalance)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: ErpTheme.productionAmber,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime(2023),
                            lastDate: DateTime(now.year, now.month, now.day),
                          );
                          if (picked != null) {
                            setSheetState(() => selectedDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Advance Date',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(
                            DateFormat('dd MMM yyyy').format(selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: amountCtrl,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setSheetState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Advance Amount (₹) *',
                          prefixIcon: Icon(Icons.currency_rupee_rounded),
                        ),
                        validator: (val) {
                          final parsed = double.tryParse((val ?? '').trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Enter amount greater than 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: [200, 500, 1000, 2000]
                            .map(
                              (preset) => ActionChip(
                                label: Text('+₹$preset'),
                                onPressed: () => setSheetState(
                                  () => amountCtrl.text = '$preset',
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Note / Reason',
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: ErpTheme.productionAmber,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                if (!(formKey.currentState?.validate() ??
                                    false)) {
                                  return;
                                }
                                final amount = double.parse(
                                  amountCtrl.text.trim(),
                                );
                                final success = await widget.viewModel
                                    .giveAdvance(
                                      employee: employee,
                                      date: selectedDate,
                                      amount: amount,
                                      description: descCtrl.text,
                                    );
                                if (success && ctx.mounted) {
                                  Navigator.of(ctx).pop(true);
                                }
                              },
                              child: const Text('Record Advance'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    amountCtrl.dispose();
    descCtrl.dispose();

    if (ok == true && mounted && widget.viewModel.statusMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.viewModel.statusMessage!),
          backgroundColor: ErpTheme.ordersEmerald,
        ),
      );
    }
  }

  Future<void> _openWorkerLedgerSheet(Employee employee) async {
    await widget.viewModel.loadEmployeeAdvances(employee.id);
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (ctx, scrollController) {
            return ListenableBuilder(
              listenable: widget.viewModel,
              builder: (ctx, _) {
                final history = widget.viewModel.advancesForEmployee(
                  employee.id,
                );
                return Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ErpTheme.slate200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  employee.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: ErpTheme.slate900,
                                  ),
                                ),
                                Text(
                                  'Current Advance Balance: ₹${_inrFormat.format(employee.advanceBalance)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: ErpTheme.productionAmber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: ErpTheme.productionAmber,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _openGiveAdvanceSheet(employee);
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Give'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: history.isEmpty
                          ? const ErpEmptyState(
                              icon: Icons.account_balance_wallet_outlined,
                              title: 'No Advance History',
                              subtitle:
                                  'Cash advances given and payroll recoveries appear here.',
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: history.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (ctx, idx) {
                                final adv = history[idx];
                                return Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: adv.isGiven
                                          ? ErpTheme.productionAmberSoft
                                          : ErpTheme.ordersEmeraldSoft,
                                      child: Icon(
                                        adv.isGiven
                                            ? Icons.arrow_upward_rounded
                                            : Icons.arrow_downward_rounded,
                                        color: adv.isGiven
                                            ? ErpTheme.productionAmber
                                            : ErpTheme.ordersEmerald,
                                      ),
                                    ),
                                    title: Text(
                                      adv.description ??
                                          (adv.isGiven
                                              ? 'Advance Given'
                                              : 'Recovered in Payroll'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      toIsoCalendarDate(adv.date),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: ErpTheme.slate500,
                                      ),
                                    ),
                                    trailing: Text(
                                      '${adv.isGiven ? '+' : '-'}₹${_inrFormat.format(adv.amount)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: adv.isGiven
                                            ? ErpTheme.dangerRose
                                            : ErpTheme.ordersEmerald,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authViewModel.currentUser;
    final isEmbedded = ErpShellScope.isEmbeddedShell(context);
    final canManageRates = _canManageRates;
    final canAddEmployee = user == null || user.canAdd('employees');

    if (user != null && !user.canViewEmployees) {
      return Scaffold(
        appBar: isEmbedded
            ? null
            : AppBar(
                title: const Text('Workers & Advances'),
                actions: [
                  AccountAppBarAction(authViewModel: widget.authViewModel),
                ],
              ),
        body: const ErpEmptyState(
          icon: Icons.lock_outline,
          title: 'Workers & Advances Restricted',
          subtitle:
              'Ask an Admin to grant Employees access for your account.',
        ),
      );
    }

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        return Scaffold(
          appBar: isEmbedded
              ? null
              : AppBar(
                  title: const Text('Workers & Advances'),
                  actions: [
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: vm.isLoading ? null : vm.loadAll,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                    AccountAppBarAction(authViewModel: widget.authViewModel),
                  ],
                ),
          floatingActionButton: _showRecentAdvancesTab || !canAddEmployee
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _openEmployeeForm(),
                  backgroundColor: ErpTheme.hrIndigo,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: Text(canManageRates ? 'Add Employee' : 'Add Worker'),
                ),
          body: Column(
            children: [
              if (isEmbedded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
                  child: ErpSectionHeaderBar(
                    title: canManageRates
                        ? 'Employee Master & Advances'
                        : 'Workers & Advances',
                    subtitle: canManageRates
                        ? 'Manage employee salaries, piece rates, and advance ledgers.'
                        : 'Manage factory workers and track cash advances.',
                    accentColor: ErpTheme.hrIndigo,
                    actions: [
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: vm.isLoading ? null : vm.loadAll,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<bool>(
                        segments: [
                          ButtonSegment<bool>(
                            value: false,
                            icon: const Icon(Icons.groups_rounded, size: 18),
                            label: Text(canManageRates ? 'Employees' : 'Workers'),
                          ),
                          const ButtonSegment<bool>(
                            value: true,
                            icon: Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 18,
                            ),
                            label: Text('Recent Advances'),
                          ),
                        ],
                        selected: {_showRecentAdvancesTab},
                        onSelectionChanged: (sel) => setState(() {
                          _showRecentAdvancesTab = sel.first;
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              if (vm.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: ErpErrorBanner(
                    message: vm.errorMessage!,
                    onRetry: vm.loadAll,
                    onDismiss: vm.clearMessages,
                  ),
                ),
              Expanded(
                child: vm.isLoading && vm.employees.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _showRecentAdvancesTab
                    ? _buildRecentAdvancesTab(vm)
                    : _buildWorkersTab(vm),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWorkersTab(EmployeesAdvancesViewModel vm) {
    final list = vm.filteredEmployees;

    return RefreshIndicator(
      onRefresh: vm.loadAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 88),
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ErpStatTile(
                label: 'Active Workers',
                value: '${vm.activeWorkersCount}',
                accentColor: ErpTheme.hrIndigo,
                icon: Icons.groups_rounded,
              ),
              ErpStatTile(
                label: 'Contractual',
                value: '${vm.contractualActiveCount}',
                accentColor: ErpTheme.productionAmber,
                icon: Icons.handyman_rounded,
              ),
              ErpStatTile(
                label: 'Advance Balance',
                value: '₹${_inrFormat.format(vm.totalAdvanceOutstanding)}',
                accentColor: ErpTheme.dangerRose,
                icon: Icons.account_balance_wallet_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: vm.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Search worker name, mobile, role or unit...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        vm.setSearchQuery('');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Active Only'),
                  selected: vm.activeOnly,
                  onSelected: vm.setActiveOnly,
                ),
                const SizedBox(width: 8),
                ...['All', 'Contractual', 'Monthly'].map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t),
                      selected: vm.paymentTypeFilter == t,
                      onSelected: (_) => vm.setPaymentTypeFilter(t),
                    ),
                  ),
                ),
                ...vm.availableRoles
                    .where((r) => r != 'All')
                    .map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(r),
                          selected: vm.roleFilter == r,
                          onSelected: (selected) =>
                              vm.setRoleFilter(selected ? r : 'All'),
                        ),
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (list.isEmpty)
            const ErpEmptyState(
              icon: Icons.person_search_outlined,
              title: 'No Workers Match Filters',
              subtitle:
                  'Try adjusting filters or tap Add Worker to register factory staff.',
            )
          else
            ...list.map(
              (emp) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: emp.isActive
                                  ? ErpTheme.hrIndigoSoft
                                  : ErpTheme.slate100,
                              child: Text(
                                emp.name.isNotEmpty
                                    ? emp.name[0].toUpperCase()
                                    : 'W',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: emp.isActive
                                      ? ErpTheme.hrIndigo
                                      : ErpTheme.slate500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          emp.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            color: ErpTheme.slate900,
                                          ),
                                        ),
                                      ),
                                      ErpBadge(
                                        label: emp.status,
                                        backgroundColor: emp.isActive
                                            ? ErpTheme.ordersEmeraldSoft
                                            : ErpTheme.slate100,
                                        foregroundColor: emp.isActive
                                            ? ErpTheme.ordersEmerald
                                            : ErpTheme.slate500,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      emp.roleGroup,
                                      emp.paymentType,
                                      if (emp.unit != null) emp.unit!,
                                      if (emp.mobile != null) emp.mobile!,
                                    ].join(' • '),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: ErpTheme.slate500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: ErpTheme.slate50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: ErpTheme.slate200),
                          ),
                          child: Column(
                            children: [
                              if (_canManageRates) ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      emp.isContractual
                                          ? 'Piece Rate'
                                          : 'Basic Salary',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: ErpTheme.slate700,
                                      ),
                                    ),
                                    Text(
                                      '₹${_inrFormat.format(emp.salary ?? 0)}'
                                      '${emp.isContractual && emp.unit != null ? ' / ${emp.unit}' : ''}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: ErpTheme.hrIndigo,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 12),
                              ],
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Advance Balance',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: ErpTheme.slate700,
                                    ),
                                  ),
                                  Text(
                                    '₹${_inrFormat.format(emp.advanceBalance)}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: emp.advanceBalance > 0
                                          ? ErpTheme.dangerRose
                                          : ErpTheme.slate700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: () => _openGiveAdvanceSheet(emp),
                              icon: const Icon(
                                Icons.currency_rupee_rounded,
                                size: 16,
                              ),
                              label: const Text('Give Advance'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _openWorkerLedgerSheet(emp),
                              icon: const Icon(
                                Icons.receipt_long_outlined,
                                size: 16,
                              ),
                              label: const Text('Ledger'),
                            ),
                            if (widget.authViewModel.currentUser == null ||
                                widget.authViewModel.currentUser!.canEdit(
                                  'employees',
                                ))
                              IconButton(
                                tooltip: 'Edit worker',
                                onPressed: () =>
                                    _openEmployeeForm(existing: emp),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                            if (widget.authViewModel.currentUser == null ||
                                widget.authViewModel.currentUser!.canEdit(
                                  'employees',
                                ))
                              IconButton(
                                tooltip: emp.isActive
                                    ? 'Mark Inactive'
                                    : 'Mark Active',
                                onPressed: () => vm.toggleEmployeeStatus(
                                  emp,
                                  includeSalary: _canManageRates,
                                ),
                                icon: Icon(
                                  emp.isActive
                                      ? Icons.person_off_outlined
                                      : Icons.how_to_reg_outlined,
                                  color: emp.isActive
                                      ? ErpTheme.slate500
                                      : ErpTheme.ordersEmerald,
                                ),
                              ),
                            if (_canDeleteEmployee)
                              IconButton(
                                tooltip: 'Delete employee',
                                onPressed: () => _confirmDeleteEmployee(emp),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: ErpTheme.dangerRose,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentAdvancesTab(EmployeesAdvancesViewModel vm) {
    if (vm.recentAdvances.isEmpty) {
      return RefreshIndicator(
        onRefresh: vm.loadAll,
        child: ListView(
          children: const [
            SizedBox(height: 80),
            ErpEmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No Cash Advances Recorded',
              subtitle:
                  'Tap Give Advance on any worker card to issue an advance.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.loadAll,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: vm.recentAdvances.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (ctx, idx) {
          final adv = vm.recentAdvances[idx];
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              leading: CircleAvatar(
                backgroundColor: adv.isGiven
                    ? ErpTheme.productionAmberSoft
                    : ErpTheme.ordersEmeraldSoft,
                child: Icon(
                  adv.isGiven
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: adv.isGiven
                      ? ErpTheme.productionAmber
                      : ErpTheme.ordersEmerald,
                ),
              ),
              title: Text(
                adv.employeeName ?? 'Worker #${adv.employeeId}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: ErpTheme.slate900,
                ),
              ),
              subtitle: Text(
                '${toIsoCalendarDate(adv.date)} • ${adv.description ?? adv.type}',
                style: const TextStyle(fontSize: 12, color: ErpTheme.slate500),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${adv.isGiven ? '+' : '-'}₹${_inrFormat.format(adv.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: adv.isGiven
                          ? ErpTheme.dangerRose
                          : ErpTheme.ordersEmerald,
                    ),
                  ),
                  Text(
                    adv.isGiven ? 'GIVEN' : 'RECOVERED',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: ErpTheme.slate500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
