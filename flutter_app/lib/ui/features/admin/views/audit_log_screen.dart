import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/domain/models/audit_log.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/core/erp_crud_widgets.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/features/admin/view_models/audit_log_view_model.dart';
import 'package:crackers_erp/ui/features/auth/view_models/auth_view_model.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({
    required this.viewModel,
    required this.authViewModel,
    super.key,
  });

  final AuditLogViewModel viewModel;
  final AuthViewModel authViewModel;

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.authViewModel.currentUser?.isAdmin == true) {
        widget.viewModel.loadLogs();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ({Color bg, Color fg, IconData icon}) _actionStyle(String action) {
    switch (action) {
      case 'CREATE':
        return (
          bg: ErpTheme.ordersEmeraldSoft,
          fg: ErpTheme.ordersEmerald,
          icon: Icons.add_circle_outline_rounded,
        );
      case 'UPDATE':
        return (
          bg: ErpTheme.hrIndigoSoft,
          fg: ErpTheme.hrIndigo,
          icon: Icons.edit_rounded,
        );
      case 'DELETE':
        return (
          bg: ErpTheme.dangerRoseSoft,
          fg: ErpTheme.dangerRose,
          icon: Icons.delete_forever_rounded,
        );
      default:
        return (
          bg: ErpTheme.slate100,
          fg: ErpTheme.slate700,
          icon: Icons.info_outline_rounded,
        );
    }
  }

  ({String label, Color bg, Color fg}) _moduleStyle(String module) {
    switch (module) {
      case 'production':
        return (
          label: 'PRODUCTION',
          bg: ErpTheme.productionAmberSoft,
          fg: ErpTheme.productionAmber,
        );
      case 'advances':
        return (
          label: 'ADVANCES',
          bg: ErpTheme.hrIndigoSoft,
          fg: ErpTheme.hrIndigo,
        );
      case 'payroll':
        return (
          label: 'PAYROLL',
          bg: ErpTheme.ordersEmeraldSoft,
          fg: ErpTheme.ordersEmerald,
        );
      default:
        return (
          label: module.toUpperCase(),
          bg: ErpTheme.slate100,
          fg: ErpTheme.slate700,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authViewModel.currentUser;
    final isEmbedded = ErpShellScope.isEmbeddedShell(context);

    if (user != null && !user.isAdmin) {
      return Scaffold(
        appBar: isEmbedded ? null : AppBar(title: const Text('Audit Logs')),
        body: const ErpEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Admin Access Required',
          subtitle:
              'Activity & anti-malpractice audit logs are restricted to Admin accounts.',
        ),
      );
    }

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final timeFmt = DateFormat('dd MMM yyyy, hh:mm a');

        return Scaffold(
          backgroundColor: ErpTheme.slate50,
          appBar: isEmbedded
              ? null
              : AppBar(
                  title: const Text('Audit Logs'),
                  actions: [
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: vm.isLoading ? null : vm.loadLogs,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                    AccountAppBarAction(authViewModel: widget.authViewModel),
                  ],
                ),
          body: Column(
            children: [
              if (isEmbedded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: ErpSectionHeaderBar(
                    title: 'Audit Logs',
                    subtitle:
                        'Tamper-proof trail of Production, Advances, and Payroll changes (who changed what).',
                    accentColor: ErpTheme.hrIndigo,
                    actions: [
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: vm.isLoading ? null : vm.loadLogs,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                ),

              // Search & Filter Controls
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onSubmitted: vm.setSearchQuery,
                            decoration: InputDecoration(
                              hintText:
                                  'Search worker, supervisor, date, or item...',
                              isDense: true,
                              prefixIcon: const Icon(Icons.search, size: 18),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        vm.setSearchQuery('');
                                      },
                                    )
                                  : IconButton(
                                      tooltip: 'Search',
                                      icon: const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                      ),
                                      onPressed: () => vm.setSearchQuery(
                                        _searchController.text,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        if (vm.users.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: ErpTheme.slate50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: ErpTheme.slate200),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: vm.users.contains(vm.userFilter)
                                    ? vm.userFilter
                                    : 'all',
                                items: [
                                  const DropdownMenuItem(
                                    value: 'all',
                                    child: Text(
                                      'All Users',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  ...vm.users.map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(
                                        u,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) vm.setUserFilter(val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              key: const ValueKey('audit-only-flagged-chip'),
                              avatar: Icon(
                                Icons.warning_amber_rounded,
                                size: 15,
                                color: vm.onlyFlagged
                                    ? ErpTheme.dangerRose
                                    : ErpTheme.slate500,
                              ),
                              label: const Text('Flagged Alerts'),
                              selected: vm.onlyFlagged,
                              selectedColor: ErpTheme.dangerRoseSoft,
                              checkmarkColor: ErpTheme.dangerRose,
                              labelStyle: TextStyle(
                                fontSize: 11.5,
                                fontWeight: vm.onlyFlagged
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: vm.onlyFlagged
                                    ? ErpTheme.dangerRose
                                    : ErpTheme.slate700,
                              ),
                              onSelected: vm.toggleOnlyFlagged,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          for (final mod in const [
                            ('all', 'All Modules'),
                            ('production', 'Production'),
                            ('advances', 'Advances'),
                            ('payroll', 'Payroll'),
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(mod.$2),
                                selected: vm.moduleFilter == mod.$1,
                                onSelected: (_) => vm.setModuleFilter(mod.$1),
                                visualDensity: VisualDensity.compact,
                                labelStyle: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          const SizedBox(width: 4),
                          for (final act in const [
                            ('all', 'All Actions'),
                            ('CREATE', 'Created'),
                            ('UPDATE', 'Updated'),
                            ('DELETE', 'Deleted'),
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(act.$2),
                                selected: vm.actionFilter == act.$1,
                                onSelected: (_) => vm.setActionFilter(act.$1),
                                visualDensity: VisualDensity.compact,
                                labelStyle: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: ErpTheme.slate200),

              if (vm.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: ErpErrorBanner(
                    message: vm.errorMessage!,
                    onRetry: vm.loadLogs,
                    onDismiss: vm.clearError,
                  ),
                ),

              // Results List
              Expanded(
                child: vm.isLoading && vm.logs.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : vm.logs.isEmpty
                    ? RefreshIndicator(
                        onRefresh: vm.loadLogs,
                        child: ListView(
                          children: const [
                            SizedBox(height: 80),
                            ErpEmptyState(
                              icon: Icons.policy_outlined,
                              title: 'No Audit Entries Found',
                              subtitle:
                                  'Changes to Production, Advances, and Payroll will automatically appear here.',
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: vm.loadLogs,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                          itemCount: vm.logs.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (ctx, idx) {
                            final log = vm.logs[idx];
                            return _buildLogCard(log, timeFmt);
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogCard(AuditLogEntry log, DateFormat timeFmt) {
    final act = _actionStyle(log.action);
    final mod = _moduleStyle(log.module);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: log.isFlagged
              ? ErpTheme.dangerRose.withValues(alpha: 0.45)
              : ErpTheme.slate200,
          width: log.isFlagged ? 1.4 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ErpBadge(
                  label: log.action,
                  backgroundColor: act.bg,
                  foregroundColor: act.fg,
                ),
                ErpBadge(
                  label: mod.label,
                  backgroundColor: mod.bg,
                  foregroundColor: mod.fg,
                ),
                if (log.isBackdated)
                  const ErpBadge(
                    label: 'BACKDATED EDIT',
                    backgroundColor: ErpTheme.dangerRoseSoft,
                    foregroundColor: ErpTheme.dangerRose,
                  ),
                Text(
                  timeFmt.format(log.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ErpTheme.slate500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 15,
                  color: ErpTheme.slate700,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'By ${log.username} (${log.userRole})'
                    '${log.employeeName != null ? '  •  Worker: ${log.employeeName}' : ''}'
                    '${log.targetDate != null ? '  •  Date: ${log.targetDate}' : ''}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: ErpTheme.slate900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: ErpTheme.slate50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ErpTheme.slate200),
              ),
              child: Text(
                log.summary,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: ErpTheme.slate800,
                ),
              ),
            ),
            if (log.beforeData != null || log.afterData != null)
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(top: 4),
                  visualDensity: VisualDensity.compact,
                  title: const Text(
                    'View Before / After Snapshot',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: ErpTheme.hrIndigo,
                    ),
                  ),
                  children: [
                    if (log.beforeData != null)
                      _snapshotBox('Before', log.beforeData!),
                    if (log.beforeData != null && log.afterData != null)
                      const SizedBox(height: 6),
                    if (log.afterData != null)
                      _snapshotBox('After', log.afterData!),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _snapshotBox(String label, Map<String, dynamic> data) {
    const encoder = JsonEncoder.withIndent('  ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ErpTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: ErpTheme.slate500,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            encoder.convert(data),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: ErpTheme.slate700,
            ),
          ),
        ],
      ),
    );
  }
}

