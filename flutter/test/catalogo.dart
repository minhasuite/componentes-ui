// Catálogo dos componentes: o que a skill `componentes` exporta em SVG.
// Componente novo no pacote = entrada nova aqui (nome, para que serve, o que
// faz e um estado por variação que importa). Os textos vão para o SVG.
import 'package:flutter/material.dart';
import 'package:componentes_ui/componentes_ui.dart';

class Estado {
  const Estado(this.slug, this.titulo, this.build, {this.tamanho = const Size(360, 96)});
  final String slug;
  final String titulo;
  final WidgetBuilder build;

  /// Área da captura, em pixels lógicos.
  final Size tamanho;
}

class Componente {
  const Componente(this.slug, this.nome, this.descricao, {required this.comportamentos, required this.estados});
  final String slug;
  final String nome;
  final String descricao;
  final List<String> comportamentos;
  final List<Estado> estados;
}

void _nada() {}
Widget _pad(Widget w) => Padding(
  padding: const EdgeInsets.all(16),
  child: Center(child: w),
);
const _tela = Size(360, 780);

final catalogo = <Componente>[
  Componente(
    'ss-button',
    'SsButton',
    'Botão do design system: altura 50 (36 no small), raio 14, largura cheia por padrão.',
    comportamentos: [
      'primary leva o glow da cor da marca (sombra direcional); some quando desabilitado.',
      'loading troca o conteúdo por um spinner e bloqueia o toque.',
      'Sem onPressed (ou loading) fica com opacidade 50%.',
      'Toque com ripple do Material no raio do botão.',
    ],
    estados: [
      for (final v in SsButtonVariant.values)
        Estado(v.name, v.name, (_) => _pad(SsButton(label: 'Salvar', icon: Icons.check, variant: v, onPressed: _nada))),
      Estado('loading', 'loading', (_) => _pad(const SsButton(label: 'Salvar', loading: true, onPressed: _nada))),
      Estado('desabilitado', 'desabilitado', (_) => _pad(const SsButton(label: 'Salvar'))),
      Estado(
        'small',
        'small, sem expandir',
        (_) => _pad(const SsButton(label: 'Filtrar', small: true, expand: false, onPressed: _nada)),
      ),
    ],
  ),
  Componente(
    'ss-card',
    'SsCard',
    'Superfície padrão: raio 18, sombra suave em duas camadas. Espelha o .ss-card do web.',
    comportamentos: [
      'active: borda de 2 px na cor da marca, raio 22 e glow; a troca anima em 180 ms.',
      'done: conteúdo com opacidade 70% (item concluído).',
      'Com onTap vira tocável, com ripple dentro do raio.',
    ],
    estados: [
      Estado('normal', 'normal', (_) => _pad(const SsCard(child: Text('Pedido 1042 · R\$ 1.250,00')))),
      Estado('ativo', 'active', (_) => _pad(const SsCard(active: true, child: Text('Pedido 1042 · R\$ 1.250,00')))),
      Estado('feito', 'done', (_) => _pad(const SsCard(done: true, child: Text('Pedido 1042 · R\$ 1.250,00')))),
    ],
  ),
  Componente(
    'ss-badge',
    'SsBadge',
    'Selo em pílula: fundo suave e texto na cor, com contraste AA nos dois temas.',
    comportamentos: ['micro: 10 px, caixa alta e espaçado.', 'Leitor de tela lê só o rótulo.'],
    estados: [
      Estado(
        'variantes',
        'accent · success · warning · danger · ghost · aquec',
        (_) => _pad(
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final v in SsBadgeVariant.values) SsBadge(v.name, variant: v)],
          ),
        ),
      ),
      Estado(
        'micro',
        'micro',
        (_) => _pad(
          Wrap(spacing: 6, children: [for (final v in SsBadgeVariant.values) SsBadge(v.name, variant: v, micro: true)]),
        ),
      ),
    ],
  ),
  Componente(
    'ss-progress',
    'SsProgress',
    'Barra de progresso em pílula, de 0 a 1.',
    comportamentos: ['Em 100% vira verde (sucesso). Para limite estourado, passe color: danger.'],
    estados: [
      Estado('meio', '50%', (_) => _pad(const SsProgress(.5)), tamanho: const Size(360, 48)),
      Estado('cheio', '100%', (_) => _pad(const SsProgress(1)), tamanho: const Size(360, 48)),
    ],
  ),
  Componente(
    'ss-hero',
    'SsHeroCard',
    'Herói com o gradiente da marca: rótulo, número grande em DM Mono, legenda e selos.',
    comportamentos: ['Texto sempre claro: o gradiente é escuro nos dois temas.'],
    estados: [
      Estado(
        'padrao',
        'com selos',
        (_) => _pad(
          const SsHeroCard(
            label: 'Vendido no mês',
            value: 'R\$ 48.320,00',
            caption: '12% acima de setembro',
            chips: [
              SsHeroChip(Icons.people_outline, '38 clientes'),
              SsHeroChip(Icons.receipt_long_outlined, '112 pedidos'),
            ],
          ),
        ),
        tamanho: const Size(360, 300),
      ),
    ],
  ),
  Componente(
    'ss-section',
    'SsSection e SsIconBubble',
    'Título de seção em caixa alta com ação opcional; ícone em bolha suave.',
    comportamentos: ['A ação é um TextButton compacto na cor da marca.'],
    estados: [
      Estado('secao', 'SsSection com ação', (_) => _pad(SsSection('Vence logo', action: 'Ver tudo', onAction: _nada))),
      Estado(
        'bolha',
        'SsIconBubble',
        (_) => _pad(
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SsIconBubble(Icons.shopping_bag_outlined),
              SizedBox(width: 8),
              SsIconBubble(Icons.warning_amber, color: AppColors.danger),
            ],
          ),
        ),
      ),
    ],
  ),
  Componente(
    'ss-empty-state',
    'SsEmptyState',
    'Estado vazio: ilustração, título, subtítulo e ação opcional, dentro de um SsCard.',
    comportamentos: [
      'A ilustração flutua devagar (4 s, vai e volta) e para quando o sistema pede menos animação.',
      'A ação só aparece com actionLabel e onAction.',
    ],
    estados: [
      Estado(
        'com-acao',
        'com ação',
        (_) => const SsEmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'Nenhum pedido ainda',
          subtitle: 'Os pedidos da carteira aparecem aqui.',
          actionLabel: 'Novo pedido',
          onAction: _nada,
        ),
        tamanho: const Size(360, 380),
      ),
    ],
  ),
  Componente(
    'ss-error-view',
    'SsErrorView',
    'Erro de carregamento: ícone, mensagem e "Tentar de novo".',
    comportamentos: ['Sem onRetry o botão não aparece.'],
    estados: [
      Estado(
        'com-retry',
        'com onRetry',
        (_) => const SsErrorView(message: 'Sem conexão com o servidor.', onRetry: _nada),
        tamanho: const Size(360, 200),
      ),
    ],
  ),
  Componente(
    'skeleton',
    'SkeletonList e SkeletonBox',
    'Fantasmas de carregamento no lugar do spinner: lista de cartões e bloco de altura fixa (gráfico, imagem).',
    comportamentos: [
      'Pulsam a opacidade entre 45% e 85% a cada 1,1 s.',
      'SkeletonBox segura a altura final para a tela não pular.',
    ],
    estados: [
      Estado('lista', 'SkeletonList(count: 3)', (_) => const SkeletonList(count: 3), tamanho: const Size(360, 300)),
      Estado(
        'caixa',
        'SkeletonBox(height: 120)',
        (_) => _pad(const SkeletonBox(height: 120)),
        tamanho: const Size(360, 152),
      ),
    ],
  ),
  Componente(
    'ss-plans',
    'SsPlansView',
    'Tela de planos padrão: plano atual, Mensal/Anual, um cartão por plano e o comparativo.',
    comportamentos: ['O Max leva a cor de destaque (laranja).', 'busy desabilita a compra enquanto a loja responde.'],
    estados: [
      Estado(
        'vitrine',
        'vitrine',
        (_) => SsPlansView(
          currentName: 'Grátis',
          yearly: false,
          onYearly: (_) {},
          offers: const [
            SsPlanOffer(
              tier: SsTier.pro,
              name: 'Pro',
              price: 'R\$ 19,90/mês',
              features: ['Clientes ilimitados', 'Relatórios'],
              onBuy: _nada,
            ),
            SsPlanOffer(
              tier: SsTier.max,
              name: 'Max',
              price: 'R\$ 39,90/mês',
              badge: 'Mais completo',
              features: ['Tudo do Pro', 'IA sem limite'],
              onBuy: _nada,
            ),
          ],
          compare: const [
            (label: 'Clientes', free: '50', pro: '∞', max: '∞'),
            (label: 'IA', free: '—', pro: '30/mês', max: '∞'),
          ],
        ),
        tamanho: _tela,
      ),
    ],
  ),
  Componente(
    'ss-menu',
    'SsMenuView',
    'Aba "Mais" padrão: busca, perfil, planos, seções recolhíveis, aparência, excluir conta e sair.',
    comportamentos: [
      'A busca filtra todas as linhas pelo título e subtítulo.',
      'Seções recolhem e expandem; danger pinta a linha de vermelho.',
    ],
    estados: [
      Estado(
        'padrao',
        'padrão',
        (_) => SsMenuView(
          name: 'Ana Souza',
          email: 'ana@exemplo.com',
          planLabel: 'Pro',
          onPlans: _nada,
          sections: const [
            SsMenuSection('Vendas', [
              SsMenuItem(Icons.people_outline, 'Clientes', subtitle: 'Carteira'),
              SsMenuItem(Icons.route_outlined, 'Visitas'),
            ]),
          ],
          themeMode: ThemeMode.system,
          onThemeMode: (_) {},
          onDeleteAccount: _nada,
          onLogout: _nada,
        ),
        tamanho: _tela,
      ),
    ],
  ),
];
