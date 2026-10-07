import 'package:flutter/material.dart';

class HarmonicBars extends StatelessWidget {
  const HarmonicBars({
    super.key,
    required this.amplitudes,
    required this.enabled,
    required this.onToggle,
  });

  final List<double> amplitudes;
  final List<bool> enabled;
  final void Function(int index) onToggle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: LayoutBuilder(
        builder: (context, c) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(amplitudes.length, (i) {
              final active = i < enabled.length && enabled[i];
              return Expanded(
                child: InkWell(
                  onTap: () => onToggle(i),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: double.infinity,
                              height: (c.maxHeight - 38) * amplitudes[i].clamp(0.03, 1.0),
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xFF58D5E8)
                                    : Colors.white.withValues(alpha: 0.11),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text('H${i + 1}', style: TextStyle(fontSize: i < 9 ? 10 : 8)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
