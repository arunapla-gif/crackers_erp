import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/domain/models/erp_user.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/core/erp_crud_widgets.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/features/admin/view_models/user_master_view_model.dart';
import 'package:crackers_erp/ui/features/auth/view_models/auth_view_model.dart';
import 'package:crackers_erp/ui/features/masters/views/master_shared_widgets.dart';

class UserMasterScreen extends StatefulWidget {
  const UserMasterScreen({
    required this.viewModel,
    required this.authViewModel,
    super.key,
  });

  final UserMasterViewModel viewModel;
  final AuthViewModel authViewModel;

  @override
  State<UserMasterScreen> createState() => _UserMasterScreenState();
}

class _UserMasterScreenState extends State<UserMasterScreen> {
  final _usernameCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _syncControllers();
    widget.viewModel.addListener(_syncControllers);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.viewModel.initialize();
    });
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_syncControllers);
    _usernameCtrl.dispose();
    _pinCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _syncControllers() {
    final vm = widget.viewModel;
    syncMasterController(_usernameCtrl, vm.username);
    syncMasterController(_pinCtrl, vm.pin);
  }

  void _handleEdit(ErpUser user) {
    widget.viewModel.editUser(user);
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAccount = widget.authViewModel.currentUser;
    if (currentAccount != null && !currentAccount.isAdmin) {
      return const ErpScreenScaffold(
        title: 'User Management',
        body: ErpEmptyState(
          icon: Icons.lock_outline,
          title: 'Admin Access Required',
          subtitle: 'Only Administrators can manage system users and RBAC.',
        ),
      );
    }

    final vm = widget.viewModel;
    final embedded = ErpShellScope.isEmbeddedShell(context);

    return ErpScreenScaffold(
      title: 'User Management',
      actions: [
        IconButton(
          onPressed: vm.refresh,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh',
        ),
      ],
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          return RefreshIndicator(
            onRefresh: vm.refresh,
            child: ListView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              children: [
                if (embedded) ...[
                  ErpSectionHeaderBar(
                    title: 'User Access & Permissions Master',
                    subtitle:
                        'Configure users, numeric PINs, and granular module RBAC',
                    accentColor: ErpTheme.dangerRose,
                    actions: [
                      IconButton(
                        onPressed: vm.isLoading ? null : vm.refresh,
                        icon: const Icon(Icons.refresh_rounded),
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                if (vm.errorMessage != null) ...[
                  ErpErrorBanner(
                    message: vm.errorMessage!,
                    onDismiss: vm.dismissMessages,
                  ),
                  const SizedBox(height: 12),
                ],
                if (vm.successMessage != null) ...[
                  ErpSuccessBanner(
                    message: vm.successMessage!,
                    onDismiss: vm.dismissMessages,
                  ),
                  const SizedBox(height: 12),
                ],
                MasterFormCard(
                  title: vm.isEditing
                      ? 'Edit User: ${vm.username}'
                      : 'User Access & Permissions Master',
                  accentColor: ErpTheme.dangerRose,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ErpResponsiveFormGrid(
                        minItemWidth: 200,
                        children: [
                          TextField(
                            controller: _usernameCtrl,
                            enabled: !vm.isEditingSuperAdmin,
                            decoration: const InputDecoration(
                              labelText: 'Username *',
                              hintText: 'e.g. cashier1',
                            ),
                            onChanged: vm.setUsername,
                          ),
                          TextField(
                            controller: _pinCtrl,
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(12),
                            ],
                            decoration: InputDecoration(
                              labelText: vm.isEditing
                                  ? 'Reset PIN (Leave blank to keep)'
                                  : 'PIN (Numbers only) *',
                              hintText: '****',
                            ),
                            onChanged: vm.setPin,
                          ),
                          DropdownButtonFormField<String>(
                            initialValue: vm.role,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Role',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'STAFF',
                                child: Text('STAFF'),
                              ),
                              DropdownMenuItem(
                                value: 'SUPERVISOR',
                                child: Text('FACTORY SUPERVISOR (Android)'),
                              ),
                              DropdownMenuItem(
                                value: 'REP',
                                child: Text('SALES REP'),
                              ),
                              DropdownMenuItem(
                                value: 'ADMIN',
                                child: Text('ADMIN (Full Access)'),
                              ),
                            ],
                            onChanged: vm.isEditingSuperAdmin
                                ? null
                                : (val) {
                                    if (val != null) vm.setRole(val);
                                  },
                          ),
                          DropdownButtonFormField<String>(
                            initialValue: vm.status,
                            isExpanded: true,
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
                            onChanged: vm.isEditingSuperAdmin
                                ? null
                                : (val) {
                                    if (val != null) vm.setStatus(val);
                                  },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (vm.role == 'REP') _RepCategoriesPanel(viewModel: vm),
                      if (vm.role == 'SUPERVISOR')
                        const _SupervisorPolicyBanner(),
                      if (vm.role == 'STAFF')
                        _StaffPermissionsPanel(viewModel: vm),
                      if (vm.role == 'ADMIN')
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F3FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: ErpTheme.hrPurple.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                color: ErpTheme.hrPurpleDark,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'ADMIN role grants unrestricted access across all ERP modules, branches, rates, and user settings.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: ErpTheme.hrPurpleDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ErpTheme.slate50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: ErpTheme.slate200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: vm.isSaving ? null : vm.clearForm,
                              child: const Text('Clear'),
                            ),
                            const SizedBox(width: 10),
                            FilledButton.icon(
                              onPressed: vm.isSaving ? null : vm.saveUser,
                              style: FilledButton.styleFrom(
                                backgroundColor: ErpTheme.dangerRose,
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
                                  : const Icon(Icons.save_outlined),
                              label: const Text('Save User'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'SYSTEM USERS',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.7,
                                color: ErpTheme.dangerRose,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ErpBadge(
                              label: '${vm.users.length}',
                              backgroundColor: ErpTheme.dangerRoseSoft,
                              foregroundColor: ErpTheme.dangerRose,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (vm.isLoading && vm.users.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (vm.users.isEmpty)
                          const ErpEmptyState(
                            icon: Icons.people_outline,
                            title: 'No Users Found',
                            subtitle: 'Create an ERP user account above.',
                          )
                        else
                          ...vm.users.map((u) {
                            final isSuperAdmin =
                                u.username.trim().toLowerCase() == 'admin';
                            final (roleBg, roleFg) = switch (u.role) {
                              'ADMIN' => (
                                const Color(0xFFF3E8FF),
                                ErpTheme.hrPurpleDark,
                              ),
                              'REP' => (
                                ErpTheme.salesBlueSoft,
                                ErpTheme.salesBlueDark,
                              ),
                              'SUPERVISOR' => (
                                ErpTheme.productionAmberSoft,
                                ErpTheme.productionAmberDark,
                              ),
                              _ => (ErpTheme.slate100, ErpTheme.slate700),
                            };
                            return Opacity(
                              opacity: u.isActive ? 1.0 : 0.65,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: ErpTheme.slate200),
                                ),
                                child: Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 10,
                                  runSpacing: 8,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: roleBg,
                                          child: Text(
                                            u.username.isEmpty
                                                ? '?'
                                                : u.username[0].toUpperCase(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: roleFg,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              u.username,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: ErpTheme.slate900,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 6,
                                              children: [
                                                ErpBadge(
                                                  label: u.role,
                                                  backgroundColor: roleBg,
                                                  foregroundColor: roleFg,
                                                ),
                                                MasterStatusBadge(
                                                  isActive: u.isActive,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _handleEdit(u),
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 16,
                                          ),
                                          label: const Text('Edit'),
                                        ),
                                        if (!isSuperAdmin) ...[
                                          const SizedBox(width: 4),
                                          TextButton(
                                            onPressed: () =>
                                                vm.toggleUserStatus(u),
                                            style: TextButton.styleFrom(
                                              foregroundColor: u.isActive
                                                  ? ErpTheme.dangerRose
                                                  : ErpTheme.ordersEmerald,
                                            ),
                                            child: Text(
                                              u.isActive ? 'Disable' : 'Enable',
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SupervisorPolicyBanner extends StatelessWidget {
  const _SupervisorPolicyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ErpTheme.productionAmberSoft.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ErpTheme.productionAmber.withValues(alpha: 0.35),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FACTORY SUPERVISOR ACCESS POLICY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: ErpTheme.productionAmberDark,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Can manage Daily Production entries, Employees & Advances, and view Approved Factory Orders (box quantities only). '
            'All rupee wage rates, piece rates, salaries, Payroll, and customer prices are strictly hidden on the server.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: ErpTheme.productionAmberDark,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _RepCategoriesPanel extends StatelessWidget {
  const _RepCategoriesPanel({required this.viewModel});

  final UserMasterViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ErpTheme.slate200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: ErpTheme.purchasesOrangeSoft,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REP ALLOWED PRODUCT CATEGORIES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: ErpTheme.purchasesOrangeDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Select which product categories or sub-categories this rep is allowed to see and sell. If none are selected, they can see all.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ErpTheme.purchasesOrangeDark,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MAIN CATEGORIES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: ErpTheme.slate500,
                  ),
                ),
                const SizedBox(height: 8),
                if (viewModel.categories.isEmpty)
                  const Text(
                    'No categories found.',
                    style: TextStyle(fontSize: 12, color: ErpTheme.slate400),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: viewModel.categories.map((cat) {
                      final selected = viewModel.allowedCategories.contains(
                        cat,
                      );
                      return FilterChip(
                        label: Text(cat),
                        selected: selected,
                        selectedColor: ErpTheme.purchasesOrangeSoft,
                        checkmarkColor: ErpTheme.purchasesOrangeDark,
                        onSelected: (_) => viewModel.toggleCategory(cat),
                      );
                    }).toList(),
                  ),
                const Divider(height: 24),
                const Text(
                  'SUB-CATEGORIES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: ErpTheme.slate500,
                  ),
                ),
                const SizedBox(height: 8),
                if (viewModel.subCategories.isEmpty)
                  const Text(
                    'No sub-categories found.',
                    style: TextStyle(fontSize: 12, color: ErpTheme.slate400),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: viewModel.subCategories.map((subCat) {
                      final selected = viewModel.allowedCategories.contains(
                        subCat,
                      );
                      return FilterChip(
                        label: Text(subCat),
                        selected: selected,
                        selectedColor: ErpTheme.purchasesOrangeSoft,
                        checkmarkColor: ErpTheme.purchasesOrangeDark,
                        onSelected: (_) => viewModel.toggleCategory(subCat),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffPermissionsPanel extends StatelessWidget {
  const _StaffPermissionsPanel({required this.viewModel});

  final UserMasterViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ErpTheme.slate200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: ErpTheme.slate50,
            child: const Text(
              'GRANULAR MODULE PERMISSIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: ErpTheme.slate700,
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 680) {
                return Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2.6),
                    1: FixedColumnWidth(84),
                    2: FixedColumnWidth(84),
                    3: FixedColumnWidth(84),
                    4: FixedColumnWidth(84),
                    5: FixedColumnWidth(68),
                  },
                  border: const TableBorder(
                    horizontalInside: BorderSide(color: ErpTheme.slate100),
                  ),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(color: ErpTheme.slate100),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Text(
                            'MODULE NAME',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: ErpTheme.slate500,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            'VIEW',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: ErpTheme.slate500,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            'ADD',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: ErpTheme.slate500,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            'EDIT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: ErpTheme.slate500,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            'DELETE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: ErpTheme.slate500,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            'ALL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: ErpTheme.slate500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ...UserMasterViewModel.modules.map((mod) {
                      final perms =
                          viewModel.modulePermissions[mod.id] ??
                          const ErpModulePermission();
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: Text(
                              mod.label,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: ErpTheme.slate700,
                              ),
                            ),
                          ),
                          Center(
                            child: Checkbox(
                              value: perms.view,
                              activeColor: ErpTheme.dangerRose,
                              onChanged: (v) => viewModel.setModulePermission(
                                mod.id,
                                'view',
                                v ?? false,
                              ),
                            ),
                          ),
                          Center(
                            child: Checkbox(
                              value: perms.add,
                              activeColor: ErpTheme.dangerRose,
                              onChanged: (v) => viewModel.setModulePermission(
                                mod.id,
                                'add',
                                v ?? false,
                              ),
                            ),
                          ),
                          Center(
                            child: Checkbox(
                              value: perms.edit,
                              activeColor: ErpTheme.dangerRose,
                              onChanged: (v) => viewModel.setModulePermission(
                                mod.id,
                                'edit',
                                v ?? false,
                              ),
                            ),
                          ),
                          Center(
                            child: Checkbox(
                              value: perms.delete,
                              activeColor: ErpTheme.dangerRose,
                              onChanged: (v) => viewModel.setModulePermission(
                                mod.id,
                                'delete',
                                v ?? false,
                              ),
                            ),
                          ),
                          Center(
                            child: Checkbox(
                              value: perms.allSelected,
                              activeColor: ErpTheme.slate900,
                              onChanged: (v) =>
                                  viewModel.toggleAllModulePermissions(
                                    mod.id,
                                    v ?? false,
                                  ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: UserMasterViewModel.modules.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: ErpTheme.slate100),
                itemBuilder: (context, idx) {
                  final mod = UserMasterViewModel.modules[idx];
                  final perms =
                      viewModel.modulePermissions[mod.id] ??
                      const ErpModulePermission();
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                mod.label,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: ErpTheme.slate900,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  viewModel.toggleAllModulePermissions(
                                    mod.id,
                                    !perms.allSelected,
                                  ),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              child: Text(
                                perms.allSelected ? 'Clear All' : 'Select All',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _PermChip(
                              label: 'View',
                              selected: perms.view,
                              onSelected: (v) => viewModel.setModulePermission(
                                mod.id,
                                'view',
                                v,
                              ),
                            ),
                            _PermChip(
                              label: 'Add',
                              selected: perms.add,
                              onSelected: (v) => viewModel.setModulePermission(
                                mod.id,
                                'add',
                                v,
                              ),
                            ),
                            _PermChip(
                              label: 'Edit',
                              selected: perms.edit,
                              onSelected: (v) => viewModel.setModulePermission(
                                mod.id,
                                'edit',
                                v,
                              ),
                            ),
                            _PermChip(
                              label: 'Delete',
                              selected: perms.delete,
                              onSelected: (v) => viewModel.setModulePermission(
                                mod.id,
                                'delete',
                                v,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PermChip extends StatelessWidget {
  const _PermChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      selectedColor: ErpTheme.dangerRoseSoft,
      checkmarkColor: ErpTheme.dangerRose,
      onSelected: onSelected,
    );
  }
}
