// v0.13: texto longo, parágrafo de abertura e grupo de campos com ajuda (pares
// do Ss::ProseComponent/.ss-prose, Ss::IntroComponent/.ss-intro e ss_fieldset).
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../density.dart';
import '../ss_fields.dart' show SsFieldHelper;

/// Texto longo (termos, privacidade, ajuda): os [children] (parágrafos,
/// títulos, listas) um embaixo do outro, com a cor e a altura de linha de
/// leitura e largura máxima de leitura ([maxWidth], ~70 caracteres).
/// `SsProse.paragraphs(texto)` quebra um texto nos parágrafos (linha em
/// branco) e nas listas ("- item"). O web é o `.ss-prose`.
class SsProse extends StatelessWidget {
  const SsProse({super.key, required this.children, this.maxWidth = 640});

  /// Parágrafos separados por linha em branco; linhas com "- " viram itens de lista.
  factory SsProse.paragraphs(String text, {Key? key, double maxWidth = 640}) {
    final blocks = text.trim().split(RegExp(r'\n\s*\n'));
    return SsProse(
      key: key,
      maxWidth: maxWidth,
      children: [
        for (final b in blocks)
          if (b.trimLeft().startsWith('- '))
            SsProseList([for (final l in b.split('\n')) l.trim().replaceFirst(RegExp(r'^- '), '')])
          else
            Text(b.trim()),
      ],
    );
  }

  final List<Widget> children;
  final double maxWidth;

  /// Estilo do título dentro do texto (h2 do web).
  static TextStyle heading(BuildContext context) => TextStyle(
    color: SsColors.of(context).ink,
    fontSize: SsDensity.of(context).font(AppType.lg),
    fontWeight: FontWeight.w800,
    height: 1.25,
  );

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: c.ink2, fontSize: d.font(AppType.body), height: 1.6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: d.space(12), children: children),
        ),
      ),
    );
  }
}

/// Lista com marcador do [SsProse] (o `ul` do web).
///
/// v0.19.2: [ordered] numera os itens num círculo suave da marca (passos de
/// uma receita, instruções do aparelho; o `ol.is-steps` dentro do
/// `.ss-prose` do web). O leitor de tela lê "1. texto". Fora do [SsProse], o
/// texto herda o estilo de cima (passe um `DefaultTextStyle` para mudar).
class SsProseList extends StatelessWidget {
  const SsProseList(this.items, {super.key, this.ordered = false, this.start = 1});

  final List<String> items;
  final bool ordered;

  /// Número do primeiro item com [ordered].
  final int start;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    if (ordered) {
      final n = d.font(24);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: d.space(8),
        children: [
          for (final (k, i) in items.indexed)
            MergeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    label: '${start + k}.',
                    excludeSemantics: true,
                    child: Container(
                      width: n,
                      height: n,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: c.accentSoft, shape: BoxShape.circle),
                      child: Text(
                        '${start + k}',
                        style: AppTheme.number(
                          context,
                          size: AppType.meta,
                          weight: FontWeight.w700,
                          color: c.accentText,
                        ).copyWith(height: AppType.solid),
                      ),
                    ),
                  ),
                  SizedBox(width: d.space(10)),
                  Expanded(
                    child: Padding(padding: const EdgeInsets.only(top: 2), child: Text(i)),
                  ),
                ],
              ),
            ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        for (final i in items)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Text('•  ', style: TextStyle(color: c.muted)),
              ),
              Expanded(child: Text(i)),
            ],
          ),
      ],
    );
  }
}

/// Parágrafo de abertura de uma aba ou seção: uma ou duas frases do que ela
/// faz, apagado, antes do conteúdo. O web é o `Ss::IntroComponent` (`.ss-intro`).
class SsIntro extends StatelessWidget {
  const SsIntro(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final d = SsDensity.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: d.gap * 1.2),
      child: Text(
        text,
        style: TextStyle(color: SsColors.of(context).muted, fontSize: d.font(AppType.set), height: 1.5),
      ),
    );
  }
}

/// Grupo de campos com legenda ([label]) e uma ajuda do grupo ([helperText])
/// antes dos campos ([children]), como o `ss_fieldset` do web. O leitor de
/// tela lê a legenda e a ajuda ao entrar no grupo.
class SsFieldGroup extends StatelessWidget {
  const SsFieldGroup({super.key, required this.label, this.helperText, required this.children, this.spacing});

  final String label;
  final String? helperText;
  final List<Widget> children;

  /// Espaço entre os campos (padrão: o `gap` da densidade).
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    return Semantics(
      container: true,
      label: [label, ?helperText].join('. '),
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Text(
              label,
              style: TextStyle(color: c.ink2, fontSize: d.font(AppType.set), fontWeight: FontWeight.w700),
            ),
          ),
          if (helperText != null) ExcludeSemantics(child: SsFieldHelper(helperText!)),
          SizedBox(height: d.space(10)),
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: spacing ?? d.gap, children: children),
        ],
      ),
    );
  }
}
