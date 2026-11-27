// v1.14.0 "interface e animação": o gesto de arrastar o dedo (ou passar o mouse) por um gráfico, igual nos quatro
// gráficos do pacote (SsLineChart, SsAreaChart, SsBarChart e SsTimeChart). Par do `ss-scrub` do web.
import 'package:material_ui/material_ui.dart';

/// Arrasto que segue o dedo ou o mouse por cima de um gráfico: chama [onScrub] com a posição (no espaço do
/// filho) ao arrastar na horizontal, ao tocar e ao passar o mouse, e [onEnd] quando o dedo solta, o mouse sai ou
/// a pessoa toca fora. Com [enabled] falso, só desenha o filho (o gráfico fica parado, sem balão).
///
/// O gráfico decide o ponto (`SsScrubDetector.indexAt`), vibra a cada ponto novo (`SsHaptics.selection`) e
/// avisa a tela pelo `onScrub(i)` dele, para o resto acompanhar (o total do mês, a linha da lista).
///
/// `SsScrubDetector(onScrub: (p) => _escolhe(p.dx), onEnd: _solta, child: CustomPaint(...))`.
class SsScrubDetector extends StatelessWidget {
  const SsScrubDetector({
    super.key,
    required this.child,
    required this.onScrub,
    this.onEnd,
    this.enabled = true,
    this.keepOnTap = true,
    this.onDoubleTap,
  });

  final Widget child;
  final ValueChanged<Offset> onScrub;
  final VoidCallback? onEnd;
  final bool enabled;

  /// O toque deixa o balão aberto até tocar fora (padrão); falso: some ao soltar.
  final bool keepOnTap;

  /// Toque duplo (o "aproximar" do [SsTimeChart]).
  final ValueChanged<Offset>? onDoubleTap;

  /// O índice do ponto mais perto de [dx] numa largura [width] com [count] pontos. Com [slots] (barras), cada
  /// ponto é uma vaga de mesma largura; sem, os pontos vão de [side] a `width - side` (linha e área).
  static int indexAt(double dx, double width, int count, {double side = 0, bool slots = false}) {
    if (count <= 1) return 0;
    final util = width - side * 2;
    if (util <= 0) return 0;
    final i = slots ? ((dx - side) / (util / count)).floor() : ((dx - side) / util * (count - 1)).round();
    return i.clamp(0, count - 1);
  }

  void _end([Object? _]) => onEnd?.call();

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    Widget w = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (d) => onScrub(d.localPosition),
      onHorizontalDragUpdate: (d) => onScrub(d.localPosition),
      onHorizontalDragEnd: _end,
      onHorizontalDragCancel: _end,
      onTapDown: (d) => onScrub(d.localPosition),
      onTapUp: keepOnTap ? null : _end,
      onLongPressStart: (d) => onScrub(d.localPosition),
      onLongPressMoveUpdate: (d) => onScrub(d.localPosition),
      onLongPressEnd: _end,
      onDoubleTapDown: onDoubleTap == null ? null : (d) => onDoubleTap!(d.localPosition),
      onDoubleTap: onDoubleTap == null ? null : () {},
      child: child,
    );
    // O mouse: o balão segue o cursor e some quando ele sai.
    w = MouseRegion(onHover: (e) => onScrub(e.localPosition), onExit: _end, child: w);
    return keepOnTap ? TapRegion(onTapOutside: _end, child: w) : w;
  }
}
