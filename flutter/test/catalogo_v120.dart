// v1.2 (minhas-vendas, auditoria de UX V02 e U03) ([comV120]): a linha compacta do SsRepeater no
// celular (mobile: compact + SsRepeaterCell) e os rótulos do eixo X do SsBarChart que não colam.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'catalogo.dart';

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

Widget _campo(String rotulo, String valor) => Builder(
  builder: (context) => SsTextField(label: rotulo, hideLabel: !SsRepeater.compactOf(context), initialValue: valor),
);

Widget _pedido({bool aberto = false}) => SsRepeater(
  mobile: SsRepeaterMobile.compact,
  itemCount: 2,
  minItems: 1,
  header: const ['Produto', 'Descrição', 'Qtd', 'Unitário', 'Desc.', 'Total'],
  flex: const [4, 2, 1, 2, 1, 2],
  onAdd: () {},
  onRemove: (_) {},
  itemBuilder: (_, i) => SsRepeater.cells(
    [
      SsRepeaterCell(_campo('Produto', i == 0 ? 'Arroz 5 kg' : 'Feijão 1 kg')),
      SsRepeaterCell(_campo('Descrição', ''), role: SsRepeaterRole.detail),
      SsRepeaterCell(_campo('Qtd', '${i + 2}'), role: SsRepeaterRole.inline),
      SsRepeaterCell(_campo('Unitário', i == 0 ? '25,90' : '8,90'), role: SsRepeaterRole.inline),
      SsRepeaterCell(_campo('Desc.', ''), role: SsRepeaterRole.detail),
      SsRepeaterCell(Text(i == 0 ? 'R\$ 51,80' : 'R\$ 26,70', textAlign: TextAlign.end), role: SsRepeaterRole.inline),
    ],
    flex: const [4, 2, 1, 2, 1, 2],
    detailsOpen: aberto && i == 0,
  ),
);

const _meses = ['DEZ', 'JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV'];

final Map<String, (List<String>, List<Estado>)> _v120 = {
  'ss-repeater': (
    [
      'v1.2: mobile: SsRepeaterMobile.compact troca, abaixo de compactBelow (768), as colunas apertadas por uma linha compacta: '
          'SsRepeaterCell(role: primary) na largura inteira, inline lado a lado numa linha, detail recolhida atrás do "Detalhes" '
          '(texto repeaterDetails, pt/en/es). Sem SsRepeaterCell a célula é primary.',
      'v1.2: compacto, o cabeçalho some e os rótulos voltam (hideLabel: !SsRepeater.compactOf(context)); as células recolhidas '
          'continuam montadas (o texto e o validador do Form não se perdem); detailsOpen: true abre (campo com erro).',
    ],
    [
      Estado('compacto', 'pedido no celular (v1.2)', (_) => _pad(_pedido()), tamanho: const Size(360, 540)),
      Estado(
        'compacto-aberto',
        'detalhes da 1ª linha abertos (v1.2)',
        (_) => _pad(_pedido(aberto: true)),
        tamanho: const Size(360, 720),
      ),
    ],
  ),
  'ss-bar-chart': (
    [
      'v1.2: os rótulos do eixo X saem de N em N pela largura do maior rótulo (ssAxisLabelStep), a partir do ativo: o vizinho do '
          'mês atual não cola nele.',
    ],
    [
      Estado(
        'doze-meses',
        'doze meses no celular, o atual em destaque (v1.2)',
        (_) => _pad(
          SsBarChart(
            labels: _meses,
            series: [
              SsSeries([for (var i = 0; i < 12; i++) 18000.0 + i * 900 - (i % 3) * 2500], name: 'Faturamento'),
            ],
            active: 11,
            legend: false,
            height: 180,
          ),
        ),
        tamanho: const Size(320, 230),
      ),
    ],
  ),
};

List<Componente> comV120(List<Componente> base) => [
  for (final c in base)
    if (_v120[c.slug] case (final comp, final est))
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
