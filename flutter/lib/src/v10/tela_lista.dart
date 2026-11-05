// v0.10.2 (tela): linhas em card, lista de arrastar para ordenar, zona de
// perigo, aviso em linha, bloco de código, grupo de botões de comando,
// passo numerado e divisor com texto. Pares no web: .ss-rows,
// Ss::SortableListComponent (.ss-sortable), .ss-danger-zone, .ss-callout
// (Ss::CalloutComponent), .ss-code (Ss::CodeBlockComponent), .ss-btn-group,
// .ss-steps/.ss-steps-head e .ss-divider.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_theme.dart';
import '../motion.dart';
import '../ss_badge.dart' show SsTone;
import '../ss_card.dart';
import '../ss_rows.dart' show SsDashedDivider;
import '../ss_strings.dart';
import 'tela_barra.dart';

/// Linhas de uma lista dentro de um card, separadas por um fio (o `.ss-rows`
/// do web). Bom para [SsListItem], [SsSwitchRow] e linhas montadas no app.
/// [indent] recua o fio (alinhar com o texto depois do ícone); [card] falso
/// tira o card (as linhas ficam soltas, só com os fios).
class SsRows extends StatelessWidget {
  const SsRows({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    this.indent = 0,
    this.card = true,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final double indent;
  final bool card;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final col = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) Divider(height: 1, thickness: 1, indent: indent, color: c.line),
          children[i],
        ],
      ],
    );
    return card ? SsCard(padding: padding, child: col) : Padding(padding: padding, child: col);
  }
}

/// Alça de arrastar de uma linha da [SsReorderableList]: alvo de 48 dp, o
/// ícone ⠿ e a dica "Arrastar para reordenar" ([SsStrings.dragToReorder]).
class SsDragHandle extends StatelessWidget {
  const SsDragHandle({super.key, required this.index, this.enabled = true});

  /// Posição da linha na lista.
  final int index;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final icone = Tooltip(
      message: SsStrings.of(context).dragToReorder,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.grab : SystemMouseCursors.basic,
        child: SizedBox.square(
          dimension: 40,
          child: Icon(Icons.drag_indicator_rounded, color: enabled ? c.muted : c.muted2),
        ),
      ),
    );
    return enabled ? ReorderableDragStartListener(index: index, child: icone) : icone;
  }
}

/// Lista de arrastar para mudar a ordem (seções de um painel, favoritos,
/// passos). Cada linha vem do [itemBuilder] com uma `Key` própria e põe uma
/// [SsDragHandle] onde quiser; com [longPress], segurar a linha também
/// arrasta. A linha levantada ganha sombra e cresce um pouco (sem crescer com
/// "reduzir movimento"); vibra leve ao pegar. [onReorder] já recebe o destino
/// ajustado (`lista.insert(to, lista.removeAt(from))`). O leitor de tela
/// ganha "mover para cima/baixo" em cada linha.
///
/// ```dart
/// SsReorderableList(
///   itemCount: secoes.length,
///   onReorder: (from, to) => setState(() => secoes.insert(to, secoes.removeAt(from))),
///   itemBuilder: (context, i) => SsCard(key: ValueKey(secoes[i].id), child: Row(children: [
///     SsDragHandle(index: i), Expanded(child: Text(secoes[i].title)),
///   ])),
/// )
/// ```
class SsReorderableList extends StatelessWidget {
  const SsReorderableList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onReorder,
    this.padding,
    this.spacing = 0,
    this.longPress = false,
    this.shrinkWrap = false,
    this.physics,
    this.header,
    this.footer,
  });

  final int itemCount;

  /// A linha `index`; precisa de `key` (a do item, não a posição).
  final IndexedWidgetBuilder itemBuilder;

  /// (de, para), com o destino já ajustado pela remoção.
  final void Function(int from, int to) onReorder;
  final EdgeInsets? padding;

  /// Espaço embaixo de cada linha.
  final double spacing;

  /// Segurar a linha arrasta (além da alça).
  final bool longPress;

  /// Dentro de outra rolagem (card, `SliverList`): `shrinkWrap: true` e
  /// `physics: NeverScrollableScrollPhysics()`.
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Widget? header;
  final Widget? footer;

  Widget _linha(BuildContext context, int i) {
    final w = itemBuilder(context, i);
    assert(w.key != null, 'SsReorderableList: a linha $i precisa de key');
    Widget filho = spacing == 0
        ? w
        : Padding(
            padding: EdgeInsets.only(bottom: spacing),
            child: w,
          );
    if (longPress) filho = ReorderableDelayedDragStartListener(index: i, child: filho);
    return KeyedSubtree(key: w.key, child: filho);
  }

  @override
  Widget build(BuildContext context) {
    final parado = reduceMotion(context);
    return ReorderableListView.builder(
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      header: header,
      footer: footer,
      buildDefaultDragHandles: false,
      itemCount: itemCount,
      itemBuilder: _linha,
      onReorderStart: (_) => SsHaptics.tick(),
      onReorderItem: (from, to) {
        if (from == to) return;
        onReorder(from, to);
      },
      proxyDecorator: (child, index, animation) => AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final t = Curves.easeOut.transform(animation.value);
          final c = SsColors.of(context);
          return Transform.scale(
            scale: parado ? 1 : 1 + .02 * t,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.card),
                boxShadow: [
                  BoxShadow(
                    color: c.accent.withValues(alpha: .28 * t),
                    blurRadius: 24,
                    offset: Offset(0, 10 * t),
                    spreadRadius: -8,
                  ),
                ],
              ),
              child: Material(type: MaterialType.transparency, child: child),
            ),
          );
        },
        child: child,
      ),
    );
  }
}

/// Ação perigosa separada do resto (excluir local, sair de todos os
/// aparelhos, apagar dados): fio tracejado em vermelho, [title] (padrão
/// "Zona de perigo") e [message], e os botões em [child].
class SsDangerZone extends StatelessWidget {
  const SsDangerZone({super.key, this.title, this.message, required this.child});

  final String? title;
  final String? message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SsDashedDivider(color: c.danger.withValues(alpha: .45), height: 24),
          Text(
            title ?? SsStrings.of(context).dangerZone,
            style: TextStyle(color: c.dangerText, fontSize: AppType.sub, fontWeight: FontWeight.w800),
          ),
          if (message != null) ...[
            const SizedBox(height: 4),
            Text(
              message!,
              style: TextStyle(color: c.muted, fontSize: AppType.sub, height: 1.4),
            ),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// Aviso em linha, dentro da tela (não some sozinho): faltou campo, a
/// automação é crítica, o servidor está desatualizado. Fundo suave do [tone],
/// ícone (padrão por tom), [title] em negrito, [message] e, embaixo, [child]
/// (lista) e [actions] (botões). Perigo e aviso são lidos na hora pelo
/// leitor de tela.
class SsCallout extends StatelessWidget {
  const SsCallout({
    super.key,
    this.tone = SsTone.info,
    this.icon,
    this.title,
    this.message,
    this.child,
    this.actions = const [],
  });

  final SsTone tone;
  final IconData? icon;
  final String? title;
  final String? message;
  final Widget? child;
  final List<Widget> actions;

  static IconData _icone(SsTone t) => switch (t) {
    SsTone.success => Icons.check_circle_outline_rounded,
    SsTone.warning => Icons.warning_amber_rounded,
    SsTone.danger => Icons.error_outline_rounded,
    SsTone.accent => Icons.auto_awesome_outlined,
    _ => Icons.info_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final cores = tone.colors(context);
    final urgente = tone == SsTone.danger || tone == SsTone.warning;
    return Semantics(
      container: true,
      liveRegion: urgente,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        decoration: BoxDecoration(
          color: Color.alphaBlend(cores.soft, c.surface),
          borderRadius: BorderRadius.circular(AppRadius.field),
          border: Border.all(color: cores.solid.withValues(alpha: .25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon ?? _icone(tone), size: 20, color: cores.text),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: TextStyle(
                        color: cores.text,
                        fontSize: AppType.set,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                  if (message != null)
                    Padding(
                      padding: EdgeInsets.only(top: title == null ? 0 : 2),
                      child: Text(
                        message!,
                        style: TextStyle(color: c.ink2, fontSize: AppType.sub, height: 1.4),
                      ),
                    ),
                  if (child != null) Padding(padding: const EdgeInsets.only(top: 6), child: child),
                  if (actions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Wrap(spacing: 8, runSpacing: 8, children: actions),
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

/// Texto técnico em DM Mono que dá para selecionar e copiar: log, YAML,
/// chave de integração, resposta da API. [terminal] usa o fundo escuro fixo
/// (log), senão o fundo de campo; [copy] põe o botão de copiar no canto (o ✓
/// fica 2 s); [maxHeight] limita e rola; [wrap] falso rola de lado em vez de
/// quebrar a linha.
class SsCodeBlock extends StatefulWidget {
  const SsCodeBlock(
    this.text, {
    super.key,
    this.terminal = false,
    this.copy = true,
    this.maxHeight,
    this.wrap = true,
    this.onCopied,
  });

  final String text;
  final bool terminal;
  final bool copy;
  final double? maxHeight;
  final bool wrap;

  /// Depois de copiar (o app pode mostrar um aviso).
  final VoidCallback? onCopied;

  @override
  State<SsCodeBlock> createState() => _SsCodeBlockState();
}

class _SsCodeBlockState extends State<SsCodeBlock> {
  bool _copiado = false;

  Future<void> _copiar() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    SsHaptics.tick();
    widget.onCopied?.call();
    if (!mounted) return;
    setState(() => _copiado = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiado = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = SsStrings.of(context);
    final fg = widget.terminal ? const Color(0xFFE7E4F6) : c.ink;
    final bg = widget.terminal ? AppColors.headerDarkBg : c.field;
    final estilo = AppTheme.number(context, size: 12.5, color: fg).copyWith(height: 1.45);
    Widget texto = SelectableText(widget.text, style: estilo);
    if (!widget.wrap) {
      texto = SingleChildScrollView(scrollDirection: Axis.horizontal, child: texto);
    }
    texto = Padding(padding: EdgeInsets.fromLTRB(12, 12, widget.copy ? 48 : 12, 12), child: texto);
    if (widget.maxHeight != null) {
      texto = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxHeight!),
        child: SingleChildScrollView(child: texto),
      );
    }
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.thumb)),
      child: Stack(
        children: [
          texto,
          if (widget.copy)
            Positioned(
              top: 0,
              right: 0,
              child: SsIconButton(
                icon: _copiado ? Icons.check_rounded : Icons.copy_rounded,
                tooltip: _copiado ? s.copied : s.copy,
                size: 36,
                color: _copiado
                    ? (widget.terminal ? AppColors.success : c.successText)
                    : (widget.terminal ? AppColors.onDarkMuted : c.muted),
                onPressed: _copiar,
              ),
            ),
        ],
      ),
    );
  }
}

/// Um botão do [SsButtonGroup].
@immutable
class SsGroupButton {
  const SsGroupButton({required this.icon, required this.tooltip, this.onPressed});

  final IconData icon;

  /// Nome do comando (dica e leitor de tela): "Abrir", "Parar", "Fechar".
  final String tooltip;
  final VoidCallback? onPressed;
}

/// Botões de comando colados num grupo (abrir/parar/fechar da cortina,
/// −/+ de volume): cada toque manda o comando na hora. [label] nomeia o
/// grupo no leitor de tela ("Ações da cortina da sala").
class SsButtonGroup extends StatelessWidget {
  const SsButtonGroup({super.key, required this.buttons, this.label});

  final List<SsGroupButton> buttons;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final raio = BorderRadius.circular(AppRadius.thumb);
    return Semantics(
      container: true,
      label: label,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: raio,
          border: Border.all(color: c.line),
        ),
        child: ClipRRect(
          borderRadius: raio,
          child: Material(
            type: MaterialType.transparency,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (i, b) in buttons.indexed) ...[
                  if (i > 0) Container(width: 1, height: 28, color: c.line),
                  Tooltip(
                    message: b.tooltip,
                    child: Semantics(
                      button: true,
                      enabled: b.onPressed != null,
                      label: b.tooltip,
                      excludeSemantics: true,
                      child: InkWell(
                        onTap: b.onPressed == null
                            ? null
                            : () {
                                SsHaptics.tick();
                                b.onPressed!();
                              },
                        highlightColor: c.accentSoft,
                        splashColor: c.accent.withValues(alpha: .12),
                        child: SizedBox(
                          width: 48,
                          height: 44,
                          child: Icon(b.icon, size: 20, color: b.onPressed == null ? c.muted2 : c.ink2),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Título de um passo numerado (Quando → Só se → Então; passo 1, 2, 3 de
/// um assistente): o número num círculo na cor sólida da marca, ou o ✓ em
/// verde quando [done]. [trailing] fica no fim da linha.
class SsStepHeading extends StatelessWidget {
  const SsStepHeading(this.number, this.title, {super.key, this.subtitle, this.trailing, this.done = false});

  final int number;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final cor = done ? AppColors.success : c.accentSolid;
    return Semantics(
      header: true,
      label: '$number. $title',
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: cor.withValues(alpha: .45),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: done
                  ? const Icon(Icons.check_rounded, size: 16, color: AppColors.onDark)
                  : Text(
                      '$number',
                      style: AppTheme.number(
                        context,
                        size: AppType.meta,
                        weight: FontWeight.w800,
                        color: AppColors.onDark,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: c.ink, fontSize: AppType.md, fontWeight: FontWeight.w800),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(color: c.muted, fontSize: AppType.sub),
                    ),
                ],
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Fio de separação; com [label], o texto no meio ("ou", "Hoje").
class SsDivider extends StatelessWidget {
  const SsDivider({super.key, this.label, this.height = 24});

  final String? label;

  /// Altura total ocupada (o fio fica no meio).
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    if (label == null) return Divider(height: height, thickness: 1, color: c.line);
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(child: Divider(thickness: 1, color: c.line)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label!,
              style: TextStyle(color: c.muted, fontSize: AppType.meta, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Divider(thickness: 1, color: c.line)),
        ],
      ),
    );
  }
}
