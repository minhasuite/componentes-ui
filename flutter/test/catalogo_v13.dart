// Entradas do catálogo da v0.13: o que os painéis do minha-automacao pediram
// (seção com ícone, cabeçalho de bloco, mosaico em colunas, coluna lateral,
// bloco de área com pílulas, card de foto e marca a partir de duas cores).
import 'package:flutter/material.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo.dart';

void _nada() {}

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

Widget _foto() => const DecoratedBox(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.inkLight, AppColors.success],
    ),
  ),
);

Widget _card(String titulo, int linhas) => SsCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SsCardHeader(title: titulo, subtitle: '$linhas linha(s)'),
      for (var i = 0; i < linhas; i++)
        const Padding(padding: EdgeInsets.only(top: 6), child: Text('Linha de conteúdo do card.')),
    ],
  ),
);

final catalogoV13 = <Componente>[
  Componente(
    'ss-section-icon',
    'SsSection(icon:) e SsSectionHeader(icon:)',
    'Título de seção em versalete com ícone (o Ss::SectionComponent) e título de bloco maior com ícone na cor da marca (o Ss::SectionHeaderComponent).',
    comportamentos: [
      'SsSection: o ícone vem antes do texto, na cor apagada; o leitor de tela lê o título como escrito (sem a caixa alta).',
      'SsSectionHeader: ícone na cor da marca, título que cede espaço e a ação nunca sai da tela.',
    ],
    estados: [
      Estado(
        'secoes',
        'seção com ícone e ação · cabeçalho de bloco com ícone',
        (_) => _pad(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SsSection('Sala de estar', icon: Icons.weekend_outlined, action: 'Ver tudo', onAction: _nada),
              SsSectionHeader(
                'Andar de cima',
                subtitle: '3 cômodos · 2 luzes acesas',
                icon: Icons.home_outlined,
                action: const SsButton.text(label: 'Editar', onPressed: _nada),
              ),
            ],
          ),
        ),
        tamanho: const Size(390, 170),
      ),
    ],
  ),
  Componente(
    'ss-masonry',
    'SsMasonry',
    'Mosaico em colunas: os cards na ordem, um por coluna (1, 2, 3 ou 4 pela largura), cada coluna na própria altura. Par do Ss::MasonryComponent.',
    comportamentos: [
      'Colunas pela largura que recebe: 1 abaixo de 640, 2 até 1024, 3 até 1440, 4 acima; maxColumns limita.',
      'Espaço entre cards: o gap da densidade (spacing troca).',
    ],
    estados: [
      Estado(
        'duas',
        'duas colunas (700 de largura)',
        (_) => _pad(
          SsMasonry(
            children: [
              for (final (i, n) in [3, 1, 2, 1].indexed) _card('Card ${i + 1}', n),
            ],
          ),
        ),
        tamanho: const Size(700, 360),
      ),
    ],
  ),
  Componente(
    'ss-aside-layout',
    'SsAsideLayout',
    'Conteúdo + coluna lateral: 2/3 e 1/3 lado a lado a partir de 1024; abaixo, a coluna desce para baixo. Par do Ss::AsideLayoutComponent.',
    comportamentos: [
      'breakpoint troca a largura da quebra; asideLabel nomeia a coluna para o leitor de tela.',
      'Sem aside, é só o principal.',
    ],
    estados: [
      Estado(
        'lado',
        'lado a lado (1040 de largura)',
        (_) => _pad(SsAsideLayout(breakpoint: 900, main: _card('Principal', 3), aside: _card('Coluna lateral', 1))),
        tamanho: const Size(1040, 200),
      ),
      Estado(
        'empilhado',
        'empilhado (celular)',
        (_) => _pad(SsAsideLayout(main: _card('Principal', 1), aside: _card('Coluna lateral', 1))),
        tamanho: const Size(390, 250),
      ),
    ],
  ),
  Componente(
    'ss-mosaic-facts',
    'SsMosaicTile(facts:)',
    'Bloco de área com pílulas de resumo no lugar da legenda (v0.13; o facts: do Ss::MosaicTileComponent).',
    comportamentos: [
      'Pílulas brancas translúcidas numa linha que rola de lado se não couber; ícone opcional (SsMosaicFact).',
      'Leitor de tela: título e as pílulas numa frase só.',
      'v0.20.3: tone: pinta a pílula no tom semântico (SsTone; fundo suave opaco, texto no tom).',
      'v0.20.3: onTap: na pílula é um botão à parte (ganha do toque do bloco; semanticLabel: para o leitor de tela).',
    ],
    estados: [
      Estado(
        'pilulas',
        'com pílulas · com legenda',
        (_) => _pad(
          Row(
            spacing: 12,
            children: [
              Expanded(
                child: SsMosaicTile(
                  title: 'Sala',
                  icon: Icons.weekend_outlined,
                  height: 150,
                  onTap: _nada,
                  facts: const [
                    SsMosaicFact('2 ligados', icon: Icons.lightbulb_outline),
                    SsMosaicFact('87 W', icon: Icons.bolt),
                  ],
                ),
              ),
              const Expanded(
                child: SsMosaicTile(
                  title: 'Quarto',
                  icon: Icons.bed_outlined,
                  height: 150,
                  variant: 2,
                  caption: 'Tudo calmo',
                ),
              ),
            ],
          ),
        ),
        tamanho: const Size(390, 190),
      ),
      Estado(
        'tom-e-toque',
        'pílula no tom e com toque próprio',
        (_) => _pad(
          SsMosaicTile(
            title: 'Contas a pagar',
            icon: Icons.receipt_long_outlined,
            height: 150,
            variant: 1,
            onTap: _nada,
            facts: const [
              SsMosaicFact('12 em dia', icon: Icons.check),
              SsMosaicFact('3 atrasadas', icon: Icons.schedule, tone: SsTone.warning, onTap: _nada),
              SsMosaicFact('1 vencida', tone: SsTone.danger, onTap: _nada),
            ],
          ),
        ),
        tamanho: const Size(390, 190),
      ),
    ],
  ),
  Componente(
    'ss-photo-card',
    'SsPhotoCard',
    'Foto cobrindo o card na proporção pedida, com título e selo por cima de um véu; dimmed deixa em cinza (desligado). Par do Ss::PhotoCardComponent.',
    comportamentos: [
      'A imagem vem pronta do app (SsNetImage, com cache).',
      'onTap: o card afunda e volta com a mola (SsCard).',
      'Leitor de tela: imagem com "título, selo".',
    ],
    estados: [
      Estado(
        'fotos',
        'ligada · apagada',
        (_) => _pad(
          Row(
            spacing: 12,
            children: [
              Expanded(
                child: SsPhotoCard(image: _foto(), title: 'Varanda', badge: 'Ligada', aspectRatio: 4 / 3),
              ),
              Expanded(
                child: SsPhotoCard(
                  image: _foto(),
                  title: 'Jardim',
                  badge: 'Desligada',
                  aspectRatio: 4 / 3,
                  dimmed: true,
                ),
              ),
            ],
          ),
        ),
        tamanho: const Size(390, 170),
      ),
    ],
  ),
  Componente(
    'ss-brand-from-colors',
    'SsBrand.fromColors e ssMix',
    'Marca a partir de uma ou duas cores soltas (tema do usuário), com os tons derivados por mistura em sRGB; o ss_brand_style do Rails.',
    comportamentos: [
      'ssMix(a, b, t) = color-mix(in srgb, a, t de b).',
      'Hover 14% mais escuro, suave 12% sobre o branco, accent do escuro 28% mais claro, fundo do gradiente 35% mais escuro.',
    ],
    estados: [
      Estado(
        'oceano',
        'marca de #0284C7 → #14B8A6 num trecho',
        (_) => Theme(
          data: AppTheme.build(
            Brightness.light,
            brand: SsBrand.fromColors(SsBrand.oceano.accentLight, SsBrand.turquesa.accentLight),
          ),
          child: Builder(
            builder: (context) => _pad(
              Row(
                spacing: 8,
                children: [
                  const SsButton(label: 'Oceano', onPressed: _nada, expand: false),
                  const SsBadge('Selo', variant: SsBadgeVariant.accent),
                  const SsFilterChip('Atual', selected: true, onTap: _nada),
                ],
              ),
            ),
          ),
        ),
        tamanho: const Size(390, 90),
      ),
    ],
  ),
  Componente(
    'ss-prose',
    'SsProse e SsIntro',
    'Texto longo com medida de leitura (termos, ajuda; o .ss-prose) e o parágrafo de abertura de uma aba (o Ss::IntroComponent).',
    comportamentos: [
      'SsProse.paragraphs quebra o texto em parágrafos (linha em branco) e listas ("- item").',
      'Largura máxima de leitura (maxWidth, ~70 caracteres) e altura de linha 1,6; cresce com a fonte do sistema.',
      'SsIntro: uma ou duas frases apagadas antes do conteúdo.',
    ],
    estados: [
      Estado(
        'texto',
        'abertura · título, parágrafos e lista',
        (_) => _pad(
          Builder(
            builder: (context) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SsIntro('Aqui ficam as regras que avisam quando algo sai do normal.'),
                SsProse(
                  children: [
                    Text('Privacidade', style: SsProse.heading(context)),
                    const Text('Guardamos só o que a casa precisa para funcionar.'),
                    const SsProseList(['Leituras dos aparelhos', 'Histórico de 30 dias']),
                  ],
                ),
              ],
            ),
          ),
        ),
        tamanho: const Size(390, 280),
      ),
    ],
  ),
  Componente(
    'ss-field-group',
    'SsFieldGroup',
    'Grupo de campos com legenda e uma ajuda do grupo (o ss_fieldset do web).',
    comportamentos: [
      'O leitor de tela lê a legenda e a ajuda ao entrar no grupo.',
      'Espaço entre os campos: o gap da densidade (spacing troca).',
    ],
    estados: [
      Estado(
        'horario',
        'legenda, ajuda e dois campos',
        (_) => _pad(
          const SsFieldGroup(
            label: 'Horário',
            helperText: 'Vale para todos os dias da semana.',
            children: [
              SsTextField(label: 'Início'),
              SsTextField(label: 'Fim'),
            ],
          ),
        ),
        tamanho: const Size(390, 260),
      ),
    ],
  ),
];
