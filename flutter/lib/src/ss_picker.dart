import 'dart:async';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'ss_controls.dart';
import 'ss_error_view.dart';
import 'ss_list.dart';
import 'ss_sheet.dart';

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
Future<T?> showSsPicker<T>(
  BuildContext context, {
  required String title,
  Future<List<T>> Function(String query)? load,
  List<T>? items,
  String Function(T item)? labelOf,
  Widget Function(BuildContext context, T item)? itemBuilder,
  String emptyText = 'Nada encontrado',
  String hint = 'Buscar',
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: false,
  builder: (context) => SsPickerSheet<T>(
    title: title,
    load: load,
    items: items,
    labelOf: labelOf,
    itemBuilder: itemBuilder,
    emptyText: emptyText,
    hint: hint,
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
    this.emptyText = 'Nada encontrado',
    this.hint = 'Buscar',
  }) : assert(load != null || items != null, 'Passe load ou items');

  final String title;
  final ValueChanged<T> onSelect;
  final Future<List<T>> Function(String query)? load;
  final List<T>? items;
  final String Function(T item)? labelOf;
  final Widget Function(BuildContext context, T item)? itemBuilder;
  final String emptyText;
  final String hint;

  @override
  State<SsPickerSheet<T>> createState() => _SsPickerSheetState<T>();
}

class _SsPickerSheetState<T> extends State<SsPickerSheet<T>> {
  String _q = '';
  List<T> _result = const [];
  bool _loading = false;
  Object? _error;
  Timer? _debounce;
  int _seq = 0;

  String _label(T e) => widget.labelOf?.call(e) ?? '$e';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
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
    final Widget body;
    if (_loading && _result.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = SsErrorView(message: 'Não deu para carregar.', onRetry: _fetch);
    } else if (_result.isEmpty) {
      body = Center(
        child: Semantics(
          liveRegion: true,
          child: Text(
            widget.emptyText,
            style: TextStyle(color: c.muted, fontSize: AppType.body),
          ),
        ),
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: _result.length,
        itemBuilder: (context, i) {
          final e = _result[i];
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
              child: SsSearchField(hint: widget.hint, onChanged: _onQuery, autofocus: widget.load != null),
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
