import 'package:flutter/material.dart';
import 'package:my_mobility_services/design/tokens/app_tokens.dart';

class LgChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const LgChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final Color bg = selected
        ? t.accent.withOpacity(0.18)
        : t.glassTint.withOpacity(0.12);
    final Color outline = selected
        ? t.accent.withOpacity(0.24)
        : t.glassStroke.withOpacity(0.24);
    final Color text = selected ? t.accentOn : t.textPrimary.withOpacity(0.88);

    return RepaintBoundary(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: t.spaceMd,
              vertical: t.spaceSm,
            ),
            constraints: BoxConstraints(minHeight: 36, minWidth: 48),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: outline, width: 1),
            ),
            child: Center(
              child: Text(
                label,
                style: t.caption.copyWith(
                  color: text,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


