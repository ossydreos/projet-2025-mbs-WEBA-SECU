import 'package:flutter/material.dart';
import 'package:my_mobility_services/design/tokens/app_tokens.dart';

class LgSegmentedSwitch extends StatelessWidget {
  final List<String> values;
  final int index;
  final ValueChanged<int> onChanged;

  const LgSegmentedSwitch({
    super.key,
    required this.values,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return RepaintBoundary(
      child: Semantics(
        toggled: true,
        child: Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: t.glassTint.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.glassStroke.withOpacity(0.24), width: 1),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double itemWidth = (constraints.maxWidth - 8) / values.length;
              return Stack(
                children: [
                  Positioned(
                    left: 4 + itemWidth * index,
                    top: 4,
                    bottom: 4,
                    width: itemWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: t.accent.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (int i = 0; i < values.length; i++)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => onChanged(i),
                            child: Container(
                              height: 40,
                              alignment: Alignment.center,
                              child: Text(
                                values[i],
                                style: t.caption.copyWith(
                                  color: i == index ? t.accentOn : t.textPrimary.withOpacity(0.72),
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}


