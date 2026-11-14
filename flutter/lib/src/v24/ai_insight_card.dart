// v0.24 (auditoria de UX do meu-gestor, B16): o insight da IA num cartão, com a
// espera DENTRO do cartão (a tela segue livre) e "Cancelar". Par do
// Ss::AiInsightCardComponent do web (mesmo desenho: selo "IA", título, texto,
// fontes recolhíveis, Aplicar/Ignorar e o estado "pensando").
import 'dart:async';

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../density.dart';
import '../skeleton.dart';
import '../ss_badge.dart';
import '../ss_button.dart';
import '../ss_card.dart';
import '../ss_strings.dart';
import '../v10/estrutura.dart' show SsCollapsible;
import '../v10/tela.dart' show SsSpinner;

/// Insight da IA (par do `Ss::AiInsightCardComponent`): selo "IA" com a
/// [confidence] e o [whenText], [title], o texto ([text] ou [child]), as
/// [sources] recolhidas em "De onde vem isso" e as ações [onApply]/[onDismiss].
///
/// Com [thinking] o cartão mostra a espera no lugar do conteúdo: roda, o
/// [thinkingText] ("Analisando seus dados…"), o aviso de que a tela continua
/// livre ([thinkingHint]), os segundos passando depois de [showElapsedAfter] e
/// "Cancelar" ([onCancel]: o app cancela a chamada, ex. o `CancelToken`). Nada
/// cobre a tela, então não use `ssRunBlocking` para a IA que explica.
///
/// ```dart
/// SsAiInsightCard(
///   title: 'Quer uma segunda opinião?',
///   text: _advice?.summary,
///   thinking: _explaining != null,
///   thinkingText: 'A IA está lendo a sugestão.',
///   onCancel: _cancelExplain,
///   applyLabel: 'Explicar com IA',
///   onApply: _advice == null ? _explain : null,
/// )
/// ```
class SsAiInsightCard extends StatefulWidget {
  const SsAiInsightCard({
    super.key,
    this.title,
    this.text,
    this.child,
    this.sources = const [],
    this.confidence,
    this.whenText,
    this.applyLabel,
    this.onApply,
    this.applyIcon,
    this.dismissLabel,
    this.onDismiss,
    this.thinking = false,
    this.thinkingText,
    this.thinkingHint,
    this.onCancel,
    this.cancelLabel,
    this.showElapsedAfter = const Duration(seconds: 5),
  });

  final String? title;

  /// Texto do insight (ou [child], que vence).
  final String? text;
  final Widget? child;

  /// Fontes/evidências ("42 lançamentos de outubro"), recolhidas.
  final List<String> sources;

  /// "alta", "média"… (fica ao lado do selo; some enquanto pensa).
  final String? confidence;

  /// "hoje, 9:12", "há 2 dias".
  final String? whenText;

  /// Ação principal (padrão [SsStrings.aiApply]); sem [onApply], não aparece.
  final String? applyLabel;
  final VoidCallback? onApply;
  final IconData? applyIcon;

  /// Ação discreta (padrão [SsStrings.aiDismiss]); sem [onDismiss], não aparece.
  final String? dismissLabel;
  final VoidCallback? onDismiss;

  /// A IA trabalhando: a espera aparece dentro do cartão.
  final bool thinking;

  /// Padrão [SsStrings.aiThinking].
  final String? thinkingText;

  /// Padrão [SsStrings.aiThinkingHint] ("Pode continuar usando a tela."); `''` tira.
  final String? thinkingHint;

  /// "Cancelar" na espera; nulo = sem o botão.
  final VoidCallback? onCancel;

  /// Padrão [SsStrings.cancel].
  final String? cancelLabel;

  /// A partir de quanto tempo os segundos aparecem ao lado do texto.
  final Duration showElapsedAfter;

  @override
  State<SsAiInsightCard> createState() => _SsAiInsightCardState();
}

class _SsAiInsightCardState extends State<SsAiInsightCard> {
  /// Segundos de espera (contados pelo tique: anda junto com o relógio dos testes).
  var _seg = 0;
  Timer? _tique;

  @override
  void initState() {
    super.initState();
    if (widget.thinking) _comeca();
  }

  @override
  void didUpdateWidget(SsAiInsightCard old) {
    super.didUpdateWidget(old);
    if (widget.thinking && !old.thinking) _comeca();
    if (!widget.thinking && old.thinking) _para();
  }

  void _comeca() {
    _seg = 0;
    _tique?.cancel();
    _tique = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seg++);
    });
  }

  void _para() {
    _tique?.cancel();
    _tique = null;
  }

  @override
  void dispose() {
    _tique?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    final w = widget;
    final cabeca = Wrap(
      spacing: d.space(8),
      runSpacing: d.space(4),
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SsBadge(s.aiBadge, icon: Icons.auto_awesome_rounded),
        if (w.confidence != null && !w.thinking)
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${s.aiConfidence} '),
                TextSpan(
                  text: w.confidence,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            style: TextStyle(fontSize: d.font(AppType.meta), color: c.muted),
          ),
        if (w.whenText != null)
          Text(
            w.whenText!,
            style: TextStyle(fontSize: d.font(AppType.meta), color: c.muted),
          ),
      ],
    );
    return SsCard(
      outline: c.accent.withValues(alpha: .4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          cabeca,
          SizedBox(height: d.space(10)),
          if (w.thinking) _esperando(context) else ..._conteudo(context),
        ],
      ),
    );
  }

  Widget _esperando(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    final w = widget;
    final seg = _seg;
    final texto = w.thinkingText ?? s.aiThinking;
    final mostra = Duration(seconds: seg) >= w.showElapsedAfter;
    final dica = w.thinkingHint ?? s.aiThinkingHint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SsSpinner(size: 18, semanticsLabel: texto),
            SizedBox(width: d.space(10)),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  mostra ? '$texto ($seg s)' : texto,
                  style: TextStyle(color: c.ink2, fontSize: d.font(AppType.sub), fontWeight: FontWeight.w600),
                ),
              ),
            ),
            if (w.onCancel != null) SsButton.text(label: w.cancelLabel ?? s.cancel, small: true, onPressed: w.onCancel),
          ],
        ),
        if (dica.isNotEmpty) ...[
          SizedBox(height: d.space(4)),
          Text(
            dica,
            style: TextStyle(color: c.muted, fontSize: d.font(AppType.meta)),
          ),
        ],
        SizedBox(height: d.space(10)),
        const ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FractionallySizedBox(widthFactor: .88, child: SkeletonBox(height: 10)),
              SizedBox(height: 8),
              FractionallySizedBox(widthFactor: .64, child: SkeletonBox(height: 10)),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _conteudo(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    final w = widget;
    final corpo = w.child ?? (w.text == null ? null : Text(w.text!));
    return [
      if (w.title != null)
        Semantics(
          header: true,
          child: Text(
            w.title!,
            style: TextStyle(fontSize: d.font(AppType.body), fontWeight: FontWeight.w800, color: c.ink),
          ),
        ),
      if (corpo != null) ...[
        if (w.title != null) SizedBox(height: d.space(6)),
        DefaultTextStyle.merge(
          style: TextStyle(fontSize: d.font(AppType.set), color: c.ink2, height: 1.45),
          child: corpo,
        ),
      ],
      if (w.sources.isNotEmpty) ...[
        SizedBox(height: d.space(8)),
        SsCollapsible(
          title: s.aiSources,
          count: w.sources.length,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final f in w.sources)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: d.space(3)),
                  child: Text(
                    '· $f',
                    style: TextStyle(fontSize: d.font(AppType.sub), color: c.ink2),
                  ),
                ),
            ],
          ),
        ),
      ],
      if (w.onApply != null || w.onDismiss != null) ...[
        SizedBox(height: d.space(12)),
        Wrap(
          spacing: d.space(8),
          runSpacing: d.space(8),
          children: [
            if (w.onApply != null)
              SsButton(
                label: w.applyLabel ?? s.aiApply,
                icon: w.applyIcon,
                small: true,
                expand: false,
                onPressed: w.onApply,
              ),
            if (w.onDismiss != null)
              SsButton.ghost(label: w.dismissLabel ?? s.aiDismiss, small: true, expand: false, onPressed: w.onDismiss),
          ],
        ),
      ],
    ];
  }
}
