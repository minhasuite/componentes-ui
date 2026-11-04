// Entradas do catálogo do movimento (lote b): entrada quando aparece na tela,
// números que rolam, camadas por cima com mola e listas/cards. Todas são demos
// vivas: "Repetir" remonta a peça (a entrada toca de novo), "+/−" mudam o
// número e os botões abrem folha, aviso, diálogo e menu.
import 'package:flutter/material.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo.dart';

Widget _pad(Widget w) => Padding(
  padding: const EdgeInsets.all(16),
  child: Center(child: w),
);

/// Remonta [build] ao tocar em "Repetir" (chave nova: a entrada toca de novo).
class _Repetir extends StatefulWidget {
  const _Repetir(this.build, {this.rolar = false});
  final WidgetBuilder build;

  /// Põe a peça numa lista rolável (a entrada espera aparecer na tela).
  final bool rolar;

  @override
  State<_Repetir> createState() => _RepetirState();
}

class _RepetirState extends State<_Repetir> {
  int _n = 0;

  @override
  Widget build(BuildContext context) {
    final corpo = KeyedSubtree(
      key: ValueKey(_n),
      child: Builder(builder: widget.build),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(() => _n++),
            icon: const Icon(Icons.replay_rounded, size: 18),
            label: const Text('Repetir'),
          ),
        ),
        Expanded(
          child: widget.rolar
              ? SingleChildScrollView(
                  key: ValueKey('rolagem$_n'),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: corpo,
                )
              : Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: corpo),
        ),
      ],
    );
  }
}

/// Um valor em centavos com "−" e "+" (o número rola para o lado da mudança).
class _MaisMenos extends StatefulWidget {
  const _MaisMenos(this.inicio, this.passo, this.build);
  final int inicio;
  final int passo;
  final Widget Function(int valor) build;

  @override
  State<_MaisMenos> createState() => _MaisMenosState();
}

class _MaisMenosState extends State<_MaisMenos> {
  late int v = widget.inicio;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      widget.build(v),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 12,
        children: [
          IconButton.filledTonal(
            tooltip: 'Diminuir',
            onPressed: () => setState(() => v = (v - widget.passo).clamp(0, 1 << 40)),
            icon: const Icon(Icons.remove_rounded),
          ),
          IconButton.filledTonal(
            tooltip: 'Aumentar',
            onPressed: () => setState(() => v += widget.passo),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    ],
  );
}

/// Guarda um valor qualquer para as demos com estado (feito, escolhidos).
class _Guarda<T> extends StatefulWidget {
  const _Guarda(this.inicio, this.build);
  final T inicio;
  final Widget Function(T valor, ValueChanged<T> muda) build;

  @override
  State<_Guarda<T>> createState() => _GuardaState<T>();
}

class _GuardaState<T> extends State<_Guarda<T>> {
  late T v = widget.inicio;

  @override
  Widget build(BuildContext context) => widget.build(v, (n) => setState(() => v = n));
}

Widget _cartao(BuildContext context, String titulo, String sub) {
  final c = SsColors.of(context);
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: c.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      boxShadow: c.isDark ? null : AppShadows.card,
      border: c.isDark ? Border.all(color: c.line) : null,
    ),
    child: Row(
      children: [
        SsIconTile(Icons.receipt_long_outlined, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(color: c.ink, fontWeight: FontWeight.w800),
              ),
              Text(
                sub,
                style: TextStyle(color: c.muted, fontSize: AppType.meta),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

const _dias = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
const _semana = <double>[320.0, 410, 280, 520, 460, 610, 380];
const _meses = ['Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov'];
const _gastos = <double>[4200.0, 5150, 4680, 6100, 6640, 5800];

final catalogoMovB = <Componente>[
  // ------------------------------------------------------- entrada na tela
  Componente(
    'mov-in-view',
    'SsInView · SsInViewReveal',
    'Entrada que espera a peça aparecer na tela: dispara uma vez quando ao menos 25% dela fica visível no Scrollable em volta (sem Scrollable, já no primeiro quadro).',
    comportamentos: [
      'SsInView(builder: (context, t, child)): t vai de 0 a 1 com a curva pedida (a mola passa de 1) quando entra na tela, depois de delay.',
      'SsInView.visible(builder: (context, visible)): só o sinal; SsTweenInView anima um valor de begin até end com ele.',
      'SsInViewReveal: aparece e sobe 16 px com a mola da suíte (passa um pouco e assenta), com atraso de index × 40 ms (até 8).',
      'Ouve a rolagem (removido no dispose) e confere a geometria depois do quadro; peça maior que a tela conta 25% da tela.',
      'Com menos movimento chega direto no fim. Para repetir, troque a key.',
    ],
    estados: [
      Estado(
        'lista',
        'cards que entram ao rolar',
        (_) => _Repetir(
          (context) => Column(
            children: [
              for (var i = 0; i < 9; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SsInViewReveal(
                    index: i % 4,
                    child: _cartao(context, 'Pedido #${1040 + i}', 'Entra com mola quando aparece'),
                  ),
                ),
            ],
          ),
          rolar: true,
        ),
        tamanho: const Size(360, 460),
        aguarde: 700,
      ),
    ],
  ),

  // ------------------------------------------------------- gráficos na tela
  Componente(
    'mov-graficos',
    'Gráficos que crescem na tela',
    'SsPillBars, SsSparkline, SsRings, SsGauge, SsProgress, SsLineChart e SsCountdownRing animam quando entram na tela, não ao montar (o que acontecia fora da vista).',
    comportamentos: [
      'SsPillBars: cada barra sobe com mola, 40 ms depois da anterior.',
      'SsSparkline e SsLineChart se desenham da esquerda para a direita; SsRings enchem em cascata.',
      'SsGauge: o ponto vai com mola até o valor; SsProgress e SsProportionBar enchem; mudar o valor anima do atual até o novo.',
      'Rolando a lista, os de baixo só tocam quando chegam; "Repetir" remonta tudo.',
    ],
    estados: [
      Estado(
        'rolagem',
        'gráficos numa tela rolável',
        (_) => _Repetir(
          (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 18,
            children: [
              SsPillBars(values: _semana, labels: _dias, format: (v) => '${v.round()}'),
              const SsSparkline([3, 5, 4, 6, 5, 8, 7, 9], height: 48),
              const Center(child: SsRings([SsRing(.82), SsRing(.56), SsRing(.34)], size: 120)),
              const Center(child: SsGauge(value: .62, label: 'Preço do litro')),
              const SsProgress(.68, marker: .5, markerLabel: 'hoje'),
              SsLineChart(
                series: const [
                  SsSeries([12, 14, 13, 17, 16, 19, 21], name: 'Preço'),
                ],
                labels: const ['01/10', '05/10', '09/10', '13/10', '17/10', '21/10', '25/10'],
              ),
              const Center(child: SsCountdownRing(total: 30, left: 12)),
            ],
          ),
          rolar: true,
        ),
        tamanho: const Size(360, 640),
        aguarde: 900,
      ),
    ],
  ),

  Componente(
    'mov-graficos-v09',
    'Gráficos v0.9 que crescem na tela',
    'SsAreaChart, SsExplodedDonut, SsBigRing e SsFloatingBars tocam a entrada quando aparecem.',
    comportamentos: [
      'SsFloatingBars: as barras sobem com mola em cascata (40 ms).',
      'SsAreaChart se desenha; a rosca e o anel grande enchem; o número do anel conta junto.',
      '"Repetir" remonta (a entrada toca de novo).',
    ],
    estados: [
      Estado(
        'rolagem',
        'dentro de uma tela rolável',
        (_) => _Repetir(
          (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 18,
            children: [
              SsFloatingBars(values: _gastos, labels: _meses, title: 'Gastos', value: 'R\$ 5.800', height: 220),
              SsAreaChart(values: _gastos, labels: _meses, height: 180),
              const Center(child: SsBigRing(.72, caption: 'da meta', size: 170)),
              const SsExplodedDonut(
                slices: [SsDonutSlice('Mercado', 1200), SsDonutSlice('Casa', 800), SsDonutSlice('Lazer', 400)],
                size: 180,
              ),
            ],
          ),
          rolar: true,
        ),
        tamanho: const Size(360, 640),
        aguarde: 1000,
      ),
    ],
  ),

  // ------------------------------------------------------- números que rolam
  Componente(
    'mov-odometro',
    'SsOdometer (caça-níquel)',
    'Cada dígito que muda é uma coluna 0–9 que gira até o novo e assenta com mola; sobe quando o valor aumentou e desce quando caiu.',
    comportamentos: [
      'As casas giram em cascata da direita para a esquerda (35 ms entre elas), como o "vai um".',
      'Mais casas a girar, um pouco mais de tempo; trocar no meio parte de onde a coluna está.',
      'Vírgula, ponto e "R\$" ficam parados; casa nova à esquerda entra com fade.',
      'rollIn: true faz os dígitos partirem do 0 quando o número entra na tela.',
    ],
    estados: [
      Estado(
        'mais-menos',
        '"+" e "−" mudam o valor',
        (_) => _pad(_MaisMenos(123456, 8790, (v) => Center(child: SsOdometer(money(v), size: 40)))),
        tamanho: const Size(360, 170),
      ),
      Estado(
        'roll-in',
        'rollIn: gira do 0 ao aparecer',
        (_) => _Repetir((_) => Center(child: SsOdometer(money(987650), size: 40, rollIn: true))),
        tamanho: const Size(360, 150),
        aguarde: 900,
      ),
    ],
  ),

  Componente(
    'mov-valor-rola',
    'SsAmount que conta e rola',
    'SsAmount(countUp: true) conta de 0 até o valor (no formato do texto) quando entra na tela; SsAmount(roll: true) faz o valor novo rolar na vertical. SsStatCard e SsValueTile usam os dois.',
    comportamentos: [
      'Conta uma vez, quando aparece (700 ms); depois disso, mudar o valor rola em vez de contar.',
      'Rola para cima quando aumentou e para baixo quando caiu, com a mola da suíte; o antigo sai para o outro lado.',
      'SsRollSwitcher (qualquer filho) e SsRollingText (texto) fazem a mesma troca para status e contadores.',
    ],
    estados: [
      Estado(
        'stat-card',
        'SsStatCard com "+" e "−"',
        (_) => _pad(
          _MaisMenos(
            1284390,
            45600,
            (v) => SsStatCard(
              label: 'Vendas do mês',
              value: money(v),
              icon: Icons.trending_up_rounded,
              spark: const [3, 4, 3.5, 5, 6, 5.5, 7],
            ),
          ),
        ),
        tamanho: const Size(360, 260),
        aguarde: 900,
      ),
      Estado(
        'texto',
        'SsRollingText e SsValueTile',
        (_) => _pad(
          _Guarda<int>(
            0,
            (i, muda) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SsValueTile(title: 'Café torrado', subtitle: 'Melitta · 500 g', value: money(1890 + 250 * i)),
                const SizedBox(height: 8),
                SsRollingText(['Separando', 'Em rota', 'Entregue'][i % 3], up: true),
                TextButton(onPressed: () => muda(i + 1), child: const Text('Próximo')),
              ],
            ),
          ),
        ),
        tamanho: const Size(360, 200),
        aguarde: 900,
      ),
    ],
  ),

  Componente(
    'mov-dinheiro',
    'SsPriceBoard · SsLevelCard (movimento)',
    'Cotações que rolam ao atualizar; pontos que contam e barra que enche quando o card aparece.',
    comportamentos: [
      'SsPriceBoard: compra, venda e variação que mudam rolam na vertical (para cima quando subiram).',
      'SsLevelCard: o saldo conta, a barra até o próximo nível enche e as linhas entram em cascata, quando o card entra na tela.',
    ],
    estados: [
      Estado(
        'cotacoes',
        '"Atualizar" muda as cotações',
        (_) => _pad(
          _Guarda<int>(
            0,
            (i, muda) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SsPriceBoard(
                  rows: [
                    SsPriceRow(
                      name: 'Dólar',
                      code: 'USD',
                      buy: '5,${(41 + i * 3) % 100}',
                      sell: '5,${(47 + i * 3) % 100}',
                      change: i.isEven ? .42 + i / 10 : -.18,
                    ),
                    SsPriceRow(
                      name: 'Euro',
                      code: 'EUR',
                      buy: '6,${(12 + i * 7) % 100}',
                      sell: '6,${(20 + i * 7) % 100}',
                      change: i.isEven ? -.31 : .27,
                    ),
                  ],
                  highlighted: 0,
                ),
                TextButton(onPressed: () => muda(i + 1), child: const Text('Atualizar')),
              ],
            ),
          ),
        ),
        tamanho: const Size(360, 240),
      ),
      Estado(
        'pontos',
        'SsLevelCard ao aparecer',
        (_) => _Repetir(
          (_) => const SsLevelCard(
            points: 12480,
            level: 'Ouro',
            nextLevel: 'Platina',
            progress: .64,
            pointsToNext: 4520,
            entries: [SsLevelEntry('Mercado Bom Preço', 18990, 190), SsLevelEntry('Posto Sol', 25000, 250)],
          ),
        ),
        tamanho: const Size(360, 420),
        aguarde: 900,
      ),
    ],
  ),

  // ------------------------------------------------------- camadas por cima
  Componente(
    'mov-camadas',
    'Folha, aviso, diálogo e menu com mola',
    'As camadas por cima entram com a mola da suíte e saem retas e rápidas. SsOverlayMotion.sheet/dialog servem para quem monta a rota direto.',
    comportamentos: [
      'showSsSheet e showSsPicker: a folha sobe, passa ~3% e assenta (460 ms); desce em 220 ms.',
      'showSsConfirm e showSsPrompt: o fundo esmaece e o cartão abre de 0,9 com mola (SsRouteScale).',
      'showSsToast/showSsUndo: o aviso sobe de baixo com mola; arrastar para baixo ou para o lado dispensa (no desfazer, conta como não desfeito); soltar antes volta com mola.',
      'SsContextMenu: o item levanta e o menu brota da âncora passando um pouco do tamanho; as linhas descem em cascata. SsOverflowMenu: linhas em cascata (SsRouteStagger).',
    ],
    estados: [Estado('botoes', 'abrir cada camada', (_) => const _Camadas(), tamanho: const Size(360, 360))],
  ),

  // ------------------------------------------------------- listas e cards
  Componente(
    'mov-timeline-kanban',
    'SsTimeline · SsKanban (entrada)',
    'A linha do tempo chega em cascata e o fio se desenha para baixo; os cards do kanban entram com mola.',
    comportamentos: [
      'SsTimeline: itens 70 ms um depois do outro, subindo com mola; o fio de cada um desce até o próximo; o atual pulsa uma vez.',
      'SsKanban: os cards de cada coluna chegam em cascata quando a coluna aparece.',
    ],
    estados: [
      Estado(
        'timeline',
        'linha do tempo',
        (_) => _Repetir(
          (_) => const SsTimeline(
            items: [
              SsTimelineItem(title: 'Pedido recebido', time: '09:12', done: true),
              SsTimelineItem(title: 'Separado', time: '10:40', done: true),
              SsTimelineItem(title: 'Saiu para entrega', time: '13:05', current: true),
              SsTimelineItem(title: 'Entregue', time: '—'),
            ],
          ),
        ),
        tamanho: const Size(360, 380),
        aguarde: 900,
      ),
      Estado(
        'kanban',
        'cards em cascata',
        (_) => _Repetir(
          (context) => SsKanban<String>(
            columns: const [
              SsKanbanColumn(id: 'a', title: 'Recebido', items: ['#1042', '#1043', '#1045']),
              SsKanbanColumn(id: 'b', title: 'Em rota', items: ['#1039']),
            ],
            onMove: (_, _, _, _) {},
            cardBuilder: (context, s) => _cartao(context, 'Pedido $s', 'Arraste para mover'),
          ),
        ),
        tamanho: const Size(360, 420),
        aguarde: 900,
      ),
    ],
  ),

  Componente(
    'mov-cards',
    'Cards com mola',
    'SsWalletCard inclina para o dedo, SsCardStack abre com mola física, SsGoalCard brota, SsRecurringCard estoura o check, SsPeoplePicker estoura o avatar, SsStoryRing se desenha e o SsSnapCarousel assenta com mola.',
    comportamentos: [
      'SsWalletCard: com o dedo em cima, inclina até ~5° para o lado dele e volta com mola ao soltar; o saldo rola ao mudar.',
      'SsCardStack: abre e fecha com mola física (passa ~9%); tocar no meio herda a velocidade.',
      'SsGoalCard: a arte brota com mola e o sublinhado se desenha do meio quando o card aparece.',
      'SsRecurringCard: o check estoura com mola ao marcar; o valor rola ao mudar.',
      'SsPeoplePicker: o avatar escolhido encolhe e volta passando do tamanho; o ✓ entra com mola.',
      'SsStoryRing: os gomos se desenham em sequência quando o anel aparece.',
      'SsSnapCarousel: ao soltar, assenta no item com mola (passa ~4%); a bolinha ativa estica com mola.',
    ],
    estados: [
      Estado(
        'carteira-pilha',
        'toque e incline · toque para abrir',
        (_) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            spacing: 16,
            children: [
              const SsWalletCard(amount: 'R\$ 10.240,00', holder: 'Rita Souza', number: '•••• 4086'),
              SsCardStack(
                cardHeight: 90,
                children: [
                  for (var i = 0; i < 3; i++)
                    Builder(builder: (context) => _cartao(context, 'Cartão ${i + 1}', 'Toque na pilha')),
                ],
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 520),
      ),
      Estado(
        'meta-recorrente',
        'aparecer e marcar',
        (_) => _Repetir(
          (_) => _Guarda<bool>(
            false,
            (feito, muda) => Column(
              spacing: 12,
              children: [
                const SsGoalCard(text: 'Guarde para a viagem de fim de ano.', actionLabel: 'Criar meta'),
                SsRecurringCard(
                  schedule: 'Todo domingo',
                  time: '11:00',
                  amount: feito ? 'R\$ 150,00' : 'R\$ 120,00',
                  destination: 'para Instituto Sol',
                  done: feito,
                  onTap: () => muda(!feito),
                ),
              ],
            ),
          ),
          rolar: true,
        ),
        tamanho: const Size(360, 520),
        aguarde: 900,
      ),
      Estado(
        'social-carrossel',
        'escolher pessoas · carrossel',
        (_) => _Repetir(
          (context) => _Guarda<Set<String>>(
            {'Rita Souza'},
            (sel, muda) => Column(
              spacing: 12,
              children: [
                SsPeoplePicker(people: const ['Rita Souza', 'Cauã Lima', 'Ana Paula'], selected: sel, onChanged: muda),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SsStoryRing('Rita Souza', segments: 3, seen: 1, caption: 'Rita'),
                    SsStoryRing('Cauã Lima', segments: 1, caption: 'Cauã'),
                  ],
                ),
                SsSnapCarousel(
                  itemCount: 4,
                  height: 120,
                  itemBuilder: (context, i) => Container(
                    decoration: BoxDecoration(
                      color: SsColors.of(context).series[i % 6].withValues(alpha: .7),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                  ),
                ),
              ],
            ),
          ),
          rolar: true,
        ),
        tamanho: const Size(360, 520),
        aguarde: 900,
      ),
    ],
  ),
];

/// Botões que abrem cada camada (na vitrine, cada estado tem seu Navigator).
class _Camadas extends StatelessWidget {
  const _Camadas();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonal(
              onPressed: () => showSsSheet<void>(
                context,
                title: 'Nova despesa',
                subtitle: 'A folha sobe com mola',
                icon: Icons.receipt_long_outlined,
                child: const SizedBox(height: 120),
              ),
              child: const Text('Abrir folha'),
            ),
            FilledButton.tonal(
              onPressed: () => showSsUndo(context, 'Pedido excluído', bottom: 24),
              child: const Text('Mostrar aviso'),
            ),
            FilledButton.tonal(
              onPressed: () => showSsConfirm(context, title: 'Excluir o pedido?', danger: true),
              child: const Text('Confirmar'),
            ),
            FilledButton.tonal(
              onPressed: () => showSsPicker<String>(
                context,
                title: 'Cliente',
                items: const ['Mercado Bom Preço', 'Padaria Central', 'Hortifruti Sol'],
                labelOf: (s) => s,
              ),
              child: const Text('Escolher'),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: SsContextMenu(
                actions: [
                  SsContextAction(Icons.edit_outlined, 'Editar', () {}),
                  SsContextAction(Icons.copy_rounded, 'Duplicar', () {}),
                  SsContextAction(Icons.delete_outline, 'Excluir', () {}, destructive: true),
                ],
                child: Builder(builder: (context) => _cartao(context, 'Segure este card', 'Menu de contexto')),
              ),
            ),
            SsOverflowMenu(
              items: [
                SsMenuAction(Icons.sort_rounded, 'Ordenar', () {}),
                SsMenuAction(Icons.filter_list_rounded, 'Filtrar', () {}),
                SsMenuAction(Icons.delete_outline, 'Excluir', () {}, destructive: true),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}
