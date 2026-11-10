// v0.10.2 (tela): barra de topo compacta (inclusive sobre mapa, planta e
// foto em tela cheia), botão de ícone, botão flutuante, carregando e
// abertura do app. Pares no web: Ss::TopBarComponent (.ss-topbar),
// .ss-icon-btn, .ss-fab, .ss-spinner e Ss::SplashComponent (.ss-splash).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../ss_fit.dart';
import '../ss_strings.dart';

/// Visual do [SsIconButton].
enum SsIconButtonVariant {
  /// Só o ícone (barra de topo, ação em linha de lista).
  plain,

  /// Fundo de campo, redondo (o do cabeçalho).
  tonal,

  /// Contorno fino (ação dentro de card).
  outline,

  /// Ícone na cor de perigo (excluir); fundo de perigo no toque.
  danger,
}

/// Botão só de ícone da suíte: alvo de 48 dp, dica ([tooltip], que também é
/// o nome no leitor de tela) e o ponto/número de [badge] ("" vira só o ponto).
/// [selected] marca na cor da marca (alternar). Sem [onPressed], apagado.
///
/// `SsIconButton(icon: Icons.delete_outline_rounded, tooltip: 'Excluir', variant: SsIconButtonVariant.danger, onPressed: ...)`
class SsIconButton extends StatelessWidget {
  const SsIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.variant = SsIconButtonVariant.plain,
    this.size,
    this.color,
    this.badge,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final SsIconButtonVariant variant;

  /// Diâmetro visível (o alvo de toque fica em 48). Nulo (v0.11): o da
  /// densidade, 36 / 40 / 44 ([SsDensity.iconButton]).
  final double? size;

  /// Cor do ícone (padrão: a do tema, ou a da barra quando está numa [SsTopBar]).
  final Color? color;
  final String? badge;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final size = this.size ?? SsDensity.of(context).iconButton;
    Widget i = Icon(icon, size: size * .52);
    if (badge != null) {
      i = Badge(
        label: badge!.isEmpty ? null : Text(badge!),
        backgroundColor: AppColors.danger,
        textColor: AppColors.onDark,
        child: i,
      );
    }
    final fg = selected
        ? c.accentText
        : (color ??
              switch (variant) {
                SsIconButtonVariant.danger => c.dangerText,
                SsIconButtonVariant.tonal || SsIconButtonVariant.outline => c.ink2,
                SsIconButtonVariant.plain => null,
              });
    final bg = selected
        ? c.accentSoft
        : switch (variant) {
            SsIconButtonVariant.tonal => c.field,
            _ => null,
          };
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      isSelected: selected,
      icon: i,
      style: IconButton.styleFrom(
        foregroundColor: fg,
        backgroundColor: bg,
        disabledForegroundColor: c.muted2,
        highlightColor: variant == SsIconButtonVariant.danger ? AppColors.dangerSoft : c.accentSoft,
        fixedSize: Size.square(size),
        minimumSize: Size.square(size),
        tapTargetSize: MaterialTapTargetSize.padded,
        // O tamanho já vem da SsDensity: sem o ajuste do visualDensity do tema,
        // que no compacto baixaria o alvo de toque para 40.
        visualDensity: VisualDensity.standard,
        side: variant == SsIconButtonVariant.outline ? BorderSide(color: c.line) : null,
        shape: variant == SsIconButtonVariant.plain
            ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(size * .3))
            : const CircleBorder(),
      ),
    );
  }
}

/// Visual da [SsTopBar].
enum SsTopBarStyle {
  /// Fundo da página e texto escuro/claro conforme o tema (o padrão).
  surface,

  /// Fundo escuro fixo e texto claro, nos dois temas: foto, vídeo, câmera.
  dark,

  /// Transparente por cima do conteúdo (mapa, planta, imagem em tela cheia),
  /// com um véu escuro que some para baixo e texto claro. Use com
  /// `Scaffold(extendBodyBehindAppBar: true)`.
  overlay,
}

/// Barra de topo compacta da suíte, para a tela que não é lista com título
/// grande ([SsScreenHeader]): editor, mapa, painel com abas, visualizador.
/// Título que encolhe em vez de cortar ([SsFitTitle]) e [subtitle] menor;
/// voltar automático (com [onBack] trocando o pop); [actions] à direita
/// ([SsIconButton], `SsButton.text`, `SsButton(small: true)`). [style] escolhe
/// superfície, escuro ou sobreposto.
///
/// ```dart
/// Scaffold(
///   appBar: SsTopBar(title: 'Editar painel', actions: [
///     SsButton.text(label: 'Rascunho', onPressed: ...),
///     SsButton(label: 'Publicar', small: true, expand: false, onPressed: ...),
///   ]),
/// )
/// ```
class SsTopBar extends StatelessWidget implements PreferredSizeWidget {
  const SsTopBar({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.eyebrow,
    this.actions = const [],
    this.leading,
    this.automaticallyImplyLeading = true,
    this.onBack,
    this.style = SsTopBarStyle.surface,
    this.bottom,
    this.centerTitle = false,
  });

  final String? title;

  /// Troca o título de texto (ex.: um seletor de local).
  final Widget? titleWidget;
  final String? subtitle;

  /// v0.17 (par do `Ss::PageComponent(eyebrow:)`): linha pequena em caixa alta
  /// acima do título ("CASA · 10 DE NOVEMBRO"), o topo discreto de um painel.
  final String? eyebrow;
  final List<Widget> actions;

  /// Troca o voltar automático.
  final Widget? leading;
  final bool automaticallyImplyLeading;

  /// Toque no voltar (padrão: `Navigator.maybePop`, que respeita o `PopScope`).
  final VoidCallback? onBack;
  final SsTopBarStyle style;

  /// Faixa embaixo (abas, busca).
  final PreferredSizeWidget? bottom;
  final bool centerTitle;

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    final claro = style != SsTopBarStyle.surface;
    final fg = claro ? AppColors.onDark : c.ink;
    final bg = switch (style) {
      SsTopBarStyle.surface => c.page,
      SsTopBarStyle.dark => AppColors.headerDarkBg,
      SsTopBarStyle.overlay => Colors.transparent,
    };
    final podeVoltar = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    final volta =
        leading ??
        (automaticallyImplyLeading && (podeVoltar || onBack != null)
            ? SsIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: s.back,
                color: fg,
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              )
            : null);
    // Do tema (Manrope): o AppBar troca o DefaultTextStyle pelo titleTextStyle,
    // então um TextStyle cru cairia na fonte do sistema.
    final tema = Theme.of(context).textTheme;
    final estiloTitulo = (tema.titleLarge ?? const TextStyle()).copyWith(
      color: fg,
      fontSize: d.font(AppType.lg),
      fontWeight: FontWeight.w800,
      letterSpacing: -.2,
      shadows: style == SsTopBarStyle.overlay ? const [Shadow(color: Color(0x66000000), blurRadius: 8)] : null,
    );
    Widget? tituloW = titleWidget ?? (title == null ? null : SsFitTitle(title!, style: estiloTitulo));
    if (tituloW != null && eyebrow != null) {
      tituloW = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow!.toUpperCase(),
            key: const ValueKey('ss-topbar-eyebrow'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (tema.labelSmall ?? const TextStyle()).copyWith(
              color: claro ? AppColors.onDarkSoft : c.muted,
              fontSize: d.font(AppType.micro),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              height: 1.2,
            ),
          ),
          tituloW,
        ],
      );
    }
    if (tituloW != null && subtitle != null) {
      tituloW = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          tituloW,
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (tema.bodySmall ?? const TextStyle()).copyWith(
              color: claro ? AppColors.onDarkSoft : c.muted,
              fontSize: d.font(AppType.meta),
              fontWeight: FontWeight.w600,
              shadows: style == SsTopBarStyle.overlay ? const [Shadow(color: Color(0x66000000), blurRadius: 6)] : null,
            ),
          ),
        ],
      );
    }
    final Widget barra = AppBar(
      backgroundColor: bg,
      foregroundColor: fg,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: volta,
      titleSpacing: volta == null ? d.padX : 4,
      centerTitle: centerTitle,
      title: tituloW,
      titleTextStyle: estiloTitulo,
      iconTheme: IconThemeData(color: fg),
      actionsIconTheme: IconThemeData(color: fg),
      systemOverlayStyle: claro || c.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      actions: [
        for (final a in actions) Padding(padding: const EdgeInsets.only(left: 4), child: a),
        SizedBox(width: d.space(8)),
      ],
      bottom: bottom,
    );
    // Sobreposto: o véu fica atrás da barra inteira (status bar + barra + faixa
    // de baixo). No flexibleSpace, sem tamanho, ele sumia (altura zero).
    final Widget corpo = style == SsTopBarStyle.overlay
        ? DecoratedBox(
            key: const ValueKey('ss-topbar-scrim'),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x8C000000), Color(0x00000000)],
              ),
            ),
            child: barra,
          )
        : barra;
    return IconButtonTheme(
      data: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: fg)),
      child: corpo,
    );
  }
}

/// Botão flutuante da suíte: pílula na cor sólida da marca com [label]
/// (estendido) ou círculo só com o ícone (a dica vira [tooltip] e o nome no
/// leitor de tela). Encolhe ao toque e volta com a mola. Sem `heroTag`, então
/// pode ficar em várias abas de um `IndexedStack`.
///
/// `floatingActionButton: SsFab(icon: Icons.add_rounded, label: 'Seção', onPressed: _add)`
///
/// v0.17 (par do `Ss::FabComponent`): `extended: false` mostra só o ícone e o
/// [label] vira a dica e o nome lido (o FAB de toda tela: "Falar com a casa");
/// `extendedFrom: 640` mostra o texto só com a tela a partir dessa largura (o
/// `extended: :wide` do web).
class SsFab extends StatelessWidget {
  const SsFab({
    super.key,
    required this.icon,
    this.label,
    this.tooltip,
    required this.onPressed,
    this.extended = true,
    this.extendedFrom,
  });

  final IconData icon;
  final String? label;

  /// Nome do botão sem [label] (padrão: o [label]).
  final String? tooltip;
  final VoidCallback? onPressed;

  /// Com [label]: false desenha o círculo só com o ícone (o rótulo vai para a dica e o leitor).
  final bool extended;

  /// Largura mínima da tela para mostrar o [label] (abaixo, só o ícone).
  final double? extendedFrom;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final wide = extendedFrom == null || MediaQuery.sizeOf(context).width >= extendedFrom!;
    final shown = extended && wide ? label : null;
    final name = label ?? tooltip;
    // 48 / 56 / 60 (o FAB do Material é 56).
    final h = d.controlHeight + 8;
    final on = onPressed != null;
    final corpo = AnimatedOpacity(
      duration: reduceMotion(context) ? Duration.zero : SsMotion.fast,
      opacity: on ? 1 : .5,
      child: Container(
        height: h,
        constraints: BoxConstraints(minWidth: h),
        padding: EdgeInsets.symmetric(horizontal: shown == null ? 0 : d.padX + 4),
        decoration: BoxDecoration(
          color: c.accentSolid,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: c.primaryShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.onDark, size: d.iconSize + 4),
            if (shown != null) ...[
              SizedBox(width: d.space(8)),
              Text(
                shown,
                style: TextStyle(color: AppColors.onDark, fontSize: d.font(AppType.set), fontWeight: FontWeight.w800),
              ),
            ],
          ],
        ),
      ),
    );
    Widget w = Semantics(
      button: true,
      enabled: on,
      label: name,
      excludeSemantics: true,
      child: SsPressable(onTap: onPressed, enabled: on, scale: .94, child: corpo),
    );
    if (shown == null && (tooltip ?? label) != null) w = Tooltip(message: tooltip ?? label!, child: w);
    return w;
  }
}

/// Carregando em anel: o arco na cor da marca girando sobre o trilho suave.
/// Com "reduzir movimento", o arco fica parado. Nome no leitor de tela:
/// [semanticsLabel] (padrão: "Carregando").
class SsSpinner extends StatefulWidget {
  const SsSpinner({super.key, this.size = 22, this.strokeWidth, this.color, this.semanticsLabel});

  final double size;
  final double? strokeWidth;

  /// Cor do arco (padrão: a da marca; [AppColors.onDark] sobre fundo escuro).
  final Color? color;
  final String? semanticsLabel;

  @override
  State<SsSpinner> createState() => _SsSpinnerState();
}

class _SsSpinnerState extends State<SsSpinner> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final cor = widget.color ?? c.accent;
    return Semantics(
      label: widget.semanticsLabel ?? SsStrings.of(context).loading,
      child: SizedBox.square(
        dimension: widget.size,
        child: RotationTransition(
          turns: _c,
          child: CustomPaint(
            painter: _ArcoPainter(
              cor: cor,
              trilho: cor.withValues(alpha: .18),
              largura: widget.strokeWidth ?? widget.size / 9,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcoPainter extends CustomPainter {
  _ArcoPainter({required this.cor, required this.trilho, required this.largura});
  final Color cor, trilho;
  final double largura;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(largura / 2, largura / 2, size.width - largura, size.height - largura);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = largura
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, math.pi * 2, false, p..color = trilho);
    canvas.drawArc(r, -math.pi / 2, math.pi * .55, false, p..color = cor);
  }

  @override
  bool shouldRepaint(_ArcoPainter old) => old.cor != cor || old.trilho != trilho || old.largura != largura;
}

/// Tela de abertura enquanto o app descobre a sessão ou carrega o essencial:
/// fundo da página, a marca do app ([logo], ex. o SVG dele), [title], o
/// [SsSpinner] e [message]. O spinner e a mensagem só aparecem depois de
/// [delay] (a abertura rápida não pisca). Funciona como `home` de um
/// `MaterialApp` (não precisa de `Scaffold`).
///
/// `home: status == AuthStatus.unknown ? const SsSplash(title: 'Minha Automação') : const LoginScreen()`
class SsSplash extends StatefulWidget {
  const SsSplash({super.key, this.logo, this.title, this.message, this.delay = const Duration(milliseconds: 300)});

  final Widget? logo;
  final String? title;
  final String? message;
  final Duration delay;

  @override
  State<SsSplash> createState() => _SsSplashState();
}

class _SsSplashState extends State<SsSplash> {
  bool _mostra = false;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _mostra = true;
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) setState(() => _mostra = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final dur = reduceMotion(context) ? Duration.zero : SsMotion.base;
    return Material(
      color: c.page,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.logo != null) ...[SizedBox(height: 72, child: widget.logo), const SizedBox(height: 16)],
                if (widget.title != null) ...[
                  Text(
                    widget.title!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.ink, fontSize: AppType.headerTitle, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 24),
                ],
                AnimatedOpacity(
                  duration: dur,
                  opacity: _mostra ? 1 : 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SsSpinner(size: 28),
                      if (widget.message != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          widget.message!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: c.muted, fontSize: AppType.sub),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
