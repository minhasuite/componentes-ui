// v0.10 (dados): tabela de dados. No celular as linhas viram cartões
// empilhados (rótulo à esquerda, valor à direita), como o modo empilhado do
// Ss::DataTableComponent do Rails.
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../motion_view.dart';
import '../skeleton.dart';
import '../ss_empty_state.dart';
import '../ss_strings.dart';

/// Coluna do [SsDataTable]. [numeric] alinha à direita em DM Mono; [onSort]
/// torna o cabeçalho tocável (recebe o sentido novo: true = crescente);
/// [flex] divide a largura (ou [width] fixa).
///
/// v0.20: [header] troca o texto do cabeçalho por um widget (ícone, selo,
/// duas linhas); o [label] continua no leitor de tela e nos cartões.
class SsDataColumn {
  const SsDataColumn(this.label, {this.numeric = false, this.onSort, this.flex = 1, this.width, this.header});

  final String label;

  /// v0.20: cabeçalho montado (par do `t.column(..., header:)` do web).
  final Widget? header;
  final bool numeric;
  final ValueChanged<bool>? onSort;
  final int flex;
  final double? width;
}

/// Linha do [SsDataTable]: uma célula por coluna. [onTap] torna a linha
/// tocável.
///
/// v0.20: [dimmed] apaga a linha (inativo, cancelado, arquivado), par do
/// `tr.is-dimmed` do web.
class SsDataRow {
  const SsDataRow(this.cells, {this.onTap, this.dimmed = false});

  /// Atalho para células só de texto.
  SsDataRow.text(List<String> texts, {this.onTap, this.dimmed = false}) : cells = [for (final t in texts) Text(t)];

  final List<Widget> cells;
  final VoidCallback? onTap;
  final bool dimmed;
}

/// Tabela de dados com cabeçalho ordenável e números à direita. Abaixo de
/// [stackBelow] de largura, cada linha vira um cartão: a coluna [titleColumn]
/// é o título e as outras viram "RÓTULO  valor"; a ordenação passa para
/// fichas em cima. Estados: [loading] (linhas-fantasma), vazio ([emptyTitle])
/// e ordenada ([sortColumn] + [sortAscending], com a seta e o `aria-sort`).
///
/// v0.20: [footer] é a linha de total (uma célula por coluna, em negrito, no
/// fundo do campo; no celular vira um bloco no fim), [flat] tira a moldura de
/// card (tabela dentro de um card com título) e [stickyFirstColumn] deixa a
/// tabela rolar de lado com a 1ª coluna parada quando as colunas não cabem
/// (cada coluna sem `width` tem no mínimo [minColumnWidth]).
///
/// `SsDataTable(columns: [SsDataColumn('Nome', onSort: ordena), SsDataColumn('Valor', numeric: true)], rows: linhas)`
class SsDataTable extends StatelessWidget {
  const SsDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.sortColumn,
    this.sortAscending = true,
    this.loading = false,
    this.loadingRows = 4,
    this.stackBelow = 600,
    this.titleColumn = 0,
    this.label,
    this.emptyTitle,
    this.emptySubtitle,
    this.sortByLabel,
    this.ascendingLabel,
    this.descendingLabel,
    this.footer,
    this.flat = false,
    this.stickyFirstColumn = false,
    this.minColumnWidth = 120,
  });

  /// v0.20: linha de total (par do `t.footer`/`t.total` do web).
  final List<Widget>? footer;

  /// v0.20: sem fundo, sombra nem raio de card (par do `flat: true`).
  final bool flat;

  /// v0.20: 1ª coluna parada ao rolar de lado (par do `t.column(..., sticky: true)`).
  final bool stickyFirstColumn;

  /// v0.20: largura mínima de cada coluna com [stickyFirstColumn].
  final double minColumnWidth;

  final List<SsDataColumn> columns;
  final List<SsDataRow> rows;

  /// Índice da coluna ordenada (nulo: nenhuma).
  final int? sortColumn;
  final bool sortAscending;
  final bool loading;
  final int loadingRows;

  /// Largura abaixo da qual as linhas viram cartões.
  final double stackBelow;

  /// Coluna que vira o título do cartão.
  final int titleColumn;

  /// Nome da tabela para o leitor de tela.
  final String? label;

  /// Textos (padrão: os do [SsStrings] do idioma).
  final String? emptyTitle;
  final String? emptySubtitle;
  final String? sortByLabel;
  final String? ascendingLabel;
  final String? descendingLabel;

  void _ordena(int i) {
    final s = columns[i].onSort;
    if (s == null) return;
    SsHaptics.tick();
    s(sortColumn == i ? !sortAscending : true);
  }

  String _sentido(BuildContext context, int i) {
    if (sortColumn != i) return '';
    final s = SsStrings.of(context);
    return ', ${sortAscending ? ascendingLabel ?? s.ascending : descendingLabel ?? s.descending}';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: label,
      child: LayoutBuilder(
        builder: (context, box) {
          final pilha = box.maxWidth < stackBelow;
          if (loading) return _fantasma(context, pilha);
          if (rows.isEmpty) {
            return SsEmptyState(
              compact: true,
              icon: Icons.table_rows_outlined,
              title: emptyTitle ?? SsStrings.of(context).emptyYet,
              subtitle: emptySubtitle,
            );
          }
          return pilha ? _cartoes(context) : _tabela(context);
        },
      ),
    );
  }

  Widget _conteudo(BuildContext context, SsDataColumn col, Widget child, {bool head = false, bool foot = false}) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    var estilo = head
        ? TextStyle(fontSize: d.font(AppType.label), fontWeight: FontWeight.w800, letterSpacing: .8, color: c.muted)
        : col.numeric
        ? AppTheme.number(context, size: d.font(AppType.set), color: c.ink)
        : TextStyle(fontSize: d.font(AppType.set), color: c.ink);
    if (foot) estilo = estilo.copyWith(fontWeight: FontWeight.w800);
    // Célula: 8×8 / 12×12 / 16×16 (horizontal pelo padX, vertical pela linha).
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: d.padX - 4, vertical: d.rowPadV + 2),
      child: Align(
        alignment: col.numeric ? Alignment.centerRight : Alignment.centerLeft,
        child: DefaultTextStyle.merge(style: estilo, child: child),
      ),
    );
  }

  Widget _celula(
    BuildContext context,
    SsDataColumn col,
    Widget child, {
    bool head = false,
    bool foot = false,
    double? width,
  }) {
    final conteudo = _conteudo(context, col, child, head: head, foot: foot);
    final w = width ?? col.width;
    return w != null ? SizedBox(width: w, child: conteudo) : Expanded(flex: col.flex, child: conteudo);
  }

  /// Larguras com [stickyFirstColumn]: as fixas valem; as outras dividem o
  /// que sobra pelo flex, com o mínimo [minColumnWidth].
  List<double> _larguras(double total) {
    final fixas = columns.fold<double>(0, (a, col) => a + (col.width ?? 0));
    final flexes = columns.fold<int>(0, (a, col) => a + (col.width == null ? col.flex : 0));
    final sobra = (total - fixas).clamp(0, double.infinity);
    return [
      for (final col in columns)
        col.width ??
            (flexes == 0 ? minColumnWidth : (sobra * col.flex / flexes).clamp(minColumnWidth, double.infinity)),
    ];
  }

  /// Uma linha (cabeçalho, dado ou total). Com [larguras], a 1ª célula fica
  /// parada por cima ([rolagem] desloca junto com a rolagem de lado).
  Widget _linha(
    BuildContext context,
    List<Widget> cells, {
    bool head = false,
    bool foot = false,
    List<double>? larguras,
    ScrollController? rolagem,
    required Color fundo,
  }) {
    final c = SsColors.of(context);
    Widget celula(int i, {bool fantasma = false}) {
      final filho = i < cells.length ? cells[i] : const SizedBox();
      final w = larguras?[i];
      final cel = _celula(context, columns[i], filho, head: head, foot: foot, width: w);
      return fantasma
          ? Visibility(visible: false, maintainSize: true, maintainAnimation: true, maintainState: true, child: cel)
          : cel;
    }

    final linha = Row(
      children: [for (var i = 0; i < columns.length; i++) celula(i, fantasma: larguras != null && i == 0)],
    );
    if (larguras == null || columns.isEmpty) return linha;
    final primeira = _conteudo(
      context,
      columns[0],
      cells.isEmpty ? const SizedBox() : cells[0],
      head: head,
      foot: foot,
    );
    return Stack(
      children: [
        linha,
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: larguras[0],
          child: AnimatedBuilder(
            animation: rolagem!,
            builder: (context, child) {
              final dx = rolagem.hasClients ? rolagem.offset : 0.0;
              return Transform.translate(
                offset: Offset(dx, 0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: fundo,
                    border: dx > 0 ? Border(right: BorderSide(color: c.line)) : null,
                  ),
                  child: child,
                ),
              );
            },
            child: primeira,
          ),
        ),
      ],
    );
  }

  List<Widget> _linhas(BuildContext context, {List<double>? larguras, ScrollController? rolagem}) {
    final c = SsColors.of(context);
    return [
      Container(
        color: c.field,
        child: _linha(
          context,
          [for (var i = 0; i < columns.length; i++) _cabecalho(context, i)],
          head: true,
          larguras: larguras,
          rolagem: rolagem,
          fundo: c.field,
        ),
      ),
      for (var r = 0; r < rows.length; r++)
        SsInViewReveal(
          index: r,
          offset: 8,
          child: Opacity(
            opacity: rows[r].dimmed ? .5 : 1,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: rows[r].onTap,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: c.line)),
                  ),
                  child: _linha(
                    context,
                    [
                      for (var i = 0; i < columns.length; i++)
                        Semantics(
                          label: '${columns[i].label}: ',
                          child: i < rows[r].cells.length ? rows[r].cells[i] : const SizedBox(),
                        ),
                    ],
                    larguras: larguras,
                    rolagem: rolagem,
                    fundo: c.surface,
                  ),
                ),
              ),
            ),
          ),
        ),
      if (footer != null)
        Container(
          decoration: BoxDecoration(
            color: c.field,
            border: Border(top: BorderSide(color: c.line)),
          ),
          child: _linha(context, footer!, foot: true, larguras: larguras, rolagem: rolagem, fundo: c.field),
        ),
    ];
  }

  Widget _tabela(BuildContext context) {
    final c = SsColors.of(context);
    final corpo = LayoutBuilder(
      builder: (context, box) {
        if (stickyFirstColumn && box.hasBoundedWidth) {
          final larguras = _larguras(box.maxWidth);
          final total = larguras.fold<double>(0, (a, b) => a + b);
          if (total > box.maxWidth + .5) return _RolagemFixa(tabela: this, larguras: larguras, total: total);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _linhas(context));
      },
    );
    if (flat) return ClipRect(child: corpo);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(SsDensity.of(context).radiusCard),
        boxShadow: c.isDark ? null : AppShadows.card,
        border: c.isDark ? Border.all(color: c.line) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: corpo,
    );
  }

  Widget _cabecalho(BuildContext context, int i) {
    final c = SsColors.of(context);
    final col = columns[i];
    final ativa = sortColumn == i;
    final Widget texto = col.header != null
        ? Semantics(label: col.label, excludeSemantics: true, child: col.header)
        : Text(col.label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis);
    if (col.onSort == null) return Semantics(header: true, child: texto);
    return Semantics(
      header: true,
      button: true,
      label: '${col.label}${_sentido(context, i)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => _ordena(i),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: DefaultTextStyle.merge(
                style: TextStyle(color: ativa ? c.accentText : null),
                child: texto,
              ),
            ),
            const SizedBox(width: 2),
            _Seta(ativa: ativa, asc: sortAscending),
          ],
        ),
      ),
    );
  }

  Widget _cartoes(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final ordenaveis = [
      for (var i = 0; i < columns.length; i++)
        if (columns[i].onSort != null) i,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ordenaveis.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: d.space(10)),
            child: Wrap(
              spacing: d.space(6),
              runSpacing: d.space(6),
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  sortByLabel ?? SsStrings.of(context).sortBy,
                  style: TextStyle(fontSize: d.font(AppType.meta), color: c.muted, fontWeight: FontWeight.w600),
                ),
                for (final i in ordenaveis)
                  Semantics(
                    button: true,
                    selected: sortColumn == i,
                    label: '${sortByLabel ?? SsStrings.of(context).sortBy} ${columns[i].label}${_sentido(context, i)}',
                    excludeSemantics: true,
                    child: SsPressable(
                      onTap: () => _ordena(i),
                      child: AnimatedContainer(
                        duration: reduceMotion(context) ? Duration.zero : SsMotion.fast,
                        padding: EdgeInsets.fromLTRB(d.space(10), d.space(5), d.space(8), d.space(5)),
                        decoration: BoxDecoration(
                          color: sortColumn == i ? c.accentSoft : c.surface,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: sortColumn == i ? Colors.transparent : c.line),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              columns[i].label,
                              style: TextStyle(
                                fontSize: d.font(AppType.meta),
                                fontWeight: FontWeight.w700,
                                color: sortColumn == i ? c.accentText : c.ink2,
                              ),
                            ),
                            const SizedBox(width: 2),
                            _Seta(ativa: sortColumn == i, asc: sortAscending),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        for (var r = 0; r < rows.length; r++)
          SsInViewReveal(
            index: r,
            offset: 10,
            child: Padding(
              padding: EdgeInsets.only(bottom: d.space(10)),
              child: _apaga(
                rows[r].dimmed,
                Material(
                  color: c.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(d.radiusCard - 2),
                    side: BorderSide(color: c.line),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: rows[r].onTap,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: d.padX - 2, vertical: d.rowPadV),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (titleColumn < rows[r].cells.length)
                            Padding(
                              padding: EdgeInsets.only(bottom: d.space(4)),
                              child: DefaultTextStyle.merge(
                                style: TextStyle(
                                  fontSize: d.font(AppType.body),
                                  fontWeight: FontWeight.w800,
                                  color: c.ink,
                                ),
                                child: rows[r].cells[titleColumn],
                              ),
                            ),
                          for (var i = 0; i < columns.length; i++)
                            if (i != titleColumn && i < rows[r].cells.length)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: d.space(4)),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      columns[i].label.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: d.font(AppType.label),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: .6,
                                        color: c.muted,
                                      ),
                                    ),
                                    SizedBox(width: d.gap),
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: DefaultTextStyle.merge(
                                          textAlign: TextAlign.right,
                                          style: columns[i].numeric
                                              ? AppTheme.number(context, size: d.font(AppType.set), color: c.ink)
                                              : TextStyle(fontSize: d.font(AppType.set), color: c.ink),
                                          child: rows[r].cells[i],
                                        ),
                                      ),
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
            ),
          ),
        if (footer != null) _totalCartao(context),
      ],
    );
  }

  static Widget _apaga(bool dimmed, Widget child) => dimmed ? Opacity(opacity: .5, child: child) : child;

  /// O total no celular: um bloco no fundo do campo, "RÓTULO  valor" por coluna.
  Widget _totalCartao(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: d.padX - 2, vertical: d.rowPadV),
      decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(d.radiusCard - 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < columns.length && i < footer!.length; i++)
            Padding(
              padding: EdgeInsets.symmetric(vertical: d.space(4)),
              child: Row(
                children: [
                  if (i != titleColumn)
                    Text(
                      columns[i].label.toUpperCase(),
                      style: TextStyle(
                        fontSize: d.font(AppType.label),
                        fontWeight: FontWeight.w700,
                        letterSpacing: .6,
                        color: c.muted,
                      ),
                    ),
                  SizedBox(width: d.gap),
                  Expanded(
                    child: Align(
                      alignment: i == titleColumn ? Alignment.centerLeft : Alignment.centerRight,
                      child: DefaultTextStyle.merge(
                        style:
                            (columns[i].numeric
                                    ? AppTheme.number(context, size: d.font(AppType.set), color: c.ink)
                                    : TextStyle(fontSize: d.font(AppType.set), color: c.ink))
                                .copyWith(fontWeight: FontWeight.w800),
                        child: footer![i],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _fantasma(BuildContext context, bool pilha) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    if (pilha) {
      return Column(
        children: [
          for (var i = 0; i < loadingRows; i++)
            const Padding(padding: EdgeInsets.only(bottom: 10), child: SkeletonBox(height: 96, radius: 16)),
        ],
      );
    }
    return Container(
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(d.radiusCard)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(height: d.rowPadV * 2 + 20, color: c.field),
          for (var i = 0; i < loadingRows; i++)
            Container(
              padding: EdgeInsets.symmetric(horizontal: d.padX - 4, vertical: d.rowPadV + 4),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: Row(
                children: [
                  for (var k = 0; k < columns.length; k++)
                    Expanded(
                      flex: columns[k].flex,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Align(
                          alignment: columns[k].numeric ? Alignment.centerRight : Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: k == 0 ? .8 : .5,
                            child: const SkeletonBox(height: 12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Seta da ordenação: gira com a mola quando o sentido troca; apagada se a
/// coluna não é a ordenada.
class _Seta extends StatelessWidget {
  const _Seta({required this.ativa, required this.asc});

  final bool ativa;
  final bool asc;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return AnimatedRotation(
      turns: ativa && !asc ? .5 : 0,
      duration: reduceMotion(context) ? Duration.zero : SsMotion.indicator,
      curve: SsMotion.bounce,
      child: Icon(
        ativa ? Icons.arrow_upward_rounded : Icons.unfold_more_rounded,
        size: 14,
        color: ativa ? c.accentText : c.muted2,
      ),
    );
  }
}

/// A tabela larga que rola de lado com a 1ª coluna parada.
class _RolagemFixa extends StatefulWidget {
  const _RolagemFixa({required this.tabela, required this.larguras, required this.total});

  final SsDataTable tabela;
  final List<double> larguras;
  final double total;

  @override
  State<_RolagemFixa> createState() => _RolagemFixaState();
}

class _RolagemFixaState extends State<_RolagemFixa> {
  final _rolagem = ScrollController();

  @override
  void dispose() {
    _rolagem.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scrollbar(
    controller: _rolagem,
    child: SingleChildScrollView(
      controller: _rolagem,
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: widget.total,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widget.tabela._linhas(context, larguras: widget.larguras, rolagem: _rolagem),
        ),
      ),
    ),
  );
}
