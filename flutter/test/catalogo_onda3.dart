// Entradas do catálogo da onda3: gráfico de linhas, calendários, linha do
// tempo, medidores e barras de progresso.
import 'package:flutter/material.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo.dart';

Widget _pad(Widget w) => Padding(
  padding: const EdgeInsets.all(16),
  child: Center(child: w),
);
void _nadaD(DateTime _) {}

final _out = DateTime(2026, 10);
final _hoje = DateTime(2026, 10, 31);
const _precos = [12.9, 13.4, 12.1, 11.8, 12.6, 13.9, 14.2, 13.1, 12.4, 11.9, 12.8, 13.5];
final _datas = [for (var i = 0; i < 12; i++) '${two(1 + i * 2)}/10'];
String _reais(double v) => money((v * 100).round());

final _constancia = <DateTime, double>{
  for (var i = 0; i < 126; i++)
    if (i % 3 != 0 && i % 7 != 5) DateTime(2026, 10, 31 - i): ((i * 37) % 5 + 1).toDouble(),
};

class _Mes extends StatefulWidget {
  const _Mes();
  @override
  State<_Mes> createState() => _MesState();
}

class _MesState extends State<_Mes> {
  late DateTime m = _out;
  @override
  Widget build(BuildContext context) => SsMonthSwitcher(month: m, max: _out, onChanged: (v) => setState(() => m = v));
}

final catalogoOnda3 = <Componente>[
  Componente(
    'ss-line-chart',
    'SsLineChart',
    'Gráfico de linhas (até 3 séries) com eixo discreto: 3 linhas guia com o valor em DM Mono e poucos rótulos embaixo.',
    comportamentos: [
      'Desenha-se da esquerda para a direita ao aparecer (800 ms).',
      'Arrastar o dedo mostra a linha vertical, um ponto por série e um balão com a data e os valores; soltou, some.',
      'Tique de haptic (selectionClick) a cada ponto novo cruzado.',
      'Linha de alvo tracejada opcional com rótulo e valor à direita.',
      'Uma série ganha preenchimento que some para baixo; com mais séries, só as linhas.',
      'Sem cor, as séries usam a marca e depois a paleta da suíte.',
      'Leitor de tela: resumo com mínimo, máximo e último.',
    ],
    estados: [
      Estado(
        'uma',
        'uma série',
        (_) => _pad(
          SsLineChart(
            series: const [SsSeries(_precos, name: 'Preço')],
            labels: _datas,
            format: _reais,
          ),
        ),
        tamanho: const Size(360, 220),
        aguarde: 900,
      ),
      Estado(
        'alvo',
        'duas séries e alvo',
        (_) => _pad(
          SsLineChart(
            series: [
              const SsSeries(_precos, name: 'Este mês'),
              SsSeries([for (final p in _precos.reversed) p - .8], name: 'Mês passado'),
            ],
            labels: _datas,
            target: 13,
            format: _reais,
          ),
        ),
        tamanho: const Size(360, 220),
        aguarde: 900,
      ),
      Estado(
        'desenhando',
        'desenhando',
        (_) => _pad(SsLineChart(series: const [SsSeries(_precos)], labels: _datas, format: _reais)),
        tamanho: const Size(360, 220),
        aguarde: 200,
      ),
    ],
  ),
  Componente(
    'ss-month-switcher',
    'SsMonthSwitcher',
    '‹ Outubro 2026 ›: troca de mês, com min/max travando as setas.',
    comportamentos: [
      'O título desliza na direção da troca (o novo entra pelo lado da seta) com fade.',
      'Tocar no título volta ao mês atual.',
      'Haptic de seleção na troca; seta fora do min/max fica desabilitada.',
    ],
    estados: [
      Estado('atual', 'mês atual (max)', (_) => _pad(const _Mes()), tamanho: const Size(360, 80)),
      Estado(
        'outro',
        'outro mês',
        (_) => _pad(SsMonthSwitcher(month: DateTime(2026, 3), onChanged: _nadaD)),
        tamanho: const Size(360, 80),
      ),
    ],
  ),
  Componente(
    'ss-month-grid',
    'SsMonthGrid',
    'Grade do mês em 7 colunas, semana começando no domingo (D S T Q Q S S).',
    comportamentos: [
      'Hoje tem anel na cor da marca; o selecionado tem o fundo da marca.',
      'Marcadores viram até 3 pontinhos coloridos embaixo do dia.',
      'Dias de fora do mês ficam apagados e não são tocáveis.',
      'Arrastar para o lado troca de mês (onMonthChanged).',
      'Toque com haptic de seleção; leitor de tela lê a data, "hoje" e os marcadores.',
    ],
    estados: [
      Estado(
        'padrao',
        'com hoje, seleção e marcadores',
        (_) => _pad(
          SsMonthGrid(
            month: _out,
            today: _hoje,
            selected: DateTime(2026, 10, 14),
            markers: {
              DateTime(2026, 10, 3): [AppColors.success],
              DateTime(2026, 10, 14): [AppColors.success, AppColors.danger],
              DateTime(2026, 10, 22): [AppColors.aquecFg, AppColors.success, AppColors.danger],
            },
            onSelect: _nadaD,
          ),
        ),
        tamanho: const Size(360, 360),
      ),
    ],
  ),
  Componente(
    'ss-heat-calendar',
    'SsHeatCalendar',
    'Constância estilo contribuições do GitHub: uma coluna por semana, 5 níveis da cor da marca, com SsHeatLegend.',
    comportamentos: [
      'Últimas N semanas (padrão 18) até hoje, ou só um mês.',
      'Nível pelo maior valor: vazio, 1/4, 2/4, 3/4 e cheio.',
      'Tocar num dia mostra a data e o valor embaixo (format); tocar de novo esconde.',
      'Leitor de tela lê a data e o valor de cada dia.',
    ],
    estados: [
      Estado(
        'semanas',
        '18 semanas',
        (_) => _pad(SsHeatCalendar(values: _constancia, end: _hoje)),
        tamanho: const Size(360, 200),
      ),
      Estado(
        'mes',
        'um mês',
        (_) => _pad(SsHeatCalendar(values: _constancia, month: _out)),
        tamanho: const Size(360, 320),
      ),
    ],
  ),
  Componente(
    'ss-timeline',
    'SsTimeline',
    'Linha do tempo vertical: nós ligados por uma linha; passado cheio, atual em destaque, futuro tracejado.',
    comportamentos: [
      'Os itens entram em cascata (60 ms entre eles), subindo com fade.',
      'O nó atual pulsa um anel UMA vez ao aparecer e fica com halo suave.',
      'Linha cheia depois do que já passou; tracejada no que vem.',
      'Horário em DM Mono em cima do título; child opcional embaixo.',
      'Leitor de tela: "Passo 2 de 4, agora".',
    ],
    estados: [
      Estado(
        'padrao',
        'feito, agora e a seguir',
        (_) => _pad(
          const SsTimeline(
            items: [
              SsTimelineItem(title: 'Check-in no hotel', subtitle: 'Rua Augusta, 120', time: '14:00', done: true),
              SsTimelineItem(
                title: 'Passeio no centro histórico',
                subtitle: 'Saída da recepção',
                time: '16:30',
                icon: Icons.directions_walk_rounded,
                current: true,
              ),
              SsTimelineItem(title: 'Jantar', time: '20:00', icon: Icons.restaurant_rounded),
              SsTimelineItem(title: 'Voo de volta', time: '08:15'),
            ],
          ),
        ),
        tamanho: const Size(360, 340),
      ),
      Estado(
        'pulso',
        'atual pulsando',
        (_) => _pad(
          const SsTimeline(
            items: [
              SsTimelineItem(title: 'Germinação', time: '01/10', done: true),
              SsTimelineItem(title: 'Muda', time: '12/10', current: true),
            ],
          ),
        ),
        tamanho: const Size(360, 160),
        aguarde: 380,
      ),
    ],
  ),
  Componente(
    'ss-gauge',
    'SsGauge',
    'Meia-lua com faixas (padrão barato / normal / caro) e um ponto que vai com mola até o valor.',
    comportamentos: [
      'O ponto anda com mola (easeOutBack, 900 ms) do valor anterior até o novo.',
      'A faixa do valor fica forte e as outras apagadas; o rótulo dela vai embaixo com um ponto da cor.',
      'Faixas próprias: (até, rótulo, cor), em ordem.',
      'center vai dentro da meia-lua (o número); label é a legenda de baixo.',
    ],
    estados: [
      Estado(
        'barato',
        'barato',
        (_) => _pad(
          SsGauge(
            value: .2,
            label: 'vs. últimos 90 dias',
            center: Builder(builder: (c) => Text(r'R$ 11,90', style: AppTheme.number(c, size: 20))),
          ),
        ),
        tamanho: const Size(360, 200),
      ),
      Estado('caro', 'caro', (_) => _pad(const SsGauge(value: .86)), tamanho: const Size(360, 180)),
    ],
  ),
  Componente(
    'ss-countdown-ring',
    'SsCountdownRing',
    'Contagem regressiva em gomos, um por dia; o número que resta no meio.',
    comportamentos: [
      'Os gomos que restam ficam na cor da marca; com 20% ou menos, aquecimento; em 0, vermelho.',
      'Os gomos acendem em sequência ao aparecer (600 ms).',
      'Mais de 60 gomos viram um anel contínuo.',
      'Leitor de tela: "Faltam 12 de 30 dias".',
    ],
    estados: [
      Estado(
        'folga',
        '12 de 30',
        (_) => _pad(const SsCountdownRing(total: 30, left: 12)),
        tamanho: const Size(360, 140),
      ),
      Estado('pouco', '2 de 14', (_) => _pad(const SsCountdownRing(total: 14, left: 2)), tamanho: const Size(360, 140)),
      Estado('zero', 'acabou', (_) => _pad(const SsCountdownRing(total: 7, left: 0)), tamanho: const Size(360, 140)),
    ],
  ),
  Componente(
    'ss-progress',
    'SsProgress',
    'Barra de progresso em pílula: 0 a 1, com marca de "onde devia estar", estouro e gomos.',
    comportamentos: [
      'Cresce de 0 ao aparecer (600 ms).',
      'Em 100% vira verde (sucesso).',
      'marker: tracinho de "onde devia estar hoje", com rótulo opcional em cima.',
      'Acima de 1 é estouro: o 100% recua e o excesso aparece listrado em vermelho.',
      'segments divide a barra em N gomos.',
    ],
    estados: [
      Estado('meio', '50%', (_) => _pad(const SsProgress(.5)), tamanho: const Size(360, 48), aguarde: 700),
      Estado('cheio', '100%', (_) => _pad(const SsProgress(1)), tamanho: const Size(360, 48), aguarde: 700),
      Estado(
        'marca',
        'com marca de hoje',
        (_) => _pad(const SsProgress(.42, marker: .6, markerLabel: 'hoje')),
        tamanho: const Size(360, 64),
        aguarde: 700,
      ),
      Estado(
        'estouro',
        '130%',
        (_) => _pad(const SsProgress(1.3, height: 12)),
        tamanho: const Size(360, 48),
        aguarde: 700,
      ),
      Estado(
        'gomos',
        '3 de 5 gomos',
        (_) => _pad(const SsProgress(.6, segments: 5)),
        tamanho: const Size(360, 48),
        aguarde: 700,
      ),
    ],
  ),
  Componente(
    'ss-proportion-bar',
    'SsProportionBar',
    'Categorias numa barra só, cantos arredondados, com legenda e % em DM Mono.',
    comportamentos: [
      'Cresce da esquerda ao aparecer (600 ms).',
      'Tocar numa parte (na barra ou na legenda) destaca ela e apaga as outras; tocar de novo desfaz.',
      'Sem cor, as partes usam a marca e depois a paleta da suíte.',
      'Leitor de tela: "Mercado: 45%".',
    ],
    estados: [
      Estado(
        'padrao',
        'com legenda',
        (_) => _pad(
          const SsProportionBar(
            parts: [(450, 'Mercado', null), (250, 'Casa', null), (180, 'Transporte', null), (120, 'Lazer', null)],
          ),
        ),
        tamanho: const Size(360, 130),
        aguarde: 700,
      ),
    ],
  ),
];
