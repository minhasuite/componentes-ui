// Estados e comportamentos da v0.19.1 (o que o minhas-compras-app e o
// minhas-viagens-app ainda tinham de Material cru): peça nova em
// [catalogoV191] e os extras das que já existiam (por slug) em [comV191].
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';

import 'catalogo.dart';

void _nada() {}

const _abas = ['Cronograma', 'Passeios', 'Reservas', 'Gastos', 'Resumo'];
const _icones = <IconData?>[
  Icons.view_timeline_outlined,
  Icons.local_activity_outlined,
  Icons.confirmation_number_outlined,
  Icons.payments_outlined,
  Icons.pie_chart_outline,
];

class _AbasComConteudo extends StatefulWidget {
  const _AbasComConteudo();

  @override
  State<_AbasComConteudo> createState() => _AbasComConteudoState();
}

class _AbasComConteudoState extends State<_AbasComConteudo> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 3, vsync: this, initialIndex: 1)..addListener(() => setState(() {}));

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SsTabsUnderline(tabs: const ['Painel', 'Histórico', 'Lojas (3)'], index: _tabs.index, onChanged: _tabs.animateTo),
      Expanded(
        child: SsTabsView(
          controller: _tabs,
          children: const [
            Center(child: SsNote('Painel do desejo')),
            Center(child: SsNote('O gráfico aparece depois de duas leituras de preço.')),
            Center(child: SsNote('Lojas monitoradas')),
          ],
        ),
      ),
    ],
  );
}

final catalogoV191 = <Componente>[
  Componente(
    'ss-tabs-view',
    'SsTabsView',
    'O conteúdo das abas do SsTabsUnderline/SsCountTabs: uma página por aba, no mesmo TabController (no lugar do TabBarView).',
    comportamentos: [
      'Segue o controller (ou o DefaultTabController de cima): tocar na aba desliza para a página, arrastar de lado troca a aba.',
      'swipe: false desliga o arrastar (aba com mapa ou carrossel); o toque na aba continua trocando.',
      'Cada filho com PageStorageKey guarda a própria rolagem.',
    ],
    estados: [Estado('padrao', 'abas + conteúdo', (_) => const _AbasComConteudo(), tamanho: const Size(360, 200))],
  ),
  Componente(
    'ss-tooltip',
    'SsTooltip',
    'Dica curta ao segurar (toque) ou passar o mouse/focar (par do Ss::TooltipComponent); não é o SsTip dispensável.',
    comportamentos: [
      'Aparece em cima do filho (below: embaixo), segurando ou com o mouse por 250 ms; some sozinha.',
      'Claro: fundo de tinta e texto branco; escuro: fundo do campo com borda. Texto 12/600, raio 8, sombra do card.',
      'O leitor de tela lê a mensagem junto do filho. Botão de ícone já tem a dele (SsIconButton(tooltip:)).',
    ],
    estados: [
      Estado(
        'padrao',
        'num chip de cidade',
        (_) => const Padding(
          padding: EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SsTooltip(
              message: 'Trocar a cidade',
              child: SsFilterChip('Fortaleza', selected: false, icon: Icons.place_outlined, onTap: _nada),
            ),
          ),
        ),
      ),
    ],
  ),
  Componente(
    'ss-fullscreen',
    'showSsFullscreen / SsFullscreenPage',
    'Algo grande e sozinho em tela cheia (a frase para quem está do outro lado do balcão, o código de embarque); no lugar do Dialog.fullscreen.',
    comportamentos: [
      'Rota por cima de tudo (useRootNavigator), sobe de baixo com fade; reduzir movimento abre sem animar.',
      'Barra com × (Fechar), o título e as actions; o voltar do sistema fecha.',
      'dismissOnTap: um toque em qualquer lugar fecha, e o leitor diz "Toque para fechar".',
    ],
    estados: [
      Estado(
        'padrao',
        'frase do guia',
        (_) => const SsFullscreenPage(
          title: 'Frases',
          dismissOnTap: true,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Où sont les toilettes ?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: AppType.statNum, fontWeight: FontWeight.w800, height: AppType.tight),
              ),
            ),
          ),
        ),
        tamanho: const Size(360, 320),
      ),
    ],
  ),
];

/// Soma os extras da v0.19.1 às entradas de [base] com o mesmo slug.
List<Componente> comV191(List<Componente> base) => [
  for (final c in base)
    if (_v191[c.slug] case (final comp, final est))
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

final Map<String, (List<String>, List<Estado>)> _v191 = {
  'ss-tabs-underline': (
    [
      'v0.19.1: stacked põe o ícone em cima do nome e nunca rola (5 abas cabem em 360 px; o nome encolhe). Altura em SsTabsUnderline.stackedHeight(context) (66 no padrão), para o bottomHeight do SsSliverHeader.',
    ],
    [
      Estado(
        'empilhada',
        'ícone em cima, 5 abas em 360 px',
        (_) => SsTabsUnderline(tabs: _abas, icons: _icones, stacked: true, index: 2, onChanged: (_) {}),
        tamanho: const Size(360, 80),
      ),
    ],
  ),
  'ss-divider': (
    [
      'v0.19.1: SsDivider.vertical() (ou vertical: true) é o fio em pé entre duas colunas (menu lateral e conteúdo), no lugar do VerticalDivider.',
    ],
    [
      Estado(
        'vertical',
        'em pé entre duas colunas',
        (_) => const SizedBox(
          height: 96,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: Center(child: SsNote('Lista'))),
              SsDivider.vertical(),
              Expanded(child: Center(child: SsNote('Vence logo'))),
            ],
          ),
        ),
      ),
    ],
  ),
  'ss-overflow-menu': (
    [
      'v0.19.1: SsMenuAction(leading:) põe um widget (logo da loja, avatar) no lugar do ícone; SsOverflowMenu(child:) troca o ⋮ por outra âncora (o menu abre mesmo com uma ação só).',
    ],
    [
      Estado(
        'ancora',
        'âncora em texto ("No app")',
        (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SsOverflowMenu(
              tooltip: 'Buscar no app da loja',
              items: [
                SsMenuAction(
                  Icons.storefront,
                  'Buscar no app da Shopee',
                  () {},
                  leading: const SsAvatar('Shopee', size: 18),
                ),
              ],
              child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Text('No app')),
            ),
          ),
        ),
      ),
    ],
  ),
};
