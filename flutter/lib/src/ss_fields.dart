import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'format.dart';
import 'motion.dart';
import 'ss_button.dart';
import 'ss_controls.dart';
import 'ss_list.dart';
import 'ss_picker.dart';
import 'ss_sheet.dart';
import 'ss_stat.dart';

/// Validadores prontos (mensagens pt-BR) para os campos `Ss*`.
abstract final class SsValidators {
  /// Vazio (nulo ou texto em branco) → "Campo obrigatório". Serve para texto e escolha.
  static String? required(Object? v) => v == null || (v is String && v.trim().isEmpty) ? 'Campo obrigatório' : null;

  /// Para o [SsMoneyField]: precisa de valor maior que zero.
  static String? money(int? cents) => cents == null || cents <= 0 ? 'Informe um valor' : null;

  /// Número inteiro entre [min] e [max] (inclusive).
  static FormFieldValidator<String> intRange(int min, int max) => (v) {
    final n = int.tryParse(v?.trim() ?? '');
    if (n == null) return 'Informe um número';
    return n < min || n > max ? 'Use um número de $min a $max' : null;
  };
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 2, bottom: 6),
    child: Text(
      text,
      style: TextStyle(color: SsColors.of(context).ink2, fontSize: AppType.sub, fontWeight: FontWeight.w700),
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
    final on = _focus.hasFocus;
    OutlineInputBorder borda(Color cor) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.field),
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
      obscureText: widget.obscureText,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.obscureText ? null : widget.minLines,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      style: widget.style ?? TextStyle(color: c.ink, fontSize: AppType.body, fontWeight: FontWeight.w600),
      errorBuilder: (_, msg) => _ErrorLine(msg),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(color: c.muted, fontSize: AppType.body, fontWeight: FontWeight.w500),
        helperText: widget.helperText,
        helperMaxLines: 3,
        helperStyle: TextStyle(color: c.muted, fontSize: AppType.meta),
        prefixIcon: widget.icon == null ? null : Icon(widget.icon, size: 21, color: on ? c.accent : c.muted),
        prefixText: widget.prefixText,
        prefixStyle: widget.style ?? TextStyle(color: c.muted, fontSize: AppType.body, fontWeight: FontWeight.w600),
        suffixIcon: widget.suffix,
        suffixText: widget.suffixText,
        suffixStyle: TextStyle(color: c.muted, fontSize: AppType.sub, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: on ? c.surface : c.field,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: borda(Colors.transparent),
        disabledBorder: borda(Colors.transparent),
        focusedBorder: borda(c.accent.withValues(alpha: .45)),
        errorBorder: borda(c.danger.withValues(alpha: .55)),
        focusedErrorBorder: borda(c.danger),
      ),
    );
    final dur = reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 180);
    return AnimatedBuilder(
      animation: _shake,
      builder: (_, child) {
        final t = _shake.value;
        return Transform.translate(offset: Offset(math.sin(t * math.pi * 6) * 8 * (1 - t), 0), child: child);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.label != null) _Label(widget.label!),
          // O halo só sem erro: com erro, a caixa ganharia a altura da mensagem.
          AnimatedContainer(
            duration: dur,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.field),
              boxShadow: on && !_hasError
                  ? [BoxShadow(color: c.accent.withValues(alpha: .12), spreadRadius: 4)]
                  : const [],
            ),
            child: campo,
          ),
        ],
      ),
    );
  }
}

/// Dinheiro em centavos: digita só números e o valor cresce da direita
/// (0,00 → 0,05 → 0,50 → 5,00), em DM Mono com "R$" na frente.
/// [keypad] troca o teclado do sistema pelo [showSsAmountKeypad].
class SsMoneyField extends StatefulWidget {
  const SsMoneyField({
    super.key,
    this.label,
    required this.cents,
    required this.onChanged,
    this.validator,
    this.hint = '0,00',
    this.keypad = false,
    this.enabled = true,
  });

  final String? label;
  final int? cents;
  final ValueChanged<int?> onChanged;

  /// Recebe os centavos (ex.: [SsValidators.money]).
  final String? Function(int? cents)? validator;
  final String hint;
  final bool keypad;
  final bool enabled;

  @override
  State<SsMoneyField> createState() => _SsMoneyFieldState();
}

String _semRs(int? cents) => cents == null ? '' : money(cents).replaceFirst(r'R$ ', '');

/// Só dígitos; os 2 últimos são centavos. Até 11 dígitos (R$ 999.999.999,99).
class _CentavosFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue value) {
    final d = value.text.replaceAll(RegExp(r'\D'), '');
    if (d.length > 11) return old;
    final t = d.isEmpty ? '' : _semRs(int.parse(d));
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

class _SsMoneyFieldState extends State<SsMoneyField> {
  late final _ctrl = TextEditingController(text: _semRs(widget.cents));

  @override
  void didUpdateWidget(SsMoneyField old) {
    super.didUpdateWidget(old);
    if (widget.cents != parseMoney(_ctrl.text)) _ctrl.text = _semRs(widget.cents);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _abrir() async {
    final v = await showSsAmountKeypad(context, initial: widget.cents, title: widget.label ?? 'Valor');
    if (v == null) return;
    _ctrl.text = _semRs(v);
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return SsTextField(
      label: widget.label,
      controller: _ctrl,
      hint: widget.hint,
      prefixText: r'R$ ',
      enabled: widget.enabled,
      readOnly: widget.keypad,
      onTap: widget.keypad ? _abrir : null,
      keyboardType: TextInputType.number,
      inputFormatters: [_CentavosFormatter()],
      style: AppTheme.number(context, size: AppType.md, color: c.ink),
      validator: widget.validator == null ? null : (s) => widget.validator!(parseMoney(s ?? '')),
      onChanged: (s) => widget.onChanged(parseMoney(s)),
    );
  }
}

/// Abre a folha com o valor grande (DM Mono) e um teclado 3×4 próprio
/// (1–9, 00, 0, ⌫; segurar ⌫ zera). Devolve os centavos, ou nulo se fechar.
Future<int?> showSsAmountKeypad(BuildContext context, {int? initial, String title = 'Valor'}) => showSsSheet<int>(
  context,
  title: title,
  child: SsAmountKeypad(initial: initial),
);

/// O corpo do [showSsAmountKeypad]. Sem [onConfirm], fecha a rota com o valor.
class SsAmountKeypad extends StatefulWidget {
  const SsAmountKeypad({super.key, this.initial, this.onConfirm});

  final int? initial;
  final ValueChanged<int>? onConfirm;

  @override
  State<SsAmountKeypad> createState() => _SsAmountKeypadState();
}

class _SsAmountKeypadState extends State<SsAmountKeypad> {
  late int _c = widget.initial ?? 0;

  void _tecla(String k) => setState(() {
    if (k == '⌫') {
      _c ~/= 10;
    } else if (_c < 1000000000) {
      _c = k == '00' ? _c * 100 : _c * 10 + int.parse(k);
    }
  });

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    Widget tecla(String k) => Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Semantics(
          button: true,
          label: k == '⌫' ? 'Apagar (segure para zerar)' : k,
          excludeSemantics: true,
          child: GestureDetector(
            onLongPress: k == '⌫' ? () => setState(() => _c = 0) : null,
            child: SsPressable(
              scale: .9,
              onTap: () => _tecla(k),
              child: Container(
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(AppRadius.field)),
                child: k == '⌫'
                    ? Icon(Icons.backspace_outlined, color: c.ink2)
                    : Text(k, style: AppTheme.number(context, size: 22, color: c.ink)),
              ),
            ),
          ),
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(liveRegion: true, child: Center(child: SsAmount(money(_c), size: 44))),
        const SizedBox(height: 14),
        for (final linha in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['00', '0', '⌫'],
        ])
          Row(children: [for (final k in linha) tecla(k)]),
        const SizedBox(height: 12),
        SsButton(
          label: 'Confirmar',
          icon: Icons.check_rounded,
          onPressed: () => widget.onConfirm != null ? widget.onConfirm!(_c) : Navigator.pop(context, _c),
        ),
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
  final bool _hora;

  /// Os 3 atalhos a partir de [today]: (rótulo, dia).
  static List<(String, DateTime)> shortcuts(DateTime today) {
    final d = DateUtils.dateOnly(today);
    final amanha = DateTime(d.year, d.month, d.day + 1);
    final sexta = amanha.weekday < DateTime.friday;
    final util = DateTime(
      amanha.year,
      amanha.month,
      amanha.day + (sexta ? DateTime.friday - amanha.weekday : 8 - amanha.weekday),
    );
    return [('Hoje', d), ('Amanhã', amanha), ('${sexta ? 'Sex' : 'Seg'} ${two(util.day)}/${two(util.month)}', util)];
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
      locale: const Locale('pt', 'BR'),
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
    final atalhos = showShortcuts
        ? shortcuts(DateTime.now()).where((a) => _noIntervalo(a.$2)).toList()
        : <(String, DateTime)>[];
    final v = value;
    final outra = v != null && !atalhos.any((a) => DateUtils.isSameDay(a.$2, v));
    final rotulo = showShortcuts ? 'Outra…' : 'Escolher data';
    final campo = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) _Label(label!),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final (nome, dia) in atalhos)
              SsFilterChip(
                nome,
                selected: v != null && DateUtils.isSameDay(dia, v),
                onTap: () => onChanged(_comHora(dia)),
              ),
            SsFilterChip(outra ? date(v) : rotulo, selected: outra, onTap: () => _outra(context)),
            if (_hora)
              SsFilterChip(
                v == null ? 'Hora' : '${two(v.hour)}:${two(v.minute)}',
                selected: v != null,
                onTap: () => _horario(context),
              ),
            if (clearable && v != null)
              IconButton(
                tooltip: 'Limpar data',
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close_rounded, size: 20, color: c.muted),
                onPressed: () => onChanged(null),
              ),
          ],
        ),
      ],
    );
    if (validator == null) return campo;
    return FormField<DateTime>(
      validator: (_) => validator!(value),
      builder: (f) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [campo, if (f.errorText != null) _ErrorLine(f.errorText!)],
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
    this.hint = 'Escolher',
    this.icon,
    this.validator,
    this.enabled = true,
  });

  final String? label;
  final T? value;

  /// Valor → texto, na ordem em que aparecem.
  final Map<T, String> options;
  final ValueChanged<T> onChanged;
  final String hint;
  final IconData? icon;
  final FormFieldValidator<T>? validator;
  final bool enabled;

  Future<void> _abrir(BuildContext context, FormFieldState<T> field) async {
    final r = await showSsSheet<(T,)>(
      context,
      title: label ?? hint,
      child: SsChoiceList<T>(options: options, selected: value),
    );
    if (r == null) return;
    field.didChange(r.$1);
    onChanged(r.$1);
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
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
            if (label != null) _Label(label!),
            Semantics(
              button: true,
              enabled: enabled,
              label: label,
              value: texto ?? hint,
              excludeSemantics: true,
              child: SsPressable(
                enabled: enabled,
                onTap: enabled ? () => _abrir(context, field) : null,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: c.field,
                    borderRadius: BorderRadius.circular(AppRadius.field),
                    border: Border.all(
                      color: erro != null ? c.danger.withValues(alpha: .55) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (icon != null) ...[Icon(icon, size: 21, color: c.muted), const SizedBox(width: 10)],
                      Expanded(
                        child: Text(
                          texto ?? hint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: texto == null ? c.muted : (enabled ? c.ink : c.muted),
                            fontSize: AppType.body,
                            fontWeight: texto == null ? FontWeight.w500 : FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(Icons.unfold_more_rounded, size: 20, color: c.muted),
                    ],
                  ),
                ),
              ),
            ),
            if (erro != null) _ErrorLine(erro),
          ],
        );
      },
    );
  }
}

/// A lista da folha do [SsChoiceField]: a opção marcada tem ✓; com mais de 8,
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
              'Nada encontrado',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.muted),
            ),
          ),
        for (final e in itens)
          Semantics(
            button: true,
            selected: e.key == widget.selected,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onSelect != null ? widget.onSelect!(e.key) : Navigator.pop(context, (e.key,));
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.value,
                          style: TextStyle(
                            color: e.key == widget.selected ? c.accentText : c.ink,
                            fontSize: AppType.body,
                            fontWeight: e.key == widget.selected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (e.key == widget.selected) Icon(Icons.check_rounded, size: 22, color: c.accent),
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

/// Linha com título, subtítulo e um Switch na cor da marca; tocar em
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
    void alterna(bool v) {
      HapticFeedback.selectionClick();
      onChanged!(v);
    }

    return MergeSemantics(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onChanged == null ? null : () => alterna(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              if (icon != null) ...[SsIconTile(icon!, size: 38), const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: onChanged == null ? c.muted : c.ink,
                        fontSize: AppType.body,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(color: c.muted, fontSize: AppType.sub),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: value,
                onChanged: onChanged == null ? null : alterna,
                thumbColor: WidgetStateProperty.resolveWith(
                  (s) => s.contains(WidgetState.selected) ? AppColors.onDark : c.muted,
                ),
                trackColor: WidgetStateProperty.resolveWith(
                  (s) => s.contains(WidgetState.selected) ? c.accent : c.field,
                ),
                trackOutlineColor: WidgetStateProperty.resolveWith(
                  (s) => s.contains(WidgetState.selected) ? Colors.transparent : c.line,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Campo só de hora (lembrete, horário de treino): mostra "07:30" em DM Mono
/// e o toque abre o relógio do sistema (24 h). [clearable] põe um × para
/// voltar a "sem horário".
class SsTimeField extends StatelessWidget {
  const SsTimeField({
    super.key,
    this.label,
    required this.value,
    required this.onChanged,
    this.hint = 'Sem horário',
    this.clearable = false,
    this.enabled = true,
  });

  final String? label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay?> onChanged;
  final String hint;
  final bool clearable;
  final bool enabled;

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
    final c = SsColors.of(context);
    final texto = value == null ? null : format(value!);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) _Label(label!),
        Semantics(
          button: true,
          enabled: enabled,
          label: label,
          value: texto ?? hint,
          excludeSemantics: true,
          child: SsPressable(
            enabled: enabled,
            onTap: enabled ? () => _abrir(context) : null,
            child: Container(
              height: 52,
              padding: const EdgeInsets.only(left: 14, right: 4),
              decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(AppRadius.field)),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 21, color: c.muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: texto == null
                        ? Text(
                            hint,
                            style: TextStyle(color: c.muted, fontSize: AppType.body),
                          )
                        : Text(
                            texto,
                            style: AppTheme.number(context, size: AppType.md, color: enabled ? c.ink : c.muted),
                          ),
                  ),
                  if (clearable && value != null && enabled)
                    IconButton(
                      tooltip: 'Limpar horário',
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
      ],
    );
  }
}

/// Linha com caixa de marcar (aceite, "lembrar"): toda a linha é o alvo do
/// toque; a marca entra com mola. [child] no lugar de [title] para texto com
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
    final on = onChanged != null;
    final dur = reduceMotion(context) ? Duration.zero : SsMotion.fast;
    return Semantics(
      checked: value,
      enabled: on,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: on
            ? () {
                HapticFeedback.selectionClick();
                onChanged!(!value);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: dur,
                curve: Curves.easeOutBack,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: value ? c.accent : c.field,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: value ? c.accent : c.muted2, width: 1.5),
                ),
                child: AnimatedScale(
                  duration: dur,
                  curve: Curves.easeOutBack,
                  scale: value ? 1 : 0,
                  child: const Icon(Icons.check_rounded, size: 17, color: AppColors.onDark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    child ??
                        Text(
                          title!,
                          style: TextStyle(
                            color: on ? c.ink : c.muted,
                            fontSize: AppType.body,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(color: c.muted, fontSize: AppType.sub),
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
