import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_theme.dart';
import '../format.dart';
import '../motion.dart';
import '../ss_strings.dart';
import 'ctl_comum.dart';

/// Trilha do [SsSlider].
enum SsSliderTrack {
  /// Parte cheia na cor (marca ou [SsSlider.color]) e o resto apagado.
  solid,

  /// Do escuro à cor: brilho de lâmpada.
  brightness,

  /// Temperatura de cor em kelvin (âmbar quente → branco frio). Use min/max em K.
  kelvin,

  /// Arco-íris do matiz (0–360°).
  hue,
}

/// Slider horizontal da casa. Trilha cheia na cor da marca ou em gradiente
/// ([track]: brilho, kelvin, matiz), bolha com o valor enquanto arrasta,
/// passo ([step]), [format] do texto e apagado sem [onChanged].
///
/// [fill] é a variante de tile: uma barra grossa em que a parte cheia é o
/// valor (como o brilho de uma lâmpada), com [label], [icon] e o valor
/// escritos dentro.
class SsSlider extends StatefulWidget {
  const SsSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.label,
    this.format,
    this.track = SsSliderTrack.solid,
    this.gradient,
    this.color,
    this.fill = false,
    this.icon,
    this.showBubble = true,
    this.showValue = false,
  });

  final double value;

  /// A cada passo durante o arrasto. Nulo = apagado.
  final ValueChanged<double>? onChanged;

  /// Ao soltar (ou a cada passo do teclado): a hora de mandar o comando.
  final ValueChanged<double>? onChangeEnd;
  final double min, max;

  /// Passo (0 = contínuo).
  final double step;

  /// Nome para o leitor de tela e, na variante [fill], escrito na barra.
  final String? label;

  /// Texto do valor ("80%", "2700 K"). Padrão: [qty].
  final String Function(double value)? format;
  final SsSliderTrack track;

  /// Gradiente próprio (vence o [track]).
  final List<Color>? gradient;

  /// Cor da parte cheia e do brilho (padrão: a marca).
  final Color? color;
  final bool fill;
  final IconData? icon;

  /// Bolha com o valor em cima do seletor enquanto arrasta.
  final bool showBubble;

  /// Rótulo e valor numa linha acima da trilha (fora da variante [fill]).
  final bool showValue;

  /// Cor aproximada de uma temperatura de cor (1000–40000 K), para a trilha
  /// em kelvin e o seletor (aproximação de Tanner Helland).
  static Color kelvinColor(double k) {
    final t = k.clamp(1000, 40000) / 100;
    double r, g, b;
    if (t <= 66) {
      r = 255;
      g = 99.4708025861 * math.log(t) - 161.1195681661;
      b = t <= 19 ? 0 : 138.5177312231 * math.log(t - 10) - 305.0447927307;
    } else {
      r = 329.698727446 * math.pow(t - 60, -0.1332047592);
      g = 288.1221695283 * math.pow(t - 60, -0.0755148492);
      b = 255;
    }
    int f(double v) => v.clamp(0, 255).round();
    return Color.fromARGB(255, f(r), f(g), f(b));
  }

  /// Cores da trilha em gradiente (nulo para [SsSliderTrack.solid]).
  static List<Color>? trackColors(
    SsSliderTrack track, {
    required Color tone,
    required Color dim,
    double min = 0,
    double max = 100,
  }) => switch (track) {
    SsSliderTrack.solid => null,
    SsSliderTrack.brightness => [Color.lerp(dim, tone, .12)!, tone],
    SsSliderTrack.kelvin => [for (var i = 0; i <= 6; i++) kelvinColor(min + (max - min) * i / 6)],
    SsSliderTrack.hue => [for (var h = 0; h <= 360; h += 60) HSVColor.fromAHSV(1, h % 360 * 1.0, 1, 1).toColor()],
  };

  @override
  State<SsSlider> createState() => _SsSliderState();
}

class _SsSliderState extends State<SsSlider> {
  bool _drag = false;
  bool _focus = false;

  String _fmt(double v) => widget.format?.call(v) ?? qty(v, SsFormats.of(context));
  bool get _enabled => widget.onChanged != null;
  double get _span => widget.max - widget.min;
  double get _f => _span == 0 ? 0 : ((widget.value - widget.min) / _span).clamp(0.0, 1.0);

  double _snap(double v) => ctlSnap(v, widget.min, widget.max, widget.step);

  // Último valor pedido (o pai pode ainda não ter reconstruído quando o arrasto acaba).
  double? _ultimo;

  void _set(double v, {bool end = false}) {
    final n = _snap(v);
    _ultimo = n;
    if (n != widget.value && widget.onChanged != null) {
      SsHaptics.tick();
      widget.onChanged!(n);
    }
    if (end) widget.onChangeEnd?.call(n);
  }

  double _stepKey() => widget.step > 0 ? widget.step : _span / 100;

  // Valor do ponto x (o seletor tem [pad] de margem nas pontas).
  double _valueAt(double x, double width, double pad) {
    final f = ((x - pad) / math.max(1, width - 2 * pad)).clamp(0.0, 1.0);
    return widget.min + f * _span;
  }

  // Cor do ponto f do gradiente (para o seletor e a bolha).
  Color _sample(List<Color> cores, double f) {
    if (cores.length == 1) return cores.first;
    final x = f * (cores.length - 1);
    final i = x.floor().clamp(0, cores.length - 2);
    return Color.lerp(cores[i], cores[i + 1], x - i)!;
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final tone = widget.color ?? c.accent;
    final cores =
        widget.gradient ??
        SsSlider.trackColors(
          widget.track,
          tone: tone,
          dim: c.isDark ? Colors.black : c.ink,
          min: widget.min,
          max: widget.max,
        );
    final reduce = reduceMotion(context);
    final dur = reduce ? Duration.zero : SsMotion.indicator;
    final pad = widget.fill ? 0.0 : 14.0;
    final h = widget.fill ? 56.0 : 48.0;

    Widget corpo = LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: _enabled
              ? (d) {
                  setState(() => _drag = true);
                  _set(_valueAt(d.localPosition.dx, w, pad));
                }
              : null,
          onHorizontalDragUpdate: _enabled ? (d) => _set(_valueAt(d.localPosition.dx, w, pad)) : null,
          onHorizontalDragEnd: _enabled
              ? (_) {
                  setState(() => _drag = false);
                  widget.onChangeEnd?.call(_ultimo ?? widget.value);
                }
              : null,
          onHorizontalDragCancel: _enabled ? () => setState(() => _drag = false) : null,
          onTapUp: _enabled ? (d) => _set(_valueAt(d.localPosition.dx, w, pad), end: true) : null,
          child: SizedBox(
            height: h,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: _f),
              // Arrastando, o seletor segue o dedo; no toque e no teclado, desliza.
              duration: _drag || reduce ? Duration.zero : SsMotion.fast,
              curve: Curves.easeOutCubic,
              builder: (context, f, _) {
                final cor = cores == null ? tone : _sample(cores, f);
                return widget.fill
                    ? _fill(context, c, f, w, cor, cores)
                    : _linha(context, c, f, w, pad, cor, cores, dur);
              },
            ),
          ),
        );
      },
    );

    if (widget.showValue && !widget.fill) {
      corpo = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Row(
              children: [
                if (widget.label != null)
                  Expanded(
                    child: Text(
                      widget.label!,
                      style: TextStyle(color: c.ink2, fontSize: AppType.meta, fontWeight: FontWeight.w700),
                    ),
                  )
                else
                  const Spacer(),
                Text(
                  _fmt(widget.value),
                  style: AppTheme.number(context, size: AppType.md, color: c.accentText),
                ),
              ],
            ),
          ),
          corpo,
        ],
      );
    }

    return Semantics(
      slider: true,
      label: widget.label,
      value: _fmt(widget.value),
      increasedValue: _fmt(_snap(widget.value + _stepKey())),
      decreasedValue: _fmt(_snap(widget.value - _stepKey())),
      onIncrease: _enabled ? () => _set(widget.value + _stepKey(), end: true) : null,
      onDecrease: _enabled ? () => _set(widget.value - _stepKey(), end: true) : null,
      child: Focus(
        canRequestFocus: _enabled,
        onFocusChange: (v) => setState(() => _focus = v),
        onKeyEvent: (_, e) {
          if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
          final k = e.logicalKey;
          if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.arrowUp) {
            _set(widget.value + _stepKey(), end: true);
          } else if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.arrowDown) {
            _set(widget.value - _stepKey(), end: true);
          } else if (k == LogicalKeyboardKey.home) {
            _set(widget.min, end: true);
          } else if (k == LogicalKeyboardKey.end) {
            _set(widget.max, end: true);
          } else {
            return KeyEventResult.ignored;
          }
          return KeyEventResult.handled;
        },
        child: AnimatedOpacity(
          opacity: _enabled ? 1 : .45,
          duration: reduce ? Duration.zero : SsMotion.fast,
          child: corpo,
        ),
      ),
    );
  }

  // Trilha fina + seletor redondo + bolha.
  Widget _linha(
    BuildContext context,
    SsColors c,
    double f,
    double w,
    double pad,
    Color cor,
    List<Color>? cores,
    Duration dur,
  ) {
    final x = pad + f * (w - 2 * pad);
    final apagado = Color.alphaBlend(c.muted.withValues(alpha: .22), c.field);
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerLeft,
      children: [
        Positioned(
          left: pad,
          right: pad,
          child: Container(
            height: cores == null ? 8 : 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              gradient: cores != null
                  ? LinearGradient(colors: cores)
                  : LinearGradient(colors: [cor, cor, apagado, apagado], stops: [0, f, f, 1]),
            ),
          ),
        ),
        Positioned(
          left: x - 12,
          child: AnimatedScale(
            scale: _drag ? 1.25 : 1,
            duration: dur,
            curve: SsMotion.bounce,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cores == null ? Colors.white : cor,
                border: Border.all(color: cores == null ? cor : Colors.white, width: 3),
                boxShadow: [
                  const BoxShadow(color: Color(0x40141628), blurRadius: 6, offset: Offset(0, 2)),
                  if (_drag || _focus) BoxShadow(color: cor.withValues(alpha: .25), spreadRadius: 6),
                ],
              ),
            ),
          ),
        ),
        if (widget.showBubble)
          Positioned(
            left: x - 32,
            bottom: 40,
            width: 64,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: AnimatedScale(
                  scale: _drag ? 1 : 0,
                  alignment: Alignment.bottomCenter,
                  duration: dur,
                  curve: SsMotion.bounce,
                  child: _Bolha(texto: _fmt(widget.value), cor: cores == null ? cor : c.ink),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Barra grossa: a parte cheia é o valor.
  Widget _fill(BuildContext context, SsColors c, double f, double w, Color cor, List<Color>? cores) {
    final cheio = f * w;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: c.field)),
          // Gradiente da trilha inteira recortado na parte cheia (igual ao CSS);
          // trilha lisa: a cor com um brilho na ponta de baixo.
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: cheio,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: w,
                maxWidth: w,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: cores ?? [Color.lerp(cor, Colors.white, .15)!, cor]),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          // Alça: tracinho branco na ponta da parte cheia.
          Positioned(
            left: (cheio - 10).clamp(4.0, math.max(4.0, w - 8)),
            top: 16,
            bottom: 16,
            child: AnimatedScale(
              scale: _drag ? 1.3 : 1,
              duration: reduceMotion(context) ? Duration.zero : SsMotion.indicator,
              curve: SsMotion.bounce,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: f > 0.02 ? Colors.white.withValues(alpha: .9) : c.muted2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // O texto vai duas vezes: em tinta por baixo e em branco recortado na
          // parte cheia (lê bem dos dois lados da ponta), como no CSS da gem.
          Positioned.fill(child: _textoFill(context, c.ink, c.ink2)),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: cheio,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: w,
                maxWidth: w,
                child: _textoFill(context, Colors.white, Colors.white),
              ),
            ),
          ),
          if (_focus)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.accent, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _textoFill(BuildContext context, Color fg, Color icone) {
    final dur = reduceMotion(context) ? Duration.zero : SsMotion.indicator;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: ExcludeSemantics(
        child: Row(
          children: [
            if (widget.icon != null) ...[Icon(widget.icon, size: 20, color: icone), const SizedBox(width: 8)],
            if (widget.label != null)
              Expanded(
                child: Text(
                  widget.label!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: AppType.set),
                ),
              )
            else
              const Spacer(),
            AnimatedScale(
              scale: _drag ? 1.12 : 1,
              duration: dur,
              curve: SsMotion.bounce,
              child: Text(
                _fmt(widget.value),
                style: AppTheme.number(context, size: AppType.md, color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bolha extends StatelessWidget {
  const _Bolha({required this.texto, required this.cor});
  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: cor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Color(0x33141628), blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Text(
          texto,
          maxLines: 1,
          style: AppTheme.number(
            context,
            size: AppType.sub,
            color: ThemeData.estimateBrightnessForColor(cor) == Brightness.dark ? Colors.white : AppColors.inkLight,
          ),
        ),
      ),
    );
  }
}
