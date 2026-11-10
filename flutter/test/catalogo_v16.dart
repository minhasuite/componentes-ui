// Estados e comportamentos da v0.16 (etapa 5 da migração do minhas-compras e do
// minhas-viagens): peças novas em [catalogoV16] e os extras das que já existiam
// (por slug) em [comV16].
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';

import 'catalogo.dart';

void _nada() {}

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

/// O trecho com o tema de alto contraste do mesmo brilho do catálogo.
Widget _hc(BuildContext context, Widget child, {SsBrand brand = SsBrand.violeta}) => Theme(
  data: AppTheme.build(Theme.of(context).brightness, brand: brand, highContrast: true),
  child: Builder(builder: (_) => child),
);

Widget _amostra(BuildContext context) {
  final c = SsColors.of(context);
  return SsCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Lisboa em maio',
          style: TextStyle(color: c.ink, fontWeight: FontWeight.w800, fontSize: AppType.md),
        ),
        Text(
          '12 dias · 2 pessoas',
          style: TextStyle(color: c.muted, fontSize: AppType.sub),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            SsBadge('Confirmada', variant: SsBadgeVariant.accent),
            const SizedBox(width: 8),
            SsButton.text(label: 'Ver roteiro', trailingIcon: Icons.chevron_right_rounded, onPressed: _nada),
          ],
        ),
      ],
    ),
  );
}

final catalogoV16 = <Componente>[
  Componente(
    'ss-chart-legend',
    'SsChartLegend',
    'Legenda de gráfico (v0.16, par do Ss::ChartLegendComponent): cor da série, rótulo e valor opcional em DM Mono, em linhas que quebram.',
    comportamentos: [
      'line: traço no lugar da bolinha (série de linha); dashed: tracejado (alvo, média).',
      'Rótulo longo termina em "…" na largura do contêiner; o leitor de tela lê "rótulo: valor".',
      'Itens repetidos aparecem uma vez.',
    ],
    estados: [
      Estado('padrao', 'séries, valor e alvo tracejado', (context) {
        final c = SsColors.of(context);
        return _pad(
          SsChartLegend(
            items: [
              SsLegendItem('Atacadão', c.series[0]),
              SsLegendItem('Carrefour', c.series[1]),
              SsLegendItem('menor', AppColors.success, value: money(214800)),
              SsLegendItem('alvo', c.muted, value: money(199000), line: true, dashed: true),
            ],
          ),
        );
      }, tamanho: const Size(360, 90)),
    ],
  ),
  Componente(
    'ss-input-chip',
    'SsInputChip',
    'Chip de um valor escolhido que se tira com o ✕ (v0.16, par do .ss-tag): destino, etiqueta, validade.',
    comportamentos: [
      'onPressed (tocar no chip: editar) e onDeleted (o ✕; nulo, o ✕ some) são independentes.',
      'O ✕ tem alvo de 48 e a dica "Remover Lisboa" (deleteTooltip troca).',
      'Rótulo longo termina em "…" (o leitor de tela lê tudo).',
    ],
    estados: [
      Estado(
        'padrao',
        'com ícone, só leitura e rótulo longo',
        (_) => _pad(
          SizedBox(
            width: 280,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                SsInputChip('Lisboa', icon: Icons.place_outlined, onDeleted: _nada),
                const SsInputChip('Porto'),
                SsInputChip('Vence 12/11/2026', icon: Icons.event_outlined, onPressed: _nada, onDeleted: _nada),
                SsInputChip('Madri, Espanha, Península Ibérica', icon: Icons.place_outlined, onDeleted: _nada),
              ],
            ),
          ),
        ),
        tamanho: const Size(320, 150),
      ),
    ],
  ),
  Componente(
    'ss-diverging-bars',
    'SsDivergingBars',
    'Barras para os dois lados de um eixo (v0.16, par do Ss::DivergingBarsComponent): o que subiu vai à direita, o que caiu à esquerda.',
    comportamentos: [
      'Tamanho proporcional ao maior |valor|; nome em cima da barra, valor com sinal em DM Mono.',
      'Subir é ruim (vermelho) e cair é bom (verde) por padrão; upIsGood inverte.',
      'As barras crescem do eixo em cascata (60 ms entre elas) quando entram na tela.',
    ],
    estados: [
      Estado(
        'padrao',
        'inflação da cesta (p.p.)',
        (_) => _pad(
          const SsDivergingBars(
            unit: 'p.p.',
            items: [
              SsDivergingBar('Café torrado', 1.8, detail: '+32% · 9% da cesta'),
              SsDivergingBar('Azeite extra virgem', .9),
              SsDivergingBar('Tomate', -.6, detail: '−18%'),
            ],
          ),
        ),
        tamanho: const Size(360, 240),
        aguarde: 900,
      ),
    ],
  ),
  Componente(
    'ss-rating',
    'SsRating',
    'Nota em estrelas (v0.16, par do .ss-stars / Ss::RatingComponent): leitura com meia e edição com uma estrela por toque.',
    comportamentos: [
      'Leitura: 4,5 pinta metade da 5ª estrela; o leitor de tela lê "Nota 4,5 de 5".',
      'Com onChanged, cada estrela é um botão de alvo 48 ("3 estrelas") e o grupo aceita deslizar para cima/baixo.',
      'Toque encolhe a estrela com a mola e vibra leve.',
    ],
    estados: [
      Estado(
        'padrao',
        'leitura (4,5) e edição (3)',
        (_) => _pad(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SsRating(4.5),
              const SizedBox(height: 8),
              SsRating(3, size: 32, onChanged: (_) {}),
            ],
          ),
        ),
        tamanho: const Size(360, 120),
      ),
    ],
  ),
  Componente(
    'ss-compare-table',
    'SsCompareTable',
    'Comparação lado a lado (v0.16, mesma API e desenho do Ss::CompareTableComponent): planos, fornecedores, destinos.',
    comportamentos: [
      'Coluna recomendada com a fita "Recomendado", topo e fundo na marca.',
      'true vira ✓ (Incluído), false/null vira — (Não incluído); best: pinta a célula de verde.',
      'Rola de lado quando não cabe (columnWidth por coluna).',
    ],
    estados: [
      Estado(
        'padrao',
        'destinos com o menor total',
        (_) => _pad(
          const SsCompareTable(
            caption: 'Destinos',
            columnWidth: 96,
            labelWidth: 96,
            plans: [
              SsComparePlan('Lisboa', price: 'maio'),
              SsComparePlan('Porto', price: 'maio', recommended: true),
            ],
            features: [
              SsCompareFeature('Total', ['R\$ 8.000', 'R\$ 7.200'], best: 1),
              SsCompareFeature('Voo direto', [true, false]),
              SsCompareFeature('Fuso', ['+3 h', '+3 h'], mono: false),
            ],
          ),
        ),
        tamanho: const Size(360, 260),
      ),
    ],
  ),
  Componente(
    'ss-series-ink',
    'SsColors.seriesInk',
    'Série de cores em variante de texto (v0.16, --series-ink-1..6 no web): a cor da série puxada para a tinta até 4,5:1 sobre o fundo.',
    comportamentos: [
      'seriesInk[i] escreve o que series[i] pinta: mais escura no claro, mais clara no escuro.',
      'inkFor(cor) faz o mesmo para qualquer cor (categoria, carimbo); 7:1 no alto contraste.',
    ],
    estados: [
      Estado('padrao', 'series (ponto) × seriesInk (texto)', (context) {
        final c = SsColors.of(context);
        return _pad(
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              for (var i = 0; i < c.series.length; i++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: c.series[i], shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Série ${i + 1}',
                      style: TextStyle(color: c.seriesInk[i], fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
            ],
          ),
        );
      }, tamanho: const Size(360, 110)),
    ],
  ),
  Componente(
    'ss-high-contrast',
    'AppTheme.build(highContrast: true)',
    'Alto contraste (v0.16, data-ss-contrast="high" no web): o acento da marca a 7:1 gerado da paleta, texto apagado no tom do ink2 e linhas mais fortes.',
    comportamentos: [
      'SsBrand.highContrast(): accent puxado para o preto (claro) ou para o branco (escuro) até 7:1; sólido a 7:1 com texto branco.',
      'Mesma conta do paletas/gerar.py, que gera o alto contraste do web para as 30 paletas.',
      'Num trecho: Theme(data: AppTheme.build(b, brand:, highContrast: true)).',
    ],
    estados: [
      Estado(
        'normal',
        'Petróleo, normal',
        (context) => _pad(
          Theme(
            data: AppTheme.build(Theme.of(context).brightness, brand: SsBrand.petroleo),
            child: Builder(builder: _amostra),
          ),
        ),
        tamanho: const Size(360, 210),
      ),
      Estado(
        'alto',
        'Petróleo, alto contraste',
        (context) => _pad(_hc(context, Builder(builder: _amostra), brand: SsBrand.petroleo)),
        tamanho: const Size(360, 210),
      ),
    ],
  ),
  Componente(
    'ss-date-picker',
    'showSsDatePicker',
    'O calendário do pacote fora do SsDateField (v0.16): textos do SsStrings, data inicial presa no intervalo e o tema do app.',
    comportamentos: [
      'Título "Escolher data", Cancelar e Confirmar do SsStrings (pt, en, es); calendário no idioma do SsStrings.',
      'initialDate fora de firstDate–lastDate é trazida para dentro (sem o assert do showDatePicker cru).',
      'Devolve o dia sem hora, ou nulo se cancelar. O SsDateField passa a usá-lo.',
    ],
    estados: [
      Estado(
        'aberto',
        'calendário de novembro',
        (_) => DatePickerDialog(
          initialDate: DateTime(2026, 11, 12),
          firstDate: DateTime(2026),
          lastDate: DateTime(2027, 12, 31),
          currentDate: DateTime(2026, 11, 10),
          helpText: SsStrings.pt.pickDate,
          confirmText: SsStrings.pt.confirm,
          cancelText: SsStrings.pt.cancel,
        ),
        tamanho: const Size(360, 560),
      ),
    ],
  ),
];

/// Soma os extras da v0.16 às entradas de [base] com o mesmo slug.
List<Componente> comV16(List<Componente> base) => [
  for (final c in base)
    if (_v16[c.slug] case (final comp, final est))
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

final Map<String, (List<String>, List<Estado>)> _v16 = {
  'ss-offer-card': (
    [
      'v0.16: badges (selos), meta (linha pequena), actions (rodapé), menu (⋮) e hit (preço no alvo, verde).',
      'v0.16: kind/kindIcon (tipo em caixa alta), unit (embaixo do preço), savings/savingsGood e estimate (≈, borda tracejada).',
      'v0.16: stacked/fill: preço embaixo do texto (cartão estreito numa fileira; fill desce até a base).',
    ],
    [
      Estado(
        'completa',
        'selos, meta, ação e menu (compras)',
        (_) => _pad(
          SsOfferCard(
            source: 'Mercado Livre',
            title: 'Fone Bluetooth JBL Tune 520BT preto',
            price: money(21990),
            note: 'à vista · ou 10x ${money(2390)} sem juros',
            hit: true,
            badges: const [
              SsBadge('promoção de verdade', variant: SsBadgeVariant.success, micro: true),
              SsBadge('em estoque', variant: SsBadgeVariant.ghost, micro: true),
            ],
            meta: 'verificado 12/10/2026 14:00',
            actions: [SsButton.text(label: 'Ver oferta', trailingIcon: Icons.open_in_new_rounded, onPressed: _nada)],
            menu: SsOverflowMenu(items: [SsMenuAction(Icons.flag_outlined, 'Reportar', _nada)]),
          ),
        ),
        tamanho: const Size(360, 300),
      ),
      Estado(
        'fileira',
        'tipo, unidade, economia e estimativa (viagens)',
        (_) => _pad(
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 290,
                  child: SsOfferCard(
                    source: 'CVC',
                    kind: 'Pacote',
                    title: 'Viasui Hotel · café da manhã',
                    price: money(780800),
                    unit: '${money(390400)} por pessoa',
                    savings: '${money(11200)} abaixo do alvo',
                    best: true,
                    fill: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 290,
                  child: SsOfferCard(
                    source: 'Kayak + Booking',
                    kind: 'voo + hospedagem',
                    title: 'Voo e hotel mais baratos nas datas',
                    price: money(812000),
                    estimate: true,
                    savings: '+${money(31200)} que a mais barata',
                    savingsGood: false,
                    fill: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        tamanho: const Size(420, 330),
      ),
    ],
  ),
  'ss-filter-chip': (
    ['v0.16: rótulo longo termina em "…" na largura que sobra (estourava 35 px a 1,3× num Wrap estreito).'],
    [
      Estado(
        'longo',
        'rótulo longo em 200 px',
        (_) => _pad(
          SizedBox(
            width: 200,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                SsFilterChip('Quanto gastei com café este ano?', selected: false, onTap: _nada),
                SsFilterChip('Mercado', selected: true, onTap: _nada, count: 3),
              ],
            ),
          ),
        ),
        tamanho: const Size(240, 130),
      ),
    ],
  ),
  'ss-sparkline': (
    [
      'v0.16: target desenha a linha tracejada do alvo (entra na escala); markMin marca o menor valor com um ponto verde.',
    ],
    [
      Estado(
        'alvo',
        'alvo tracejado e o menor marcado',
        (_) => _pad(const SsSparkline([329, 312, 298, 305, 279, 301, 318], target: 290, markMin: true, height: 56)),
        tamanho: const Size(360, 100),
        aguarde: 900,
      ),
    ],
  ),
  'ss-button': (
    [
      'v0.16: trailingIcon põe o ícone depois do rótulo ("Ver todas ›").',
      'v0.16: SsButton.text(tone:) pinta o texto no tom (aviso, perigo); onDark: claro sobre foto, câmera ou gradiente.',
    ],
    [
      Estado(
        'texto-v16',
        'ícone no fim · aviso · sobre o escuro',
        (context) => Column(
          children: [
            _pad(
              Wrap(
                spacing: 8,
                children: [
                  SsButton.text(label: 'Ver todas', trailingIcon: Icons.chevron_right_rounded, onPressed: _nada),
                  SsButton.text(
                    label: 'Vence logo',
                    icon: Icons.warning_amber_rounded,
                    tone: SsTone.warning,
                    onPressed: _nada,
                  ),
                ],
              ),
            ),
            Container(
              color: SsColors.of(context).headerBg,
              padding: const EdgeInsets.all(12),
              alignment: Alignment.center,
              child: SsButton.text(
                label: 'Usar inteira',
                icon: Icons.crop_free_rounded,
                onDark: true,
                onPressed: _nada,
              ),
            ),
          ],
        ),
        tamanho: const Size(360, 200),
      ),
    ],
  ),
  'ss-stat-card': (
    ['v0.16: SsDelta.neutral("0%"): traço no lugar da seta e tom apagado (sem variação).'],
    [
      Estado(
        'delta-neutro',
        'SsDelta: subiu bom · caiu ruim · neutro',
        (_) => _pad(
          const Wrap(
            spacing: 8,
            children: [SsDelta('12%', up: true), SsDelta('4%', up: false, good: false), SsDelta.neutral('0%')],
          ),
        ),
        tamanho: const Size(360, 70),
      ),
    ],
  ),
  'ss-countdown-ring': (
    ['v0.16: warnAt troca os 20% do aquecimento por uma conta fixa (warnAt: 2 aquece com 2 ou menos).'],
    [
      Estado(
        'warn-at',
        'total 7, warnAt 2: 6 · 2 · 0',
        (_) => _pad(
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SsCountdownRing(total: 7, left: 6, warnAt: 2, size: 76, label: 'dias'),
              SsCountdownRing(total: 7, left: 2, warnAt: 2, size: 76, label: 'dias'),
              SsCountdownRing(total: 7, left: 0, warnAt: 2, size: 76, label: 'dias'),
            ],
          ),
        ),
        tamanho: const Size(360, 120),
      ),
    ],
  ),
  'ss-proportion-bar': (
    [
      'v0.16: onDark para o herói em gradiente (trilha translúcida, legenda clara, cores da paleta clareadas).',
      'v0.16: legendValue: SsLegendValue.count troca o % pela contagem antes do rótulo ("3 vencidos") e esconde as partes zeradas.',
    ],
    [
      Estado(
        'on-dark',
        'sobre o gradiente, com contagem',
        (context) => Container(
          decoration: BoxDecoration(gradient: SsColors.of(context).gradient4),
          padding: const EdgeInsets.all(16),
          child: const SsProportionBar(
            onDark: true,
            legendValue: SsLegendValue.count,
            parts: [(1, 'vencido', null), (3, 'vencem na semana', null), (0, 'abertos', null), (9, 'em dia', null)],
          ),
        ),
        tamanho: const Size(360, 110),
        aguarde: 900,
      ),
    ],
  ),
  'ss-reorderable-list': (
    [
      'v0.16: primary: false dentro de um NestedScrollView (aba com cabeçalho que encolhe): a rolagem não vaza para o de fora.',
    ],
    const [],
  ),
  'ss-net-image': (
    [
      'v0.16: placeholderColor (a cor média da foto, vinda da API) troca as listras por um degradê dessa cor, com ícone e iniciais claros.',
    ],
    [
      Estado(
        'cor',
        'vazio com a cor da foto',
        (_) => _pad(
          const Row(
            children: [
              SsNetImage(null, width: 140, height: 96, name: 'Lisboa', placeholderColor: Color(0xFF2E6A8C)),
              SizedBox(width: 12),
              SsNetImage(
                null,
                width: 96,
                height: 96,
                fallbackIcon: Icons.landscape_outlined,
                placeholderColor: Color(0xFF7A4B2A),
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 130),
      ),
    ],
  ),
  'ss-timeline': (
    [
      'v0.16: endTime vai depois do horário ("09:30 – 11:00"); alert (conflito, atraso) pinta o horário de vermelho com ⚠.',
    ],
    [
      Estado(
        'roteiro',
        'fim e conflito de horário',
        (_) => _pad(
          const SsTimeline(
            items: [
              SsTimelineItem(
                title: 'Voo GRU → LIS',
                time: '09:30',
                endTime: '11:00',
                icon: Icons.flight_takeoff,
                done: true,
              ),
              SsTimelineItem(
                title: 'Check-in no hotel',
                time: '10:45',
                icon: Icons.hotel_outlined,
                alert: true,
                current: true,
              ),
              SsTimelineItem(title: 'Jantar no Bairro Alto', time: '20:00', icon: Icons.restaurant_outlined),
            ],
          ),
        ),
        tamanho: const Size(360, 260),
        aguarde: 1200,
      ),
    ],
  ),
  'ss-picker': (
    [
      'v0.16: allowCustom deixa usar o texto digitado: a 1ª linha vira "Usar “texto”" e o Enter também usa (customOf transforma em T).',
      'v0.16: noneLabel ("Sem loja") põe no topo, com a busca vazia, a linha que devolve customOf(\'\').',
    ],
    [
      Estado(
        'livre',
        'texto que não está na lista',
        (_) => SsPickerSheet<String>(
          title: 'Onde comprou?',
          items: const ['Atacadão', 'Feira da Lapa', 'Padaria Real'],
          initialQuery: 'Feira do bairro',
          allowCustom: true,
          onSelect: (_) {},
        ),
        tamanho: const Size(360, 420),
      ),
    ],
  ),
  'ss-screen-header': (
    [
      'v0.16: SsSliverHeader(background:) mostra a capa (foto, herói do registro) no lugar do título grande, com o título sempre na barra.',
      'v0.16: a capa sobe por baixo da barra e apaga ao rolar; o bottom (abas) continua preso. backgroundHeight: 180 por padrão.',
    ],
    [
      Estado(
        'capa',
        'capa com abas presas',
        (context) => CustomScrollView(
          slivers: [
            SsSliverHeader(
              title: 'Lisboa em maio',
              actions: [SsHeaderAction(icon: Icons.more_vert, tooltip: 'Mais', onPressed: _nada)],
              background: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: SsColors.of(context).gradient4,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.all(16),
                  child: const Text(
                    'faltam 12 dias',
                    style: TextStyle(color: AppColors.onDark, fontWeight: FontWeight.w800, fontSize: AppType.lg),
                  ),
                ),
              ),
              backgroundHeight: 150,
              bottom: SsTabsUnderline(tabs: const ['Cronograma', 'Reservas', 'Gastos'], index: 0, onChanged: (_) {}),
            ),
            SliverList.list(children: [for (var i = 0; i < 6; i++) ListTile(title: Text('Parada ${i + 1}'))]),
          ],
        ),
        tamanho: const Size(360, 420),
      ),
    ],
  ),
};
