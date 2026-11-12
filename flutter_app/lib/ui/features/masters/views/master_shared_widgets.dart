import 'package:flutter/material.dart';

import 'package:crackers_erp/core/constants/indian_states.dart';
import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/domain/models/customer.dart';
import 'package:crackers_erp/ui/core/searchable_picker.dart';

void syncMasterController(TextEditingController controller, String value) {
  if (controller.text != value) {
    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}

class MasterFormCard extends StatelessWidget {
  const MasterFormCard({
    required this.title,
    required this.accentColor,
    required this.child,
    this.trailing,
    super.key,
  });

  final String title;
  final Color accentColor;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.25),
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                      color: accentColor,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class MasterStatusBadge extends StatelessWidget {
  const MasterStatusBadge({required this.isActive, super.key});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? ErpTheme.ordersEmeraldSoft : ErpTheme.dangerRoseSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'INACTIVE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: isActive ? ErpTheme.ordersEmerald : ErpTheme.dangerRose,
        ),
      ),
    );
  }
}

class AdditionalAddressesBox extends StatelessWidget {
  const AdditionalAddressesBox({required this.addresses, super.key});

  final List<PartyAddress> addresses;

  @override
  Widget build(BuildContext context) {
    final extra = addresses
        .where((a) => a.type != 'Principal Place')
        .toList();
    if (extra.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ErpTheme.slate50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ErpTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Additional Places of Business (Auto-saved):',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: ErpTheme.slate500,
            ),
          ),
          const SizedBox(height: 4),
          ...extra.map(
            (addr) => Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                '${addr.type}: ${addr.formattedSummary}',
                style: const TextStyle(fontSize: 12, color: ErpTheme.slate700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IndianStatePickerField extends StatelessWidget {
  const IndianStatePickerField({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final normalized = value.trim();
    return SearchablePickerField<String>(
      label: 'State',
      value: normalized.isEmpty ? null : normalized,
      displayText: normalized.isEmpty ? '' : normalized,
      hintText: 'Select State',
      options: indianStatesAndUts
          .map((s) => SearchablePickerOption(value: s, label: s))
          .toList(),
      onSelected: onChanged,
      onClear: normalized.isEmpty ? null : () => onChanged(''),
    );
  }
}

