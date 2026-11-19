import 'package:material_ui/material_ui.dart';

import '../ss_strings.dart';
import '../v27/side_menu.dart';

/// v1.6 · Ajuda no menu lateral (par do `Ss::HelpMenuComponent` do web): a seção "Ajuda" com **Aprenda** (as
/// videoaulas) e **Novidades** (o que mudou), as duas abrindo fora do app (ícone de saída e "abre no navegador"
/// para o leitor de tela). Com [unseenNews] > 0, a linha Novidades ganha o selo "2 novas" na cor da marca.
///
/// Abrir a página (navegador ou aba personalizada) e guardar o "visto até" é do app: no [onNews], marque como
/// visto e abra. Sem [onNews] (produto que ainda não publicou novidade), só Aprenda. [extra] soma linhas.
///
/// ```dart
/// SsSideMenu(sections: [
///   ...,
///   SsHelpMenu.section(context, onLearn: () => abrir(aprenda), onNews: () => abrirNovidades(), unseenNews: 2),
/// ])
/// ```
abstract final class SsHelpMenu {
  static SsSideMenuSection section(
    BuildContext context, {
    required VoidCallback onLearn,
    VoidCallback? onNews,
    int unseenNews = 0,
    List<SsSideMenuItem> extra = const [],
    String? title,
  }) {
    final s = SsStrings.of(context);
    final n = onNews == null ? 0 : unseenNews.clamp(0, 99);
    return SsSideMenuSection([
      SsSideMenuItem(Icons.school_outlined, s.helpLearn, subtitle: s.helpLearnNote, onTap: onLearn, external: true),
      if (onNews != null)
        SsSideMenuItem(
          Icons.auto_awesome_outlined,
          s.helpNews,
          subtitle: s.helpNewsNote,
          onTap: onNews,
          external: true,
          badgeLabel: n > 0 ? s.helpNewsUnseen(n) : null,
        ),
      ...extra,
    ], title: title ?? s.helpTitle);
  }
}
