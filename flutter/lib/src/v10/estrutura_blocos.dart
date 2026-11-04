// v0.10 (estrutura): lista de blocos (núcleo genérico de um editor de
// automação) e grupo recolhível.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../motion.dart';
import '../ss_badge.dart';
import '../ss_dialogs.dart' show showSsConfirm;
import '../ss_fields.dart';
import '../ss_menu.dart';
import '../ss_strings.dart';

/// Abre e fecha a altura com a mola da suíte (passa um tiquinho e assenta);
/// fecha sem mola. Com "reduzir movimento", troca direto.
class SsSpringReveal extends StatefulWidget {
  const SsSpringReveal({super.key, required this.expanded, required this.child});
  final bool expanded;
  final Widget child;

  @override
  State<SsSpringReveal> createState() => _SsSpringRevealState();
}

class _SsSpringRevealState extends State<SsSpringReveal> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, value: widget.expanded ? 1 : 0, duration: SsMotion.slow);

  @override
  void didUpdateWidget(SsSpringReveal old) {
    super.didUpdateWidget(old);
    if (old.expanded == widget.expanded) return;
    if (reduceMotion(context)) {
      _c.value = widget.expanded ? 1 : 0;
    } else if (widget.expanded) {
      _c.duration = const Duration(milliseconds: 460);
      _c.forward();
    } else {
      _c.duration = SsMotion.fast;
      _c.reverse();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) {
      final abrindo = _c.status == AnimationStatus.forward || _c.status == AnimationStatus.completed;
      final v = abrindo ? SsMotion.bounce.transform(_c.value) : Curves.easeOutCubic.transform(_c.value);
      return Visibility(
        visible: _c.value > 0,
        maintainState: true,
        child: ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: math.max(0, v),
            child: Opacity(opacity: _c.value.clamp(0, 1), child: child),
          ),
        ),
      );
    },
    child: widget.child,
  );
}

// ──────────────────────────────────────────────────────── lista de blocos

/// Um bloco do [SsBlockList] (gatilho, condição, ação…). Pode ter filhos.
class SsBlock {
  const SsBlock({
    required this.id,
    required this.title,
    this.icon = Icons.extension_outlined,
    this.summary,
    this.enabled = true,
    this.error,
    this.tone = SsTone.accent,
    this.body,
    this.children = const [],
    this.initiallyExpanded = false,
    this.duplicable = true,
  });

  final String id;
  final String title;
  final IconData icon;

  /// Resumo de uma linha ("Quando a porta abrir depois das 22h").
  final String? summary;

  /// Desligado: o bloco fica apagado (ainda editável).
  final bool enabled;

  /// Erro de validação: borda vermelha e a mensagem embaixo do cabeçalho.
  final String? error;

  /// Tom do ícone (gatilho, condição, ação com cores diferentes).
  final SsTone tone;

  /// O formulário do bloco (do app).
  final Widget? body;

  /// Blocos aninhados (dentro de um "se", de um "repetir").
  final List<SsBlock> children;
  final bool initiallyExpanded;

  /// Falso tira "Duplicar" do ⋮ só deste bloco (gatilho único, por exemplo).
  final bool duplicable;
}

/// Textos do [SsBlockList]; o que ficar nulo vem do [SsStrings] do idioma.
class SsBlockListLabels {
  const SsBlockListLabels({
    this.moveUp,
    this.moveDown,
    this.duplicate,
    this.delete,
    this.enabled,
    this.expand,
    this.collapse,
    this.drag,
    this.more,
  });
  final String? moveUp, moveDown, duplicate, delete, enabled, expand, collapse, drag, more;

  /// Todos preenchidos: o que veio nulo sai de [s].
  SsBlockListLabels resolve(SsStrings s) => SsBlockListLabels(
    moveUp: moveUp ?? s.moveUp,
    moveDown: moveDown ?? s.moveDown,
    duplicate: duplicate ?? s.duplicate,
    delete: delete ?? s.delete,
    enabled: enabled ?? s.enabled,
    expand: expand ?? s.expand,
    collapse: collapse ?? s.collapse,
    drag: drag ?? s.dragToReorder,
    more: more ?? s.moreOptions,
  );
}

/// Lista ordenada de blocos recolhíveis (o núcleo genérico de um editor de
/// automação). Cada bloco: ícone, resumo, liga/desliga, mover (setas no menu e
/// arrastar pela alça), duplicar e excluir no ⋮, e o corpo do app. Aninha.
///
/// [onMove] recebe o bloco e o novo índice entre os irmãos.
class SsBlockList extends StatefulWidget {
  const SsBlockList({
    super.key,
    required this.blocks,
    this.onToggle,
    this.onMove,
    this.onDuplicate,
    this.onDelete,
    this.focusedId,
    this.draggable = true,
    this.labels = const SsBlockListLabels(),
    this.deleteConfirm,
  });

  final List<SsBlock> blocks;
  final void Function(SsBlock block, bool enabled)? onToggle;
  final void Function(SsBlock block, int to)? onMove;
  final ValueChanged<SsBlock>? onDuplicate;
  final ValueChanged<SsBlock>? onDelete;

  /// Bloco em foco (anel na cor da marca).
  final String? focusedId;

  /// Alça de arrastar (precisa de [onMove]).
  final bool draggable;
  final SsBlockListLabels labels;

  /// Pergunta antes de excluir (diálogo de perigo com o título do bloco e
  /// este texto); nulo = exclui direto (o app pode oferecer "Desfazer").
  final String? deleteConfirm;

  @override
  State<SsBlockList> createState() => _SsBlockListState();
}

class _SsBlockListState extends State<SsBlockList> {
  late final Map<String, bool> _aberto = {for (final b in widget.blocks) b.id: b.initiallyExpanded};

  bool _isOpen(SsBlock b) => _aberto[b.id] ?? b.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final arrasta = widget.draggable && widget.onMove != null && widget.blocks.length > 1;
    Widget item(int i) {
      final b = widget.blocks[i];
      return Padding(
        key: ValueKey(b.id),
        padding: const EdgeInsets.only(bottom: 8),
        child: _BlocoView(
          block: b,
          index: i,
          count: widget.blocks.length,
          open: _isOpen(b),
          focused: widget.focusedId == b.id,
          dragHandle: arrasta,
          onOpen: (v) => setState(() => _aberto[b.id] = v),
          list: widget,
        ),
      );
    }

    if (!arrasta) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (var i = 0; i < widget.blocks.length; i++) item(i)],
      );
    }
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      proxyDecorator: (child, i, a) => AnimatedBuilder(
        animation: a,
        builder: (context, child) => Transform.scale(scale: 1 + .02 * Curves.easeOut.transform(a.value), child: child),
        child: Material(color: Colors.transparent, child: child),
      ),
      // onReorderItem já desconta o item tirado do índice novo.
      onReorderItem: (de, para) {
        if (para != de) widget.onMove!(widget.blocks[de], para);
      },
      children: [for (var i = 0; i < widget.blocks.length; i++) item(i)],
    );
  }
}

class _BlocoView extends StatelessWidget {
  const _BlocoView({
    required this.block,
    required this.index,
    required this.count,
    required this.open,
    required this.focused,
    required this.dragHandle,
    required this.onOpen,
    required this.list,
  });
  final SsBlock block;
  final int index;
  final int count;
  final bool open;
  final bool focused;
  final bool dragHandle;
  final ValueChanged<bool> onOpen;
  final SsBlockList list;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final b = block;
    final l = list.labels.resolve(SsStrings.of(context));
    final t = b.tone.colors(context);
    final invalido = b.error != null;
    final rm = reduceMotion(context);
    final temCorpo = b.body != null || b.children.isNotEmpty;
    final borda = invalido
        ? Border.all(color: AppColors.danger, width: 1.5)
        : focused
        ? Border.all(color: c.accent, width: 2)
        : Border.all(color: c.line);

    final menu = [
      if (list.onMove != null && index > 0)
        SsMenuAction(Icons.arrow_upward_rounded, l.moveUp!, () => list.onMove!(b, index - 1)),
      if (list.onMove != null && index < count - 1)
        SsMenuAction(Icons.arrow_downward_rounded, l.moveDown!, () => list.onMove!(b, index + 1)),
      if (list.onDuplicate != null && b.duplicable)
        SsMenuAction(Icons.copy_rounded, l.duplicate!, () => list.onDuplicate!(b)),
      if (list.onDelete != null)
        SsMenuAction(Icons.delete_outline_rounded, l.delete!, () async {
          final pergunta = list.deleteConfirm;
          if (pergunta != null) {
            final ok = await showSsConfirm(
              context,
              title: b.title,
              message: pergunta,
              confirmLabel: l.delete,
              danger: true,
              icon: Icons.delete_outline_rounded,
            );
            if (!ok) return;
          }
          list.onDelete!(b);
        }, destructive: true),
    ];

    return AnimatedContainer(
      duration: rm ? Duration.zero : SsMotion.fast,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.field + 2),
        border: borda,
        boxShadow: focused ? [BoxShadow(color: c.accent.withValues(alpha: .18), blurRadius: 0, spreadRadius: 3)] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: temCorpo,
            expanded: temCorpo ? open : null,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.field + 2),
              onTap: temCorpo ? () => onOpen(!open) : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
                child: Row(
                  children: [
                    if (dragHandle)
                      ReorderableDragStartListener(
                        index: index,
                        child: Tooltip(
                          message: l.drag!,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            child: Icon(Icons.drag_indicator_rounded, size: 20, color: c.muted2),
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 8),
                    Opacity(
                      opacity: b.enabled ? 1 : .45,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(color: t.soft, borderRadius: BorderRadius.circular(10)),
                        child: Icon(b.icon, size: 19, color: t.text),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Opacity(
                        opacity: b.enabled ? 1 : .5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: c.ink, fontWeight: FontWeight.w800, fontSize: AppType.set),
                            ),
                            if (b.summary != null)
                              Text(
                                b.summary!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: c.muted, fontSize: AppType.meta),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (list.onToggle != null)
                      Semantics(
                        label: '${l.enabled}: ${b.title}',
                        child: SsSwitch(value: b.enabled, onChanged: (v) => list.onToggle!(b, v)),
                      ),
                    if (menu.isNotEmpty) SsOverflowMenu(items: menu, tooltip: l.more!),
                    if (temCorpo)
                      IconButton(
                        tooltip: open ? l.collapse! : l.expand!,
                        onPressed: () => onOpen(!open),
                        visualDensity: VisualDensity.compact,
                        icon: AnimatedRotation(
                          turns: open ? .5 : 0,
                          duration: rm ? Duration.zero : SsMotion.base,
                          curve: SsMotion.bounce,
                          child: Icon(Icons.expand_more_rounded, color: c.muted),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (invalido)
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, size: 15, color: c.dangerText),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        b.error!,
                        style: TextStyle(color: c.dangerText, fontSize: AppType.meta, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (temCorpo)
            SsSpringReveal(
              expanded: open,
              child: Opacity(
                opacity: b.enabled ? 1 : .55,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: c.line)),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (b.body != null) Padding(padding: const EdgeInsets.only(bottom: 10), child: b.body!),
                      if (b.children.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.only(left: 10),
                          decoration: BoxDecoration(
                            border: Border(left: BorderSide(color: t.solid.withValues(alpha: .4), width: 2)),
                          ),
                          child: SsBlockList(
                            blocks: b.children,
                            onToggle: list.onToggle,
                            onMove: list.onMove,
                            onDuplicate: list.onDuplicate,
                            onDelete: list.onDelete,
                            focusedId: list.focusedId,
                            draggable: list.draggable,
                            labels: list.labels,
                            deleteConfirm: list.deleteConfirm,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── grupo recolhível

/// Grupo recolhível: cabeçalho com seta, contagem e um selo colorido opcional;
/// o corpo abre com a mola. `SsCollapsible(title: 'Sala', count: 6, child: ...)`
class SsCollapsible extends StatefulWidget {
  const SsCollapsible({
    super.key,
    required this.title,
    required this.child,
    this.count,
    this.label,
    this.labelTone = SsTone.accent,
    this.icon,
    this.initiallyExpanded = false,
    this.onChanged,
    this.expandLabel,
    this.collapseLabel,
  });

  final String title;
  final Widget child;

  /// Quantos itens tem dentro (pílula ao lado do título).
  final int? count;

  /// Selo colorido ("3 ligados", "Offline").
  final String? label;
  final SsTone labelTone;
  final IconData? icon;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onChanged;
  final String? expandLabel;
  final String? collapseLabel;

  @override
  State<SsCollapsible> createState() => _SsCollapsibleState();
}

class _SsCollapsibleState extends State<SsCollapsible> {
  SsStrings get _s => SsStrings.of(context);
  late bool _open = widget.initiallyExpanded;

  void _toggle() {
    SsHaptics.tick();
    setState(() => _open = !_open);
    widget.onChanged?.call(_open);
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final rm = reduceMotion(context);
    final t = widget.labelTone.colors(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          hint: _open ? widget.collapseLabel ?? _s.collapse : widget.expandLabel ?? _s.expand,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.field),
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _open ? .25 : 0,
                    duration: rm ? Duration.zero : SsMotion.base,
                    curve: SsMotion.bounce,
                    child: Icon(Icons.chevron_right_rounded, color: c.muted),
                  ),
                  const SizedBox(width: 4),
                  if (widget.icon != null) ...[Icon(widget.icon, size: 18, color: c.ink2), const SizedBox(width: 6)],
                  Flexible(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.ink, fontWeight: FontWeight.w800, fontSize: AppType.md),
                    ),
                  ),
                  if (widget.count != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(AppRadius.pill)),
                      child: Text(
                        '${widget.count}',
                        style: AppTheme.number(context, size: AppType.label, color: c.muted, weight: FontWeight.w600),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (widget.label != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(color: t.soft, borderRadius: BorderRadius.circular(AppRadius.pill)),
                      child: Text(
                        widget.label!,
                        style: TextStyle(color: t.text, fontSize: AppType.label, fontWeight: FontWeight.w800),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        SsSpringReveal(
          expanded: _open,
          child: Padding(padding: const EdgeInsets.fromLTRB(6, 2, 6, 8), child: widget.child),
        ),
      ],
    );
  }
}
