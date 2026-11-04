// Entradas do catálogo da v0.9 (lote a): fundação (paletas, gradiente de 4
// paradas, OLED, sombra colorida, vidro, brilho, textura, squircle),
// navegação, cards e herói.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo.dart';

void _nada() {}
Widget _pad(Widget w) => Padding(
  padding: const EdgeInsets.all(16),
  child: Center(child: w),
);
const _tela = Size(360, 720);

const _abas4 = [
  SsNavItem(Icons.home_outlined, 'Início', activeIcon: Icons.home_rounded),
  SsNavItem(Icons.pie_chart_outline_rounded, 'Relatórios', activeIcon: Icons.pie_chart_rounded),
  SsNavItem(Icons.credit_card_outlined, 'Cartões', activeIcon: Icons.credit_card_rounded),
  SsNavItem(Icons.person_outline_rounded, 'Perfil', activeIcon: Icons.person_rounded),
];

/// QR de mentira para o catálogo (o app passa o dele).
class FakeQr extends StatelessWidget {
  const FakeQr({super.key});

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _QrPainter(), child: const SizedBox.expand());
}

class _QrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const n = 25;
    final cell = size.width / n;
    final p = Paint()..color = AppColors.inkLight;
    final rnd = math.Random(11);
    bool finder(int x, int y) => (x < 7 || x >= n - 7) && y < 7 || x < 7 && y >= n - 7;
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        if (finder(x, y)) continue;
        if (rnd.nextDouble() < .48) canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), p);
      }
    }
    for (final (ox, oy) in [(0, 0), (n - 7, 0), (0, n - 7)]) {
      final o = Offset(ox * cell, oy * cell);
      canvas
        ..drawRect(o & Size(cell * 7, cell * 7), p)
        ..drawRect((o + Offset(cell, cell)) & Size(cell * 5, cell * 5), Paint()..color = AppColors.onDark)
        ..drawRect((o + Offset(cell * 2, cell * 2)) & Size(cell * 3, cell * 3), p);
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) => false;
}

/// Troca um valor logo depois do 1º quadro (para capturar a animação no meio).
class _Troca<T> extends StatefulWidget {
  const _Troca(this.inicio, this.fim, this.build);
  final T inicio;
  final T? fim;
  final Widget Function(T valor, ValueChanged<T> muda) build;

  @override
  State<_Troca<T>> createState() => _TrocaState<T>();
}

class _TrocaState<T> extends State<_Troca<T>> {
  late T v = widget.inicio;

  @override
  void initState() {
    super.initState();
    if (widget.fim != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => v = widget.fim as T);
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.build(v, (n) => setState(() => v = n));
}

Widget _swatches(SsBrand b, {double tam = 22}) => Builder(
  builder: (context) {
    final c = SsColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final k in b.gradientColors)
          Container(
            width: tam,
            height: tam,
            margin: EdgeInsets.only(right: tam / 6),
            decoration: BoxDecoration(
              color: k,
              borderRadius: BorderRadius.circular(tam / 3.5),
              border: Border.all(color: c.line),
            ),
          ),
      ],
    );
  },
);

Widget _comMarca(SsBrand b, Brightness br, Widget child, {bool oled = false}) => Theme(
  data: AppTheme.build(br, brand: b, oled: oled),
  child: child,
);

List<SsMosaicTile> _tiles() => const [
  SsMosaicTile(title: 'Natureza', caption: '450 lugares', icon: Icons.park_outlined, wide: true, height: 150),
  SsMosaicTile(title: 'Cultura', caption: '257 lugares', icon: Icons.theater_comedy_outlined, height: 170, variant: 1),
  SsMosaicTile(title: 'Cidade', caption: '117 lugares', icon: Icons.location_city_outlined, height: 220, variant: 2),
  SsMosaicTile(title: 'Mirantes', caption: '357 lugares', icon: Icons.landscape_outlined, height: 220, variant: 3),
  SsMosaicTile(title: 'Sol e praia', caption: '147 lugares', icon: Icons.wb_sunny_outlined, height: 170, variant: 4),
];

Widget _cartao(BuildContext context, String nome, String valor, int variante) {
  final cores = SsMosaicTile.colorsFor(SsColors.of(context), variante);
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: cores),
      borderRadius: BorderRadius.circular(AppRadius.cardActive),
      boxShadow: SsColors.of(context).tintedShadow(cores[1]),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nome,
          style: const TextStyle(color: AppColors.onDark, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        Text(valor, style: AppTheme.number(context, size: 24, color: AppColors.onDark)),
      ],
    ),
  );
}

final catalogoV09A = <Componente>[
  // ------------------------------------------------------------ fundação
  Componente(
    'ss-paletas',
    'SsBrand.paletas',
    'Paletas prontas como SsBrand (${SsPaleta.todas.length}, em ${SsPaleta.familias.length} famílias), as mesmas do Rails: '
        'geradas de paletas/paletas.json por paletas/gerar.py. O app passa em AppTheme.build(b, brand: SsBrand.marple).',
    comportamentos: [
      'SsBrand.paletas: mapa nome em pt-BR → marca, com a violeta primeiro e agrupado por família (seletor de aparência).',
      'SsPaleta.todas: a mesma lista com slug (o data-palette do Rails), nome, família e brand.',
      'Cada paleta define as 4 cores do gradiente (stops) e um accent ajustado para AA: texto da marca sobre página e superfície ≥ 4,5:1 no claro e no escuro, e texto branco sobre o botão no claro (gerar.py confere).',
      'brandFrom/brandTo/brandDeep seguem a paleta: aurora, confete e sombras mudam junto.',
    ],
    estados: [
      for (final br in [Brightness.light, Brightness.dark])
        Estado(
          br == Brightness.light ? 'todas-claro' : 'todas-escuro',
          br == Brightness.light ? 'todas as paletas no claro' : 'todas as paletas no escuro',
          (_) => Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in SsBrand.paletas.entries)
                  _comMarca(
                    e.value,
                    br,
                    Builder(
                      builder: (context) {
                        final c = SsColors.of(context);
                        return Container(
                          width: 165,
                          padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
                          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  e.key,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: c.accentText,
                                    fontSize: AppType.meta,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              _swatches(e.value, tam: 12),
                              const SizedBox(width: 4),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(7)),
                                child: const Icon(Icons.check_rounded, size: 14, color: AppColors.onDark),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          tamanho: const Size(360, 600),
        ),
    ],
  ),
  Componente(
    'ss-gradient4',
    'SsColors.gradient4',
    'Gradiente de 4 paradas da marca (SsBrand.gradient / SsColors.gradient4), da cor funda à clara, em 135°. Decorativo: fundo de herói, mosaico e cartão.',
    comportamentos: [
      'Paleta pronta usa as suas 4 cores; violeta e marcas dos produtos derivam de brandDeep → brandTo → brandFrom → accentDark.',
      'Nunca em texto ou botão (direção visual); texto por cima vai com véu escuro.',
    ],
    estados: [
      Estado(
        'paletas',
        'o gradiente de cada paleta',
        (_) => Padding(
          padding: const EdgeInsets.all(12),
          child: GridView.count(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (final e in SsBrand.paletas.entries)
                Container(
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: e.value.gradient,
                    borderRadius: BorderRadius.circular(AppRadius.field),
                  ),
                  child: Text(
                    e.key,
                    maxLines: 2,
                    style: const TextStyle(
                      color: AppColors.onDark,
                      fontSize: AppType.label,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      shadows: [Shadow(blurRadius: 6, color: AppColors.scrim)],
                    ),
                  ),
                ),
            ],
          ),
        ),
        tamanho: const Size(360, 630),
      ),
    ],
  ),
  Componente(
    'ss-oled',
    'AppTheme.build(oled: true)',
    'Modo escuro OLED: página preta pura e superfícies quase pretas (economiza bateria em tela OLED). SsColors.isOled fica verdadeiro.',
    comportamentos: [
      'Só vale no escuro: no claro o parâmetro é ignorado.',
      'Página #000, superfície e campo quase pretos; tinta, cinzas e marca são as do escuro (contraste AA conferido em teste).',
      'Os componentes que leem SsColors (surface, field, page, headerBg) mudam sozinhos.',
    ],
    estados: [
      Estado(
        'oled',
        'escuro comum × OLED',
        (_) => Row(
          children: [
            for (final oled in [false, true])
              Expanded(
                child: _comMarca(
                  SsBrand.violeta,
                  Brightness.dark,
                  oled: oled,
                  Builder(
                    builder: (context) {
                      final c = SsColors.of(context);
                      return Container(
                        color: c.page,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              oled ? 'OLED' : 'Escuro',
                              style: TextStyle(color: c.ink, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            const SsListItem(title: 'Mercado', subtitle: 'Hoje', icon: Icons.shopping_cart_outlined),
                            const SizedBox(height: 8),
                            SsButton(label: 'Salvar', onPressed: _nada),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
        tamanho: const Size(360, 200),
      ),
    ],
  ),
  Componente(
    'ss-tinted-shadow',
    'SsColors.tintedShadow',
    'Sombra na cor do próprio card (card colorido flutua na sua cor). Mais forte no escuro, onde a sombra preta some.',
    comportamentos: ['tintedShadow(cor, strength: 1): lista de BoxShadow para a decoração.'],
    estados: [
      Estado('cores', 'marca, sucesso e mosaico', (context) {
        final c = SsColors.of(context);
        Widget bloco(Color k) => Container(
          width: 84,
          height: 64,
          decoration: BoxDecoration(
            color: k,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: c.tintedShadow(k),
          ),
        );
        return _pad(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 18,
            children: [bloco(c.accent), bloco(AppColors.success), bloco(SsMosaicTile.colorsFor(c, 1)[1])],
          ),
        );
      }, tamanho: const Size(360, 130)),
    ],
  ),
  Componente(
    'ss-glass',
    'SsGlass',
    'Superfície de vidro (desfoque + véu claro + filete de luz na borda de cima), em 3 intensidades. Só em sobreposição ou herói, sobre foto ou gradiente; nunca em card de lista.',
    comportamentos: [
      'level: leve, medio (padrão) e forte: mais desfoque e mais véu.',
      'O filete de luz no topo some nas pontas.',
      'No escuro o véu usa a superfície escura em vez do branco.',
    ],
    estados: [
      Estado(
        'niveis',
        'leve, médio e forte sobre o gradiente',
        (context) => Container(
          decoration: BoxDecoration(gradient: SsColors.of(context).gradient4),
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Positioned.fill(child: SsTexture(color: AppColors.onDark.withValues(alpha: .2))),
              Row(
                spacing: 10,
                children: [
                  for (final l in SsGlassLevel.values)
                    Expanded(
                      child: SsGlass(
                        level: l,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.wb_sunny_outlined, color: AppColors.onDark),
                            const SizedBox(height: 18),
                            Text(
                              l.name,
                              style: const TextStyle(color: AppColors.onDark, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 150),
      ),
    ],
  ),
  Componente(
    'ss-glow',
    'SsGlow',
    'Brilho radial ambiente atrás de um filho (ação do herói, ícone de conquista). Não ocupa espaço e não recebe toque.',
    comportamentos: ['Sem cor, usa a da marca; spread diz quanto o brilho vaza; no escuro fica um pouco mais forte.'],
    estados: [
      Estado(
        'botao',
        'atrás de um ícone redondo',
        (context) => _pad(
          SsGlow(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: SsColors.of(context).accent, shape: BoxShape.circle),
              child: const Icon(Icons.bolt_rounded, color: AppColors.onDark, size: 32),
            ),
          ),
        ),
        tamanho: const Size(360, 150),
      ),
    ],
  ),
  Componente(
    'ss-texture',
    'SsTexture',
    'Textura sutil pintada (curvas de nível ou ruído fino) para ficar atrás de herói ou mosaico.',
    comportamentos: ['kind: topografia ou ruido; semente fixa (igual a cada pintura); cor padrão é a tinta a 7%.'],
    estados: [
      Estado(
        'tipos',
        'topografia e ruído',
        (_) => const Row(
          children: [
            Expanded(child: SsTexture()),
            Expanded(child: SsTexture(kind: SsTextureKind.ruido)),
          ],
        ),
        tamanho: const Size(360, 160),
      ),
    ],
  ),
  Componente(
    'ss-squircle',
    'SsSquircle / AppRadius.squircle',
    'Canto contínuo (squircle, estilo iOS): AppRadius.squircle(r) devolve o ContinuousRectangleBorder; SsSquircle é a superfície pronta.',
    comportamentos: ['O raio visual fica próximo de r (o ContinuousRectangleBorder pede ~2,3× o raio).'],
    estados: [
      Estado('formas', 'raio comum × squircle', (context) {
        final c = SsColors.of(context);
        return _pad(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 24,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(24)),
              ),
              SsSquircle(
                radius: 24,
                width: 88,
                height: 88,
                color: c.accentSoft,
                child: Icon(Icons.apps_rounded, color: c.accentText, size: 36),
              ),
            ],
          ),
        );
      }, tamanho: const Size(360, 140)),
    ],
  ),
  // ------------------------------------------------------------ navegação
  Componente(
    'ss-tabs-underline',
    'SsTabsUnderline',
    'Abas com traço embaixo que desliza e estica entre as abas. Versalete espaçado opcional; variante sobre fundo escuro.',
    comportamentos: [
      'Ao trocar, o traço viaja como minhoca (520 ms): a ponta da frente dispara, a de trás vem ~90 ms depois com mola; no meio cobre as duas abas e afina (3 → 2 px); ao chegar amassa (~8% mais largo) e assenta.',
      'Um rastro de brilho da marca (transparente → 35%) vai atrás da cabeça e apaga.',
      'O rótulo novo sobe 2 px e volta com mola enquanto passa para a cor da marca; o antigo apaga para o tom suave.',
      'Troca no meio continua de onde o traço está.',
      'uppercase: versalete com espaçamento largo; onDark: texto claro e traço na marca clara.',
      'Toque com haptic de seleção; sem animação com menos movimento.',
      'Não cabendo (muitas abas, nomes longos, fonte grande), a faixa rola na horizontal com cada aba na largura do nome; a escolhida vem para o meio da vista ao mudar. scrollable força um ou outro.',
      'icons: um ícone antes de cada nome (nulo na posição = sem ícone).',
    ],
    estados: [
      Estado(
        'versalete',
        'versalete, aba 2',
        (_) => _pad(
          SsTabsUnderline(tabs: const ['Descobrir', 'Atividades'], index: 1, onChanged: (_) {}, uppercase: true),
        ),
      ),
      Estado(
        'esticando',
        'da 1 para a 3: traço esticado',
        (_) => _pad(
          _Troca<int>(
            0,
            2,
            (v, muda) => SsTabsUnderline(tabs: const ['Tudo', 'Entradas', 'Saídas'], index: v, onChanged: muda),
          ),
        ),
        aguarde: 140,
      ),
      Estado(
        'escuro',
        'onDark, dentro de cabeçalho',
        (context) => Container(
          color: SsCurvedHeader.background(context, SsHeaderTone.dark),
          padding: const EdgeInsets.all(16),
          child: SsTabsUnderline(tabs: const ['Dia', 'Semana', 'Mês'], index: 0, onChanged: (_) {}, onDark: true),
        ),
      ),
      Estado(
        'icones',
        'icons: ícone antes de cada nome',
        (_) => _pad(
          SsTabsUnderline(
            tabs: const ['Painel', 'Câmeras', 'Energia'],
            icons: const [Icons.dashboard_outlined, Icons.videocam_outlined, Icons.bolt_rounded],
            index: 1,
            onChanged: (_) {},
          ),
        ),
      ),
      Estado(
        'rolavel',
        'muitas abas: a faixa rola e a escolhida (6ª) vem para a vista',
        (_) => _pad(
          SsTabsUnderline(
            tabs: const ['Sala', 'Cozinha', 'Quarto', 'Escritório', 'Varanda', 'Garagem', 'Lavanderia', 'Jardim'],
            index: 5,
            onChanged: (_) {},
          ),
        ),
        aguarde: 600,
      ),
    ],
  ),
  Componente(
    'ss-curved-header',
    'SsCurvedHeader',
    'Cabeçalho escuro (cor funda da marca ou superfície escura) que termina em curva côncava; o conteúdo sobe por cima. Aceita título, voltar, ações e um filho embaixo (segmented, abas).',
    comportamentos: [
      'tone: brand (cor funda da marca) ou dark (headerBg); texto sempre claro (AA).',
      'O fundo vaza overlap px para baixo, por trás do conteúdo, e fecha em curva.',
      'Soma a área segura de cima (safeTop).',
    ],
    estados: [
      for (final tone in SsHeaderTone.values)
        Estado(
          tone.name,
          tone == SsHeaderTone.brand ? 'marca, com segmented e cards por cima' : 'escuro, só título e ações',
          (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SsCurvedHeader(
                title: 'Minhas tarefas',
                tone: tone,
                leading: IconButton(onPressed: _nada, icon: const Icon(Icons.arrow_back_rounded), tooltip: 'Voltar'),
                actions: [const SsBellDot(count: 2, color: AppColors.onDark)],
                bottom: tone == SsHeaderTone.brand
                    ? SsSegmented(
                        segments: const [(0, 'Dia'), (1, 'Semana'), (2, 'Mês')],
                        value: 1,
                        onChanged: (_) {},
                        onDark: true,
                      )
                    : null,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SsListItem(title: 'Revisar orçamento', subtitle: 'Hoje, 10:00', icon: Icons.task_alt_rounded),
              ),
            ],
          ),
          tamanho: Size(360, tone == SsHeaderTone.brand ? 260 : 200),
        ),
    ],
  ),
  Componente(
    'ss-segmented-on-dark',
    'SsSegmented(onDark: true)',
    'Variante embutida do SsSegmented para dentro de cabeçalho escuro: trilha clara translúcida, pílula branca e texto claro.',
    comportamentos: ['A opção escolhida fica em texto da marca sobre a pílula branca (AA); as outras em claro suave.'],
    estados: [
      Estado(
        'escuro',
        'sobre o cabeçalho',
        (context) => Container(
          color: SsCurvedHeader.background(context, SsHeaderTone.brand),
          padding: const EdgeInsets.all(16),
          child: SsSegmented(
            segments: const [(0, 'Gastos'), (1, 'Receitas')],
            value: 0,
            onChanged: (_) {},
            onDark: true,
          ),
        ),
      ),
    ],
  ),
  Componente(
    'ss-nav-bar-centro',
    'SsNavBar(center:)',
    'SsNavBar com ação central elevada: botão redondo na cor da marca, sombra na própria cor, encaixado num recorte fixo no meio da barra.',
    comportamentos: [
      'center: SsNavCenter(ícone, onTap, label); o botão não é aba, só chama onTap (com haptic e encolhe ao toque).',
      'As abas se dividem metade à esquerda e metade à direita (use 2 ou 4).',
      'O círculo da aba atual pula por cima do botão ao trocar de lado; o recorte que anda some perto do recorte fixo.',
      'Leitor de tela lê o label do botão.',
    ],
    estados: [
      for (final i in [0, 2])
        Estado(
          'aba-$i',
          i == 0 ? 'aba 1 com o botão central' : 'aba 3 (do outro lado)',
          (_) => Scaffold(
            extendBody: true,
            body: const SizedBox.expand(),
            bottomNavigationBar: SsNavBar(
              items: _abas4,
              currentIndex: i,
              onTap: (_) {},
              center: const SsNavCenter(Icons.add_rounded, onTap: _nada, label: 'Novo lançamento'),
            ),
          ),
          tamanho: const Size(360, 160),
        ),
    ],
  ),
  Componente(
    'ss-side-rail',
    'SsSideRail',
    'Trilho lateral vertical (tablet, painel): o item ativo abre um recorte curvo na borda do trilho e fica num círculo encaixado nele.',
    comportamentos: [
      'O círculo estica na vertical como gota até o item novo, passa do ponto e assenta com mola; o recorte acompanha e o ícone novo entra pulando.',
      'Topo e rodapé opcionais (logo, configurações), na cor do trilho.',
      'Cada item tem dica e leitura de tela com o nome.',
    ],
    estados: [
      Estado(
        'ativo',
        'item 2 ativo',
        (_) => Row(
          children: [
            SsSideRail(
              items: _abas4,
              currentIndex: 1,
              onTap: (_) {},
              header: const Icon(Icons.menu_rounded),
              footer: const Icon(Icons.settings_outlined),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
        tamanho: const Size(360, 400),
      ),
    ],
  ),
  Componente(
    'ss-bell-dot',
    'SsBellDot',
    'Ícone (sino) com ponto de notificação que pulsa uma vez quando chega contagem nova.',
    comportamentos: [
      'count > 0 mostra o ponto; showCount põe o número (até 99+).',
      'Quando count sobe, o ponto cresce e solta um anel uma vez; com menos movimento, só aparece.',
      'Alvo de 48 dp; leitor de tela: "Notificações: 3 novas".',
    ],
    estados: [
      Estado(
        'estados',
        'sem nada, ponto e com número',
        (_) => _pad(
          const Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [SsBellDot(), SsBellDot(count: 1), SsBellDot(count: 12, showCount: true)],
          ),
        ),
      ),
      Estado(
        'pulsando',
        'de 2 para 3: o pulso',
        (_) => _pad(_Troca<int>(2, 3, (v, _) => SsBellDot(count: v))),
        aguarde: 180,
      ),
    ],
  ),
  Componente(
    'ss-count-tabs',
    'SsCountTabs',
    'Abas de categoria com o contador num círculo em cima do rótulo; a atual tem o círculo cheio na marca.',
    comportamentos: [
      'O círculo cheio desliza até a aba nova esticando no caminho, e o número pula ao chegar; sombra na cor da marca.',
      'Rola na horizontal quando não cabe; alvo mínimo 48 dp.',
    ],
    estados: [
      Estado(
        'pendentes',
        '"Pendentes" escolhida',
        (_) => Center(
          child: SsCountTabs(
            tabs: const [('Todas', 24), ('Pendentes', 8), ('Feitas', 14), ('Atrasadas', 2)],
            index: 1,
            onChanged: (_) {},
          ),
        ),
        tamanho: const Size(360, 110),
      ),
    ],
  ),
  Componente(
    'ss-step-top-bar',
    'SsStepTopBar',
    'Barra de topo de fluxo em tela cheia: "3 / 4" em DM Mono, Cancelar e uma barrinha de progresso.',
    comportamentos: [
      'A barrinha anda como minhoca (SsWormProgress): a cabeça passa do ponto com uma faísca e o corpo alcança.',
      'O número novo pula (0,6 → 1,15 → 1) e solta um anel da marca que se abre e apaga.',
      'onBack opcional mostra a seta de voltar; leitor de tela lê "Passo 3 de 4".',
    ],
    estados: [
      Estado(
        'passo-3',
        'passo 3 de 4',
        (_) => const Align(
          alignment: Alignment.topCenter,
          child: SsStepTopBar(step: 3, total: 4, onCancel: _nada),
        ),
      ),
    ],
  ),
  // ------------------------------------------------------------ cards
  Componente(
    'ss-mosaic-grid',
    'SsMosaicGrid / SsMosaicTile',
    'Grade masonry de 2 colunas com alturas variadas; cada bloco no gradiente da marca (tom deslocado por variant), com imagem opcional por baixo, ícone de traço, título e contador em versalete.',
    comportamentos: [
      'Cada bloco vai para a coluna mais baixa; bloco wide ocupa as duas e realinha.',
      'Os blocos entram em cascata (SsReveal) e encolhem ao toque.',
      'Véu escuro embaixo: o texto claro passa AA mesmo em tom claro.',
      'Sombra na cor do bloco; a altura cresce com a fonte grande.',
    ],
    estados: [
      Estado(
        'grade',
        'cinco blocos, o primeiro largo',
        (_) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SsMosaicGrid(tiles: _tiles()),
        ),
        tamanho: const Size(360, 620),
        aguarde: 800,
      ),
    ],
  ),
  Componente(
    'ss-ticket-card',
    'SsTicketCard',
    'Card de ingresso: duas seções separadas por um picote tracejado com recortes semicirculares nas laterais, exatamente na altura do picote. Badge opcional num recorte maior à direita.',
    comportamentos: [
      'O recorte acompanha a altura real da seção de cima (layout próprio, sem medir depois).',
      'A sombra segue o contorno recortado; no escuro, borda de 1 px.',
      'bottomColor muda a cor só da seção de baixo.',
    ],
    estados: [
      Estado('simples', 'recibo com duas seções', (context) {
        final c = SsColors.of(context);
        return _pad(
          SsTicketCard(
            top: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Jantar da equipe',
                      style: TextStyle(color: c.ink, fontWeight: FontWeight.w800, fontSize: AppType.md),
                    ),
                  ),
                  Text(
                    r'R$ 750,86',
                    style: AppTheme.number(context, size: AppType.md, color: c.ink),
                  ),
                ],
              ),
            ),
            bottom: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  SsAvatarStack(['Ana Souza', 'Caio Lima', 'Lia Reis']),
                ],
              ),
            ),
            bottomColor: c.field,
          ),
        );
      }, tamanho: const Size(360, 170)),
    ],
  ),
  Componente(
    'ss-boarding-pass',
    'SsBoardingPass',
    'Cartão de embarque: códigos grandes de origem e destino ligados por um arco tracejado com o avião na posição progress, cidades, horários, grade de campos e o botão do QR no picote.',
    comportamentos: [
      'progress (0–1) anima o avião pelo arco; o trecho percorrido fica cheio na cor da marca, o resto tracejado.',
      'O avião gira acompanhando a tangente do arco.',
      'onQr mostra o botão redondo encaixado no recorte da direita (sombra na cor da marca).',
      'Leitor de tela: "Voo de GRU para REC, 40% do trajeto".',
    ],
    estados: [
      Estado(
        'em-voo',
        'a 40% do trajeto',
        (context) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SsBoardingPass(
            fromCode: 'GRU',
            fromCity: 'São Paulo',
            toCode: 'REC',
            toCity: 'Recife',
            departureDate: 'qui, 12 nov',
            arrivalDate: 'qui, 12 nov',
            departure: '20:50',
            arrival: '23:55',
            progress: .4,
            fields: const [('Passageiro', 'Ana Souza'), ('Voo', 'MS 2050'), ('Assento', '24A'), ('Portão', '4F')],
            footer: Text('Embarque até 20:20', style: TextStyle(color: SsColors.of(context).muted)),
            onQr: _nada,
          ),
        ),
        tamanho: const Size(360, 470),
        aguarde: 1000,
      ),
    ],
  ),
  Componente(
    'ss-wallet-card',
    'SsWalletCard',
    'Cartão de saldo no gradiente de 4 paradas da marca, sombra na própria cor, leve inclinação 3D por tilt e brilho que acompanha.',
    comportamentos: [
      'tilt (−1 a 1) vem do giroscópio que o app liga (sem plugin no pacote); a inclinação e o brilho seguem suave (160 ms).',
      'Véu escuro por baixo do texto: AA em qualquer paleta.',
      'Valor em DM Mono com centavos menores, encolhe para caber.',
    ],
    estados: [
      Estado(
        'reto',
        'sem inclinação',
        (_) => _pad(
          const SsWalletCard(
            amount: r'R$ 10.000,00',
            holder: 'Ana Souza',
            number: '•••• 4086',
            network: 'Débito',
            expiry: '05/29',
          ),
        ),
        tamanho: const Size(360, 260),
      ),
      Estado(
        'inclinado',
        'tilt (0,6; −0,4)',
        (_) => _pad(
          const SsWalletCard(amount: r'R$ 2.844,50', holder: 'Ana Souza', number: '•••• 8609', tilt: Offset(.6, -.4)),
        ),
        tamanho: const Size(360, 260),
      ),
    ],
  ),
  Componente(
    'ss-card-stack',
    'SsCardStack',
    'Cartões empilhados (só a borda dos de trás aparece) que se abrem em lista com mola ao tocar.',
    comportamentos: [
      'Toque abre (mola com leve passada) e fecha (rápido); haptic de seleção.',
      'Os de trás ficam menores e mais apagados; o 4º em diante some na pilha.',
      'Leitor de tela: "Abrir 3 cartões" / "Fechar cartões".',
    ],
    estados: [
      for (final aberto in [false, true])
        Estado(
          aberto ? 'aberta' : 'fechada',
          aberto ? 'aberta em lista' : 'fechada (pilha)',
          (context) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SsCardStack(
              initiallyOpen: aberto,
              cardHeight: 120,
              children: [
                _cartao(context, 'Conta corrente', r'R$ 9.560,94', 0),
                _cartao(context, 'Poupança', r'R$ 28.090,00', 2),
                _cartao(context, 'Viagem', r'R$ 1.200,00', 4),
              ],
            ),
          ),
          tamanho: Size(360, aberto ? 450 : 200),
        ),
    ],
  ),
  Componente(
    'ss-status-tab-card',
    'SsStatusTabCard',
    'Card de tarefa com aba de status no topo à esquerda (recorte em S), avatares e progresso no topo à direita, ícone em losango, título, subtítulo e menu.',
    comportamentos: [
      'tone é a cor do status: o card fica no tom a 20% (26% no escuro), texto na tinta do tema.',
      'A barra de progresso cresce ao aparecer.',
      'Encolhe ao toque; menu ⋮ com dica.',
    ],
    estados: [
      Estado(
        'status',
        'concluída e em andamento',
        (context) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            spacing: 14,
            children: [
              SsStatusTabCard(
                status: 'Concluída',
                tone: AppColors.success,
                title: 'Site novo',
                subtitle: 'Projeto do cliente',
                people: const ['Ana Souza', 'Caio Lima', 'Lia Reis'],
                progress: 1,
                onMenu: _nada,
              ),
              SsStatusTabCard(
                status: 'Andamento',
                title: 'Pesquisa de mercado',
                subtitle: 'Tarefa da empresa',
                people: const ['Rui Prado', 'Bia Melo'],
                progress: .72,
                onMenu: _nada,
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 330),
        aguarde: 900,
      ),
    ],
  ),
  Componente(
    'ss-shape-icon',
    'SsShapeIcon',
    'Ícone dentro de losango ou hexágono de cantos arredondados, tonal ou cheio.',
    comportamentos: [
      'Sem cor, usa a marca; tonal = cor a 14% (22% no escuro) e ícone na cor; filled = cheio e ícone claro.',
    ],
    estados: [
      Estado(
        'formas',
        'losango e hexágono, tonal e cheio',
        (_) => _pad(
          const Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 14,
            children: [
              SsShapeIcon(Icons.checklist_rounded),
              SsShapeIcon(Icons.checklist_rounded, filled: true),
              SsShapeIcon(Icons.bolt_rounded, shape: SsShape.hexagono),
              SsShapeIcon(Icons.arrow_forward_rounded, shape: SsShape.hexagono, filled: true),
            ],
          ),
        ),
      ),
    ],
  ),
  Componente(
    'ss-pop-out-card',
    'SsPopOutCard',
    'Card de produto em que a imagem vaza acima da borda; nome, detalhe, preço em DM Mono e botão de adicionar.',
    comportamentos: [
      'popOut diz quanto a imagem passa da borda; tone deixa o card tonal.',
      'Botão de 48 dp com sombra na cor da marca; card encolhe ao toque.',
    ],
    estados: [
      Estado(
        'dois',
        'dois produtos lado a lado',
        (context) => Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (nome, preco, ic, tom) in [
                ('Monstera', r'R$ 89,90', Icons.local_florist_rounded, AppColors.success),
                ('Cacto mini', r'R$ 24,50', Icons.spa_rounded, null),
              ])
                Expanded(
                  child: SsPopOutCard(
                    image: Icon(ic, size: 110, color: tom ?? SsColors.of(context).accent),
                    title: nome,
                    subtitle: 'Planta de interior',
                    price: preco,
                    tone: tom,
                    onAdd: _nada,
                  ),
                ),
            ],
          ),
        ),
        tamanho: const Size(360, 290),
      ),
    ],
  ),
  Componente(
    'ss-duo-stat',
    'SsDuoStat',
    'Duas estatísticas lado a lado; a ativa tem fundo no gradiente da marca e texto claro. Tocar na outra troca.',
    comportamentos: [
      'A troca anima o fundo e gira a seta da ativa com mola; haptic de seleção.',
      'Valores em DM Mono que encolhem para caber.',
    ],
    estados: [
      Estado(
        'despesa',
        'despesa ativa',
        (_) => _pad(
          SsDuoStat(
            items: const [
              SsDuoItem('Despesas', r'R$ 6.640', icon: Icons.arrow_upward_rounded),
              SsDuoItem('Receitas', r'R$ 4.660', icon: Icons.arrow_downward_rounded),
            ],
            index: 0,
            onChanged: (_) {},
          ),
        ),
        tamanho: const Size(360, 110),
      ),
    ],
  ),
  Componente(
    'ss-goal-card',
    'SsGoalCard',
    'Card de meta ou convite: ilustração (ou ícone grande com brilho), texto curto centrado e ação em texto sublinhado na cor da marca.',
    comportamentos: ['art recebe a ilustração do app; sem ela, ícone grande na marca.'],
    estados: [
      Estado(
        'meta',
        'convite para criar meta',
        (_) => _pad(
          const SsGoalCard(
            icon: Icons.change_history_rounded,
            text: 'Separe parte do que entra para chegar às suas metas',
            actionLabel: 'Criar meta',
            onAction: _nada,
          ),
        ),
        tamanho: const Size(360, 270),
      ),
    ],
  ),
  Componente(
    'ss-qr-card',
    'SsQrCard',
    'Card do QR: área sempre branca (para a câmera ler) com o QR que o app passa como widget ou bytes, instrução e rodapé. Sem plugin.',
    comportamentos: [
      'O fundo é a cor da marca (ou tone) com texto claro; a área do QR é quadrada e limitada a 240 px.',
    ],
    estados: [
      Estado(
        'embarque',
        'QR do embarque',
        (_) => const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: SsQrCard(title: 'Seu QR', qr: FakeQr(), instruction: 'Mostre no portão de embarque'),
        ),
        tamanho: const Size(360, 420),
      ),
    ],
  ),
  Componente(
    'ss-recurring-card',
    'SsRecurringCard',
    'Lançamento recorrente: "Todo domingo · 11:00", valor em DM Mono, destino e um check redondo.',
    comportamentos: ['done: o check enche de verde com mola (feito neste ciclo).'],
    estados: [
      Estado(
        'dois',
        'pendente e feito',
        (_) => const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                child: SsRecurringCard(
                  schedule: 'Todo domingo',
                  time: '11:00',
                  amount: r'R$ 100,94',
                  destination: 'para Instituto Sol',
                  onMenu: _nada,
                ),
              ),
              Expanded(
                child: SsRecurringCard(
                  schedule: 'Todo dia 5',
                  time: '08:00',
                  amount: r'R$ 1.800',
                  destination: 'Aluguel',
                  done: true,
                  onMenu: _nada,
                ),
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 180),
      ),
    ],
  ),
  Componente(
    'ss-feature-tile',
    'SsFeatureTile',
    'Card de destaque com fundo tonal na cor e ícone num círculo elevado, título e texto.',
    comportamentos: ['Sem tone, usa a marca; o círculo tem sombra na mesma cor; encolhe ao toque.'],
    estados: [
      Estado(
        'dois',
        'marca e sucesso',
        (_) => const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SsFeatureTile(icon: Icons.lightbulb_outline_rounded, title: 'Luzes', text: '4 ligadas'),
              ),
              Expanded(
                child: SsFeatureTile(
                  icon: Icons.water_drop_outlined,
                  title: 'Rega',
                  text: 'Amanhã, 7:00',
                  tone: AppColors.success,
                ),
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 190),
      ),
    ],
  ),
  // ------------------------------------------------------------ herói
  Componente(
    'ss-hero-splash',
    'SsHeroSplash',
    'Abertura: título enorme com uma palavra destacada na cor da marca, ornamento de anéis em linha, texto curto e a ação com brilho.',
    comportamentos: [
      'highlight pinta a 1ª ocorrência do trecho no título (texto da marca, AA).',
      'Título, texto e ação entram em cascata.',
      'Com actionLabel, botão largo com brilho; sem, botão hexagonal com seta (SsHexButton).',
    ],
    estados: [
      Estado(
        'hexagono',
        'com botão hexagonal',
        (_) => const SsHeroSplash(
          title: 'Seu dinheiro\ndo jeito mais\nsimples',
          highlight: 'dinheiro',
          text: 'Contas, cartões e metas num lugar só, sem planilha.',
          onAction: _nada,
        ),
        tamanho: _tela,
        aguarde: 800,
      ),
      Estado(
        'botao',
        'com botão largo',
        (_) => const SsHeroSplash(
          title: 'Cuide do seu jardim',
          highlight: 'jardim',
          text: 'Lembretes de rega e luz para cada planta.',
          actionLabel: 'Começar',
          onAction: _nada,
        ),
        tamanho: const Size(360, 520),
        aguarde: 800,
      ),
    ],
  ),
  Componente(
    'ss-hex-button',
    'SsHexButton',
    'Botão hexagonal na cor da marca com seta e brilho (ação do herói).',
    comportamentos: ['Encolhe a 0,92 ao toque com haptic; leitor de tela lê o label ("Começar").'],
    estados: [
      Estado('padrao', 'com brilho', (_) => _pad(const SsHexButton(onTap: _nada)), tamanho: const Size(360, 150)),
    ],
  ),
  Componente(
    'ss-illustrated-split',
    'SsIllustratedSplit',
    'Apresentação com ilustração em cima (fundo tonal da marca) e painel embaixo que sobe numa curva, com título, texto, ação e pontinhos de página.',
    comportamentos: ['O pontinho atual alarga com mola.', 'Respeita a área segura de cima e de baixo.'],
    estados: [
      Estado(
        'pagina-1',
        'página 1 de 3',
        (_) => const SsIllustratedSplit(
          art: EmptyIllustration(icon: Icons.local_florist_outlined, size: 180),
          title: 'Plantas felizes',
          text: 'Saiba quando regar, adubar e mudar de vaso.',
          actionLabel: 'Continuar',
          onAction: _nada,
          secondaryLabel: 'Pular',
          onSecondary: _nada,
          page: 0,
          pages: 3,
        ),
        tamanho: _tela,
      ),
    ],
  ),
  Componente(
    'ss-hero-flight',
    'SsHeroFlight',
    'Hero da imagem do produto da lista para o detalhe: mesma tag nas duas telas; no voo a imagem cresce com leve passada e pousa.',
    comportamentos: [
      'flightShuttleBuilder próprio (SsHeroFlight.shuttle): escala 1 → 1,06 → 1 durante o voo.',
      'Com menos movimento, voa sem o passo extra.',
      'Na captura aparece parado (o voo só existe na troca de tela).',
    ],
    estados: [
      Estado(
        'lista',
        'imagem na lista, pronta para voar',
        (context) => _pad(
          SsCard(
            child: Row(
              children: [
                SsHeroFlight(
                  tag: 'monstera',
                  child: SsSquircle(
                    width: 64,
                    height: 64,
                    color: SsColors.of(context).accentSoft,
                    child: Icon(Icons.local_florist_rounded, color: SsColors.of(context).accentText, size: 36),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text('Monstera', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
        tamanho: const Size(360, 130),
      ),
    ],
  ),
  Componente(
    'ss-shimmer-glass',
    'SsShimmerGlass',
    'Reflexo diagonal que passa uma vez sobre o filho ao aparecer (cartão novo, prêmio, saldo carregado).',
    comportamentos: [
      'Passa uma vez (150 ms de espera + 1,1 s); trocar trigger faz passar de novo.',
      'Com menos movimento, não passa.',
    ],
    estados: [
      Estado(
        'passando',
        'no meio da passagem',
        (_) => _pad(
          const SsShimmerGlass(
            child: SsWalletCard(amount: r'R$ 10.000,00', holder: 'Ana Souza', number: '•••• 4086'),
          ),
        ),
        tamanho: const Size(360, 260),
        aguarde: 700,
      ),
    ],
  ),
];
