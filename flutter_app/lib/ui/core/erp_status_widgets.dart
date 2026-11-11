import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/erp_theme.dart';

class ErpStatTile extends StatelessWidget {
  const ErpStatTile({
    required this.label,
    required this.value,
    required this.accentColor,
    required this.icon,
    super.key,
  });

  final String label;
  final String value;
  final Color accentColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ErpTheme.slate200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ErpTheme.slate500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: ErpTheme.slate900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ErpBadge extends StatelessWidget {
  const ErpBadge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.icon,
    super.key,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foregroundColor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: foregroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ErpErrorBanner extends StatelessWidget {
  const ErpErrorBanner({
    required this.message,
    this.onRetry,
    this.onDismiss,
    super.key,
  });

  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ErpTheme.dangerRoseSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ErpTheme.dangerRose.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: ErpTheme.dangerRose, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: ErpTheme.slate900,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: ErpTheme.slate700,
              tooltip: 'Dismiss',
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}

class ErpEmptyState extends StatelessWidget {
  const ErpEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ErpTheme.slate100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, size: 36, color: ErpTheme.slate500),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: ErpTheme.slate900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: ErpTheme.slate500,
                  height: 1.4,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class QuantityStepperField extends StatefulWidget {
  const QuantityStepperField({
    required this.quantity,
    required this.onChanged,
    this.showQuickTen = true,
    super.key,
  });

  final int quantity;
  final ValueChanged<int> onChanged;
  final bool showQuickTen;

  @override
  State<QuantityStepperField> createState() => _QuantityStepperFieldState();
}

class _QuantityStepperFieldState extends State<QuantityStepperField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.quantity > 0 ? '${widget.quantity}' : '',
    );
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant QuantityStepperField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity != widget.quantity) {
      final currentParsed = int.tryParse(_controller.text.trim()) ?? 0;
      if (!_focusNode.hasFocus || currentParsed != widget.quantity) {
        final nextText = widget.quantity > 0 ? '${widget.quantity}' : '';
        if (_controller.text != nextText) {
          _controller.value = TextEditingValue(
            text: nextText,
            selection: TextSelection.collapsed(offset: nextText.length),
          );
        }
      }
    }
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      final parsed = int.tryParse(_controller.text.trim()) ?? 0;
      final normalizedText = parsed > 0 ? '$parsed' : '';
      if (_controller.text != normalizedText) {
        _controller.text = normalizedText;
      }
      if (parsed != widget.quantity) {
        widget.onChanged(parsed);
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperButton(
          icon: Icons.remove,
          tooltip: 'Decrease by 1',
          onPressed: widget.quantity > 0
              ? () => widget.onChanged(widget.quantity - 1)
              : null,
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 68,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: widget.quantity > 0
                  ? ErpTheme.productionAmber
                  : ErpTheme.slate700,
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: const TextStyle(color: ErpTheme.slate500),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 10,
              ),
              fillColor: widget.quantity > 0
                  ? ErpTheme.productionAmberSoft.withValues(alpha: 0.4)
                  : ErpTheme.slate50,
            ),
            onChanged: (raw) {
              final parsed = int.tryParse(raw.trim()) ?? 0;
              widget.onChanged(parsed);
            },
          ),
        ),
        const SizedBox(width: 6),
        _StepperButton(
          icon: Icons.add,
          tooltip: 'Increase by 1',
          onPressed: () => widget.onChanged(widget.quantity + 1),
        ),
        if (widget.showQuickTen) ...[
          const SizedBox(width: 4),
          InkWell(
            onTap: () => widget.onChanged(widget.quantity + 10),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: ErpTheme.productionAmberSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: ErpTheme.productionAmber.withValues(alpha: 0.35),
                ),
              ),
              alignment: Alignment.center,
              child: const Text(
                '+10',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: ErpTheme.productionAmber,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: enabled ? ErpTheme.slate100 : ErpTheme.slate50,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 38,
            height: 40,
            child: Icon(
              icon,
              size: 18,
              color: enabled ? ErpTheme.slate900 : ErpTheme.slate200,
            ),
          ),
        ),
      ),
    );
  }
}

