// Catálogo dos componentes: o que a skill `componentes` exporta em SVG.
// Componente novo no pacote = entrada nova aqui (nome, para que serve, o que
// faz e um estado por variação que importa). Os textos vão para o SVG.
import 'package:flutter/material.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo_onda1.dart';
import 'catalogo_onda2.dart';
import 'catalogo_onda3.dart';
import 'catalogo_onda3b.dart';
import 'catalogo_onda4.dart';
import 'catalogo_extras.dart';
import 'catalogo_v06.dart';
import 'catalogo_v07_compras.dart';
import 'catalogo_v07_cultivo.dart';
import 'catalogo_v07_gestor.dart';
import 'catalogo_v07_viagens.dart';
import 'catalogo_v08.dart';
import 'catalogo_v09_a.dart';
import 'catalogo_v09_b.dart';
import 'catalogo_mov_a.dart';
import 'catalogo_mov_b.dart';
import 'catalogo_paletas.dart';
import 'catalogo_v10_controles.dart';
import 'catalogo_v10_dados.dart';
import 'catalogo_v10_casa.dart';
import 'catalogo_v10_estrutura.dart';
import 'catalogo_v102.dart';
import 'catalogo_v11.dart';
import 'catalogo_v12.dart';
import 'catalogo_v13.dart';
import 'catalogo_v14.dart';
import 'catalogo_v15.dart';
import 'catalogo_v152.dart';
import 'catalogo_v16.dart';
import 'catalogo_v18.dart';
import 'catalogo_v19.dart';
import 'catalogo_v191.dart';
import 'catalogo_v192.dart';
import 'catalogo_v20.dart';
import 'catalogo_v21.dart';
import 'catalogo_v22.dart';

class Estado {
  const Estado(this.slug, this.titulo, this.build, {this.tamanho = const Size(360, 96), this.aguarde = 400});
  final String slug;
  final String titulo;
  final WidgetBuilder build;

  /// ms entre montar e capturar (menor = pega uma animação no meio).
  final int aguarde;

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

const _abas = [
  SsNavItem(Icons.people_alt_outlined, 'Carteira', activeIcon: Icons.people_alt_rounded),
  SsNavItem(Icons.receipt_long_outlined, 'Pedidos', activeIcon: Icons.receipt_long_rounded),
  SsNavItem(Icons.route_outlined, 'Agenda', activeIcon: Icons.route_rounded),
  SsNavItem(Icons.menu_outlined, 'Mais', activeIcon: Icons.menu_rounded),
];

/// Tela com conteúdo colorido atrás da barra (o recorte mostra a tela).
/// Com [para], troca de aba logo depois do 1º quadro.
class _NavDemo extends StatefulWidget {
  const _NavDemo(this.inicio, {this.para});
  final int inicio;
  final int? para;

  @override
  State<_NavDemo> createState() => _NavDemoState();
}

class _NavDemoState extends State<_NavDemo> {
  late int i = widget.inicio;

  @override
  void initState() {
    super.initState();
    if (widget.para != null) WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => i = widget.para!));
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Scaffold(
      extendBody: true,
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: LinearGradient(colors: [c.brandFrom, c.brandTo])),
        ),
      ),
      bottomNavigationBar: SsNavBar(items: _abas, currentIndex: i, onTap: (v) => setState(() => i = v)),
    );
  }
}

final catalogo = comV21(comV20(comV192(comV191(comV19(comV18(comV16(comV152(_catalogo))))))));

final _catalogo = comV08(<Componente>[
  Componente(
    'ss-nav-bar',
    'SsNavBar',
    'Barra de abas: o item atual fica num círculo encaixado num recorte curvo da barra. Vai no bottomNavigationBar (extendBody opcional).',
    comportamentos: [
      'Ao trocar de aba, o círculo pula em arco até o item novo (640 ms): achata antes de sair, estica na subida e na descida e achata de novo ao pousar.',
      'Quanto mais longe a aba, mais alto o pulo (20 a 40 px).',
      'O recorte fica raso enquanto o círculo está no ar, acompanha o voo e afunda um pouco no pouso.',
      'O ícone novo aparece crescendo (com leve passada) a partir do meio do voo; o lugar do item atual na barra fica vazio.',
      'Troca no meio do pulo continua de onde o círculo está, sem teleportar.',
      'Toque com haptic leve (selectionClick); tocar na aba atual chama onTap de novo (voltar ao topo).',
      'Sem animação quando o sistema pede menos movimento.',
      'Leitor de tela: "Pedidos, aba 2 de 4", com o estado selecionado.',
      'Escuro: borda de 1 px no lugar da sombra.',
    ],
    estados: [
      Estado('primeira', 'aba 1', (_) => const _NavDemo(0), tamanho: const Size(360, 200)),
      Estado('terceira', 'aba 3', (_) => const _NavDemo(2), tamanho: const Size(360, 200)),
      Estado(
        'pulando',
        'da 1 para a 3: no alto do pulo',
        (_) => const _NavDemo(0, para: 2),
        tamanho: const Size(360, 200),
        aguarde: 290,
      ),
      Estado(
        'pousando',
        'da 1 para a 3: achatando no pouso',
        (_) => const _NavDemo(0, para: 2),
        tamanho: const Size(360, 200),
        aguarde: 540,
      ),
    ],
  ),
  Componente(
    'ss-button',
    'SsButton',
    'Botão do design system: altura 50 (36 no small), raio 14, largura cheia por padrão.',
    comportamentos: [
      'primary leva o glow da cor da marca (sombra direcional); some quando desabilitado.',
      'loading troca o conteúdo por um spinner e bloqueia o toque.',
      'Sem onPressed (ou loading) fica com opacidade 50%.',
      'Toque com ripple do Material no raio do botão.',
      'SsButton.text: botão de texto (link) sem fundo nem sombra, na cor da marca (danger: vermelho), altura 40 (32 no small), não expande.',
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
      Estado(
        'texto',
        'SsButton.text (link)',
        (_) => _pad(const SsButton.text(label: 'Esqueci a senha', onPressed: _nada)),
      ),
      Estado(
        'texto-perigo',
        'SsButton.text com ícone, danger',
        (_) => _pad(const SsButton.text(label: 'Remover', icon: Icons.delete_outline, danger: true, onPressed: _nada)),
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
      'compact: sem card nem rolagem própria, para dentro de folha ou seção que já rola.',
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
      Estado(
        'compacto',
        'compacto (dentro de folha)',
        (_) => const SsEmptyState(
          icon: Icons.flag_outlined,
          title: 'Nenhum trecho salvo',
          subtitle: 'Marque um trecho no fim da corrida.',
          compact: true,
        ),
        tamanho: const Size(360, 240),
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
      'onDeleteAccount nulo tira o botão "Excluir minha conta".',
      'appearance: widgets livres em "Aparência e sobre" (paleta, switch, idioma); SsMenuSection(top:) põe widgets antes das linhas. SsMenuCard é o cartão das linhas.',
      'O tema usa o SsSegmented da suíte (com ícones), não o SegmentedButton do Material.',
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
      Estado(
        'aparencia-livre',
        'sem excluir conta; aparência com paleta, switch e idioma',
        (_) => SsMenuView(
          name: 'Ana Souza',
          email: 'ana@exemplo.com',
          sections: const [],
          themeMode: ThemeMode.dark,
          onThemeMode: (_) {},
          onLogout: _nada,
          appearanceOpen: true,
          appearance: [
            SsMenuCard(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SsPalettePicker(value: SsBrand.violeta, onChanged: (_) {}),
            ),
            SsMenuSwitch(label: 'Sons', icon: Icons.volume_up_outlined, value: true, onChanged: (_) {}),
            SsMenuCard(
              padding: EdgeInsets.zero,
              child: SsLocalePicker(
                value: null,
                onChanged: (_) {},
                systemOption: true,
                onSystem: _nada,
                showFlag: false,
              ),
            ),
          ],
        ),
        tamanho: const Size(390, 780),
      ),
    ],
  ),
  Componente(
    'vitrine',
    'Tela de exemplo',
    'Os componentes novos juntos: fundo com aurora fraca, um só cartão de luz, indicadores em bento, filtros e lista. É a referência de composição.',
    comportamentos: [
      'Um único momento de luz por tela (o SsAuroraCard); o resto é superfície calma.',
      'Números em DM Mono, centavos menores; cor só no que tem sentido (variação, destaque de hoje).',
      'Movimento curto e de mola; nada contínuo além da deriva da aurora.',
    ],
    estados: [Estado('padrao', 'carteira do vendedor', (_) => const _Vitrine(), tamanho: _tela, aguarde: 1100)],
  ),
  Componente(
    'ss-aurora-card',
    'SsAuroraCard',
    'O momento de luz da tela: base escura da marca, manchas de aurora num canto e grão fino. Texto sempre claro. Um por tela.',
    comportamentos: [
      'As cores saem da marca (SsBrand): clara, principal e uma vizinha fria; cada produto tem a sua aurora.',
      'As manchas derivam devagar (14 s, ida e volta); param com menos movimento ou animate: false.',
      'Encolhe para 0,97 ao toque quando tem onTap.',
      'Grão de 7% numa camada própria: a deriva não repinta o texto.',
    ],
    estados: [
      Estado('padrao', 'saldo do mês', (_) => _pad(const _AuroraDemo()), tamanho: const Size(360, 230)),
      Estado(
        'verde',
        'outra marca (SsBrand do cultivo)',
        (ctx) => Theme(
          data: AppTheme.build(Theme.of(ctx).brightness, brand: _verde),
          child: _pad(const _AuroraDemo()),
        ),
        tamanho: const Size(360, 230),
      ),
    ],
  ),
  Componente(
    'ss-aurora-background',
    'SsAuroraBackground',
    'Fundo de tela com a aurora bem fraca (10% no claro, 16% no escuro) só no topo, sumindo para baixo. Vai num Stack atrás do conteúdo.',
    comportamentos: ['Parado (sem animação).', 'Não recebe toque (IgnorePointer).'],
    estados: [
      Estado(
        'padrao',
        'topo de uma tela',
        (ctx) => Stack(
          fit: StackFit.expand,
          children: [
            const SsAuroraBackground(height: 300),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
              child: Text('Bom dia, Ana', style: Theme.of(ctx).textTheme.headlineSmall),
            ),
          ],
        ),
        tamanho: const Size(360, 260),
      ),
    ],
  ),
  Componente(
    'ss-stat-card',
    'SsStatCard',
    'Indicador: rótulo, número grande em DM Mono (centavos menores), variação e minigráfico encostado na base.',
    comportamentos: [
      'A variação é colorida pelo sentido (bom/ruim), não pelo sinal.',
      'O minigráfico se desenha da esquerda para a direita (700 ms).',
      'Encolhe para 0,97 ao toque quando tem onTap.',
      'No escuro, borda de 1 px.',
      'tone pinta o ícone (sucesso, aviso); o número encolhe em vez de estourar a coluna.',
    ],
    estados: [
      Estado(
        'completo',
        'com variação e minigráfico',
        (_) => _pad(
          SizedBox(
            width: 200,
            child: SsStatCard(
              label: 'Vendido na semana',
              icon: Icons.trending_up_rounded,
              value: r'R$ 18.420,50',
              delta: const SsDelta('12%', up: true),
              spark: const [8, 9, 7, 11, 10, 13, 12, 15, 14, 18],
            ),
          ),
        ),
        tamanho: const Size(360, 230),
        aguarde: 900,
      ),
      Estado(
        'despesa',
        'despesa que caiu (bom)',
        (_) => _pad(
          const SizedBox(
            width: 200,
            child: SsStatCard(
              label: 'Gastos do mês',
              value: r'R$ 2.310,00',
              delta: SsDelta('8%', up: false, good: true),
              caption: 'vs. setembro',
            ),
          ),
        ),
        tamanho: const Size(360, 160),
      ),
      Estado(
        'tom',
        'ícone no tom de aviso e número longo encolhido',
        (_) => _pad(
          const SizedBox(
            width: 150,
            child: SsStatCard(
              label: 'Ofensiva',
              icon: Icons.local_fire_department_outlined,
              tone: AppColors.aquecFg,
              value: '128.450 kg',
            ),
          ),
        ),
        tamanho: const Size(360, 150),
      ),
    ],
  ),
  Componente(
    'ss-amount',
    'SsAmount · SsDelta',
    'Valor em DM Mono com os centavos menores e apagados; variação numa pílula colorida pelo sentido.',
    comportamentos: [
      'Sem ",dd" no fim, mostra o texto inteiro.',
      'SsDelta: good verde, ruim vermelho, null neutro; onDark para usar sobre a aurora.',
    ],
    estados: [
      Estado(
        'padrao',
        'valor e as três variações',
        (_) => _pad(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SsAmount(r'R$ 12.480,90'),
              SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SsDelta('12%', up: true),
                  SizedBox(width: 8),
                  SsDelta('4%', up: true, good: false),
                  SizedBox(width: 8),
                  SsDelta('0%', up: true, good: null),
                ],
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 130),
      ),
    ],
  ),
  Componente(
    'ss-sparkline',
    'SsSparkline',
    'Linha sem eixo, curva suave, preenchimento que some para baixo e um ponto no último valor.',
    comportamentos: ['Desenha-se da esquerda para a direita ao aparecer (700 ms).', 'Cor: a da marca, ou color.'],
    estados: [
      Estado(
        'padrao',
        'padrão',
        (_) => _pad(const SsSparkline([3, 4, 3.5, 5, 4.6, 6, 5.4, 7, 6.8, 8.5], height: 60)),
        tamanho: const Size(360, 100),
        aguarde: 900,
      ),
    ],
  ),
  Componente(
    'ss-rings',
    'SsRings',
    'Anéis concêntricos (até 3) com ponta arredondada sobre a trilha da mesma cor a 14%; o número vai no centro.',
    comportamentos: [
      'Preenchem em cascata ao aparecer: 700 ms cada, 80 ms entre eles.',
      'Sem cor, usam as cores da aurora da marca.',
      'Valor acima de 1 = anel cheio.',
    ],
    estados: [
      Estado(
        'padrao',
        'meta, visitas e positivação',
        (ctx) => _pad(
          SsRings(
            const [SsRing(.72), SsRing(.5), SsRing(.88)],
            size: 150,
            center: Text('72%', style: AppTheme.number(ctx, size: 22)),
          ),
        ),
        tamanho: const Size(360, 190),
        aguarde: 1000,
      ),
    ],
  ),
  Componente(
    'ss-pill-bars',
    'SsPillBars',
    'Barras em pílula (7 a 12 colunas): a de hoje na cor da marca, as outras a 22%.',
    comportamentos: [
      'Crescem de baixo ao aparecer, com uma leve passada (easeOutBack).',
      'Tocar numa barra mostra o valor em cima dela (format); sem toque, mostra o de hoje.',
      'Leitor de tela lê rótulo e valor de cada barra.',
    ],
    estados: [
      Estado(
        'padrao',
        'vendas da semana',
        (_) => _pad(
          SsPillBars(
            values: const [8.2, 12.5, 9.1, 15.8, 11.2, 6.4, 13.9],
            labels: const ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'],
            format: (v) => '${v.toStringAsFixed(1).replaceAll('.', ',')} mil',
          ),
        ),
        tamanho: const Size(360, 170),
        aguarde: 900,
      ),
    ],
  ),
  Componente(
    'ss-segmented',
    'SsSegmented',
    'Seletor de 2 a 4 opções: trilha afundada e uma pílula que desliza com mola até a escolhida.',
    comportamentos: [
      'Deslize de 340 ms com leve passada (easeOutBack); haptic selectionClick.',
      'Texto da escolhida na cor da marca, em 800.',
      'No escuro a pílula é mais clara que a trilha.',
    ],
    estados: [
      Estado(
        'padrao',
        'período',
        (_) => _pad(SsSegmented(segments: const [(0, 'Dia'), (1, 'Semana'), (2, 'Mês')], value: 1, onChanged: (_) {})),
      ),
    ],
  ),
  Componente(
    'ss-filter-chip',
    'SsFilterChip · SsChipBar',
    'Filtros em pílula numa faixa que rola na horizontal; marcado ganha ✓ e o tom da marca.',
    comportamentos: [
      'O ✓ entra crescendo (220 ms, easeOutBack) e empurra o texto.',
      'Encolhe para 0,97 ao toque, com haptic leve.',
      'Contador opcional em DM Mono.',
      'onTap nulo desabilita: o chip apaga (45%) e não responde ao toque.',
      'color: bolinha da cor antes do texto, com borda para a cor clara aparecer; marcado, o ✓ fica dentro dela.',
      'color com swatch: true pinta o chip inteiro (texto claro ou escuro conforme a cor); marcado ganha o anel da marca.',
      'v0.10.3 SsChipBar(currentIndex:): rola só a faixa até o chip atual (perto do meio) ao abrir e quando muda; sem animação com "reduzir movimento".',
    ],
    estados: [
      Estado(
        'padrao',
        'um marcado',
        (_) => Center(
          child: SsChipBar(
            children: [
              SsFilterChip('Todos', selected: false, onTap: _nada, count: 48),
              SsFilterChip('Com vencido', selected: true, onTap: _nada, count: 6),
              SsFilterChip('Sem compra', selected: false, onTap: _nada),
            ],
          ),
        ),
      ),
      Estado(
        'atual-a-vista',
        'v0.10.3: currentIndex rola até o atual',
        (_) => Center(
          child: SsChipBar(
            currentIndex: 6,
            children: [
              for (final (i, n) in const [
                'Todos',
                'Sala',
                'Cozinha',
                'Quarto',
                'Varanda',
                'Garagem',
                'Jardim',
                'Escritório',
              ].indexed)
                SsFilterChip(n, selected: i == 6, onTap: _nada),
            ],
          ),
        ),
      ),
      Estado(
        'desabilitado',
        'desabilitado (onTap nulo)',
        (_) => const Center(
          child: SsChipBar(
            children: [
              SsFilterChip('Todos', selected: true, onTap: null, count: 48),
              SsFilterChip('Sem compra', selected: false, onTap: null),
            ],
          ),
        ),
      ),
      Estado(
        'cor',
        'amostra de cor (cores claras com borda)',
        (_) => Center(
          child: SsChipBar(
            children: [
              SsFilterChip('Branco', color: const Color(0xFFFFFFFF), selected: true, onTap: _nada),
              SsFilterChip('Amarelo', color: const Color(0xFFFFF59D), selected: false, onTap: _nada),
              SsFilterChip('Azul', color: const Color(0xFF3D5AFE), selected: false, onTap: _nada),
            ],
          ),
        ),
      ),
      Estado(
        'swatch',
        'chip pintado (swatch: true)',
        (_) => Center(
          child: SsChipBar(
            children: [
              SsFilterChip('Quente', color: const Color(0xFFFFD8A8), swatch: true, selected: true, onTap: _nada),
              SsFilterChip('Neutro', color: const Color(0xFFFFFFFF), swatch: true, selected: false, onTap: _nada),
              SsFilterChip('Frio', color: const Color(0xFF1E3A8A), swatch: true, selected: false, onTap: _nada),
            ],
          ),
        ),
      ),
    ],
  ),
  Componente(
    'ss-search-field',
    'SsSearchField',
    'Busca afundada, sem borda; no foco ganha anel e halo na cor da marca e o fundo vira superfície.',
    comportamentos: ['Botão de limpar quando há texto.', 'Teclado com a tecla "buscar".'],
    estados: [
      Estado('padrao', 'em repouso', (_) => _pad(const SsSearchField(hint: 'Nome, cidade ou CNPJ'))),
      Estado(
        'foco',
        'com foco e texto',
        (_) => _pad(
          SsSearchField(
            hint: 'Buscar',
            autofocus: true,
            controller: TextEditingController(text: 'mercado'),
          ),
        ),
        aguarde: 300,
      ),
    ],
  ),
  Componente(
    'ss-list-item',
    'SsListItem · SsGroupHeader',
    'Item de lista com ícone num quadrado tonal, título, subtítulo e valor em DM Mono à direita; cabeçalho de grupo com total.',
    comportamentos: [
      'tone pinta o quadrado (14%) e o ícone; sem ele, a cor da marca.',
      'leading troca o ícone por outro widget (ex.: SsAvatar).',
    ],
    estados: [
      Estado(
        'padrao',
        'grupo "hoje"',
        (ctx) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SsGroupHeader('Hoje', trailing: r'R$ 3.412,40'),
              SsListItem(
                icon: Icons.receipt_long_rounded,
                title: 'Pedido 1042',
                subtitle: 'Mercado Bom Preço',
                value: r'R$ 1.250,00',
                valueCaption: '10:42',
                onTap: _nada,
              ),
              SsListItem(
                leading: const SsAvatar('Padaria Central', status: AppColors.success),
                title: 'Padaria Central',
                subtitle: 'Visita feita · com pedido',
                value: r'R$ 318,40',
                valueColor: SsColors.of(ctx).successText,
                onTap: _nada,
              ),
              SsListItem(
                icon: Icons.warning_amber_rounded,
                tone: AppColors.danger,
                title: 'Título vencido',
                subtitle: 'Carlos Souza · 3 dias',
                value: r'R$ 68,48',
                valueColor: SsColors.of(ctx).dangerText,
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 260),
      ),
    ],
  ),
  Componente(
    'ss-avatar',
    'SsAvatar · SsAvatarStack',
    'Iniciais sobre um gradiente que sai do nome (sempre a mesma cor para o mesmo nome, na família da marca), com ponto de status.',
    comportamentos: [
      'Cinco vizinhos de matiz da marca; a cor não muda entre execuções.',
      'Anel da cor da página para empilhar (−8) com "+N" em DM Mono.',
      'Leitor de tela lê o nome, não as iniciais.',
    ],
    estados: [
      Estado(
        'padrao',
        'avatares e pilha',
        (_) => _pad(
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SsAvatar('Ana Souza', size: 48, status: AppColors.success),
              SizedBox(width: 10),
              SsAvatar('Bruno Lima', size: 48),
              SizedBox(width: 10),
              SsAvatar('Carla', size: 48, status: AppColors.danger),
              SizedBox(width: 24),
              SsAvatarStack(['Ana Souza', 'Bruno Lima', 'Carla Dias', 'Davi Melo', 'Eva Rocha']),
            ],
          ),
        ),
      ),
    ],
  ),
  Componente(
    'ss-toast',
    'SsToast · showSsToast',
    'Aviso em pílula escura (igual nos dois temas) com ícone, texto curto e "Desfazer" na cor da marca.',
    comportamentos: [
      'Sobe de baixo com mola (420 ms) acima da barra de abas e some sozinho em 4 s.',
      'Um novo substitui o anterior; tocar na ação fecha.',
      'Leitor de tela anuncia o texto (liveRegion).',
    ],
    estados: [
      Estado(
        'padrao',
        'com ação',
        (_) => _pad(
          SsToast(
            'Pedido salvo na fila',
            icon: Icons.check_circle_rounded,
            tone: AppColors.success,
            actionLabel: 'Desfazer',
            onAction: _nada,
          ),
        ),
      ),
    ],
  ),
  Componente(
    'ss-seal',
    'SsSeal',
    'Selo de destaque pontual: contorno firme e sombra deslocada sem desfoque. No máximo um por tela.',
    comportamentos: ['Texto em caixa alta, 800.', 'Para "Novo", "Meta batida", "Top 1".'],
    estados: [
      Estado(
        'padrao',
        'padrão',
        (_) => _pad(
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SsSeal('Novo'),
              SizedBox(width: 12),
              SsSeal('Meta batida', icon: Icons.bolt_rounded),
            ],
          ),
        ),
      ),
    ],
  ),
  ...catalogoOnda1,
  ...catalogoOnda2,
  ...catalogoOnda3,
  ...catalogoOnda3b,
  ...catalogoOnda4,
  ...catalogoExtras,
  ...catalogoV06,
  ...catalogoV07Compras,
  ...catalogoV07Cultivo,
  ...catalogoV07Gestor,
  ...catalogoV07Viagens,
  ...catalogoV09A,
  ...catalogoV09B,
  ...catalogoMovA,
  ...catalogoMovB,
  ...catalogoPaletas,
  ...catalogoV10Controles,
  ...catalogoV10Dados,
  ...catalogoV10Casa,
  ...catalogoV10Estrutura,
  ...catalogoV102,
  ...catalogoV11,
  ...catalogoV12,
  ...catalogoV13,
  ...catalogoV14,
  ...catalogoV15,
  ...catalogoV16,
  ...catalogoV18,
  ...catalogoV19,
  ...catalogoV191,
  ...catalogoV192,
  ...catalogoV20,
  ...catalogoV21,
  ...catalogoV22,
]);

const _verde = SsBrand(
  accentLight: Color(0xFF1F9D6B),
  accentHoverLight: Color(0xFF17845A),
  accentSoftLight: Color(0xFFE3F5EC),
  accentDark: Color(0xFF4FD19A),
  accentSoftDark: Color(0xFF15372A),
  brandFrom: Color(0xFF3CC48A),
  brandTo: Color(0xFF1F9D6B),
  brandDeep: Color(0xFF0F5C3E),
);

class _AuroraDemo extends StatelessWidget {
  const _AuroraDemo();

  @override
  Widget build(BuildContext context) => SsAuroraCard(
    animate: false,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Vendido em outubro',
              style: TextStyle(fontSize: AppType.sub, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            SsDelta('18%', up: true, onDark: true),
          ],
        ),
        const SizedBox(height: 10),
        const SsAmount(r'R$ 108.543,85', size: 32, color: AppColors.onDark),
        const SizedBox(height: 6),
        Text(
          'Meta de R\$ 120 mil · faltam 9 dias',
          style: TextStyle(fontSize: AppType.meta, color: AppColors.onDark.withValues(alpha: .75)),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: .9,
            minHeight: 6,
            backgroundColor: AppColors.onDark.withValues(alpha: .18),
            color: AppColors.onDark,
          ),
        ),
      ],
    ),
  );
}

class _Vitrine extends StatefulWidget {
  const _Vitrine();

  @override
  State<_Vitrine> createState() => _VitrineState();
}

class _VitrineState extends State<_Vitrine> {
  int periodo = 1;
  int filtro = 1;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Stack(
      children: [
        const SsAuroraBackground(),
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
          children: [
            Row(
              children: [
                const SsAvatar('Ana Souza', size: 44, status: AppColors.success),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sexta, 31 de outubro',
                        style: TextStyle(color: c.muted, fontSize: AppType.meta),
                      ),
                      Text(
                        'Bom dia, Ana',
                        style: TextStyle(color: c.ink, fontSize: AppType.headerTitle, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const SsSeal('Top 3'),
              ],
            ),
            const SizedBox(height: 18),
            const _AuroraDemo(),
            const SizedBox(height: 14),
            SsSegmented(
              segments: const [(0, 'Hoje'), (1, 'Semana'), (2, 'Mês')],
              value: periodo,
              onChanged: (v) => setState(() => periodo = v),
            ),
            const SizedBox(height: 14),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SsStatCard(
                    label: 'Pedidos',
                    icon: Icons.receipt_long_rounded,
                    value: '38',
                    delta: SsDelta('9%', up: true),
                    spark: [3, 5, 4, 6, 5, 7, 8],
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: SsStatCard(
                    label: 'Ticket médio',
                    icon: Icons.sell_rounded,
                    value: r'R$ 484,70',
                    delta: SsDelta('3%', up: false),
                    spark: [6, 5.5, 6.2, 5.8, 5.1, 5.3, 4.9],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SsChipBar(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                for (final (i, nome, n) in const [(0, 'Todos', 48), (1, 'Com vencido', 6), (2, 'Sem compra', 11)])
                  SsFilterChip(nome, selected: filtro == i, count: n, onTap: () => setState(() => filtro = i)),
              ],
            ),
            const SsGroupHeader('Visitas de hoje', trailing: '3 de 5'),
            SsListItem(
              leading: const SsAvatar('Mercado Bom Preço', status: AppColors.success),
              title: 'Mercado Bom Preço',
              subtitle: 'Asa Sul · com pedido',
              value: r'R$ 1.250,00',
              valueCaption: '09:10',
              onTap: _nada,
            ),
            SsListItem(
              leading: const SsAvatar('Padaria Central'),
              title: 'Padaria Central',
              subtitle: 'Taguatinga · 14:00',
              value: 'agendada',
              valueColor: c.muted,
              onTap: _nada,
            ),
          ],
        ),
      ],
    );
  }
}
