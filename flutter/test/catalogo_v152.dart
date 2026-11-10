// Estados e comportamentos da v0.15.2 (o que a migração do minhas-compras e do
// minhas-viagens pediu), somados às entradas que já existem no catálogo, pelo slug.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';

import 'catalogo.dart';

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

/// Soma os extras da v0.15.2 às entradas de [base] com o mesmo slug.
List<Componente> comV152(List<Componente> base) => [
  for (final c in base)
    if (_v152[c.slug] case (final comp, final est))
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

final Map<String, (List<String>, List<Estado>)> _v152 = {
  'ss-badge': (
    ['Rótulo longo sem largura (Wrap, coluna estreita) termina em "…" em vez de estourar; o leitor de tela lê tudo.'],
    [
      Estado(
        'longo',
        'rótulo longo em 180 px',
        (_) => _pad(
          const SizedBox(
            width: 180,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                SsBadge('vence em 2 semanas · aberto · estimada', variant: SsBadgeVariant.warning, micro: true),
                SsBadge('Ligada há 3 horas na sala de estar', variant: SsBadgeVariant.success, dot: true),
                SsBadge('Mais barato no Atacadão Centro', icon: Icons.local_offer_outlined),
              ],
            ),
          ),
        ),
        tamanho: const Size(240, 130),
      ),
    ],
  ),
  'ss-run-blocking': (
    [
      'art: no lugar do spinner (ilustração do produto).',
      'showElapsedAfter: depois desse tempo, "12 s · ainda trabalhando, não feche o app" (separa demorando de travado).',
      'cancelAfter: o Cancelar só aparece depois desse tempo; sem onCancel, fecha e o Future termina com SsBlockingCancelled.',
    ],
    [
      Estado(
        'longa',
        'arte, tempo decorrido e Cancelar (16 s)',
        (context) => SsBlockingIndicator(
          label: 'Lendo o cupom…',
          art: Icon(Icons.receipt_long_rounded, size: 36, color: SsColors.of(context).accent),
          showElapsedAfter: const Duration(seconds: 8),
          cancelAfter: const Duration(seconds: 15),
          elapsed: const Duration(seconds: 16),
          onCancel: () {},
        ),
        tamanho: const Size(360, 170),
      ),
    ],
  ),
};
