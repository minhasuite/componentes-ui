import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'motion.dart';

/// Ajuste numérico "− valor +": o número (DM Mono) rola na direção da
/// mudança, segurar um botão repete cada vez mais rápido, o botão desabilita
/// no limite (com vibração de "bateu") e tocar no número abre para digitar.
/// Com [decimals] > 0 o valor vem como `double`; senão, como `int`.
class SsStepper extends StatefulWidget {
  const SsStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 9999,
    this.step = 1,
    this.decimals = 0,
    this.unit,
    this.label,
  });

  final num value;
  final ValueChanged<num> onChanged;
  final num min;
  final num max;
  final num step;
  final int decimals;

  /// Texto pequeno depois do número ("kg", "pessoas").
  final String? unit;

  /// Rótulo pequeno em maiúsculas em cima ("PESO (KG)").
  final String? label;

  /// Arredonda em [decimals] casas e prende entre [min] e [max].
  static num fit(num v, {num min = 0, num max = 9999, int decimals = 0}) {
    final r = double.parse(v.clamp(min, max).toStringAsFixed(decimals));
    return decimals == 0 ? r.round() : r;
  }

  /// "2", "2,5" (vírgula pt-BR, sempre com [decimals] casas).
  static String format(num v, int decimals) => v.toStringAsFixed(decimals).replaceAll('.', ',');

  @override
  State<SsStepper> createState() => _SsStepperState();
}

class _SsStepperState extends State<SsStepper> {
  int _dir = 1;
  Timer? _repeat;
  bool _editing = false;
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus && _editing) _commit();
    });
  }

  @override
  void dispose() {
    _repeat?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  num _fit(num v) => SsStepper.fit(v, min: widget.min, max: widget.max, decimals: widget.decimals);

  /// Um passo; falso quando já está no limite (para a repetição).
  bool _bump(int dir) {
    final next = _fit(widget.value + dir * widget.step);
    if (next == widget.value) return false;
    setState(() => _dir = dir);
    final limite = next == widget.min || next == widget.max;
    limite ? HapticFeedback.mediumImpact() : HapticFeedback.selectionClick();
    widget.onChanged(next);
    return !limite;
  }

  // Repete com intervalo que cai 20% a cada passo (de 350 ms até 50 ms).
  void _hold(int dir, [int ms = 350]) {
    _repeat = Timer(Duration(milliseconds: ms), () {
      if (mounted && _bump(dir)) _hold(dir, math.max(50, (ms * .8).round()));
    });
  }

  void _stop() {
    _repeat?.cancel();
    _repeat = null;
  }

  void _edit() {
    _ctrl.text = SsStepper.format(widget.value, widget.decimals);
    _ctrl.selection = TextSelection(baseOffset: 0, extentOffset: _ctrl.text.length);
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _commit() {
    final v = num.tryParse(_ctrl.text.trim().replaceAll(',', '.'));
    setState(() => _editing = false);
    if (v == null) return;
    final next = _fit(v);
    if (next != widget.value) {
      _dir = next > widget.value ? 1 : -1;
      widget.onChanged(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final text = SsStepper.format(widget.value, widget.decimals);
    final dur = reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 260);
    final numStyle = AppTheme.number(context, size: AppType.lg, color: c.ink);

    Widget valor;
    if (_editing) {
      valor = TextField(
        controller: _ctrl,
        focusNode: _focus,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.numberWithOptions(decimal: widget.decimals > 0),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(widget.decimals > 0 ? r'[0-9.,]' : r'[0-9]'))],
        onSubmitted: (_) => _focus.unfocus(),
        style: numStyle,
        decoration: const InputDecoration.collapsed(hintText: ''),
      );
    } else {
      final key = ValueKey(text);
      valor = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _edit,
        child: ClipRect(
          child: AnimatedSwitcher(
            duration: dur,
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) {
              // Entra de baixo e sai por cima quando sobe (o contrário quando desce).
              final entra = child.key == key;
              return SlideTransition(
                position: Tween(begin: Offset(0, (entra ? .7 : -.7) * _dir), end: Offset.zero).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              );
            },
            child: Row(
              key: key,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(text, style: numStyle),
                if (widget.unit != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    widget.unit!,
                    style: TextStyle(color: c.muted, fontSize: AppType.sub, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    String falado(num v) => '${SsStepper.format(v, widget.decimals)}${widget.unit == null ? '' : ' ${widget.unit}'}';
    final stepper = Semantics(
      label: widget.label,
      value: falado(widget.value),
      increasedValue: falado(_fit(widget.value + widget.step)),
      decreasedValue: falado(_fit(widget.value - widget.step)),
      onIncrease: widget.value < widget.max ? () => _bump(1) : null,
      onDecrease: widget.value > widget.min ? () => _bump(-1) : null,
      child: Container(
        height: 56,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(AppRadius.field)),
        child: Row(
          children: [
            _btn(c, Icons.remove_rounded, 'Diminuir', -1, widget.value > widget.min),
            Expanded(child: valor),
            _btn(c, Icons.add_rounded, 'Aumentar', 1, widget.value < widget.max),
          ],
        ),
      ),
    );
    if (widget.label == null) return stepper;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 5),
          child: ExcludeSemantics(
            child: Text(
              widget.label!.toUpperCase(),
              style: TextStyle(color: c.muted, fontSize: AppType.label, fontWeight: FontWeight.w700, letterSpacing: .4),
            ),
          ),
        ),
        stepper,
      ],
    );
  }

  Widget _btn(SsColors c, IconData icon, String label, int dir, bool on) => Semantics(
    button: true,
    enabled: on,
    label: label,
    excludeSemantics: true,
    child: GestureDetector(
      onTap: on ? () => _bump(dir) : null,
      onLongPressStart: on ? (_) => _hold(dir) : null,
      onLongPressEnd: (_) => _stop(),
      onLongPressCancel: _stop,
      child: SsPressable(
        enabled: on,
        scale: .9,
        child: AnimatedOpacity(
          opacity: on ? 1 : .4,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.stepperBtn),
              border: c.isDark ? Border.all(color: c.line) : null,
            ),
            child: Icon(icon, size: 22, color: c.ink2),
          ),
        ),
      ),
    ),
  );
}
