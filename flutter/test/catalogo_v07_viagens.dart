// Entradas do catálogo da v0.7 pedidas pela migração do minhas-viagens.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';

import 'catalogo.dart';

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

final catalogoV07Viagens = <Componente>[
  Componente(
    'ss-fit',
    'SsFit',
    'Valor que nunca quebra linha: encolhe para caber (dinheiro, número, data curta).',
    comportamentos: [
      'Só encolhe, nunca aumenta (BoxFit.scaleDown).',
      'alignment escolhe para que lado o texto encolhido gruda (padrão: direita).',
    ],
    estados: [
      Estado(
        'estreito',
        'valor grande numa coluna de 90 px',
        (context) =>
            _pad(SizedBox(width: 90, child: SsFit(Text('R\$ 12.345,67', style: AppTheme.number(context, size: 18))))),
      ),
    ],
  ),
  Componente(
    'ss-fit-title',
    'SsFitTitle',
    'Título de AppBar que não corta: curto encolhe numa linha, longo vai menor em até 2 linhas.',
    comportamentos: [
      'Até 22 letras: uma linha, encolhendo se preciso.',
      'Mais longo: fonte lg em até 2 linhas, com reticências.',
      'Anunciado como cabeçalho pelo leitor de tela.',
    ],
    estados: [
      Estado('curto', 'nome curto', (_) => _pad(const SsFitTitle('Lisboa 2027'))),
      Estado(
        'longo',
        'nome longo em 2 linhas',
        (_) => _pad(const SizedBox(width: 240, child: SsFitTitle('Férias de julho no Nordeste com a família toda'))),
      ),
    ],
  ),
  Componente(
    'ss-button-pair',
    'SsButtonPair',
    'Dois botões lado a lado, meio a meio; com fonte grande um embaixo do outro.',
    comportamentos: [
      'Acima de 1,15× de fonte, empilha (rótulo inteiro em vez de reticências).',
      'gap ajusta o espaço entre os dois.',
    ],
    estados: [
      Estado(
        'lado-a-lado',
        'fonte normal',
        (_) => _pad(
          SsButtonPair(
            first: SsButton(label: 'Buscar agora', onPressed: () {}),
            second: SsButton(label: 'Ajustar', variant: SsButtonVariant.ghost, onPressed: () {}),
          ),
        ),
      ),
      Estado(
        'empilhado',
        'fonte 1,3×',
        (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: _pad(
            SsButtonPair(
              first: SsButton(label: 'Buscar agora', onPressed: () {}),
              second: SsButton(label: 'Ajustar', variant: SsButtonVariant.ghost, onPressed: () {}),
            ),
          ),
        ),
        tamanho: const Size(360, 170),
      ),
    ],
  ),
];
