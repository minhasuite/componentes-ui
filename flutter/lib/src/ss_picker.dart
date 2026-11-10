import 'dart:async';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'motion_view.dart';
import 'ss_controls.dart';
import 'ss_error_view.dart';
import 'ss_list.dart';
import 'ss_sheet.dart';
import 'ss_strings.dart';

const _com = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
const _sem = 'aaaaaeeeeiiiiooooouuuucn';

/// Texto sem acento e em minúsculas, para busca: "Ação" → "acao".
String foldAccents(String s) {
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = _com.indexOf(ch);
    b.write(i < 0 ? ch : _sem[i]);
  }
  return b.toString();
}

/// Folha alta de busca e escolha (cliente, produto, lugar). Devolve o item
/// tocado, ou nulo se fechar. Passe [load] (busca no servidor, com debounce de
/// 300 ms) ou [items] (lista local, filtrada sem acento por [labelOf]).
/// [itemBuilder] troca a linha padrão ([SsListItem] com [labelOf]).
///
/// v0.16: [allowCustom] deixa escolher da lista **ou** usar o que foi
/// digitado (loja nova, cliente novo): a 1ª linha vira "Usar “texto”"
/// ([customLabel]) quando o texto não é igual a um item, e o Enter do teclado
/// também usa o texto. [customOf] transforma o texto em `T` (padrão: o
/// próprio texto, para `showSsPicker<String>`). [noneLabel] ("Sem loja") põe
/// no topo, com a busca vazia, a linha que devolve `customOf('')`.
///
/// ```dart
/// final loja = await showSsPicker<String>(context, title: 'Onde comprou?',
///   load: (q) async => (await repo.stores(q)).map((s) => s.label).toList(),
///   allowCustom: true, noneLabel: 'Sem loja', hint: 'Feira, padaria, mercado…');
/// ```
Future<T?> showSsPicker<T>(
  BuildContext context, {
  required String title,
  Future<List<T>> Function(String query)? load,
  List<T>? items,
  String Function(T item)? labelOf,
  Widget Function(BuildContext context, T item)? itemBuilder,
  String? emptyText,
  String? hint,
  String initialQuery = '',
  bool allowCustom = false,
  T Function(String text)? customOf,
  String Function(String text)? customLabel,
  String? noneLabel,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: false,
  // Sobe com mola, como a [showSsSheet].
  sheetAnimationStyle: SsOverlayMotion.sheet(context),
  builder: (context) => SsPickerSheet<T>(
    title: title,
    load: load,
    items: items,
    labelOf: labelOf,
    itemBuilder: itemBuilder,
    emptyText: emptyText,
    hint: hint,
    initialQuery: initialQuery,
    allowCustom: allowCustom,
    customOf: customOf,
    customLabel: customLabel,
    noneLabel: noneLabel,
    onSelect: (v) => Navigator.pop(context, v),
  ),
);

/// O corpo do [showSsPicker] (público para o catálogo e para quem monta a
/// própria rota): busca fixa no topo e a lista embaixo, em 90% da altura.
class SsPickerSheet<T> extends StatefulWidget {
  const SsPickerSheet({
    super.key,
    required this.title,
    required this.onSelect,
    this.load,
    this.items,
    this.labelOf,
    this.itemBuilder,
    this.emptyText,
    this.hint,
    this.initialQuery = '',
    this.allowCustom = false,
    this.customOf,
    this.customLabel,
    this.noneLabel,
  }) : assert(load != null || items != null, 'Passe load ou items');

  /// v0.16: usar o texto digitado (ver [showSsPicker]).
  final bool allowCustom;

  /// Texto → item. Padrão: o próprio texto (só serve com T = String; outro T, passe este).
  final T Function(String text)? customOf;

  /// Padrão: [SsStrings.useCustom] ("Usar “Feira”").
  final String Function(String text)? customLabel;

  /// Linha do topo com a busca vazia ("Sem loja"): devolve `customOf('')`.
  final String? noneLabel;

  final String title;
  final ValueChanged<T> onSelect;
  final Future<List<T>> Function(String query)? load;
  final List<T>? items;
  final String Function(T item)? labelOf;
  final Widget Function(BuildContext context, T item)? itemBuilder;

  /// Padrão: [SsStrings.nothingFound].
  final String? emptyText;

  /// Padrão: [SsStrings.search].
  final String? hint;

  /// Busca já preenchida ao abrir (o texto que a pessoa digitou no campo).
  final String initialQuery;

  @override
  State<SsPickerSheet<T>> createState() => _SsPickerSheetState<T>();
}

class _SsPickerSheetState<T> extends State<SsPickerSheet<T>> {
  late String _q = widget.initialQuery;
  late final _ctrl = TextEditingController(text: widget.initialQuery);
  List<T> _result = const [];
  bool _loading = false;
  Object? _error;
  Timer? _debounce;
  int _seq = 0;

  String _label(T e) => widget.labelOf?.call(e) ?? '$e';

  T _custom(String text) => widget.customOf != null ? widget.customOf!(text) : text as T;

  /// O texto digitado vale como escolha (não vazio e diferente de todo item).
  bool get _mostraCustom {
    if (!widget.allowCustom) return false;
    final q = _q.trim();
    if (q.isEmpty) return false;
    final f = foldAccents(q);
    return !_result.any((e) => foldAccents(_label(e).trim()) == f);
  }

  void _usarTexto() {
    final q = _q.trim();
    if (q.isEmpty) return;
    final f = foldAccents(q);
    final igual = _result.where((e) => foldAccents(_label(e).trim()) == f);
    widget.onSelect(igual.isNotEmpty ? igual.first : _custom(q));
  }

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onQuery(String q) {
    _q = q;
    if (widget.load == null) {
      _fetch();
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _fetch);
  }

  Future<void> _fetch() async {
    if (widget.load == null) {
      final q = foldAccents(_q.trim());
      setState(() => _result = widget.items!.where((e) => foldAccents(_label(e)).contains(q)).toList());
      return;
    }
    final seq = ++_seq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await widget.load!(_q.trim());
      if (!mounted || seq != _seq) return;
      setState(() {
        _result = r;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final mq = MediaQuery.of(context);
    final kb = mq.viewInsets.bottom;
    final s = SsStrings.of(context);
    final extras = <Widget>[
      if (widget.noneLabel != null && _q.trim().isEmpty)
        SsListItem(
          leading: Icon(Icons.remove_circle_outline_rounded, color: c.muted),
          title: widget.noneLabel!,
          onTap: () => widget.onSelect(_custom('')),
        ),
      if (_mostraCustom)
        SsListItem(
          leading: Icon(Icons.add_circle_outline_rounded, color: c.accentText),
          title: (widget.customLabel ?? s.useCustom)(_q.trim()),
          onTap: () => widget.onSelect(_custom(_q.trim())),
        ),
    ];
    final Widget body;
    if (extras.isNotEmpty && _result.isEmpty) {
      body = ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), children: extras);
    } else if (_loading && _result.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = SsErrorView(message: SsStrings.of(context).loadFailed, onRetry: _fetch);
    } else if (_result.isEmpty) {
      body = Center(
        child: Semantics(
          liveRegion: true,
          child: Text(
            widget.emptyText ?? SsStrings.of(context).nothingFound,
            style: TextStyle(color: c.muted, fontSize: AppType.body),
          ),
        ),
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: extras.length + _result.length,
        itemBuilder: (context, i) {
          if (i < extras.length) return extras[i];
          final e = _result[i - extras.length];
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => widget.onSelect(e),
            child: widget.itemBuilder?.call(context, e) ?? SsListItem(title: _label(e)),
          );
        },
      );
    }
    return Padding(
      padding: EdgeInsets.only(bottom: kb),
      child: SizedBox(
        height: (mq.size.height - kb) * .9,
        child: Column(
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
            Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 12), child: SsSheetHeader(widget.title)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SsSearchField(
                controller: _ctrl,
                hint: widget.hint ?? SsStrings.of(context).search,
                onChanged: _onQuery,
                onSubmitted: widget.allowCustom ? (_) => _usarTexto() : null,
                autofocus: widget.load != null || widget.allowCustom,
              ),
            ),
            SizedBox(height: 2, child: _loading && _result.isNotEmpty ? const LinearProgressIndicator() : null),
            const SizedBox(height: 6),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
