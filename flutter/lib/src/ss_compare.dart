import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';

/// Comparador antes/depois (foto da planta, do treino): [before] à esquerda
/// da alça, [after] à direita; arraste ou toque para mover. Ocupa o espaço
/// que recebe: ponha num `AspectRatio` ou `SizedBox`.
class SsCompare extends StatefulWidget {
  const SsCompare({
    super.key,
    required this.before,
    required this.after,
    this.beforeLabel = 'Antes',
    this.afterLabel = 'Depois',
    this.initial = .5,
  });

  final Widget before;
  final Widget after;
  final String beforeLabel;
  final String afterLabel;
  final double initial;

  @override
  State<SsCompare> createState() => _SsCompareState();
}

class _SsCompareState extends State<SsCompare> {
  late double _t = widget.initial.clamp(0.0, 1.0);

  void _set(double t) => setState(() => _t = t.clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    String pct(double t) => '${(t.clamp(0.0, 1.0) * 100).round()}%';
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final x = _t * w;
        return Semantics(
          slider: true,
          label: 'Comparar ${widget.beforeLabel} e ${widget.afterLabel}',
          value: pct(_t),
          increasedValue: pct(_t + .1),
          decreasedValue: pct(_t - .1),
          onIncrease: () => _set(_t + .1),
          onDecrease: () => _set(_t - .1),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (d) {
              HapticFeedback.selectionClick();
              _set(d.localPosition.dx / w);
            },
            onHorizontalDragUpdate: (d) => _set(d.localPosition.dx / w),
            onTapUp: (d) => _set(d.localPosition.dx / w),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ExcludeSemantics(child: widget.after),
                  ClipRect(
                    clipper: _Esquerda(_t),
                    child: ExcludeSemantics(child: widget.before),
                  ),
                  Positioned(
                    left: x - 1,
                    top: 0,
                    bottom: 0,
                    width: 2,
                    child: const ColoredBox(color: Colors.white),
                  ),
                  Positioned(
                    left: x - 22,
                    top: 0,
                    bottom: 0,
                    width: 44,
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Color(0x55000000), blurRadius: 12, offset: Offset(0, 3))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chevron_left_rounded, size: 20, color: c.brandDeep),
                            Icon(Icons.chevron_right_rounded, size: 20, color: c.brandDeep),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(left: 10, top: 10, child: _Rotulo(widget.beforeLabel)),
                  Positioned(right: 10, top: 10, child: _Rotulo(widget.afterLabel)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Esquerda extends CustomClipper<Rect> {
  _Esquerda(this.t);
  final double t;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * t, size.height);

  @override
  bool shouldReclip(_Esquerda old) => old.t != t;
}

/// Pílula escura sobre a foto: legível em qualquer imagem, nos dois temas.
class _Rotulo extends StatelessWidget {
  const _Rotulo(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: .5), borderRadius: BorderRadius.circular(99)),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: AppType.meta, fontWeight: FontWeight.w800),
      ),
    ),
  );
}
