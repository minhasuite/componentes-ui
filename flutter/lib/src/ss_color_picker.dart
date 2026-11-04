// v0.10.1: seletor de cor por fichas, com a cor livre opcional (o
// `Ss::SwatchPickerComponent(free: true)` do Rails).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'motion.dart';
import 'ss_button.dart';
import 'ss_fields.dart';
import 'ss_sheet.dart';
import 'ss_strings.dart';
import 'v10/ctl_slider.dart';

/// Escolha de cor por fichas redondas (anel na escolhida, ✓ no contraste da
/// cor). Com [free], a última ficha é a "Personalizada" (arco-íris, ou a cor
/// livre já escolhida): abre uma folha com matiz, saturação, brilho e o
/// código hex ([SsColorPickerSheet]).
///
/// `SsColorPicker(colors: [Color(0xFFFFB74D), ...], value: cor, onChanged: (c) => ..., free: true)`
class SsColorPicker extends StatelessWidget {
  const SsColorPicker({
    super.key,
    required this.colors,
    required this.value,
    required this.onChanged,
    this.free = false,
    this.label,
    this.names,
    this.freeLabel,
    this.size = 36,
  }) : assert(names == null || names.length == colors.length);

  final List<Color> colors;

  /// Cor escolhida (uma das [colors] ou a livre); nulo = nenhuma.
  final Color? value;
  final ValueChanged<Color> onChanged;

  /// Ficha "Personalizada" no fim.
  final bool free;

  /// Rótulo acima (como o dos campos).
  final String? label;

  /// Nome de cada cor para o leitor de tela e a dica ("Âmbar").
  final List<String>? names;

  /// Padrão: [SsStrings.colorCustom].
  final String? freeLabel;

  /// Diâmetro das fichas.
  final double size;

  static bool _igual(Color a, Color b) => a.toARGB32() == b.toARGB32();

  /// "#ffb74d".
  static String hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  /// "#ffb74d", "ffb74d" ou "#fb4" → cor; outro texto → nulo.
  static Color? parseHex(String text) {
    var t = text.trim().replaceFirst('#', '');
    if (t.length == 3) t = t.split('').map((ch) => '$ch$ch').join();
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(t)) return null;
    return Color(0xFF000000 | int.parse(t, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final s = SsStrings.of(context);
    final v = value;
    final livre = free && v != null && !colors.any((c) => _igual(c, v));
    final fichas = <Widget>[
      for (var i = 0; i < colors.length; i++)
        _Ficha(
          color: colors[i],
          size: size,
          selected: v != null && _igual(colors[i], v),
          label: names?[i] ?? hex(colors[i]),
          onTap: () => onChanged(colors[i]),
        ),
      if (free)
        _Ficha(
          color: livre ? v : null,
          size: size,
          selected: livre,
          label: freeLabel ?? s.colorCustom,
          onTap: () async {
            final r = await showSsColorSheet(context, initial: v ?? colors.firstOrNull ?? SsColors.of(context).accent);
            if (r != null) onChanged(r);
          },
        ),
    ];
    final grade = Wrap(spacing: 10, runSpacing: 10, children: fichas);
    if (label == null) return grade;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [SsFieldLabel(label!), grade],
    );
  }
}

/// Abre a folha da cor livre ([SsColorPickerSheet]) e devolve a cor, ou nulo
/// se fechou.
Future<Color?> showSsColorSheet(BuildContext context, {required Color initial, String? title}) => showSsSheet<Color>(
  context,
  title: title ?? SsStrings.of(context).colorPickOther,
  child: SsColorPickerSheet(initial: initial),
);

/// Ficha redonda: a cor (com borda fina para as claras), anel quando
/// escolhida e ✓ no contraste. Sem [color], o arco-íris da cor livre.
class _Ficha extends StatelessWidget {
  const _Ficha({
    required this.color,
    required this.size,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final Color? color;
  final double size;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final cor = color;
    final escura = cor != null && ThemeData.estimateBrightnessForColor(cor) == Brightness.dark;
    final rm = reduceMotion(context);
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        label: label,
        excludeSemantics: true,
        child: SsPressable(
          onTap: () {
            SsHaptics.tick();
            onTap();
          },
          child: AnimatedContainer(
            duration: rm ? Duration.zero : SsMotion.base,
            curve: SsMotion.bounce,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: selected ? c.accent : Colors.transparent, width: 2),
            ),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cor,
                gradient: cor == null
                    ? SweepGradient(
                        colors: [
                          for (var h = 0; h <= 360; h += 60) HSVColor.fromAHSV(1, h % 360 * 1.0, .75, 1).toColor(),
                        ],
                      )
                    : null,
                // Cor clara sobre fundo claro: o fio mostra a borda.
                border: Border.all(color: c.ink.withValues(alpha: .14)),
              ),
              child: cor == null
                  ? Icon(Icons.add_rounded, size: size * .5, color: Colors.white)
                  : SsCheckMark(
                      value: selected,
                      size: size * .5,
                      color: escura ? Colors.white : const Color(0xFF1B1640),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Conteúdo da folha da cor livre: amostra, matiz, saturação, brilho e o
/// código hex (os dois lados se acompanham). Sem rota ([onPicked] nulo),
/// fecha com a cor. Público para o catálogo e para quem monta a própria
/// folha.
class SsColorPickerSheet extends StatefulWidget {
  const SsColorPickerSheet({super.key, required this.initial, this.onPicked});

  final Color initial;
  final ValueChanged<Color>? onPicked;

  @override
  State<SsColorPickerSheet> createState() => _SsColorPickerSheetState();
}

class _SsColorPickerSheetState extends State<SsColorPickerSheet> {
  late HSVColor _hsv = HSVColor.fromColor(widget.initial);
  late final _hex = TextEditingController(text: SsColorPicker.hex(widget.initial));
  String? _erro;

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _muda(HSVColor h) {
    setState(() {
      _hsv = h;
      _erro = null;
    });
    _hex.text = SsColorPicker.hex(h.toColor());
  }

  void _digitou(String t) {
    final cor = SsColorPicker.parseHex(t);
    setState(() {
      if (cor != null) _hsv = HSVColor.fromColor(cor);
      _erro = null;
    });
  }

  void _usar() {
    final cor = SsColorPicker.parseHex(_hex.text);
    if (cor == null) {
      setState(() => _erro = SsStrings.of(context).colorHexInvalid);
      return;
    }
    if (widget.onPicked != null) {
      widget.onPicked!(cor);
    } else {
      Navigator.pop(context, cor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = SsStrings.of(context);
    final cor = _hsv.toColor();
    final pura = HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor();
    String pct(double v) => '${(v * 100).round()}%';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: cor,
                borderRadius: BorderRadius.circular(AppRadius.field),
                border: Border.all(color: c.ink.withValues(alpha: .14)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SsTextField(
                label: s.colorHex,
                controller: _hex,
                icon: Icons.tag_rounded,
                autocorrect: false,
                enableSuggestions: false,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[#0-9a-fA-F]'))],
                maxLength: 7,
                onChanged: _digitou,
                onSubmitted: (_) => _usar(),
                style: AppTheme.number(context, size: AppType.body, color: c.ink),
              ),
            ),
          ],
        ),
        if (_erro != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _erro!,
              style: TextStyle(color: c.dangerText, fontSize: AppType.meta, fontWeight: FontWeight.w600),
            ),
          ),
        const SizedBox(height: 14),
        SsSlider(
          label: s.colorHue,
          showValue: true,
          value: _hsv.hue,
          max: 360,
          track: SsSliderTrack.hue,
          format: (v) => '${v.round()}°',
          onChanged: (v) => _muda(_hsv.withHue(v)),
        ),
        const SizedBox(height: 8),
        SsSlider(
          label: s.colorSaturation,
          showValue: true,
          value: _hsv.saturation * 100,
          gradient: [
            HSVColor.fromAHSV(1, _hsv.hue, 0, _hsv.value).toColor(),
            HSVColor.fromAHSV(1, _hsv.hue, 1, _hsv.value).toColor(),
          ],
          color: pura,
          format: (v) => pct(v / 100),
          onChanged: (v) => _muda(_hsv.withSaturation(v / 100)),
        ),
        const SizedBox(height: 8),
        SsSlider(
          label: s.colorBrightness,
          showValue: true,
          value: _hsv.value * 100,
          gradient: [Colors.black, HSVColor.fromAHSV(1, _hsv.hue, _hsv.saturation, 1).toColor()],
          color: pura,
          format: (v) => pct(v / 100),
          onChanged: (v) => _muda(_hsv.withValue(v / 100)),
        ),
        const SizedBox(height: 18),
        SsButton(label: s.confirm, icon: Icons.check_rounded, onPressed: _usar),
      ],
    );
  }
}
