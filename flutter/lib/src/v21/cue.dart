// v0.21: micro-animações padronizadas da casa (par do `ss-cue` do web).
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';

/// O que aconteceu, e por isso o desenho do aceno.
enum SsCueKind {
  /// Ligou (luz, tomada, cena): um pulo pequeno e um halo na cor que some.
  on,

  /// Abriu (porta, portão, janela, cortina): o filho gira um pouco pela
  /// borda esquerda, como uma porta, e volta.
  open,

  /// Alguém chegou (pessoa em casa, presença): sobe 8 px e aparece com a mola.
  arrive,
}

/// Micro-animação de mudança de estado (v0.21; mesmo nome e mesma regra do
/// `ss-cue` do web). Toca **uma vez** quando [active] passa de falso para
/// verdadeiro: nada na primeira pintura (abrir a tela não acena tudo), nada ao
/// desligar/fechar/sair. Some com "remover animações" do sistema
/// ([reduceMotion]). Não muda tamanho nem posição no layout (só pinta por cima
/// e transforma), então serve em tile, marcador de planta e avatar.
///
/// ```dart
/// SsCue(kind: SsCueKind.on, active: luz.ligada, color: corDaLampada, child: SsDeviceTile(...))
/// ```
class SsCue extends StatefulWidget {
  const SsCue({super.key, required this.kind, required this.active, required this.child, this.color, this.radius});

  final SsCueKind kind;

  /// Estado "aceso/aberto/presente". O aceno toca quando vira verdadeiro.
  final bool active;
  final Widget child;

  /// Cor do halo do [SsCueKind.on] (a cor real da lâmpada). Padrão: a marca.
  final Color? color;

  /// Raio do halo. Padrão: o do card da densidade.
  final double? radius;

  /// Duração de cada aceno (a mesma do `--ss-cue-dur` do web).
  static const duration = Duration(milliseconds: 620);

  @override
  State<SsCue> createState() => _SsCueState();
}

class _SsCueState extends State<SsCue> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: SsCue.duration, value: 1);

  @override
  void didUpdateWidget(covariant SsCue old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active && !reduceMotion(context)) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final tone = widget.color ?? c.accent;
    final radius = widget.radius ?? SsDensity.of(context).radiusCard;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _c.value;
        if (t >= 1) return child!;
        switch (widget.kind) {
          case SsCueKind.on:
            // Pulo: .94 → 1 pela mola; halo cresce e some.
            final s = .94 + .06 * SsMotion.bounce.transform(t);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius),
                        boxShadow: [
                          BoxShadow(
                            color: tone.withValues(alpha: .55 * (1 - t)),
                            blurRadius: 8 + 22 * t,
                            spreadRadius: 6 * t,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Transform.scale(scale: s, child: child),
              ],
            );
          case SsCueKind.open:
            // Porta: gira até ~28° pela borda esquerda e volta (meio seno).
            final a = -.5 * math.sin(math.pi * t);
            return Transform(
              alignment: Alignment.centerLeft,
              transform: Matrix4.identity()
                ..setEntry(3, 2, .0018)
                ..rotateY(a),
              child: child,
            );
          case SsCueKind.arrive:
            final k = SsMotion.bounce.transform(t);
            return Opacity(
              opacity: (.3 + .7 * t).clamp(0, 1),
              child: Transform.translate(
                offset: Offset(0, 8 * (1 - k)),
                child: Transform.scale(scale: .9 + .1 * k, child: child),
              ),
            );
        }
      },
    );
  }
}
