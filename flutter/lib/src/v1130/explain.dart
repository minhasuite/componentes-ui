// v1.13.0 "confiança na IA e suíte": de onde vem este número (par do Ss::ExplainComponent). Envolve qualquer valor,
// KPI ou ponto de gráfico; o toque longo abre a folha com o valor, a fórmula, o que o compõe e o "Explicar com IA".
// O pacote só apresenta: os dados, os links e a IA são do produto (callbacks).
import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../ss_button.dart';
import '../ss_chat.dart';
import '../ss_sheet.dart';
import '../ss_strings.dart';
import 'strings.dart';

/// Um item que compõe o valor ("Mercado Bom Preço · R$ 214,90"), com [onTap] para abrir o registro.
class SsExplainItem {
  const SsExplainItem(this.label, this.value, {this.subtitle, this.onTap});

  final String label;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;
}

/// Envolve um valor (KPI, total, ponto de gráfico) para explicar de onde ele vem: o toque longo (e a ação "Ver de onde
/// vem este valor" do leitor de tela) abre a folha [SsExplainPanel].
///
/// ```dart
/// SsExplain(
///   value: money(total), title: 'Gastos de novembro', formula: 'Soma dos 23 lançamentos de nov',
///   items: [for (final l in top) SsExplainItem(l.descricao, money(l.valor), onTap: () => abrir(l))],
///   more: 18, onMore: verTodos,
///   onAskAi: () => api.explicar('gastos-nov'), // Future<String>; o pacote mostra o SsThinking e deixa cancelar
///   child: SsKpiCard(...),
/// )
/// ```
class SsExplain extends StatelessWidget {
  const SsExplain({
    super.key,
    required this.child,
    required this.value,
    this.title,
    this.formula,
    this.items = const [],
    this.more = 0,
    this.onMore,
    this.onAskAi,
    this.onCancelAi,
    this.enabled = true,
  });

  final Widget child;

  /// O valor como aparece ("R$ 1.240,00", "72%").
  final String value;
  final String? title;

  /// A fórmula ou a origem em uma frase ("Soma dos 23 lançamentos de nov").
  final String? formula;
  final List<SsExplainItem> items;

  /// Quantos itens ficaram fora da lista ("e mais 18").
  final int more;

  /// "Ver todos" (a lista completa é do app).
  final VoidCallback? onMore;

  /// "Explicar com IA": devolve o texto. Enquanto espera, o [SsThinking] com "Cancelar".
  final Future<String> Function()? onAskAi;

  /// Chamado ao cancelar a IA (o app cancela a requisição; a resposta que chegar depois é descartada).
  final VoidCallback? onCancelAi;
  final bool enabled;

  Future<void> open(BuildContext context) => showSsExplain(
    context,
    value: value,
    title: title,
    formula: formula,
    items: items,
    more: more,
    onMore: onMore,
    onAskAi: onAskAi,
    onCancelAi: onCancelAi,
  );

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final t = SsTrustStrings.of(context);
    return Semantics(
      hint: t.explainHint,
      customSemanticsActions: {CustomSemanticsAction(label: t.explainOpen): () => open(context)},
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: () {
          SsHaptics.selection();
          open(context);
        },
        child: child,
      ),
    );
  }
}

/// Abre a folha que explica o valor (o que o [SsExplain] abre no toque longo).
Future<void> showSsExplain(
  BuildContext context, {
  required String value,
  String? title,
  String? formula,
  List<SsExplainItem> items = const [],
  int more = 0,
  VoidCallback? onMore,
  Future<String> Function()? onAskAi,
  VoidCallback? onCancelAi,
}) => showSsSheet<void>(
  context,
  title: title ?? SsTrustStrings.of(context).explainTitle,
  icon: Icons.manage_search_rounded,
  child: SsExplainPanel(
    value: value,
    formula: formula,
    items: items,
    more: more,
    onMore: onMore,
    onAskAi: onAskAi,
    onCancelAi: onCancelAi,
  ),
);

enum _Ai { idle, thinking, done, error }

/// O corpo da explicação: o valor grande, a fórmula, a lista do que compõe e o "Explicar com IA". Vai na folha do
/// [showSsExplain] ou solto numa tela de detalhe.
class SsExplainPanel extends StatefulWidget {
  const SsExplainPanel({
    super.key,
    required this.value,
    this.formula,
    this.items = const [],
    this.more = 0,
    this.onMore,
    this.onAskAi,
    this.onCancelAi,
    this.aiAnswer,
  });

  final String value;
  final String? formula;
  final List<SsExplainItem> items;
  final int more;
  final VoidCallback? onMore;
  final Future<String> Function()? onAskAi;
  final VoidCallback? onCancelAi;

  /// A explicação que o app já tem (guardada de antes): o painel abre com ela, sem pedir de novo.
  final String? aiAnswer;

  @override
  State<SsExplainPanel> createState() => _SsExplainPanelState();
}

class _SsExplainPanelState extends State<SsExplainPanel> {
  late var _ai = widget.aiAnswer == null ? _Ai.idle : _Ai.done;
  late String? _text = widget.aiAnswer;
  var _round = 0;

  Future<void> _ask() async {
    final round = ++_round;
    setState(() => _ai = _Ai.thinking);
    try {
      final text = await widget.onAskAi!();
      if (!mounted || round != _round) return;
      setState(() {
        _text = text;
        _ai = _Ai.done;
      });
    } catch (_) {
      if (!mounted || round != _round) return;
      setState(() => _ai = _Ai.error);
    }
  }

  void _cancel() {
    _round++;
    widget.onCancelAi?.call();
    setState(() => _ai = _Ai.idle);
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final t = SsTrustStrings.of(context);
    final s = SsStrings.of(context);
    final dur = reduceMotion(context) ? Duration.zero : SsMotion.medium;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            widget.value,
            style: AppTheme.number(context, size: AppType.statNum, color: c.ink),
          ),
        ),
        if (widget.formula != null) ...[
          SizedBox(height: d.space(4)),
          Text(
            widget.formula!,
            style: TextStyle(fontSize: AppType.sub, color: c.muted, height: AppType.leading),
          ),
        ],
        if (widget.items.isNotEmpty) ...[
          SizedBox(height: d.space(16)),
          Text(
            t.explainComposition.toUpperCase(),
            style: TextStyle(
              fontSize: AppType.label,
              fontWeight: FontWeight.w800,
              letterSpacing: AppType.trackingCaps,
              color: c.muted,
            ),
          ),
          SizedBox(height: d.space(4)),
          for (final it in widget.items) _ItemRow(it),
          if (widget.more > 0 || widget.onMore != null)
            Padding(
              padding: EdgeInsets.only(top: d.space(4)),
              child: Row(
                children: [
                  if (widget.more > 0)
                    Expanded(
                      child: Text(
                        SsTrustStrings.fill(t.explainMore, {'count': widget.more}),
                        style: TextStyle(fontSize: AppType.sub, color: c.muted),
                      ),
                    )
                  else
                    const Spacer(),
                  if (widget.onMore != null)
                    SsButton.text(label: t.explainSeeAll, onPressed: widget.onMore, trailingIcon: Icons.chevron_right),
                ],
              ),
            ),
        ],
        if (widget.onAskAi != null || _ai == _Ai.done) ...[
          SizedBox(height: d.space(16)),
          AnimatedSize(
            duration: dur,
            curve: SsMotion.standard,
            alignment: Alignment.topCenter,
            child: switch (_ai) {
              _Ai.idle => SsButton.ghost(label: t.explainAskAi, icon: Icons.auto_awesome_outlined, onPressed: _ask),
              _Ai.thinking => Row(
                children: [
                  Expanded(child: SsThinking(text: t.explainThinking)),
                  SsButton.text(label: s.cancel, onPressed: _cancel),
                ],
              ),
              _Ai.done => _AiAnswer(text: _text ?? '', note: t.explainAiNote),
              _Ai.error => Semantics(
                liveRegion: true,
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, size: 18, color: c.dangerText),
                    SizedBox(width: d.space(8)),
                    Expanded(
                      child: Text(
                        t.explainAiError,
                        style: TextStyle(fontSize: AppType.sub, color: c.dangerText),
                      ),
                    ),
                    SsButton.text(label: t.explainRetry, onPressed: _ask),
                  ],
                ),
              ),
            },
          ),
        ],
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow(this.item);
  final SsExplainItem item;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final row = ConstrainedBox(
      constraints: BoxConstraints(minHeight: d.minTarget),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: d.space(6)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: AppType.set, fontWeight: FontWeight.w600, color: c.ink),
                  ),
                  if (item.subtitle != null)
                    Text(
                      item.subtitle!,
                      style: TextStyle(fontSize: AppType.meta, color: c.muted),
                    ),
                ],
              ),
            ),
            SizedBox(width: d.space(12)),
            Text(
              item.value,
              style: AppTheme.number(context, size: AppType.set, color: c.ink),
            ),
            if (item.onTap != null) ...[
              SizedBox(width: d.space(4)),
              Icon(Icons.chevron_right, size: 18, color: c.muted),
            ],
          ],
        ),
      ),
    );
    if (item.onTap == null) return MergeSemantics(child: row);
    return Semantics(
      button: true,
      child: InkWell(borderRadius: BorderRadius.circular(AppRadius.field), onTap: item.onTap, child: row),
    );
  }
}

class _AiAnswer extends StatelessWidget {
  const _AiAnswer({required this.text, required this.note});
  final String text;
  final String note;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: EdgeInsets.all(d.space(14)),
        decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(AppRadius.field)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SsAiMark(),
            SizedBox(width: d.space(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(fontSize: AppType.set, color: c.ink, height: AppType.leading),
                  ),
                  SizedBox(height: d.space(6)),
                  Text(
                    note,
                    style: TextStyle(fontSize: AppType.meta, color: c.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
