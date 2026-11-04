// v0.10 (estrutura): seletor de ícone e seletor de idioma.
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../motion.dart';
import '../ss_controls.dart';
import '../ss_strings.dart';

/// Grade de ícones com busca e anel no escolhido. Os ícones vêm do app como
/// `(nome, IconData)` (o produto usa a fonte MDI dele). Devolve o nome.
/// [labels] dá o nome legível de cada ícone (nome → "Lâmpada"): vai na dica,
/// no leitor de tela e na busca, no lugar do nome cru.
///
/// `SsIconPicker(icons: [('lightbulb', Icons.lightbulb), ...], value: 'lightbulb', onChanged: (n) => ...)`
class SsIconPicker extends StatefulWidget {
  const SsIconPicker({
    super.key,
    required this.icons,
    required this.value,
    required this.onChanged,
    this.allowNone = false,
    this.height = 260,
    this.searchHint,
    this.noneLabel,
    this.emptyText,
    this.initialQuery = '',
    this.labels = const {},
  });

  final List<(String, IconData)> icons;

  /// Nome do ícone → rótulo legível ("lightbulb" → "Lâmpada").
  final Map<String, String> labels;

  /// Nome escolhido; nulo = nenhum.
  final String? value;
  final ValueChanged<String?> onChanged;

  /// Mostra a opção "Sem ícone" no começo da grade.
  final bool allowNone;

  /// Altura da grade (rola dentro).
  final double height;

  /// Textos (padrão: os do [SsStrings] do idioma).
  final String? searchHint;
  final String? noneLabel;
  final String Function(String query)? emptyText;
  final String initialQuery;

  /// "Nenhum ícone com “q”" (pt); mantido por compatibilidade.
  static String emptyPt(String q) => SsStrings.pt.noIconFor(q);

  /// Busca sem acento e sem caixa; `-`, `_` e espaço contam igual.
  static String normalize(String s) {
    const de = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const para = 'aaaaaeeeeiiiiooooouuuucn';
    final b = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      final i = de.indexOf(ch);
      b.write(i >= 0 ? para[i] : (ch == '_' || ch == '-' ? ' ' : ch));
    }
    return b.toString().trim();
  }

  @override
  State<SsIconPicker> createState() => _SsIconPickerState();
}

class _SsIconPickerState extends State<SsIconPicker> {
  late final _q = TextEditingController(text: widget.initialQuery);

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = SsStrings.of(context);
    final q = SsIconPicker.normalize(_q.text);
    final lista = q.isEmpty
        ? widget.icons
        : widget.icons
              .where(
                (e) =>
                    SsIconPicker.normalize(e.$1).contains(q) ||
                    SsIconPicker.normalize(widget.labels[e.$1] ?? '').contains(q),
              )
              .toList();
    final itens = <(String?, IconData?)>[if (widget.allowNone && q.isEmpty) (null, null), ...lista];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SsSearchField(controller: _q, hint: widget.searchHint ?? s.searchIcon, onChanged: (_) => setState(() {})),
        const SizedBox(height: 10),
        SizedBox(
          height: widget.height,
          child: lista.isEmpty
              ? Center(
                  child: Text(
                    (widget.emptyText ?? s.noIconFor)(_q.text.trim()),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.muted, fontSize: AppType.sub, fontWeight: FontWeight.w600),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(4),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 56,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemCount: itens.length,
                  itemBuilder: (context, i) {
                    final (nome, icone) = itens[i];
                    final sel = nome == widget.value;
                    return _Celula(
                      label: nome == null ? widget.noneLabel ?? s.noIcon : widget.labels[nome] ?? nome,
                      selected: sel,
                      onTap: () {
                        SsHaptics.tick();
                        widget.onChanged(nome);
                      },
                      child: Icon(icone ?? Icons.block_rounded, size: 24, color: sel ? c.accentText : c.ink2),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _Celula extends StatelessWidget {
  const _Celula({required this.label, required this.selected, required this.onTap, required this.child});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final rm = reduceMotion(context);
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: SsPressable(
          onTap: onTap,
          child: SsPop(
            active: selected,
            child: AnimatedContainer(
              duration: rm ? Duration.zero : SsMotion.base,
              curve: SsMotion.bounce,
              decoration: BoxDecoration(
                color: selected ? c.accentSoft : c.field,
                borderRadius: BorderRadius.circular(AppRadius.field),
                border: Border.all(color: selected ? c.accent : Colors.transparent, width: 2),
              ),
              alignment: Alignment.center,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────── idioma

/// Um idioma do [SsLocalePicker]: código ("pt-BR"), nome no próprio idioma e
/// a bandeira (emoji, opcional).
class SsLocale {
  const SsLocale(this.code, this.name, {this.flag});
  final String code;
  final String name;
  final String? flag;
}

/// Escolha de idioma: lista com o atual marcado (✓) ou segmented compacto.
/// Os nomes ficam sempre no próprio idioma (Português, English, Español).
///
/// [systemOption] põe no começo "Seguir o sistema" (no segmented, "Auto"):
/// marcada quando [value] é nulo, e o toque chama [onSystem] (o app apaga o
/// idioma salvo e volta ao do aparelho).
class SsLocalePicker extends StatelessWidget {
  const SsLocalePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.locales = SsLocalePicker.suite,
    this.segmented = false,
    this.showFlag = true,
    this.systemOption = false,
    this.onSystem,
    this.systemLabel,
  }) : assert(!systemOption || onSystem != null, 'systemOption precisa de onSystem');

  /// Os 3 da suíte.
  static const suite = [
    SsLocale('pt-BR', 'Português', flag: '🇧🇷'),
    SsLocale('en', 'English', flag: '🇺🇸'),
    SsLocale('es', 'Español', flag: '🇪🇸'),
  ];

  /// Código escolhido; nulo = segue o sistema (com [systemOption]).
  final String? value;
  final ValueChanged<String> onChanged;
  final List<SsLocale> locales;

  /// Opção "Seguir o sistema" no começo.
  final bool systemOption;

  /// Toque em "Seguir o sistema".
  final VoidCallback? onSystem;

  /// Padrão: [SsStrings.localeSystem] (lista) ou [SsStrings.localeSystemShort]
  /// (segmented).
  final String? systemLabel;

  /// Segmented (cabe numa linha de configuração) em vez da lista.
  final bool segmented;

  /// Bandeira emoji; falso (ou sem bandeira) mostra o código ("PT").
  final bool showFlag;

  static String shortCode(String code) => code.split(RegExp('[-_]')).first.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = SsStrings.of(context);
    final sistema = systemOption && onSystem != null;
    if (segmented) {
      // O sistema entra como '' no segmented (os códigos nunca são vazios).
      return SsSegmented<String>(
        segments: [
          if (sistema) ('', systemLabel ?? s.localeSystemShort),
          for (final l in locales)
            (l.code, showFlag && l.flag != null ? '${l.flag} ${shortCode(l.code)}' : shortCode(l.code)),
        ],
        value: value ?? '',
        onChanged: (v) => v.isEmpty ? onSystem!() : onChanged(v),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: c.isDark ? Border.all(color: c.line) : null,
        boxShadow: c.isDark ? null : AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (sistema) ...[
            _linhaSistema(context, c, systemLabel ?? s.localeSystem),
            Divider(height: 1, indent: 60, color: c.line),
          ],
          for (final (i, l) in locales.indexed) ...[
            if (i > 0) Divider(height: 1, indent: 60, color: c.line),
            Semantics(
              inMutuallyExclusiveGroup: true,
              checked: l.code == value,
              button: true,
              label: l.name,
              excludeSemantics: true,
              child: InkWell(
                onTap: () {
                  SsHaptics.tick();
                  onChanged(l.code);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(10)),
                        child: showFlag && l.flag != null
                            ? Text(l.flag!, style: const TextStyle(fontSize: 18))
                            : Text(
                                shortCode(l.code),
                                style: TextStyle(color: c.ink2, fontWeight: FontWeight.w800, fontSize: AppType.label),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l.name,
                          style: TextStyle(
                            color: c.ink,
                            fontSize: AppType.body,
                            fontWeight: l.code == value ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),
                      SsCheckMark(value: l.code == value, size: 20, color: c.accent),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _linhaSistema(BuildContext context, SsColors c, String rotulo) {
    final sel = value == null;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: sel,
      button: true,
      label: rotulo,
      excludeSemantics: true,
      child: InkWell(
        onTap: () {
          SsHaptics.tick();
          onSystem!();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.phone_android_rounded, size: 18, color: c.ink2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  rotulo,
                  style: TextStyle(
                    color: c.ink,
                    fontSize: AppType.body,
                    fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              SsCheckMark(value: sel, size: 20, color: c.accent),
            ],
          ),
        ),
      ),
    );
  }
}
