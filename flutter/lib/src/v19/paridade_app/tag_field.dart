// v1.9 · paridade_app: etiquetas digitadas (par do Ss::TagInputComponent).
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../density.dart';
import '../../motion.dart';
import '../../ss_fields.dart' show SsFieldLabel, SsFieldHelper;
import '../../ss_strings.dart';
import '../../v16/input_chip.dart';
import 'comum.dart';

/// Etiquetas digitadas: confirmar no teclado ou digitar vírgula vira chip
/// ([SsInputChip], o `.ss-tag` do web), o ✕ tira, apagar no campo vazio
/// (teclado físico) tira a última, e colar "a, b, c" vira três. Repetida
/// (sem diferenciar maiúsculas) não entra. O teclado fica aberto entre uma
/// etiqueta e outra. Par do `Ss::TagInputComponent`.
///
/// `SsTagField(label: 'Etiquetas', values: tags, onChanged: (v) => setState(() => tags = v))`
class SsTagField extends StatefulWidget {
  const SsTagField({
    super.key,
    required this.label,
    required this.values,
    required this.onChanged,
    this.hint,
    this.helperText,
    this.maxTags,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;

  /// Padrão: [SsStrings.tagFieldHint].
  final String? hint;
  final String? helperText;

  /// Limite de etiquetas (o campo some ao chegar nele). Nulo: sem limite.
  final int? maxTags;
  final TextCapitalization textCapitalization;

  /// Separa o texto em etiquetas (vírgula ou quebra de linha), sem vazias.
  static List<String> split(String text) =>
      text.split(RegExp(r'[,\n]')).map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

  @override
  State<SsTagField> createState() => _SsTagFieldState();
}

class _SsTagFieldState extends State<SsTagField> {
  final _c = TextEditingController();
  final _foco = FocusNode();

  @override
  void dispose() {
    _c.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _somar(Iterable<String> novas) {
    final out = [...widget.values];
    for (final t in novas) {
      if (widget.maxTags != null && out.length >= widget.maxTags!) break;
      if (out.any((v) => v.toLowerCase() == t.toLowerCase())) continue;
      out.add(t);
    }
    if (out.length != widget.values.length) {
      SsHaptics.tick();
      widget.onChanged(out);
    }
  }

  void _confirmar([String? _]) {
    final t = _c.text;
    _c.clear();
    _somar(SsTagField.split(t));
    _foco.requestFocus();
  }

  void _digitou(String v) {
    if (v.contains(',') || v.contains('\n')) {
      // "abc," → "abc" vira chip; o que veio depois da última vírgula fica no campo.
      final corte = v.lastIndexOf(RegExp(r'[,\n]'));
      final resto = v.substring(corte + 1);
      _c.value = TextEditingValue(
        text: resto,
        selection: TextSelection.collapsed(offset: resto.length),
      );
      _somar(SsTagField.split(v.substring(0, corte)));
    }
  }

  void _tirar(int i) {
    SsHaptics.tick();
    widget.onChanged([...widget.values]..removeAt(i));
  }

  @override
  Widget build(BuildContext context) {
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    final cheio = widget.maxTags != null && widget.values.length >= widget.maxTags!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SsFieldLabel(widget.label),
        if (widget.values.isNotEmpty) ...[
          Semantics(
            container: true,
            label: ssFill(s.tagFieldChosen, {'label': widget.label}),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < widget.values.length; i++)
                  SsInputChip(widget.values[i], key: ValueKey(widget.values[i]), onDeleted: () => _tirar(i)),
              ],
            ),
          ),
          SizedBox(height: d.gap - 4),
        ],
        if (!cheio)
          Focus(
            onKeyEvent: (_, e) {
              if (e is KeyDownEvent &&
                  e.logicalKey == LogicalKeyboardKey.backspace &&
                  _c.text.isEmpty &&
                  widget.values.isNotEmpty) {
                _tirar(widget.values.length - 1);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: TextField(
              controller: _c,
              focusNode: _foco,
              textCapitalization: widget.textCapitalization,
              textInputAction: TextInputAction.done,
              onChanged: _digitou,
              onSubmitted: _confirmar,
              // Sem isto o "concluir" do teclado tira o foco e fecha o teclado.
              onEditingComplete: () {},
              onTapOutside: (_) {
                if (_c.text.trim().isNotEmpty) _confirmar();
                _foco.unfocus();
              },
              decoration: InputDecoration(hintText: widget.hint ?? s.tagFieldHint),
            ),
          ),
        if (widget.helperText != null) SsFieldHelper(widget.helperText!),
      ],
    );
  }
}
