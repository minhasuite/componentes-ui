// v1.10.0: o par Flutter do Ss::FilterBarComponent: a barra (botão Filtros com o número de ativos, visões
// salvas, chips do que está ativo e limpar) e a folha de filtros com "Mostrar N resultados" ao vivo.
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../motion_view.dart';
import '../ss_button.dart';
import '../ss_controls.dart';
import '../ss_list.dart';
import '../ss_sheet.dart';
import '../ss_strings.dart';
import '../v16/input_chip.dart';
import '../v19/transicoes/predictive_back.dart';

/// Os filtros escolhidos: parâmetro → valores (um só no filtro simples). O mesmo da query do web
/// (`status=pago`, `tag[]=a&tag[]=b`).
typedef SsFilterValues = Map<String, List<String>>;

/// Uma opção de um filtro: o texto e o valor.
class SsFilterOption {
  const SsFilterOption(this.label, this.value);
  final String label;
  final String value;
}

/// Um filtro (o `filters:` do web): `{ param:, label:, options:, multiple: }`.
class SsFilterGroup {
  const SsFilterGroup({required this.param, required this.label, required this.options, this.multiple = false});
  final String param;
  final String label;
  final List<SsFilterOption> options;

  /// Vários valores ao mesmo tempo (o `tag[]` do web): cada valor é um chip.
  final bool multiple;
}

/// Visão salva (o `views:` do web): "Vencidos esta semana" com os filtros dela e, opcional, a contagem.
class SsFilterView {
  const SsFilterView(this.label, {this.values = const {}, this.count});
  final String label;
  final SsFilterValues values;
  final int? count;
}

/// Um filtro ativo (um por valor), na ordem dos [SsFilterGroup].
typedef SsActiveFilter = ({SsFilterGroup group, String value, String label});

/// Utilidades dos valores (as mesmas regras do `Ss::FilterBarComponent`).
abstract final class SsFilters {
  /// Os ativos, um por valor; valor fora das opções aparece como veio.
  static List<SsActiveFilter> active(List<SsFilterGroup> filters, SsFilterValues values) => [
    for (final g in filters)
      for (final v in values[g.param] ?? const <String>[])
        if (v.isNotEmpty) (group: g, value: v, label: g.options.where((o) => o.value == v).firstOrNull?.label ?? v),
  ];

  /// Marca/desmarca [value]: no simples, troca (ou tira, se já era ele); no múltiplo, soma ou tira.
  static SsFilterValues toggle(SsFilterValues values, SsFilterGroup g, String value) {
    final out = {
      for (final e in values.entries) e.key: [...e.value],
    };
    final atual = out[g.param] ?? <String>[];
    final tem = atual.contains(value);
    final novo = g.multiple ? (tem ? (atual..remove(value)) : [...atual, value]) : (tem ? <String>[] : [value]);
    if (novo.isEmpty) {
      out.remove(g.param);
    } else {
      out[g.param] = novo;
    }
    return out;
  }

  /// Tira só aquele valor (o × do chip).
  static SsFilterValues remove(SsFilterValues values, String param, String value) {
    final out = {
      for (final e in values.entries) e.key: [...e.value],
    };
    final rest = (out[param] ?? const <String>[]).where((v) => v != value).toList();
    if (rest.isEmpty) {
      out.remove(param);
    } else {
      out[param] = rest;
    }
    return out;
  }

  /// Mesmos filtros, sem ligar para a ordem (a visão salva atual).
  static bool same(SsFilterValues a, SsFilterValues b) {
    List<String> ord(SsFilterValues m, String k) => [...?m[k]]..sort();
    final ka = {...a.keys.where((k) => a[k]!.isNotEmpty)}, kb = {...b.keys.where((k) => b[k]!.isNotEmpty)};
    if (ka.length != kb.length || !ka.containsAll(kb)) return false;
    for (final k in ka) {
      final x = ord(a, k), y = ord(b, k);
      if (x.length != y.length) return false;
      for (var i = 0; i < x.length; i++) {
        if (x[i] != y[i]) return false;
      }
    }
    return true;
  }

  static int count(List<SsFilterGroup> filters, SsFilterValues values) => active(filters, values).length;
}

/// Conta os resultados de um rascunho de filtros (local ou na API); pode ser assíncrono.
typedef SsFilterCounter = FutureOr<int> Function(SsFilterValues values);

/// Abre a [SsFilterSheet] numa folha de baixo e devolve os filtros aplicados (nulo: fechou sem aplicar).
Future<SsFilterValues?> showSsFilterSheet(
  BuildContext context, {
  required List<SsFilterGroup> filters,
  SsFilterValues values = const {},
  SsFilterCounter? count,
  String? title,
}) => showModalBottomSheet<SsFilterValues>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: false,
  sheetAnimationStyle: SsOverlayMotion.sheet(context),
  builder: (ctx) => SsFilterSheet(
    filters: filters,
    values: values,
    count: count,
    title: title,
    onApply: (v) => Navigator.of(ctx).pop(v),
  ),
);

/// Folha de filtros (v1.10, par do `Ss::FilterBarComponent`): os chips do que está ativo no topo
/// (o × tira), cada filtro com as opções em chips, "Limpar filtros" e o botão "Mostrar N resultados"
/// que conta ao vivo enquanto a pessoa escolhe ([count]; assíncrono: mantém o número anterior até chegar,
/// e a resposta velha não passa por cima da nova). O botão fica fixo embaixo; as opções rolam.
/// Abra com [showSsFilterSheet] (ou pelo [SsFilterBar]).
class SsFilterSheet extends StatefulWidget {
  const SsFilterSheet({
    super.key,
    required this.filters,
    required this.onApply,
    this.values = const {},
    this.count,
    this.title,
  });

  final List<SsFilterGroup> filters;
  final SsFilterValues values;
  final SsFilterCounter? count;
  final ValueChanged<SsFilterValues> onApply;

  /// Padrão: [SsStrings.filters].
  final String? title;

  @override
  State<SsFilterSheet> createState() => _SsFilterSheetState();
}

class _SsFilterSheetState extends State<SsFilterSheet> {
  late SsFilterValues _draft = {
    for (final e in widget.values.entries) e.key: [...e.value],
  };
  int? _n;
  bool _contando = false;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _conta();
  }

  void _muda(SsFilterValues v) {
    setState(() => _draft = v);
    _conta();
  }

  void _conta() {
    final f = widget.count;
    if (f == null) return;
    final r = f(_draft);
    if (r is int) {
      if (mounted) setState(() => _n = r);
      return;
    }
    final meu = ++_seq;
    setState(() => _contando = true);
    r.then(
      (n) {
        if (mounted && meu == _seq) {
          setState(() {
            _n = n;
            _contando = false;
          });
        }
      },
      onError: (Object _) {
        if (mounted && meu == _seq) setState(() => _contando = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    final ativos = SsFilters.active(widget.filters, _draft);
    final rotulo = _n == null ? s.filterShow : s.filterShowResults(_n!);
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    return SsPredictiveBackScope(
      child: Padding(
        padding: EdgeInsets.only(bottom: kb),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 38,
                  height: 5,
                  decoration: BoxDecoration(color: c.muted2, borderRadius: BorderRadius.circular(AppRadius.pill)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Row(
                  children: [
                    Expanded(child: SsSheetHeader(widget.title ?? s.filters, icon: Icons.tune_rounded)),
                    SsButton.text(
                      label: s.filterClear,
                      small: true,
                      onPressed: ativos.isEmpty ? null : () => _muda({}),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Ativos(ativos: ativos, onRemove: (a) => _muda(SsFilters.remove(_draft, a.group.param, a.value))),
                      for (final g in widget.filters) ...[
                        SsGroupHeader(g.label),
                        Wrap(
                          spacing: d.space(8),
                          runSpacing: d.space(4),
                          children: [
                            for (final o in g.options)
                              SsFilterChip(
                                o.label,
                                selected: (_draft[g.param] ?? const []).contains(o.value),
                                onTap: () => _muda(SsFilters.toggle(_draft, g, o.value)),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.line)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Semantics(
                    liveRegion: true,
                    child: SsButton(
                      label: rotulo,
                      loading: _contando && _n == null,
                      onPressed: () => widget.onApply(_draft),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Os chips do que está ativo (o × tira), com a animação de entrar e sair.
class _Ativos extends StatelessWidget {
  const _Ativos({required this.ativos, required this.onRemove});
  final List<SsActiveFilter> ativos;
  final ValueChanged<SsActiveFilter> onRemove;

  @override
  Widget build(BuildContext context) {
    final s = SsStrings.of(context);
    final d = SsDensity.of(context);
    final Widget corpo = ativos.isEmpty
        ? const SizedBox(width: double.infinity)
        : Semantics(
            container: true,
            label: s.filtersActive,
            child: Padding(
              padding: EdgeInsets.only(bottom: d.space(4)),
              child: Wrap(
                spacing: d.space(6),
                runSpacing: d.space(4),
                children: [
                  for (final a in ativos)
                    SsInputChip(
                      '${a.group.label}: ${a.label}',
                      deleteTooltip: s.filterRemove(a.group.label, a.label),
                      onDeleted: () => onRemove(a),
                    ),
                ],
              ),
            ),
          );
    if (reduceMotion(context)) return corpo;
    return AnimatedSize(
      duration: SsMotion.medium,
      curve: SsMotion.standard,
      alignment: Alignment.topCenter,
      child: corpo,
    );
  }
}

/// Barra de filtros (v1.10, par do `Ss::FilterBarComponent`): visões salvas em chips, busca opcional,
/// o botão "Filtros" com o número de ativos (abre a [SsFilterSheet]), os chips do que está ativo
/// (o × tira só aquele valor) e "Limpar filtros". Quem guarda os filtros é o app: a barra só chama
/// [onChanged] com os novos valores (a mesma ideia do GET do web).
///
/// ```dart
/// SsFilterBar(
///   filters: const [SsFilterGroup(param: 'status', label: 'Situação',
///     options: [SsFilterOption('Pago', 'pago'), SsFilterOption('Vencido', 'vencido')])],
///   values: filtros, onChanged: (v) => setState(() => filtros = v),
///   count: (v) => titulos.where((t) => casa(t, v)).length,
/// )
/// ```
class SsFilterBar extends StatelessWidget {
  const SsFilterBar({
    super.key,
    required this.filters,
    required this.values,
    required this.onChanged,
    this.views = const [],
    this.count,
    this.onSearch,
    this.searchHint,
    this.title,
  });

  final List<SsFilterGroup> filters;
  final SsFilterValues values;
  final ValueChanged<SsFilterValues> onChanged;
  final List<SsFilterView> views;

  /// Contagem ao vivo da folha ("Mostrar 12 resultados").
  final SsFilterCounter? count;

  /// Com ele, a barra mostra o campo de busca (o `search:` do web).
  final ValueChanged<String>? onSearch;
  final String? searchHint;

  /// Título da folha (padrão: [SsStrings.filters]).
  final String? title;

  Future<void> _abrir(BuildContext context) async {
    final v = await showSsFilterSheet(context, filters: filters, values: values, count: count, title: title);
    if (v != null) onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final s = SsStrings.of(context);
    final d = SsDensity.of(context);
    final ativos = SsFilters.active(filters, values);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (views.isNotEmpty)
          SsChipBar(
            padding: EdgeInsets.only(bottom: d.space(8)),
            children: [
              for (final v in views)
                SsFilterChip(
                  v.label,
                  selected: SsFilters.same(v.values, values),
                  count: v.count,
                  onTap: () => onChanged({
                    for (final e in v.values.entries) e.key: [...e.value],
                  }),
                ),
            ],
          ),
        if (onSearch != null) ...[
          SsSearchField(hint: searchHint, onChanged: onSearch, debounce: SsMotion.long),
          SizedBox(height: d.space(8)),
        ],
        Wrap(
          spacing: d.space(6),
          runSpacing: d.space(4),
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (filters.isNotEmpty) _BotaoFiltros(n: ativos.length, onTap: () => _abrir(context)),
            for (final a in ativos)
              SsInputChip(
                '${a.group.label}: ${a.label}',
                deleteTooltip: s.filterRemove(a.group.label, a.label),
                onDeleted: () => onChanged(SsFilters.remove(values, a.group.param, a.value)),
              ),
            if (ativos.isNotEmpty) SsButton.text(label: s.filterClear, onPressed: () => onChanged({})),
          ],
        ),
      ],
    );
  }
}

class _BotaoFiltros extends StatelessWidget {
  const _BotaoFiltros({required this.n, required this.onTap});
  final int n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    final on = n > 0;
    final fg = on ? c.accentText : c.ink2;
    return SsTapTarget(
      semantics: true,
      child: Semantics(
        container: true,
        button: true,
        label: s.filterButton(n),
        excludeSemantics: true,
        child: SsPressable(
          onTap: onTap,
          child: AnimatedContainer(
            duration: reduceMotion(context) ? Duration.zero : SsMotion.short,
            height: d.chipHeight,
            padding: EdgeInsets.symmetric(horizontal: d.padX - 4),
            decoration: BoxDecoration(
              color: on ? c.accentSoft : c.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: on ? Colors.transparent : c.line, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune_rounded, size: 17, color: fg),
                SizedBox(width: d.space(6)),
                Text(
                  s.filters,
                  style: TextStyle(color: fg, fontSize: d.font(AppType.sub), fontWeight: FontWeight.w700),
                ),
                if (on) ...[
                  SizedBox(width: d.space(6)),
                  Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.accentSolid,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '$n',
                      style: AppTheme.number(
                        context,
                        size: AppType.meta,
                        weight: FontWeight.w600,
                        color: AppColors.onDark,
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
