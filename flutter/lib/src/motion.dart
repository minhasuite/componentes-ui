import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';

/// Movimento do design system: tudo aqui some quando o sistema pede menos
/// animação (Acessibilidade → remover animações).
bool reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Encolhe para 0,97 enquanto o dedo está em cima e, ao soltar, volta com a
/// mola ([SsMotion.bounce]): passa um tiquinho do tamanho e assenta. Com
/// [onTap], também trata o toque (com haptic leve); sem ele, só dá o efeito a
/// um filho que já é tocável (InkWell, botão). [enabled] falso desliga o efeito.
class SsPressable extends StatefulWidget {
  const SsPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.enabled = true,
    this.scale = .97,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Toque longo (v0.10.3), com vibração média. Dê também um caminho visível
  /// ou de leitor de tela para a mesma ação.
  final VoidCallback? onLongPress;

  /// Toque duplo (v0.10.3). Com ele, o toque simples espera o tempo do duplo
  /// antes de disparar: use só onde o atalho vale a espera.
  final VoidCallback? onDoubleTap;
  final bool enabled;
  final double scale;

  @override
  State<SsPressable> createState() => _SsPressableState();
}

class _SsPressableState extends State<SsPressable> with SingleTickerProviderStateMixin {
  // Criado já no initState: desabilitado o build não toca nele, e criar no
  // dispose quebra.
  late final AnimationController _c;
  bool _down = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, value: 1);
  }

  Offset _origem = Offset.zero;

  // Trecho atual: da escala [_s0] até [_s1] pela [_curve].
  double _s0 = 1, _s1 = 1;
  Curve _curve = Curves.easeOut;

  double get _scale => lerpDouble(_s0, _s1, _curve.transform(_c.value))!;

  void _set(bool v) {
    if (_down == v || !mounted) return;
    _down = v;
    final alvo = v ? widget.scale : 1.0;
    if (reduceMotion(context)) {
      _s0 = _s1 = 1;
      _c.value = 1;
      return;
    }
    // Afunda rápido (100 ms); solta devagar, com a mola passando do ponto.
    _s0 = _scale;
    _s1 = alvo;
    _curve = v ? Curves.easeOut : SsMotion.bounce;
    _c.duration = v ? const Duration(milliseconds: 100) : SsMotion.release;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    Widget child = AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.scale(scale: _scale, child: child),
      child: widget.child,
    );
    if (widget.onTap != null || widget.onLongPress != null || widget.onDoubleTap != null) {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap == null
            ? null
            : () {
                SsHaptics.light();
                widget.onTap!();
              },
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                _set(false);
                SsHaptics.threshold();
                widget.onLongPress!();
              },
        onDoubleTap: widget.onDoubleTap == null
            ? null
            : () {
                SsHaptics.light();
                widget.onDoubleTap!();
              },
        child: child,
      );
    }
    // Listener (ponteiro cru): não disputa o toque com o InkWell do filho.
    return Listener(
      onPointerDown: (e) {
        _origem = e.position;
        _set(true);
      },
      // Virou rolagem (o dedo andou): solta, para a lista não andar encolhida.
      onPointerMove: (e) {
        if (_down && (e.position - _origem).distance > kTouchSlop) _set(false);
      },
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: child,
    );
  }
}

/// Número que conta de onde estava até [value] (600 ms) e é desenhado por
/// [builder]: `SsCountUp(1234.5, builder: (v) => Text(money(v)))`.
class SsCountUp extends StatelessWidget {
  const SsCountUp(this.value, {super.key, required this.builder, this.duration = const Duration(milliseconds: 600)});

  final double value;
  final Widget Function(double value) builder;
  final Duration duration;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value),
    duration: reduceMotion(context) ? Duration.zero : duration,
    curve: Curves.easeOutCubic,
    builder: (_, v, _) => builder(v),
  );
}

/// A "mesma mola em todo lugar": curva e tempos do movimento da suíte.
/// `AnimatedFoo(duration: SsMotion.base, curve: SsMotion.spring)`.
class SsMotion {
  const SsMotion._();
  static const Curve spring = Curves.easeOutBack;
  static const fast = Duration(milliseconds: 180);
  static const base = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 400);

  /// Atraso entre itens de uma lista que entra em cascata.
  static const stagger = Duration(milliseconds: 40);

  /// Mola de verdade (passa ~12% do ponto e assenta), o ritmo do pulo do
  /// [SsNavBar]: indicador que desliza, folha que sobe, toque que volta.
  /// Mesma curva do `--ss-bounce` no CSS da gem.
  static const bounce = SsSpringCurve();

  /// Indicador deslizando (abas, segmented, faixa de datas).
  static const indicator = Duration(milliseconds: 460);

  /// Mola mais solta (passa ~25% do ponto): o "pulinho" de quem foi
  /// escolhido ou marcado ([SsPop], ✓ da caixa, chip).
  static const pop = SsSpringCurve(damping: .4, stiffness: 14);

  /// Volta do toque ao soltar ([SsPressable]).
  static const release = Duration(milliseconds: 420);

  /// Viagem "minhoca" (traço das abas, barra de passos, interruptor): a
  /// frente dispara, a de trás vem ~90 ms depois e no fim ele assenta.
  /// Mesmo tempo do `--ss-worm` no CSS da gem.
  static const worm = Duration(milliseconds: 520);
}

/// Mola subamortecida normalizada em 0..1 (termina exatamente em 1).
/// [damping] menor = mais balanço; o padrão passa ~12% do ponto.
class SsSpringCurve extends Curve {
  const SsSpringCurve({this.damping = .55, this.stiffness = 11.3});
  final double damping;
  final double stiffness;

  @override
  double transformInternal(double t) {
    final z = damping, w = stiffness;
    final wd = w * math.sqrt(1 - z * z);
    return 1 - math.exp(-z * w * t) * (math.cos(wd * t) + z * w / wd * math.sin(wd * t));
  }
}

/// Entrada do filho, uma vez: aparece e sobe 12 px, com atraso de
/// `index * SsMotion.stagger` (só os 8 primeiros esperam: lista longa não
/// fica "chegando" para sempre). Com menos movimento, aparece direto.
class SsReveal extends StatelessWidget {
  const SsReveal({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return child;
    final delay = math.min(index, 8) * SsMotion.stagger.inMilliseconds;
    final total = SsMotion.slow.inMilliseconds + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 12), child: child),
      ),
      child: child,
    );
  }
}

/// Revela o filho da esquerda para a direita (gráfico "se desenhando"), uma vez.
class SsDrawIn extends StatelessWidget {
  const SsDrawIn({super.key, required this.child, this.duration = const Duration(milliseconds: 900)});

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeInOutCubic,
      builder: (_, t, child) => ClipRect(clipper: _WidthClipper(t), child: child),
      child: child,
    );
  }
}

class _WidthClipper extends CustomClipper<Rect> {
  _WidthClipper(this.t);
  final double t;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * t, size.height);

  @override
  bool shouldReclip(_WidthClipper old) => old.t != t;
}

/// Confete por cima de tudo (~1,2 s) nas cores da marca e do sucesso, e some
/// sozinho. Para conquista de verdade (meta batida, primeiros passos feitos).
/// Com menos movimento não faz nada: a mensagem já comemora.
void showSsConfetti(BuildContext context) {
  if (reduceMotion(context)) return;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  final c = SsColors.of(context);
  final cores = [c.brandFrom, c.brandTo, c.accentBright, c.brandDeep, AppColors.success];
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Confetti(cores: cores, onDone: () => entry.remove()),
  );
  overlay.insert(entry);
}

class _Confetti extends StatefulWidget {
  const _Confetti({required this.cores, required this.onDone});
  final List<Color> cores;
  final VoidCallback onDone;

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
    ..forward().whenComplete(widget.onDone);
  final _rnd = math.Random();
  late final _pieces = List.generate(
    70,
    (i) => _Piece(
      x: .5 + (_rnd.nextDouble() - .5) * .3,
      vx: (_rnd.nextDouble() - .5) * 1.1,
      vy: -(.35 + _rnd.nextDouble() * .45),
      spin: (_rnd.nextDouble() - .5) * 12,
      size: 6 + _rnd.nextDouble() * 5,
      color: widget.cores[i % widget.cores.length],
    ),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, _) => CustomPaint(size: Size.infinite, painter: _ConfettiPainter(_pieces, _c.value)),
    ),
  );
}

class _Piece {
  const _Piece({
    required this.x,
    required this.vx,
    required this.vy,
    required this.spin,
    required this.size,
    required this.color,
  });
  final double x, vx, vy, spin, size;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);
  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in pieces) {
      // Estoura do meio para cima e cai com gravidade; some no último quarto.
      final y = .45 + p.vy * t + 1.1 * t * t;
      final x = p.x + p.vx * t * .5;
      paint.color = p.color.withValues(alpha: (1 - math.max(0.0, t - .75) * 4).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(p.spin * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * .55),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/// Vibração por contexto, para todo app usar a mesma: [tick] ao escolher,
/// [threshold] ao cruzar um limite (deslize), [success] ao concluir,
/// [error] ao falhar.
class SsHaptics {
  const SsHaptics._();
  static Future<void> tick() => HapticFeedback.selectionClick();

  /// Toque leve (v0.10.3): começar a gravar, abrir um menu, um passo pequeno.
  static Future<void> light() => HapticFeedback.lightImpact();
  static Future<void> threshold() => HapticFeedback.mediumImpact();

  /// Dois toques leves (o "deu certo").
  static Future<void> success() async {
    await HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    await HapticFeedback.lightImpact();
  }

  static Future<void> error() => HapticFeedback.heavyImpact();
}

/// Indicador que desliza com mola entre itens (pílula do segmented, traço das
/// abas, dia escolhido), no ritmo do pulo do [SsNavBar]: a ponta da frente sai
/// na hora e a de trás espera um pouco, então ele **estica** no sentido do
/// movimento (e afina no outro, como gota), passa um pouco do alvo e assenta
/// ([SsMotion.bounce] em [SsMotion.indicator]). Troca no meio continua de onde
/// ele está. Com menos movimento, pula direto.
///
/// Ocupa o espaço do pai: vai num `Stack`, em `Positioned.fill`, atrás (ou na
/// frente) dos itens. [count] divide o espaço em vagas iguais no [axis] (com
/// [padding] dentro de cada vaga); [rectOf] dá o retângulo de cada item quando
/// as vagas não são iguais. Desenha [child] no retângulo do instante, ou, com
/// [builder], a camada inteira a partir do retângulo e do quanto ele está
/// esticado (0 parado; perto de 1 no meio de um caminho longo).
class SsSlidingIndicator extends StatefulWidget {
  const SsSlidingIndicator({
    super.key,
    required this.index,
    this.count,
    this.rectOf,
    this.child,
    this.builder,
    this.frameBuilder,
    this.axis = Axis.horizontal,
    this.padding = EdgeInsets.zero,
    this.duration = SsMotion.indicator,
  }) : assert(count != null || rectOf != null),
       assert(child != null || builder != null || frameBuilder != null);

  final int index;
  final int? count;
  final Rect Function(int index, Size size)? rectOf;
  final Widget? child;
  final Widget Function(BuildContext context, Rect rect, double stretch)? builder;

  /// Como [builder], mas com o quadro inteiro ([SsIndicatorFrame]): de onde
  /// saiu, para onde vai e o instante da viagem, para quem desenha rastro ou
  /// o "amassado" da chegada.
  final Widget Function(BuildContext context, SsIndicatorFrame frame)? frameBuilder;
  final Axis axis;
  final EdgeInsets padding;
  final Duration duration;

  /// Pose do indicador no instante [t] (0..1) da viagem de [from] até [to]:
  /// o retângulo e o quanto está esticado. Exposto para quem desenha o
  /// próprio indicador com o mesmo movimento.
  static (Rect, double) pose(Rect from, Rect to, double t, {Axis axis = Axis.horizontal}) {
    if (t >= 1 || from == to) return (to, 0);
    final h = axis == Axis.horizontal;
    double ini(Rect r) => h ? r.left : r.top;
    double fim(Rect r) => h ? r.right : r.bottom;
    final frente = ini(to) + fim(to) >= ini(from) + fim(from);
    // A ponta da frente sai na hora; a de trás espera ~16% e vem com a mesma mola.
    final lead = SsMotion.bounce.transform((t / .8).clamp(0.0, 1.0));
    final trail = SsMotion.bounce.transform(((t - .16) / .84).clamp(0.0, 1.0));
    // Passa do alvo no máximo 22% do próprio tamanho (salto longo não exagera).
    final cap = (fim(to) - ini(to)).abs() * .22;
    double vai(double a, double b, double p) {
      if (p <= 1) return a + (b - a) * p;
      return b + (b - a).sign * math.min((p - 1) * (b - a).abs(), cap);
    }

    final a = vai(ini(from), ini(to), frente ? trail : lead);
    final b = math.max(vai(fim(from), fim(to), frente ? lead : trail), a + 1);
    // O eixo cruzado só acompanha, sem mola.
    final m = Curves.easeOutCubic.transform(t);
    final repouso = lerpDouble(fim(from) - ini(from), fim(to) - ini(to), m)!;
    final estica = repouso <= 0 ? 0.0 : ((b - a) / repouso - 1).clamp(0.0, 2.0);
    final cs = lerpDouble(h ? from.top : from.left, h ? to.top : to.left, m)!;
    final ce = lerpDouble(h ? from.bottom : from.right, h ? to.bottom : to.right, m)!;
    return (h ? Rect.fromLTRB(a, cs, b, ce) : Rect.fromLTRB(cs, a, ce, b), estica);
  }

  @override
  State<SsSlidingIndicator> createState() => _SsSlidingIndicatorState();
}

class _SsSlidingIndicatorState extends State<SsSlidingIndicator> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.duration, value: 1);
  Rect? _from;
  Rect? _last;

  @override
  void didUpdateWidget(SsSlidingIndicator old) {
    super.didUpdateWidget(old);
    _c.duration = widget.duration;
    if (old.index == widget.index) return;
    // Sai de onde está agora (troca no meio do caminho não teleporta).
    _from = _last;
    if (_from == null || reduceMotion(context)) {
      _c.value = 1;
    } else {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Rect _alvo(Size size) {
    if (widget.rectOf != null) return widget.rectOf!(widget.index, size);
    final n = widget.count!;
    final h = widget.axis == Axis.horizontal;
    final vaga = h
        ? Rect.fromLTWH(size.width / n * widget.index, 0, size.width / n, size.height)
        : Rect.fromLTWH(0, size.height / n * widget.index, size.width, size.height / n);
    return widget.padding.deflateRect(vaga);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final alvo = _alvo(box.biggest);
        final (r, estica) = _from == null
            ? (alvo, 0.0)
            : SsSlidingIndicator.pose(_from!, alvo, _c.value, axis: widget.axis);
        _last = r;
        if (widget.frameBuilder != null) {
          return widget.frameBuilder!(
            context,
            SsIndicatorFrame(rect: r, stretch: estica, t: _c.value, from: _from, to: alvo),
          );
        }
        if (widget.builder != null) return widget.builder!(context, r, estica);
        // Esticado, afina até 14% no eixo cruzado (gota).
        final afina = 1 - math.min(.14, estica * .25);
        final rr = widget.axis == Axis.horizontal
            ? Rect.fromCenter(center: r.center, width: r.width, height: r.height * afina)
            : Rect.fromCenter(center: r.center, width: r.width * afina, height: r.height);
        return Stack(
          clipBehavior: Clip.none,
          children: [Positioned.fromRect(rect: rr, child: widget.child!)],
        );
      },
    ),
  );
}

/// Quadro do [SsSlidingIndicator] num instante: o retângulo e o quanto está
/// esticado ([SsSlidingIndicator.pose]), o instante [t] (0..1) da viagem e as
/// pontas dela ([from] é nulo antes da 1ª troca).
class SsIndicatorFrame {
  const SsIndicatorFrame({
    required this.rect,
    required this.stretch,
    required this.t,
    required this.from,
    required this.to,
  });

  final Rect rect;
  final double stretch;
  final double t;
  final Rect? from;
  final Rect to;

  /// Está a caminho (há de onde vir e ainda não chegou).
  bool get moving => from != null && from != to && t < 1;

  /// Sentido da viagem no eixo horizontal: 1 para a direita, -1 para a esquerda.
  double get direction => from == null || to.center.dx >= from!.center.dx ? 1 : -1;
}

/// "Pulinho" de escala quando [active] liga (escolheu, marcou): encolhe para
/// [from] e volta com a mola solta ([SsMotion.pop]), passando um pouco do
/// tamanho. Ao montar não pula; desligar não pula. Com menos movimento, nada.
class SsPop extends StatefulWidget {
  const SsPop({super.key, required this.active, required this.child, this.from = .8});

  final bool active;
  final Widget child;
  final double from;

  @override
  State<SsPop> createState() => _SsPopState();
}

class _SsPopState extends State<SsPop> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: SsMotion.slow, value: 1);

  @override
  void didUpdateWidget(SsPop old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active && !reduceMotion(context)) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, child) => Transform.scale(
      scale: _c.value >= 1 ? 1 : lerpDouble(widget.from, 1, SsMotion.pop.transform(_c.value))!,
      child: child,
    ),
    child: widget.child,
  );
}

/// ✓ que se desenha (o traço curto e depois o longo) quando [value] liga e
/// some rápido quando desliga. Montado já marcado, aparece pronto. Decorativo:
/// quem marca diz o estado ao leitor de tela. Sem [color], a cor da marca.
class SsCheckMark extends StatefulWidget {
  const SsCheckMark({super.key, required this.value, this.size = 16, this.color, this.strokeWidth});

  final bool value;
  final double size;
  final Color? color;

  /// Padrão: 14% do [size].
  final double? strokeWidth;

  @override
  State<SsCheckMark> createState() => _SsCheckMarkState();
}

class _SsCheckMarkState extends State<SsCheckMark> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, value: widget.value ? 1 : 0);

  @override
  void didUpdateWidget(SsCheckMark old) {
    super.didUpdateWidget(old);
    if (old.value == widget.value) return;
    if (reduceMotion(context)) {
      _c.value = widget.value ? 1 : 0;
    } else if (widget.value) {
      _c.animateTo(1, duration: SsMotion.base, curve: Curves.easeOutCubic);
    } else {
      _c.animateBack(0, duration: const Duration(milliseconds: 120), curve: Curves.easeIn);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _CheckPainter(
            t: _c.value,
            color: widget.color ?? SsColors.of(context).accent,
            stroke: widget.strokeWidth ?? widget.size * .14,
          ),
        ),
      ),
    ),
  );
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.t, required this.color, required this.stroke});
  final double t;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final s = size.width;
    final path = Path()
      ..moveTo(s * .2, s * .54)
      ..lineTo(s * .42, s * .74)
      ..lineTo(s * .8, s * .3);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (t >= 1) return canvas.drawPath(path, paint);
    final metric = path.computeMetrics().first;
    canvas.drawPath(metric.extractPath(0, metric.length * t), paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.t != t || old.color != color || old.stroke != stroke;
}

/// Trecho [a]..[b] (em ms) de uma linha do tempo, normalizado em 0..1 e
/// passado pela [curve]. Antes de [a] dá 0; depois de [b], 1.
double _trecho(double ms, double a, double b, [Curve curve = Curves.linear]) =>
    curve.transform(((ms - a) / (b - a)).clamp(0.0, 1.0));

/// Base dos efeitos de uma vez só ([SsRipple], [SsBurst]): toca quando
/// [trigger] muda e [play] é verdadeiro, depois de [delay], e some sozinho.
/// Ao montar não toca. Com menos movimento, nunca toca.
abstract class _SsOneShot extends StatefulWidget {
  const _SsOneShot({
    super.key,
    required this.trigger,
    required this.child,
    required this.play,
    required this.delay,
    required this.duration,
    this.color,
  });

  final Object? trigger;
  final Widget child;
  final bool play;
  final Duration delay;
  final Duration duration;

  /// Padrão: a cor da marca ([SsColors.accent]).
  final Color? color;

  CustomPainter painter(double t, Color color);

  @override
  State<_SsOneShot> createState() => _SsOneShotState();
}

class _SsOneShotState extends State<_SsOneShot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.delay + widget.duration, value: 1);

  @override
  void didUpdateWidget(_SsOneShot old) {
    super.didUpdateWidget(old);
    if (old.trigger == widget.trigger || !widget.play || reduceMotion(context)) return;
    _c.duration = widget.delay + widget.duration;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Progresso do efeito (0..1, já sem o atraso); nulo quando não há o que pintar.
  double? get _t {
    if (_c.value >= 1) return null;
    final total = (widget.delay + widget.duration).inMicroseconds;
    final us = _c.value * total - widget.delay.inMicroseconds;
    if (us < 0) return null;
    return us / widget.duration.inMicroseconds;
  }

  @override
  Widget build(BuildContext context) {
    final cor = widget.color ?? SsColors.of(context).accent;
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, _) {
                final t = _t;
                return t == null ? const SizedBox.shrink() : CustomPaint(painter: widget.painter(t, cor));
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Anel que se expande uma vez em volta do [child] e some (o "eco" de quem
/// foi escolhido: passo novo, interruptor que bateu no fim, bolinha de
/// opção). Vai de [begin] até [scale] vezes o [radius] (padrão: metade do
/// lado menor do filho). Toca quando [trigger] muda com [play] ligado.
class SsRipple extends _SsOneShot {
  const SsRipple({
    super.key,
    required super.trigger,
    required super.child,
    super.play = true,
    super.delay = Duration.zero,
    super.duration = const Duration(milliseconds: 520),
    super.color,
    this.radius,
    this.begin = 0,
    this.scale = 1.8,
    this.strokeWidth = 2,
  });

  final double? radius;
  final double begin;
  final double scale;
  final double strokeWidth;

  @override
  CustomPainter painter(double t, Color color) =>
      _RipplePainter(t: t, color: color, radius: radius, begin: begin, scale: scale, stroke: strokeWidth);
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({
    required this.t,
    required this.color,
    required this.radius,
    required this.begin,
    required this.scale,
    required this.stroke,
  });
  final double t;
  final Color color;
  final double? radius;
  final double begin, scale, stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final e = Curves.easeOutCubic.transform(t);
    final r0 = radius ?? size.shortestSide / 2;
    canvas.drawCircle(
      size.center(Offset.zero),
      r0 * lerpDouble(begin, scale, e)!,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * (1 - .4 * e)
        ..color = color.withValues(alpha: color.a * .75 * (1 - t)),
    );
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.t != t || old.color != color;
}

/// Estouro de [count] risquinhos que saem do contorno do [child] (raio
/// [radius], padrão metade do lado menor), andam [distance] px para fora e
/// somem, uma vez (~450 ms). O "deu certo" da caixa marcada.
class SsBurst extends _SsOneShot {
  const SsBurst({
    super.key,
    required super.trigger,
    required super.child,
    super.play = true,
    super.delay = Duration.zero,
    super.duration = const Duration(milliseconds: 450),
    super.color,
    this.count = 7,
    this.distance = 14,
    this.radius,
  });

  final int count;
  final double distance;
  final double? radius;

  @override
  CustomPainter painter(double t, Color color) =>
      _BurstPainter(t: t, color: color, count: count, distance: distance, radius: radius);
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.t, required this.color, required this.count, required this.distance, this.radius});
  final double t;
  final Color color;
  final int count;
  final double distance;
  final double? radius;

  @override
  void paint(Canvas canvas, Size size) {
    final e = Curves.easeOutCubic.transform(t);
    final c = size.center(Offset.zero);
    final r0 = (radius ?? size.shortestSide / 2) + 2;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2
      ..color = color.withValues(alpha: color.a * (1 - Curves.easeIn.transform(t)));
    for (var i = 0; i < count; i++) {
      // Começa no alto e gira; os ímpares saem um pouco mais curtos.
      final a = -math.pi / 2 + 2 * math.pi * i / count;
      final dir = Offset(math.cos(a), math.sin(a));
      final ponta = r0 + distance * e;
      final rabo = ponta - (i.isEven ? 4.5 : 3) * (1 - t * .7);
      canvas.drawLine(c + dir * math.max(r0, rabo), c + dir * ponta, paint);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t || old.color != color;
}

/// Barra de progresso "minhoca": ao mudar [value] (0..1), a cabeça dispara
/// na frente com mola (passa um pouco) e o corpo alcança ~90 ms depois; entre
/// os dois fica um rastro claro. Uma faísca (ponto branco com brilho da
/// marca) vai na cabeça e se apaga no fim. Ao montar não anima. Com menos
/// movimento, pula direto.
class SsWormProgress extends StatefulWidget {
  const SsWormProgress({
    super.key,
    required this.value,
    this.height = 3,
    this.color,
    this.trackColor,
    this.spark = true,
  });

  final double value;
  final double height;

  /// Padrão: a cor da marca; trilho: [SsColors.field].
  final Color? color;
  final Color? trackColor;
  final bool spark;

  @override
  State<SsWormProgress> createState() => _SsWormProgressState();
}

class _SsWormProgressState extends State<SsWormProgress> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: SsMotion.worm, value: 1);
  late double _alvo = widget.value.clamp(0.0, 1.0);
  late double _cabeca0 = _alvo, _corpo0 = _alvo;

  // A cabeça sai na hora; o corpo espera ~17% (90 ms) e vem com a mesma mola.
  double get _cabeca => lerpDouble(_cabeca0, _alvo, SsMotion.bounce.transform((_c.value / .8).clamp(0.0, 1.0)))!;
  double get _corpo => lerpDouble(_corpo0, _alvo, SsMotion.bounce.transform(((_c.value - .17) / .83).clamp(0.0, 1.0)))!;

  @override
  void didUpdateWidget(SsWormProgress old) {
    super.didUpdateWidget(old);
    final novo = widget.value.clamp(0.0, 1.0);
    if (novo == _alvo) return;
    // Sai de onde está agora (trocar no meio não teleporta).
    final (cabeca, corpo) = (_cabeca, _corpo);
    _alvo = novo;
    if (reduceMotion(context)) {
      _cabeca0 = _corpo0 = novo;
      _c.value = 1;
      return;
    }
    _cabeca0 = cabeca;
    _corpo0 = corpo;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          painter: _WormPainter(
            cabeca: _cabeca,
            corpo: _corpo,
            t: _c.value,
            faisca: widget.spark && _cabeca0 != _alvo,
            cor: widget.color ?? c.accent,
            trilho: widget.trackColor ?? c.field,
          ),
        ),
      ),
    );
  }
}

class _WormPainter extends CustomPainter {
  _WormPainter({
    required this.cabeca,
    required this.corpo,
    required this.t,
    required this.faisca,
    required this.cor,
    required this.trilho,
  });
  final double cabeca, corpo, t;
  final bool faisca;
  final Color cor, trilho;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final raio = Radius.circular(h / 2);
    final pista = RRect.fromRectAndRadius(Offset.zero & size, raio);
    canvas.drawRRect(pista, Paint()..color = trilho);
    final lo = math.min(cabeca, corpo).clamp(0.0, 1.0), hi = math.max(cabeca, corpo).clamp(0.0, 1.0);
    canvas.save();
    canvas.clipRRect(pista);
    // Rastro claro entre o corpo e a cabeça; o cheio vai até o mais curto.
    if (hi > lo) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(0, 0, hi * w, h), raio),
        Paint()..color = cor.withValues(alpha: cor.a * .35),
      );
    }
    if (lo > 0) canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(0, 0, lo * w, h), raio), Paint()..color = cor);
    canvas.restore();
    // A faísca vai na cabeça e se apaga no último terço.
    if (!faisca || t <= 0 || t >= 1) return;
    final a = 1 - _trecho(t, .6, .92);
    if (a <= 0) return;
    final p = Offset(cabeca.clamp(0.0, 1.0) * w, h / 2);
    canvas.drawCircle(
      p,
      h + 2.5,
      Paint()
        ..color = cor.withValues(alpha: cor.a * .7 * a)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(p, h * .5 + 1, Paint()..color = Colors.white.withValues(alpha: .9 * a));
  }

  @override
  bool shouldRepaint(_WormPainter old) =>
      old.cabeca != cabeca || old.corpo != corpo || old.t != t || old.cor != cor || old.trilho != trilho;
}

/// Caixa de marcar animada (quadrada, ou redonda com [circle]). Marcando: a
/// caixa encolhe (0,85, antecipação), pula para 1,12 e assenta com mola; a
/// cor da marca inunda do centro como um círculo crescendo; o ✓ se desenha
/// logo depois; e um estouro de risquinhos ([SsBurst]) sai em volta.
/// Desmarcando: o ✓ se desfaz rápido, a cor encolhe para o centro e a caixa
/// balança (−6° → 4° → 0). Montada, aparece pronta. Decorativa: quem marca
/// diz o estado ao leitor de tela.
class SsCheckBox extends StatefulWidget {
  const SsCheckBox({
    super.key,
    required this.value,
    this.size = 24,
    this.circle = false,
    this.radius = 7,
    this.borderWidth = 1.5,
    this.color,
    this.checkColor = AppColors.onDark,
    this.emptyColor,
    this.borderColor,
    this.burst = true,
  });

  final bool value;
  final double size;
  final bool circle;

  /// Raio do canto (sem [circle]).
  final double radius;
  final double borderWidth;

  /// Cor cheia; padrão: a da marca.
  final Color? color;
  final Color checkColor;

  /// Fundo vazio (padrão [SsColors.field]) e borda vazia (padrão [SsColors.muted2]).
  final Color? emptyColor;
  final Color? borderColor;

  /// Estouro de risquinhos ao marcar.
  final bool burst;

  @override
  State<SsCheckBox> createState() => _SsCheckBoxState();
}

class _SsCheckBoxState extends State<SsCheckBox> with SingleTickerProviderStateMixin {
  // Duração total de cada linha do tempo (ms).
  static const _marcar = 560.0, _desmarcar = 360.0;

  late final _c = AnimationController(vsync: this, value: 1);
  late bool _marcando = widget.value;
  // De onde a troca saiu (trocar no meio continua de onde está).
  double _cheio0 = 0, _check0 = 0;

  double get _ms => _c.value * (_marcando ? _marcar : _desmarcar);

  double get _cheio => _marcando
      ? lerpDouble(_cheio0, 1, _trecho(_ms, 60, 280, Curves.easeOutCubic))!
      : lerpDouble(_cheio0, 0, _trecho(_ms, 60, 220, Curves.easeInCubic))!;

  double get _check => _marcando
      ? lerpDouble(_check0, 1, _trecho(_ms, 160, 400, Curves.easeOutCubic))!
      : lerpDouble(_check0, 0, _trecho(_ms, 0, 100, Curves.easeIn))!;

  /// Antecipação (1 → 0,85), pulo (→ 1,12) e mola até 1.
  double get _escala {
    if (!_marcando || _c.value >= 1) return 1;
    final ms = _ms;
    if (ms < 80) return lerpDouble(1, .85, _trecho(ms, 0, 80, Curves.easeOut))!;
    if (ms < 200) return lerpDouble(.85, 1.12, _trecho(ms, 80, 200, Curves.easeOut))!;
    return lerpDouble(1.12, 1, _trecho(ms, 200, 480, SsMotion.bounce))!;
  }

  /// Balanço ao desmarcar, em graus: 0 → −6 → 4 → 0.
  double get _giro {
    if (_marcando || _c.value >= 1) return 0;
    final ms = _ms;
    if (ms < 90) return lerpDouble(0, -6, _trecho(ms, 0, 90, Curves.easeOut))!;
    if (ms < 200) return lerpDouble(-6, 4, _trecho(ms, 90, 200, Curves.easeInOut))!;
    return lerpDouble(4, 0, _trecho(ms, 200, 360, Curves.easeOut))!;
  }

  @override
  void didUpdateWidget(SsCheckBox old) {
    super.didUpdateWidget(old);
    if (old.value == widget.value) return;
    _cheio0 = _cheio;
    _check0 = _check;
    _marcando = widget.value;
    if (reduceMotion(context)) {
      _c.value = 1;
      return;
    }
    _c.duration = Duration(milliseconds: (_marcando ? _marcar : _desmarcar).round());
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final cor = widget.color ?? c.accent;
    return ExcludeSemantics(
      child: SsBurst(
        trigger: widget.value,
        play: widget.value && widget.burst,
        delay: const Duration(milliseconds: 100),
        color: cor,
        child: SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final s = _escala;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationZ(_giro * math.pi / 180)..multiply(Matrix4.diagonal3Values(s, s, 1)),
                child: CustomPaint(
                  painter: _BoxPainter(
                    cheio: _cheio,
                    check: _check,
                    circle: widget.circle,
                    radius: widget.radius,
                    borda: widget.borderWidth,
                    vazio: widget.emptyColor ?? c.field,
                    bordaVazia: widget.borderColor ?? c.muted2,
                    cor: cor,
                    corCheck: widget.checkColor,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BoxPainter extends CustomPainter {
  _BoxPainter({
    required this.cheio,
    required this.check,
    required this.circle,
    required this.radius,
    required this.borda,
    required this.vazio,
    required this.bordaVazia,
    required this.cor,
    required this.corCheck,
  });
  final double cheio, check, radius, borda;
  final bool circle;
  final Color vazio, bordaVazia, cor, corCheck;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final rect = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(circle ? s / 2 : radius));
    canvas.drawRRect(rr, Paint()..color = vazio);
    // A cor inunda do centro (círculo crescendo, recortado na caixa).
    if (cheio > 0) {
      canvas.save();
      canvas.clipRRect(rr);
      canvas.drawCircle(rect.center, s * .75 * cheio, Paint()..color = cor);
      canvas.restore();
    }
    canvas.drawRRect(
      rr.deflate(borda / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = borda
        ..color = Color.lerp(bordaVazia, cor, (cheio * 1.6).clamp(0.0, 1.0))!,
    );
    if (check <= 0) return;
    final lado = s * .72;
    canvas.save();
    canvas.translate((size.width - lado) / 2, (size.height - lado) / 2);
    _CheckPainter(t: check, color: corCheck, stroke: s * .1).paint(canvas, Size.square(lado));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BoxPainter old) =>
      old.cheio != cheio ||
      old.check != check ||
      old.cor != cor ||
      old.vazio != vazio ||
      old.bordaVazia != bordaVazia ||
      old.corCheck != corCheck;
}
