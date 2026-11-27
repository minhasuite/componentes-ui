// v1.9.3: o que mudou de visível com as correções da conferência no emulador (27/11/2026): a alça do menu fora
// do gesto de voltar do Android, o trilho até o topo, e o texto 1,6× na barra de abas, no card de indicador,
// no selo do sino e o milhar da cota. Extras das peças que já existiam, por slug, em [comV19Correcoes].
import 'package:componentes_ui/componentes_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'catalogo.dart';

void _nada() {}

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

/// O trecho com outro MediaQuery (texto grande, gesto do sistema, barra de status).
Widget _mq(BuildContext context, Widget child, {double? escala, EdgeInsets? gesto, EdgeInsets? padding}) {
  var mq = MediaQuery.of(context);
  if (escala != null) mq = mq.copyWith(textScaler: TextScaler.linear(escala));
  if (gesto != null) mq = mq.copyWith(systemGestureInsets: gesto);
  if (padding != null) mq = mq.copyWith(padding: padding, viewPadding: padding);
  return MediaQuery(data: mq, child: child);
}

const _abas = [
  SsNavItem(Icons.home_outlined, 'Início'),
  SsNavItem(Icons.receipt_long_outlined, 'Lançamentos'),
  SsNavItem(Icons.auto_awesome_outlined, 'Assistente'),
  SsNavItem(Icons.account_balance_wallet_outlined, 'Carteira'),
  SsNavItem(Icons.insights_outlined, 'Planejar'),
];

List<Componente> comV19Correcoes(List<Componente> base) => [
  for (final c in base)
    if (_v193[c.slug] case (final comp, final est))
      Componente(
        c.slug,
        c.nome,
        c.descricao,
        comportamentos: [...c.comportamentos, ...comp],
        estados: [...c.estados, ...est],
      )
    else
      c,
];

final Map<String, (List<String>, List<Estado>)> _v193 = {
  'ss-side-menu': (
    [
      'v1.9.3: a alça e a faixa de arrastar começam depois do gesto de voltar do sistema (systemGestureInsets.left): no Android com gestos, arrastar colado na borda é o "voltar" e fechava o app na 1ª aba. Com gesto, a pílula solta da borda (pontas arredondadas); tocar nela abre o menu. Sem gesto, colada como antes.',
    ],
    [
      Estado(
        'fora-do-gesto',
        'Android com gestos (24 dp): a alça depois da faixa do sistema',
        (ctx) => _mq(
          ctx,
          SsSideMenuHost(
            peek: false,
            menu: const SsSideMenu(title: 'Meu Financeiro', sections: []),
            child: Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final t in ['Contas', 'Cartões', 'Metas']) SsListItem(title: t, onTap: _nada),
                ],
              ),
            ),
          ),
          gesto: const EdgeInsets.only(left: 24, right: 24),
        ),
        tamanho: const Size(360, 300),
      ),
    ],
  ),
  'ss-side-rail': (
    [
      'v1.9.3: cada aba é um nó do leitor de tela com o toque ("Início, aba 1 de 5", selecionada); topo e rodapé (railHeader/railFooter) em grupo próprio. edgeToEdge (ligado no SsAdaptiveScaffold): o trilho pinta sob a barra de status e a de navegação, sem a faixa clara do SafeArea.',
    ],
    [
      Estado(
        'ate-o-topo',
        'SsAdaptiveScaffold com barra de status de 24: o trilho até o topo',
        (ctx) => _mq(
          ctx,
          SsAdaptiveScaffold(
            items: _abas,
            currentIndex: 2,
            onTap: (_) {},
            breakpoint: 600,
            railHeader: IconButton(onPressed: _nada, icon: const Icon(Icons.search), tooltip: 'Buscar'),
            body: const Center(child: Text('Assistente')),
          ),
          padding: const EdgeInsets.only(top: 24),
        ),
        tamanho: const Size(640, 420),
      ),
    ],
  ),
  'ss-nav-bar': (
    [
      'v1.9.3: com texto grande o rótulo da aba encolhe só ele até caber (piso no tamanho normal, 11), em vez de "Lançam…"; o ícone e o alvo de toque não mudam.',
    ],
    [
      Estado(
        'texto-1-6',
        '5 abas em 360 com texto 1,6×',
        (ctx) => _mq(
          ctx,
          Align(
            alignment: Alignment.bottomCenter,
            child: SsNavBar(items: _abas, currentIndex: 0, onTap: (_) {}),
          ),
          escala: 1.6,
        ),
        tamanho: const Size(360, 110),
      ),
    ],
  ),
  'ss-stat-card': (
    ['v1.9.3: o rótulo quebra em até 3 linhas (antes cortava com "…" no texto 1,6×).'],
    [
      Estado(
        'texto-1-6',
        'rótulo longo em 2 colunas de 360 com texto 1,6×',
        (ctx) => _mq(
          ctx,
          _pad(
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Expanded(
                  child: SsStatCard(label: 'Receita recorrente', value: 'R\$ 1.234,00', icon: Icons.trending_up),
                ),
                Expanded(
                  child: SsStatCard(label: 'Clientes', value: '128'),
                ),
              ],
            ),
          ),
          escala: 1.6,
        ),
        tamanho: const Size(360, 220),
      ),
    ],
  ),
  'ss-notification-bell': (
    [
      'v1.9.3: o leitor de tela lê um nó só, "Notificações, 3 não lidas" (o plural: "1 não lida"), em vez de só o número do selo. Nome padrão: SsStrings.notifications.',
      'v1.9.3: o selo largo ("12", "99+") cresce para a esquerda e não passa de 1,3× de texto: não é cortado na borda com texto 1,6×.',
    ],
    [
      Estado(
        'texto-1-6',
        '"99+" encostado na borda direita, texto 1,6×',
        (ctx) => _mq(
          ctx,
          Align(
            alignment: Alignment.topRight,
            child: SsNotificationBell(count: 120, onPressed: _nada),
          ),
          escala: 1.6,
        ),
        tamanho: const Size(200, 64),
      ),
    ],
  ),
  'ss-plan': (
    ['v1.9.3: SsQuota com milhar do SsFormats ("36 de 1.500 este mês").'],
    [
      Estado(
        'cota-milhar',
        'SsQuota: 36 de 1.500',
        (_) => _pad(const SsQuota(used: 36, limit: 1500)),
        tamanho: const Size(360, 60),
      ),
    ],
  ),
};
