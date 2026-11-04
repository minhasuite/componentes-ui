import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'motion.dart';
import 'ss_list.dart';
import 'ss_strings.dart';

/// Um comando da [showSsCommandPalette]: o que aparece ([icon], [label]),
/// palavras extras que também acham ([keywords]), o grupo do cabeçalho e o
/// que fazer ([onRun], chamado depois que a paleta fecha).
class SsCommand {
  const SsCommand(this.icon, this.label, {this.keywords = const [], this.group, required this.onRun});

  final IconData icon;
  final String label;
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
}) {
  final rapido = reduceMotion(context);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: SsStrings.of(context).close,
    barrierColor: Colors.black.withValues(alpha: .45),
    transitionDuration: rapido ? Duration.zero : const Duration(milliseconds: 280),
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
  });

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

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<String> get _termos => _fold(_ctrl.text).split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

  /// Quem casa no rótulo vem antes de quem só casa nas palavras-chave.
  List<SsCommand> _resultados() {
    final termos = _termos;
    if (termos.isEmpty) return widget.recent.isNotEmpty ? widget.recent : widget.commands;
    final noRotulo = <SsCommand>[], soChave = <SsCommand>[];
    for (final c in widget.commands) {
      final rotulo = _fold(c.label);
      final tudo = '$rotulo ${_fold(c.keywords.join(' '))}';
      if (!termos.every(tudo.contains)) continue;
      (termos.every(rotulo.contains) ? noRotulo : soChave).add(c);
    }
    return [...noRotulo, ...soChave];
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
                      onChanged: (_) => setState(() {}),
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
                      onPressed: () => setState(_ctrl.clear),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: c.line),
            Flexible(
              child: lista.isEmpty
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
    final base = TextStyle(color: c.ink, fontSize: AppType.body, fontWeight: FontWeight.w500);
    return Semantics(
      button: true,
      child: Material(
        color: primeiro ? c.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.field),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.field),
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onSelected(cmd);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(10)),
                  child: Icon(cmd.icon, size: 19, color: c.accentText),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    TextSpan(children: _destaque(cmd.label, base)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
