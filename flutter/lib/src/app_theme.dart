import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  });

  final Color accentLight;
  final Color accentHoverLight;
  final Color accentSoftLight;
  final Color accentDark;
  final Color accentSoftDark;
  final Color brandFrom;
  final Color brandTo;
  final Color brandDeep;

  /// Violeta da suíte (financeiro, vendas, gestor...).
  static const violeta = SsBrand(
    accentLight: Color(0xFF5A45E8),
    accentHoverLight: Color(0xFF4A37D1),
    accentSoftLight: Color(0xFFEEEBFF),
    accentDark: Color(0xFF8F7DFF),
    accentSoftDark: Color(0xFF241F45),
    brandFrom: Color(0xFF7B5CFF),
    brandTo: Color(0xFF5A45E8),
    brandDeep: Color(0xFF3B2BB0),
  );

  @override
  SsBrand copyWith() => this;

  @override
  SsBrand lerp(SsBrand? other, double t) => t < .5 || other == null ? this : other;
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
}

/// Cores resolvidas do tema atual — atalho para os widgets `Ss*` lerem tokens
/// que não existem no `ColorScheme` (ex.: field, muted2, ink2, accentBright).
class SsColors {
  SsColors._(this._dark, this.brand);
  final bool _dark;
  final SsBrand brand;

  static SsColors of(BuildContext context) {
    final t = Theme.of(context);
    return SsColors._(t.brightness == Brightness.dark, t.extension<SsBrand>() ?? SsBrand.violeta);
  }

  /// Para testes de contraste.
  factory SsColors.forDark(bool dark, [SsBrand brand = SsBrand.violeta]) => SsColors._(dark, brand);

  bool get isDark => _dark;

  Color get accent => _dark ? brand.accentDark : brand.accentLight;
  Color get accentSoft => _dark ? brand.accentSoftDark : brand.accentSoftLight;
  Color get accentBright => brand.accentDark;
  Color get brandFrom => brand.brandFrom;
  Color get brandTo => brand.brandTo;
  Color get brandDeep => brand.brandDeep;

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
  Color get muted => _dark ? AppColors.mutedDark : AppColors.mutedLight;
  Color get muted2 => _dark ? AppColors.muted2Dark : AppColors.muted2Light;
  Color get surface => _dark ? AppColors.surfaceDark : AppColors.surfaceLight;
  Color get field => _dark ? AppColors.fieldDark : AppColors.fieldLight;
  Color get page => _dark ? AppColors.pageDark : AppColors.pageLight;
  Color get line => _dark ? AppColors.lineDark : AppColors.lineLight;
  Color get headerBg => _dark ? AppColors.headerDarkBg : AppColors.headerLightBg;
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

class AppTheme {
  const AppTheme._();

  /// Tema violeta padrão. Produto com outra cor: `AppTheme.build(b, brand: ...)`
  /// guardado num `static final` do app (não num getter: recria a cada rebuild).
  static final ThemeData light = build(Brightness.light);
  static final ThemeData dark = build(Brightness.dark);

  static ThemeData build(Brightness brightness, {SsBrand brand = SsBrand.violeta}) {
    final isDark = brightness == Brightness.dark;
    final accent = isDark ? brand.accentDark : brand.accentLight;
    final accentSoft = isDark ? brand.accentSoftDark : brand.accentSoftLight;
    final page = isDark ? AppColors.pageDark : AppColors.pageLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final field = isDark ? AppColors.fieldDark : AppColors.fieldLight;
    final ink = isDark ? AppColors.inkDark : AppColors.inkLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final line = isDark ? AppColors.lineDark : AppColors.lineLight;

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
      extensions: [brand],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: AppColors.onDark,
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          textStyle: GoogleFonts.manrope(fontSize: AppType.body, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: AppColors.onDark,
          minimumSize: const Size.fromHeight(50),
          textStyle: GoogleFonts.manrope(fontSize: AppType.body, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
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
          minimumSize: const Size.fromHeight(50),
          side: BorderSide(color: line),
          textStyle: GoogleFonts.manrope(fontSize: AppType.body, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: AppColors.onDark,
        elevation: 0,
        highlightElevation: 0,
        extendedTextStyle: GoogleFonts.manrope(fontSize: AppType.body, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.fieldDark : AppColors.headerLightBg,
        contentTextStyle: GoogleFonts.manrope(color: AppColors.onDark, fontSize: AppType.set),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
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
