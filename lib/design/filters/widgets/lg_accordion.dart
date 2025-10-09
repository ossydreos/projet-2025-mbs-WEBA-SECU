import 'package:flutter/material.dart';
import 'package:my_mobility_services/design/tokens/app_tokens.dart';

class LgAccordion extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  const LgAccordion({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  State<LgAccordion> createState() => _LgAccordionState();
}

class _LgAccordionState extends State<LgAccordion> with SingleTickerProviderStateMixin {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: t.glassTint.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.glassStroke.withOpacity(0.24), width: 1),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: t.spaceLg, vertical: t.spaceMd),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: t.body.copyWith(fontWeight: FontWeight.w600, color: t.textPrimary),
                    ),
                  ),
                  AnimatedRotation(
                    duration: t.motionBase,
                    turns: _expanded ? 0.25 : 0.0,
                    child: Icon(Icons.chevron_right_rounded, color: t.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedAlign(
              alignment: Alignment.center,
              heightFactor: _expanded ? 1.0 : 0.0,
              duration: t.motionBase,
              curve: Curves.easeInOut,
              child: Padding(
                padding: EdgeInsets.fromLTRB(t.spaceLg, 0, t.spaceLg, t.spaceLg),
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


