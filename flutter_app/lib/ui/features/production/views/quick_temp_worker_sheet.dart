import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/core/utils/tamil_transliteration.dart';
import 'package:crackers_erp/domain/models/employee.dart';
import 'package:crackers_erp/ui/features/production/view_models/daily_production_view_model.dart';

/// Opens a fast, zero-rupee-safe bottom sheet to register a walk-in Temporary
/// worker directly from Daily Production Hub or Matrix.
Future<Employee?> showQuickTempWorkerSheet(
  BuildContext context, {
  required DailyProductionViewModel viewModel,
  String? initialRole,
}) {
  return showModalBottomSheet<Employee>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _QuickTempWorkerSheet(
      viewModel: viewModel,
      initialRole: initialRole,
    ),
  );
}

class _QuickTempWorkerSheet extends StatefulWidget {
  const _QuickTempWorkerSheet({
    required this.viewModel,
    this.initialRole,
  });

  final DailyProductionViewModel viewModel;
  final String? initialRole;

  @override
  State<_QuickTempWorkerSheet> createState() => _QuickTempWorkerSheetState();
}

class _QuickTempWorkerSheetState extends State<_QuickTempWorkerSheet> {
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
    'Rolling',
    'Filling',
    'Fuse',
    'Packing',
    'Mixing',
    'Drying',
    'Helper',
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialRole?.trim();
    if (initial != null &&
        initial.isNotEmpty &&
        initial.toLowerCase() != 'all') {
      _roleCtrl.text = initial;
    }
  }

  @override
  void dispose() {
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
    final transliterated = TamilTransliteration.transliterate(val);
    _tamilCtrl.text = transliterated;
  }

  Future<void> _submit() async {
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
      Navigator.of(context).pop(created);
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
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
                      color: ErpTheme.productionAmberSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: ErpTheme.productionAmber,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Add Temporary Worker',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: ErpTheme.slate900,
                          ),
                        ),
                        Text(
                          'Appears immediately in the worksheet with TEMP badge',
                          style: TextStyle(
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
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
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
                        'Saved as Temporary (TEMP). Admin sets wage rate & regularizes later.',
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
              const SizedBox(height: 14),
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
                        onPressed: () =>
                            setState(() => _roleCtrl.text = preset),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _paymentType,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Work Type',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Contractual',
                          child: Text('Contractual (Piece Rate)'),
                        ),
                        DropdownMenuItem(
                          value: 'Monthly',
                          child: Text('Monthly'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _paymentType = val);
                      },
                    ),
                  ),
                ],
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
                  onPressed: _isSaving ? null : _submit,
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
      ),
    );
  }
}
