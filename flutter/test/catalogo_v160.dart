// v1.6: ajuda no menu lateral ([catalogoV160]: ss-help-menu), par do Ss::HelpMenuComponent.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'catalogo.dart';

Widget _menu({int novas = 0, bool comNovidades = true}) => Builder(
  builder: (context) => SsSideMenu(
    title: 'Minhas Vendas',
    subtitle: 'ana@loja.com.br',
    icon: Icons.storefront_outlined,
    sections: [
      SsSideMenuSection([SsSideMenuItem(Icons.home_outlined, 'Início', selected: true, onTap: () {})]),
      SsHelpMenu.section(context, onLearn: () {}, onNews: comNovidades ? () {} : null, unseenNews: novas),
    ],
  ),
);

final catalogoV160 = <Componente>[
  Componente(
    'ss-help-menu',
    'SsHelpMenu',
    'Ajuda no menu lateral (v1.6, par do Ss::HelpMenuComponent): a seção "Ajuda" com Aprenda (videoaulas) e Novidades, abrindo fora do app.',
    comportamentos: [
      'SsHelpMenu.section(context, onLearn:, onNews:, unseenNews:) devolve a SsSideMenuSection pronta, com os textos do SsStrings (pt/en/es).',
      'As duas linhas têm o ícone de saída (SsSideMenuItem.external) e "abre no navegador" para o leitor de tela.',
      'unseenNews > 0 põe o selo "2 novas" na cor da marca na linha Novidades (SsSideMenuItem.badgeLabel).',
      'Sem onNews (produto sem novidade publicada), só Aprenda. Abrir a página e gravar o visto é do app.',
    ],
    estados: [
      Estado('novas', 'com 2 novidades não vistas', (_) => _menu(novas: 2), tamanho: const Size(320, 420)),
      Estado('visto', 'tudo visto', (_) => _menu(), tamanho: const Size(320, 420)),
      Estado('so-aulas', 'sem novidades publicadas', (_) => _menu(comNovidades: false), tamanho: const Size(320, 420)),
    ],
  ),
];
