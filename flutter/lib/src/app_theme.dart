import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'density.dart';

part 'paletas.g.dart';

/// Design system "Lista Clara" da MinhaSuite. A cor da marca vem de [SsBrand]
/// (padrão: violeta `#5A45E8`); o resto dos tokens é igual em todos os apps. Tokens por tema em [AppColors], forma em [AppRadius]/[AppShadows],
/// tipografia em [AppType]. Os `ColorScheme` são montados à mão (NÃO `fromSeed`)
/// para reproduzir as superfícies exatas, não os tons derivados do Material 3.
///
/// Regras que valem para a UI inteira:
/// - **Cor é semântica.** `danger`/`dangerSoft`/`dangerBorder` só em erro e
///   exclusão; `success` em conclusão/PR; `warnFg`/`aquec*` em aquecimento e
///   avisos. Cor decorativa (gráfico, confete) sai de [AppColors.series],
/// - **Ícones**: família única (Material). Outlined é o padrão; a variante
///   cheia/rounded marca estado ativo ou concluído (aba selecionada, check).
/// - **Números** usam [AppTheme.number] (DM Mono + tabular) para não dançarem
///   quando o valor muda.
class AppColors {
  const AppColors._();

  // ---- Claro ----
  static const inkLight = Color(0xFF1E2233);
  static const ink2Light = Color(0xFF3D4256);
  // Escurecido de #9096AC para passar AA (4,5:1) sobre o branco e o fundo.
  static const mutedLight = Color(0xFF636981);
  static const muted2Light = Color(0xFFC2C6D6);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const fieldLight = Color(0xFFF4F5FA);
  static const pageLight = Color(0xFFEEF0F6);
  static const lineLight = Color(0x14141628); // rgba(20,22,40,.08)

  // ---- Escuro ----
  static const inkDark = Color(0xFFF2F3FB);
  static const ink2Dark = Color(0xFFCDD0E0);
  static const mutedDark = Color(0xFF9AA0BD);
  static const muted2Dark = Color(0xFF5A5F78);
  static const surfaceDark = Color(0xFF171925);
  static const fieldDark = Color(0xFF23273A);
  static const pageDark = Color(0xFF0F1017);
  static const lineDark = Color(0x14FFFFFF); // rgba(255,255,255,.08)

  // ---- Escuro OLED (página preta pura; superfícies quase pretas) ----
  static const pageOled = Color(0xFF000000);
  static const surfaceOled = Color(0xFF0B0B10);
  static const fieldOled = Color(0xFF17171F);
  static const headerOledBg = Color(0xFF07070A);

  // ---- Fixos nos dois temas ----
  static const headerLine = Color(0xFF2C3040);
  static const success = Color(0xFF22C483);
  static const danger = Color(0xFFE05A6B);
  static const warnFg = Color(0xFFFFD07A);
  static const warnBg = Color(0xFF3A3420);
  static const aquecFg = Color(0xFFE0952A);
  static const aquecBg = Color(0xFFFBEED3);
  static const onDark = Color(0xFFFFFFFF);
  static const onDarkMuted = Color(0xFF9FA3BD);

  /// Texto secundário claro sobre gradiente/cor da marca (85% de branco).
  static const onDarkSoft = Color(0xD9FFFFFF);

  /// Véu escuro para texto claro sobre foto ou gradiente (base dos degradês).
  static const scrim = Color(0xFF000000);

  /// Tinta das sombras pintadas à mão (drawShadow).
  static const shadowInk = Color(0xFF141628);

  /// v0.19.1: nenhuma cor (preto a 0%). Borda ou fundo que some no estado não
  /// selecionado (`selected ? c.accentSoft : AppColors.transparent`), sem o
  /// `Colors.transparent` do Material no produto.
  static const transparent = Color(0x00000000);

  // Ícones/labels sobre header e sheets escuros (contraste AA sobre #1C1F2B).
  static const onDarkIcon = Color(0xFFC9CBE0);

  // Erro: borda do bloco de mensagem (danger a 30%). O fundo usa `dangerSoft`.
  static const dangerBorder = Color(0x4DE05A6B);

  /// Paleta de séries para gráficos/confete. Cores decorativas ficam AQUI,
  /// nunca soltas na tela — e nenhuma delas é o vermelho de erro.
  static const series = <Color>[
    Color(0xFF7B5CFF), // roxo da marca
    Color(0xFF3B82F6),
    Color(0xFFFF8A4C), // laranja
    Color(0xFF1BA06A), // verde
    Color(0xFFF4B740), // amarelo
    Color(0xFFEC5A8D), // rosa
  ];

  // Headers/sheets são escuros MESMO no tema claro (cara de app nativo).
  static const headerLightBg = Color(0xFF1C1F2B);
  static const headerDarkBg = Color(0xFF12141C);
  static const sheetBg = Color(0xFF12141C);

  // Fundos "soft" derivados (rgba de constantes) — usados em badges/stat icons.
  static Color successSoft = const Color(0x2622C483); // .15
  static Color dangerSoft = const Color(0x26E05A6B); // .15
  static Color ghostSoft = const Color(0x249096AC); // .14
}

/// Mistura [a] com [t] de [b] (0 = [a], 1 = [b]), em sRGB como o
/// `color-mix(in srgb, …)` do CSS (v0.13). Para derivar um tom de uma cor que
/// veio de fora (tema do usuário) sem escrever cor solta na tela:
/// `ssMix(cor, AppColors.scrim, .14)` = 14% mais escura.
Color ssMix(Color a, Color b, double t) => Color.lerp(a, b, t.clamp(0.0, 1.0))!;

/// Contraste WCAG entre duas cores (1 a 21): 4,5 é o AA de texto, 3 o de
/// ícone e borda, 7 o AAA (v0.16).
double ssContrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + .05) / (math.min(la, lb) + .05);
}

/// [color] puxada para [toward] em passos de 5% até passar [min]:1 sobre
/// todos os [over] (a mesma conta do `paletas/gerar.py`). Já passando, volta
/// a própria cor.
Color ssUntilContrast(Color color, Color toward, List<Color> over, double min) {
  for (var i = 0; i <= 20; i++) {
    final c = ssMix(color, toward, i / 20);
    if (over.every((b) => ssContrast(c, b) >= min)) return c;
  }
  return toward;
}

/// Cor da marca do produto. Vai no `ThemeData.extensions` (ver [AppTheme.build])
/// e os `Ss*` leem daqui; o resto da paleta é comum à suíte.
@immutable
class SsBrand extends ThemeExtension<SsBrand> {
  const SsBrand({
    required this.accentLight,
    required this.accentHoverLight,
    required this.accentSoftLight,
    required this.accentDark,
    required this.accentSoftDark,
    required this.brandFrom,
    required this.brandTo,
    required this.brandDeep,
    this.stops,
    Color? accentSolidLight,
    Color? accentSolidDark,
    // Parâmetro nomeado não pode ser privado: por isso não é this._accentSolid*.
  })
    // ignore: prefer_initializing_formals
    : _accentSolidLight = accentSolidLight,
       // ignore: prefer_initializing_formals
       _accentSolidDark = accentSolidDark;

  final Color accentLight;
  final Color accentHoverLight;
  final Color accentSoftLight;
  final Color accentDark;
  final Color accentSoftDark;
  final Color brandFrom;
  final Color brandTo;
  final Color brandDeep;

  final Color? _accentSolidLight;
  final Color? _accentSolidDark;

  /// Accent sólido do claro: fundo com texto branco ≥ 4,5:1 (checkbox, rádio,
  /// switch, botão sólido). Sem valor, é o [accentLight] (que já passa 4,5:1).
  Color get accentSolidLight => _accentSolidLight ?? accentLight;

  /// Accent sólido do escuro: o [accentDark] é claro demais para texto branco,
  /// então as paletas prontas trazem um tom fechado (paletas/gerar.py). Sem valor,
  /// é o [accentLight].
  Color get accentSolidDark => _accentSolidDark ?? accentLight;

  /// As 4 cores do gradiente, da mais funda à mais clara. Sem elas, derivam de
  /// [brandDeep], [brandTo], [brandFrom] e [accentDark] (ver [gradientColors]).
  final List<Color>? stops;

  /// As 4 paradas do gradiente da marca (funda → clara).
  List<Color> get gradientColors => stops ?? [brandDeep, brandTo, brandFrom, accentDark];

  /// Gradiente de 4 paradas da marca (135°). Decorativo: fundo de herói,
  /// mosaico e cartão; nunca em texto ou botão.
  LinearGradient get gradient =>
      LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradientColors);

  // <paletas> gerado por paletas/gerar.py a partir de paletas/paletas.json, não edite.
  /// Violeta da suíte (financeiro, vendas, gestor...).
  static const violeta = _violeta;

  /// Noite de Tóquio: anil profundo, roxo, magenta e rosa neon.
  static const tokyoNight = _tokyoNight;

  /// Safira: azul real profundo ao azul-céu.
  static const safira = _safira;

  /// Meia-noite: quase preto, azul-marinho e um anil de luar.
  static const meiaNoite = _meiaNoite;

  /// Vinho: bordô, carmim e rosé.
  static const vinho = _vinho;

  /// Ameixa: roxo fechado, orquídea e lilás.
  static const ameixa = _ameixa;

  /// Ardósia: grafite azulado, sóbrio (painel, relatório).
  static const ardosia = _ardosia;

  /// Neon pop: noite roxa, magenta e amarelo elétrico.
  static const neonPop = _neonPop;

  /// Cereja: vermelho intenso ao rosa-claro.
  static const cereja = _cereja;

  /// Coral: salmão vivo, coral e espuma.
  static const coral = _coral;

  /// Laranja: tangerina cheia, do queimado ao creme.
  static const laranja = _laranja;

  /// Turquesa: petróleo, ciano e água clara.
  static const turquesa = _turquesa;

  /// Marple: framboesa, coral, pêssego e creme.
  static const marple = _marple;

  /// Terracota: barro cozido, telha e argila clara.
  static const terracota = _terracota;

  /// Pôr do sol: roxo da noite, rosa, laranja e dourado.
  static const porDoSol = _porDoSol;

  /// Âmbar: mel escuro, âmbar e amarelo-manteiga.
  static const ambar = _ambar;

  /// Café: grão torrado, caramelo e leite.
  static const cafe = _cafe;

  /// Crepúsculo violeta: ameixa, malva, areia e marfim.
  static const violetDusk = _violetDusk;

  /// Lavanda: lilás suave, campo de lavanda e névoa.
  static const lavanda = _lavanda;

  /// Pêssego: damasco, pêssego e creme.
  static const pessego = _pessego;

  /// Algodão-doce: rosa e azul de parque, bem claros.
  static const algodaoDoce = _algodaoDoce;

  /// Oceano: fundo do mar, azul-petróleo e espuma.
  static const oceano = _oceano;

  /// Ártico: azul-gelo, glaciar e branco de neve.
  static const artico = _artico;

  /// Menta: verde-água fresco, do jade ao gelo de menta.
  static const menta = _menta;

  /// Azul do Minhas Compras: cobalto, royal e céu.
  static const azul = _azul;

  /// Petróleo do Minhas Viagens: mar fundo, azul-petróleo e verde-água.
  static const petroleo = _petroleo;

  /// Eucalipto: verdes acinzentados, calmos (jardim, saúde).
  static const eucalipto = _eucalipto;

  /// Floresta: pinheiro, folha e broto.
  static const floresta = _floresta;

  /// Oliva: azeitona, musgo dourado e palha.
  static const oliva = _oliva;

  /// Sálvia: folha seca, verde-acinzentado e linho.
  static const salvia = _salvia;

  /// Paletas prontas por nome em pt-BR (30, a violeta primeiro, agrupadas por família):
  /// seletor de aparência e vitrine. Com slug e família: [SsPaleta.todas].
  static const paletas = _ssPaletasMapa;
  // </paletas>

  /// Marca a partir de uma ou duas cores soltas (v0.13; o `ss_brand_style` /
  /// `ComponentesUi.brand_css` do Rails): tema de usuário, painel com a própria
  /// cor, cliente. Os tons saem de [ssMix] com o preto e o branco da suíte:
  /// hover 14% mais escuro, suave 12% da cor sobre o branco (no escuro, 22%
  /// sobre a superfície), accent do escuro 28% mais claro e o fundo do
  /// gradiente 35% mais escuro. [accent2] (padrão: a própria) é o fim do gradiente.
  factory SsBrand.fromColors(Color accent, [Color? accent2]) => SsBrand(
    accentLight: accent,
    accentHoverLight: ssMix(accent, AppColors.scrim, .14),
    accentSoftLight: ssMix(AppColors.surfaceLight, accent, .12),
    accentDark: ssMix(accent, AppColors.surfaceLight, .28),
    accentSoftDark: ssMix(AppColors.surfaceDark, accent, .22),
    brandFrom: ssMix(accent, AppColors.surfaceLight, .12),
    brandTo: accent2 ?? accent,
    brandDeep: ssMix(accent, AppColors.scrim, .35),
  );

  /// Fundos claros do alto contraste (superfície, página, campo e o suave da marca).
  static const _hcClaros = [AppColors.surfaceLight, AppColors.pageLight, AppColors.fieldLight];

  /// Fundos escuros do alto contraste (normal e OLED).
  static const _hcEscuros = [
    AppColors.surfaceDark,
    AppColors.pageDark,
    AppColors.fieldDark,
    AppColors.surfaceOled,
    AppColors.pageOled,
    AppColors.fieldOled,
  ];

  /// Alto contraste (v0.16): a mesma marca com o acento mais forte, gerado da
  /// paleta (não à mão). Claro: o accent puxado para o preto até 7:1 (AAA)
  /// sobre superfície, página, campo e o suave da marca; escuro: puxado para o
  /// branco até 7:1 sobre as superfícies escuras e OLED; sólido com texto
  /// branco ≥ 7:1. Gradiente e suaves ficam. A mesma conta do
  /// `paletas/gerar.py` (que gera o `data-ss-contrast="high"` do web).
  /// Use pelo `AppTheme.build(b, brand:, highContrast: true)`.
  SsBrand highContrast() {
    final claro = ssUntilContrast(accentLight, AppColors.scrim, [..._hcClaros, accentSoftLight], 7);
    final escuro = ssUntilContrast(accentDark, AppColors.onDark, [..._hcEscuros, accentSoftDark], 7);
    return SsBrand(
      accentLight: claro,
      accentHoverLight: claro,
      accentSoftLight: accentSoftLight,
      accentDark: escuro,
      accentSoftDark: accentSoftDark,
      brandFrom: brandFrom,
      brandTo: brandTo,
      brandDeep: brandDeep,
      stops: gradientColors,
      accentSolidLight: ssUntilContrast(accentSolidLight, AppColors.scrim, const [AppColors.onDark], 7),
      accentSolidDark: ssUntilContrast(accentSolidDark, AppColors.scrim, const [AppColors.onDark], 7),
    );
  }

  @override
  SsBrand copyWith() => this;

  @override
  SsBrand lerp(SsBrand? other, double t) => t < .5 || other == null ? this : other;
}

/// Paleta pronta com o que o seletor precisa: slug (o mesmo do `data-palette` do
/// Rails), nome em pt-BR, família e a marca. A fonte é `paletas/paletas.json`
/// (gerado por `paletas/gerar.py`): o Rails tem as mesmas, com os mesmos nomes e cores.
@immutable
class SsPaleta {
  const SsPaleta({required this.slug, required this.nome, required this.familia, required this.brand});

  final String slug;
  final String nome;
  final String familia;
  final SsBrand brand;

  /// Todas, na ordem do seletor (a violeta primeiro, agrupadas por família).
  static const todas = _ssPaletasLista;

  /// Famílias na ordem do seletor (Profundas, Vivas, Quentes, Pastel, Frias, Natureza).
  static const familias = _ssFamilias;

  /// A paleta de uma marca, se for uma das prontas.
  static SsPaleta? of(SsBrand brand) {
    for (final p in todas) {
      if (identical(p.brand, brand) || p.brand == brand) return p;
    }
    return null;
  }

  /// A paleta pelo slug (`tokyo-night`…), se existir.
  static SsPaleta? porSlug(String slug) {
    for (final p in todas) {
      if (p.slug == slug) return p;
    }
    return null;
  }
}

class AppRadius {
  const AppRadius._();
  static const card = 18.0;
  static const cardActive = 22.0;
  static const field = 14.0;
  static const stepperBtn = 11.0;
  static const thumb = 12.0;
  static const pill = 999.0;
  static const sheet = 26.0;

  /// Squircle (canto contínuo, estilo iOS) com raio visual próximo de [r]:
  /// `Container(decoration: ShapeDecoration(shape: AppRadius.squircle(20), ...))`.
  static ContinuousRectangleBorder squircle(double r, {BorderSide side = BorderSide.none}) =>
      ContinuousRectangleBorder(borderRadius: BorderRadius.circular(r * 2.3), side: side);
}

/// Sombras do design system. O botão primário e o card ativo têm o "glow" roxo
/// direcional característico — o `elevation` do Material não reproduz, então os
/// componentes usam estes `BoxShadow` diretamente.
class AppShadows {
  const AppShadows._();
  static const card = [BoxShadow(color: Color(0x4D141628), offset: Offset(0, 4), blurRadius: 14, spreadRadius: -10)];
  static const sheet = [BoxShadow(color: Color(0x99141628), offset: Offset(0, 18), blurRadius: 40, spreadRadius: -14)];
}

/// Escala tipográfica (px lógicos). Manrope para UI, DM Mono tabular p/ números.
class AppType {
  const AppType._();
  static const screenTitle = 28.0;
  static const statNum = 34.0;
  static const headerTitle = 20.0;
  static const lg = 18.0;
  static const md = 16.0;
  static const body = 15.0;
  static const set = 14.0;
  static const sub = 13.0;
  static const meta = 12.0;
  static const label = 11.0;
  static const micro = 10.0;

  /// v0.19: entrelinha (`TextStyle.height`) de texto corrido: explicação,
  /// mensagem, parágrafo de folha. No produto, no lugar do `height: 1.4` solto.
  static const leading = 1.4;

  /// v0.19: espaço entre letras (`letterSpacing`) de rótulo pequeno em caixa
  /// alta: "FATURA", cabeçalho de tabela, selo.
  static const trackingCaps = .8;

  /// v0.19: espaço largo entre letras: sobrelinha ("CASA · 10 DE NOVEMBRO") e
  /// dígitos agrupados (número do cartão, código).
  static const trackingWide = 1.4;

  /// v0.19.1: entrelinha 1 (sem respiro): monograma num círculo, número ou
  /// letra centrada numa caixa do tamanho da fonte.
  static const solid = 1.0;

  /// v0.19.1: entrelinha justa (1,2): título e nome em destaque em até 2
  /// linhas, carimbo, cabeçalho de herói.
  static const tight = 1.2;

  /// v0.19.1: entrelinha média (1,3): legenda e meta de 2 linhas (sob o
  /// valor, no cupom), entre o [tight] e o [leading] do texto corrido.
  static const snug = 1.3;

  /// v0.19.1: espaço entre letras discreto (0,5): rótulo pequeno em caixa
  /// alta ou número de selo que só pede um respiro (menos que o [trackingCaps]).
  static const trackingTight = .5;

  /// v0.19.1: espaço negativo de título grande (−0,3), o mesmo aperto do
  /// título do [SsScreenHeader] (−1% de 28).
  static const trackingTitle = -.3;
}

/// Cores resolvidas do tema atual — atalho para os widgets `Ss*` lerem tokens
/// que não existem no `ColorScheme` (ex.: field, muted2, ink2, accentBright).
class SsColors {
  SsColors._(this._dark, this.brand, [this._oled = false, this._hc = false]);
  final bool _dark;
  final bool _oled;
  final bool _hc;
  final SsBrand brand;

  static SsColors of(BuildContext context) {
    final t = Theme.of(context);
    final dark = t.brightness == Brightness.dark;
    return SsColors._(
      dark,
      t.extension<SsBrand>() ?? SsBrand.violeta,
      dark && (t.extension<_SsOled>()?.on ?? false),
      t.extension<_SsContrast>()?.high ?? false,
    );
  }

  /// Para testes de contraste. [highContrast] não troca a marca: passe
  /// `brand.highContrast()` junto, como o [AppTheme.build] faz.
  factory SsColors.forDark(
    bool dark, [
    SsBrand brand = SsBrand.violeta,
    bool oled = false,
    bool highContrast = false,
  ]) => SsColors._(dark, brand, dark && oled, highContrast);

  bool get isDark => _dark;

  /// Alto contraste (v0.16, `AppTheme.build(highContrast: true)`): acento da
  /// marca a 7:1, texto apagado ([muted]) no tom do [ink2] e divisórias mais fortes.
  bool get isHighContrast => _hc;

  /// Escuro OLED: página preta pura e superfícies quase pretas.
  bool get isOled => _oled;

  /// Gradiente de 4 paradas da marca (ver [SsBrand.gradient]).
  LinearGradient get gradient4 => brand.gradient;

  /// Sombra na cor do card (card colorido "flutua" na própria cor). No escuro
  /// fica mais forte, porque a sombra preta some no fundo.
  List<BoxShadow> tintedShadow(Color color, {double strength = 1}) => [
    BoxShadow(
      color: color.withValues(alpha: ((_dark ? .5 : .38) * strength).clamp(0.0, 1.0)),
      offset: const Offset(0, 14),
      blurRadius: 28,
      spreadRadius: -12,
    ),
  ];

  Color get accent => _dark ? brand.accentDark : brand.accentLight;
  Color get accentSoft => _dark ? brand.accentSoftDark : brand.accentSoftLight;

  /// Accent sólido (texto branco ≥ 4,5:1): preenchimento de checkbox, rádio,
  /// switch e botão sólido. É o `--accent-solid` do Rails.
  Color get accentSolid => _dark ? brand.accentSolidDark : brand.accentSolidLight;
  Color get accentBright => brand.accentDark;
  Color get brandFrom => brand.brandFrom;
  Color get brandTo => brand.brandTo;
  Color get brandDeep => brand.brandDeep;

  /// [AppColors.series] com a 1ª cor trocada pela marca do produto: use esta
  /// (e não `AppColors.series[0]`, que é sempre o violeta).
  List<Color> get series => [accent, ...AppColors.series.skip(1)];

  /// v0.16: [color] na variante de texto (tinta) do tema atual: puxada para o
  /// [ink] (mais escura no claro, mais clara no escuro) só até passar 4,5:1
  /// (AA; 7:1 no alto contraste) sobre a superfície, a página e o campo. Para
  /// texto, carimbo ou ícone pequeno na cor de uma série ou de uma categoria.
  Color inkFor(Color color) => ssUntilContrast(color, ink, [surface, page, field], _hc ? 7 : 4.5);

  /// v0.16: [series] em variante de texto ([inkFor]), na mesma ordem:
  /// `seriesInk[i]` escreve sobre o fundo o que `series[i]` pinta (ponto,
  /// barra, faixa). No web, `--series-ink-1..6`.
  List<Color> get seriesInk => [for (final c in series) inkFor(c)];

  /// Glow direcional do botão primário e do card ativo, na cor da marca.
  List<BoxShadow> get primaryShadow => [
    BoxShadow(
      color: brand.accentLight.withValues(alpha: .35),
      offset: const Offset(0, 8),
      blurRadius: 18,
      spreadRadius: -10,
    ),
  ];
  List<BoxShadow> get activeShadow => [
    BoxShadow(
      color: brand.accentLight.withValues(alpha: .4),
      offset: const Offset(0, 16),
      blurRadius: 36,
      spreadRadius: -16,
    ),
  ];
  Color get ink => _dark ? AppColors.inkDark : AppColors.inkLight;
  Color get ink2 => _dark ? AppColors.ink2Dark : AppColors.ink2Light;
  Color get muted => _hc ? ink2 : (_dark ? AppColors.mutedDark : AppColors.mutedLight);
  Color get muted2 => _hc
      ? (_dark ? AppColors.mutedDark : AppColors.mutedLight)
      : (_dark ? AppColors.muted2Dark : AppColors.muted2Light);
  Color get surface => _oled ? AppColors.surfaceOled : (_dark ? AppColors.surfaceDark : AppColors.surfaceLight);
  Color get field => _oled ? AppColors.fieldOled : (_dark ? AppColors.fieldDark : AppColors.fieldLight);
  Color get page => _oled ? AppColors.pageOled : (_dark ? AppColors.pageDark : AppColors.pageLight);
  Color get line => _hc ? ink.withValues(alpha: .22) : (_dark ? AppColors.lineDark : AppColors.lineLight);
  Color get headerBg => _oled ? AppColors.headerOledBg : (_dark ? AppColors.headerDarkBg : AppColors.headerLightBg);
  Color get headerLine => AppColors.headerLine;
  Color get danger => AppColors.danger;
  Color get success => AppColors.success;

  // Texto colorido (selos, valores) com contraste AA no tema atual. As cores
  // vivas da marca (success, danger, aquec) ficam para ícone e preenchimento.
  Color get accentText => _dark ? brand.accentDark : brand.accentHoverLight;
  Color get successText => _dark ? AppColors.success : const Color(0xFF0F7A4E);
  Color get dangerText => _dark ? const Color(0xFFF2899A) : const Color(0xFFB42335);
  Color get aquecText => _dark ? const Color(0xFFF0B054) : const Color(0xFF8A4B00);
  Color get aquecSoft => _dark ? const Color(0xFF3A2A12) : AppColors.aquecBg;
}

/// Marca do tema de alto contraste (lida por [SsColors.of]).
@immutable
class _SsContrast extends ThemeExtension<_SsContrast> {
  const _SsContrast(this.high);
  final bool high;

  @override
  _SsContrast copyWith() => this;

  @override
  _SsContrast lerp(_SsContrast? other, double t) => t < .5 || other == null ? this : other;
}

/// Marca do tema OLED (lida por [SsColors.of]).
@immutable
class _SsOled extends ThemeExtension<_SsOled> {
  const _SsOled(this.on);
  final bool on;

  @override
  _SsOled copyWith() => this;

  @override
  _SsOled lerp(_SsOled? other, double t) => t < .5 || other == null ? this : other;
}

class AppTheme {
  const AppTheme._();

  /// Tema violeta padrão. Produto com outra cor: `AppTheme.build(b, brand: ...)`
  /// guardado num `static final` do app (não num getter: recria a cada rebuild).
  static final ThemeData light = build(Brightness.light);
  static final ThemeData dark = build(Brightness.dark);

  /// [oled] (só no escuro): página preta pura e superfícies quase pretas,
  /// para tela OLED (economiza bateria). `SsColors.isOled` fica verdadeiro.
  ///
  /// [density] (v0.11): `SsDensity.compact`, `standard` (padrão) ou
  /// `comfortable`. Vai no `extensions` (os `Ss*` leem com `SsDensity.of`) e
  /// alinha o `visualDensity` e os botões/campos Material que sobram.
  ///
  /// [highContrast] (v0.16): acento a 7:1 gerado da marca ([SsBrand.highContrast]),
  /// texto apagado no tom do `ink2` e divisórias mais fortes
  /// (`SsColors.isHighContrast`). O web é o `data-ss-contrast="high"`.
  static ThemeData build(
    Brightness brightness, {
    SsBrand brand = SsBrand.violeta,
    bool oled = false,
    SsDensity density = SsDensity.standard,
    bool highContrast = false,
  }) {
    final d = density;
    if (highContrast) brand = brand.highContrast();
    final isDark = brightness == Brightness.dark;
    final isOled = isDark && oled;
    final accent = isDark ? brand.accentDark : brand.accentLight;
    final accentSoft = isDark ? brand.accentSoftDark : brand.accentSoftLight;
    final page = isOled ? AppColors.pageOled : (isDark ? AppColors.pageDark : AppColors.pageLight);
    final surface = isOled ? AppColors.surfaceOled : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
    final field = isOled ? AppColors.fieldOled : (isDark ? AppColors.fieldDark : AppColors.fieldLight);
    final ink = isDark ? AppColors.inkDark : AppColors.inkLight;
    final muted = highContrast
        ? (isDark ? AppColors.ink2Dark : AppColors.ink2Light)
        : (isDark ? AppColors.mutedDark : AppColors.mutedLight);
    final line = highContrast ? ink.withValues(alpha: .22) : (isDark ? AppColors.lineDark : AppColors.lineLight);

    // ColorScheme montado à mão — cada papel aponta para um token real, sem os
    // tons lavanda/teal que o fromSeed inventava.
    final scheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: AppColors.onDark,
      primaryContainer: accentSoft,
      onPrimaryContainer: accent,
      secondary: accent,
      onSecondary: AppColors.onDark,
      secondaryContainer: accentSoft,
      onSecondaryContainer: accent,
      tertiary: accent,
      onTertiary: AppColors.onDark,
      error: AppColors.danger,
      onError: AppColors.onDark,
      errorContainer: AppColors.dangerSoft,
      onErrorContainer: AppColors.danger,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      surfaceContainerLowest: surface,
      surfaceContainerLow: field,
      surfaceContainer: field,
      surfaceContainerHigh: field,
      surfaceContainerHighest: field,
      surfaceTint: Colors.transparent,
      outline: line,
      outlineVariant: line,
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: isDark ? AppColors.inkDark : AppColors.headerLightBg,
      onInverseSurface: isDark ? AppColors.inkLight : AppColors.onDark,
      inversePrimary: accent,
    );

    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final manrope = GoogleFonts.manropeTextTheme(base.textTheme);
    final text = _textTheme(manrope, ink, muted);

    return base.copyWith(
      extensions: [brand, d, if (isOled) const _SsOled(true), if (highContrast) const _SsContrast(true)],
      visualDensity: d.visualDensity,
      colorScheme: scheme,
      scaffoldBackgroundColor: page,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      // Transição de páginas suave (deslize horizontal estilo iOS) no lugar do
      // zoom padrão do Material 3, que ficava "grosseiro" entre as views.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: page,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: AppType.screenTitle,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.01 * AppType.screenTitle,
          color: ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(d.radiusCard)),
      ),
      dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: field,
        selectedColor: accentSoft,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        labelStyle: GoogleFonts.manrope(fontSize: AppType.sub, fontWeight: FontWeight.w700, color: muted),
        secondaryLabelStyle: GoogleFonts.manrope(fontSize: AppType.sub, fontWeight: FontWeight.w700, color: accent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: field,
        hintStyle: TextStyle(color: muted),
        labelStyle: TextStyle(color: muted),
        floatingLabelStyle: TextStyle(color: accent),
        contentPadding: EdgeInsets.symmetric(horizontal: d.padX - 2, vertical: (d.fieldHeight - 26) / 2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(d.radiusField), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(d.radiusField),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(d.radiusField),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(d.radiusField),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: AppColors.onDark,
          elevation: 0,
          minimumSize: Size.fromHeight(d.controlHeight),
          textStyle: GoogleFonts.manrope(fontSize: AppType.body, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(d.radiusField)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: AppColors.onDark,
          minimumSize: Size.fromHeight(d.controlHeight),
          textStyle: GoogleFonts.manrope(fontSize: AppType.body, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(d.radiusField)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: GoogleFonts.manrope(fontSize: AppType.body, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: Size.fromHeight(d.controlHeight),
          side: BorderSide(color: line),
          textStyle: GoogleFonts.manrope(fontSize: AppType.body, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(d.radiusField)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: AppColors.onDark,
        elevation: 0,
        highlightElevation: 0,
        extendedTextStyle: GoogleFonts.manrope(fontSize: AppType.body, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(d.radiusField)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(d.radiusCard)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.fieldDark : AppColors.headerLightBg,
        contentTextStyle: GoogleFonts.manrope(color: AppColors.onDark, fontSize: AppType.set),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(d.radiusField)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: field,
        circularTrackColor: field,
      ),
      listTileTheme: ListTileThemeData(iconColor: muted, textColor: ink),
    );
  }

  static TextTheme _textTheme(TextTheme m, Color ink, Color muted) {
    TextStyle? ink800(TextStyle? s, double size) =>
        s?.copyWith(color: ink, fontWeight: FontWeight.w800, fontSize: size, letterSpacing: -0.01 * size);
    TextStyle? inkW(TextStyle? s, double size, [FontWeight w = FontWeight.w600]) =>
        s?.copyWith(color: ink, fontWeight: w, fontSize: size);
    TextStyle? mutedW(TextStyle? s, double size, [FontWeight w = FontWeight.w500]) =>
        s?.copyWith(color: muted, fontWeight: w, fontSize: size);
    return m.copyWith(
      headlineLarge: ink800(m.headlineLarge, AppType.screenTitle),
      headlineMedium: ink800(m.headlineMedium, 24),
      titleLarge: ink800(m.titleLarge, AppType.headerTitle),
      titleMedium: inkW(m.titleMedium, AppType.md, FontWeight.w700),
      titleSmall: inkW(m.titleSmall, AppType.set, FontWeight.w700),
      bodyLarge: inkW(m.bodyLarge, AppType.body),
      bodyMedium: inkW(m.bodyMedium, AppType.set),
      bodySmall: mutedW(m.bodySmall, AppType.meta),
      labelLarge: inkW(m.labelLarge, AppType.body, FontWeight.w700),
      labelMedium: mutedW(m.labelMedium, AppType.sub, FontWeight.w600),
      labelSmall: mutedW(m.labelSmall, AppType.label, FontWeight.w700),
    );
  }

  /// Estilo para NÚMEROS (DM Mono + tabular) — o `.num` do design system.
  static TextStyle number(BuildContext context, {double size = 16, FontWeight weight = FontWeight.w500, Color? color}) {
    return GoogleFonts.dmMono(
      fontSize: size,
      fontWeight: weight,
      fontFeatures: const [FontFeature.tabularFigures()],
      height: 1.0,
      color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
    );
  }
}
