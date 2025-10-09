import 'package:flutter/material.dart';
import 'package:my_mobility_services/design/tokens/app_tokens.dart';
import 'package:my_mobility_services/design/widgets/primitives/glass_container.dart' as primitives;

/// Sticky bottom export bar displayed in Export Mode.
/// Uses a glass container, respects SafeArea, and avoids overflow by
/// sitting above the gesture area. Height >= 72, buttons >= 48.
class TripExportBar extends StatelessWidget {
  final int count;
  final VoidCallback onCancel;
  final VoidCallback onExport;

  const TripExportBar({
    super.key,
    required this.count,
    required this.onCancel,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SafeArea(
          bottom: true,
          minimum: EdgeInsets.fromLTRB(t.spaceMd, t.spaceSm, t.spaceMd, 0),
          child: RepaintBoundary(
            child: SizedBox(
              height: 84, // Taller for more separation from nav bar
              width: double.infinity,
              child: primitives.GlassContainer(
                padding: EdgeInsets.all(t.spaceSm),
                radius: BorderRadius.circular(20),
                blurSigma: 22,
                child: Row(
                  children: [
                    // Cancel (ghost)
                    _GlassButton(
                      label: 'Annuler',
                      onPressed: onCancel,
                      isPrimary: false,
                    ),

                    SizedBox(width: t.spaceSm),

                    // Counter (center)
                    Expanded(
                      child: Center(
                        child: Text(
                          '$count sélectionnés',
                          style: t.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: t.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    SizedBox(width: t.spaceSm),

                    // Export (primary)
                    _GlassButton(
                      label: 'Exporter',
                      onPressed: count > 0 ? onExport : null,
                      isPrimary: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Force spacing between export bar and bottom nav
        SizedBox(height: 24),
      ],
    );
  }
}

class _GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const _GlassButton({
    required this.label,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final bool enabled = onPressed != null;

    Color bg;
    Color fg;
    Color border;

    if (isPrimary) {
      bg = enabled ? t.accent : t.accent.withOpacity(0.3);
      fg = t.accentOn;
      border = enabled ? t.accent : t.glassStroke;
    } else {
      bg = t.glassTint.withOpacity(0.3);
      fg = t.textPrimary.withOpacity(enabled ? 1.0 : 0.5);
      border = t.glassStroke;
    }

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: t.spaceMd, vertical: t.spaceXs),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                label,
                style: t.caption.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


