// v0.28 (meulog, segunda rodada) ([comV28]): o max: dos gráficos, o subtítulo inteiro do SsListItem,
// o nome do QR no SsQrCard e a peça nova SsDayStrip (faixa de status por dia).
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';

import 'catalogo.dart';

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

const _dias = [
  SsDay('10/11', SsDayTone.ok, text: '100% no ar'),
  SsDay('11/11', SsDayTone.ok, text: '100% no ar'),
  SsDay('12/11', SsDayTone.warn, text: '2 falhas em 288'),
  SsDay('13/11', SsDayTone.ok, text: '100% no ar'),
  SsDay('14/11', SsDayTone.bad, text: 'fora 3 h'),
  SsDay('15/11', SsDayTone.ok, text: '100% no ar'),
  SsDay('16/11', SsDayTone.none),
];

final Map<String, (List<String>, List<Estado>)> _v28 = {
  'ss-bar-chart': (
    ['v0.28: max: fixa o topo da escala (pequenos múltiplos lado a lado na mesma escala); valor acima alarga.'],
    [
      Estado(
        'max',
        'dois gráficos na mesma escala (max: 40) (v0.28)',
        (_) => _pad(
          const Row(
            children: [
              Expanded(
                child: SsBarChart(
                  labels: ['a', 'b', 'c'],
                  series: [
                    SsSeries([30, 12, 40]),
                  ],
                  max: 40,
                  height: 120,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: SsBarChart(
                  labels: ['a', 'b', 'c'],
                  series: [
                    SsSeries([4, 6, 3]),
                  ],
                  max: 40,
                  height: 120,
                ),
              ),
            ],
          ),
        ),
        tamanho: const Size(380, 170),
      ),
    ],
  ),
  'ss-list-item': (
    ['v0.28: subtitleMaxLines: mostra o subtítulo inteiro (par do subtitle_wrap: do web).'],
    [
      Estado(
        'subtitulo-inteiro',
        'subtítulo em até 3 linhas (v0.28)',
        (_) => const SsListItem(
          title: 'Erros e regressões',
          subtitle: 'O que o meulog agrupa, como prioriza e quando avisa quem está de plantão, com exemplos.',
          subtitleMaxLines: 3,
        ),
        tamanho: const Size(360, 110),
      ),
    ],
  ),
  'ss-qr-card': (
    ['v0.28: qrLabel: o nome do QR para o leitor de tela (ex. "QR do autenticador" no segundo fator).'],
    const [],
  ),
};

final _dayStrip = Componente(
  'ss-day-strip',
  'SsDayStrip',
  'Faixa de status por dia (v0.28, par do Ss::DayStripComponent): um traço por dia, com respiro entre eles, '
      'como numa página de status.',
  comportamentos: const [
    'Tom por dia: ok (verde), warn (âmbar), bad (vermelho), none (vazado: sem dado não é "no ar").',
    'Toque longo ou mouse mostra a data, a situação e o texto do dia (SsTooltip).',
    'Leitor de tela: o título e o resumo (quantos dias, fora, instáveis).',
    'startLabel/endLabel nas pontas (padrão: o primeiro e o último dia).',
  ],
  estados: [
    Estado(
      'padrao',
      'sete dias com uma queda e um dia instável',
      (_) => _pad(const SsDayStrip(title: 'Disponibilidade', days: _dias, startLabel: 'há 7 dias', endLabel: 'hoje')),
      tamanho: const Size(360, 110),
    ),
    Estado(
      'titulo',
      'com o título à vista',
      (_) => _pad(const SsDayStrip(title: 'Rotina noturna, 7 dias', days: _dias, showTitle: true, height: 24)),
      tamanho: const Size(360, 120),
    ),
  ],
);

List<Componente> comV28(List<Componente> base) => [
  for (final c in base)
    if (_v28[c.slug] case (final comp, final est))
      Componente(
        c.slug,
        c.nome,
        c.descricao,
        comportamentos: [...c.comportamentos, ...comp],
        estados: [...c.estados, ...est],
      )
    else
      c,
  _dayStrip,
];
