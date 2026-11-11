// Estados e comportamentos da v0.19.2 (as últimas caixas genéricas que o
// minhas-compras-app e o minhas-viagens-app desenhavam à mão): peça nova em
// [catalogoV192] e os extras das que já existiam (por slug) em [comV192].
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';

import 'catalogo.dart';

void _nada() {}

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

/// Foto de mentira (sem rede): degradê de céu e mar.
class _Foto extends StatelessWidget {
  const _Foto();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF7DB9E8), Color(0xFF2B6C8F), Color(0xFF1E3D4F)],
      ),
    ),
  );
}

final catalogoV192 = <Componente>[
  Componente(
    'ss-monogram',
    'SsMonogram',
    'Sigla de loja, site ou companhia num quadrado arredondado ou círculo, na cor de marca do terceiro (dado, por ssColorFromHex); par do ss_monogram.',
    comportamentos: [
      'A sigla é clara e encolhe para caber ("a", "ML", "Ali"); raio size/4, ou circle: true.',
      'color é dado (cor da marca da loja); sem ela, a cor da marca do produto. Nome de pessoa usa o SsAvatar.',
      'semanticLabel: o nome por extenso para o leitor de tela.',
    ],
    estados: [
      Estado(
        'padrao',
        'lojas e sites',
        (_) => _pad(
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SsMonogram('a', color: ssColorFromHex('#232F3E'), size: 32, semanticLabel: 'Amazon'),
              SsMonogram('ML', color: ssColorFromHex('#2D3277'), size: 32, semanticLabel: 'Mercado Livre'),
              SsMonogram('Ali', color: ssColorFromHex('#E43225'), size: 32, semanticLabel: 'AliExpress'),
              SsMonogram('S', color: ssColorFromHex('#EE4D2D'), size: 32, circle: true, semanticLabel: 'Shopee'),
              const SsMonogram('?', size: 32),
            ],
          ),
        ),
      ),
    ],
  ),
  Componente(
    'ss-dot',
    'SsDot',
    'Ponto de estado ou de não lida (par do .ss-dot), com anel opcional na cor do fundo para encostar num ícone.',
    comportamentos: [
      'Cor padrão: a da marca; size padrão 8; ring: anel de 2 px (o ponto cresce 4).',
      'A cor nunca vai sozinha: semanticLabel (ex. SsStrings.unread) ou o texto ao lado diz o estado.',
      'SsIconBubble(badge:) usa o mesmo ponto no canto.',
    ],
    estados: [
      Estado(
        'padrao',
        'não lida, ligado, erro',
        (ctx) => _pad(
          Row(
            spacing: 16,
            children: [
              const SsDot(size: 10, semanticLabel: 'Não lido'),
              const SsDot(color: AppColors.success),
              SsDot(color: AppColors.danger, size: 10, ring: SsColors.of(ctx).surface),
            ],
          ),
        ),
      ),
    ],
  ),
  Componente(
    'ss-quote',
    'SsQuote',
    'Recado de outra pessoa dentro de um card (doação, pedido, comentário): balão no fundo do campo, canto de cima reto, itálico entre aspas; par do .ss-quote.',
    comportamentos: [
      'Aspas automáticas (quoted: false tira); author: vai embaixo com travessão.',
      'Não é o SsChatBubble: não entra com mola nem se alinha pelo remetente.',
    ],
    estados: [
      Estado(
        'padrao',
        'recado da doação',
        (_) => _pad(const SsQuote('Pode buscar depois das 18h, deixo na portaria.')),
      ),
      Estado(
        'autor',
        'com autor',
        (_) => _pad(const SsQuote('Ainda está na validade, só não vou usar.', author: 'Ana')),
        tamanho: const Size(360, 110),
      ),
    ],
  ),
  Componente(
    'ss-illustration-stage',
    'SsIllustrationStage',
    'Palco de uma ilustração (passo do onboarding com formulário, abertura de recurso): degradê suave da marca para a página, raio de folha.',
    comportamentos: [
      'A ilustração encolhe para caber na height (112 padrão), para o botão do passo caber sem rolar.',
      'Cores do tema: accentSoft → page.',
    ],
    estados: [
      Estado(
        'padrao',
        'passo 1',
        (_) => _pad(const SsIllustrationStage(child: EmptyIllustration(icon: Icons.shopping_basket_outlined))),
        tamanho: const Size(360, 170),
      ),
    ],
  ),
  Componente(
    'ss-page-dots',
    'SsPageDots',
    'Indicador de página em pílulas (o do SsOnboarding, público): a atual estica na cor da marca.',
    comportamentos: [
      'Para passos que só avançam ao salvar (o SsOnboarding avança sozinho).',
      'Muda com a mola da suíte; reduzir movimento troca sem animar.',
      'O leitor de tela lê "Página 2 de 3".',
    ],
    estados: [
      Estado(
        'padrao',
        'página 2 de 3',
        (_) => _pad(const SsPageDots(count: 3, index: 1)),
        tamanho: const Size(360, 60),
      ),
      Estado(
        'esquerda',
        'pequeno, à esquerda',
        (_) => _pad(const SsPageDots(count: 3, index: 0, size: 6, alignment: MainAxisAlignment.start)),
        tamanho: const Size(360, 60),
      ),
    ],
  ),
];

/// Soma os extras da v0.19.2 às entradas de [base] com o mesmo slug.
List<Componente> comV192(List<Componente> base) => [
  for (final c in base)
    if (_v192[c.slug] case (final comp, final est))
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

final Map<String, (List<String>, List<Estado>)> _v192 = {
  'ss-hero': (
    [
      'v0.19.2: SsHeroCard.custom(child:) é o mesmo gradiente com conteúdo livre (texto e ícone já claros); background: fica atrás (desenho com Positioned), onTap: o deixa tocável, radius:/shadow:/padding: ajustam.',
    ],
    [
      Estado(
        'livre',
        'chamada com três atalhos',
        (_) => _pad(
          SsHeroCard.custom(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Olá, Ana!',
                  style: TextStyle(color: AppColors.onDarkIcon, fontWeight: FontWeight.w700),
                ),
                const Text(
                  'Para onde vamos?',
                  style: TextStyle(fontSize: AppType.screenTitle, fontWeight: FontWeight.w800, height: AppType.tight),
                ),
                const SizedBox(height: 14),
                Row(
                  spacing: 8,
                  children: [
                    for (final (i, t) in [
                      (Icons.flight_rounded, 'Voo'),
                      (Icons.luggage_rounded, 'Pacote'),
                      (Icons.hotel_rounded, 'Hospedagem'),
                    ])
                      Expanded(
                        child: SsButton.onGradient(label: t, icon: i, solid: true, stacked: true, onPressed: _nada),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        tamanho: const Size(360, 250),
      ),
      Estado(
        'toque',
        'bloco tocável ("Foto do cupom")',
        (_) => _pad(
          SsHeroCard.custom(
            onTap: _nada,
            semanticLabel: 'Foto do cupom',
            radius: AppRadius.cardActive,
            child: const Row(
              children: [
                SsIconTile(Icons.receipt_long_rounded, size: 60, onGradient: true),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Foto do cupom',
                    style: TextStyle(fontSize: AppType.lg, fontWeight: FontWeight.w800),
                  ),
                ),
                Icon(Icons.arrow_forward_rounded),
              ],
            ),
          ),
        ),
        tamanho: const Size(360, 130),
      ),
    ],
  ),
  'ss-button': (
    [
      'v0.19.2: SsButton.onGradient é o botão sobre o gradiente: translúcido com fio claro (o .ss-btn.is-on-grad) ou solid: true, branco com o texto na cor funda da marca (.is-solid).',
      'v0.19.2: stacked: true põe o ícone em cima do rótulo (o rótulo encolhe numa linha); no web, .is-stacked.',
    ],
    [
      Estado(
        'sobre-gradiente',
        'translúcido e sólido, empilhado',
        (_) => _pad(
          SsHeroCard.custom(
            shadow: false,
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: SsButton.onGradient(label: 'Novo', icon: Icons.add, onPressed: _nada),
                ),
                Expanded(
                  child: SsButton.onGradient(
                    label: 'Voo',
                    icon: Icons.flight,
                    solid: true,
                    stacked: true,
                    onPressed: _nada,
                  ),
                ),
              ],
            ),
          ),
        ),
        tamanho: const Size(360, 170),
      ),
    ],
  ),
  'ss-card': (
    [
      'v0.19.2: stripe: faixa de 5 px na borda esquerda por dentro do raio (o padding conta a partir dela); web .ss-card.has-stripe com --ss-card-stripe.',
      'v0.19.2: outline: contorno de 2 px na cor, sem trocar fundo nem sombra ("no alvo", conflito); web .has-outline com --ss-card-outline.',
    ],
    [
      Estado(
        'faixa',
        'faixa do tipo do aviso',
        (ctx) => _pad(
          SsCard(stripe: SsTone.danger.colors(ctx).solid, child: const Text('Recall: lote 2231 do leite integral')),
        ),
      ),
      Estado(
        'contorno',
        'contorno "no alvo"',
        (_) => _pad(const SsCard(outline: AppColors.success, child: Text('Chegou no seu preço-alvo'))),
      ),
    ],
  ),
  'ss-badge': (
    [
      'v0.19.2: solid: fundo cheio no tom e texto claro (muted/ghost saem invertidos: fundo de tinta); mono: rótulo em DM Mono. Web .ss-badge.is-solid / .is-mono.',
    ],
    [
      Estado(
        'solido',
        'DIA 3 · ANTES · HOJE',
        (_) => _pad(
          const Wrap(
            spacing: 8,
            children: [
              SsBadge('DIA 3', variant: SsBadgeVariant.accent, solid: true, mono: true),
              SsBadge('ANTES', variant: SsBadgeVariant.muted, solid: true, mono: true),
              SsBadge('No alvo', variant: SsBadgeVariant.success, solid: true),
              SsBadge('Vencido', variant: SsBadgeVariant.danger, solid: true),
            ],
          ),
        ),
      ),
    ],
  ),
  'ss-photo-card': (
    [
      'v0.19.2: subtitle: embaixo do título (o título cresce); credit: no canto de cima (onCredit: abre a fonte); selected: contorno da marca e ✓; expand: ocupa a altura que recebe (PageView).',
    ],
    [
      Estado(
        'destino',
        'carrossel de destinos, escolhido',
        (_) => _pad(
          const SizedBox(
            width: 280,
            height: 180,
            child: SsPhotoCard(
              image: _Foto(),
              title: 'Praia do Rosa',
              subtitle: 'Imbituba, SC',
              credit: 'Foto: Fulano · CC BY 4.0',
              onCredit: _nada,
              selected: true,
              expand: true,
              onTap: _nada,
            ),
          ),
        ),
        tamanho: const Size(360, 220),
      ),
    ],
  ),
  'ss-prose': (
    [
      'v0.19.2: SsProseList(ordered: true) numera os itens num círculo suave da marca (passos de receita, instruções); start: o primeiro número. Web: ol.is-steps no .ss-prose.',
    ],
    [
      Estado(
        'passos',
        'passos numerados',
        (_) => _pad(
          const SsProseList([
            'Abra Configurações › Apps › Minhas Viagens.',
            'Toque em Bateria.',
            'Escolha "Sem restrição".',
          ], ordered: true),
        ),
        tamanho: const Size(360, 140),
      ),
    ],
  ),
  'ss-section': (
    [
      'v0.19.2: SsIconBubble(badge:) põe um ponto de estado no canto, com anel na cor da superfície (badgeLabel: o que o leitor lê).',
    ],
    [
      Estado(
        'ponto',
        'bolha com ponto de estado',
        (_) => _pad(
          const Row(
            spacing: 16,
            children: [
              SsIconBubble(
                Icons.account_balance_wallet_outlined,
                size: 44,
                badge: AppColors.success,
                badgeLabel: 'Ligado',
              ),
              SsIconBubble(Icons.sync_problem_outlined, size: 44, badge: AppColors.danger, badgeLabel: 'Erro'),
            ],
          ),
        ),
      ),
    ],
  ),
  'ss-glass': (
    [
      'v0.19.2: tone: SsGlassTone.dark troca o véu claro por um escuro e o texto fica claro (dica sobre a câmera); web .ss-glass.is-dark.',
    ],
    [
      Estado(
        'escuro',
        'dica sobre a câmera',
        (_) => const Stack(
          fit: StackFit.expand,
          children: [
            _Foto(),
            Center(
              child: SsGlass(
                tone: SsGlassTone.dark,
                radius: AppRadius.field,
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text('Aponte para o código de barras', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
        tamanho: const Size(360, 120),
      ),
    ],
  ),
  'ss-deal-badge': (
    [
      'v0.19.2: SsSourceChip(trailing:) põe um ícone depois do nome (estado da busca na loja); semanticLabel: o nome com o estado.',
    ],
    [
      Estado(
        'estado',
        'loja com o estado da busca',
        (_) => _pad(
          const Wrap(
            spacing: 8,
            children: [
              SsSourceChip(
                'Shopee',
                trailing: Icon(Icons.check_circle, color: AppColors.success),
                semanticLabel: 'Shopee: 3 ofertas',
              ),
              SsSourceChip('Magalu', trailing: Icon(Icons.hourglass_top), semanticLabel: 'Magalu: buscando'),
            ],
          ),
        ),
      ),
    ],
  ),
};
