import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/core/utils/tamil_transliteration.dart';
import 'package:crackers_erp/domain/models/employee.dart';
import 'package:crackers_erp/ui/features/production/view_models/daily_production_view_model.dart';

class TempRosterSheetResult {
  const TempRosterSheetResult({
    this.createdWorker,
    this.rosterUpdated = false,
    this.selectedCount = 0,
    this.selectedRoles = const {},
  });

  final Employee? createdWorker;
  final bool rosterUpdated;
  final int selectedCount;
  final Set<String> selectedRoles;
}

/// Opens a 2-in-1 On-Demand Temp Roster sheet directly from Daily Production
/// Hub or Matrix:
/// 1. Pick which existing Temporary workers showed up today (1-tap checkboxes).
/// 2. Register a brand-new walk-in Temporary worker (zero-rupee safe).
Future<TempRosterSheetResult?> showTempRosterSheet(
  BuildContext context, {
  required DailyProductionViewModel viewModel,
  String? initialRole,
  bool canCreateNew = true,
}) {
  return showModalBottomSheet<TempRosterSheetResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _TempRosterSheet(
      viewModel: viewModel,
      initialRole: initialRole,
      canCreateNew: canCreateNew,
    ),
  );
}

class _TempRosterSheet extends StatefulWidget {
  const _TempRosterSheet({
    required this.viewModel,
    this.initialRole,
    required this.canCreateNew,
  });

  final DailyProductionViewModel viewModel;
  final String? initialRole;
  final bool canCreateNew;

  @override
  State<_TempRosterSheet> createState() => _TempRosterSheetState();
}

class _TempRosterSheetState extends State<_TempRosterSheet> {
  // 0 = Pick Existing Temp Workers, 1 = Add New Temp Worker
  late int _activeTab;

  // Roster picker state
  final _searchCtrl = TextEditingController();
  late Set<int> _selectedIds;
  late String _roleFilter;

  // New temp worker form state
  final _formKey = GlobalKey<FormState>();
  final _englishCtrl = TextEditingController();
  final _tamilCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  bool _userEditedTamil = false;
  bool _isSaving = false;
  String _paymentType = 'Contractual';
  String? _localError;

  static const List<String> _defaultRolePresets = [
    'Tape',
    'Chemical',
    'Valayam Contract',
    'Rolling',
    'Filling',
    'Packing',
    'Helper',
  ];

  @override
  void initState() {
    super.initState();
    final pool = widget.viewModel.allTemporaryWorkers;
    _selectedIds = Set<int>.from(widget.viewModel.selectedTempIdsForDate);
    final initial = widget.initialRole?.trim();
    final hasInitialRole =
        initial != null &&
        initial.isNotEmpty &&
        initial.toLowerCase() != 'all';

    _roleFilter =
        hasInitialRole &&
            pool.any(
              (e) => e.roleGroup.toLowerCase() == initial.toLowerCase(),
            )
        ? pool
              .firstWhere(
                (e) => e.roleGroup.toLowerCase() == initial.toLowerCase(),
              )
              .roleGroup
        : 'All';

    if (hasInitialRole) {
      _roleCtrl.text = initial;
    }

    // If no existing temporary workers exist yet, jump straight to New Temp Worker
    _activeTab = (pool.isEmpty && widget.canCreateNew) ? 1 : 0;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _englishCtrl.dispose();
    _tamilCtrl.dispose();
    _roleCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  List<String> get _rolePresets {
    final seen = <String>{};
    final result = <String>[];
    for (final role in widget.viewModel.availableRoles) {
      if (role == 'All' || role == 'Unassigned') continue;
      if (seen.add(role.toLowerCase())) {
        result.add(role);
      }
    }
    for (final preset in _defaultRolePresets) {
      if (seen.add(preset.toLowerCase())) {
        result.add(preset);
      }
    }
    return result;
  }

  void _onEnglishChanged(String val) {
    if (_userEditedTamil) return;
    _tamilCtrl.text = TamilTransliteration.transliterate(val);
  }

  void _applyRoster() {
    widget.viewModel.setTempRosterForDate(_selectedIds);
    final selectedRoles = <String>{};
    for (final emp in widget.viewModel.allTemporaryWorkers) {
      if (_selectedIds.contains(emp.id)) {
        selectedRoles.add(emp.roleGroup);
      }
    }
    Navigator.of(context).pop(
      TempRosterSheetResult(
        rosterUpdated: true,
        selectedCount: widget.viewModel.selectedTempCountForDate,
        selectedRoles: selectedRoles,
      ),
    );
  }

  Future<void> _submitNewTempWorker() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _localError = null;
    });

    final fullName = TamilTransliteration.formatBilingualName(
      _englishCtrl.text,
      _tamilCtrl.text,
    );

    final created = await widget.viewModel.addQuickTemporaryWorker(
      name: fullName,
      role: _roleCtrl.text.trim(),
      mobile: _mobileCtrl.text.trim(),
      paymentType: _paymentType,
    );

    if (!mounted) return;
    if (created != null) {
      Navigator.of(context).pop(
        TempRosterSheetResult(
          createdWorker: created,
          rosterUpdated: true,
          selectedCount: widget.viewModel.selectedTempCountForDate,
          selectedRoles: {created.roleGroup},
        ),
      );
    } else {
      setState(() {
        _isSaving = false;
        _localError =
            widget.viewModel.errorMessage ?? 'Could not add temporary worker.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pool = widget.viewModel.allTemporaryWorkers;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        12,
        18,
        MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: ErpTheme.slate200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ErpTheme.hrIndigoSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _activeTab == 0
                        ? Icons.how_to_reg_rounded
                        : Icons.person_add_alt_1_rounded,
                    color: ErpTheme.hrIndigo,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _activeTab == 0
                            ? "Today's Temp Roster"
                            : 'Quick Add Temporary Worker',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: ErpTheme.slate900,
                        ),
                      ),
                      Text(
                        _activeTab == 0
                            ? 'Tick only the temp workers who came today'
                            : 'Appears immediately in today\'s worksheet with TEMP badge',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: ErpTheme.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
              ],
            ),
            if (widget.canCreateNew) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      key: const ValueKey('temp-sheet-tab-roster'),
                      label: SizedBox(
                        width: double.infinity,
                        child: Text(
                          'Existing Pool (${pool.length})',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      selected: _activeTab == 0,
                      onSelected: (_) => setState(() => _activeTab = 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      key: const ValueKey('temp-sheet-tab-new'),
                      label: const SizedBox(
                        width: double.infinity,
                        child: Text(
                          '+ New Temp Worker',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      selected: _activeTab == 1,
                      onSelected: (_) => setState(() => _activeTab = 1),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            if (_activeTab == 0)
              Flexible(child: _buildRosterPicker(pool))
            else
              Flexible(child: _buildNewWorkerForm()),
          ],
        ),
      ),
    );
  }

  Widget _buildRosterPicker(List<Employee> pool) {
    if (pool.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.groups_2_outlined,
              size: 40,
              color: ErpTheme.slate400,
            ),
            const SizedBox(height: 8),
            const Text(
              'No temporary workers registered yet',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: ErpTheme.slate700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add a walk-in temporary worker once — next time you can tick them in 1 tap.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: ErpTheme.slate500),
            ),
            if (widget.canCreateNew) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => setState(() => _activeTab = 1),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Add First Temp Worker'),
              ),
            ],
          ],
        ),
      );
    }

    final roles = <String>{
      for (final emp in pool) emp.roleGroup,
    }.toList()..sort(DailyProductionViewModel.compareRoles);

    final q = _searchCtrl.text.trim().toLowerCase();
    final filtered = pool.where((emp) {
      if (_roleFilter != 'All' &&
          emp.roleGroup.toLowerCase() != _roleFilter.toLowerCase()) {
        return false;
      }
      if (q.isEmpty) return true;
      return emp.matchesSearchQuery(q) ||
          emp.roleGroup.toLowerCase().contains(q);
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('temp-roster-search-field'),
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search temp worker name...',
            isDense: true,
            prefixIcon: const Icon(Icons.search, size: 18),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
        ),
        if (roles.length > 1) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text('All (${pool.length})'),
                    selected: _roleFilter == 'All',
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => setState(() => _roleFilter = 'All'),
                  ),
                ),
                for (final r in roles)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(
                        '$r (${pool.where((e) => e.roleGroup == r).length})',
                      ),
                      selected: _roleFilter == r,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() => _roleFilter = r),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        Flexible(
          child: filtered.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No matching temporary workers.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: ErpTheme.slate500),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: ErpTheme.slate100),
                  itemBuilder: (ctx, i) {
                    final emp = filtered[i];
                    final hasPieces = widget.viewModel
                        .tempWorkerHasPiecesForDate(emp.id);
                    final pieces = widget.viewModel.getWorkerTotalQuantity(
                      emp.id,
                    );
                    final isSelected =
                        hasPieces || _selectedIds.contains(emp.id);

                    return CheckboxListTile(
                      key: ValueKey('temp-roster-item-${emp.id}'),
                      value: isSelected,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: ErpTheme.hrIndigo,
                      onChanged: hasPieces
                          ? null
                          : (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedIds.add(emp.id);
                                } else {
                                  _selectedIds.remove(emp.id);
                                }
                              });
                            },
                      title: Text(
                        emp.displayTamilName != emp.displayEnglishName
                            ? '${emp.displayTamilName} • ${emp.displayEnglishName}'
                            : emp.displayEnglishName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: ErpTheme.slate900,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          Text(
                            emp.roleGroup,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: ErpTheme.slate500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: ErpTheme.productionAmberSoft,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'TEMP',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: ErpTheme.productionAmber,
                              ),
                            ),
                          ),
                          if (hasPieces) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: ErpTheme.ordersEmeraldSoft,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$pieces pcs logged',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: ErpTheme.ordersEmerald,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 46,
          child: FilledButton.icon(
            key: const ValueKey('temp-roster-apply-button'),
            style: FilledButton.styleFrom(
              backgroundColor: ErpTheme.hrIndigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _applyRoster,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(
              'Apply Today\'s Roster (${_selectedIds.length} Selected)',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewWorkerForm() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: ErpTheme.slate50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ErpTheme.slate200),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 15,
                    color: ErpTheme.hrIndigo,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Saved as Temporary (TEMP) & checked in for today. Admin sets wage rate separately.',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: ErpTheme.slate700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_localError != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ErpTheme.dangerRoseSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _localError!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ErpTheme.dangerRose,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('quick-temp-name-field'),
              controller: _englishCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              onChanged: _onEnglishChanged,
              decoration: const InputDecoration(
                labelText: 'Worker Name (English) *',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (val) => (val == null || val.trim().isEmpty)
                  ? 'Enter worker name'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const ValueKey('quick-temp-tamil-field'),
              controller: _tamilCtrl,
              onChanged: (_) => _userEditedTamil = true,
              decoration: const InputDecoration(
                labelText: 'Tamil Name (Auto-filled)',
                prefixIcon: Icon(Icons.translate_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('quick-temp-role-field'),
              controller: _roleCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Department / Role *',
                prefixIcon: Icon(Icons.work_outline_rounded),
              ),
              validator: (val) => (val == null || val.trim().isEmpty)
                  ? 'Select or enter department'
                  : null,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _rolePresets
                  .map(
                    (preset) => ActionChip(
                      label: Text(
                        preset,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _roleCtrl.text = preset),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _paymentType,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Work Type'),
              items: const [
                DropdownMenuItem(
                  value: 'Contractual',
                  child: Text('Contractual (Piece Rate)'),
                ),
                DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _paymentType = val);
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const ValueKey('quick-temp-mobile-field'),
              controller: _mobileCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                labelText: 'Mobile Number (Optional)',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                key: const ValueKey('quick-temp-save-button'),
                style: FilledButton.styleFrom(
                  backgroundColor: ErpTheme.productionAmber,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isSaving ? null : _submitNewTempWorker,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.person_add_rounded, size: 18),
                label: Text(
                  _isSaving ? 'Adding Worker...' : 'Add Temporary Worker',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
