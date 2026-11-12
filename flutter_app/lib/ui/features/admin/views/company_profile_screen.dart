import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/domain/models/company_profile.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/core/erp_crud_widgets.dart';
import 'package:crackers_erp/ui/core/erp_status_widgets.dart';
import 'package:crackers_erp/ui/features/admin/view_models/company_profile_view_model.dart';
import 'package:crackers_erp/ui/features/masters/views/master_shared_widgets.dart';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({required this.viewModel, super.key});

  final CompanyProfileViewModel viewModel;

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
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
    _nameCtrl.dispose();
    _gstinCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _pincodeCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _syncControllers() {
    final vm = widget.viewModel;
    syncMasterController(_nameCtrl, vm.name);
    syncMasterController(_gstinCtrl, vm.gstin);
    syncMasterController(_addressCtrl, vm.address);
    syncMasterController(_cityCtrl, vm.city);
    syncMasterController(_districtCtrl, vm.district);
    syncMasterController(_pincodeCtrl, vm.pincode);
  }

  void _handleEdit(CompanyProfile profile) {
    widget.viewModel.editProfile(profile);
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _showCredentialsDialog(SystemCredentials creds) async {
    Future<void> copyVal(String label, String? val) async {
      final text = (val ?? '').trim();
      if (text.isEmpty) return;
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$label copied to clipboard.')));
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.vpn_key_outlined, color: ErpTheme.hrIndigo),
            SizedBox(width: 10),
            Expanded(child: Text('Global API Credentials')),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ErpTheme.slate900,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CredRow(
                  label: 'WHITEBOOKS_USERNAME',
                  value: creds.whitebooksUsername ?? '-',
                  accent: const Color(0xFF818CF8),
                  onCopy: () => copyVal('Username', creds.whitebooksUsername),
                ),
                _CredRow(
                  label: 'WHITEBOOKS_PASSWORD',
                  value: creds.whitebooksPassword ?? '-',
                  accent: const Color(0xFF34D399),
                  onCopy: () => copyVal('Password', creds.whitebooksPassword),
                ),
                _CredRow(
                  label: 'WHITEBOOKS_GSTIN',
                  value: creds.whitebooksGstin ?? '-',
                  accent: const Color(0xFFFB7185),
                  onCopy: () => copyVal('GSTIN', creds.whitebooksGstin),
                ),
                _CredRow(
                  label: 'WHITEBOOKS_EMAIL',
                  value: creds.whitebooksEmail ?? '-',
                  accent: const Color(0xFFFBBF24),
                  onCopy: () => copyVal('Email', creds.whitebooksEmail),
                ),
                if ((creds.whitebooksClientId ?? '').isNotEmpty)
                  _CredRow(
                    label: 'WHITEBOOKS_CLIENT_ID',
                    value: creds.whitebooksClientId!,
                    accent: const Color(0xFF38BDF8),
                    onCopy: () =>
                        copyVal('Client ID', creds.whitebooksClientId),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBillingSeriesDialog(CompanyProfile profile) async {
    final vm = widget.viewModel;
    vm.selectProfileForSeries(profile);
    await showDialog<void>(
      context: context,
      builder: (ctx) => _BillingSeriesDialog(viewModel: vm),
    );
    vm.selectProfileForSeries(null);
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final embedded = ErpShellScope.isEmbeddedShell(context);

    return ErpScreenScaffold(
      title: 'Company Profiles',
      actions: [
        IconButton(
          onPressed: () => vm.refresh(),
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
                    title: 'Company Profiles (Multi-GSTIN)',
                    subtitle:
                        'Manage company branches, GSTIN addresses & billing series prefixes',
                    accentColor: ErpTheme.hrIndigo,
                    actions: [
                      if (vm.credentials != null)
                        OutlinedButton.icon(
                          onPressed: () =>
                              _showCredentialsDialog(vm.credentials!),
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text('API Credentials'),
                        ),
                      IconButton(
                        onPressed: vm.isLoading ? null : vm.refresh,
                        icon: const Icon(Icons.refresh_rounded),
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ] else if (vm.credentials != null) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => _showCredentialsDialog(vm.credentials!),
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('View Global API Credentials'),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                      ? 'Edit Company Profile'
                      : 'Add Company Profile (Multi-GSTIN)',
                  accentColor: ErpTheme.hrIndigo,
                  trailing: vm.isEditing
                      ? TextButton.icon(
                          onPressed: vm.clearForm,
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Cancel Edit'),
                        )
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ErpResponsiveFormGrid(
                        minItemWidth: 220,
                        children: [
                          TextField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Branch Name *',
                              hintText: 'Main Branch / Factory 1',
                            ),
                            onChanged: vm.setName,
                          ),
                          TextField(
                            controller: _gstinCtrl,
                            textCapitalization: TextCapitalization.characters,
                            maxLength: 15,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(15),
                            ],
                            decoration: InputDecoration(
                              labelText: 'GSTIN *',
                              hintText: 'e.g. 33AABCU9603R1ZX',
                              counterText: '',
                              suffixIcon: vm.isSearchingGstin
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            onChanged: vm.setGstin,
                          ),
                          IndianStatePickerField(
                            value: vm.state,
                            onChanged: vm.setStateName,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _addressCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Street Address',
                          hintText: 'Street, Area',
                        ),
                        onChanged: vm.setAddress,
                      ),
                      const SizedBox(height: 12),
                      ErpResponsiveFormGrid(
                        minItemWidth: 180,
                        children: [
                          TextField(
                            controller: _cityCtrl,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              hintText: 'City',
                            ),
                            onChanged: vm.setCity,
                          ),
                          TextField(
                            controller: _districtCtrl,
                            decoration: const InputDecoration(
                              labelText: 'District',
                              hintText: 'District',
                            ),
                            onChanged: vm.setDistrict,
                          ),
                          TextField(
                            controller: _pincodeCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Pincode',
                              hintText: '600001',
                              counterText: '',
                            ),
                            onChanged: vm.setPincode,
                          ),
                        ],
                      ),
                      if (vm.addresses.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        AdditionalAddressesBox(addresses: vm.addresses),
                      ],
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: vm.isSaving ? null : vm.saveProfile,
                          style: FilledButton.styleFrom(
                            backgroundColor: ErpTheme.hrIndigo,
                          ),
                          icon: vm.isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            vm.isEditing ? 'Update Profile' : 'Save Profile',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(
                      Icons.apartment_rounded,
                      size: 18,
                      color: ErpTheme.hrIndigo,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'SAVED PROFILES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: ErpTheme.slate500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ErpBadge(
                      label: '${vm.profiles.length}',
                      backgroundColor: ErpTheme.hrIndigoSoft,
                      foregroundColor: ErpTheme.hrIndigo,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (vm.isLoading && vm.profiles.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (vm.profiles.isEmpty)
                  const ErpEmptyState(
                    icon: Icons.business_outlined,
                    title: 'No Company Profiles',
                    subtitle: 'Add a branch profile and GSTIN above to begin.',
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth >= 980
                          ? 3
                          : constraints.maxWidth >= 600
                          ? 2
                          : 1;
                      const spacing = 12.0;
                      final itemWidth =
                          (constraints.maxWidth - spacing * (cols - 1)) / cols;
                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: vm.profiles
                            .map(
                              (profile) => SizedBox(
                                width: itemWidth,
                                child: _CompanyProfileCard(
                                  profile: profile,
                                  onTapSeries: () =>
                                      _showBillingSeriesDialog(profile),
                                  onEdit: () => _handleEdit(profile),
                                  onToggleStatus: () =>
                                      vm.toggleStatus(profile),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CredRow extends StatelessWidget {
  const _CredRow({
    required this.label,
    required this.value,
    required this.accent,
    required this.onCopy,
  });

  final String label;
  final String value;
  final Color accent;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: SelectableText.rich(
              TextSpan(
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.white,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onCopy,
            icon: const Icon(Icons.copy, size: 15, color: ErpTheme.slate400),
            tooltip: 'Copy',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _CompanyProfileCard extends StatelessWidget {
  const _CompanyProfileCard({
    required this.profile,
    required this.onTapSeries,
    required this.onEdit,
    required this.onToggleStatus,
  });

  final CompanyProfile profile;
  final VoidCallback onTapSeries;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) {
    final active = profile.isActive;
    return Opacity(
      opacity: active ? 1.0 : 0.72,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTapSeries,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: active
                            ? ErpTheme.hrIndigoSoft
                            : ErpTheme.slate100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.apartment_rounded,
                        color: active ? ErpTheme.hrIndigo : ErpTheme.slate400,
                      ),
                    ),
                    const Spacer(),
                    MasterStatusBadge(isActive: active),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      color: ErpTheme.salesBlue,
                      tooltip: 'Edit Profile',
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      onPressed: onToggleStatus,
                      icon: Icon(
                        active
                            ? Icons.power_settings_new_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 18,
                      ),
                      color: active
                          ? ErpTheme.dangerRose
                          : ErpTheme.ordersEmerald,
                      tooltip: active ? 'Disable Profile' : 'Enable Profile',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: ErpTheme.slate900,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ErpTheme.slate100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    profile.gstin,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: ErpTheme.hrIndigo,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  profile.state,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ErpTheme.slate700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.fullDispatchAddress,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ErpTheme.slate500,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ErpBadge(
                      label:
                          '${profile.billingSeries.length} Billing Series',
                      backgroundColor: ErpTheme.hrIndigoSoft,
                      foregroundColor: ErpTheme.hrIndigo,
                      icon: Icons.receipt_long_outlined,
                    ),
                    if (profile.addresses.isNotEmpty)
                      ErpBadge(
                        label: '+${profile.addresses.length} Places',
                        backgroundColor: ErpTheme.slate100,
                        foregroundColor: ErpTheme.slate700,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BillingSeriesDialog extends StatefulWidget {
  const _BillingSeriesDialog({required this.viewModel});

  final CompanyProfileViewModel viewModel;

  @override
  State<_BillingSeriesDialog> createState() => _BillingSeriesDialogState();
}

class _BillingSeriesDialogState extends State<_BillingSeriesDialog> {
  final _prefixCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _lastNoCtrl = TextEditingController(text: '0');

  @override
  void dispose() {
    _prefixCtrl.dispose();
    _nameCtrl.dispose();
    _lastNoCtrl.dispose();
    super.dispose();
  }

  Future<void> _addSeries() async {
    final ok = await widget.viewModel.saveBillingSeries();
    if (!mounted) return;
    if (ok) {
      _prefixCtrl.clear();
      _nameCtrl.clear();
      _lastNoCtrl.text = '0';
    }
  }

  Future<void> _deleteSeries(BillingSeries s) async {
    final confirmed = await showErpConfirmDialog(
      context: context,
      title: 'Delete Billing Series?',
      message: 'Delete "${s.prefix} (${s.name})"?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await widget.viewModel.deleteBillingSeries(s.id);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final profile = vm.selectedProfile;
        if (profile == null) {
          return const SizedBox.shrink();
        }

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640, maxHeight: 680),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    color: ErpTheme.slate50,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    border: Border(bottom: BorderSide(color: ErpTheme.slate200)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: ErpTheme.hrIndigoSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.apartment_rounded,
                          color: ErpTheme.hrIndigo,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: ErpTheme.slate900,
                              ),
                            ),
                            Text(
                              profile.gstin,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                                color: ErpTheme.hrIndigo,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ErpTheme.slate50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: ErpTheme.slate200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'REGISTERED ADDRESS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.7,
                                  color: ErpTheme.slate500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile.fullDispatchAddress,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: ErpTheme.slate700,
                                ),
                              ),
                              if (profile.addresses.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                const Text(
                                  'ADDITIONAL PLACES OF BUSINESS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.7,
                                    color: ErpTheme.slate500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ...profile.addresses.map(
                                  (a) => Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(
                                      '${a.type}: ${a.formattedSummary}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: ErpTheme.slate700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Row(
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              size: 16,
                              color: ErpTheme.hrIndigo,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'BILLING SERIES MANAGEMENT',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                color: ErpTheme.slate900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (vm.seriesErrorMessage != null) ...[
                          ErpErrorBanner(message: vm.seriesErrorMessage!),
                          const SizedBox(height: 10),
                        ],
                        ErpResponsiveFormGrid(
                          minItemWidth: 160,
                          spacing: 10,
                          children: [
                            TextField(
                              controller: _prefixCtrl,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'Prefix (e.g. RET-) *',
                              ),
                              onChanged: vm.setSeriesPrefix,
                            ),
                            TextField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Series Name (e.g. Retail) *',
                              ),
                              onChanged: vm.setSeriesName,
                            ),
                            TextField(
                              controller: _lastNoCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Last No.',
                              ),
                              onChanged: vm.setSeriesLastNumber,
                            ),
                            DropdownButtonFormField<String>(
                              initialValue: vm.seriesDocType,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Document Type',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'INV',
                                  child: Text('Tax Invoice'),
                                ),
                                DropdownMenuItem(
                                  value: 'EST',
                                  child: Text('Estimate'),
                                ),
                                DropdownMenuItem(
                                  value: 'PRO',
                                  child: Text('Performa Invoice'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) vm.setSeriesDocType(val);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: vm.isSavingSeries ? null : _addSeries,
                            style: FilledButton.styleFrom(
                              backgroundColor: ErpTheme.hrIndigo,
                            ),
                            icon: vm.isSavingSeries
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.add),
                            label: const Text('Add Series'),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (profile.billingSeries.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: ErpTheme.slate50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: ErpTheme.slate200),
                            ),
                            child: const Column(
                              children: [
                                Text(
                                  'No billing series added yet.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: ErpTheme.slate500,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Add prefixes like "RET-2425/" or "WHS-" to auto-generate invoice numbers.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ErpTheme.slate400,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...profile.billingSeries.map((s) {
                            final (bg, fg, label) = switch (s.docType) {
                              'PRO' => (
                                const Color(0xFFF3E8FF),
                                ErpTheme.hrPurpleDark,
                                'PERFORMA',
                              ),
                              'EST' => (
                                ErpTheme.productionAmberSoft,
                                ErpTheme.productionAmberDark,
                                'ESTIMATE',
                              ),
                              _ => (
                                ErpTheme.hrIndigoSoft,
                                ErpTheme.hrIndigo,
                                'INVOICE',
                              ),
                            };
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: ErpTheme.slate200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: bg,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      s.prefix,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                        color: fg,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                s.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: ErpTheme.slate900,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            ErpBadge(
                                              label: label,
                                              backgroundColor: bg,
                                              foregroundColor: fg,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Current Bill No: ${s.lastNumber} (Next: ${s.prefix}${s.formattedNextNumber})',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: ErpTheme.ordersEmerald,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: vm.isSavingSeries
                                        ? null
                                        : () => _deleteSeries(s),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                    ),
                                    color: ErpTheme.dangerRose,
                                    tooltip: 'Delete Series',
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
