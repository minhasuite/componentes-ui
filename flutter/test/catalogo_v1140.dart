// v1.14.0 "interface e animação" ([comV1140]): gráfico que se arrasta, este período × o anterior, a linha que se
// expande, a folha com 3 alturas, o ícone que anima na barra, o fundo de manchas, o odômetro no KPI, o cabeçalho
// que ganha cor, o check que se desenha, o cartão que inclina, a troca de aba e o esqueleto no formato real.
// Dados de exemplo, sem pessoas reais (os mesmos da vitrine web).
import 'package:componentes_ui/componentes_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'catalogo.dart';

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

const _dias = ['01/11', '05/11', '10/11', '15/11', '20/11', '25/11', '30/11'];
const _nov = <double>[320.0, 540, 410, 880, 760, 1020, 940];
const _out = <double>[280.0, 460, 520, 610, 700, 760, 820];

String _reais(double v) => money((v * 100).round());

Widget _linhaPedido() => SsListItem(
  title: 'Mercado Bom Preço',
  subtitle: 'Lançamento de 26/11 · Mercado',
  value: r'R$ 214,90',
  icon: Icons.shopping_cart_outlined,
);

List<Componente> comV1140(List<Componente> base) => [...base, ..._v1140];

final _v1140 = <Componente>[
  Componente(
    'ss-chart-scrub',
    'scrub: (gráficos)',
    'Gráfico que se arrasta com o dedo (v1.14, par do scrub: do web): SsLineChart, SsAreaChart, SsBarChart e SsTimeChart com o marcador que segue o dedo ou o mouse, o balão com valor e data e a vibração a cada ponto.',
    comportamentos: const [
      'scrub: true (padrão): arrastar na horizontal, tocar, segurar ou passar o mouse mostra a linha vertical, os pontos e o balão; soltou ou o mouse saiu, some (no toque, some ao tocar fora).',
      'Cada ponto novo vibra com SsHaptics.selection (o mesmo clique da chave e do segmentado).',
      'onScrub(i) avisa o índice (nulo quando some) para a tela inteira acompanhar: o total do mês, a linha da lista. No SsTimeChart, o onScrub(DateTime?) de sempre.',
      'O gesto é o SsScrubDetector, público para o gráfico do produto. scrub: false deixa o gráfico parado.',
      'No SsAreaChart, enquanto o dedo está em cima, a pílula mostra o rótulo junto do valor.',
    ],
    estados: [
      Estado(
        'linha',
        'linha com a meta',
        (_) => _pad(
          SsLineChart(
            labels: _dias,
            series: const [SsSeries(_nov, name: 'Gastos')],
            target: 900,
            format: _reais,
            onScrub: (_) {},
          ),
        ),
        tamanho: const Size(360, 220),
      ),
      Estado(
        'barras',
        'barras',
        (_) => _pad(
          SsBarChart(
            labels: _dias,
            series: const [SsSeries(_nov, name: 'Vendas')],
            format: _reais,
            onScrub: (_) {},
          ),
        ),
        tamanho: const Size(360, 240),
      ),
    ],
  ),
  Componente(
    'ss-period-compare',
    'SsPeriodCompare',
    'Este período × o anterior (v1.14, par do Ss::PeriodCompareComponent): o total com a diferença em destaque e as duas séries no mesmo gráfico, o anterior como linha fantasma.',
    comportamentos: const [
      'O total deste período rola ao mudar (SsOdometer) e o SsDelta diz a diferença, verde quando o sentido é bom (higherIsBetter: false para despesa).',
      'A série do anterior é tracejada e apagada, por baixo; a legenda diz qual é qual.',
      'periods: o SsSegmented em cima troca o período (onPeriodChanged); os dados novos deslizam do valor antigo ao novo.',
      'Arrastando no gráfico, o número de cima vira o do ponto e a diferença, a daquele dia contra o mesmo dia do anterior; onScrub avisa o índice.',
      'O leitor de tela ouve "R\$ 4.870,00 neste período, R\$ 4.150,00 no anterior".',
    ],
    estados: [
      Estado(
        'mes',
        'novembro × outubro',
        (_) => _pad(
          SsPeriodCompare(
            title: 'Gastos do mês',
            labels: _dias,
            current: _nov,
            previous: _out,
            currentLabel: 'Novembro',
            previousLabel: 'Outubro',
            format: _reais,
            higherIsBetter: false,
            periods: const ['Semana', 'Mês', 'Ano'],
            period: 1,
            onPeriodChanged: (_) {},
          ),
        ),
        tamanho: const Size(360, 420),
      ),
    ],
  ),
  Componente(
    'ss-expandable-row',
    'SsExpandableRow',
    'Linha que se expande no lugar para edição rápida (v1.14, par do Ss::ExpandableRowComponent): os campos abrem embaixo da linha, com a altura animada e o foco no 1º campo.',
    comportamentos: const [
      'Tocar na linha abre os campos do editor embaixo dela (altura animada, SsMotion.medium) e põe o foco no primeiro campo; a seta gira.',
      'Salvar chama onSave (o botão carrega enquanto espera); false mantém aberta para o erro aparecer no campo. Deu certo: vibra e fecha.',
      'Cancelar ou Esc fecha, chama onCancel e devolve o foco à linha.',
      'expanded + onExpandedChanged deixam o app manter só uma aberta por vez.',
    ],
    estados: [
      Estado(
        'fechada',
        'fechada',
        (_) => _pad(
          SsExpandableRow(
            title: 'Mercado Bom Preço',
            subtitle: '26/11 · Mercado',
            value: r'R$ 214,90',
            icon: Icons.shopping_cart_outlined,
            editor: (_) => const SizedBox(),
          ),
        ),
        tamanho: const Size(360, 110),
      ),
      Estado(
        'aberta',
        'aberta para editar',
        (_) => _pad(
          SsExpandableRow(
            title: 'Mercado Bom Preço',
            subtitle: '26/11 · Mercado',
            value: r'R$ 214,90',
            icon: Icons.shopping_cart_outlined,
            expanded: true,
            onSave: () => true,
            editor: (_) => Column(
              spacing: 12,
              children: [
                SsMoneyField(label: 'Valor', cents: 21490, onChanged: (_) {}),
                SsTextField(label: 'Observação', onChanged: (_) {}),
              ],
            ),
          ),
        ),
        tamanho: const Size(360, 360),
      ),
    ],
  ),
  Componente(
    'ss-detent-sheet',
    'showSsSheet(detents:)',
    'Folha com 3 alturas (v1.14, par do Ss::DrawerComponent(detents:) no celular): arrastar a alça leva entre elas e, ao soltar, a folha assenta com uma mola.',
    comportamentos: const [
      'showSsSheet(context, detents: [.33, .5, 1], initialDetent: 1, child: …): frações da altura da tela.',
      'Arrastar a alça (ou o conteúdo no topo, para baixo) leva a folha junto; ao soltar, vai para a altura mais perto de onde o gesto a levaria (a velocidade conta), com mola de verdade. Abaixo da menor, fecha.',
      'Cada altura nova vibra (SsHaptics.selection). Tocar na alça sobe uma altura; na maior, volta à menor.',
      'Leitor de tela: "Alça da folha, 50% da tela", com aumentar e diminuir; no teclado, ↑ e ↓ com o foco na alça.',
      'Com "reduzir movimento", troca de altura sem mola.',
    ],
    estados: [
      Estado(
        'meia',
        'na altura do meio',
        (_) => Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: 420,
            child: SsCard(
              padding: EdgeInsets.zero,
              child: SsDetentSheet(
                detents: const [.33, .5, 1],
                initial: 2,
                title: 'Filtrar pedidos',
                subtitle: 'Arraste a alça para mudar a altura',
                child: Column(
                  children: [
                    for (final s in ['Abertos', 'Faturados', 'Entregues']) SsListItem(title: s),
                  ],
                ),
              ),
            ),
          ),
        ),
        tamanho: const Size(360, 440),
      ),
    ],
  ),
  Componente(
    'ss-nav-animated-icon',
    'SsNavItem(animatedIcon:)',
    'Ícone animado na barra (v1.14, par da barra inferior da app_shell no celular): ao virar a aba atual, o ícone chega no círculo girando de leve com mola e passa do contorno para o cheio.',
    comportamentos: const [
      'animatedIcon: true (padrão): no fim do pulo do círculo, o ícone cresce, gira ~20° e assenta com a mola; o contorno (icon) cruza para o cheio (activeIcon).',
      'Sem activeIcon, só gira e cresce. "Reduzir movimento" desliga (a barra troca seco).',
    ],
    estados: [
      Estado(
        'barra',
        'a barra com 4 abas',
        (_) => Align(
          alignment: Alignment.bottomCenter,
          child: SsNavBar(
            currentIndex: 1,
            onTap: (_) {},
            items: const [
              SsNavItem(Icons.home_outlined, 'Início', activeIcon: Icons.home_rounded),
              SsNavItem(Icons.receipt_long_outlined, 'Pedidos', activeIcon: Icons.receipt_long_rounded),
              SsNavItem(Icons.inventory_2_outlined, 'Estoque', activeIcon: Icons.inventory_2_rounded),
              SsNavItem(Icons.forum_outlined, 'Assistente', activeIcon: Icons.forum_rounded),
            ],
          ),
        ),
        tamanho: const Size(360, 130),
      ),
    ],
  ),
  Componente(
    'ss-mesh-background',
    'SsMeshBackground',
    'Fundo de manchas da marca (v1.14, par do Ss::MeshBackgroundComponent): manchas suaves se movendo devagar, para cabeçalhos de destaque (SsHeroCard(mesh: true)).',
    comportamentos: const [
      'Quatro gradientes radiais na cor da marca andam devagar (uma volta em SsMotion.ambient, 24 s) sobre a cor funda; sem desfoque nem shader próprio: o custo é pintar 4 círculos por quadro, isolado por RepaintBoundary.',
      'Um véu da cor funda sobe sozinho até o texto claro passar de 4,5:1 sobre a mancha mais clara (SsMeshBackground.veilFor), em toda paleta.',
      'É a animação contínua da tela: um herói por tela, nada de aurora ou esqueleto junto.',
      'Parado com "reduzir movimento", com animate: false e com o app em segundo plano.',
    ],
    estados: [
      Estado(
        'heroi',
        'no SsHeroCard',
        (_) => _pad(
          const SsHeroCard(
            mesh: true,
            label: 'Saldo de novembro',
            value: r'R$ 4.870,00',
            caption: r'R$ 720,00 a mais que outubro',
          ),
        ),
        tamanho: const Size(360, 170),
      ),
    ],
  ),
  Componente(
    'ss-kpi-odometer',
    'SsKpiCard(animate:)',
    'Odômetro como padrão (v1.14, par do Ss::KpiCardComponent(animate:) e do ss_amount(animate:)): o valor do SsKpiCard e do SsStatCard rola dígito a dígito ao mudar.',
    comportamentos: const [
      'SsKpiCard e SsStatCard: animate: true por padrão; o número parte dos zeros ao entrar na tela e, ao mudar, cada dígito gira até o novo (SsOdometer), subindo quando aumentou.',
      'SsAmount(animate: true) faz o mesmo em qualquer valor (padrão desligado).',
      'O leitor de tela ouve o valor inteiro; "reduzir movimento" troca seco.',
      'Ao subir a tag: teste que procura o valor do KPI por find.text passa a find.bySemanticsLabel (os dígitos são colunas), ou animate: false.',
    ],
    estados: [
      Estado(
        'kpi',
        'KPI e stat',
        (_) => _pad(
          const Row(
            spacing: 12,
            children: [
              Expanded(
                child: SsKpiCard(label: 'Vendas hoje', value: r'R$ 8.240,50'),
              ),
              Expanded(
                child: SsStatCard(label: 'Pedidos', value: '42'),
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 170),
        aguarde: 1600,
      ),
    ],
  ),
  Componente(
    'ss-collapse-tint',
    'SsScreenHeader(collapseTint:)',
    'Cabeçalho que encolhe e muda de cor com a rolagem (v1.14, par do Ss::PageComponent(collapse_tint:)): aberto é transparente; ao rolar, o título grande vira o pequeno e o fundo passa à superfície com sombra.',
    comportamentos: const [
      'collapseTint: true: a cor do fundo vai de transparente à superfície (SsColors.surface) junto com o dedo, e a sombra da barra chega com ela (no escuro, o fio basta).',
      'O título grande sobe e esmaece; o pequeno entra crescendo de leve na barra (como antes).',
      'Sem collapseTint, o fundo é sempre o da tela com o fio embaixo.',
    ],
    estados: [
      Estado(
        'aberto',
        'aberto (transparente)',
        (_) => SsScreenHeader(
          title: 'Pedidos',
          subtitle: '12 abertos',
          collapseTint: true,
          slivers: [
            SliverList.list(children: [for (var i = 0; i < 6; i++) _linhaPedido()]),
          ],
        ),
        tamanho: const Size(360, 360),
      ),
    ],
  ),
  Componente(
    'ss-success-check',
    'SsSuccessCheck',
    'Check que se desenha (v1.14, par do Ss::SuccessCheckComponent): o círculo corre em volta e o traço do ✓ vem depois, com um pulinho; vibra e, com sound: true, chama o som do app.',
    comportamentos: const [
      'Desenha em SsMotion.long + SsMotion.medium: círculo, traço e o pulinho de mola no fim; com "reduzir movimento", aparece pronto.',
      'haptic: true (padrão) vibra com SsHaptics.success; sound: true chama SsSounds.player (o app fornece o player; o pacote só o gancho; no web, o evento ss:sound).',
      'filled: disco cheio com o ✓ claro. É o fim do SsMorphButton, do SsSwipeToConfirm e do SsPixCard pago.',
      'O leitor de tela ouve "Concluído" (região viva); label: troca.',
    ],
    estados: [
      Estado(
        'contorno',
        'contorno e cheio',
        (_) => _pad(
          const Row(
            spacing: 24,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [SsSuccessCheck(haptic: false), SsSuccessCheck(filled: true, haptic: false)],
          ),
        ),
        tamanho: const Size(360, 110),
        aguarde: 900,
      ),
    ],
  ),
  Componente(
    'ss-tilt-card',
    'SsTiltCard',
    'Cartão que inclina (v1.14, par do Ss::TiltCardComponent): inclina de leve ao toque ou ao passar o mouse, com um reflexo de vidro que corre junto, para cartões de destaque.',
    comportamentos: const [
      'Até maxTilt (6°) para o lado do dedo ou do mouse; soltou, volta com a mola (SsMotion.bounce).',
      'O reflexo (o brilho do SsGlass) segue o dedo; glass: true põe o conteúdo sobre o vidro.',
      'Para cartão de crédito, plano e conquista; nunca em tela de dados densos (enabled: false). Desligado com "reduzir movimento".',
    ],
    estados: [
      Estado(
        'cartao',
        'cartão de destaque',
        (_) => _pad(
          SsTiltCard(
            child: SsHeroCard.custom(
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Plano Pro', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  SizedBox(height: 4),
                  Text('IA sem limite, 5 lojas e relatórios'),
                ],
              ),
            ),
          ),
        ),
        tamanho: const Size(360, 140),
      ),
    ],
  ),
  Componente(
    'ss-shared-axis',
    'SsSharedAxisTransition / SsTabHero',
    'Entre abas (v1.14, par das View Transitions da app_shell): a troca de aba no SsNavScaffold com eixo compartilhado (fade through) em vez de corte seco, e o SsTabHero que voa quando a mesma peça aparece nas duas abas.',
    comportamentos: const [
      'SsNavScaffold(tabTransition: SsSharedAxis.fadeThrough) (padrão): a aba nova aparece esmaecendo e crescendo de 92%; horizontal desliza do lado da aba escolhida; null volta ao corte seco.',
      'SsTabHero(tag:, child:): a peça com a mesma tag na aba que sai e na que entra voa do lugar e do tamanho antigos aos novos (SsMotion.medium). Sem par, nada voa.',
      'Fora do SsNavScaffold: SsSharedAxisTransition(transitionKey: aba, index: aba, child: IndexedStack(…)).',
      '"Reduzir movimento": troca seca, sem voo.',
    ],
    estados: [
      Estado(
        'aba',
        'a aba entrando',
        (_) => _pad(
          SsSharedAxisTransition(
            transitionKey: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                SsTabHero(
                  tag: 'saldo',
                  child: SsKpiCard(label: 'Saldo', value: r'R$ 3.482,10', animate: false),
                ),
                _linhaPedido(),
              ],
            ),
          ),
        ),
        tamanho: const Size(360, 220),
      ),
    ],
  ),
  Componente(
    'ss-skeleton-of',
    'SsSkeleton.of',
    'Esqueleto no formato real (v1.14, par do ss_skeleton_for do web): o esqueleto sai da própria árvore de widgets, com blocos onde há texto e imagem e o pulso da v1.9.',
    comportamentos: const [
      'SsSkeleton.of(child): mede o child (com dados de exemplo) sem pintar nada dele e desenha um bloco por linha de texto, na largura do texto; um bloco onde há imagem e um círculo no avatar redondo; o contorno dos cards.',
      'O pulso é o do SsSkeleton (SsMotion.pulse); com "reduzir movimento", fica parado.',
      'Fora do toque e do leitor de tela, que ouve "Carregando…". Serve de loading: do SsAsyncBody.',
    ],
    estados: [
      Estado(
        'lista',
        'a linha e o card',
        (_) => _pad(
          SsSkeleton.of(
            Column(
              spacing: 12,
              children: [
                _linhaPedido(),
                const SsKpiCard(label: 'Vendas hoje', value: r'R$ 8.240,50', caption: '42 pedidos', animate: false),
              ],
            ),
          ),
        ),
        tamanho: const Size(360, 230),
      ),
    ],
  ),
];
