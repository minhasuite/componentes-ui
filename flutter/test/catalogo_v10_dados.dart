// Entradas do catálogo da v0.10 (dados): histórico da casa (gráfico de séries
// no tempo e faixas de estado), logbook por dia e tabela de dados.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo.dart';

const _pt = Locale('pt', 'BR');

/// "Agora" fixo: o catálogo sai igual em todo lugar.
final agoraDemo = DateTime(2026, 11, 4, 14, 30);

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

/// Leituras desiguais (de 4 a 40 min entre elas) de [horas] até [agoraDemo].
List<SsTimePoint> leiturasDemo({
  required int seed,
  required double base,
  required double amp,
  int horas = 48,
  double ruido = .4,
  int? buracoNaHora,
}) {
  final rnd = math.Random(seed);
  final ini = agoraDemo.subtract(Duration(hours: horas));
  final out = <SsTimePoint>[];
  var t = ini;
  while (t.isBefore(agoraDemo)) {
    final h = t.hour + t.minute / 60;
    // Ciclo do dia: mínimo às 5 h, máximo às 15 h.
    final ciclo = math.sin((h - 9) / 24 * 2 * math.pi);
    final noBuraco = buracoNaHora != null && t.difference(ini).inHours == buracoNaHora;
    out.add(SsTimePoint(t, noBuraco ? null : base + amp * ciclo + (rnd.nextDouble() - .5) * ruido * 2));
    t = t.add(Duration(minutes: 4 + rnd.nextInt(36)));
  }
  return out;
}

List<SsTimeSeries> seriesClima() => [
  SsTimeSeries(name: 'Sala', unit: '°C', points: leiturasDemo(seed: 1, base: 23, amp: 2.6), decimals: 1),
  SsTimeSeries(
    name: 'Quarto',
    unit: '°C',
    points: leiturasDemo(seed: 2, base: 21.5, amp: 1.8, buracoNaHora: 20),
    decimals: 1,
  ),
  SsTimeSeries(
    name: 'Umidade da sala',
    unit: '%',
    points: leiturasDemo(seed: 3, base: 62, amp: -9, ruido: 2),
    decimals: 0,
  ),
];

List<SsStateSegment> _alterna(int seed, String a, String b, {String? la, String? lb, int horas = 48}) {
  final rnd = math.Random(seed);
  final out = <SsStateSegment>[];
  var t = agoraDemo.subtract(Duration(hours: horas));
  var on = false;
  while (t.isBefore(agoraDemo)) {
    final fim = t.add(Duration(minutes: on ? 20 + rnd.nextInt(160) : 60 + rnd.nextInt(360)));
    final f = fim.isAfter(agoraDemo) ? agoraDemo : fim;
    out.add(SsStateSegment(t, f, on ? a : b, label: on ? la : lb));
    t = f;
    on = !on;
  }
  return out;
}

List<SsStateRow> faixasDemo({bool longo = false}) {
  final ini24 = agoraDemo.subtract(const Duration(hours: 24));
  DateTime h(double x) => ini24.add(Duration(minutes: (x * 60).round()));
  return [
    SsStateRow(
      longo ? 'Luz pendente da mesa de jantar (sala de estar, térreo)' : 'Luz da sala',
      _alterna(4, 'on', 'off', la: 'Ligada', lb: 'Desligada'),
      current: 'Desligada',
    ),
    SsStateRow(
      'Porta da frente',
      _alterna(5, 'open', 'closed', la: 'Aberta', lb: 'Fechada'),
      current: 'Fechada',
    ),
    SsStateRow('Aspirador', [
      SsStateSegment(agoraDemo.subtract(const Duration(hours: 48)), h(9), 'docked', label: 'Na base'),
      SsStateSegment(h(9), h(10.2), 'cleaning', label: 'Limpando'),
      SsStateSegment(h(10.2), h(10.5), 'returning', label: 'Voltando'),
      SsStateSegment(h(10.5), h(18), 'docked', label: 'Na base'),
      SsStateSegment(h(18), h(18.4), 'error', label: 'Preso'),
      SsStateSegment(h(18.4), agoraDemo, 'docked', label: 'Na base'),
    ], current: 'Na base'),
  ];
}

const _tonsAspirador = {'docked': SsTone.neutral, 'cleaning': SsTone.success, 'returning': SsTone.info};

List<SsLogEntry> eventosDemo({int dias = 3, int porDia = 4}) {
  const modelos = [
    ('Luz da sala ligada', 'pela automação Pôr do sol', Icons.lightbulb_outline_rounded, SsTone.accent, 'Ligada'),
    ('Porta da frente aberta', 'Ana', Icons.door_front_door_outlined, SsTone.warning, 'Aberta'),
    ('Alarme armado', 'modo Noite · pelo app', Icons.shield_outlined, SsTone.success, null),
    ('Aspirador preso', 'perto do sofá', Icons.error_outline_rounded, SsTone.danger, 'Erro'),
    ('Temperatura acima de 28 °C', 'Quarto', Icons.thermostat_rounded, SsTone.warning, null),
    ('Cena Cinema', null, Icons.movie_outlined, SsTone.neutral, null),
  ];
  final out = <SsLogEntry>[];
  for (var d = 0; d < dias; d++) {
    for (var i = 0; i < porDia; i++) {
      final m = modelos[(d * porDia + i) % modelos.length];
      out.add(
        SsLogEntry(
          at: DateTime(agoraDemo.year, agoraDemo.month, agoraDemo.day - d, 13 - i * 3, 47 - i * 11),
          title: m.$1,
          detail: m.$2,
          icon: m.$3,
          tone: m.$4,
          state: m.$5,
          onTap: () {},
        ),
      );
    }
  }
  return out;
}

/// Logbook que carrega a página 2 de mentira (600 ms) ao tocar ou rolar.
class LogbookDemo extends StatefulWidget {
  const LogbookDemo({super.key, this.falha = false});

  final bool falha;

  @override
  State<LogbookDemo> createState() => _LogbookDemoState();
}

class _LogbookDemoState extends State<LogbookDemo> {
  var _itens = eventosDemo(dias: 2);
  var _carregando = false;
  var _pagina = 1;
  String? _erro;

  Future<void> _mais() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _carregando = false;
      if (widget.falha && _pagina == 1) {
        _erro = 'Não deu para carregar mais. Confira a conexão.';
        return;
      }
      _pagina++;
      final todos = eventosDemo(dias: 4);
      _itens = todos.take(_itens.length + 4).toList();
    });
  }

  @override
  Widget build(BuildContext context) => SsLogbook(
    entries: _itens,
    now: agoraDemo,
    locale: _pt,
    hasMore: _pagina < 3,
    loadingMore: _carregando,
    error: _erro,
    onLoadMore: _mais,
    onRetry: _mais,
  );
}

class _Pedido {
  const _Pedido(this.nome, this.consumo, this.horas);
  final String nome;
  final double consumo;
  final int horas;
}

const _pedidos = [
  _Pedido('Ar-condicionado do quarto', 412.5, 96),
  _Pedido('Geladeira', 38.2, 720),
  _Pedido('Chuveiro', 96.8, 22),
  _Pedido('Máquina de lavar', 21.4, 14),
];

/// Tabela de consumo que ordena de verdade (toque no cabeçalho ou na ficha).
class TabelaDemo extends StatefulWidget {
  const TabelaDemo({super.key, this.coluna, this.asc = true});

  final int? coluna;
  final bool asc;

  @override
  State<TabelaDemo> createState() => _TabelaDemoState();
}

class _TabelaDemoState extends State<TabelaDemo> {
  late int? _col = widget.coluna;
  late bool _asc = widget.asc;

  void _ordena(int c, bool asc) => setState(() {
    _col = c;
    _asc = asc;
  });

  @override
  Widget build(BuildContext context) {
    final fmt = SsTimeFormat(_pt);
    final linhas = [..._pedidos];
    if (_col != null) {
      int cmp(_Pedido a, _Pedido b) => switch (_col) {
        0 => a.nome.compareTo(b.nome),
        1 => a.consumo.compareTo(b.consumo),
        _ => a.horas.compareTo(b.horas),
      };
      linhas.sort((a, b) => _asc ? cmp(a, b) : cmp(b, a));
    }
    return SsDataTable(
      label: 'Consumo por aparelho',
      sortColumn: _col,
      sortAscending: _asc,
      columns: [
        SsDataColumn('Aparelho', flex: 3, onSort: (asc) => _ordena(0, asc)),
        SsDataColumn('Consumo', numeric: true, flex: 2, onSort: (asc) => _ordena(1, asc)),
        SsDataColumn('Horas', numeric: true, flex: 2, onSort: (asc) => _ordena(2, asc)),
      ],
      rows: [
        for (final p in linhas)
          SsDataRow.text([p.nome, fmt.value(p.consumo, unit: 'kWh', decimals: 1), '${p.horas} h'], onTap: () {}),
      ],
    );
  }
}

final catalogoV10Dados = <Componente>[
  Componente(
    'ss-time-chart',
    'SsTimeChart',
    'Gráfico de séries no tempo (histórico de sensores): instantes reais e desiguais, eixo do tempo que escolhe as '
        'marcas pelo intervalo, um eixo Y por unidade (até duas), linha, área ou degrau, legenda que liga e desliga, '
        'cursor com balão e faixas de estado alinhadas embaixo. Mesmo nome e comportamento no Rails '
        '(Ss::TimeSeriesChartComponent).',
    comportamentos: [
      'Arrastar (ou tocar) mostra a linha do cursor, um ponto em cada série e o balão com o horário e o valor de cada série (e o estado de cada faixa); soltou, some. Tique de haptic ao começar.',
      'Valor no cursor: no degrau, a última leitura até ali; na linha, a reta entre as leituras vizinhas; buraco (v nulo) quebra a linha.',
      'Eixo do tempo inteligente: horas num dia (a meia-noite vira a data, em negrito), dias da semana numa semana, dia/mês num mês, meses num ano; uma marca a cada ~72 px.',
      'Duas unidades (°C e %) ganham um eixo de cada lado; mais de duas dividem um eixo só. Escala Y "redonda" (1, 2, 2,5, 5 × 10ⁿ).',
      'Legenda: tocar liga e desliga a série (o eixo Y se ajusta); a série desligada fica riscada.',
      'Toque duplo aproxima 2× no ponto (mínimo 5 min); "Ver tudo" volta. onZoom avisa o app para buscar leituras mais finas.',
      'Série agregada (min/max) desenha a faixa clara atrás da linha.',
      'Desenha-se da esquerda para a direita quando entra na tela (SsTweenInView); com menos movimento, aparece pronto.',
      'Números e datas no idioma do Localizations (pt, en, es) ou de locale:.',
      'Leitor de tela: resumo com o período e o mínimo, máximo e último de cada série; legenda com botões alternáveis.',
      'showValues: a legenda mostra o valor de cada série (o do cursor enquanto arrasta, senão a última leitura); legendAlways: legenda mesmo com uma série.',
      'utcOffset: horas e datas (eixo, balão, resumo) no fuso fixo do site, não no do aparelho (o time_zone: do Rails).',
    ],
    estados: [
      Estado(
        'carregando',
        'loading: esqueleto na altura final',
        (_) => _pad(const SsTimeChart(series: [], loading: true, locale: _pt)),
        tamanho: const Size(360, 280),
      ),
      Estado(
        'vazio',
        'sem leituras no período',
        (_) => _pad(
          const SsTimeChart(
            series: [SsTimeSeries(name: 'Sala', points: [])],
            locale: _pt,
          ),
        ),
        tamanho: const Size(360, 240),
      ),
      Estado(
        'uma-serie',
        'uma série em área, 48 h',
        (_) => _pad(
          SsTimeChart(
            title: 'Temperatura da sala',
            mode: SsTimeChartMode.area,
            locale: _pt,
            series: [seriesClima().first],
          ),
        ),
        tamanho: const Size(360, 260),
        aguarde: 1200,
      ),
      Estado(
        'muitas-series',
        'três séries, °C à esquerda e % à direita',
        (_) => _pad(SsTimeChart(title: 'Clima', locale: _pt, series: seriesClima())),
        tamanho: const Size(400, 320),
        aguarde: 1200,
      ),
      Estado(
        'degrau-e-faixas',
        'degrau (nível) com faixas de estado embaixo',
        (_) => _pad(
          SsTimeChart(
            title: 'Caixa d’água',
            locale: _pt,
            mode: SsTimeChartMode.step,
            from: agoraDemo.subtract(const Duration(hours: 24)),
            to: agoraDemo,
            series: [
              SsTimeSeries(
                name: 'Nível',
                unit: '%',
                points: [
                  for (var i = 0; i <= 24; i += 3)
                    SsTimePoint(
                      agoraDemo.subtract(Duration(hours: 24 - i, minutes: i * 7 % 50)),
                      [80, 80, 65, 40, 40, 100, 90, 75, 70][i ~/ 3].toDouble(),
                    ),
                ],
              ),
            ],
            bands: faixasDemo().take(2).toList(),
          ),
        ),
        tamanho: const Size(400, 360),
        aguarde: 1200,
      ),
      Estado(
        'cursor',
        'arrastando: cursor e balão',
        (_) => _pad(
          SsTimeChart(locale: _pt, series: seriesClima(), initialCursor: agoraDemo.subtract(const Duration(hours: 20))),
        ),
        tamanho: const Size(400, 320),
        aguarde: 1200,
      ),
      Estado(
        'aproximado',
        'aproximado (toque duplo), com "Ver tudo"',
        (_) => _pad(
          SsTimeChart(
            locale: _pt,
            mode: SsTimeChartMode.area,
            series: [seriesClima().first],
            initialZoom: (agoraDemo.subtract(const Duration(hours: 6)), agoraDemo),
          ),
        ),
        tamanho: const Size(360, 260),
        aguarde: 1200,
      ),
      Estado(
        'ingles',
        'locale: en (3:00 PM, 1,234.5)',
        (_) => _pad(
          SsTimeChart(
            locale: const Locale('en'),
            series: [seriesClima()[2]],
            initialCursor: agoraDemo.subtract(const Duration(hours: 30)),
          ),
        ),
        tamanho: const Size(360, 260),
        aguarde: 1200,
      ),
      Estado(
        'valores-na-legenda',
        'showValues + legendAlways: série única com o valor atual na legenda',
        (_) => _pad(
          SsTimeChart(
            series: [seriesClima().first],
            to: agoraDemo,
            locale: _pt,
            height: 150,
            showValues: true,
            legendAlways: true,
          ),
        ),
        tamanho: const Size(360, 260),
        aguarde: 1200,
      ),
      Estado(
        'valores-no-cursor',
        'showValues: a legenda acompanha o cursor; fuso fixo (utcOffset −3 h)',
        (_) => _pad(
          SsTimeChart(
            series: seriesClima().take(2).toList(),
            to: agoraDemo,
            locale: _pt,
            height: 150,
            showValues: true,
            utcOffset: const Duration(hours: -3),
            initialCursor: agoraDemo.subtract(const Duration(hours: 6)),
          ),
        ),
        tamanho: const Size(360, 280),
        aguarde: 1200,
      ),
    ],
  ),
  Componente(
    'ss-state-bands',
    'SsStateBands',
    'Faixas de estado no tempo: uma linha por item (liga/desliga, aberto/fechado, os estados de um aspirador) com '
        'trechos coloridos pelo estado sobre o mesmo intervalo e o eixo do tempo embaixo. No Rails: Ss::StateBandsComponent.',
    comportamentos: [
      'Cor por estado: o mapa tones: do app; senão ligado/aberto na marca, desligado/fechado no neutro, erro no perigo e o resto na paleta de séries.',
      'Tocar (ou passar o mouse) num trecho mostra o balão com o estado, o horário e a duração; tocar de novo fecha.',
      'labelOnTop: o nome vai em cima e a faixa ocupa a largura toda, alinhada ao SsTimeChart (que também aceita bands:).',
      'As faixas entram da esquerda para a direita, em cascata por linha, quando aparecem na tela.',
      'Nome longo corta com reticências; trecho curto tem pelo menos 1 px.',
      'Leitor de tela: cada linha diz o tempo em cada estado e o estado de agora.',
      'utcOffset: o eixo e o balão no fuso fixo do site (o time_zone: do Rails).',
    ],
    estados: [
      Estado(
        'vazio',
        'sem mudanças',
        (_) => _pad(const SsStateBands(rows: [], locale: _pt)),
        tamanho: const Size(360, 100),
      ),
      Estado(
        'uma-linha',
        'uma linha',
        (_) => _pad(SsStateBands(rows: faixasDemo().take(1).toList(), locale: _pt)),
        tamanho: const Size(360, 110),
        aguarde: 1000,
      ),
      Estado(
        'muitas-linhas',
        'luz, porta e aspirador (tons do app)',
        (_) => _pad(SsStateBands(rows: faixasDemo(), tones: _tonsAspirador, locale: _pt)),
        tamanho: const Size(400, 150),
        aguarde: 1000,
      ),
      Estado(
        'nome-longo',
        'nome longo (corta com reticências)',
        (_) => _pad(
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: SsStateBands(rows: faixasDemo(longo: true).take(1).toList(), locale: _pt),
          ),
        ),
        tamanho: const Size(360, 160),
        aguarde: 1000,
      ),
      Estado(
        'nome-em-cima',
        'labelOnTop (alinhado ao gráfico)',
        (_) => _pad(SsStateBands(rows: faixasDemo(), tones: _tonsAspirador, labelOnTop: true, locale: _pt)),
        tamanho: const Size(360, 210),
        aguarde: 1000,
      ),
      Estado(
        'fuso-do-site',
        'utcOffset: eixo e balão no fuso do site (UTC−3), não no do aparelho',
        (_) => _pad(SsStateBands(rows: faixasDemo(), utcOffset: const Duration(hours: -3), locale: _pt)),
        tamanho: const Size(360, 260),
        aguarde: 900,
      ),
    ],
  ),
  Componente(
    'ss-logbook',
    'SsLogbook',
    'Logbook (diário de eventos): eventos agrupados por dia sob um cabeçalho que gruda no topo ("Hoje", "Ontem", '
        'depois a data), cada um com hora, ícone tonal, título, estado e detalhe, e o "carregar mais" no fim. '
        'No Rails: Ss::LogbookComponent.',
    comportamentos: [
      'Cabeçalho do dia gruda no topo enquanto o dia rola (SliverMainAxisGroup).',
      'Perto do fim, com hasMore, chama onLoadMore sozinho (uma vez por página); o botão "Carregar mais" também chama.',
      'loadingMore: rodapé com indicador; sem hasMore: "Início do registro".',
      'error: sem eventos, a tela de erro com "Tentar de novo"; com eventos, o erro vai no rodapé.',
      'loading: linhas-fantasma; vazio: SsEmptyState compacto.',
      'As linhas sobem em cascata quando aparecem; com menos movimento, aparecem prontas.',
      'Hora e data no idioma do Localizations (ou locale:).',
      'SsLogbook.sliver: a mesma peça como sliver (num CustomScrollView ou nos slivers do SsScreenHeader); o "carregar mais" escuta a rolagem de fora.',
      'É SsSelfScrolling: dentro do SsPullToRefresh vai direto (antes era embrulhado num SingleChildScrollView e estourava).',
      'endAction: link ou botão no fim do registro ("Ver um período maior"); showEnd: false tira a marca "Início do registro".',
      'utcOffset: hora e agrupamento por dia no fuso fixo do site.',
    ],
    estados: [
      Estado(
        'carregando',
        'loading: linhas-fantasma',
        (_) => const SsLogbook(entries: [], loading: true, locale: _pt),
        tamanho: const Size(360, 340),
      ),
      Estado(
        'vazio',
        'sem eventos',
        (_) => SsLogbook(entries: const [], now: agoraDemo, locale: _pt),
        tamanho: const Size(360, 300),
      ),
      Estado(
        'tres-dias',
        'hoje, ontem e a data, com "Carregar mais"',
        (_) => SsLogbook(entries: eventosDemo(porDia: 3), now: agoraDemo, locale: _pt, hasMore: true, autoLoad: false),
        tamanho: const Size(360, 720),
        aguarde: 1200,
      ),
      Estado(
        'carregando-mais',
        'loadingMore no rodapé',
        (_) => SsLogbook(
          entries: eventosDemo(dias: 1, porDia: 3),
          now: agoraDemo,
          locale: _pt,
          hasMore: true,
          loadingMore: true,
        ),
        tamanho: const Size(360, 340),
        aguarde: 1200,
      ),
      Estado(
        'fim',
        'fim da lista',
        (_) => SsLogbook(entries: eventosDemo(dias: 1, porDia: 2), now: agoraDemo, locale: _pt),
        tamanho: const Size(360, 260),
        aguarde: 1200,
      ),
      Estado(
        'erro',
        'erro na 1ª carga',
        (_) => SsLogbook(entries: const [], error: 'Não deu para abrir o registro.', onRetry: () {}, locale: _pt),
        tamanho: const Size(360, 300),
      ),
      Estado(
        'erro-rodape',
        'erro ao carregar a página seguinte',
        (_) => SsLogbook(
          entries: eventosDemo(dias: 1, porDia: 2),
          now: agoraDemo,
          locale: _pt,
          hasMore: true,
          error: 'Não deu para carregar mais.',
          onRetry: () {},
        ),
        tamanho: const Size(360, 320),
        aguarde: 1200,
      ),
      Estado(
        'interativo',
        'carrega a página 2 de verdade (600 ms)',
        (_) => const LogbookDemo(),
        tamanho: const Size(360, 640),
        aguarde: 1200,
      ),
      Estado(
        'fim-com-acao',
        'endAction: link no fim do registro',
        (_) => SsLogbook(
          entries: eventosDemo(dias: 1, porDia: 2),
          now: agoraDemo,
          locale: _pt,
          endAction: SsButton.text(label: 'Ver um período maior', icon: Icons.history_rounded, onPressed: () {}),
        ),
        tamanho: const Size(360, 300),
        aguarde: 1200,
      ),
      Estado(
        'sem-marca-fim',
        'showEnd: false (sem "Início do registro")',
        (_) => SsLogbook(entries: eventosDemo(dias: 1, porDia: 2), now: agoraDemo, locale: _pt, showEnd: false),
        tamanho: const Size(360, 240),
        aguarde: 1200,
      ),
      Estado(
        'sliver-no-cabecalho',
        'SsLogbook.sliver nos slivers do SsScreenHeader (dias grudam abaixo do cabeçalho)',
        (_) => SsScreenHeader(
          title: 'Histórico',
          subtitle: 'Sala de estar',
          slivers: [
            SsLogbook.sliver(
              entries: eventosDemo(dias: 2, porDia: 3),
              now: agoraDemo,
              locale: _pt,
              hasMore: true,
              autoLoad: false,
            ),
          ],
        ),
        tamanho: const Size(360, 640),
        aguarde: 1200,
      ),
      Estado(
        'puxar-para-atualizar',
        'dentro do SsPullToRefresh (vai direto, sem SingleChildScrollView)',
        (_) => SsPullToRefresh(
          onRefresh: () async {},
          child: SsLogbook(entries: eventosDemo(dias: 1, porDia: 3), now: agoraDemo, locale: _pt),
        ),
        tamanho: const Size(360, 360),
        aguarde: 1200,
      ),
    ],
  ),
  Componente(
    'ss-data-table',
    'SsDataTable',
    'Tabela de dados: colunas com ordenação opcional e números à direita em DM Mono. No celular as linhas viram cartões '
        'empilhados (rótulo à esquerda, valor à direita), como o modo empilhado do Ss::DataTableComponent.',
    comportamentos: [
      'Cabeçalho ordenável (onSort) mostra a seta; tocar alterna o sentido; a seta gira com a mola.',
      'Abaixo de stackBelow (600) vira cartões: a titleColumn é o título; a ordenação passa para fichas "Ordenar por".',
      'loading: linhas-fantasma (ou cartões-fantasma no celular); vazio: SsEmptyState compacto.',
      'Linhas com onTap são tocáveis (ripple); entram em cascata quando aparecem.',
      'Leitor de tela: cabeçalhos com o sentido ("Consumo, decrescente"); células com o nome da coluna.',
    ],
    estados: [
      Estado(
        'larga',
        'tabela (ordenável, sem ordem)',
        (_) => _pad(const TabelaDemo()),
        tamanho: const Size(640, 300),
        aguarde: 900,
      ),
      Estado(
        'ordenada',
        'ordenada por consumo, decrescente',
        (_) => _pad(const TabelaDemo(coluna: 1, asc: false)),
        tamanho: const Size(640, 300),
        aguarde: 900,
      ),
      Estado(
        'celular',
        'celular: cartões e fichas de ordenar',
        (_) => _pad(const TabelaDemo(coluna: 1, asc: false)),
        tamanho: const Size(360, 640),
        aguarde: 900,
      ),
      Estado(
        'vazia',
        'sem linhas',
        (_) => _pad(
          const SsDataTable(columns: [SsDataColumn('Aparelho'), SsDataColumn('Consumo', numeric: true)], rows: []),
        ),
        tamanho: const Size(360, 260),
      ),
      Estado(
        'carregando',
        'loading',
        (_) => _pad(
          const SsDataTable(
            loading: true,
            columns: [
              SsDataColumn('Aparelho', flex: 3),
              SsDataColumn('Consumo', numeric: true),
              SsDataColumn('Horas', numeric: true),
            ],
            rows: [],
          ),
        ),
        tamanho: const Size(640, 260),
      ),
    ],
  ),
];
