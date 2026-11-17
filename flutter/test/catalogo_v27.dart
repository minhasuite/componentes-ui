// v0.27: menu lateral com a dica de arrastar (SsSideMenu/SsSideMenuHost) e a casca SsNavScaffold
// (faixa acima da SsNavBar transparente).
import 'package:componentes_ui/componentes_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'catalogo.dart';

const _abas = [
  SsNavItem(Icons.people_alt_outlined, 'Carteira', activeIcon: Icons.people_alt_rounded),
  SsNavItem(Icons.receipt_long_outlined, 'Pedidos', activeIcon: Icons.receipt_long_rounded, badge: 2),
  SsNavItem(Icons.route_outlined, 'Agenda', activeIcon: Icons.route_rounded),
  SsNavItem(Icons.menu_outlined, 'Mais', activeIcon: Icons.menu_rounded),
];

class _Lista extends StatelessWidget {
  const _Lista();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      for (var i = 1; i <= 12; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SsCard(
            child: SsListItem(title: 'Cliente $i', subtitle: 'Último pedido há $i dias'),
          ),
        ),
    ],
  );
}

/// Casca com a lista rolada até o fim (o conteúdo passa por trás da faixa do círculo).
class _Casca extends StatefulWidget {
  const _Casca({this.abrir = false, this.dica});
  final bool abrir;

  /// Instante da dica (0..1) para a captura.
  final double? dica;

  @override
  State<_Casca> createState() => _CascaState();
}

class _CascaState extends State<_Casca> {
  final _k = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.abrir) {
      WidgetsBinding.instance.addPostFrameCallback((_) => SsSideMenuHost.maybeOf(_k.currentContext!)?.open());
    }
  }

  @override
  Widget build(BuildContext context) => SsNavScaffold(
    peek: false,
    debugHintAt: widget.dica,
    navBar: SsNavBar(items: _abas, currentIndex: 0, onTap: (_) {}),
    sideMenu: const SsSideMenu(
      title: 'Minhas Vendas',
      subtitle: 'ana@exemplo.com',
      icon: Icons.storefront_rounded,
      version: '1.4.0 (123)',
      sections: [
        SsSideMenuSection(title: 'Atalhos', [
          SsSideMenuItem(Icons.sync, 'Sincronização', subtitle: 'Tudo enviado'),
          SsSideMenuItem(Icons.devices_outlined, 'Sessões'),
        ]),
      ],
    ),
    body: KeyedSubtree(key: _k, child: const _Lista()),
  );
}

final List<Componente> _novos = [
  Componente(
    'ss-side-menu',
    'SsSideMenu + SsSideMenuHost',
    'Menu lateral do app (v0.27): abre arrastando da borda esquerda e, a cada abertura do app, espia para ensinar o gesto.',
    comportamentos: [
      'Abre arrastando da borda esquerda (a faixa fica depois do gesto de voltar do Android), por SsSideMenuHost.maybeOf(context)?.open() ou pelo leitor de tela ("Abrir o menu").',
      'Abre com a mola da suíte (passa um pouco e assenta); fecha arrastando de volta, tocando fora, no voltar do sistema ou ao tocar numa linha.',
      'As linhas entram em cascata: com o painel abrindo, as de baixo ficam para trás e mais apagadas e alcançam as de cima no fim.',
      'Dica ao abrir o app (uma vez por abertura): o painel abre uma fresta com a coluna de ícones e volta, e a borda pisca duas vezes na cor da marca (v1.1: sem a pílula de texto). A tela segue usável; tocar na fresta abre o menu. Sem dica com "reduzir movimento".',
      'v1.1: cartão do topo no gradiente da marca, com o ícone do app (icon:), o nome na fonte de exibição e a conta embaixo; no pé, a versão do app (version:) e a do componentes_ui num tom apagado.',
      'v1.1: tela principal com SsScreenHeader ou SsTopBar dentro do menu ganha sozinha o botão de menu (o lugar da seta de voltar).',
      'Linha atual com fundo na marca suave, ícone cheio e negrito; contagem à direita (99+); danger em vermelho.',
      'No SsNavScaffold as abas entram como 1ª seção, com a aba atual marcada.',
    ],
    estados: [
      Estado('aberto', 'aberto', (_) => const _Casca(abrir: true), tamanho: const Size(390, 760), aguarde: 1200),
      Estado(
        'espiando',
        'dica ao abrir o app: a fresta e a pílula',
        (_) => const _Casca(dica: .3),
        tamanho: const Size(390, 760),
      ),
      Estado(
        'borda',
        'dica ao abrir o app: a borda pisca',
        (_) => const _Casca(dica: .64),
        tamanho: const Size(390, 360),
      ),
    ],
  ),
  Componente(
    'ss-nav-scaffold',
    'SsNavScaffold',
    'Casca única das abas (v0.27): Scaffold com a SsNavBar, o menu lateral opcional e o voltar que leva à 1ª aba.',
    comportamentos: [
      'A faixa acima da barra (onde o círculo sobe) é transparente: o conteúdo passa por trás dela em vez de ser cortado por uma tira do fundo.',
      'O corpo recebe MediaQuery.padding.bottom = SsNavBar.rise: lista com padding padrão e SafeArea não ficam embaixo do círculo.',
      'Voltar do sistema: fecha o menu se aberto; fora da 1ª aba, vai para ela; na 1ª aba, sai.',
    ],
    estados: [
      Estado('lista', 'lista no fim, passando por trás da faixa', (_) => const _Casca(), tamanho: const Size(390, 760)),
    ],
  ),
];

List<Componente> comV27(List<Componente> base) => [...base, ..._novos];
