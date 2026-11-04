import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_theme.dart';
import '../format.dart';
import '../motion.dart';
import '../ss_strings.dart';
import 'ctl_comum.dart';

/// O que o aparelho está fazendo agora (independe do modo escolhido).
enum SsThermostatAction {
  /// Desligado.
  off,

  /// Aquecendo até o alvo.
  heating,

  /// Resfriando até o alvo.
  cooling,

  /// Chegou no alvo e espera.
  idle,
}

/// Modo do termostato (chip embaixo do anel). Os quatro comuns já vêm prontos
/// ([off], [heat], [cool], [auto]); modo próprio ("seco", "ventilar") passa
/// [value], [label], [icon] e, se quiser, o [tone] do anel.
@immutable
class SsThermostatMode {
  const SsThermostatMode(this.value, this.label, {this.icon, this.tone});

  final String value;

  /// Nome no chip. Nulo nos quatro prontos: vem do [SsStrings] ([labelIn]).
  final String? label;
  final IconData? icon;

  /// Cor do anel neste modo (padrão: pelo [value]: heat quente, cool azul,
  /// off cinza, os outros na cor da marca).
  final Color? tone;

  static const off = SsThermostatMode('off', null, icon: Icons.power_settings_new_rounded);
  static const heat = SsThermostatMode('heat', null, icon: Icons.local_fire_department_outlined);
  static const cool = SsThermostatMode('cool', null, icon: Icons.ac_unit_rounded);
  static const auto = SsThermostatMode('auto', null, icon: Icons.autorenew_rounded);

  /// O [label], ou o nome do modo pronto no idioma de [s] (padrão: pt).
  String labelIn([SsStrings? s]) {
    final t = s ?? SsStrings.pt;
    return label ??
        switch (value) {
          'off' => t.thermostatModeOff,
          'heat' => t.thermostatModeHeat,
          'cool' => t.thermostatModeCool,
          'auto' => t.thermostatModeAuto,
          _ => value,
        };
  }

  /// Os quatro de sempre, na ordem.
  static const standard = [off, heat, cool, auto];
}

/// Termostato: anel de 270° com a temperatura alvo grande no centro, a
/// atual embaixo e um pontinho no anel, botões −/+ de [step] e (opcional)
/// arrasto no próprio anel. Os chips de [modes] trocam o modo; a cor do anel
/// segue o modo (aquecer âmbar, resfriar azul, desligado cinza).
///
/// O valor anda na hora (−/+, arrasto, teclado) e [onChanged] só é chamado
/// depois de [debounce] parado: vários toques viram um comando.
/// Sem [onChanged], fica apagado. [pending] mostra que o comando está indo.
class SsThermostat extends StatefulWidget {
  const SsThermostat({
    super.key,
    required this.target,
    required this.onChanged,
    this.current,
    this.min = 7,
    this.max = 35,
    this.step = .5,
    this.unit = '°C',
    this.mode = 'heat',
    this.modes = SsThermostatMode.standard,
    this.onModeChanged,
    this.action,
    this.pending = false,
    this.draggable = true,
    this.debounce = const Duration(milliseconds: 700),
    this.size = 240,
    this.format,
    this.label,
    this.currentLabel,
    this.lessLabel,
    this.moreLabel,
    this.offLabel,
    this.heatingLabel,
    this.coolingLabel,
    this.idleLabel,
    this.pendingLabel,
    this.modesLabel,
  });

  /// Temperatura alvo.
  final double target;

  /// Chamado com o alvo novo depois de [debounce]. Nulo = apagado.
  final ValueChanged<double>? onChanged;

  /// Temperatura medida agora (pontinho no anel e "Agora 21,5°").
  final double? current;
  final double min, max, step;
  final String unit;

  /// Modo atual ([SsThermostatMode.value]).
  final String mode;
  final List<SsThermostatMode> modes;
  final ValueChanged<String>? onModeChanged;

  /// O que está fazendo agora. Nulo: deduz do modo e da temperatura.
  final SsThermostatAction? action;
  final bool pending;
  final bool draggable;
  final Duration debounce;
  final double size;

  /// Texto do número (padrão: "21,5°").
  final String Function(double value)? format;

  final String? label, currentLabel, lessLabel, moreLabel, modesLabel;
  final String? offLabel, heatingLabel, coolingLabel, idleLabel, pendingLabel;

  static const _start = 135.0;
  static const _sweep = 270.0;

  /// Ângulo do toque (graus, 0 = direita, horário) → fração 0..1 do arco; na
  /// "boca" de baixo gruda na ponta mais perto de [current].
  static double fractionForAngle(double deg, double current) {
    final rel = (deg - _start + 360) % 360;
    if (rel <= _sweep) return rel / _sweep;
    return current > .5 ? 1 : 0;
  }

  /// O que o aparelho faz, quando [action] não vem: desligado no modo off;
  /// abaixo do alvo e aquecendo (heat/auto) = heating; acima e resfriando
  /// (cool/auto) = cooling; senão idle.
  static SsThermostatAction resolveAction(String mode, double target, double? current) {
    if (mode == 'off') return SsThermostatAction.off;
    if (current == null) return SsThermostatAction.idle;
    if ((mode == 'heat' || mode == 'auto') && current < target - .25) return SsThermostatAction.heating;
    if ((mode == 'cool' || mode == 'auto') && current > target + .25) return SsThermostatAction.cooling;
    return SsThermostatAction.idle;
  }

  @override
  State<SsThermostat> createState() => _SsThermostatState();
}

class _SsThermostatState extends State<SsThermostat> {
  SsStrings get _s => SsStrings.of(context);
  late double _v = widget.target;
  Timer? _t;

  @override
  void didUpdateWidget(SsThermostat old) {
    super.didUpdateWidget(old);
    // O servidor confirmou (ou trocou) o alvo e não há toque pendente.
    if (old.target != widget.target && _t == null) _v = widget.target;
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  bool get _enabled => widget.onChanged != null && widget.mode != 'off';
  String _fmt(double v) => widget.format?.call(v) ?? '${qty(v, SsFormats.of(context))}°';

  void _set(double v) {
    final n = ctlSnap(v, widget.min, widget.max, widget.step);
    if (n == _v || !_enabled) return;
    SsHaptics.tick();
    setState(() => _v = n);
    _t?.cancel();
    if (widget.debounce == Duration.zero) {
      _t = null;
      widget.onChanged!(n);
      return;
    }
    _t = Timer(widget.debounce, () {
      _t = null;
      if (mounted) widget.onChanged!(_v);
    });
  }

  double get _f {
    final span = widget.max - widget.min;
    return span == 0 ? 0 : ((_v - widget.min) / span).clamp(0.0, 1.0);
  }

  void _drag(Offset p) {
    final c = Offset(widget.size / 2, widget.size / 2);
    final d = p - c;
    // Só o anel (não o miolo nem fora).
    if (d.distance < widget.size * .3) return;
    final deg = (math.atan2(d.dy, d.dx) * 180 / math.pi + 360) % 360;
    final f = SsThermostat.fractionForAngle(deg, _f);
    _set(widget.min + f * (widget.max - widget.min));
  }

  Color _tone(SsColors c) {
    final m = widget.modes.where((m) => m.value == widget.mode).firstOrNull;
    if (m?.tone != null) return m!.tone!;
    return switch (widget.mode) {
      'off' => c.muted2,
      'heat' => ctlHeat,
      'cool' => ctlCool,
      _ => c.accent,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final tone = _tone(c);
    final off = widget.mode == 'off';
    final action = widget.action ?? SsThermostat.resolveAction(widget.mode, _v, widget.current);
    final reduce = reduceMotion(context);
    final legenda = widget.pending
        ? widget.pendingLabel ?? _s.sending
        : switch (action) {
            SsThermostatAction.off => widget.offLabel ?? _s.thermostatOff,
            SsThermostatAction.heating => widget.heatingLabel ?? _s.thermostatHeating,
            SsThermostatAction.cooling => widget.coolingLabel ?? _s.thermostatCooling,
            SsThermostatAction.idle => widget.idleLabel ?? _s.thermostatIdle,
          };
    final corLegenda = switch (action) {
      SsThermostatAction.heating => c.aquecText,
      SsThermostatAction.cooling => c.isDark ? const Color(0xFF8DB8FF) : const Color(0xFF1D5FD1),
      _ => c.muted,
    };
    final apagado = widget.onChanged == null;
    final cf = widget.current == null || widget.max == widget.min
        ? null
        : ((widget.current! - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);

    final anel = SizedBox.square(
      dimension: widget.size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: _f),
        duration: reduce ? Duration.zero : SsMotion.indicator,
        curve: SsMotion.bounce,
        builder: (context, f, _) => CustomPaint(
          painter: _RingPainter(
            f: f,
            current: cf,
            tone: tone,
            track: Color.alphaBlend(c.muted.withValues(alpha: .18), c.field),
            knob: c.surface,
            mark: c.ink2,
            off: off,
            stroke: widget.size * .065,
          ),
          child: Center(
            child: ExcludeSemantics(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.pending) ...[
                        SizedBox.square(
                          dimension: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, value: reduce ? .3 : null, color: tone),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        legenda.toUpperCase(),
                        style: TextStyle(
                          color: widget.pending ? c.muted : corLegenda,
                          fontSize: AppType.label,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AnimatedOpacity(
                    opacity: off ? .45 : 1,
                    duration: reduce ? Duration.zero : SsMotion.fast,
                    child: Text(
                      _fmt(_v),
                      style: AppTheme.number(context, size: widget.size * .2, color: c.ink),
                    ),
                  ),
                  if (widget.current != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${widget.currentLabel ?? _s.thermostatCurrent} ${_fmt(widget.current!)}',
                      style: TextStyle(color: c.ink2, fontSize: AppType.sub, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final podeMenos = _enabled && _v > widget.min;
    final podeMais = _enabled && _v < widget.max;

    return Opacity(
      opacity: apagado ? .55 : 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            slider: true,
            label: widget.label ?? _s.thermostatLabel,
            value: off ? widget.offLabel ?? _s.thermostatOff : _fmt(_v),
            hint: widget.current != null
                ? '${widget.currentLabel ?? _s.thermostatCurrent} ${_fmt(widget.current!)} · $legenda'
                : legenda,
            increasedValue: _fmt(math.min(widget.max, _v + widget.step)),
            decreasedValue: _fmt(math.max(widget.min, _v - widget.step)),
            onIncrease: podeMais ? () => _set(_v + widget.step) : null,
            onDecrease: podeMenos ? () => _set(_v - widget.step) : null,
            child: Focus(
              canRequestFocus: _enabled,
              onKeyEvent: (_, e) {
                if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
                final k = e.logicalKey;
                if (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.arrowRight) {
                  _set(_v + widget.step);
                  return KeyEventResult.handled;
                }
                if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.arrowLeft) {
                  _set(_v - widget.step);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: _enabled && widget.draggable ? (d) => _drag(d.localPosition) : null,
                onPanUpdate: _enabled && widget.draggable ? (d) => _drag(d.localPosition) : null,
                child: anel,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Passo(
                icon: Icons.remove_rounded,
                label: widget.lessLabel ?? _s.decrease,
                onTap: podeMenos ? () => _set(_v - widget.step) : null,
              ),
              SizedBox(width: widget.size * .28),
              _Passo(
                icon: Icons.add_rounded,
                label: widget.moreLabel ?? _s.increase,
                onTap: podeMais ? () => _set(_v + widget.step) : null,
              ),
            ],
          ),
          if (widget.modes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Semantics(
              label: widget.modesLabel ?? _s.thermostatMode,
              container: true,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in widget.modes)
                    _ModeChip(
                      mode: m,
                      selected: m.value == widget.mode,
                      tone:
                          m.tone ??
                          switch (m.value) {
                            'off' => c.muted,
                            'heat' => ctlHeat,
                            'cool' => ctlCool,
                            _ => c.accent,
                          },
                      onTap: widget.onModeChanged == null || apagado ? null : () => widget.onModeChanged!(m.value),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Passo extends StatelessWidget {
  const _Passo({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final on = onTap != null;
    return Semantics(
      button: true,
      enabled: on,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: SsPressable(
          scale: .88,
          enabled: on,
          onTap: onTap,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.field,
              border: Border.all(color: c.line),
            ),
            child: Icon(icon, size: 26, color: on ? c.ink : c.muted2),
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.mode, required this.selected, required this.tone, required this.onTap});
  final SsThermostatMode mode;
  final bool selected;
  final Color tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final dur = reduceMotion(context) ? Duration.zero : SsMotion.fast;
    final fg = selected
        ? (c.isDark ? Color.lerp(tone, Colors.white, .35)! : Color.lerp(tone, Colors.black, .35)!)
        : c.ink2;
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: mode.labelIn(SsStrings.of(context)),
      excludeSemantics: true,
      child: SsPressable(
        scale: .94,
        enabled: onTap != null,
        onTap: onTap,
        child: AnimatedContainer(
          duration: dur,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            color: selected ? Color.alphaBlend(tone.withValues(alpha: c.isDark ? .22 : .14), c.surface) : c.surface,
            border: Border.all(color: selected ? tone.withValues(alpha: .7) : c.line, width: selected ? 1.4 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (mode.icon != null) ...[
                Icon(mode.icon, size: 18, color: selected ? fg : c.muted),
                const SizedBox(width: 6),
              ],
              Text(
                mode.labelIn(SsStrings.of(context)),
                style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: AppType.sub),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.f,
    required this.current,
    required this.tone,
    required this.track,
    required this.knob,
    required this.mark,
    required this.off,
    required this.stroke,
  });

  final double f;
  final double? current;
  final Color tone, track, knob, mark;
  final bool off;
  final double stroke;

  static const _start = math.pi * .75;
  static const _sweep = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2 - stroke;
    final centro = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: centro, radius: r);
    Paint linha(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _start, _sweep, false, linha(track));
    Offset ponto(double t) {
      final a = _start + _sweep * t;
      return centro + Offset(math.cos(a), math.sin(a)) * r;
    }

    if (!off && f > 0) {
      final bar = linha(tone);
      canvas.drawArc(rect, _start, _sweep * f, false, bar);
    }
    // Temperatura atual: tracinho na tinta.
    if (current != null) {
      final a = _start + _sweep * current!;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        centro + dir * (r - stroke * .9),
        centro + dir * (r + stroke * .9),
        Paint()
          ..color = mark
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
    if (off) return;
    // Seletor do alvo: bolinha branca com aro na cor.
    final k = ponto(f);
    canvas
      ..drawCircle(k, stroke * .95, Paint()..color = const Color(0x33141628))
      ..drawCircle(k, stroke * .85, Paint()..color = knob)
      ..drawCircle(k, stroke * .42, Paint()..color = tone);
  }

  @override
  bool shouldRepaint(_RingPainter o) =>
      o.f != f || o.current != current || o.tone != tone || o.off != off || o.track != track || o.knob != knob;
}
