// v1.13.0 "confiança na IA e suíte": antes de a IA aplicar uma mudança, o antes e depois campo a campo (par do
// Ss::AiActionPreviewComponent). Várias alterações, cada uma com marcar/desmarcar; Aplicar, Ajustar e Cancelar; depois
// de aplicar, o aviso com "Desfazer" (showSsUndo). O pacote só apresenta: aplicar e desfazer são do app.
import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../ss_badge.dart';
import '../ss_button.dart';
import '../ss_sheet.dart';
import '../ss_toast.dart';
import 'strings.dart';

/// O que aconteceu com o campo.
enum SsDiffKind { added, removed, changed, same }

/// Um campo da alteração: o valor de antes e o de depois, já formatados (nulo ou vazio = não havia / não haverá).
class SsFieldDiff {
  const SsFieldDiff(this.label, {this.before, this.after});

  final String label;
  final String? before;
  final String? after;

  SsDiffKind get kind => SsAiActionPreview.kindOf(before, after);
}

/// Uma alteração que a IA propõe (um registro): [title] ("Lançamento · Mercado Bom Preço"), os [fields] e se começa
/// marcada.
class SsAiChange {
  const SsAiChange({
    required this.id,
    required this.title,
    this.subtitle,
    this.fields = const [],
    this.selected = true,
  });

  final String id;
  final String title;
  final String? subtitle;
  final List<SsFieldDiff> fields;
  final bool selected;
}

/// A prévia da ação da IA: cada alteração com a caixa de marcar e os campos em "antes → depois", com as cores
/// semânticas (removido em vermelho e riscado, novo em verde, alterado em âmbar) e o nome do que aconteceu escrito (a
/// cor nunca é o único sinal). Campos iguais não aparecem.
///
/// ```dart
/// SsAiActionPreview(
///   changes: sugestoes,                                   // List<SsAiChange>
///   onApply: (marcadas) => api.aplicar(marcadas),          // Future: o botão fica carregando
///   onUndo: (marcadas) => api.desfazer(marcadas),          // com ele, o aviso "3 alterações aplicadas · Desfazer"
///   onAdjust: voltarAoChat, onCancel: fechar,
/// )
/// ```
/// Na folha: [showSsAiActionPreview]. No chat: `SsChatActionCard(onReview: () => showSsAiActionPreview(...))`.
class SsAiActionPreview extends StatefulWidget {
  const SsAiActionPreview({
    super.key,
    required this.changes,
    this.onApply,
    this.onUndo,
    this.onAdjust,
    this.onCancel,
    this.title,
    this.subtitle,
    this.applyLabel,
    this.header = true,
  });

  final List<SsAiChange> changes;

  /// Recebe as marcadas. Enquanto o Future não volta, "Aplicar" fica carregando.
  final Future<void> Function(List<SsAiChange> selected)? onApply;

  /// Com ele, depois de aplicar, o aviso com "Desfazer"; chamado se a pessoa desfez.
  final void Function(List<SsAiChange> selected)? onUndo;
  final VoidCallback? onAdjust;
  final VoidCallback? onCancel;
  final String? title;
  final String? subtitle;
  final String? applyLabel;

  /// Título e subtítulo no topo (a folha do [showSsAiActionPreview] já tem o dela).
  final bool header;

  /// O que aconteceu com o campo: sem antes = novo; sem depois = removido; iguais = igual.
  static SsDiffKind kindOf(String? before, String? after) {
    final b = (before ?? '').trim(), a = (after ?? '').trim();
    if (b == a) return SsDiffKind.same;
    if (b.isEmpty) return SsDiffKind.added;
    if (a.isEmpty) return SsDiffKind.removed;
    return SsDiffKind.changed;
  }

  @override
  State<SsAiActionPreview> createState() => _SsAiActionPreviewState();
}

class _SsAiActionPreviewState extends State<SsAiActionPreview> {
  late Set<String> _on = {
    for (final c in widget.changes)
      if (c.selected) c.id,
  };
  var _busy = false;

  @override
  void didUpdateWidget(SsAiActionPreview old) {
    super.didUpdateWidget(old);
    if (old.changes != widget.changes) {
      final ids = {for (final c in widget.changes) c.id};
      _on = _on.intersection(ids);
    }
  }

  List<SsAiChange> get _selected => [
    for (final c in widget.changes)
      if (_on.contains(c.id)) c,
  ];

  Future<void> _apply() async {
    final sel = _selected;
    if (sel.isEmpty || widget.onApply == null) return;
    setState(() => _busy = true);
    try {
      await widget.onApply!(sel);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted || widget.onUndo == null) return;
    final t = SsTrustStrings.of(context);
    final msg = sel.length == 1 ? t.previewAppliedOne : SsTrustStrings.fill(t.previewApplied, {'count': sel.length});
    if (await showSsUndo(context, msg, icon: Icons.auto_awesome_outlined)) widget.onUndo!(sel);
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final t = SsTrustStrings.of(context);
    final total = widget.changes.length;
    final all = _on.length == total;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.header) ...[
          Semantics(
            header: true,
            child: Text(
              widget.title ?? t.previewTitle,
              style: TextStyle(fontSize: AppType.lg, fontWeight: FontWeight.w800, color: c.ink),
            ),
          ),
          SizedBox(height: d.space(4)),
          Text(
            widget.subtitle ?? t.previewSubtitle,
            style: TextStyle(fontSize: AppType.sub, color: c.muted),
          ),
          SizedBox(height: d.space(12)),
        ],
        if (total > 1)
          Row(
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    SsTrustStrings.fill(t.previewSelected, {'count': _on.length, 'total': total}),
                    style: TextStyle(fontSize: AppType.sub, fontWeight: FontWeight.w600, color: c.ink2),
                  ),
                ),
              ),
              SsButton.text(
                label: all ? t.previewSelectNone : t.previewSelectAll,
                onPressed: _busy
                    ? null
                    : () => setState(() => _on = all ? <String>{} : {for (final x in widget.changes) x.id}),
              ),
            ],
          ),
        for (final ch in widget.changes) ...[
          SizedBox(height: d.space(8)),
          _ChangeCard(
            change: ch,
            selected: _on.contains(ch.id),
            onChanged: _busy ? null : (v) => setState(() => v ? _on.add(ch.id) : _on.remove(ch.id)),
          ),
        ],
        SizedBox(height: d.space(12)),
        if (_on.isEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: d.space(8)),
            child: Semantics(
              liveRegion: true,
              child: Text(
                t.previewNone,
                style: TextStyle(fontSize: AppType.sub, color: c.aquecText),
              ),
            ),
          ),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: d.space(8),
          runSpacing: d.space(8),
          children: [
            if (widget.onCancel != null)
              SsButton.text(label: t.previewCancel, onPressed: _busy ? null : widget.onCancel),
            if (widget.onAdjust != null)
              SsButton.ghost(label: t.previewAdjust, expand: false, onPressed: _busy ? null : widget.onAdjust),
            SsButton(
              label: _on.isNotEmpty && _on.length < total
                  ? '${widget.applyLabel ?? t.previewApply} (${_on.length})'
                  : widget.applyLabel ?? t.previewApply,
              icon: Icons.check_rounded,
              expand: false,
              loading: _busy,
              onPressed: _on.isEmpty || widget.onApply == null ? null : _apply,
            ),
          ],
        ),
      ],
    );
  }
}

class _ChangeCard extends StatelessWidget {
  const _ChangeCard({required this.change, required this.selected, required this.onChanged});
  final SsAiChange change;
  final bool selected;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final t = SsTrustStrings.of(context);
    final dur = reduceMotion(context) ? Duration.zero : SsMotion.short;
    final fields = [
      for (final f in change.fields)
        if (f.kind != SsDiffKind.same) f,
    ];
    return AnimatedOpacity(
      duration: dur,
      opacity: selected ? 1 : .62,
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.field + 4),
          border: Border.all(color: selected ? Color.alphaBlend(c.accent.withValues(alpha: .45), c.line) : c.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              checked: selected,
              label: SsTrustStrings.fill(t.previewInclude, {'title': change.title}),
              onTap: onChanged == null ? null : () => onChanged!(!selected),
              excludeSemantics: true,
              child: InkWell(
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.field + 4)),
                onTap: onChanged == null ? null : () => onChanged!(!selected),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: d.minTarget),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(d.space(12), d.space(10), d.space(12), d.space(6)),
                    child: Row(
                      children: [
                        SsCheckBox(value: selected, size: 22, burst: false),
                        SizedBox(width: d.space(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                change.title,
                                style: TextStyle(fontSize: AppType.set, fontWeight: FontWeight.w800, color: c.ink),
                              ),
                              if (change.subtitle != null)
                                Text(
                                  change.subtitle!,
                                  style: TextStyle(fontSize: AppType.meta, color: c.muted),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(d.space(12), 0, d.space(12), d.space(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [for (final f in fields) _FieldRow(f)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow(this.f);
  final SsFieldDiff f;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final t = SsTrustStrings.of(context);
    final (kindLabel, variant, tone) = switch (f.kind) {
      SsDiffKind.added => (t.previewAdded, SsBadgeVariant.success, SsTone.success),
      SsDiffKind.removed => (t.previewRemoved, SsBadgeVariant.danger, SsTone.danger),
      _ => (t.previewChanged, SsBadgeVariant.warning, SsTone.warning),
    };
    final red = SsTone.danger.colors(context), green = SsTone.success.colors(context);
    Widget chip(String text, ({Color text, Color soft, Color solid}) tone, {bool strike = false}) => Container(
      padding: EdgeInsets.symmetric(horizontal: d.space(8), vertical: d.space(4)),
      decoration: BoxDecoration(color: tone.soft, borderRadius: BorderRadius.circular(AppRadius.thumb)),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppType.sub,
          color: tone.text,
          fontWeight: FontWeight.w600,
          decoration: strike ? TextDecoration.lineThrough : null,
          decorationColor: tone.text,
        ),
      ),
    );
    final before = (f.before ?? '').trim(), after = (f.after ?? '').trim();
    final spoken = [
      f.label,
      kindLabel,
      if (before.isNotEmpty) '${t.previewBefore}: $before',
      if (after.isNotEmpty) '${t.previewAfter}: $after',
    ].join('. ');
    return Semantics(
      label: spoken,
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.only(top: d.space(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    f.label,
                    style: TextStyle(fontSize: AppType.meta, fontWeight: FontWeight.w700, color: c.muted),
                  ),
                ),
                SizedBox(width: d.space(8)),
                SsBadge(kindLabel, variant: variant, micro: true),
              ],
            ),
            SizedBox(height: d.space(4)),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: d.space(6),
              runSpacing: d.space(4),
              children: [
                if (before.isNotEmpty) chip(before, red, strike: true),
                if (before.isNotEmpty && after.isNotEmpty) Icon(Icons.arrow_forward_rounded, size: 16, color: c.muted),
                if (after.isNotEmpty) chip(after, f.kind == SsDiffKind.changed ? tone.colors(context) : green),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Abre a prévia numa folha. Devolve as marcadas que a pessoa aplicou (ou nulo se cancelou). Com [onApply], chama
/// depois de fechar e, com [onUndo], mostra o aviso com "Desfazer".
Future<List<SsAiChange>?> showSsAiActionPreview(
  BuildContext context, {
  required List<SsAiChange> changes,
  Future<void> Function(List<SsAiChange> selected)? onApply,
  void Function(List<SsAiChange> selected)? onUndo,
  VoidCallback? onAdjust,
  String? title,
  String? subtitle,
}) async {
  final t = SsTrustStrings.of(context);
  final sel = await showSsSheet<List<SsAiChange>>(
    context,
    title: title ?? t.previewTitle,
    subtitle: subtitle ?? t.previewSubtitle,
    icon: Icons.auto_awesome_outlined,
    child: Builder(
      builder: (sheet) => SsAiActionPreview(
        changes: changes,
        header: false,
        onApply: (s) async => Navigator.of(sheet).pop(s),
        onCancel: () => Navigator.of(sheet).pop(),
        onAdjust: onAdjust == null
            ? null
            : () {
                Navigator.of(sheet).pop();
                onAdjust();
              },
      ),
    ),
  );
  if (sel == null || !context.mounted) return sel;
  if (onApply != null) await onApply(sel);
  if (onUndo != null && context.mounted) {
    final msg = sel.length == 1 ? t.previewAppliedOne : SsTrustStrings.fill(t.previewApplied, {'count': sel.length});
    if (await showSsUndo(context, msg, icon: Icons.auto_awesome_outlined)) onUndo(sel);
  }
  return sel;
}
