import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'density.dart';
import 'format.dart';
import 'motion.dart';
import 'ss_button.dart';
import 'ss_controls.dart';
import 'ss_list.dart';
import 'ss_picker.dart';
import 'ss_sheet.dart';
import 'ss_stat.dart';
import 'ss_strings.dart';
import 'v15/amount.dart';

/// Validadores prontos para os campos `Ss*`. As mensagens saem em português;
/// para outro idioma, passe [SsStrings] (ex.:
/// `validator: (v) => SsValidators.required(v, SsStrings.of(context))`).
abstract final class SsValidators {
  /// Vazio (nulo ou texto em branco) → "Campo obrigatório". Serve para texto e escolha.
  static String? required(Object? v, [SsStrings? strings]) =>
      v == null || (v is String && v.trim().isEmpty) ? (strings ?? SsStrings.pt).requiredField : null;

  /// Para o [SsMoneyField]: precisa de valor maior que zero.
  static String? money(int? cents, [SsStrings? strings]) =>
      cents == null || cents <= 0 ? (strings ?? SsStrings.pt).enterAmount : null;

  /// Número inteiro entre [min] e [max] (inclusive).
  static FormFieldValidator<String> intRange(int min, int max, [SsStrings? strings]) => (v) {
    final s = strings ?? SsStrings.pt;
    final n = int.tryParse(v?.trim() ?? '');
    if (n == null) return s.enterNumber;
    return n < min || n > max ? s.numberRange(min, max) : null;
  };
}

/// Rótulo acima dos campos `Ss*` (o mesmo de [SsTextField]). Público para o
/// campo próprio do produto ficar igual aos do pacote.
///
/// v0.14.1: [icon] opcional antes do texto, na cor apagada (o `<svg>` dentro
/// do `.ss-label` do web), para o rótulo de um recurso (brilho, modo, nível).
class SsFieldLabel extends StatelessWidget {
  const SsFieldLabel(this.text, {super.key, this.icon});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final label = Text(
      text,
      style: TextStyle(color: c.ink2, fontSize: d.font(AppType.sub), fontWeight: FontWeight.w700),
    );
    return Padding(
      padding: EdgeInsets.only(left: 2, bottom: d.space(6)),
      child: icon == null
          ? label
          : Row(
              children: [
                Icon(icon, size: d.font(16), color: c.muted),
                SizedBox(width: d.space(6)),
                Flexible(child: label),
              ],
            ),
    );
  }
}

/// Dica fixa embaixo do campo (o `helperText` dos campos `Ss*`): texto
/// apagado, até 3 linhas. Os campos a escondem enquanto há erro.
class SsFieldHelper extends StatelessWidget {
  const SsFieldHelper(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: SsDensity.of(context).space(6), left: 2),
    child: Text(
      text,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: SsColors.of(context).muted, fontSize: AppType.meta),
    ),
  );
}

/// Mensagem de erro embaixo do campo: ícone + texto (a cor nunca vai sozinha).
class _ErrorLine extends StatelessWidget {
  const _ErrorLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final cor = SsColors.of(context).dangerText;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 6, left: 2),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, size: 16, color: cor),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: cor, fontSize: AppType.meta, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Campo de texto do design system: rótulo acima, fundo de campo e, no foco,
/// anel e halo da marca (como o [SsSearchField]). Valida ao sair do campo e,
/// depois do 1º erro, a cada digitação; a mensagem vem embaixo com ícone e o
/// campo dá uma sacudida curta quando o `Form.validate()` acha erro nele.
/// É um [TextFormField] por dentro: funciona dentro de [Form].
class SsTextField extends StatefulWidget {
  const SsTextField({
    super.key,
    this.label,
    this.controller,
    this.initialValue,
    this.hint,
    this.icon,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.helperText,
    this.enabled = true,
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
    this.style,
    this.prefixText,
    this.suffix,
    this.suffixText,
    this.textCapitalization = TextCapitalization.none,
    this.maxLength,
    this.autofillHints,
    this.focusNode,
    this.autocorrect = true,
    this.enableSuggestions = true,
  });

  final String? label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hint;
  final IconData? icon;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final int? maxLines;

  /// Altura mínima em linhas (observação que já abre com 3 linhas).
  final int? minLines;

  /// Dica fixa embaixo do campo (some enquanto há erro).
  final String? helperText;
  final bool enabled;
  final bool autofocus;
  final bool readOnly;
  final VoidCallback? onTap;

  /// Estilo do texto digitado (ex.: DM Mono no dinheiro).
  final TextStyle? style;
  final String? prefixText;

  /// Fim do campo (ex.: botão de mostrar senha).
  final Widget? suffix;

  /// Unidade depois do valor ("kg", "cm").
  final String? suffixText;

  /// `sentences` em nome e título.
  final TextCapitalization textCapitalization;

  /// Limite de caracteres (sem contador embaixo).
  final int? maxLength;

  /// Autopreenchimento do sistema (`AutofillHints.email`, `.password`).
  final Iterable<String>? autofillHints;

  /// Foco de fora (pular para o próximo campo); sem ele, o campo cria o seu.
  final FocusNode? focusNode;

  /// Correção automática do teclado. Falso em código, usuário, endereço,
  /// nome de dispositivo (o teclado não "conserta" o que foi digitado).
  final bool autocorrect;

  /// Sugestões do teclado acima das teclas (falso junto com [autocorrect]).
  final bool enableSuggestions;

  @override
  State<SsTextField> createState() => _SsTextFieldState();
}

class _SsTextFieldState extends State<SsTextField> with SingleTickerProviderStateMixin {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  final _field = GlobalKey<FormFieldState<String>>();
  late final _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  var _mode = AutovalidateMode.disabled;
  var _hasError = false;
  var _blur = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      setState(() {});
      if (!_focus.hasFocus && widget.validator != null) {
        _blur = true;
        _field.currentState?.validate();
        _blur = false;
      }
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focus.dispose();
    _shake.dispose();
    super.dispose();
  }

  String? _validate(String? v) {
    final r = widget.validator?.call(v);
    final had = _hasError;
    _hasError = r != null;
    if (had != _hasError || (_hasError && _mode != AutovalidateMode.always)) {
      // Pode vir de dentro do build do campo: muda o estado no quadro seguinte.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _hasError ? _mode = AutovalidateMode.always : null);
      });
    }
    // Sacode só no envio do Form (fora do build e fora da saída do campo).
    final noBuild = SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks;
    if (r != null && !_blur && !noBuild && !reduceMotion(context)) _shake.forward(from: 0);
    return r;
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final on = _focus.hasFocus;
    OutlineInputBorder borda(Color cor) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(d.radiusField),
      borderSide: BorderSide(color: cor, width: 2),
    );
    final campo = TextFormField(
      key: _field,
      controller: widget.controller,
      initialValue: widget.controller == null ? widget.initialValue : null,
      focusNode: _focus,
      autovalidateMode: _mode,
      validator: widget.validator == null ? null : _validate,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: [
        ...?widget.inputFormatters,
        if (widget.maxLength != null) LengthLimitingTextInputFormatter(widget.maxLength),
      ],
      textCapitalization: widget.textCapitalization,
      autofillHints: widget.autofillHints,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      obscureText: widget.obscureText,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.obscureText ? null : widget.minLines,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      style: widget.style ?? TextStyle(color: c.ink, fontSize: d.font(AppType.body), fontWeight: FontWeight.w600),
      errorBuilder: (_, msg) => _ErrorLine(msg),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(color: c.muted, fontSize: d.font(AppType.body), fontWeight: FontWeight.w500),
        helperText: widget.helperText,
        helperMaxLines: 3,
        helperStyle: TextStyle(color: c.muted, fontSize: AppType.meta),
        prefixIcon: widget.icon == null
            ? null
            : Icon(widget.icon, size: d.iconSize + 1, color: on ? c.accent : c.muted),
        prefixText: widget.prefixText,
        prefixStyle:
            widget.style ?? TextStyle(color: c.muted, fontSize: d.font(AppType.body), fontWeight: FontWeight.w600),
        suffixIcon: widget.suffix,
        suffixText: widget.suffixText,
        suffixStyle: TextStyle(color: c.muted, fontSize: d.font(AppType.sub), fontWeight: FontWeight.w600),
        filled: true,
        fillColor: on ? c.surface : c.field,
        // Padrão 14/14 (52 de altura); a densidade muda a altura pela folga vertical.
        contentPadding: EdgeInsets.symmetric(horizontal: d.padX - 2, vertical: (d.fieldHeight - 24) / 2),
        isDense: d.isCompact,
        enabledBorder: borda(Colors.transparent),
        disabledBorder: borda(Colors.transparent),
        focusedBorder: borda(c.accent.withValues(alpha: .45)),
        errorBorder: borda(c.danger.withValues(alpha: .55)),
        focusedErrorBorder: borda(c.danger),
      ),
    );
    final dur = reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 180);
    // Compacto: a caixa desenha 44 e o toque continua com 48 (por fora de tudo).
    return SsTapTarget(
      minSize: Size(0, d.minTarget),
      child: AnimatedBuilder(
        animation: _shake,
        builder: (_, child) {
          final t = _shake.value;
          return Transform.translate(offset: Offset(math.sin(t * math.pi * 6) * 8 * (1 - t), 0), child: child);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.label != null) SsFieldLabel(widget.label!),
            // O halo só sem erro: com erro, a caixa ganharia a altura da mensagem.
            AnimatedContainer(
              duration: dur,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(d.radiusField),
                boxShadow: on && !_hasError
                    ? [BoxShadow(color: c.accent.withValues(alpha: .12), spreadRadius: 4)]
                    : const [],
              ),
              child: campo,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dinheiro em centavos: digita só números e o valor cresce da direita
/// (0,00 → 0,05 → 0,50 → 5,00), em DM Mono com "R$" na frente. Moeda e
/// separadores vêm de [SsFormats.of] (padrão: real) ou de [formats] (v0.15: a
/// moeda da conta, "US$").
/// [keypad] troca o teclado do sistema pelo [showSsAmountKeypad].
///
/// v0.15 (o mesmo do `Ss::MoneyInputComponent(signed:, expression:)` do web):
/// - [signed]: aceita negativo (saldo inicial): "-" na frente, tecla ± no
///   teclado. Sem ele, o sinal não entra;
/// - [expression]: aceita conta ("45+12,50", "3×19,90"): o campo fica livre,
///   embaixo aparece "= R$ 57,50", [onChanged] recebe o resultado (nulo se a
///   conta não fecha, que também é erro de validação) e, ao sair do campo, o
///   texto vira o valor. O teclado ([keypad]) ganha + − × ÷ e vírgula.
class SsMoneyField extends StatefulWidget {
  const SsMoneyField({
    super.key,
    this.label,
    required this.cents,
    required this.onChanged,
    this.validator,
    this.hint,
    this.keypad = false,
    this.enabled = true,
    this.formats,
    this.signed = false,
    this.expression = false,
  });

  final String? label;
  final int? cents;
  final ValueChanged<int?> onChanged;

  /// Recebe os centavos (ex.: [SsValidators.money]).
  final String? Function(int? cents)? validator;

  /// Padrão: zero no formato da moeda ("0,00").
  final String? hint;
  final bool keypad;
  final bool enabled;

  /// Moeda e separadores do campo; nulo = [SsFormats.of].
  final SsFormats? formats;
  final bool signed;
  final bool expression;

  @override
  State<SsMoneyField> createState() => _SsMoneyFieldState();
}

String _semRs(int? cents, SsFormats f) => cents == null ? '' : f.amount(cents);

int? _comSinal(String text, SsFormats f) {
  final v = parseMoney(text, f);
  if (v == null) return null;
  return text.trimLeft().startsWith(RegExp('[-−]')) ? -v : v;
}

/// Só dígitos; os 2 últimos são centavos. Até 11 dígitos (R$ 999.999.999,99).
/// Com [signed], o "-" na frente fica (e digitar "-" em qualquer lugar troca o sinal).
class _CentavosFormatter extends TextInputFormatter {
  _CentavosFormatter(this.f, {this.signed = false});
  final SsFormats f;
  final bool signed;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue value) {
    final d = value.text.replaceAll(RegExp(r'\D'), '');
    if (d.length > 11) return old;
    final eraNeg = old.text.startsWith('-');
    final menos = '-'.allMatches(value.text).length;
    final neg = signed && (eraNeg ? menos == 1 : menos >= 1);
    final t = d.isEmpty ? (neg ? '-' : '') : '${neg ? '-' : ''}${_semRs(int.parse(d), f)}';
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

class _SsMoneyFieldState extends State<SsMoneyField> {
  SsFormats get _f => widget.formats ?? SsFormats.of(context);
  late final _ctrl = TextEditingController(text: _semRs(widget.cents, _f));
  final _focus = FocusNode();
  // Modo conta: o resultado da última digitação (nulo = não fecha).
  int? _conta;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_saiu);
  }

  @override
  void didUpdateWidget(SsMoneyField old) {
    super.didUpdateWidget(old);
    final atual = widget.expression ? ssEvalAmount(_ctrl.text, _f) : _comSinal(_ctrl.text, _f);
    if (widget.cents != atual) _ctrl.text = _semRs(widget.cents, _f);
  }

  @override
  void dispose() {
    _focus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  bool _vale(int? v) => v != null && (widget.signed || v >= 0);

  void _saiu() {
    if (_focus.hasFocus || !widget.expression) return;
    final v = ssEvalAmount(_ctrl.text, _f);
    if (_vale(v) && ssIsAmountExpression(_ctrl.text)) setState(() => _ctrl.text = _semRs(v, _f));
  }

  void _digitouConta(String s) {
    final v = s.trim().isEmpty ? null : ssEvalAmount(s, _f);
    setState(() => _conta = v);
    widget.onChanged(_vale(v) ? v : null);
  }

  Future<void> _abrir() async {
    final v = await showSsAmountKeypad(
      context,
      initial: widget.cents,
      title: widget.label,
      expression: widget.expression,
      signed: widget.signed,
      formats: widget.formats,
    );
    if (v == null || !mounted) return;
    setState(() {
      _ctrl.text = _semRs(v, _f);
      _conta = v;
    });
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final f = _f;
    final s = SsStrings.of(context);
    final prefixo = f.symbolAfter ? null : f.prefix;
    final sufixo = f.symbolAfter ? f.suffix : null;
    final estilo = AppTheme.number(context, size: AppType.md, color: c.ink);
    if (widget.expression) {
      final mostra = _conta != null && _vale(_conta) && ssIsAmountExpression(_ctrl.text);
      return SsTextField(
        label: widget.label,
        controller: _ctrl,
        focusNode: _focus,
        hint: widget.hint ?? f.amount(0),
        prefixText: prefixo,
        suffixText: sufixo,
        enabled: widget.enabled,
        readOnly: widget.keypad,
        onTap: widget.keypad ? _abrir : null,
        keyboardType: TextInputType.numberWithOptions(decimal: true, signed: widget.signed),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,+\-*/×÷−() ]'))],
        style: estilo,
        helperText: mostra ? '= ${f.money(_conta)}' : null,
        suffix: widget.keypad
            ? null
            : IconButton(
                tooltip: s.calculator,
                icon: Icon(Icons.calculate_outlined, color: c.muted),
                onPressed: widget.enabled ? _abrir : null,
              ),
        validator: (t) {
          final txt = t ?? '';
          final v = txt.trim().isEmpty ? null : ssEvalAmount(txt, f);
          if (txt.trim().isNotEmpty && !_vale(v)) return s.invalidAmount;
          return widget.validator?.call(v);
        },
        onChanged: _digitouConta,
      );
    }
    return SsTextField(
      label: widget.label,
      controller: _ctrl,
      focusNode: _focus,
      hint: widget.hint ?? f.amount(0),
      prefixText: prefixo,
      suffixText: sufixo,
      enabled: widget.enabled,
      readOnly: widget.keypad,
      onTap: widget.keypad ? _abrir : null,
      keyboardType: TextInputType.numberWithOptions(signed: widget.signed),
      inputFormatters: [_CentavosFormatter(f, signed: widget.signed)],
      style: estilo,
      validator: widget.validator == null ? null : (t) => widget.validator!(_comSinal(t ?? '', f)),
      onChanged: (t) => widget.onChanged(_comSinal(t, f)),
    );
  }
}

/// Abre a folha com o valor grande (DM Mono) e um teclado 3×4 próprio
/// (1–9, 00, 0, ⌫; segurar ⌫ zera). Devolve os centavos, ou nulo se fechar.
/// v0.15: [expression] troca pelo teclado 4×4 com + − × ÷ e vírgula (mostra
/// "= R$ 57,50" enquanto a conta fecha; devolve o resultado); [signed] põe a
/// tecla ± (no modo conta, o "−" no começo já vale); [formats] é a moeda.
Future<int?> showSsAmountKeypad(
  BuildContext context, {
  int? initial,
  String? title,
  bool expression = false,
  bool signed = false,
  SsFormats? formats,
}) => showSsSheet<int>(
  context,
  title: title ?? SsStrings.of(context).amount,
  child: SsAmountKeypad(initial: initial, expression: expression, signed: signed, formats: formats),
);

/// O corpo do [showSsAmountKeypad]. Sem [onConfirm], fecha a rota com o valor.
class SsAmountKeypad extends StatefulWidget {
  const SsAmountKeypad({
    super.key,
    this.initial,
    this.onConfirm,
    this.expression = false,
    this.signed = false,
    this.formats,
  });

  final int? initial;
  final ValueChanged<int>? onConfirm;
  final bool expression;
  final bool signed;
  final SsFormats? formats;

  @override
  State<SsAmountKeypad> createState() => _SsAmountKeypadState();
}

class _SsAmountKeypadState extends State<SsAmountKeypad> {
  late int _c = widget.initial ?? 0;
  // Modo conta: o texto digitado ("45+12,5").
  late String _t = widget.initial == null || widget.initial == 0 ? '' : _semRs(widget.initial, _f);

  SsFormats get _f => widget.formats ?? SsFormats.of(context);

  static const _apaga = '⌫';

  void _tecla(String k) => setState(() {
    SsHaptics.tick();
    if (widget.expression) {
      if (k == _apaga) {
        if (_t.isNotEmpty) _t = _t.substring(0, _t.length - 1);
      } else {
        _t += k;
      }
      return;
    }
    if (k == _apaga) {
      _c ~/= 10;
    } else if (k == '±') {
      _c = -_c;
    } else if (_c.abs() < 1000000000) {
      final d = k == '00' ? 100 : 10;
      final soma = k == '00' ? 0 : int.parse(k);
      _c = _c < 0 ? _c * d - soma : _c * d + soma;
    }
  });

  void _limpa() => setState(() => widget.expression ? _t = '' : _c = 0);

  void _ok(int v) => widget.onConfirm != null ? widget.onConfirm!(v) : Navigator.pop(context, v);

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    final f = _f;
    final operador = RegExp(r'^[÷×−+±]$');
    Widget tecla(String k) => Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Semantics(
          button: true,
          label: k == _apaga ? s.backspaceHold : (k == '±' ? s.toggleSign : k),
          excludeSemantics: true,
          child: GestureDetector(
            onLongPress: k == _apaga ? _limpa : null,
            child: SsPressable(
              scale: .9,
              onTap: () => _tecla(k),
              child: Container(
                height: d.target(d.fieldHeight + 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(d.radiusField)),
                child: k == _apaga
                    ? Icon(Icons.backspace_outlined, color: c.ink2)
                    : Text(
                        k,
                        style: AppTheme.number(context, size: 22, color: operador.hasMatch(k) ? c.accentText : c.ink),
                      ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.expression) {
      final v = _t.isEmpty ? null : ssEvalAmount(_t, f);
      final vale = v != null && (widget.signed || v >= 0);
      final conta = ssIsAmountExpression(_t);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            child: Align(
              alignment: Alignment.centerRight,
              child: SsAmount('${f.prefix}${_t.isEmpty ? '0' : _t}${f.suffix}', size: 30),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            vale && conta
                ? '= ${f.money(v)}'
                : (_t.isNotEmpty && !vale && !RegExp(r'[-+*/×÷−(]$').hasMatch(_t) ? s.invalidAmount : ' '),
            textAlign: TextAlign.right,
            style: TextStyle(color: vale ? c.muted : c.dangerText),
          ),
          const SizedBox(height: 8),
          for (final linha in [
            const ['7', '8', '9', '÷'],
            const ['4', '5', '6', '×'],
            const ['1', '2', '3', '−'],
            [f.decimalSeparator, '0', _apaga, '+'],
          ])
            Row(children: [for (final k in linha) tecla(k)]),
          const SizedBox(height: 12),
          SsButton(label: s.confirm, icon: Icons.check_rounded, onPressed: vale ? () => _ok(v) : null),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(liveRegion: true, child: Center(child: SsAmount(money(_c, f), size: 44))),
        const SizedBox(height: 14),
        for (final linha in [
          const ['1', '2', '3'],
          const ['4', '5', '6'],
          const ['7', '8', '9'],
          [widget.signed ? '±' : '00', '0', _apaga],
        ])
          Row(children: [for (final k in linha) tecla(k)]),
        const SizedBox(height: 12),
        SsButton(label: s.confirm, icon: Icons.check_rounded, onPressed: () => _ok(_c)),
      ],
    );
  }
}

/// Data por atalhos em chips: "Hoje", "Amanhã" e o próximo dia útil (Sex, ou
/// Seg quando amanhã já é sexta ou fim de semana); o calendário só abre em
/// "Outra…" (que passa a mostrar a data escolhida). [clearable] põe um ✕.
/// [initialDate] é onde o calendário abre sem valor (ex.: nascimento);
/// [showShortcuts] falso deixa só o chip do calendário. Com [validator], vale
/// dentro de [Form] e mostra o erro embaixo.
class SsDateField extends StatelessWidget {
  const SsDateField({
    super.key,
    this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.clearable = false,
    this.initialDate,
    this.validator,
    this.showShortcuts = true,
    this.helperText,
  }) : _hora = false;

  const SsDateField._hora({
    super.key,
    this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.clearable = false,
    this.initialDate,
    this.validator,
    this.showShortcuts = true,
    this.helperText,
  }) : _hora = true;

  final String? label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool clearable;
  final DateTime? initialDate;
  final String? Function(DateTime? value)? validator;
  final bool showShortcuts;

  /// Dica fixa embaixo dos chips (some enquanto há erro).
  final String? helperText;
  final bool _hora;

  /// Os 3 atalhos a partir de [today]: (rótulo, dia). Sem [strings], em
  /// português.
  static List<(String, DateTime)> shortcuts(DateTime today, [SsStrings? strings]) {
    final s = strings ?? SsStrings.pt;
    final d = DateUtils.dateOnly(today);
    final amanha = DateTime(d.year, d.month, d.day + 1);
    final sexta = amanha.weekday < DateTime.friday;
    final util = DateTime(
      amanha.year,
      amanha.month,
      amanha.day + (sexta ? DateTime.friday - amanha.weekday : 8 - amanha.weekday),
    );
    return [
      (s.today, d),
      (s.tomorrow, amanha),
      ('${s.weekdaysShort[util.weekday - 1]} ${s.formatDayMonth(util)}', util),
    ];
  }

  bool _noIntervalo(DateTime d) =>
      (firstDate == null || !d.isBefore(DateUtils.dateOnly(firstDate!))) &&
      (lastDate == null || !d.isAfter(DateUtils.dateOnly(lastDate!)));

  DateTime _comHora(DateTime d) => _hora ? DateTime(d.year, d.month, d.day, value?.hour ?? 9, value?.minute ?? 0) : d;

  Future<void> _outra(BuildContext context) async {
    final hoje = DateUtils.dateOnly(DateTime.now());
    final first = firstDate ?? DateTime(2000);
    final last = lastDate ?? DateTime(2100);
    var inicial = value ?? initialDate ?? hoje;
    if (inicial.isBefore(first)) inicial = first;
    if (inicial.isAfter(last)) inicial = last;
    final d = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: first,
      lastDate: last,
      locale: SsStrings.of(context).locale,
    );
    if (d != null) onChanged(_comHora(d));
  }

  Future<void> _horario(BuildContext context) async {
    final t = await showTimePicker(
      context: context,
      initialTime: value == null ? const TimeOfDay(hour: 9, minute: 0) : TimeOfDay.fromDateTime(value!),
    );
    if (t == null) return;
    final d = value ?? DateTime.now();
    onChanged(DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    final atalhos = showShortcuts
        ? shortcuts(DateTime.now(), s).where((a) => _noIntervalo(a.$2)).toList()
        : <(String, DateTime)>[];
    final v = value;
    final outra = v != null && !atalhos.any((a) => DateUtils.isSameDay(a.$2, v));
    final rotulo = showShortcuts ? s.otherDate : s.pickDate;
    final campo = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) SsFieldLabel(label!),
        Wrap(
          spacing: d.gap - 4,
          runSpacing: d.gap - 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final (nome, dia) in atalhos)
              SsFilterChip(
                nome,
                selected: v != null && DateUtils.isSameDay(dia, v),
                onTap: () => onChanged(_comHora(dia)),
              ),
            SsFilterChip(outra ? s.formatDate(v) : rotulo, selected: outra, onTap: () => _outra(context)),
            if (_hora)
              SsFilterChip(
                v == null ? s.time : '${two(v.hour)}:${two(v.minute)}',
                selected: v != null,
                onTap: () => _horario(context),
              ),
            if (clearable && v != null)
              IconButton(
                tooltip: s.clearDate,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close_rounded, size: 20, color: c.muted),
                onPressed: () => onChanged(null),
              ),
          ],
        ),
      ],
    );
    final dica = helperText;
    if (validator == null) {
      if (dica == null) return campo;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [campo, SsFieldHelper(dica)],
      );
    }
    return FormField<DateTime>(
      validator: (_) => validator!(value),
      builder: (f) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [campo, if (f.errorText != null) _ErrorLine(f.errorText!) else if (dica != null) SsFieldHelper(dica)],
      ),
    );
  }
}

/// [SsDateField] com um chip de hora a mais (abre o `showTimePicker`).
/// Trocar o dia mantém a hora (9:00 quando ainda não há).
class SsDateTimeField extends SsDateField {
  const SsDateTimeField({
    super.key,
    super.label,
    required super.value,
    required super.onChanged,
    super.firstDate,
    super.lastDate,
    super.clearable,
    super.initialDate,
    super.validator,
    super.showShortcuts,
    super.helperText,
  }) : super._hora();
}

/// Escolha de uma opção (no lugar do DropdownButtonFormField): o campo mostra
/// a escolhida e o toque abre uma folha com as [options] (a marcada com ✓;
/// com mais de 8, busca sem acento). É um [FormField]: [validator] funciona
/// dentro de [Form] (ex.: `SsValidators.required`).
class SsChoiceField<T> extends StatelessWidget {
  const SsChoiceField({
    super.key,
    this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hint,
    this.icon,
    this.validator,
    this.enabled = true,
    this.helperText,
  });

  final String? label;
  final T? value;

  /// Valor → texto, na ordem em que aparecem.
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  /// Padrão: [SsStrings.choose].
  final String? hint;
  final IconData? icon;
  final FormFieldValidator<T>? validator;
  final bool enabled;

  /// Dica fixa embaixo do campo (some enquanto há erro).
  final String? helperText;

  Future<void> _abrir(BuildContext context, FormFieldState<T> field) async {
    final r = await showSsSheet<(T,)>(
      context,
      title: label ?? hint ?? SsStrings.of(context).choose,
      child: SsChoiceList<T>(options: options, selected: value),
    );
    if (r == null) return;
    field.didChange(r.$1);
    onChanged(r.$1);
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final hint = this.hint ?? SsStrings.of(context).choose;
    // Chave pelo valor: o estado do campo acompanha o valor que vem de fora.
    return FormField<T>(
      key: ValueKey(value),
      initialValue: value,
      validator: validator,
      builder: (field) {
        final texto = options[value];
        final erro = field.errorText;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (label != null) SsFieldLabel(label!),
            SsTapTarget(
              minSize: Size(0, d.minTarget),
              child: Semantics(
                button: true,
                enabled: enabled,
                label: label,
                value: texto ?? hint,
                excludeSemantics: true,
                child: SsPressable(
                  enabled: enabled,
                  onTap: enabled ? () => _abrir(context, field) : null,
                  child: Container(
                    height: d.fieldHeight,
                    padding: EdgeInsets.symmetric(horizontal: d.padX - 2),
                    decoration: BoxDecoration(
                      color: c.field,
                      borderRadius: BorderRadius.circular(d.radiusField),
                      border: Border.all(
                        color: erro != null ? c.danger.withValues(alpha: .55) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: d.iconSize + 1, color: c.muted),
                          SizedBox(width: d.gap - 2),
                        ],
                        Expanded(
                          child: Text(
                            texto ?? hint,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: texto == null ? c.muted : (enabled ? c.ink : c.muted),
                              fontSize: d.font(AppType.body),
                              fontWeight: texto == null ? FontWeight.w500 : FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(Icons.unfold_more_rounded, size: d.iconSize, color: c.muted),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (erro != null) _ErrorLine(erro) else if (helperText != null) SsFieldHelper(helperText!),
          ],
        );
      },
    );
  }
}

/// A lista da folha do [SsChoiceField]: a opção marcada tem ✓ (que se desenha
/// com um pulinho ao trocar); com mais de 8,
/// aparece a busca. Sem [onSelect], fecha a rota com `(valor,)`.
class SsChoiceList<T> extends StatefulWidget {
  const SsChoiceList({super.key, required this.options, this.selected, this.onSelect});

  final Map<T, String> options;
  final T? selected;
  final ValueChanged<T>? onSelect;

  @override
  State<SsChoiceList<T>> createState() => _SsChoiceListState<T>();
}

class _SsChoiceListState<T> extends State<SsChoiceList<T>> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final q = foldAccents(_q.trim());
    final itens = widget.options.entries.where((e) => q.isEmpty || foldAccents(e.value).contains(q)).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.options.length > 8) ...[
          SsSearchField(onChanged: (v) => setState(() => _q = v)),
          const SizedBox(height: 8),
        ],
        if (itens.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              SsStrings.of(context).nothingFound,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.muted),
            ),
          ),
        for (final e in itens)
          Semantics(
            button: true,
            selected: e.key == widget.selected,
            child: InkWell(
              borderRadius: BorderRadius.circular(d.radiusField),
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onSelect != null ? widget.onSelect!(e.key) : Navigator.pop(context, (e.key,));
              },
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: d.minTarget),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: d.rowPadV + 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.value,
                          style: TextStyle(
                            color: e.key == widget.selected ? c.accentText : c.ink,
                            fontSize: d.font(AppType.body),
                            fontWeight: e.key == widget.selected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),
                      // O ✓ se desenha na opção escolhida (e some da anterior).
                      SsPop(
                        active: e.key == widget.selected,
                        child: SsCheckMark(value: e.key == widget.selected, size: 22, strokeWidth: 2.6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Linha com título, subtítulo e um [SsSwitch] na cor da marca; tocar em
/// qualquer lugar da linha alterna. [onChanged] nulo desabilita.
class SsSwitchRow extends StatelessWidget {
  const SsSwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon,
  });

  /// Quadrado tonal à esquerda ([SsIconTile]).
  final IconData? icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    return MergeSemantics(
      child: InkWell(
        borderRadius: BorderRadius.circular(d.radiusField),
        // O toque no próprio interruptor já dá o haptic (SsSwitch).
        onTap: onChanged == null
            ? null
            : () {
                SsHaptics.tick();
                onChanged!(!value);
              },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: d.rowPadV - 2),
          child: Row(
            children: [
              if (icon != null) ...[SsIconTile(icon!, size: d.iconTile - 4), SizedBox(width: d.gap)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: onChanged == null ? c.muted : c.ink,
                        fontSize: d.font(AppType.body),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(color: c.muted, fontSize: d.font(AppType.sub)),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: d.gap),
              SsSwitch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

/// Interruptor da suíte, "líquido": ao trocar, a bolinha **estica** no
/// caminho (até 1,45× a largura, a ponta de trás ficando para trás), bate no
/// fim, **amassa** (0,82 × 1,12) e volta com a mola ([SsMotion.bounce]). A
/// cor da marca **escorre** na trilha a partir de onde a bolinha saiu (um
/// círculo crescendo) e, ao desligar, escoa de volta. Ligado, um ✓ entra
/// girando na bolinha; ao bater no fim, um anel ([SsRipple]) se abre em volta.
/// Toque alterna (com haptic, sem arrasto); [onChanged] nulo desabilita
/// (apagado). [activeColor] troca a cor da marca (ex.: `colorScheme.primary`).
class SsSwitch extends StatefulWidget {
  const SsSwitch({super.key, required this.value, required this.onChanged, this.activeColor});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;

  @override
  State<SsSwitch> createState() => _SsSwitchState();
}

class _SsSwitchState extends State<SsSwitch> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: SsMotion.worm, value: 1);
  // De onde a bolinha e a cor saíram (0 desligado, 1 ligado).
  late double _from = widget.value ? 1 : 0;
  late double _cheio0 = _from;

  static const _w = 52.0, _h = 32.0, _thumb = 24.0, _pad = 4.0;

  /// Instante (0..1) em que a bolinha bate no fim; o resto é o amassado.
  static const _batida = .5;

  double get _to => widget.value ? 1 : 0;

  /// Viagem até a batida, acelerando e freando como líquido.
  double get _viagem => Curves.easeInOutCubic.transform((_c.value / _batida).clamp(0.0, 1.0));

  /// Posição da bolinha (0 desligado, 1 ligado).
  double get _pos => lerpDouble(_from, _to, _viagem)!;

  /// Quanto da trilha está cheio da cor (vem um pouco atrás da bolinha).
  double get _cheio => lerpDouble(_cheio0, _to, Curves.easeInOutCubic.transform((_c.value / .7).clamp(0.0, 1.0)))!;

  @override
  void didUpdateWidget(SsSwitch old) {
    super.didUpdateWidget(old);
    if (old.value == widget.value) return;
    // Sai de onde a bolinha e a cor estão (trocar de novo no meio não
    // teleporta): as contas abaixo ainda usam o alvo antigo.
    final alvoAntigo = old.value ? 1.0 : 0.0;
    final t = _c.value;
    final pos = lerpDouble(_from, alvoAntigo, Curves.easeInOutCubic.transform((t / _batida).clamp(0.0, 1.0)))!;
    final cheio = lerpDouble(_cheio0, alvoAntigo, Curves.easeInOutCubic.transform((t / .7).clamp(0.0, 1.0)))!;
    if (reduceMotion(context)) {
      _from = _cheio0 = _to;
      _c.value = 1;
      return;
    }
    _from = pos;
    _cheio0 = cheio;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _alterna() {
    SsHaptics.tick();
    widget.onChanged!(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final on = widget.onChanged != null;
    final accent = widget.activeColor ?? c.accent;
    const curso = _w - _pad * 2 - _thumb;
    return Semantics(
      toggled: widget.value,
      enabled: on,
      onTap: on ? () => widget.onChanged!(!widget.value) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: on ? _alterna : null,
        child: SizedBox(
          width: 60,
          height: 48,
          child: Center(
            child: Opacity(
              opacity: on ? 1 : .5,
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final t = _c.value;
                  final p = _pos;
                  final k = _cheio.clamp(0.0, 1.0);
                  final dist = (_to - _from).abs();
                  final indo = _to >= _from;
                  // Gota: estica até 1,45× no caminho e volta a ser bola na batida.
                  final gota = t >= 1 ? 0.0 : math.sin(math.pi * (t / _batida).clamp(0.0, 1.0)) * dist;
                  // Amassado: chega rápido no máximo e volta com a mola (passa um tiquinho).
                  final v = ((t - _batida) / (1 - _batida)).clamp(0.0, 1.0);
                  final amassa = t >= 1 || v <= 0
                      ? 0.0
                      : (v < .12 ? v / .12 : 1 - SsMotion.bounce.transform((v - .12) / .88)) * dist;
                  final frente = _pad + p * curso;
                  final esticada = _thumb + _thumb * .45 * gota;
                  final w = esticada * (1 - .18 * amassa);
                  final hh = _thumb * (1 - .12 * gota) * (1 + .12 * amassa);
                  // A ponta de trás fica para trás; no amassado, encosta na parede.
                  final left = (indo ? frente + _thumb - w : frente).clamp(1.0, _w - w - 1);
                  // ✓: ligando, entra girando (−90° → 0) e pula depois da batida;
                  // desligando, some rápido.
                  final double icone, giro;
                  if (widget.value) {
                    final a = ((t - .4) / .6).clamp(0.0, 1.0);
                    icone = a <= 0 ? 0 : SsMotion.pop.transform(a);
                    giro = -math.pi / 2 * (1 - Curves.easeOutCubic.transform(a));
                  } else {
                    icone = t >= 1 ? 0 : (1 - t / .2).clamp(0.0, 1.0);
                    giro = 0;
                  }
                  return CustomPaint(
                    painter: _SwitchTrackPainter(
                      cheio: k,
                      centro: const Offset(_pad + _thumb / 2, _h / 2),
                      vazio: c.field,
                      bordaVazia: c.line,
                      cor: accent,
                    ),
                    child: SizedBox(
                      width: _w,
                      height: _h,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Halo: um anel se abre em volta da bolinha quando ela bate no fim.
                          Positioned(
                            left: _pad + _to * curso,
                            top: (_h - _thumb) / 2,
                            width: _thumb,
                            height: _thumb,
                            child: SsRipple(
                              trigger: widget.value,
                              delay: SsMotion.worm * _batida * .9,
                              duration: const Duration(milliseconds: 420),
                              begin: 1,
                              color: accent,
                              child: const SizedBox.shrink(),
                            ),
                          ),
                          Positioned(
                            left: left,
                            top: (_h - hh) / 2,
                            width: w,
                            height: hh,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color.lerp(c.muted, AppColors.onDark, k),
                                borderRadius: BorderRadius.circular(_thumb / 2),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x29000000), blurRadius: 3, offset: Offset(0, 1)),
                                ],
                              ),
                              child: icone <= 0
                                  ? null
                                  : Center(
                                      child: Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.rotationZ(giro)
                                          ..multiply(Matrix4.diagonal3Values(icone, icone, 1)),
                                        child: SsCheckMark(value: true, size: 14, color: accent, strokeWidth: 2.2),
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
          ),
        ),
      ),
    );
  }
}

/// Trilha do [SsSwitch]: fundo vazio, a cor da marca num círculo que cresce
/// a partir de [centro] (recortado na pílula) e a borda que acompanha.
class _SwitchTrackPainter extends CustomPainter {
  _SwitchTrackPainter({
    required this.cheio,
    required this.centro,
    required this.vazio,
    required this.bordaVazia,
    required this.cor,
  });
  final double cheio;
  final Offset centro;
  final Color vazio, bordaVazia, cor;

  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.height / 2));
    canvas.drawRRect(rr, Paint()..color = vazio);
    if (cheio > 0) {
      // Raio que cobre a pílula inteira a partir do centro de partida.
      final longe = Offset(size.width, 0) - centro;
      canvas.save();
      canvas.clipRRect(rr);
      canvas.drawCircle(centro, (longe.distance + 2) * cheio, Paint()..color = cor);
      canvas.restore();
    }
    canvas.drawRRect(
      rr.deflate(.75),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Color.lerp(bordaVazia, cor, cheio)!,
    );
  }

  @override
  bool shouldRepaint(_SwitchTrackPainter old) =>
      old.cheio != cheio || old.cor != cor || old.vazio != vazio || old.bordaVazia != bordaVazia;
}

/// Campo só de hora (lembrete, horário de treino): mostra "07:30" em DM Mono
/// e o toque abre o relógio do sistema (24 h). [clearable] põe um × para
/// voltar a "sem horário". Com [validator], vale dentro de [Form] e mostra o
/// erro embaixo (borda vermelha); [helperText] é a dica fixa embaixo.
class SsTimeField extends StatelessWidget {
  const SsTimeField({
    super.key,
    this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.clearable = false,
    this.enabled = true,
    this.validator,
    this.helperText,
  });

  final String? label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay?> onChanged;

  /// Padrão: [SsStrings.noTime].
  final String? hint;
  final bool clearable;
  final bool enabled;

  /// Ex.: `(v) => SsValidators.required(v, SsStrings.of(context))`.
  final FormFieldValidator<TimeOfDay>? validator;

  /// Dica fixa embaixo do campo (some enquanto há erro).
  final String? helperText;

  /// "07:30".
  static String format(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _abrir(BuildContext context) async {
    final r = await showTimePicker(
      context: context,
      initialTime: value ?? const TimeOfDay(hour: 7, minute: 0),
      builder: (context, child) =>
          MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (r != null) onChanged(r);
  }

  @override
  Widget build(BuildContext context) {
    if (validator == null) return _campo(context, null);
    // Chave pelo valor: o estado do campo acompanha o valor que vem de fora.
    return FormField<TimeOfDay>(
      key: ValueKey(value),
      initialValue: value,
      validator: validator,
      builder: (f) => _campo(context, f.errorText),
    );
  }

  Widget _campo(BuildContext context, String? erro) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final texto = value == null ? null : format(value!);
    final hint = this.hint ?? SsStrings.of(context).noTime;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) SsFieldLabel(label!),
        SsTapTarget(
          minSize: Size(0, d.minTarget),
          child: Semantics(
            button: true,
            enabled: enabled,
            label: label,
            value: texto ?? hint,
            excludeSemantics: true,
            child: SsPressable(
              enabled: enabled,
              onTap: enabled ? () => _abrir(context) : null,
              child: Container(
                height: d.fieldHeight,
                padding: EdgeInsets.only(left: d.padX - 2, right: 4),
                decoration: BoxDecoration(
                  color: c.field,
                  borderRadius: BorderRadius.circular(d.radiusField),
                  // Sem erro, sem borda: o campo fica igual ao de antes.
                  border: erro == null ? null : Border.all(color: c.danger.withValues(alpha: .55), width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: d.iconSize + 1, color: c.muted),
                    SizedBox(width: d.gap - 2),
                    Expanded(
                      child: texto == null
                          ? Text(
                              hint,
                              style: TextStyle(color: c.muted, fontSize: d.font(AppType.body)),
                            )
                          : Text(
                              texto,
                              style: AppTheme.number(
                                context,
                                size: d.font(AppType.md),
                                color: enabled ? c.ink : c.muted,
                              ),
                            ),
                    ),
                    if (clearable && value != null && enabled)
                      IconButton(
                        tooltip: SsStrings.of(context).clearTime,
                        onPressed: () => onChanged(null),
                        icon: Icon(Icons.close_rounded, size: 18, color: c.muted),
                      )
                    else
                      const SizedBox(width: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (erro != null) _ErrorLine(erro) else if (helperText != null) SsFieldHelper(helperText!),
      ],
    );
  }
}

/// Linha com caixa de marcar (aceite, "lembrar"): toda a linha é o alvo do
/// toque. A caixa é um [SsCheckBox]: ao marcar, encolhe, pula com mola, a cor
/// inunda do centro, o ✓ se desenha e sai um estouro de risquinhos; ao
/// desmarcar, desfaz e balança. [child] no lugar de [title] para texto com
/// link.
class SsCheckRow extends StatelessWidget {
  const SsCheckRow({super.key, this.title, this.child, this.subtitle, required this.value, required this.onChanged})
    : assert(title != null || child != null);

  final String? title;
  final Widget? child;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final on = onChanged != null;
    return Semantics(
      checked: value,
      enabled: on,
      child: InkWell(
        borderRadius: BorderRadius.circular(d.radiusField),
        onTap: on
            ? () {
                HapticFeedback.selectionClick();
                onChanged!(!value);
              }
            : null,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: d.rowPadV),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Marcou: a caixa encolhe, pula, a cor inunda do centro, o ✓ se
              // desenha e sai um estouro; desmarcou: desfaz e balança.
              SsCheckBox(value: value),
              SizedBox(width: d.gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    child ??
                        Text(
                          title!,
                          style: TextStyle(
                            color: on ? c.ink : c.muted,
                            fontSize: d.font(AppType.body),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(color: c.muted, fontSize: d.font(AppType.sub)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
