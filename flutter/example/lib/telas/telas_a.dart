// Telas montadas da v0.9 (lote a): as peças novas junto com as que já existiam.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';

import '../catalogo/catalogo_v09_a.dart' show FakeQr;
import 'tela_demo.dart';

final telasA = <TelaDemo>[
  TelaDemo(
    'Explorar',
    'Cabeçalho curvo escuro com abas sublinhadas, sino e mosaico de categorias.',
    (_) => const _Explorar(),
    icone: Icons.explore_outlined,
  ),
  TelaDemo(
    'Carteira',
    'Cartão de saldo com reflexo, despesa × receita, recorrentes, cartões empilhados e barra com ação central.',
    (_) => const _Carteira(),
    icone: Icons.account_balance_wallet_outlined,
  ),
  TelaDemo(
    'Embarque',
    'Cartão de embarque com o avião no arco, QR numa folha e destaques da viagem.',
    (_) => const _Embarque(),
    icone: Icons.flight_takeoff_rounded,
  ),
  TelaDemo(
    'Boas-vindas',
    'Herói com palavra destacada e botão hexagonal; leva à apresentação ilustrada.',
    (_) => const _BoasVindas(),
    icone: Icons.waving_hand_outlined,
  ),
];

// ---------------------------------------------------------------- Explorar

class _Explorar extends StatefulWidget {
  const _Explorar();

  @override
  State<_Explorar> createState() => _ExplorarState();
}

class _ExplorarState extends State<_Explorar> {
  int aba = 1;
  int nav = 1;
  int avisos = 1;

  static const _atividades = [
    SsMosaicTile(title: 'Natureza', caption: '450 lugares', icon: Icons.park_outlined, wide: true, height: 150),
    SsMosaicTile(
      title: 'Cultura',
      caption: '257 lugares',
      icon: Icons.theater_comedy_outlined,
      height: 170,
      variant: 1,
    ),
    SsMosaicTile(title: 'Cidade', caption: '117 lugares', icon: Icons.location_city_outlined, height: 220, variant: 2),
    SsMosaicTile(title: 'Mirantes', caption: '357 lugares', icon: Icons.landscape_outlined, height: 220, variant: 3),
    SsMosaicTile(title: 'Sol e praia', caption: '147 lugares', icon: Icons.wb_sunny_outlined, height: 170, variant: 4),
  ];

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SsCurvedHeader(
            title: 'Explorar',
            tone: SsHeaderTone.dark,
            overlap: 24,
            leading: IconButton(
              tooltip: 'Voltar',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            actions: [
              SsBellDot(count: avisos, color: AppColors.onDark, onTap: () => setState(() => avisos++)),
              IconButton(tooltip: 'Buscar', onPressed: () {}, icon: const Icon(Icons.search_rounded)),
            ],
            bottom: SsTabsUnderline(
              tabs: const ['Descobrir', 'Atividades'],
              index: aba,
              onChanged: (i) => setState(() => aba = i),
              uppercase: true,
              onDark: true,
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: SsMotion.base,
              child: aba == 1
                  ? SingleChildScrollView(
                      key: const ValueKey('atividades'),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: SsMosaicGrid(
                        tiles: [
                          for (final t in _atividades)
                            SsMosaicTile(
                              title: t.title,
                              caption: t.caption,
                              icon: t.icon,
                              height: t.height,
                              variant: t.variant,
                              wide: t.wide,
                              background: t.wide ? SsTexture(color: AppColors.onDark.withValues(alpha: .12)) : null,
                              onTap: () => showSsToast(context, t.title),
                            ),
                        ],
                      ),
                    )
                  : ListView(
                      key: const ValueKey('descobrir'),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        Row(
                          spacing: 12,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SsFeatureTile(
                                icon: Icons.hiking_rounded,
                                title: 'Trilhas',
                                text: '38 perto de você',
                                onTap: () {},
                              ),
                            ),
                            Expanded(
                              child: SsFeatureTile(
                                icon: Icons.restaurant_rounded,
                                title: 'Comida local',
                                text: '112 lugares',
                                tone: AppColors.success,
                                onTap: () {},
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SsGoalCard(
                          icon: Icons.map_outlined,
                          text: 'Monte um roteiro com os lugares que você salvou.',
                          actionLabel: 'Montar roteiro',
                          onAction: () {},
                        ),
                        const SizedBox(height: 8),
                        SsGroupHeader('Perto de você', trailing: '3 lugares'),
                        for (final (n, d) in [
                          ('Mirante do Sol', '1,2 km'),
                          ('Feira da praça', '800 m'),
                          ('Museu do Rio', '2,4 km'),
                        ])
                          SsListItem(title: n, subtitle: d, icon: Icons.place_outlined, onTap: () {}),
                      ],
                    ),
            ),
          ),
        ],
      ),
      backgroundColor: c.page,
      bottomNavigationBar: SsNavBar(
        items: const [
          SsNavItem(Icons.flight_outlined, 'Viagens', activeIcon: Icons.flight_rounded),
          SsNavItem(Icons.explore_outlined, 'Explorar', activeIcon: Icons.explore_rounded),
          SsNavItem(Icons.bookmark_border_rounded, 'Salvos', activeIcon: Icons.bookmark_rounded),
          SsNavItem(Icons.person_outline_rounded, 'Perfil', activeIcon: Icons.person_rounded),
        ],
        currentIndex: nav,
        onTap: (i) => setState(() => nav = i),
      ),
    );
  }
}

// ---------------------------------------------------------------- Carteira

class _Carteira extends StatefulWidget {
  const _Carteira();

  @override
  State<_Carteira> createState() => _CarteiraState();
}

class _CarteiraState extends State<_Carteira> {
  int nav = 0;
  int lado = 0;
  final feitos = <int>{1};

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    Widget conta(String nome, String valor, IconData icone) => SsCard(
      child: Row(
        children: [
          SsIconTile(icone),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              nome,
              style: TextStyle(color: c.ink, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            valor,
            style: AppTheme.number(context, size: AppType.md, color: c.ink),
          ),
        ],
      ),
    );
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá, Ana',
                        style: TextStyle(color: c.ink, fontSize: AppType.headerTitle, fontWeight: FontWeight.w800),
                      ),
                      Text('Bom te ver de novo', style: TextStyle(color: c.muted)),
                    ],
                  ),
                ),
                SsBellDot(count: 3, showCount: true, onTap: () {}),
                const SizedBox(width: 4),
                const SsAvatar('Ana Souza', size: 40),
              ],
            ),
            const SizedBox(height: 20),
            const SsShimmerGlass(
              child: SsWalletCard(
                amount: r'R$ 10.000,00',
                holder: 'Ana Souza',
                number: '•••• 4086',
                network: 'Débito',
                expiry: '05/29',
              ),
            ),
            const SizedBox(height: 20),
            SsDuoStat(
              items: const [
                SsDuoItem('Despesas do mês', r'R$ 6.640,00', icon: Icons.arrow_upward_rounded),
                SsDuoItem('Receitas do mês', r'R$ 4.660,00', icon: Icons.arrow_downward_rounded),
              ],
              index: lado,
              onChanged: (i) => setState(() => lado = i),
            ),
            const SizedBox(height: 8),
            SsSectionHeader(
              'Recorrentes',
              action: TextButton(onPressed: () {}, child: const Text('Ver todos')),
            ),
            Row(
              spacing: 12,
              children: [
                for (final (i, (s, h, v, d)) in [
                  ('Todo domingo', '11:00', r'R$ 100,94', 'para Instituto Sol'),
                  ('Todo dia 5', '08:00', r'R$ 1.800', 'Aluguel'),
                ].indexed)
                  Expanded(
                    child: SsRecurringCard(
                      schedule: s,
                      time: h,
                      amount: v,
                      destination: d,
                      done: feitos.contains(i),
                      onTap: () => setState(() => feitos.contains(i) ? feitos.remove(i) : feitos.add(i)),
                      onMenu: () {},
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const SsSectionHeader('Contas', subtitle: 'Toque para abrir'),
            SsCardStack(
              cardHeight: 76,
              peek: 10,
              children: [
                conta('Conta corrente', r'R$ 9.560,94', Icons.account_balance_outlined),
                conta('Poupança', r'R$ 28.090,00', Icons.savings_outlined),
                conta('Viagem', r'R$ 1.200,00', Icons.luggage_outlined),
              ],
            ),
            const SizedBox(height: 8),
            const SsGroupHeader('Transações', trailing: 'Hoje'),
            for (final (n, cat, v, ic) in [
              ('Curso de desenho', 'Educação', r'-R$ 80,00', Icons.brush_outlined),
              ('Mercado do bairro', 'Mercado', r'-R$ 59,00', Icons.shopping_basket_outlined),
              ('Salário', 'Trabalho', r'R$ 2.844,50', Icons.work_outline_rounded),
            ])
              SsListItem(
                title: n,
                subtitle: cat,
                icon: ic,
                value: v,
                valueColor: v.startsWith('-') ? null : c.successText,
                onTap: () {},
              ),
          ],
        ),
      ),
      bottomNavigationBar: SsNavBar(
        items: const [
          SsNavItem(Icons.home_outlined, 'Início', activeIcon: Icons.home_rounded),
          SsNavItem(Icons.credit_card_outlined, 'Cartões', activeIcon: Icons.credit_card_rounded),
          SsNavItem(Icons.bar_chart_rounded, 'Relatórios'),
          SsNavItem(Icons.settings_outlined, 'Ajustes', activeIcon: Icons.settings_rounded),
        ],
        currentIndex: nav,
        onTap: (i) => setState(() => nav = i),
        center: SsNavCenter(
          Icons.add_rounded,
          label: 'Novo lançamento',
          onTap: () => showSsToast(context, 'Novo lançamento'),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Embarque

class _Embarque extends StatelessWidget {
  const _Embarque();

  void _qr(BuildContext context) => showSsSheet<void>(
    context,
    title: 'QR do embarque',
    child: const SsQrCard(
      title: 'Seu QR',
      qr: FakeQr(),
      instruction: 'Mostre no portão de embarque',
      footer: Row(
        children: [
          Expanded(
            child: Text(
              'Airbus A320',
              style: TextStyle(color: AppColors.onDark, fontWeight: FontWeight.w800),
            ),
          ),
          Text('Portão 4F', style: TextStyle(color: AppColors.onDarkSoft)),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SsCurvedHeader(
            title: 'Cartão de embarque',
            subtitle: 'Embarque em 1 h 20 min',
            overlap: 120,
            leading: IconButton(
              tooltip: 'Voltar',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            actions: [IconButton(tooltip: 'Compartilhar', onPressed: () {}, icon: const Icon(Icons.ios_share_rounded))],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                SsBoardingPass(
                  fromCode: 'GRU',
                  fromCity: 'São Paulo',
                  toCode: 'REC',
                  toCity: 'Recife',
                  departureDate: 'qui, 12 nov',
                  arrivalDate: 'qui, 12 nov',
                  departure: '20:50',
                  arrival: '23:55',
                  progress: .35,
                  fields: const [('Passageiro', 'Ana Souza'), ('Voo', 'MS 2050'), ('Assento', '24A'), ('Portão', '4F')],
                  footer: Row(
                    children: [
                      const SsShapeIcon(Icons.flight_rounded, shape: SsShape.hexagono, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Embarque até 20:20 · grupo 2',
                          style: TextStyle(color: c.ink2, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  onQr: () => _qr(context),
                ),
                const SizedBox(height: 20),
                Row(
                  spacing: 12,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SsFeatureTile(
                        icon: Icons.luggage_outlined,
                        title: 'Bagagem',
                        text: '1 mala de 23 kg',
                        onTap: () {},
                      ),
                    ),
                    Expanded(
                      child: SsFeatureTile(
                        icon: Icons.chair_outlined,
                        title: 'Sala de espera',
                        text: 'Piso 2, perto do portão',
                        tone: AppColors.success,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SsTicketCard(
                  top: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Traslado até o hotel',
                            style: TextStyle(color: c.ink, fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(r'R$ 64,00', style: AppTheme.number(context, color: c.ink)),
                      ],
                    ),
                  ),
                  bottom: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Motorista espera no desembarque, saída B', style: TextStyle(color: c.muted)),
                  ),
                  bottomColor: c.field,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Boas-vindas

class _BoasVindas extends StatelessWidget {
  const _BoasVindas();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SsHeroSplash(
          title: 'Seu dinheiro\ndo jeito mais\nsimples',
          highlight: 'dinheiro',
          text: 'Contas, cartões e metas num lugar só. Sem planilha, sem susto no fim do mês.',
          onAction: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const _Apresentacao())),
        ),
      ),
    );
  }
}

class _Apresentacao extends StatefulWidget {
  const _Apresentacao();

  @override
  State<_Apresentacao> createState() => _ApresentacaoState();
}

class _ApresentacaoState extends State<_Apresentacao> {
  int pagina = 0;

  static const _paginas = [
    (
      Icons.account_balance_wallet_outlined,
      'Tudo num lugar só',
      'Contas, cartões e dinheiro vivo somados num saldo que você entende.',
    ),
    (Icons.flag_outlined, 'Metas que andam', 'Separe parte do que entra e veja cada meta chegar mais perto.'),
    (Icons.notifications_active_outlined, 'Sem susto', 'Aviso antes de cada conta vencer, no celular e na web.'),
  ];

  @override
  Widget build(BuildContext context) {
    final (icone, titulo, texto) = _paginas[pagina];
    final ultima = pagina == _paginas.length - 1;
    return Scaffold(
      body: SsIllustratedSplit(
        art: EmptyIllustration(key: ValueKey(pagina), icon: icone, size: 200),
        title: titulo,
        text: texto,
        page: pagina,
        pages: _paginas.length,
        actionLabel: ultima ? 'Começar' : 'Continuar',
        onAction: () => ultima ? Navigator.of(context).maybePop() : setState(() => pagina++),
        secondaryLabel: ultima ? null : 'Pular',
        onSecondary: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}
