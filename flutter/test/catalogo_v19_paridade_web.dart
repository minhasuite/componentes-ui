// v1.9 · paridade web ([comV19ParidadeWeb]): a UX transversal do app (barra que some ao rolar, busca no menu
// lateral, sincronização completa, toque longo e deslizar no item). Os pares web das peças do Flutter estão
// no rails/catalogo/index.html.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'catalogo.dart';

const _abas = [
  SsNavItem(Icons.people_alt_outlined, 'Carteira', activeIcon: Icons.people_alt_rounded),
  SsNavItem(Icons.receipt_long_outlined, 'Pedidos', activeIcon: Icons.receipt_long_rounded),
  SsNavItem(Icons.menu_outlined, 'Mais', activeIcon: Icons.menu_rounded),
];

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

/// Lista rolada para baixo logo depois do 1º quadro: a barra está escondida na captura.
class _Rolada extends StatefulWidget {
  const _Rolada({required this.rolar});
  final bool rolar;

  @override
  State<_Rolada> createState() => _RoladaState();
}

class _RoladaState extends State<_Rolada> {
  final _s = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.rolar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_s.hasClients) _s.position.moveTo(400, duration: const Duration(milliseconds: 120));
      });
    }
  }

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SsNavScaffold(
    peek: false,
    hideNavOnScroll: true,
    navBar: SsNavBar(items: _abas, currentIndex: 1, onTap: (_) {}),
    body: ListView.builder(
      controller: _s,
      padding: const EdgeInsets.all(16),
      itemCount: 30,
      itemBuilder: (_, i) => SsListItem(
        title: 'Pedido ${120 + i}',
        subtitle: 'Mercado Bom Preço',
        value: 'R\$ ${(i + 1) * 37},00',
        icon: Icons.receipt_long_outlined,
      ),
    ),
  );
}

final _telas = [
  SsCommand(Icons.people_alt_outlined, 'Carteira', group: 'Telas', onRun: () {}),
  SsCommand(Icons.receipt_long_outlined, 'Pedidos', group: 'Telas', onRun: () {}),
];

final _v19ParidadeWeb = <Componente>[
  Componente(
    'ss-nav-hide',
    'SsNavBar(hideOnScroll:) · SsNavScaffold(hideNavOnScroll:)',
    'Barra de abas que some ao rolar para baixo e volta ao rolar para cima (v1.9): mais tela para a lista no celular.',
    comportamentos: [
      'Rolar a lista principal 24 px para baixo esconde (a barra desce para fora); 24 px para cima, chegar ao topo ou trocar de aba mostra.',
      'No SsNavScaffold o corpo ganha a altura da barra enquanto ela está escondida; navBar.hideOnScroll: true vale o mesmo.',
      'SsNavBar(hideOnScroll: true) solto escuta o ScrollNotificationObserver do Scaffold (o mesmo do AppBar).',
      'Leitor de tela ligado: nunca some. Reduzir movimento: some e volta sem animar. Escondida, sai do foco do teclado.',
    ],
    estados: [
      Estado('visivel', 'no topo da lista', (_) => const _Rolada(rolar: false), tamanho: const Size(360, 640)),
      Estado(
        'escondida',
        'depois de rolar para baixo',
        (_) => const _Rolada(rolar: true),
        tamanho: const Size(360, 640),
        aguarde: 900,
      ),
    ],
  ),
  Componente(
    'ss-side-search',
    'SsSideMenu(search: SsSideMenuSearch(...))',
    'Busca no topo do menu lateral (v1.9): abre a paleta de comandos com telas, ações e os registros do app; Ctrl+K com teclado.',
    comportamentos: [
      'A linha parece um campo (lupa e "Buscar"); tocar fecha o menu e abre o showSsCommandPalette.',
      'commands/recent: telas e ações; records: (texto) → registros do servidor, 250 ms depois da última tecla, depois das telas.',
      'Ctrl+K (⌘K no Mac) abre de qualquer tela do SsSideMenuHost/SsNavScaffold; com a paleta aberta, não abre outra.',
      'No computador mostra o atalho ("Ctrl K"); no celular, não. Par do Ctrl+K do Ss::AppShellComponent.',
    ],
    estados: [
      Estado(
        'menu',
        'painel com a busca no topo',
        (_) => SizedBox(
          width: 320,
          child: Material(
            child: SsSideMenu(
              title: 'Minhas Vendas',
              subtitle: 'ana@exemplo.com',
              icon: Icons.storefront_rounded,
              search: SsSideMenuSearch(commands: _telas),
              sections: [
                SsSideMenuSection([
                  SsSideMenuItem(Icons.settings_outlined, 'Configurações', onTap: () {}),
                  SsSideMenuItem(Icons.help_outline_rounded, 'Ajuda', onTap: () {}),
                ]),
              ],
            ),
          ),
        ),
        tamanho: const Size(320, 520),
      ),
    ],
  ),
  Componente(
    'ss-sync-panel',
    'SsSyncPanel · SsSyncStatus(failedCount:, lastSyncedAt:)',
    'Sincronização completa (v1.9, como no minhas-vendas-app): o cartão da fila e a pílula com erro e a última vez.',
    comportamentos: [
      'SsSyncStatus.resolve(syncing:, failed:, offline:, pending:): enviando > com erro > sem conexão > pendente > tudo salvo.',
      'failedCount troca "Falhou · Tentar de novo" por "2 com erro"; lastSyncedAt vai na dica e no leitor de tela.',
      'SsSyncPanel: "Sincronizado às 14:32" (ou "em 12/11", "Nunca sincronizado"), o erro, a pílula, details e "Sincronizar agora".',
      'Enviando, o botão fica carregando e não toca. Só app: o web salva direto (o par é o Ss::SyncStatusComponent).',
    ],
    estados: [
      Estado(
        'erro',
        'com erro e sem conexão',
        (_) => _pad(
          SsSyncPanel(
            state: SsSyncState.failed,
            pendingCount: 3,
            failedCount: 1,
            lastSyncedAt: DateTime(2026, 11, 24, 14, 32),
            now: DateTime(2026, 11, 24, 18),
            error: 'Sem conexão: usando os dados do aparelho.',
            details: '120 clientes · 40 pedidos no aparelho',
            onSyncNow: () {},
          ),
        ),
        tamanho: const Size(360, 260),
      ),
      Estado(
        'enviando',
        'sincronizando',
        (_) => _pad(SsSyncPanel(state: SsSyncState.sending, pendingCount: 2, onSyncNow: () {})),
        tamanho: const Size(360, 170),
      ),
    ],
  ),
  Componente(
    'ss-list-item-acoes',
    'SsListItem(contextActions:, swipeStart:, swipeEnd:)',
    'Toque longo e deslizar padronizados no item de lista (v1.9).',
    comportamentos: [
      'contextActions: o toque longo abre o SsContextMenu (o item levanta e as ações aparecem); ganha do onLongPress.',
      'swipeStart/swipeEnd: o SsSwipeAction (para a direita e para a esquerda); destrutiva encolhe o item.',
      'Leitor de tela: as ações do menu e dos lados viram ações personalizadas do item.',
      'No web as mesmas ações vão no menu ⋮ (Ss::RowActionsComponent).',
    ],
    estados: [
      Estado(
        'item',
        'item com menu e deslizar',
        (_) => _pad(
          SsListItem(
            title: 'Pedido 124',
            subtitle: 'Mercado Bom Preço',
            value: 'R\$ 148,00',
            icon: Icons.receipt_long_outlined,
            onTap: () {},
            contextActions: [
              SsContextAction(Icons.edit_outlined, 'Editar', () {}),
              SsContextAction(Icons.delete_outline, 'Excluir', () {}, destructive: true),
            ],
            swipeEnd: SsSwipeSide(
              icon: Icons.archive_outlined,
              label: 'Arquivar',
              color: AppColors.danger,
              onTrigger: () {},
            ),
          ),
        ),
      ),
    ],
  ),
];

List<Componente> comV19ParidadeWeb(List<Componente> base) => [...base, ..._v19ParidadeWeb];
