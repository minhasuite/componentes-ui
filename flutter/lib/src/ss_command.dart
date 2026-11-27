import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'density.dart';
import 'motion.dart';
import 'ss_list.dart';
import 'ss_strings.dart';

/// Um comando da [showSsCommandPalette]: o que aparece ([icon], [label]),
/// palavras extras que também acham ([keywords]), o grupo do cabeçalho e o
/// que fazer ([onRun], chamado depois que a paleta fecha).
///
/// v1.14.1: [subtitle] é a segunda linha, menor e apagada (o cômodo de um
/// aparelho, a loja de um cliente); entra na busca e no leitor de tela.
/// Par do `subtitle:` do item do `Ss::CommandPaletteComponent`.
class SsCommand {
  const SsCommand(this.icon, this.label, {this.keywords = const [], this.group, this.subtitle, required this.onRun});

  final IconData icon;
  final String label;

  /// v1.14.1: a segunda linha ("Sala", "Loja Centro · 3 pedidos").
  final String? subtitle;
  final List<String> keywords;
  final String? group;
  final VoidCallback onRun;
}

/// Busca global ("ir para…", "novo pedido") num diálogo de topo: filtra por
/// rótulo e palavras-chave sem ligar para acento ou maiúscula, agrupa por
/// `group` e destaca o trecho que casou. Enter ou toque executa e fecha.
/// Sem busca, mostra [recent] (ou tudo, se não houver recentes).
Future<void> showSsCommandPalette(
  BuildContext context, {
  required List<SsCommand> commands,
  List<SsCommand> recent = const [],
  String? hint,
  String initialQuery = '',
  Future<List<SsCommand>> Function(String query)? search,
}) {
  final rapido = reduceMotion(context);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: SsStrings.of(context).close,
    barrierColor: Colors.black.withValues(alpha: .45),
    transitionDuration: rapido ? Duration.zero : SsMotion.medium,
    pageBuilder: (ctx, _, _) => SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SsCommandPalette(
              commands: commands,
              recent: recent,
              hint: hint,
              initialQuery: initialQuery,
              search: search,
              onSelected: (cmd) {
                Navigator.of(ctx).pop();
                cmd.onRun();
              },
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (_, a, _, child) => FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, -.06),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)),
        child: child,
      ),
    ),
  );
}

/// O painel da paleta (o que o [showSsCommandPalette] abre). Público para
/// catálogo e para quem quer a busca dentro de outra tela.
class SsCommandPalette extends StatefulWidget {
  const SsCommandPalette({
    super.key,
    required this.commands,
    required this.onSelected,
    this.recent = const [],
    this.hint,
    this.initialQuery = '',
    this.search,
  });

  /// v1.9: registros do servidor (clientes, pedidos) para o texto digitado, 250 ms depois da última tecla;
  /// entram depois das telas e ações, com o grupo de cada um. Enquanto busca, uma barra fina corre embaixo
  /// do campo. Erro conta como nada achado. O par do `src:` do `Ss::CommandPaletteComponent`.
  final Future<List<SsCommand>> Function(String query)? search;

  final List<SsCommand> commands;
  final List<SsCommand> recent;

  /// Padrão: [SsStrings.commandHint].
  final String? hint;
  final String initialQuery;
  final ValueChanged<SsCommand> onSelected;

  @override
  State<SsCommandPalette> createState() => _SsCommandPaletteState();
}

const _acentos = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', //
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', //
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', //
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', //
  'ç': 'c', 'ñ': 'n',
};

/// Minúscula e sem acento, **com o mesmo comprimento** (o destaque usa os índices).
String _fold(String s) => s.split('').map((ch) {
  final l = ch.toLowerCase();
  return l.length == 1 ? (_acentos[l] ?? l) : ch;
}).join();

class _SsCommandPaletteState extends State<SsCommandPalette> {
  late final _ctrl = TextEditingController(text: widget.initialQuery);

  // v1.9: o que veio do [SsCommandPalette.search] e para qual texto.
  List<SsCommand> _remote = const [];
  String _remoteFor = '';
  bool _busy = false;
  Timer? _debounce;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.trim().isNotEmpty) _schedule();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _changed() {
    setState(() {});
    _schedule();
  }

  void _schedule() {
    final f = widget.search;
    if (f == null) return;
    _debounce?.cancel();
    final q = _ctrl.text.trim();
    if (q.isEmpty) {
      _token++;
      if (_busy || _remote.isNotEmpty) {
        setState(() {
          _busy = false;
          _remote = const [];
        });
      }
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final t = ++_token;
      setState(() => _busy = true);
      List<SsCommand> r;
      try {
        r = await f(q);
      } catch (_) {
        r = const [];
      }
      if (!mounted || t != _token) return;
      setState(() {
        _remote = r;
        _remoteFor = q;
        _busy = false;
      });
    });
  }

  List<String> get _termos => _fold(_ctrl.text).split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

  /// Quem casa no rótulo vem antes de quem só casa nas palavras-chave (e, v1.14.1, no subtítulo).
  List<SsCommand> _resultados() {
    final termos = _termos;
    if (termos.isEmpty) return widget.recent.isNotEmpty ? widget.recent : widget.commands;
    final noRotulo = <SsCommand>[], soChave = <SsCommand>[];
    for (final c in widget.commands) {
      final rotulo = _fold(c.label);
      final tudo = '$rotulo ${_fold(c.subtitle ?? '')} ${_fold(c.keywords.join(' '))}';
      if (!termos.every(tudo.contains)) continue;
      (termos.every(rotulo.contains) ? noRotulo : soChave).add(c);
    }
    final remotos = _remoteFor == _ctrl.text.trim() ? _remote : const <SsCommand>[];
    return [...noRotulo, ...soChave, ...remotos];
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final lista = _resultados();
    final buscando = _termos.isNotEmpty;
    final alturaMax = MediaQuery.sizeOf(context).height - MediaQuery.viewInsetsOf(context).bottom - 120;

    final linhas = <Widget>[];
    if (!buscando && widget.recent.isNotEmpty) {
      linhas.add(SsGroupHeader(SsStrings.of(context).recent));
      for (final cmd in lista) {
        linhas.add(_linha(cmd, false));
      }
    } else {
      // Grupos na ordem em que aparecem.
      final grupos = <String?, List<SsCommand>>{};
      for (final cmd in lista) {
        grupos.putIfAbsent(cmd.group, () => []).add(cmd);
      }
      for (final g in grupos.entries) {
        if (g.key != null) linhas.add(SsGroupHeader(g.key!));
        for (final cmd in g.value) {
          linhas.add(_linha(cmd, buscando && identical(cmd, lista.first)));
        }
      }
    }

    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(AppRadius.cardActive),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: BoxConstraints(maxHeight: alturaMax.clamp(200.0, 640.0)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.cardActive),
          border: c.isDark ? Border.all(color: c.line) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 22, color: c.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      onChanged: (_) => _changed(),
                      onSubmitted: (_) {
                        if (buscando && lista.isNotEmpty) widget.onSelected(lista.first);
                      },
                      textInputAction: TextInputAction.go,
                      style: TextStyle(color: c.ink, fontSize: AppType.md, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        hintText: widget.hint ?? SsStrings.of(context).commandHint,
                        hintStyle: TextStyle(color: c.muted, fontSize: AppType.md, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  if (_ctrl.text.isNotEmpty)
                    IconButton(
                      tooltip: SsStrings.of(context).clear,
                      icon: Icon(Icons.close_rounded, size: 20, color: c.muted),
                      onPressed: () {
                        _ctrl.clear();
                        _changed();
                      },
                    ),
                ],
              ),
            ),
            if (_busy)
              Semantics(
                label: SsStrings.of(context).loading,
                child: LinearProgressIndicator(minHeight: 1, color: c.accent, backgroundColor: c.line),
              )
            else
              Divider(height: 1, color: c.line),
            Flexible(
              child: lista.isEmpty && !_busy
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        SsStrings.of(context).nothingFoundFor(_ctrl.text.trim()),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: c.muted, fontSize: AppType.sub),
                      ),
                    )
                  : ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(8, 0, 8, 10), children: linhas),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linha(SsCommand cmd, bool primeiro) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final base = TextStyle(color: c.ink, fontSize: d.font(AppType.body), fontWeight: FontWeight.w500);
    final sub = cmd.subtitle?.trim() ?? '';
    final rotulo = Text.rich(
      TextSpan(children: _destaque(cmd.label, base)),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    // v1.14.1: o leitor lê as duas linhas juntas ("Luz do teto, Sala").
    return Semantics(
      button: true,
      label: sub.isEmpty ? null : '${cmd.label}, $sub',
      excludeSemantics: sub.isNotEmpty,
      child: Material(
        color: primeiro ? c.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(d.radiusField),
        child: InkWell(
          borderRadius: BorderRadius.circular(d.radiusField),
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onSelected(cmd);
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: d.rowPadV - 3),
            child: Row(
              children: [
                Container(
                  width: d.iconTile - 8,
                  height: d.iconTile - 8,
                  decoration: BoxDecoration(
                    color: c.accentSoft,
                    borderRadius: BorderRadius.circular(d.radiusField - 4),
                  ),
                  child: Icon(cmd.icon, size: d.iconSize - 1, color: c.accentText),
                ),
                SizedBox(width: d.gap),
                Expanded(
                  child: sub.isEmpty
                      ? rotulo
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            rotulo,
                            const SizedBox(height: 1),
                            Text.rich(
                              TextSpan(
                                children: _destaque(
                                  sub,
                                  TextStyle(
                                    color: c.muted,
                                    fontSize: d.font(AppType.meta),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                ),
                if (primeiro) Icon(Icons.keyboard_return_rounded, size: 16, color: c.accentText),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// O rótulo em trechos, com o que casou com cada termo em negrito.
  List<TextSpan> _destaque(String label, TextStyle base) {
    final f = _fold(label);
    final marca = List.filled(label.length, false);
    for (final t in _termos) {
      final i = f.indexOf(t);
      if (i >= 0) marca.fillRange(i, i + t.length, true);
    }
    final spans = <TextSpan>[];
    var ini = 0;
    for (var i = 1; i <= label.length; i++) {
      if (i == label.length || marca[i] != marca[ini]) {
        spans.add(
          TextSpan(
            text: label.substring(ini, i),
            style: marca[ini]
                ? base.copyWith(fontWeight: FontWeight.w800, color: SsColors.of(context).accentText)
                : base,
          ),
        );
        ini = i;
      }
    }
    return spans;
  }
}
