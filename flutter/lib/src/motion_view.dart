import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'motion.dart';

/// Builder do [SsInView]: [t] vai de 0 a 1 (com a curva; a mola passa de 1)
/// quando o filho entra na tela.
typedef SsInViewBuilder = Widget Function(BuildContext context, Animation<double> t, Widget? child);

/// Dispara **uma vez** quando o filho fica ao menos [threshold] (25%) visível
/// no Scrollable em volta. Gráfico e número animam quando a pessoa chega
/// neles, não ao montar (que acontece antes, fora da tela, e ninguém vê).
///
/// Sem Scrollable em volta, conta como visível já no primeiro quadro. Com
/// menos movimento, chega direto no fim.
///
/// - `SsInView(builder: (context, t, child) => ...)`: animação de 0 a 1 em
///   [duration] com [curve], depois de [delay].
/// - `SsInView.visible(builder: (context, visible) => ...)`: só o sinal; o
///   filho anima do jeito dele (ex.: `Tween(end: visible ? valor : 0)`).
///
/// Para repetir a entrada, troque a `key`.
class SsInView extends StatefulWidget {
  const SsInView({
    super.key,
    required SsInViewBuilder this.builder,
    this.child,
    this.duration = SsMotion.slow,
    this.curve = Curves.easeOutCubic,
    this.delay = Duration.zero,
    this.threshold = .25,
    this.onVisible,
  }) : visibleBuilder = null;

  const SsInView.visible({
    super.key,
    required Widget Function(BuildContext context, bool visible) builder,
    this.delay = Duration.zero,
    this.threshold = .25,
    this.onVisible,
  }) : visibleBuilder = builder,
       builder = null,
       child = null,
       duration = Duration.zero,
       curve = Curves.linear;

  final SsInViewBuilder? builder;
  final Widget Function(BuildContext context, bool visible)? visibleBuilder;

  /// Parte que não depende da animação (repassada ao [builder]).
  final Widget? child;
  final Duration duration;
  final Curve curve;

  /// Espera depois de entrar na tela (cascata: `index * SsMotion.stagger`).
  final Duration delay;

  /// Fração do filho (ou da tela, se ele for maior que ela) que precisa aparecer.
  final double threshold;

  /// Chamado uma vez, ao entrar na tela.
  final VoidCallback? onVisible;

  @override
  State<SsInView> createState() => _SsInViewState();
}

class _SsInViewState extends State<SsInView> with SingleTickerProviderStateMixin {
  // Criado só quando precisa (o modo `.visible` sem atraso não usa).
  AnimationController? _ctl;
  AnimationController get _c => _ctl ??= AnimationController(vsync: this);
  Animation<double> _t = kAlwaysDismissedAnimation;
  ScrollableState? _scrollable;
  ScrollPosition? _pos;

  /// Entrou na tela.
  bool _seen = false;

  /// Entrou e já passou o atraso (o que o modo `.visible` entrega).
  bool _visible = false;
  bool _agendado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = Scrollable.maybeOf(context);
    if (s != _scrollable) {
      _pos?.removeListener(_agenda);
      _scrollable = s;
      _pos = s?.position;
      if (!_seen) _pos?.addListener(_agenda);
    }
    // Sem rolagem em volta: visível já (anima a partir do primeiro quadro).
    if (!_seen && _scrollable == null) _dispara(rebuild: false);
  }

  @override
  void dispose() {
    _pos?.removeListener(_agenda);
    final t = _t;
    if (t is CurvedAnimation) t.dispose();
    _ctl?.dispose();
    super.dispose();
  }

  /// Confere depois do quadro (a geometria do quadro atual já está pronta).
  void _agenda() {
    if (_seen || _agendado) return;
    _agendado = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _agendado = false;
      _confere();
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  void _confere() {
    if (_seen || !mounted) return;
    final box = context.findRenderObject();
    final vp = _scrollable?.context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    if (vp is! RenderBox || !vp.attached || !vp.hasSize) return _dispara();
    final r = MatrixUtils.transformRect(box.getTransformTo(vp), Offset.zero & box.size);
    final tela = Offset.zero & vp.size;
    final vertical = axisDirectionToAxis(_scrollable!.axisDirection) == Axis.vertical;
    final ext = vertical ? r.height : r.width;
    final extTela = vertical ? tela.height : tela.width;
    final i = r.intersect(tela);
    if (i.width < 0 || i.height < 0) return;
    if (ext <= 0) return _dispara();
    final visto = (vertical ? i.height : i.width) / math.min(ext, extTela);
    if (visto >= widget.threshold) _dispara();
  }

  void _dispara({bool rebuild = true}) {
    if (_seen) return;
    _seen = true;
    _pos?.removeListener(_agenda);
    widget.onVisible?.call();
    void marca(VoidCallback f) => rebuild ? setState(f) : f();
    final atraso = widget.delay.inMicroseconds;
    if (reduceMotion(context)) {
      marca(() {
        _visible = true;
        _t = kAlwaysCompleteAnimation;
      });
      return;
    }
    if (widget.visibleBuilder != null) {
      if (atraso == 0) return marca(() => _visible = true);
      _c.duration = widget.delay;
      _c.addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) setState(() => _visible = true);
      });
      _c.forward();
      return;
    }
    final total = atraso + widget.duration.inMicroseconds;
    if (total == 0) return marca(() => _t = kAlwaysCompleteAnimation);
    _c.duration = Duration(microseconds: total);
    _t = CurvedAnimation(
      parent: _c,
      curve: atraso == 0 ? widget.curve : Interval(atraso / total, 1, curve: widget.curve),
    );
    _c.forward();
    if (rebuild) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_seen && _scrollable != null) _agenda();
    final vb = widget.visibleBuilder;
    if (vb != null) return vb(context, _visible);
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) => widget.builder!(context, _t, child),
      child: widget.child,
    );
  }
}

/// Valor que anda de [begin] até [end] quando entra na tela (um
/// `TweenAnimationBuilder` disparado pelo [SsInView]). Depois disso, mudar
/// [end] anima do valor atual até o novo, como o `TweenAnimationBuilder`.
class SsTweenInView extends StatelessWidget {
  const SsTweenInView({
    super.key,
    required this.end,
    required this.builder,
    this.begin = 0,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
    this.delay = Duration.zero,
    this.child,
  });

  final double begin;
  final double end;
  final ValueWidgetBuilder<double> builder;
  final Duration duration;
  final Curve curve;
  final Duration delay;
  final Widget? child;

  @override
  Widget build(BuildContext context) => SsInView.visible(
    delay: delay,
    builder: (context, visible) => TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: visible ? end : begin),
      duration: reduceMotion(context) ? Duration.zero : duration,
      curve: curve,
      builder: builder,
      child: child,
    ),
  );
}

/// Como o [SsReveal], mas quando entra na tela: aparece e sobe [offset] com
/// a mola ([SsMotion.bounce], passa um pouco do ponto e assenta), com atraso
/// de `index * SsMotion.stagger` (só os 8 primeiros esperam).
class SsInViewReveal extends StatelessWidget {
  const SsInViewReveal({super.key, required this.child, this.index = 0, this.offset = 16});

  final Widget child;
  final int index;
  final double offset;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return child;
    return SsInView(
      delay: SsMotion.stagger * math.min(index, 8),
      duration: SsMotion.indicator,
      curve: SsMotion.bounce,
      builder: (_, t, child) => Opacity(
        // A opacidade chega antes (a mola passa de 1 só na posição).
        opacity: (t.value * 1.6).clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, (1 - t.value) * offset), child: child),
      ),
      child: child,
    );
  }
}

/// Troca de conteúdo rolando na vertical: o novo entra por baixo e o antigo
/// sai por cima quando [up] (valor aumentou), ao contrário quando cai. A
/// troca acontece quando [value] muda. Sem [up], compara [value] com o
/// anterior se os dois forem números (subiu = rola para cima).
class SsRollSwitcher extends StatefulWidget {
  const SsRollSwitcher({
    super.key,
    required this.value,
    required this.child,
    this.up,
    this.duration = SsMotion.slow,
    this.alignment = Alignment.centerLeft,
  });

  final Object value;
  final Widget child;
  final bool? up;
  final Duration duration;
  final AlignmentGeometry alignment;

  @override
  State<SsRollSwitcher> createState() => _SsRollSwitcherState();
}

class _SsRollSwitcherState extends State<SsRollSwitcher> {
  bool _up = true;

  @override
  void didUpdateWidget(SsRollSwitcher old) {
    super.didUpdateWidget(old);
    if (old.value == widget.value) return;
    final (a, b) = (old.value, widget.value);
    _up = widget.up ?? (a is num && b is num ? b >= a : true);
  }

  @override
  Widget build(BuildContext context) {
    final key = ValueKey(widget.value);
    final dir = _up ? 1.0 : -1.0;
    return ClipRect(
      child: AnimatedSwitcher(
        duration: reduceMotion(context) ? Duration.zero : widget.duration,
        switchInCurve: SsMotion.bounce,
        switchOutCurve: Curves.easeIn,
        layoutBuilder: (atual, antigos) => Stack(alignment: widget.alignment, children: [...antigos, ?atual]),
        transitionBuilder: (child, a) {
          final entra = child.key == key;
          return AnimatedBuilder(
            animation: a,
            child: child,
            builder: (_, child) {
              final t = a.value;
              // Entra de baixo (subindo) e passa um tiquinho; sai para cima.
              final dy = (entra ? 1 - t : -(1 - t)) * dir * .9;
              return FractionalTranslation(
                translation: Offset(0, dy),
                child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
              );
            },
          );
        },
        child: KeyedSubtree(key: key, child: widget.child),
      ),
    );
  }
}

/// Texto que rola ([SsRollSwitcher]) ao mudar: rótulo de status, contador.
class SsRollingText extends StatelessWidget {
  const SsRollingText(this.text, {super.key, this.style, this.up, this.textAlign});

  final String text;
  final TextStyle? style;
  final bool? up;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => SsRollSwitcher(
    value: text,
    up: up,
    child: Text(text, style: style, textAlign: textAlign, maxLines: 1, softWrap: false),
  );
}

/// Movimento das camadas por cima (folha, diálogo, menu), para passar a
/// `showModalBottomSheet(sheetAnimationStyle:)`, `showDialog(animationStyle:)`
/// e afins quando o app monta a rota direto: `SsOverlayMotion.sheet(context)`.
/// Com menos movimento, devolve `AnimationStyle.noAnimation`.
class SsOverlayMotion {
  const SsOverlayMotion._();

  /// Mola mais firme que a [SsMotion.bounce] (passa ~3%): a folha é grande e
  /// passar mais mostraria o fundo embaixo dela.
  static const sheetCurve = SsSpringCurve(damping: .75);

  /// Folha que sobe, passa um pouco e assenta; desce reta e rápida.
  static AnimationStyle sheet(BuildContext context) => reduceMotion(context)
      ? AnimationStyle.noAnimation
      : AnimationStyle(
          curve: sheetCurve,
          duration: SsMotion.indicator,
          reverseCurve: Curves.easeInCubic,
          reverseDuration: const Duration(milliseconds: 220),
        );

  /// Diálogo: o fundo e o cartão aparecem na primeira metade; a escala do
  /// cartão (com mola) é do [SsRouteScale] dentro dele.
  static AnimationStyle dialog(BuildContext context) => reduceMotion(context)
      ? AnimationStyle.noAnimation
      : AnimationStyle(
          curve: const Interval(0, .45, curve: Curves.easeOut),
          duration: const Duration(milliseconds: 380),
          reverseCurve: Curves.easeIn,
          reverseDuration: const Duration(milliseconds: 160),
        );
}

/// Escala o filho com a animação da rota em que ele está: abre de [from] com
/// mola ([SsMotion.bounce]) e fecha reto. Para o cartão de um diálogo ou de
/// um menu (a partir de [alignment], a âncora). Fora de rota, ou com menos
/// movimento, não faz nada.
class SsRouteScale extends StatelessWidget {
  const SsRouteScale({super.key, required this.child, this.from = .9, this.alignment = Alignment.center});

  final Widget child;
  final double from;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final a = ModalRoute.of(context)?.animation;
    if (a == null || reduceMotion(context)) return child;
    return AnimatedBuilder(
      animation: a,
      child: child,
      builder: (_, child) {
        final volta = a.status == AnimationStatus.reverse;
        final t = volta ? Curves.easeIn.transform(a.value) : SsMotion.bounce.transform(a.value);
        return Transform.scale(scale: from + (1 - from) * t, alignment: alignment, child: child);
      },
    );
  }
}

/// Item de menu que entra em cascata com a rota do menu: aparece e desce
/// alguns px até o lugar com mola, [index] × 30 ms depois do anterior.
class SsRouteStagger extends StatelessWidget {
  const SsRouteStagger({super.key, required this.child, this.index = 0, this.offset = -6});

  final Widget child;
  final int index;

  /// Deslocamento inicial (negativo: vem de cima, do lado da âncora).
  final double offset;

  @override
  Widget build(BuildContext context) {
    final a = ModalRoute.of(context)?.animation;
    if (a == null || reduceMotion(context)) return child;
    return AnimatedBuilder(
      animation: a,
      child: child,
      builder: (_, child) {
        if (a.status == AnimationStatus.reverse) return child!;
        final ini = math.min(index, 8) * .08;
        final local = ((a.value - ini) / (1 - ini)).clamp(0.0, 1.0);
        final t = SsMotion.bounce.transform(local);
        return Opacity(
          opacity: (local * 2).clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, offset * (1 - t)), child: child),
        );
      },
    );
  }
}
