import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../ss_button.dart';
import '../ss_strings.dart';

/// Situação do [SsCodeKeypad] (o estado "digitando" é só ter dígitos).
enum SsCodeStatus { idle, busy, error, success }

/// Botão extra do [SsCodeKeypad] ("Armar ausente", "Armar em casa"): recebe o
/// código digitado e devolve se deu certo (falso = erro, treme e limpa).
@immutable
class SsCodeAction {
  const SsCodeAction(this.label, this.onPressed, {this.icon, this.primary = false});
  final String label;
  final IconData? icon;
  final bool primary;
  final Future<bool> Function(String code) onPressed;
}

/// Teclado de código (PIN do alarme): bolinhas dos dígitos, teclado 3×4 e
/// apagar. Com [length], envia sozinho ao completar; sem ele, o botão
/// [submitLabel] envia (ou os botões de [actions]).
///
/// [onSubmit] devolve se o código valeu: enquanto espera, fica ocupado;
/// falso treme as bolinhas em vermelho e limpa; verdadeiro mostra o ✓.
/// [status] força a situação vinda de fora (ex.: o servidor ainda armando).
///
/// [onChanged] avisa cada dígito (e o apagar); com [controller], o código
/// pode ser lido e trocado de fora (`controller.clear()` limpa e, depois do
/// ✓, recomeça). Com
/// [actionsNeedCode] falso, os botões de [actions] valem com o código vazio
/// (ex.: "Desarmar" que não pede senha).
class SsCodeKeypad extends StatefulWidget {
  const SsCodeKeypad({
    super.key,
    this.onSubmit,
    this.length,
    this.maxLength = 8,
    this.obscure = true,
    this.actions = const [],
    this.status,
    this.initialCode = '',
    this.title,
    this.submitLabel,
    this.backspaceLabel,
    this.errorText,
    this.successText,
    this.digitsLabel,
    this.onChanged,
    this.controller,
    this.actionsNeedCode = true,
  });

  final Future<bool> Function(String code)? onSubmit;

  /// Tamanho fixo do código (envia ao completar). Nulo = livre até [maxLength].
  final int? length;
  final int maxLength;
  final bool obscure;
  final List<SsCodeAction> actions;
  final SsCodeStatus? status;
  final String initialCode;
  final String? title;
  final String? submitLabel, backspaceLabel, errorText, successText, digitsLabel;

  /// Código a cada mudança feita no teclado (dígito, apagar, limpar depois do erro).
  final ValueChanged<String>? onChanged;

  /// Guarda o código: ler (`controller.text`) e trocar de fora. Começa com
  /// [initialCode] quando vem vazio.
  final TextEditingController? controller;

  /// Falso: os botões de [actions] funcionam mesmo sem código digitado.
  final bool actionsNeedCode;

  @override
  State<SsCodeKeypad> createState() => _SsCodeKeypadState();
}

class _SsCodeKeypadState extends State<SsCodeKeypad> with SingleTickerProviderStateMixin {
  SsStrings get _s => SsStrings.of(context);
  late String _local = widget.initialCode;

  String get _code => widget.controller?.text ?? _local;
  set _code(String v) {
    if (v == _code) return;
    final ctl = widget.controller;
    if (ctl != null) {
      ctl.value = TextEditingValue(
        text: v,
        selection: TextSelection.collapsed(offset: v.length),
      );
    } else {
      _local = v;
    }
    widget.onChanged?.call(v);
  }

  // O controller mudou (de fora ou por nós): redesenha.
  void _ouve() {
    if (!mounted) return;
    setState(() {
      // controller.clear() depois do ✓ recomeça o teclado.
      if (widget.controller!.text.isEmpty && _status == SsCodeStatus.success) _status = SsCodeStatus.idle;
    });
  }

  @override
  void initState() {
    super.initState();
    final ctl = widget.controller;
    if (ctl != null) {
      if (ctl.text.isEmpty && widget.initialCode.isNotEmpty) ctl.text = widget.initialCode;
      ctl.addListener(_ouve);
    }
  }

  SsCodeStatus _status = SsCodeStatus.idle;
  late final _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
  final _focus = FocusNode();
  Timer? _limpa;

  SsCodeStatus get _st => widget.status ?? _status;
  int get _max => widget.length ?? widget.maxLength;
  bool get _travado => _st == SsCodeStatus.busy || _st == SsCodeStatus.success;

  @override
  void didUpdateWidget(SsCodeKeypad old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_ouve);
      widget.controller?.addListener(_ouve);
      if (old.controller != null && widget.controller == null) _local = old.controller!.text;
    }
    if (widget.status == SsCodeStatus.error && old.status != SsCodeStatus.error) _erro();
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_ouve);
    _limpa?.cancel();
    _shake.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _tecla(String d) {
    // Tocou numa tecla: o foco vem para o teclado (digitar e Enter passam a valer).
    if (!_focus.hasFocus) _focus.requestFocus();
    if (_travado || _code.length >= _max) return;
    SsHaptics.tick();
    setState(() {
      _code += d;
      if (_status == SsCodeStatus.error) _status = SsCodeStatus.idle;
    });
    if (widget.length != null && _code.length == widget.length) _enviar(widget.onSubmit);
  }

  void _apaga() {
    if (_travado || _code.isEmpty) return;
    SsHaptics.tick();
    setState(() => _code = _code.substring(0, _code.length - 1));
  }

  Future<void> _enviar(Future<bool> Function(String)? f, {bool allowEmpty = false}) async {
    if (f == null || (_code.isEmpty && !allowEmpty) || _travado) return;
    setState(() => _status = SsCodeStatus.busy);
    bool ok;
    try {
      ok = await f(_code);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    if (ok) {
      SsHaptics.success();
      setState(() => _status = SsCodeStatus.success);
    } else {
      _erro();
    }
  }

  void _erro() {
    SsHaptics.error();
    setState(() => _status = SsCodeStatus.error);
    if (!reduceMotion(context)) _shake.forward(from: 0);
    _limpa?.cancel();
    _limpa = Timer(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _code = '');
    });
  }

  KeyEventResult _key(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final ch = e.character;
    if (ch != null && RegExp(r'^\d$').hasMatch(ch)) {
      _tecla(ch);
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.backspace) {
      _apaga();
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _enviar(widget.onSubmit);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final st = _st;
    final dur = reduceMotion(context) ? Duration.zero : SsMotion.fast;
    final cor = switch (st) {
      SsCodeStatus.error => c.danger,
      SsCodeStatus.success => c.success,
      _ => c.accent,
    };
    final d = SsDensity.of(context);
    // Tecla: 48 / 56 / 60 (era 64 sempre).
    final alturaTecla = d.controlHeight + 8;
    // Bolinhas: tamanho fixo mostra todas; livre mostra 4 vazias ou o que tem.
    final total = widget.length ?? math.max(4, _code.length);

    final pontos = AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final t = _shake.value;
        final dx = math.sin(t * math.pi * 6) * 10 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Semantics(
        liveRegion: true,
        label: widget.digitsLabel ?? _s.codeDigits,
        value: switch (st) {
          SsCodeStatus.error => widget.errorText ?? _s.codeError,
          SsCodeStatus.success => widget.successText ?? _s.done,
          _ => '${_code.length}${widget.length != null ? ' / ${widget.length}' : ''}',
        },
        excludeSemantics: true,
        child: SizedBox(
          height: 28,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < total; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: _Ponto(
                    cheio: i < _code.length,
                    cor: cor,
                    vazio: c.muted2,
                    digito: widget.obscure || i >= _code.length ? null : _code[i],
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    final rodape = SizedBox(
      height: 22,
      child: AnimatedSwitcher(
        duration: dur,
        child: switch (st) {
          SsCodeStatus.busy => SizedBox.square(
            key: const ValueKey('busy'),
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: c.accent,
              value: reduceMotion(context) ? .3 : null,
            ),
          ),
          SsCodeStatus.error => Text(
            widget.errorText ?? _s.codeError,
            key: const ValueKey('erro'),
            style: TextStyle(color: c.dangerText, fontWeight: FontWeight.w700, fontSize: d.font(AppType.sub)),
          ),
          SsCodeStatus.success => Row(
            key: const ValueKey('ok'),
            mainAxisSize: MainAxisSize.min,
            children: [
              SsCheckMark(value: true, color: c.success, size: 18),
              const SizedBox(width: 6),
              Text(
                widget.successText ?? _s.done,
                style: TextStyle(color: c.successText, fontWeight: FontWeight.w700, fontSize: d.font(AppType.sub)),
              ),
            ],
          ),
          SsCodeStatus.idle => const SizedBox(key: ValueKey('nada')),
        },
      ),
    );

    Widget tecla(String k) {
      final apagar = k == '⌫';
      final vazio = k.isEmpty;
      if (vazio) return Expanded(child: SizedBox(height: alturaTecla));
      final ativo = !_travado && (apagar ? _code.isNotEmpty : _code.length < _max);
      return Expanded(
        child: Padding(
          padding: EdgeInsets.all(d.space(5)),
          child: Semantics(
            button: true,
            enabled: ativo,
            label: apagar ? widget.backspaceLabel ?? _s.codeBackspace : k,
            excludeSemantics: true,
            child: SsPressable(
              scale: .9,
              enabled: ativo,
              onTap: () => apagar ? _apaga() : _tecla(k),
              child: Container(
                height: alturaTecla,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: apagar ? Colors.transparent : c.field,
                  borderRadius: BorderRadius.circular(d.radiusField + 4),
                ),
                child: apagar
                    ? Icon(Icons.backspace_outlined, size: d.iconSize + 4, color: ativo ? c.ink2 : c.muted2)
                    : Text(
                        k,
                        style: AppTheme.number(context, size: d.font(24), color: _travado ? c.muted : c.ink),
                      ),
              ),
            ),
          ),
        ),
      );
    }

    final enviaPorBotao = widget.length == null && widget.actions.isEmpty && widget.onSubmit != null;
    return Focus(
      focusNode: _focus,
      autofocus: false,
      onKeyEvent: _key,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _focus.requestFocus,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.title != null) ...[
              Text(
                widget.title!,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.ink, fontWeight: FontWeight.w700, fontSize: d.font(AppType.md)),
              ),
              SizedBox(height: d.space(14)),
            ],
            pontos,
            SizedBox(height: d.space(8)),
            Center(child: rodape),
            SizedBox(height: d.space(10)),
            for (final linha in const [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
              ['', '0', '⌫'],
            ])
              Row(children: [for (final k in linha) tecla(k)]),
            if (enviaPorBotao) ...[
              SizedBox(height: d.gap),
              SsButton(
                label: widget.submitLabel ?? _s.confirm,
                icon: Icons.check_rounded,
                loading: st == SsCodeStatus.busy,
                onPressed: _code.isEmpty || _travado ? null : () => _enviar(widget.onSubmit),
              ),
            ],
            if (widget.actions.isNotEmpty) ...[
              SizedBox(height: d.gap),
              // Lado a lado quando cabe (≥ 180 por botão); senão, empilhados.
              LayoutBuilder(
                builder: (context, box) {
                  final botoes = [
                    for (final a in widget.actions)
                      SsButton(
                        label: a.label,
                        icon: a.icon,
                        variant: a.primary ? SsButtonVariant.primary : SsButtonVariant.ghost,
                        onPressed: (_code.isEmpty && widget.actionsNeedCode) || _travado
                            ? null
                            : () => _enviar(a.onPressed, allowEmpty: !widget.actionsNeedCode),
                      ),
                  ];
                  if (box.maxWidth / botoes.length >= 180) {
                    return Row(
                      spacing: d.space(10),
                      children: [for (final b in botoes) Expanded(child: b)],
                    );
                  }
                  return Column(spacing: d.space(8), crossAxisAlignment: CrossAxisAlignment.stretch, children: botoes);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Ponto extends StatelessWidget {
  const _Ponto({required this.cheio, required this.cor, required this.vazio, this.digito});
  final bool cheio;
  final Color cor, vazio;
  final String? digito;

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotion(context);
    if (digito != null) {
      return SizedBox(
        width: 18,
        child: Text(
          digito!,
          textAlign: TextAlign.center,
          style: AppTheme.number(context, size: 22, color: cor),
        ),
      );
    }
    return AnimatedScale(
      scale: cheio ? 1 : .72,
      duration: reduce ? Duration.zero : SsMotion.indicator,
      curve: SsMotion.pop,
      child: AnimatedContainer(
        duration: reduce ? Duration.zero : SsMotion.fast,
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cheio ? cor : Colors.transparent,
          border: Border.all(color: cheio ? cor : vazio, width: 2),
        ),
      ),
    );
  }
}
