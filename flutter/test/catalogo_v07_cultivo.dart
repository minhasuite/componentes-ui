// Entradas do catálogo da v0.7 pedidas pela migração do meu-cultivo.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';

import 'catalogo.dart';

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

final catalogoV07Cultivo = <Componente>[
  Componente(
    'ss-section-header',
    'SsSectionHeader',
    'Título de bloco numa tela de detalhe, com uma linha de explicação e uma ação à direita.',
    comportamentos: [
      'O título quebra em até 2 linhas e cede espaço: a ação nunca sai da tela em fonte grande.',
      'subtitle opcional, em muted, diz por que o bloco existe.',
      'action é qualquer widget (TextButton, IconButton, "+").',
      'O título é anunciado como cabeçalho pelo leitor de tela.',
    ],
    estados: [
      Estado(
        'simples',
        'só título e explicação',
        (_) => _pad(const SsSectionHeader('Histórico', subtitle: 'O que já foi feito nesta planta')),
      ),
      Estado(
        'com-acao',
        'com botão à direita',
        (_) => _pad(
          SsSectionHeader(
            'Diário',
            subtitle: 'O que você notou',
            action: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Anotar'),
            ),
          ),
        ),
      ),
    ],
  ),
];
