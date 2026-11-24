// v1.9 · UX transversal: "Buscar" no topo do menu lateral, que abre a paleta de comandos, e o Ctrl+K.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../app_theme.dart';
import '../../density.dart';
import '../../motion.dart';
import '../../ss_command.dart';
import '../../ss_strings.dart';

/// A busca do [SsSideMenu] (`search:`): telas e ações ([commands], [recent]) e os registros do app
/// ([records], chamado com o texto digitado, 250 ms depois da última tecla; devolve [SsCommand]s com o
/// grupo que o app quiser, ex. "Clientes"). Abre o [showSsCommandPalette]. Par do
/// `Ss::CommandPaletteComponent` (src:) com o Ctrl+K do `Ss::AppShellComponent`.
///
/// ```dart
/// SsSideMenu(search: SsSideMenuSearch(commands: telas, records: (q) => api.buscar(q)), sections: [...])
/// ```
class SsSideMenuSearch {
  const SsSideMenuSearch({
    this.commands = const [],
    this.recent = const [],
    this.records,
    this.hint,
    this.label,
    this.shortcut = true,
  });

  /// Telas e ações (filtradas no aparelho, sem acento e sem caixa).
  final List<SsCommand> commands;

  /// O que aparece antes de digitar.
  final List<SsCommand> recent;

  /// Registros pelo servidor (clientes, pedidos); entram depois das telas e ações.
  final Future<List<SsCommand>> Function(String query)? records;

  /// Dica do campo da paleta (padrão: [SsStrings.commandHint]).
  final String? hint;

  /// O texto da linha no menu (padrão: [SsStrings.search]).
  final String? label;

  /// Ctrl+K (⌘K no Mac) abre a paleta com o menu aberto ou fechado, quando há teclado.
  final bool shortcut;

  /// Abre a paleta.
  Future<void> open(BuildContext context, {String initialQuery = ''}) => showSsCommandPalette(
    context,
    commands: commands,
    recent: recent,
    hint: hint,
    search: records,
    initialQuery: initialQuery,
  );

  /// O atalho mostrado na linha: "Ctrl K" ou "⌘K" no computador; nulo no celular (sem teclado à vista).
  static String? shortcutLabel([TargetPlatform? platform]) => switch (platform ?? defaultTargetPlatform) {
    TargetPlatform.macOS => '⌘K',
    TargetPlatform.windows || TargetPlatform.linux => 'Ctrl K',
    _ => null,
  };

  /// É o Ctrl+K (ou ⌘K) sem Shift nem Alt?
  static bool isShortcut(KeyEvent e, [HardwareKeyboard? keyboard]) {
    final k = keyboard ?? HardwareKeyboard.instance;
    return e is KeyDownEvent &&
        e.logicalKey == LogicalKeyboardKey.keyK &&
        (k.isControlPressed || k.isMetaPressed) &&
        !k.isShiftPressed &&
        !k.isAltPressed;
  }
}

/// A linha "Buscar" do topo do menu: parece um campo (lupa, o texto apagado e o atalho à direita) e abre a
/// paleta ao tocar.
class SsSideSearchRow extends StatelessWidget {
  const SsSideSearchRow({super.key, required this.search, required this.onOpen});

  final SsSideMenuSearch search;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    final label = search.label ?? s.search;
    final atalho = search.shortcut ? SsSideMenuSearch.shortcutLabel() : null;
    return Semantics(
      button: true,
      label: label,
      hint: search.hint ?? s.commandHint,
      excludeSemantics: true,
      child: SsPressable(
        onTap: onOpen,
        scale: .98,
        child: Container(
          constraints: BoxConstraints(minHeight: d.minTarget),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: c.field,
            borderRadius: BorderRadius.circular(d.radiusField),
            border: Border.all(color: c.line),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: 20, color: c.accentText),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.muted, fontSize: d.font(AppType.body), fontWeight: FontWeight.w600),
                ),
              ),
              if (atalho != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: c.line),
                  ),
                  child: Text(
                    atalho,
                    style: AppTheme.number(context, size: AppType.label, color: c.muted),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Escuta o Ctrl+K no teclado do aparelho (qualquer foco) enquanto [enabled] e a rota de [child] está no topo.
class SsSearchShortcut extends StatefulWidget {
  const SsSearchShortcut({super.key, required this.enabled, required this.onShortcut, required this.child});

  final bool enabled;
  final VoidCallback onShortcut;
  final Widget child;

  @override
  State<SsSearchShortcut> createState() => _SsSearchShortcutState();
}

class _SsSearchShortcutState extends State<SsSearchShortcut> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _onKey(KeyEvent e) {
    if (!widget.enabled || !mounted || !SsSideMenuSearch.isShortcut(e)) return false;
    // Com um diálogo por cima (a própria paleta), o atalho é dele.
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;
    widget.onShortcut();
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
