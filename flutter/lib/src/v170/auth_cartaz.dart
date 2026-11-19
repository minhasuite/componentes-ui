import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';
import '../ss_strings.dart';

/// Arranjo da tela de entrada "Cartaz" (v1.7, par do `layout:` do `Ss::AuthLayoutComponent(variant: :cartaz)`).
enum SsCartazLayout {
  /// Metade cartaz, metade papel (largura ≥ 840); mais estreito, o cartaz vira uma faixa em cima do papel.
  split,
}

/// v1.7 · tela de entrada "Cartaz + papel" (par do `Ss::AuthLayoutComponent(variant: :cartaz)`). Use pelo
/// [SsAuthLayout.cartaz]. O cartaz é a cor funda da marca ([SsColors.brandDeep]; no escuro, misturada a 52% com a
/// página, a mesma regra do web e das capas), com a marca, o [product] (e o [icon]), o [tagline] grande na fonte de
/// exibição, a linha de dados [facts] em DM Mono e a palavra gigante [word] cortada pela borda (fora do leitor de
/// tela). O papel ([SsColors.page]) leva "Parte da MinhaSuite", o [title], o [subtitle], o formulário do app
/// ([children]) e o [footer]. Uma passada de cor varre o cartaz ao abrir, uma vez; "reduzir movimento"
/// ([MediaQuery.disableAnimationsOf]) desliga.
class SsAuthCartaz extends StatefulWidget {
  const SsAuthCartaz({
    super.key,
    required this.product,
    required this.title,
    required this.children,
    this.subtitle,
    this.tagline,
    this.word,
    this.layout = SsCartazLayout.split,
    this.facts = const [],
    this.icon,
    this.brand = const ('Minha', 'Suite'),
    this.footer = const [],
  });

  final String product;
  final String title;
  final String? subtitle;

  /// A frase do produto, grande no cartaz ("A venda não para.").
  final String? tagline;

  /// A palavra gigante (decorativa). Padrão: a última palavra do [product], em minúsculas.
  final String? word;
  final SsCartazLayout layout;

  /// A linha de dados embaixo do cartaz ("Web", "Windows", "Caixa", "App"); some na faixa estreita.
  final List<String> facts;

  /// Ícone antes do nome do produto.
  final IconData? icon;

  /// Marca do topo: as duas partes do nome (a segunda num tom claro da marca).
  final (String, String) brand;
  final List<Widget> children;

  /// Links de baixo (termos, privacidade), já montados pelo app.
  final List<Widget> footer;

  /// A palavra que vai no cartaz.
  String get posterWord => (word?.trim().isNotEmpty ?? false)
      ? word!.trim().toLowerCase()
      : product.trim().split(RegExp(r'\s+')).last.toLowerCase();

  /// Largura a partir da qual cartaz e papel ficam lado a lado.
  static const double splitWidth = 840;

  @override
  State<SsAuthCartaz> createState() => _SsAuthCartazState();
}

/// Cores do cartaz a partir do tema (o mesmo cálculo do `v170_cartaz_web.css`).
class SsCartazColors {
  SsCartazColors.of(BuildContext context) : this._(SsColors.of(context));

  SsCartazColors._(SsColors c)
    : background = c.isDark ? ssMix(c.page, c.brandDeep, .52) : c.brandDeep,
      ink = AppColors.onDark,
      ink2 = c.isHighContrast
          ? AppColors.onDark
          : ssMix(c.isDark ? ssMix(c.page, c.brandDeep, .52) : c.brandDeep, AppColors.onDark, .82),
      word = ssMix(c.isDark ? ssMix(c.page, c.brandDeep, .52) : c.brandDeep, c.brandFrom, c.isDark ? .34 : .46),
      line = c.isHighContrast
          ? AppColors.onDark
          : ssMix(c.isDark ? ssMix(c.page, c.brandDeep, .52) : c.brandDeep, AppColors.onDark, .4),
      brandTint = ssMix(AppColors.onDark, c.brandFrom, .4),
      sweep = c.brandFrom,
      spotFrom = c.brandFrom,
      spotTo = c.brandTo;

  /// A cor cheia do cartaz.
  final Color background;

  /// Texto (branco, ≥ 7:1 em todas as paletas; o gerar.py confere).
  final Color ink;

  /// Texto secundário (≥ 4,5:1; branco inteiro no alto contraste).
  final Color ink2;

  /// A palavra gigante (decorativa).
  final Color word;
  final Color line;
  final Color brandTint;
  final Color sweep;
  final Color spotFrom;
  final Color spotTo;
}

class _SsAuthCartazState extends State<SsAuthCartaz> with SingleTickerProviderStateMixin {
  // A passada (1,05 s) e a palavra que entra (0,45 s depois, 1,9 s): 2,35 s ao todo.
  static const _total = 2350;
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _total),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _ctl.value = 1;
    } else {
      _ctl.forward();
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  static const _pass = Cubic(.7, 0, .2, 1);
  static const _settle = Cubic(.16, 1, .3, 1);

  double get _tPass => _pass.transform((_ctl.value * _total / 1050).clamp(0.0, 1.0));
  double get _tWord => ((_ctl.value * _total - 450) / 1900).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return ColoredBox(
      color: c.page,
      child: LayoutBuilder(
        builder: (context, box) {
          final largo = box.maxWidth >= SsAuthCartaz.splitWidth;
          if (largo) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 6, child: _cartaz(context, largo: true, larguraTela: box.maxWidth)),
                Expanded(flex: 5, child: _papel(context, largo: true)),
              ],
            );
          }
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight.isFinite ? box.maxHeight : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _cartaz(context, largo: false, larguraTela: box.maxWidth),
                  _papel(context, largo: false),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _marca(BuildContext context, SsCartazColors k, {required bool largo}) {
    final st = AppTheme.display(context, size: largo ? 28 : 24, color: k.ink);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: widget.brand.$1, style: st),
          TextSpan(
            text: widget.brand.$2,
            style: st.copyWith(color: k.brandTint),
          ),
        ],
      ),
    );
  }

  Widget _cartaz(BuildContext context, {required bool largo, required double larguraTela}) {
    final k = SsCartazColors.of(context);
    final tamPalavra = largo ? (larguraTela * .30).clamp(192.0, 544.0) : 192.0;
    final tamFrase = largo ? (larguraTela * .07).clamp(56.0, 120.0) : math.min(52.0, math.max(44.0, larguraTela * .13));
    final miolo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: largo ? MainAxisSize.max : MainAxisSize.min,
      children: [
        _marca(context, k, largo: largo),
        SizedBox(height: largo ? 40 : 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[Icon(widget.icon, size: 24, color: k.ink), const SizedBox(width: 10)],
                Flexible(
                  child: Text(
                    widget.product,
                    style: TextStyle(color: k.ink, fontWeight: FontWeight.w800, fontSize: AppType.headerTitle),
                  ),
                ),
              ],
            ),
            if (widget.tagline != null) ...[
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.textScalerOf(context).scale(tamFrase) * (largo ? 4.4 : 4.2),
                ),
                child: Text(
                  widget.tagline!,
                  style: AppTheme.display(context, size: tamFrase, color: k.ink).copyWith(height: .9),
                ),
              ),
            ],
          ],
        ),
        if (largo && widget.facts.isNotEmpty) ...[
          const SizedBox(height: 40),
          Wrap(
            spacing: 18,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < widget.facts.length; i++) ...[
                if (i > 0)
                  ExcludeSemantics(
                    child: SizedBox(width: 2, height: 19, child: ColoredBox(color: k.line)),
                  ),
                Text(
                  widget.facts[i],
                  style: AppTheme.number(context, size: AppType.md, color: k.ink),
                ),
              ],
            ],
          ),
        ] else if (largo)
          const SizedBox.shrink(),
      ],
    );

    return AnimatedBuilder(
      animation: _ctl,
      builder: (context, _) {
        final tp = _tPass, tw = _tWord;
        final corpo = ColoredBox(
          color: k.background,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // As duas manchas da paleta (o fundo das capas).
              Positioned(right: -320, top: -680, child: _mancha(1100, k.spotFrom, .38)),
              Positioned(left: -440, bottom: -640, child: _mancha(900, k.spotTo, .42)),
              Positioned(
                right: -larguraTela * (largo ? .04 : .06),
                bottom: -tamPalavra * .18,
                child: ExcludeSemantics(
                  child: Opacity(
                    opacity: (tw / .3).clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(larguraTela * .18 * (1 - _settle.transform(tw)), 0),
                      child: Text(
                        widget.posterWord,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                        style: AppTheme.display(
                          context,
                          size: tamPalavra,
                          color: k.word,
                        ).copyWith(height: .8, letterSpacing: -tamPalavra * .02),
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                bottom: largo,
                right: false,
                child: Padding(
                  padding: largo
                      ? EdgeInsets.all((larguraTela * .04).clamp(24.0, 56.0))
                      : const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: largo
                      ? SizedBox.expand(child: miolo)
                      : ConstrainedBox(constraints: const BoxConstraints(minHeight: 200), child: miolo),
                ),
              ),
              if (tp < 1)
                Positioned.fill(
                  child: IgnorePointer(child: CustomPaint(painter: _Passada(tp, k.sweep))),
                ),
            ],
          ),
        );
        if (tp >= 1) return corpo;
        return ClipPath(clipper: _Revela(tp), child: corpo);
      },
    );
  }

  Widget _mancha(double d, Color cor, double alfa) => IgnorePointer(
    child: SizedBox(
      width: d,
      height: d,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              cor.withValues(alpha: alfa),
              cor.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _papel(BuildContext context, {required bool largo}) {
    final c = SsColors.of(context);
    final s = SsStrings.of(context);
    final miolo = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            s.authPartOf('${widget.brand.$1}${widget.brand.$2}'),
            style: AppTheme.number(context, size: AppType.set, color: c.muted),
          ),
          const SizedBox(height: 12),
          Semantics(
            header: true,
            child: Text(
              widget.title,
              style: AppTheme.display(context, size: largo ? 56 : 48, color: c.ink).copyWith(height: .9),
            ),
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.subtitle!,
              style: TextStyle(color: c.muted, fontSize: AppType.md),
            ),
          ],
          const SizedBox(height: 24),
          ...widget.children,
        ],
      ),
    );
    final rodape = widget.footer.isEmpty
        ? null
        : Wrap(alignment: WrapAlignment.center, spacing: 20, runSpacing: 8, children: widget.footer);
    if (largo) {
      return ColoredBox(
        color: c.page,
        child: SafeArea(
          left: false,
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              padding: EdgeInsets.all((box.maxWidth * .08).clamp(24.0, 80.0)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(0, box.maxHeight - 2 * (box.maxWidth * .08).clamp(24.0, 80.0)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(child: miolo),
                    if (rodape != null) ...[const SizedBox(height: 32), rodape],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return ColoredBox(
      color: c.page,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: miolo),
              if (rodape != null) ...[const SizedBox(height: 24), rodape],
            ],
          ),
        ),
      ),
    );
  }
}

/// O cartaz aparece da esquerda para a direita com a borda inclinada (a passada da serigrafia).
class _Revela extends CustomClipper<Path> {
  _Revela(this.t);
  final double t;

  @override
  Path getClip(Size s) => Path()
    ..moveTo(0, 0)
    ..lineTo(s.width * 1.4 * t, 0)
    ..lineTo(s.width * (-.12 + 1.12 * t), s.height)
    ..lineTo(0, s.height)
    ..close();

  @override
  bool shouldReclip(_Revela old) => old.t != t;
}

/// A faixa de luz que corre na frente da passada.
class _Passada extends CustomPainter {
  _Passada(this.t, this.cor);
  final double t;
  final Color cor;

  double _x(double de, double ate) => de + (ate - de) * t;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final p = Path()
      ..moveTo(w * _x(-.08, 1.12), 0)
      ..lineTo(w * _x(-.02, 1.18), 0)
      ..lineTo(w * _x(-.14, 1.06), s.height)
      ..lineTo(w * _x(-.20, 1.0), s.height)
      ..close();
    canvas.drawPath(p, Paint()..color = cor);
  }

  @override
  bool shouldRepaint(_Passada old) => old.t != t || old.cor != cor;
}
