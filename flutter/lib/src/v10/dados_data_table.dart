// v0.10 (dados): tabela de dados. No celular as linhas viram cartões
// empilhados (rótulo à esquerda, valor à direita), como o modo empilhado do
// Ss::DataTableComponent do Rails.
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../motion.dart';
import '../motion_view.dart';
import '../skeleton.dart';
import '../ss_empty_state.dart';
import '../ss_strings.dart';

/// Coluna do [SsDataTable]. [numeric] alinha à direita em DM Mono; [onSort]
/// torna o cabeçalho tocável (recebe o sentido novo: true = crescente);
/// [flex] divide a largura (ou [width] fixa).
class SsDataColumn {
  const SsDataColumn(this.label, {this.numeric = false, this.onSort, this.flex = 1, this.width});

  final String label;
  final bool numeric;
  final ValueChanged<bool>? onSort;
  final int flex;
  final double? width;
}

/// Linha do [SsDataTable]: uma célula por coluna. [onTap] torna a linha
/// tocável.
class SsDataRow {
  const SsDataRow(this.cells, {this.onTap});

  /// Atalho para células só de texto.
  SsDataRow.text(List<String> texts, {this.onTap}) : cells = [for (final t in texts) Text(t)];

  final List<Widget> cells;
  final VoidCallback? onTap;
}

/// Tabela de dados com cabeçalho ordenável e números à direita. Abaixo de
/// [stackBelow] de largura, cada linha vira um cartão: a coluna [titleColumn]
/// é o título e as outras viram "RÓTULO  valor"; a ordenação passa para
/// fichas em cima. Estados: [loading] (linhas-fantasma), vazio ([emptyTitle])
/// e ordenada ([sortColumn] + [sortAscending], com a seta e o `aria-sort`).
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
  });

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

  Widget _celula(BuildContext context, SsDataColumn col, Widget child, {bool head = false}) {
    final c = SsColors.of(context);
    final estilo = head
        ? TextStyle(fontSize: AppType.label, fontWeight: FontWeight.w800, letterSpacing: .8, color: c.muted)
        : col.numeric
        ? AppTheme.number(context, size: AppType.set, color: c.ink)
        : TextStyle(fontSize: AppType.set, color: c.ink);
    final conteudo = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Align(
        alignment: col.numeric ? Alignment.centerRight : Alignment.centerLeft,
        child: DefaultTextStyle.merge(style: estilo, child: child),
      ),
    );
    return col.width != null ? SizedBox(width: col.width, child: conteudo) : Expanded(flex: col.flex, child: conteudo);
  }

  Widget _tabela(BuildContext context) {
    final c = SsColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: c.isDark ? null : AppShadows.card,
        border: c.isDark ? Border.all(color: c.line) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: c.field,
            child: Row(
              children: [
                for (var i = 0; i < columns.length; i++)
                  _celula(context, columns[i], _cabecalho(context, i), head: true),
              ],
            ),
          ),
          for (var r = 0; r < rows.length; r++)
            SsInViewReveal(
              index: r,
              offset: 8,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: rows[r].onTap,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: c.line)),
                    ),
                    child: Row(
                      children: [
                        for (var i = 0; i < columns.length; i++)
                          _celula(
                            context,
                            columns[i],
                            Semantics(
                              label: '${columns[i].label}: ',
                              child: i < rows[r].cells.length ? rows[r].cells[i] : const SizedBox(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cabecalho(BuildContext context, int i) {
    final c = SsColors.of(context);
    final col = columns[i];
    final ativa = sortColumn == i;
    final texto = Text(col.label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis);
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
    final ordenaveis = [
      for (var i = 0; i < columns.length; i++)
        if (columns[i].onSort != null) i,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ordenaveis.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  sortByLabel ?? SsStrings.of(context).sortBy,
                  style: TextStyle(fontSize: AppType.meta, color: c.muted, fontWeight: FontWeight.w600),
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
                        duration: SsMotion.fast,
                        padding: const EdgeInsets.fromLTRB(10, 5, 8, 5),
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
                                fontSize: AppType.meta,
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
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: c.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: c.line),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: rows[r].onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (titleColumn < rows[r].cells.length)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: DefaultTextStyle.merge(
                              style: TextStyle(fontSize: AppType.body, fontWeight: FontWeight.w800, color: c.ink),
                              child: rows[r].cells[titleColumn],
                            ),
                          ),
                        for (var i = 0; i < columns.length; i++)
                          if (i != titleColumn && i < rows[r].cells.length)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    columns[i].label.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: AppType.label,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: .6,
                                      color: c.muted,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: DefaultTextStyle.merge(
                                        textAlign: TextAlign.right,
                                        style: columns[i].numeric
                                            ? AppTheme.number(context, size: AppType.set, color: c.ink)
                                            : TextStyle(fontSize: AppType.set, color: c.ink),
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
      ],
    );
  }

  Widget _fantasma(BuildContext context, bool pilha) {
    final c = SsColors.of(context);
    if (pilha) {
      return Column(
        children: [
          for (var i = 0; i < loadingRows; i++)
            const Padding(padding: EdgeInsets.only(bottom: 10), child: SkeletonBox(height: 96, radius: 16)),
        ],
      );
    }
    return Container(
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(AppRadius.card)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(height: 40, color: c.field),
          for (var i = 0; i < loadingRows; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
