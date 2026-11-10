// Entradas do catálogo da v0.14: o que sobrou de genérico no minha-automacao
// (nota no lugar do conteúdo, tarefa com comando e foto no ícone tonal).
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo.dart';

void _nada() {}

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

final catalogoV14 = <Componente>[
  Componente(
    'ss-note',
    'SsNote',
    'Nota: a frase curta e apagada no lugar do conteúdo de um card (nada agora, escolha a fonte, sem leituras), com ícone. Par do Ss::NoteComponent (.ss-note).',
    comportamentos: [
      'O tom pinta o ícone; warning e danger pintam a frase também e viram região viva (leitor de tela).',
      'Texto longo quebra linha; o ícone fica alinhado com a 1ª linha.',
    ],
    estados: [
      Estado(
        'tons',
        'neutra · sucesso · perigo · sem ícone',
        (_) => _pad(
          const SsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                SsCardHeader(title: 'Alertas'),
                SsNote('Nenhum alerta aberto', icon: Icons.check_circle_outline, tone: SsTone.success),
                SsNote('Escolha o medidor de energia nas opções do card.', icon: Icons.bolt_outlined),
                SsNote('O robô parou: escova presa.', icon: Icons.error_outline, tone: SsTone.danger),
                SsNote('Sem ícone, só a frase.'),
              ],
            ),
          ),
        ),
        tamanho: const Size(390, 260),
      ),
    ],
  ),
  Componente(
    'ss-task-item',
    'SsTaskItem',
    'Tarefa com comando: a linha inteira marca/desmarca, marcada fica riscada, e o × no fim remove. Par da .ss-checklist com button[role=checkbox] e .ss-checklist-x.',
    comportamentos: [
      'onChanged nulo = só leitura (sem toque, sem ×).',
      'O × tem a dica "Excluir: <tarefa>" (deleteTooltip troca) e alvo de toque de 48.',
    ],
    estados: [
      Estado(
        'lista',
        'pendentes · marcada · só leitura',
        (_) => _pad(
          SsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SsCardHeader(title: 'Compras', subtitle: '2 pendentes'),
                SsTaskItem('Comprar pão', onChanged: (_) {}, onDelete: _nada),
                SsTaskItem('Trocar o filtro do ar', onChanged: (_) {}, onDelete: _nada),
                SsTaskItem('Regar as plantas', done: true, onChanged: (_) {}, onDelete: _nada),
                const SsTaskItem('Sem permissão de marcar'),
              ],
            ),
          ),
        ),
        tamanho: const Size(390, 300),
      ),
    ],
  ),
  Componente(
    'ss-icon-tile-image',
    'SsIconTile(image:)',
    'Ícone tonal com foto no lugar do ícone (planta, pessoa, aparelho). O <img> dentro do .ss-icon-tile do web.',
    comportamentos: ['A foto cobre o quadrado (ou círculo); enquanto carrega ou se falhar, fica o ícone.'],
    estados: [
      Estado(
        'foto',
        'ícone · foto que falhou (volta ao ícone) · âmbar',
        (_) => _pad(
          Row(
            spacing: 12,
            children: [
              const SsIconTile(Icons.eco_outlined, tone: AppColors.success),
              SsIconTile(Icons.eco_outlined, tone: AppColors.success, image: MemoryImage(Uint8List(0)), size: 52),
              const SsIconTile(Icons.bolt_rounded, tone: AppColors.aquecFg),
            ],
          ),
        ),
        tamanho: const Size(390, 90),
      ),
    ],
  ),
];
