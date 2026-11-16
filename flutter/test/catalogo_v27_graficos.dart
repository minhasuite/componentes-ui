// v0.27 (meulog): o que mudou no SsLineChart e no SsBarChart ([comV27Graficos]):
// linha reta, série tracejada, marcas verticais, barras deitadas, cor por valor e o vazio.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'catalogo.dart';

const _dias = ['01/11', '02/11', '03/11', '04/11', '05/11', '06/11', '07/11'];
const _marcas = [
  SsChartMarker(at: '03/11', label: 'v2.3.1'),
  SsChartMarker(at: '05/11', label: 'API fora', kind: SsChartMarkerKind.incident),
  SsChartMarker(at: '05/11', label: 'v2.3.2'),
];

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

final Map<String, (List<String>, List<Estado>)> _v27 = {
  'ss-line-chart': (
    [
      'v0.27: curved: false liga os pontos em reta (série diária: a curva inventa valor entre dois dias).',
      'v0.27: SsSeries(dashed: true) sai tracejada e fina (o período anterior, a referência).',
      'v0.27: markers: SsChartMarker(at:, label:, kind:) desenha um traço tracejado no rótulo e o nome no alto: '
          'deploy na cor de informação, incidente na de perigo, nota na apagada; duas no mesmo rótulo empilham.',
      'v0.27: empty: mostra o texto numa caixa tracejada quando não há ponto.',
    ],
    [
      Estado(
        'reta-marcas',
        'reta, anterior tracejada e marcas (v0.27)',
        (_) => _pad(
          const SsLineChart(
            curved: false,
            labels: _dias,
            markers: _marcas,
            series: [
              SsSeries([12, 19, 8, 24, 17, 22, 30], name: 'Agora'),
              SsSeries([10, 11, 9, 14, 12, 15, 18], name: 'Anterior', dashed: true),
            ],
          ),
        ),
        tamanho: const Size(380, 240),
      ),
      Estado(
        'vazio',
        'sem dados (v0.27)',
        (_) => _pad(const SsLineChart(labels: [], series: [], empty: 'Sem dados no período', height: 120)),
        tamanho: const Size(380, 160),
      ),
    ],
  ),
  'ss-bar-chart': (
    [
      'v0.27: horizontal: true deita as barras (rótulo à esquerda com reticências e o nome inteiro na dica).',
      'v0.27: SsSeries(colors:) dá cor por valor (a categoria "Outros" apagada).',
      'v0.27: markers: e empty: como no SsLineChart (as marcas não valem no deitado).',
    ],
    [
      Estado(
        'deitado',
        'barras deitadas com Outros apagado (v0.27)',
        (context) => _pad(
          SsBarChart(
            horizontal: true,
            labels: const ['ActiveRecord::RecordNotFound', 'Net::ReadTimeout em Pagamentos', 'NoMethodError', 'Outros'],
            series: [
              SsSeries(
                const [120, 64, 48, 30],
                name: 'Ocorrências',
                colors: [null, null, null, SsColors.of(context).muted],
              ),
            ],
          ),
        ),
        tamanho: const Size(380, 170),
      ),
      Estado(
        'marcas',
        'colunas com marcas (v0.27)',
        (_) => _pad(
          const SsBarChart(
            labels: _dias,
            markers: _marcas,
            series: [
              SsSeries([12, 19, 8, 24, 17, 22, 30], name: 'Agora'),
            ],
          ),
        ),
        tamanho: const Size(380, 260),
      ),
    ],
  ),
};

List<Componente> comV27Graficos(List<Componente> base) => [
  for (final c in base)
    if (_v27[c.slug] case (final comp, final est))
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
