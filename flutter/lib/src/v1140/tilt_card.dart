// v1.14.0 "interface e animação": o cartão de destaque que inclina sob o dedo ou o mouse. Par do
// Ss::TiltCardComponent (o `ss-tilt` do web).
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';
import '../motion.dart';
import '../v09/a_fundacao.dart';

/// Cartão de destaque que inclina de leve para o lado do dedo (ou do mouse), até [maxTilt] graus, com um
/// reflexo de vidro que corre junto (o brilho do [SsGlass]); soltou ou o mouse saiu, volta com a mola
/// ([SsMotion.bounce]). Para o cartão de crédito, o plano escolhido, a conquista: **nunca** em tela de dados
/// densos (lista, tabela, painel de números), onde [enabled] fica falso. Com "reduzir movimento", não inclina.
///
/// [glass] põe o [child] sobre o vidro ([SsGlass], só sobre foto, aurora ou gradiente); sem ele, o cartão é o
/// [child] (o `SsWalletCard`, um `SsHeroCard`) e só o reflexo é desenhado por cima, recortado pelo [radius].
///
/// `SsTiltCard(child: SsWalletCard(...))`.
class SsTiltCard extends StatefulWidget {
  const SsTiltCard({
    super.key,
    required this.child,
    this.enabled = true,
    this.glass = false,
    this.maxTilt = 6,
    this.radius = AppRadius.card,
    this.shine = true,
  });

  final Widget child;
  final bool enabled;
  final bool glass;

  /// Inclinação máxima, em graus.
  final double maxTilt;
  final double radius;

  /// O reflexo de vidro que segue o dedo.
  final bool shine;

  @override
  State<SsTiltCard> createState() => _SsTiltCardState();
}

class _SsTiltCardState extends State<SsTiltCard> with SingleTickerProviderStateMixin {
  // Onde está o dedo, de -1 a 1 em cada eixo (0,0 = parado).
  Offset _alvo = Offset.zero;
  Offset _de = Offset.zero;
  late final _volta = AnimationController(vsync: this, duration: SsMotion.indicator, value: 1)
    ..addListener(() => setState(() {}));

  Offset get _pose => Offset.lerp(_de, _alvo, SsMotion.bounce.transform(_volta.value))!;

  @override
  void dispose() {
    _volta.dispose();
    super.dispose();
  }

  void _move(Offset local, Size size) {
    if (size.isEmpty) return;
    _volta.value = 1;
    setState(() {
      _alvo = Offset(
        (local.dx / size.width * 2 - 1).clamp(-1.0, 1.0),
        (local.dy / size.height * 2 - 1).clamp(-1.0, 1.0),
      );
      _de = _alvo;
    });
  }

  void _solta([Object? _]) {
    _de = _pose;
    _alvo = Offset.zero;
    _volta.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final corpo = widget.glass ? SsGlass(radius: widget.radius, child: widget.child) : widget.child;
    if (!widget.enabled || reduceMotion(context)) return corpo;
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth.isFinite ? box.maxWidth : 0, box.maxHeight.isFinite ? box.maxHeight : 0);
        final p = _pose;
        final graus = widget.maxTilt * math.pi / 180;
        final m = Matrix4.identity()
          ..setEntry(3, 2, .0012)
          ..rotateX(-p.dy * graus)
          ..rotateY(p.dx * graus);
        final brilho = p.distance.clamp(0.0, 1.0);
        Widget w = Transform(
          alignment: Alignment.center,
          transform: m,
          child: Stack(
            children: [
              corpo,
              if (widget.shine && brilho > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(widget.radius),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(p.dx, p.dy),
                            radius: 1.1,
                            colors: [
                              AppColors.onDark.withValues(alpha: .22 * brilho),
                              AppColors.onDark.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
        w = Listener(
          onPointerDown: (e) => _move(e.localPosition, context.size ?? size),
          onPointerMove: (e) => _move(e.localPosition, context.size ?? size),
          onPointerUp: _solta,
          onPointerCancel: _solta,
          child: w,
        );
        return MouseRegion(onHover: (e) => _move(e.localPosition, context.size ?? size), onExit: _solta, child: w);
      },
    );
  }
}
