// Estados e comportamentos da v0.19 (o que o meu-financeiro-app ainda tinha de
// genérico): peça nova em [catalogoV19] e os extras das que já existiam (por
// slug) em [comV19].
import 'dart:convert';

import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';

import 'catalogo.dart';

/// "Comprovante" de 16×10 para o catálogo (sem rede nem asset).
final _foto = MemoryImage(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAABAAAAAKCAIAAAAy3EnLAAAA+0lEQVR4nIXOoWrFQBCF4X25FSNWRERkYcSIEQMRERELERERgVBW7FP+L3BNVSlU3UILv/04J9WMZizjmcismS2zZ1rmyJyZK3NnnkzPjEyqggomuBDCKmzCLjThEE7hEm7hEbowhFQLWrCCF6KwFrbCXmiFo3AWrsJdeAq9MAqpTuiETbxen3/0TPSJMZHqjM7Y/A1a+/jdD5jpM2Mm1QVdsOUdvC8s9IWxkKqiiul/l5SuDCVVQw0z3AhjNTZjN5pxGKdxGbfxGN0YRqqOOua4E87qbM7uNOdwTudybudxujOcVAMNLPAggjXYgj1owRGcwRXcwRP0YARftxMw8HkkFq4AAAAASUVORK5CYII=',
  ),
);

final catalogoV19 = <Componente>[
  Componente(
    'ss-image-viewer',
    'showSsImageViewer / SsImageViewer',
    'Imagem em tela cheia com zoom (comprovante, foto do cupom, anexo), sobre fundo escuro.',
    comportamentos: [
      'Abre por cima de tudo (rota própria, com fade); o × e o voltar do sistema fecham.',
      'Pinça amplia até maxScale (padrão 4×) e arrastar move a imagem ampliada.',
      'Toque duplo amplia 2,5× no ponto tocado e, ampliada, volta à imagem inteira; reduzir movimento troca sem animar.',
      'Barra escura (SsTopBar dark) com o título (nome do arquivo) e actions à direita (compartilhar, baixar).',
      'Leitor de tela: imagem com o nome (semanticLabel, título ou "Imagem") e a dica de zoom; imagem que não carrega vira o ícone de imagem quebrada.',
    ],
    estados: [
      Estado(
        'padrao',
        'com título e ação',
        (_) => SsImageViewer(
          image: _foto,
          title: 'cupom-mercado.jpg',
          actions: [
            SsIconButton(icon: Icons.ios_share, tooltip: 'Compartilhar', color: AppColors.onDark, onPressed: () {}),
          ],
        ),
        tamanho: const Size(360, 420),
      ),
    ],
  ),
];

/// Soma os extras da v0.19 às entradas de [base] com o mesmo slug.
List<Componente> comV19(List<Componente> base) => [
  for (final c in base)
    if (_v19[c.slug] case (final comp, final est))
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

final Map<String, (List<String>, List<Estado>)> _v19 = {
  'ss-collapsible': (
    [
      'v0.19: subtitle é a linha apagada embaixo do título, à vista também fechado (o que tem dentro); no lugar do ExpansionTile(subtitle:).',
      'O corpo continua montado fechado: campos de formulário guardam o estado e validam.',
    ],
    [
      Estado(
        'subtitulo',
        'fechado com subtítulo (mais opções do formulário)',
        (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: SsCollapsible(
            title: 'Mais opções',
            subtitle: 'Pessoa, centro de custo, tags, dividir, forma de pagamento, repetição',
            child: const SsTextField(label: 'Observação'),
          ),
        ),
        tamanho: const Size(360, 110),
      ),
    ],
  ),
};
