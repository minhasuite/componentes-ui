// Entradas do catálogo da v0.7 pedidas pela migração do minhas-compras.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';

import 'catalogo.dart';

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

final catalogoV07Compras = <Componente>[
  Componente(
    'ss-value-tile',
    'SsValueTile',
    'Linha de lista com nome (até 2 linhas) e valor à direita que encolhe; com fonte grande o valor desce.',
    comportamentos: [
      'O valor ocupa no máximo 40% da largura e encolhe (nunca quebra o dinheiro).',
      'Fonte do sistema acima de 1,15×: o valor vai para baixo do nome.',
      'details entra embaixo do subtítulo (medidor, selo); trailing é a ação no fim.',
      'Com onTap, a linha inteira é tocável.',
    ],
    estados: [
      Estado(
        'valor',
        'nome longo e valor com nota',
        (_) => _pad(
          const SsValueTile(
            title: 'Café torrado e moído extraforte embalagem a vácuo',
            subtitle: 'Melitta · 500 g',
            value: r'R$ 18,90',
            valueNote: '12% mais barato',
          ),
        ),
        tamanho: const Size(360, 130),
      ),
      Estado(
        'acao',
        'sem valor, com botão no fim',
        (_) => _pad(
          SsValueTile(
            leading: const SsIconTile(Icons.help_outline, size: 34),
            title: 'Feijão carioca',
            subtitle: 'contei 2',
            trailing: TextButton(onPressed: () {}, child: const Text('Cadastrar')),
          ),
        ),
        tamanho: const Size(360, 120),
      ),
    ],
  ),
];
