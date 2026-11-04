// v0.9 (lote b): campos e interação — divisão, sliders, dial e confirmações.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_theme.dart';
import '../format.dart';
import '../motion.dart';
import '../ss_list.dart';
import '../ss_strings.dart';

// ---------------------------------------------------------------------------
// SsSplitSlider
// ---------------------------------------------------------------------------

/// Uma linha do [SsSplitSlider]: quem e quanto (em centavos).
class SsSplitEntry {
  const SsSplitEntry(this.name, this.cents);
  final String name;
  final int cents;
}

/// Divide um valor entre pessoas: uma linha por pessoa (avatar, nome e valor
/// em DM Mono) com um slider de marcas pontilhadas e seletor grande. Com
/// [locked] (soma travada), mexer numa linha redistribui o resto entre as
/// outras para fechar [total]; sem ele, cada uma vai livre de 0 a [total] e o
/// rodapé mostra quanto falta ou sobra.
///
/// `SsSplitSlider(total: 75086, entries: [SsSplitEntry('Eu', 25000), ...], onChanged: (v) => ...)`
class SsSplitSlider extends StatefulWidget {
  const SsSplitSlider({
    super.key,
    required this.total,
    required this.entries,
    this.onChanged,
    this.locked = true,
    this.step = 100,
    this.marks = 8,
    this.showTotal = true,
  });

  /// Valor a dividir, em centavos.
  final int total;
  final List<SsSplitEntry> entries;

  /// Valores de cada linha (centavos), na ordem de [entries].
  final ValueChanged<List<int>>? onChanged;
  final bool locked;

  /// Passo do arrasto e do teclado, em centavos (padrão R$ 1,00).
  final int step;

  /// Pontinhos na trilha (dão o ritmo do haptic).
  final int marks;
  final bool showTotal;

  /// Põe [index] em [value] e redistribui o resto entre as outras linhas, na
  /// proporção que já tinham, para a soma continuar [total] (exata, em centavos).
  static List<int> redistribute(List<int> values, int index, int value, int total) {
    final v = value.clamp(0, total);
    final out = [...values];
    out[index] = v;
    final others = [for (var i = 0; i < values.length; i++) i]..remove(index);
    if (others.isEmpty) return out..[index] = total;
    final resto = total - v;
    final soma = others.fold<int>(0, (s, i) => s + values[i]);
    var usado = 0;
    for (final i in others) {
      final parte = soma == 0 ? resto ~/ others.length : (values[i] * resto / soma).floor();
      out[i] = parte;
      usado += parte;
    }
    // Centavos que sobraram do arredondamento: um para cada, a partir da maior.
    final ordem = [...others]..sort((a, b) => out[b].compareTo(out[a]));
    var k = 0;
    while (usado < resto) {
      out[ordem[k % ordem.length]]++;
      usado++;
      k++;
    }
    return out;
  }

  @override
  State<SsSplitSlider> createState() => _SsSplitSliderState();
}

class _SsSplitSliderState extends State<SsSplitSlider> {
  late List<int> _v = [for (final e in widget.entries) e.cents];
  int? _dragging;

  @override
  void didUpdateWidget(SsSplitSlider old) {
    super.didUpdateWidget(old);
    final novos = [for (final e in widget.entries) e.cents];
    final antigos = [for (final e in old.entries) e.cents];
    if (novos.length != antigos.length || widget.total != old.total || !_iguais(novos, antigos)) _v = novos;
  }

  static bool _iguais(List<int> a, List<int> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _set(int i, int cents) {
    final snapped = ((cents / widget.step).round() * widget.step).clamp(0, widget.total);
    if (snapped == _v[i]) return;
    final markCents = widget.total / math.max(widget.marks, 1);
    if ((snapped / markCents).floor() != (_v[i] / markCents).floor()) SsHaptics.tick();
    setState(() {
      _v = widget.locked ? SsSplitSlider.redistribute(_v, i, snapped, widget.total) : ([..._v]..[i] = snapped);
    });
    widget.onChanged?.call(List.unmodifiable(_v));
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final soma = _v.fold<int>(0, (s, v) => s + v);
    final diff = widget.total - soma;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.entries.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _SplitRow(
              name: widget.entries[i].name,
              cents: _v[i],
              total: widget.total,
              color: c.series[i % c.series.length],
              marks: widget.marks,
              animate: _dragging != i,
              onStart: () => setState(() => _dragging = i),
              onEnd: () => setState(() => _dragging = null),
              onChanged: (v) => _set(i, v),
              step: widget.step,
            ),
          ),
        if (widget.showTotal)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.locked
                        ? SsStrings.of(context).total
                        : (diff == 0
                              ? SsStrings.of(context).totalClosed
                              : (diff > 0 ? SsStrings.of(context).missing : SsStrings.of(context).over)),
                    style: TextStyle(
                      color: !widget.locked && diff != 0 ? c.dangerText : c.muted,
                      fontSize: AppType.sub,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  widget.locked || diff == 0
                      ? money(widget.total, SsFormats.of(context))
                      : money(diff.abs(), SsFormats.of(context)),
                  style: AppTheme.number(
                    context,
                    size: AppType.body,
                    color: !widget.locked && diff != 0 ? c.dangerText : c.ink,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SplitRow extends StatelessWidget {
  const _SplitRow({
    required this.name,
    required this.cents,
    required this.total,
    required this.color,
    required this.marks,
    required this.animate,
    required this.onStart,
    required this.onEnd,
    required this.onChanged,
    required this.step,
  });

  final String name;
  final int cents, total, marks, step;
  final Color color;
  final bool animate;
  final VoidCallback onStart, onEnd;
  final ValueChanged<int> onChanged;

  static const _thumb = 30.0;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final frac = total == 0 ? 0.0 : cents / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SsAvatar(name, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: c.ink, fontSize: AppType.body, fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              money(cents, SsFormats.of(context)),
              style: AppTheme.number(context, size: AppType.md, weight: FontWeight.w500, color: c.ink),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Semantics(
          slider: true,
          label: SsStrings.of(context).shareOf(name),
          value: money(cents, SsFormats.of(context)),
          increasedValue: money(math.min(total, cents + step), SsFormats.of(context)),
          decreasedValue: money(math.max(0, cents - step), SsFormats.of(context)),
          onIncrease: () => onChanged(cents + step),
          onDecrease: () => onChanged(cents - step),
          child: LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth;
              int at(double dx) => ((dx - _thumb / 2) / math.max(1, w - _thumb) * total).round();
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (d) {
                  onStart();
                  onChanged(at(d.localPosition.dx));
                },
                onHorizontalDragUpdate: (d) => onChanged(at(d.localPosition.dx)),
                onHorizontalDragEnd: (_) => onEnd(),
                onHorizontalDragCancel: onEnd,
                onTapUp: (d) => onChanged(at(d.localPosition.dx)),
                child: SizedBox(
                  height: 48,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: frac),
                    duration: animate && !reduceMotion(context) ? SsMotion.base : Duration.zero,
                    curve: Curves.easeOutCubic,
                    builder: (_, f, _) => CustomPaint(
                      painter: _SplitTrackPainter(
                        f: f,
                        color: color,
                        track: c.field,
                        dot: c.muted2,
                        marks: marks,
                        thumb: _thumb,
                        thumbFill: c.surface,
                        shadow: c.isDark ? Colors.black : const Color(0x33141628),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SplitTrackPainter extends CustomPainter {
  _SplitTrackPainter({
    required this.f,
    required this.color,
    required this.track,
    required this.dot,
    required this.marks,
    required this.thumb,
    required this.thumbFill,
    required this.shadow,
  });

  final double f, thumb;
  final Color color, track, dot, thumbFill, shadow;
  final int marks;

  @override
  void paint(Canvas canvas, Size size) {
    const h = 22.0;
    final cy = size.height / 2;
    final r = RRect.fromLTRBR(0, cy - h / 2, size.width, cy + h / 2, const Radius.circular(h / 2));
    canvas.drawRRect(r, Paint()..color = track);
    final x = thumb / 2 + (size.width - thumb) * f.clamp(0.0, 1.0);
    canvas.drawRRect(
      RRect.fromLTRBR(0, cy - h / 2, x + h / 2, cy + h / 2, const Radius.circular(h / 2)),
      Paint()..color = color,
    );
    // Marcas pontilhadas: claras sobre o preenchimento, apagadas na trilha.
    for (var k = 0; k <= marks; k++) {
      final mx = thumb / 2 + (size.width - thumb) * k / math.max(marks, 1);
      final cheio = mx < x;
      canvas.drawCircle(
        Offset(mx, cy),
        k.isEven ? 2.4 : 1.6,
        Paint()..color = cheio ? Colors.white.withValues(alpha: .8) : dot,
      );
    }
    final c = Offset(x, cy);
    canvas.drawCircle(c.translate(0, 2), thumb / 2, Paint()..color = shadow.withValues(alpha: .22));
    canvas.drawCircle(c, thumb / 2, Paint()..color = thumbFill);
    canvas.drawCircle(
      c,
      thumb / 2 - 2,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_SplitTrackPainter old) => old.f != f || old.color != color || old.track != track;
}

// ---------------------------------------------------------------------------
// SsVerticalSlider
// ---------------------------------------------------------------------------

/// Slider vertical (termostato, volume, luz): trilha alta em pílula que enche
/// de baixo e o valor escrito no seletor, em DM Mono. Arrastar ou tocar muda;
/// setas do teclado e o leitor de tela sobem e descem [step].
class SsVerticalSlider extends StatefulWidget {
  const SsVerticalSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.label,
    this.format,
    this.height = 220,
    this.width = 64,
    this.color,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double min, max, step;

  /// Nome para o leitor de tela ("Temperatura").
  final String? label;

  /// Texto do valor (padrão: [qty]).
  final String Function(double value)? format;
  final double height, width;
  final Color? color;

  @override
  State<SsVerticalSlider> createState() => _SsVerticalSliderState();
}

class _SsVerticalSliderState extends State<SsVerticalSlider> {
  bool _focus = false;

  SsFormats _formats = SsFormats.brl;

  String _fmt(double v) => widget.format?.call(v) ?? qty(v, _formats);

  void _set(double v) {
    final s = widget.step <= 0 ? v : (v / widget.step).round() * widget.step;
    final n = s.clamp(widget.min, widget.max).toDouble();
    if (n == widget.value || widget.onChanged == null) return;
    SsHaptics.tick();
    widget.onChanged!(n);
  }

  void _fromDy(double dy) {
    final thumb = widget.width - 8;
    final f = 1 - ((dy - thumb / 2) / math.max(1, widget.height - thumb)).clamp(0.0, 1.0);
    _set(widget.min + f * (widget.max - widget.min));
  }

  @override
  Widget build(BuildContext context) {
    _formats = SsFormats.of(context);
    final c = SsColors.of(context);
    final cor = widget.color ?? c.accent;
    final span = widget.max - widget.min;
    final f = span == 0 ? 0.0 : ((widget.value - widget.min) / span).clamp(0.0, 1.0);
    final thumb = widget.width - 8;
    final enabled = widget.onChanged != null;
    return Semantics(
      slider: true,
      label: widget.label,
      value: _fmt(widget.value),
      increasedValue: _fmt(math.min(widget.max, widget.value + widget.step)),
      decreasedValue: _fmt(math.max(widget.min, widget.value - widget.step)),
      onIncrease: enabled ? () => _set(widget.value + widget.step) : null,
      onDecrease: enabled ? () => _set(widget.value - widget.step) : null,
      child: Focus(
        canRequestFocus: enabled,
        onFocusChange: (v) => setState(() => _focus = v),
        onKeyEvent: (_, e) {
          if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
          if (e.logicalKey == LogicalKeyboardKey.arrowUp || e.logicalKey == LogicalKeyboardKey.arrowRight) {
            _set(widget.value + widget.step);
            return KeyEventResult.handled;
          }
          if (e.logicalKey == LogicalKeyboardKey.arrowDown || e.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _set(widget.value - widget.step);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: enabled ? (d) => _fromDy(d.localPosition.dy) : null,
          onVerticalDragUpdate: enabled ? (d) => _fromDy(d.localPosition.dy) : null,
          onTapUp: enabled ? (d) => _fromDy(d.localPosition.dy) : null,
          child: Container(
            width: widget.width,
            height: widget.height,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: c.field,
              borderRadius: BorderRadius.circular(widget.width / 2),
              border: _focus ? Border.all(color: c.accent, width: 2) : null,
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: f),
              duration: reduceMotion(context) ? Duration.zero : SsMotion.fast,
              curve: Curves.easeOutCubic,
              builder: (context, t, _) {
                final inner = widget.height - 8;
                final top = (inner - thumb) * (1 - t);
                return Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: inner - top,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: cor.withValues(alpha: enabled ? 1 : .4),
                          borderRadius: BorderRadius.circular(thumb / 2),
                        ),
                      ),
                    ),
                    Positioned(
                      top: top,
                      left: 0,
                      child: Container(
                        width: thumb,
                        height: thumb,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.surface,
                          shape: BoxShape.circle,
                          boxShadow: const [BoxShadow(color: Color(0x33141628), blurRadius: 8, offset: Offset(0, 2))],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FittedBox(
                            child: Text(
                              _fmt(widget.value),
                              style: AppTheme.number(context, size: AppType.md, weight: FontWeight.w500, color: c.ink),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SsDial
// ---------------------------------------------------------------------------

/// Botão giratório: arco de 270° com marcações, progresso na cor da marca e o
/// valor grande no centro. Arrasto circular (vibra a cada [step]); setas do
/// teclado e o leitor de tela também mudam o valor.
class SsDial extends StatefulWidget {
  const SsDial({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.label,
    this.caption,
    this.format,
    this.size = 220,
    this.ticks = 40,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double min, max, step;

  /// Nome para o leitor de tela.
  final String? label;

  /// Texto pequeno embaixo do valor ("Sala", "°C").
  final String? caption;
  final String Function(double value)? format;
  final double size;
  final int ticks;

  static const _start = 135.0;
  static const _sweep = 270.0;

  /// Ângulo do toque (graus, 0 = direita, horário) → fração 0..1 do arco.
  /// Na "boca" de baixo, gruda na ponta mais perto de [current].
  static double fractionForAngle(double deg, double current) {
    final rel = (deg - _start + 360) % 360;
    if (rel <= _sweep) return rel / _sweep;
    return current > .5 ? 1 : 0;
  }

  @override
  State<SsDial> createState() => _SsDialState();
}

class _SsDialState extends State<SsDial> {
  SsFormats _formats = SsFormats.brl;

  String _fmt(double v) => widget.format?.call(v) ?? qty(v, _formats);

  double get _f {
    final span = widget.max - widget.min;
    return span == 0 ? 0 : ((widget.value - widget.min) / span).clamp(0.0, 1.0);
  }

  void _set(double v) {
    final s = widget.step <= 0 ? v : (v / widget.step).round() * widget.step;
    final n = s.clamp(widget.min, widget.max).toDouble();
    if (n == widget.value || widget.onChanged == null) return;
    SsHaptics.tick();
    widget.onChanged!(n);
  }

  void _drag(Offset p) {
    final c = Offset(widget.size / 2, widget.size / 2);
    final d = p - c;
    if (d.distance < widget.size * .12) return;
    final deg = (math.atan2(d.dy, d.dx) * 180 / math.pi + 360) % 360;
    final f = SsDial.fractionForAngle(deg, _f);
    _set(widget.min + f * (widget.max - widget.min));
  }

  @override
  Widget build(BuildContext context) {
    _formats = SsFormats.of(context);
    final c = SsColors.of(context);
    final enabled = widget.onChanged != null;
    return Semantics(
      slider: true,
      label: widget.label,
      value: _fmt(widget.value),
      increasedValue: _fmt(math.min(widget.max, widget.value + widget.step)),
      decreasedValue: _fmt(math.max(widget.min, widget.value - widget.step)),
      onIncrease: enabled ? () => _set(widget.value + widget.step) : null,
      onDecrease: enabled ? () => _set(widget.value - widget.step) : null,
      child: Focus(
        canRequestFocus: enabled,
        onKeyEvent: (_, e) {
          if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
          final k = e.logicalKey;
          if (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.arrowRight) {
            _set(widget.value + widget.step);
            return KeyEventResult.handled;
          }
          if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.arrowLeft) {
            _set(widget.value - widget.step);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: enabled ? (d) => _drag(d.localPosition) : null,
          onPanUpdate: enabled ? (d) => _drag(d.localPosition) : null,
          onTapUp: enabled ? (d) => _drag(d.localPosition) : null,
          child: SizedBox.square(
            dimension: widget.size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: _f),
              duration: reduceMotion(context) ? Duration.zero : SsMotion.fast,
              curve: Curves.easeOutCubic,
              builder: (context, f, _) => CustomPaint(
                painter: _DialPainter(
                  f: f,
                  ticks: widget.ticks,
                  accent: c.accent,
                  track: c.field,
                  tick: c.muted2,
                  knob: c.surface,
                  line: c.line,
                  dark: c.isDark,
                ),
                child: Center(
                  child: ExcludeSemantics(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _fmt(widget.value),
                          style: AppTheme.number(context, size: widget.size * .17, color: c.ink),
                        ),
                        if (widget.caption != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            widget.caption!,
                            style: TextStyle(color: c.muted, fontSize: AppType.sub, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.f,
    required this.ticks,
    required this.accent,
    required this.track,
    required this.tick,
    required this.knob,
    required this.line,
    required this.dark,
  });

  final double f;
  final int ticks;
  final Color accent, track, tick, knob, line;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    const rad = math.pi / 180;
    final start = SsDial._start * rad;
    final sweep = SsDial._sweep * rad;
    // Marcações por fora.
    for (var k = 0; k <= ticks; k++) {
      final a = start + sweep * k / ticks;
      final on = k / ticks <= f + 1e-6;
      final longa = k % 5 == 0;
      final p1 = c + Offset(math.cos(a), math.sin(a)) * (r - 2);
      final p2 = c + Offset(math.cos(a), math.sin(a)) * (r - (longa ? 12 : 8));
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = on ? accent : tick
          ..strokeWidth = longa ? 2 : 1.4
          ..strokeCap = StrokeCap.round,
      );
    }
    // Trilha e progresso.
    final ar = r - 26;
    final rect = Rect.fromCircle(center: c, radius: ar);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep, false, arc..color = track);
    if (f > 0) canvas.drawArc(rect, start, sweep * f, false, arc..color = accent);
    // Botão do meio (sombra no claro, borda no escuro).
    final kr = ar - 18;
    if (!dark) {
      canvas.drawCircle(
        c.translate(0, 4),
        kr,
        Paint()
          ..color = const Color(0x22141628)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    canvas.drawCircle(c, kr, Paint()..color = knob);
    if (dark) {
      canvas.drawCircle(
        c,
        kr,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke,
      );
    }
    // Seletor na ponta do arco.
    final a = start + sweep * f;
    final p = c + Offset(math.cos(a), math.sin(a)) * ar;
    canvas.drawCircle(p, 9, Paint()..color = knob);
    canvas.drawCircle(p, 5, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_DialPainter old) => old.f != f || old.accent != accent || old.knob != knob;
}

// ---------------------------------------------------------------------------
// SsHoldToConfirm
// ---------------------------------------------------------------------------

/// Segurar para confirmar (excluir, encerrar, transferir): o fundo enche da
/// esquerda enquanto o dedo fica em cima; no fim vibra, mostra ✓ e chama
/// [onConfirmed]. Soltou antes, volta. O leitor de tela confirma com um toque.
class SsHoldToConfirm extends StatefulWidget {
  const SsHoldToConfirm({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.icon = Icons.touch_app_outlined,
    this.doneLabel,
    this.duration = const Duration(milliseconds: 1200),
    this.danger = false,
  });

  final String label;
  final VoidCallback? onConfirmed;
  final IconData icon;

  /// Padrão: [SsStrings.confirmed] (segurar) ou [SsStrings.done] (arrastar).
  final String? doneLabel;
  final Duration duration;

  /// Vermelho de erro (exclusão).
  final bool danger;

  @override
  State<SsHoldToConfirm> createState() => _SsHoldToConfirmState();
}

class _SsHoldToConfirmState extends State<SsHoldToConfirm> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.duration)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _done();
    });
  bool _ok = false;
  Timer? _volta;

  void _done() {
    if (_ok) return;
    SsHaptics.success();
    setState(() => _ok = true);
    widget.onConfirmed?.call();
    _volta = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      _c.value = 0;
      setState(() => _ok = false);
    });
  }

  void _down() {
    if (_ok || widget.onConfirmed == null) return;
    SsHaptics.tick();
    _c.forward();
  }

  void _up() {
    if (_ok || _c.isCompleted) return;
    _c.animateBack(
      0,
      duration: Duration(milliseconds: (240 * _c.value).round() + 1),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _volta?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final cor = widget.danger ? AppColors.danger : c.accent;
    final enabled = widget.onConfirmed != null;
    Widget conteudo(Color fg, IconData icon, String text) => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: fg),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: fg, fontSize: AppType.body, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: _ok ? widget.doneLabel ?? SsStrings.of(context).confirmed : widget.label,
      hint: SsStrings.of(context).holdToConfirm,
      liveRegion: true,
      onTap: enabled && !_ok ? () => _c.value = 1 : null,
      excludeSemantics: true,
      child: Listener(
        onPointerDown: (_) => _down(),
        onPointerUp: (_) => _up(),
        onPointerCancel: (_) => _up(),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _ok ? 1.0 : _c.value;
            return AnimatedScale(
              scale: t > 0 && !_ok && !reduceMotion(context) ? .98 : 1,
              duration: SsMotion.fast,
              child: Container(
                height: 56,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: widget.danger ? AppColors.dangerSoft : c.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: conteudo(
                        enabled ? (widget.danger ? c.dangerText : c.accentText) : c.muted,
                        widget.icon,
                        widget.label,
                      ),
                    ),
                    // Parte cheia: mesma linha em branco, recortada até o progresso.
                    ClipRect(
                      clipper: _FracClipper(t),
                      child: ColoredBox(
                        color: _ok ? AppColors.success : cor,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: conteudo(
                            AppColors.onDark,
                            _ok ? Icons.check_rounded : widget.icon,
                            _ok ? widget.doneLabel ?? SsStrings.of(context).confirmed : widget.label,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FracClipper extends CustomClipper<Rect> {
  _FracClipper(this.t);
  final double t;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * t, size.height);

  @override
  bool shouldReclip(_FracClipper old) => old.t != t;
}

// ---------------------------------------------------------------------------
// SsSwipeToConfirm
// ---------------------------------------------------------------------------

/// Arrastar a bolinha até o fim para pagar ou fechar o pedido (evita o toque
/// sem querer). Passou de 85%: vibra, gruda no fim, mostra carregando enquanto
/// [onConfirm] roda e termina em ✓ [doneLabel]. Se [onConfirm] lançar erro,
/// a bolinha volta. O leitor de tela confirma com um toque.
class SsSwipeToConfirm extends StatefulWidget {
  const SsSwipeToConfirm({
    super.key,
    required this.label,
    required this.onConfirm,
    this.doneLabel,
    this.icon = Icons.arrow_forward_rounded,
    this.done = false,
  });

  final String label;
  final Future<void> Function()? onConfirm;

  /// Padrão: [SsStrings.confirmed] (segurar) ou [SsStrings.done] (arrastar).
  final String? doneLabel;
  final IconData icon;

  /// Já começa concluído (restaurar a tela depois de pago).
  final bool done;

  @override
  State<SsSwipeToConfirm> createState() => _SsSwipeToConfirmState();
}

enum _SwipeFase { idle, loading, done }

class _SsSwipeToConfirmState extends State<SsSwipeToConfirm> with SingleTickerProviderStateMixin {
  late final _pos = AnimationController(vsync: this, value: widget.done ? 1 : 0);
  late var _fase = widget.done ? _SwipeFase.done : _SwipeFase.idle;
  bool _passou = false;

  static const _h = 60.0;
  static const _thumb = 52.0;

  Future<void> _confirm() async {
    if (_fase != _SwipeFase.idle || widget.onConfirm == null) return;
    SsHaptics.threshold();
    setState(() => _fase = _SwipeFase.loading);
    _pos.animateTo(1, duration: SsMotion.fast, curve: Curves.easeOut);
    try {
      await widget.onConfirm!();
    } catch (_) {
      if (!mounted) return;
      SsHaptics.error();
      setState(() => _fase = _SwipeFase.idle);
      _pos.animateTo(0, duration: SsMotion.slow, curve: Curves.easeOutCubic);
      return;
    }
    if (!mounted) return;
    SsHaptics.success();
    setState(() => _fase = _SwipeFase.done);
  }

  @override
  void dispose() {
    _pos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final enabled = widget.onConfirm != null;
    final done = _fase == _SwipeFase.done;
    return Semantics(
      button: true,
      enabled: enabled,
      label: done ? widget.doneLabel ?? SsStrings.of(context).done : widget.label,
      hint: done ? null : SsStrings.of(context).slideToConfirm,
      liveRegion: true,
      onTap: enabled && _fase == _SwipeFase.idle ? _confirm : null,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, box) {
          final curso = math.max(1.0, box.maxWidth - _thumb - 8);
          return GestureDetector(
            onHorizontalDragUpdate: !enabled || _fase != _SwipeFase.idle
                ? null
                : (d) {
                    _pos.value = (_pos.value + d.delta.dx / curso).clamp(0.0, 1.0);
                    final passou = _pos.value > .85;
                    if (passou != _passou) {
                      _passou = passou;
                      if (passou) SsHaptics.tick();
                    }
                  },
            onHorizontalDragEnd: !enabled || _fase != _SwipeFase.idle
                ? null
                : (_) {
                    if (_pos.value > .85) {
                      _confirm();
                    } else {
                      _pos.animateTo(
                        0,
                        duration: reduceMotion(context) ? Duration.zero : SsMotion.slow,
                        curve: SsMotion.spring,
                      );
                    }
                    _passou = false;
                  },
            child: AnimatedBuilder(
              animation: _pos,
              builder: (context, _) {
                final p = _pos.value.clamp(0.0, 1.0);
                return AnimatedContainer(
                  duration: SsMotion.base,
                  height: _h,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: done ? AppColors.success : c.field,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Stack(
                    children: [
                      // Rastro da bolinha na cor da marca.
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: _thumb + curso * p,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: done ? Colors.transparent : c.accent.withValues(alpha: .16),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: _thumb + 8),
                          child: Opacity(
                            opacity: done ? 1 : (1 - p * 1.4).clamp(0.0, 1.0),
                            child: Text(
                              done ? widget.doneLabel ?? SsStrings.of(context).done : widget.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: done ? AppColors.onDark : (enabled ? c.ink2 : c.muted),
                                fontSize: AppType.body,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: curso * p,
                        top: 0,
                        child: Container(
                          width: _thumb,
                          height: _thumb,
                          decoration: BoxDecoration(
                            color: done ? AppColors.onDark : (enabled ? c.accent : c.muted2),
                            shape: BoxShape.circle,
                            boxShadow: enabled && !done ? c.primaryShadow : null,
                          ),
                          child: Center(
                            child: switch (_fase) {
                              _SwipeFase.loading => const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.onDark),
                              ),
                              _SwipeFase.done => const Icon(Icons.check_rounded, color: AppColors.success, size: 26),
                              _SwipeFase.idle => Icon(widget.icon, color: AppColors.onDark, size: 24),
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SsMorphButton
// ---------------------------------------------------------------------------

/// Botão em pílula que vira um círculo com progresso enquanto [onPressed]
/// roda e termina em ✓ (verde) ou ✗ (vermelho, quando lança erro), voltando à
/// pílula depois de 1,6 s. Com [progress] (0 a 1, ex.: envio de arquivo) o
/// anel é determinado. Diferente do `SsActionButton`, que fica do tamanho do
/// botão e só sacode no erro: use este quando o resultado precisa ficar visível.
class SsMorphButton extends StatefulWidget {
  const SsMorphButton({super.key, required this.label, required this.onPressed, this.icon, this.progress});

  final String label;
  final Future<void> Function()? onPressed;
  final IconData? icon;

  /// Progresso real (upload). Nulo: anel indeterminado.
  final ValueListenable<double>? progress;

  @override
  State<SsMorphButton> createState() => _SsMorphButtonState();
}

enum _MorphFase { idle, running, ok, erro }

class _SsMorphButtonState extends State<SsMorphButton> {
  var _fase = _MorphFase.idle;
  Timer? _volta;

  Future<void> _run() async {
    if (_fase != _MorphFase.idle || widget.onPressed == null) return;
    setState(() => _fase = _MorphFase.running);
    var ok = true;
    try {
      await widget.onPressed!();
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    ok ? SsHaptics.success() : SsHaptics.error();
    setState(() => _fase = ok ? _MorphFase.ok : _MorphFase.erro);
    _volta = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _fase = _MorphFase.idle);
    });
  }

  @override
  void dispose() {
    _volta?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final idle = _fase == _MorphFase.idle;
    final enabled = widget.onPressed != null;
    final bg = switch (_fase) {
      _MorphFase.ok => AppColors.success,
      _MorphFase.erro => AppColors.danger,
      _MorphFase.running => c.accentSoft,
      _MorphFase.idle => enabled ? c.accent : c.muted2,
    };
    final dur = reduceMotion(context) ? Duration.zero : SsMotion.base;
    final rotulo = switch (_fase) {
      _MorphFase.idle => widget.label,
      _MorphFase.running => SsStrings.of(context).stateLoading(widget.label),
      _MorphFase.ok => SsStrings.of(context).stateDone(widget.label),
      _MorphFase.erro => SsStrings.of(context).stateFailed(widget.label),
    };
    return Semantics(
      button: true,
      enabled: enabled,
      label: rotulo,
      liveRegion: true,
      excludeSemantics: true,
      onTap: enabled && idle ? _run : null,
      child: LayoutBuilder(
        builder: (context, box) {
          final full = box.maxWidth.isFinite ? box.maxWidth : 240.0;
          return Center(
            child: SsPressable(
              enabled: enabled && idle,
              onTap: enabled && idle ? _run : null,
              child: AnimatedContainer(
                duration: dur,
                curve: Curves.easeInOutCubic,
                width: idle ? full : 52,
                height: 52,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: idle && enabled ? c.primaryShadow : null,
                ),
                child: AnimatedSwitcher(
                  duration: dur,
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: ScaleTransition(scale: Tween(begin: .6, end: 1.0).animate(a), child: child),
                  ),
                  child: switch (_fase) {
                    _MorphFase.idle => Padding(
                      key: const ValueKey('idle'),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, color: AppColors.onDark, size: 20),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              widget.label,
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              softWrap: false,
                              style: const TextStyle(
                                color: AppColors.onDark,
                                fontSize: AppType.body,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _MorphFase.running => Padding(
                      key: const ValueKey('run'),
                      padding: const EdgeInsets.all(12),
                      child: widget.progress == null
                          ? CircularProgressIndicator(strokeWidth: 3, color: c.accent)
                          : ValueListenableBuilder<double>(
                              valueListenable: widget.progress!,
                              builder: (_, v, _) => CircularProgressIndicator(
                                value: v.clamp(0.0, 1.0),
                                strokeWidth: 3,
                                color: c.accent,
                                backgroundColor: c.accent.withValues(alpha: .18),
                              ),
                            ),
                    ),
                    _MorphFase.ok => const Icon(
                      Icons.check_rounded,
                      key: ValueKey('ok'),
                      color: AppColors.onDark,
                      size: 26,
                    ),
                    _MorphFase.erro => const Icon(
                      Icons.close_rounded,
                      key: ValueKey('erro'),
                      color: AppColors.onDark,
                      size: 26,
                    ),
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
