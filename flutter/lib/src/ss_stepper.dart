import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'motion.dart';
import 'ss_strings.dart';

/// Ajuste numérico "− valor +": o número (DM Mono) rola na direção da
/// mudança e assenta com mola, os botões afundam e voltam com mola, segurar um botão repete cada vez mais rápido, o botão desabilita
/// no limite (com vibração de "bateu") e tocar no número abre para digitar.
/// Com [decimals] > 0 o valor vem como `double`; senão, como `int`.
///
/// [onChanged] nulo desabilita: mostra só o valor, com os botões apagados.
/// Com [debounce], o número muda na hora a cada toque, mas [onChanged] só
/// recebe o valor final depois de [debounce] sem toque (um envio por rajada);
/// sair da tela antes disso ainda envia o pendente.
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
    this.decreaseLabel,
    this.increaseLabel,
    this.debounce,
  });

  final num value;

  /// Nulo desabilita (só mostra o valor).
  final ValueChanged<num>? onChanged;
  final num min;
  final num max;
  final num step;
  final int decimals;

  /// Texto pequeno depois do número ("kg", "pessoas").
  final String? unit;

  /// Rótulo pequeno em maiúsculas em cima ("PESO (KG)").
  final String? label;

  /// Leitor de tela do − e do +; padrão "Diminuir" e "Aumentar" de [SsStrings].
  final String? decreaseLabel;
  final String? increaseLabel;

  /// Espera sem toque antes de avisar [onChanged] (ex.: 600 ms para mandar
  /// à API uma vez só). Nulo avisa a cada passo.
  final Duration? debounce;

  /// Arredonda em [decimals] casas e prende entre [min] e [max].
  static num fit(num v, {num min = 0, num max = 9999, int decimals = 0}) {
    final r = double.parse(v.clamp(min, max).toStringAsFixed(decimals));
    return decimals == 0 ? r.round() : r;
  }

  /// "2", "2,5" (vírgula pt-BR, sempre com [decimals] casas).
  /// Sem [formats], com vírgula decimal.
  static String format(num v, int decimals, [SsFormats? formats]) =>
      v.toStringAsFixed(decimals).replaceAll('.', (formats ?? SsFormats.brl).decimalSeparator);

  @override
  State<SsStepper> createState() => _SsStepperState();
}

class _SsStepperState extends State<SsStepper> {
  int _dir = 1;
  Timer? _repeat;
  bool _editing = false;
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  // Valor mostrado que ainda não foi avisado (com debounce).
  num? _pending;
  Timer? _debounce;

  num get _value => _pending ?? widget.value;
  bool get _enabled => widget.onChanged != null;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus && _editing) _commit();
    });
  }

  @override
  void dispose() {
    // Saiu com valor pendente: avisa fora do desmonte (setState no pai aqui quebra).
    final pendente = _pending;
    final cb = widget.onChanged;
    _debounce?.cancel();
    if (pendente != null && cb != null) scheduleMicrotask(() => cb(pendente));
    _repeat?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _report(num next) {
    final cb = widget.onChanged;
    if (cb == null) return;
    final d = widget.debounce;
    if (d == null) {
      cb(next);
      return;
    }
    setState(() => _pending = next);
    _debounce?.cancel();
    _debounce = Timer(d, _flush);
  }

  void _flush() {
    final v = _pending;
    if (v == null || !mounted) return;
    _pending = null;
    widget.onChanged?.call(v);
    // Se o pai não guardar o valor, o número volta para o dele.
    setState(() {});
  }

  num _fit(num v) => SsStepper.fit(v, min: widget.min, max: widget.max, decimals: widget.decimals);

  /// Um passo; falso quando já está no limite (para a repetição).
  bool _bump(int dir) {
    if (!_enabled) return false;
    final next = _fit(_value + dir * widget.step);
    if (next == _value) return false;
    setState(() => _dir = dir);
    final limite = next == widget.min || next == widget.max;
    limite ? HapticFeedback.mediumImpact() : HapticFeedback.selectionClick();
    _report(next);
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
    if (!_enabled) return;
    _ctrl.text = SsStepper.format(_value, widget.decimals, SsFormats.of(context));
    _ctrl.selection = TextSelection(baseOffset: 0, extentOffset: _ctrl.text.length);
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _commit() {
    final v = num.tryParse(_ctrl.text.trim().replaceAll(',', '.'));
    setState(() => _editing = false);
    if (v == null) return;
    final next = _fit(v);
    if (next != _value) {
      _dir = next > _value ? 1 : -1;
      _report(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final f = SsFormats.of(context);
    final value = _value;
    final on = _enabled;
    final text = SsStepper.format(value, widget.decimals, f);
    final dur = reduceMotion(context) ? Duration.zero : SsMotion.slow;
    final numStyle = AppTheme.number(context, size: AppType.lg, color: on ? c.ink : c.ink2);

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
        onTap: on ? _edit : null,
        child: ClipRect(
          child: AnimatedSwitcher(
            duration: dur,
            // O número novo chega com a mola (passa um tiquinho e assenta).
            switchInCurve: SsMotion.bounce,
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

    String falado(num v) => '${SsStepper.format(v, widget.decimals, f)}${widget.unit == null ? '' : ' ${widget.unit}'}';
    final s = SsStrings.of(context);
    final stepper = Semantics(
      label: widget.label,
      enabled: on,
      value: falado(value),
      increasedValue: on ? falado(_fit(value + widget.step)) : null,
      decreasedValue: on ? falado(_fit(value - widget.step)) : null,
      onIncrease: on && value < widget.max ? () => _bump(1) : null,
      onDecrease: on && value > widget.min ? () => _bump(-1) : null,
      child: Container(
        height: 56,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(AppRadius.field)),
        child: Row(
          children: [
            // Desabilitado: os botões ficam (o tamanho não pula), mas bem apagados.
            _btn(c, Icons.remove_rounded, widget.decreaseLabel ?? s.decrease, -1, on && value > widget.min, on),
            Expanded(child: valor),
            _btn(c, Icons.add_rounded, widget.increaseLabel ?? s.increase, 1, on && value < widget.max, on),
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

  Widget _btn(SsColors c, IconData icon, String label, int dir, bool on, bool enabled) => Semantics(
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
          opacity: on ? 1 : (enabled ? .4 : .2),
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
