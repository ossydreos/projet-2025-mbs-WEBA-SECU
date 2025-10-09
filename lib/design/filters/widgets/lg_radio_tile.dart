import 'package:flutter/material.dart';
import 'package:my_mobility_services/design/tokens/app_tokens.dart';

class LgRadioTile<T> extends StatelessWidget {
  final T value;
  final T? groupValue;
  final String label;
  final IconData? leadingIcon;
  final ValueChanged<T> onChanged;

  const LgRadioTile({
    super.key,
    required this.value,
    required this.groupValue,
    required this.label,
    required this.onChanged,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final bool selected = value == groupValue;
    final Color bg = selected
        ? t.accent.withOpacity(0.18)
        : t.glassTint.withOpacity(0.12);
    final Color outline = selected
        ? t.accent.withOpacity(0.24)
        : t.glassStroke.withOpacity(0.24);
    final Color text = selected ? t.accentOn : t.textPrimary;

    return RepaintBoundary(
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: Container(
            height: 56,
            padding: EdgeInsets.symmetric(horizontal: t.spaceLg),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: outline, width: 1),
            ),
            child: Row(
              children: [
                if (leadingIcon != null) ...[
                  Icon(
                    leadingIcon,
                    size: 18,
                    color: selected ? t.accentOn : t.textSecondary,
                  ),
                  SizedBox(width: t.spaceMd),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: t.body.copyWith(
                      color: text,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: t.spaceMd),
                _RadioVisual(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioVisual extends StatelessWidget {
  final bool selected;
  const _RadioVisual({required this.selected});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: selected ? t.accent : t.glassStroke.withOpacity(0.6),
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: selected ? t.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}


