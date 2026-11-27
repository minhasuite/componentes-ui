// v1.10.0: o par Flutter do Ss::TreeViewComponent (plano de contas, categorias).
import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../ss_strings.dart';
import '../v15/privacy.dart';

/// Um nó da [SsTreeView] (o hash do `nodes:` do web): rótulo, contagem, valor e os filhos.
class SsTreeNode {
  const SsTreeNode(
    this.label, {
    this.id,
    this.value,
    this.count,
    this.children = const [],
    this.open = false,
    this.onTap,
  });
  final String label;

  /// Chave do nó para a seleção e o abrir/fechar (padrão: o caminho dos rótulos).
  final String? id;

  /// Valor à direita, em DM Mono ("R$ 9.000,00"); some com a privacidade ligada.
  final String? value;
  final int? count;
  final List<SsTreeNode> children;

  /// Começa aberto.
  final bool open;

  /// Tocar na folha (o `url:` do web): abrir o detalhe.
  final VoidCallback? onTap;

  bool get isLeaf => children.isEmpty;
}

/// Como a árvore escolhe: nenhuma (só navega), uma folha ou várias (com caixa, o galho marca os filhos).
enum SsTreeSelection { none, single, multiple }

/// Árvore (v1.10, par do `Ss::TreeViewComponent`): recuo com o fio à esquerda, a seta que gira ao abrir,
/// contagem e valor por nó. Tocar no galho abre e recolhe (com animação; reduzir movimento: na hora).
/// [selection]: `single` marca a folha tocada; `multiple` põe uma caixa em cada nó (a do galho marca ou
/// desmarca todas as folhas de baixo e fica "misturada" quando só parte está marcada). [selected] guarda
/// os ids das folhas; [onSelectionChanged] devolve o novo conjunto. [wrap]: rótulo longo quebra a linha.
///
/// ```dart
/// SsTreeView(label: 'Categorias', selection: SsTreeSelection.multiple, selected: marcadas,
///   onSelectionChanged: (s) => setState(() => marcadas = s),
///   nodes: const [SsTreeNode('Casa', open: true, children: [SsTreeNode('Luz', value: r'R$ 180,00')])])
/// ```
class SsTreeView extends StatefulWidget {
  const SsTreeView({
    super.key,
    required this.nodes,
    this.label,
    this.wrap = false,
    this.selection = SsTreeSelection.none,
    this.selected = const {},
    this.onSelectionChanged,
  });

  final List<SsTreeNode> nodes;

  /// Nome da árvore no leitor de tela (padrão: [SsStrings.treeLabel]).
  final String? label;
  final bool wrap;
  final SsTreeSelection selection;
  final Set<String> selected;
  final ValueChanged<Set<String>>? onSelectionChanged;

  /// A chave de cada nó (o [SsTreeNode.id] ou o caminho dos rótulos).
  static String keyOf(SsTreeNode n, String parent) => n.id ?? (parent.isEmpty ? n.label : '$parent/${n.label}');

  /// As chaves das folhas embaixo de [n] (ele mesmo, se for folha).
  static List<String> leavesOf(SsTreeNode n, String parent) {
    final k = keyOf(n, parent);
    if (n.isLeaf) return [k];
    return [for (final f in n.children) ...leavesOf(f, k)];
  }

  @override
  State<SsTreeView> createState() => _SsTreeViewState();
}

class _SsTreeViewState extends State<SsTreeView> {
  final _abertos = <String>{};

  @override
  void initState() {
    super.initState();
    void anda(List<SsTreeNode> ns, String pai) {
      for (final n in ns) {
        final k = SsTreeView.keyOf(n, pai);
        if (n.open) _abertos.add(k);
        anda(n.children, k);
      }
    }

    anda(widget.nodes, '');
  }

  void _troca(String k) => setState(() => _abertos.contains(k) ? _abertos.remove(k) : _abertos.add(k));

  void _marca(SsTreeNode n, String pai) {
    final f = widget.onSelectionChanged;
    if (f == null) return;
    final folhas = SsTreeView.leavesOf(n, pai);
    if (widget.selection == SsTreeSelection.single) {
      f({folhas.first});
      return;
    }
    final todas = folhas.every(widget.selected.contains);
    final novo = {...widget.selected};
    todas ? novo.removeAll(folhas) : novo.addAll(folhas);
    f(novo);
  }

  List<Widget> _lista(List<SsTreeNode> ns, String pai, int nivel) => [for (final n in ns) ..._no(n, pai, nivel)];

  List<Widget> _no(SsTreeNode n, String pai, int nivel) {
    final k = SsTreeView.keyOf(n, pai);
    final aberto = _abertos.contains(k);
    final folhas = SsTreeView.leavesOf(n, pai);
    final n0 = folhas.where(widget.selected.contains).length;
    final bool? marcado = n0 == 0 ? false : (n0 == folhas.length ? true : null);
    final reduz = reduceMotion(context);
    final linha = _Linha(
      node: n,
      open: aberto,
      wrap: widget.wrap,
      selection: widget.selection,
      checked: marcado,
      onTap: n.isLeaf ? (widget.selection == SsTreeSelection.none ? n.onTap : () => _marca(n, pai)) : () => _troca(k),
      onCheck: widget.selection == SsTreeSelection.multiple ? () => _marca(n, pai) : null,
    );
    if (n.isLeaf) return [linha];
    final c = SsColors.of(context);
    return [
      linha,
      _Abre(
        reduce: reduz,
        child: aberto
            ? Container(
                margin: const EdgeInsets.only(left: 17),
                padding: const EdgeInsets.only(left: 9),
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: c.line, width: 1.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _lista(n.children, k, nivel + 1),
                ),
              )
            : const SizedBox(width: double.infinity),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.label ?? SsStrings.of(context).treeLabel,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _lista(widget.nodes, '', 0)),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({
    required this.node,
    required this.open,
    required this.wrap,
    required this.selection,
    required this.checked,
    required this.onTap,
    required this.onCheck,
  });
  final SsTreeNode node;
  final bool open;
  final bool wrap;
  final SsTreeSelection selection;
  final bool? checked;
  final VoidCallback? onTap;
  final VoidCallback? onCheck;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    final reduz = reduceMotion(context);
    final galho = !node.isLeaf;
    final escolhido = selection == SsTreeSelection.single && node.isLeaf && checked == true;
    final lead = galho
        ? AnimatedRotation(
            turns: open ? 0 : -.25,
            duration: reduz ? Duration.zero : SsMotion.short,
            curve: SsMotion.spring,
            child: Icon(Icons.expand_more_rounded, size: 20, color: c.muted),
          )
        : Center(
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: c.line, shape: BoxShape.circle),
            ),
          );
    final caixa = onCheck == null
        ? null
        : SsTapTarget(
            semantics: true,
            child: Semantics(
              container: true,
              checked: checked ?? false,
              mixed: checked == null,
              label: node.label,
              onTap: onCheck,
              excludeSemantics: true,
              child: GestureDetector(onTap: onCheck, behavior: HitTestBehavior.opaque, child: _Caixa(checked)),
            ),
          );
    final partes = [node.label, if (node.count != null) s.treeCount(node.count!), ?node.value].join(', ');
    final corpo = Semantics(
      container: true,
      button: onTap != null,
      expanded: galho ? open : null,
      selected: escolhido,
      label: partes,
      hint: galho ? (open ? s.collapse : s.expand) : null,
      excludeSemantics: true,
      child: SsPressable(
        onTap: onTap,
        enabled: onTap != null,
        scale: .99,
        child: AnimatedContainer(
          duration: reduz ? Duration.zero : SsMotion.short,
          constraints: BoxConstraints(minHeight: d.minTarget),
          padding: EdgeInsets.symmetric(horizontal: d.space(8), vertical: d.space(wrap ? 8 : 4)),
          decoration: BoxDecoration(
            color: escolhido ? c.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: wrap ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              SizedBox(width: 20, height: 20, child: lead),
              SizedBox(width: d.space(8)),
              Expanded(
                child: Text(
                  node.label,
                  maxLines: wrap ? null : 1,
                  overflow: wrap ? null : TextOverflow.ellipsis,
                  style: TextStyle(
                    color: escolhido ? c.accentText : c.ink,
                    fontSize: d.font(AppType.set),
                    fontWeight: galho ? FontWeight.w800 : FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
              if (node.count != null) ...[
                SizedBox(width: d.space(6)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(AppRadius.pill)),
                  child: Text(
                    '${node.count}',
                    style: AppTheme.number(context, size: d.font(AppType.label), color: c.muted),
                  ),
                ),
              ],
              if (node.value != null) ...[
                SizedBox(width: d.space(8)),
                SsPrivate(
                  child: Text(
                    node.value!,
                    style: AppTheme.number(context, size: d.font(AppType.sub), color: c.ink2),
                  ),
                ),
              ],
              if (escolhido) ...[SizedBox(width: d.space(6)), Icon(Icons.check_rounded, size: 18, color: c.accentText)],
            ],
          ),
        ),
      ),
    );
    if (caixa == null) return corpo;
    return Row(
      children: [
        caixa,
        Expanded(child: corpo),
      ],
    );
  }
}

class _Caixa extends StatelessWidget {
  const _Caixa(this.checked);
  final bool? checked;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final on = checked != false;
    return AnimatedContainer(
      duration: reduceMotion(context) ? Duration.zero : SsMotion.short,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: on ? c.accentSolid : c.surface,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: on ? c.accentSolid : c.muted2, width: 1.6),
      ),
      child: checked == null
          ? const Icon(Icons.remove_rounded, size: 16, color: AppColors.onDark)
          : SsCheckMark(value: checked!, size: 15, color: AppColors.onDark),
    );
  }
}

/// Os filhos que descem e sobem (reduzir movimento: troca direto, sem o AnimatedSize).
class _Abre extends StatelessWidget {
  const _Abre({required this.reduce, required this.child});
  final bool reduce;
  final Widget child;

  @override
  Widget build(BuildContext context) => reduce
      ? child
      : ClipRect(
          child: AnimatedSize(
            duration: SsMotion.medium,
            curve: SsMotion.standard,
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
}
