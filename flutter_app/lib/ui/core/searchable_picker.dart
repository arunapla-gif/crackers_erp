import 'package:flutter/material.dart';

import '../../core/theme/erp_theme.dart';

class SearchablePickerOption<T> {
  const SearchablePickerOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.badge,
    this.badgeColor,
    this.searchTerms = '',
  });

  final T value;
  final String label;
  final String? subtitle;
  final String? badge;
  final Color? badgeColor;
  final String searchTerms;

  bool matches(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.trim().toLowerCase();
    return label.toLowerCase().contains(q) ||
        (subtitle?.toLowerCase().contains(q) ?? false) ||
        (badge?.toLowerCase().contains(q) ?? false) ||
        searchTerms.toLowerCase().contains(q);
  }
}

Future<T?> showSearchablePickerSheet<T>({
  required BuildContext context,
  required String title,
  required List<SearchablePickerOption<T>> options,
  String searchHint = 'Search...',
  T? currentValue,
  String emptyText = 'No matching records found.',
  String? customActionLabel,
  T Function(String query)? onCustomAction,
}) {
  final isWide = MediaQuery.sizeOf(context).width >= 680;
  if (isWide) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
          child: _SearchablePickerBody<T>(
            title: title,
            options: options,
            searchHint: searchHint,
            currentValue: currentValue,
            emptyText: emptyText,
            customActionLabel: customActionLabel,
            onCustomAction: onCustomAction,
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => FractionallySizedBox(
      heightFactor: 0.86,
      child: _SearchablePickerBody<T>(
        title: title,
        options: options,
        searchHint: searchHint,
        currentValue: currentValue,
        emptyText: emptyText,
        customActionLabel: customActionLabel,
        onCustomAction: onCustomAction,
      ),
    ),
  );
}

class _SearchablePickerBody<T> extends StatefulWidget {
  const _SearchablePickerBody({
    required this.title,
    required this.options,
    required this.searchHint,
    required this.currentValue,
    required this.emptyText,
    this.customActionLabel,
    this.onCustomAction,
  });

  final String title;
  final List<SearchablePickerOption<T>> options;
  final String searchHint;
  final T? currentValue;
  final String emptyText;
  final String? customActionLabel;
  final T Function(String query)? onCustomAction;

  @override
  State<_SearchablePickerBody<T>> createState() =>
      _SearchablePickerBodyState<T>();
}

class _SearchablePickerBodyState<T> extends State<_SearchablePickerBody<T>> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.options
        .where((opt) => opt.matches(_query))
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: ErpTheme.slate900,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                tooltip: 'Close',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: widget.searchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
            ),
            onChanged: (val) => setState(() => _query = val),
          ),
        ),
        if (widget.customActionLabel != null &&
            widget.onCustomAction != null &&
            _query.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.of(
                  context,
                ).pop(widget.onCustomAction!(_query.trim())),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: Text('${widget.customActionLabel}: "${_query.trim()}"'),
              ),
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      widget.emptyText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: ErpTheme.slate500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final option = filtered[index];
                    final isSelected =
                        widget.currentValue != null &&
                        option.value == widget.currentValue;
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: ErpTheme.salesBlueSoft,
                      onTap: () => Navigator.of(context).pop(option.value),
                      title: Text(
                        option.label,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w700,
                          color: isSelected
                              ? ErpTheme.salesBlueDark
                              : ErpTheme.slate900,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: option.subtitle != null &&
                              option.subtitle!.trim().isNotEmpty
                          ? Text(
                              option.subtitle!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: ErpTheme.slate500,
                              ),
                            )
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (option.badge != null &&
                              option.badge!.trim().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: (option.badgeColor ?? ErpTheme.slate500)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                option.badge!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: option.badgeColor ?? ErpTheme.slate700,
                                ),
                              ),
                            ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.check_circle,
                              color: ErpTheme.salesBlue,
                              size: 18,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class SearchablePickerField<T> extends StatelessWidget {
  const SearchablePickerField({
    required this.label,
    required this.displayText,
    required this.options,
    required this.onSelected,
    this.value,
    this.hintText = 'Tap to select',
    this.prefixIcon,
    this.onClear,
    this.enabled = true,
    this.searchHint = 'Search...',
    this.customActionLabel,
    this.onCustomAction,
    super.key,
  });

  final String label;
  final String displayText;
  final List<SearchablePickerOption<T>> options;
  final ValueChanged<T> onSelected;
  final T? value;
  final String hintText;
  final IconData? prefixIcon;
  final VoidCallback? onClear;
  final bool enabled;
  final String searchHint;
  final String? customActionLabel;
  final T Function(String query)? onCustomAction;

  @override
  Widget build(BuildContext context) {
    final hasValue = displayText.trim().isNotEmpty;
    return InkWell(
      onTap: !enabled
          ? null
          : () async {
              final picked = await showSearchablePickerSheet<T>(
                context: context,
                title: 'Select $label',
                options: options,
                currentValue: value,
                searchHint: searchHint,
                customActionLabel: customActionLabel,
                onCustomAction: onCustomAction,
              );
              if (picked != null) {
                onSelected(picked);
              }
            },
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18) : null,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasValue && onClear != null && enabled)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  tooltip: 'Clear $label',
                  onPressed: onClear,
                ),
              const Icon(Icons.arrow_drop_down_rounded),
              const SizedBox(width: 4),
            ],
          ),
        ),
        child: Text(
          hasValue ? displayText : hintText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500,
            color: hasValue ? ErpTheme.slate900 : ErpTheme.slate500,
          ),
        ),
      ),
    );
  }
}

