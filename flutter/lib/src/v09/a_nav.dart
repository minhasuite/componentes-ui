import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../ss_nav_bar.dart' show SsNavItem;
import '../ss_strings.dart';

/// Abas com um traço embaixo que viaja como **minhoca** até a aba escolhida:
/// a ponta da frente dispara, a de trás vem ~90 ms depois com mola, então no
/// meio ele cobre as duas abas e afina (3 → 2 px); ao chegar, amassa (≈8%
/// mais largo e mais grosso) e assenta ([SsMotion.worm], 520 ms). Atrás da
/// cabeça vai um rastro de brilho da marca que some. O rótulo novo sobe 2 px
/// e volta com mola enquanto a cor passa para a da marca; o antigo apaga.
/// [uppercase] usa versalete espaçado ("DESCOBRIR"); [onDark] para dentro de
/// cabeçalho escuro ([SsCurvedHeader]).
///
/// Cabendo, as abas dividem a largura por igual. Quando não cabem (muitas
/// abas, nomes longos, fonte grande), a faixa rola na horizontal, cada aba
/// com a largura do nome, e a escolhida é trazida para a vista ao mudar.
/// [scrollable] `true` força a rolagem; `false`, a divisão por igual.
/// [icons] põe um ícone antes de cada nome (nulo na posição = sem ícone).
///
/// v0.19.1: [stacked] põe o ícone **em cima** do nome e nunca rola: as abas
/// dividem a largura por igual e o nome encolhe para caber (5 abas cabem em
/// 360 px). A faixa fica com [stackedHeight] de altura (66 no padrão), para
/// o `bottomHeight:` do [SsSliverHeader]. O conteúdo das abas vai no
/// [SsTabsView] com o mesmo `TabController`.
class SsTabsUnderline extends StatefulWidget {
  const SsTabsUnderline({
    super.key,
    required this.tabs,
    required this.index,
    required this.onChanged,
    this.uppercase = false,
    this.onDark = false,
    this.icons,
    this.scrollable,
    this.stacked = false,
  }) : assert(tabs.length >= 2),
       assert(icons == null || icons.length == tabs.length);

  /// Altura da faixa com [stacked] na densidade de [context] (60/66/70).
  static double stackedHeight(BuildContext context) => SsDensity.of(context).segmentHeight + 24;

  final List<String> tabs;
  final int index;
  final ValueChanged<int> onChanged;
  final bool uppercase;
  final bool onDark;

  /// Um ícone por aba, antes do nome.
  final List<IconData?>? icons;

  /// Nulo = rola só quando as abas não cabem.
  final bool? scrollable;

  /// v0.19.1: ícone em cima do nome, sem rolagem (ver a classe).
  final bool stacked;

  @override
  State<SsTabsUnderline> createState() => _SsTabsUnderlineState();
}

class _SsTabsUnderlineState extends State<SsTabsUnderline> {
  static const _pad = 16.0; // folga de cada lado do nome, no modo rolável
  static const _icone = 18.0;
  static const _iconeEmCima = 20.0;
  final _rolagem = ScrollController();

  // Posição de cada aba no modo rolável (do último layout), para trazer a
  // escolhida para a vista.
  List<double> _esq = const [];
  List<double> _larg = const [];

  @override
  void didUpdateWidget(SsTabsUnderline old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) WidgetsBinding.instance.addPostFrameCallback((_) => _mostra(animar: true));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _mostra(animar: false));
  }

  @override
  void dispose() {
    _rolagem.dispose();
    super.dispose();
  }

  /// Centraliza a aba escolhida na faixa (sem passar das pontas).
  void _mostra({required bool animar}) {
    if (!mounted || !_rolagem.hasClients || widget.index >= _esq.length) return;
    final p = _rolagem.position;
    final alvo = (_esq[widget.index] + _larg[widget.index] / 2 - p.viewportDimension / 2).clamp(
      p.minScrollExtent,
      p.maxScrollExtent,
    );
    if ((alvo - p.pixels).abs() < 1) return;
    if (!animar || reduceMotion(context)) {
      _rolagem.jumpTo(alvo);
    } else {
      _rolagem.animateTo(alvo, duration: SsMotion.base, curve: Curves.easeOutCubic);
    }
  }

  TextStyle _estilo(BuildContext context, {required bool selected, required Color cor}) => TextStyle(
    fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
    color: cor,
    fontSize: SsDensity.of(context).font(widget.uppercase || widget.stacked ? AppType.meta : AppType.set),
    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
    letterSpacing: widget.uppercase ? 2.4 : 0,
  );

  String _nome(int i) => widget.uppercase ? widget.tabs[i].toUpperCase() : widget.tabs[i];

  /// Largura natural de cada aba (no peso da escolhida, para não pular).
  List<double> _naturais(BuildContext context) {
    final escala = MediaQuery.textScalerOf(context);
    final estilo = _estilo(context, selected: true, cor: const Color(0xFF000000));
    return [
      for (var i = 0; i < widget.tabs.length; i++)
        () {
          final tp = TextPainter(
            text: TextSpan(text: _nome(i), style: estilo),
            textDirection: TextDirection.ltr,
            textScaler: escala,
            maxLines: 1,
          )..layout();
          final ic = widget.icons?[i] == null ? 0.0 : escala.scale(_icone) + SsDensity.of(context).space(6);
          final w = tp.width + ic + 2 * _pad;
          tp.dispose();
          return w.ceilToDouble();
        }(),
    ];
  }

  /// O traço no instante: afina esticado, amassa ao chegar; o rastro vai atrás.
  Widget _traco(SsIndicatorFrame f, Color bar, double base) {
    final r = f.rect;
    // Amassado da chegada: um pulso nos últimos 30% da viagem.
    final chegada = f.from == null || f.t >= 1 ? 0.0 : math.sin(math.pi * ((f.t - .7) / .3).clamp(0.0, 1.0));
    final w = r.width * (1 + .08 * chegada);
    final h = 3 - math.min(1.0, f.stretch) + .8 * chegada;
    final traco = Rect.fromLTWH(r.center.dx - w / 2, base - h, w, h);
    final filhos = <Widget>[];
    if (f.moving) {
      // Rastro: da ponta de trás de onde saiu até a cabeça, do transparente
      // para a marca a 35%, apagando ao longo da viagem.
      final de = f.from!;
      final cabeca = f.direction > 0 ? r.right : r.left;
      final cauda = lerpDouble(f.direction > 0 ? de.left : de.right, cabeca, Curves.easeIn.transform(f.t))!;
      final a = (1 - f.t / .75).clamp(0.0, 1.0);
      if (a > 0 && (cabeca - cauda).abs() > 1) {
        filhos.add(
          Positioned.fromRect(
            rect: Rect.fromLTRB(math.min(cauda, cabeca), base - 7, math.max(cauda, cabeca), base),
            child: IgnorePointer(
              child: Opacity(
                opacity: a,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      begin: f.direction > 0 ? Alignment.centerLeft : Alignment.centerRight,
                      end: f.direction > 0 ? Alignment.centerRight : Alignment.centerLeft,
                      colors: [bar.withValues(alpha: 0), bar.withValues(alpha: .35)],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    filhos.add(
      Positioned.fromRect(
        rect: traco,
        child: DecoratedBox(
          decoration: BoxDecoration(color: bar, borderRadius: BorderRadius.circular(2)),
        ),
      ),
    );
    return Stack(clipBehavior: Clip.none, children: filhos);
  }

  Widget _aba(BuildContext context, int i, Color on, Color off) {
    final sel = i == widget.index;
    final icone = widget.icons?[i];
    final texto = Text(_nome(i), maxLines: 1, overflow: TextOverflow.ellipsis);
    final Widget rotulo;
    if (widget.stacked) {
      // Ícone em cima; o nome encolhe (sem reticências) para caber na aba.
      rotulo = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icone != null) ...[
              Icon(icone, size: _iconeEmCima, color: sel ? on : off),
              SizedBox(height: SsDensity.of(context).space(4)),
            ],
            FittedBox(fit: BoxFit.scaleDown, child: Text(_nome(i), maxLines: 1)),
          ],
        ),
      );
    } else {
      rotulo = icone == null
          ? texto
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icone, size: _icone, color: sel ? on : off),
                  SizedBox(width: SsDensity.of(context).space(6)),
                  Flexible(child: texto),
                ],
              ),
            );
    }
    return Semantics(
      button: true,
      selected: sel,
      child: InkWell(
        onTap: () {
          if (!sel) SsHaptics.tick();
          widget.onChanged(i);
        },
        child: Center(
          child: _TabLabel(
            selected: sel,
            child: AnimatedDefaultTextStyle(
              duration: reduceMotion(context) ? Duration.zero : SsMotion.base,
              curve: Curves.easeOut,
              style: _estilo(context, selected: sel, cor: sel ? on : off),
              child: rotulo,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    // Escolhida: a cor da marca (no escuro, a clara de texto; sobre o
    // cabeçalho escuro, o texto claro, pelo contraste).
    final on = widget.onDark ? AppColors.onDark : c.accentText;
    final off = widget.onDark ? AppColors.onDarkMuted : c.muted;
    final bar = widget.onDark ? c.accentBright : c.accent;
    final n = widget.tabs.length;
    final linha = Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(height: 1, color: widget.onDark ? AppColors.onDark.withValues(alpha: .08) : c.line),
    );
    // Altura pela densidade (42 / 48 / 52); no compacto o toque continua com 48.
    final d = SsDensity.of(context);
    return SsTapTarget(minSize: Size(0, d.minTarget), child: _faixa(context, d, linha, on, off, bar, n));
  }

  Widget _faixa(BuildContext context, SsDensity d, Widget linha, Color on, Color off, Color bar, int n) {
    return SizedBox(
      height: widget.stacked ? d.segmentHeight + 24 : d.segmentHeight + 6,
      child: LayoutBuilder(
        builder: (context, box) {
          final naturais = widget.stacked ? const <double>[] : _naturais(context);
          final soma = naturais.fold(0.0, (a, b) => a + b);
          final rola = !widget.stacked && (widget.scrollable ?? soma > box.maxWidth);
          if (!rola) {
            _esq = const [];
            _larg = const [];
            final w = box.maxWidth / n;
            return Stack(
              children: [
                linha,
                Row(children: [for (var i = 0; i < n; i++) Expanded(child: _aba(context, i, on, off))]),
                // O traço viaja como minhoca: a frente dispara, a de trás alcança,
                // afina no caminho e amassa ao chegar.
                Positioned.fill(
                  child: SsSlidingIndicator(
                    index: widget.index,
                    duration: SsMotion.worm,
                    rectOf: (i, size) => Rect.fromLTWH(i * w + 14, size.height - 3, w - 28, 3),
                    frameBuilder: (context, f) => _traco(f, bar, box.maxHeight),
                  ),
                ),
              ],
            );
          }
          // Rolável: cada aba com a largura do nome (sobra repartida se couber).
          final extra = soma < box.maxWidth ? (box.maxWidth - soma) / n : 0.0;
          final larg = [for (final w in naturais) w + extra];
          final esq = <double>[];
          var x = 0.0;
          for (final w in larg) {
            esq.add(x);
            x += w;
          }
          _esq = esq;
          _larg = larg;
          return Stack(
            children: [
              linha,
              SingleChildScrollView(
                controller: _rolagem,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: x,
                  height: box.maxHeight,
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          for (var i = 0; i < n; i++) SizedBox(width: larg[i], child: _aba(context, i, on, off)),
                        ],
                      ),
                      Positioned.fill(
                        child: SsSlidingIndicator(
                          index: widget.index,
                          duration: SsMotion.worm,
                          rectOf: (i, size) => Rect.fromLTWH(esq[i] + 12, size.height - 3, larg[i] - 24, 3),
                          frameBuilder: (context, f) => _traco(f, bar, box.maxHeight),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Rótulo da aba: ao ser escolhido, sobe 2 px e volta com a mola (passa um
/// tiquinho para baixo e assenta). Com menos movimento, fica parado.
class _TabLabel extends StatefulWidget {
  const _TabLabel({required this.selected, required this.child});
  final bool selected;
  final Widget child;

  @override
  State<_TabLabel> createState() => _TabLabelState();
}

class _TabLabelState extends State<_TabLabel> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 460), value: 1);

  @override
  void didUpdateWidget(_TabLabel old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected && !reduceMotion(context)) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, child) {
      final t = _c.value;
      // Sobe rápido no 1º quarto; volta com a mola no resto.
      final dy = t >= 1
          ? 0.0
          : t < .25
          ? -2 * Curves.easeOut.transform(t / .25)
          : -2 * (1 - SsMotion.bounce.transform((t - .25) / .75));
      return Transform.translate(offset: Offset(0, dy), child: child);
    },
    child: widget.child,
  );
}

/// Tom do fundo do [SsCurvedHeader].
enum SsHeaderTone { brand, dark }

/// Cabeçalho escuro (cor funda da marca ou superfície escura) que termina numa
/// curva côncava; o conteúdo de baixo sobe [overlap] px por cima dele. Tem
/// título, voltar opcional, ações e um [bottom] (ex.: `SsSegmented(onDark:
/// true)` ou `SsTabsUnderline(onDark: true)`). Texto sempre claro (AA).
///
/// Vai no topo da tela, antes do conteúdo:
/// `Column(children: [SsCurvedHeader(...), Expanded(child: lista)])`.
class SsCurvedHeader extends StatelessWidget {
  const SsCurvedHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.bottom,
    this.tone = SsHeaderTone.brand,
    this.curve = 28,
    this.overlap = 36,
    this.safeTop = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? bottom;
  final SsHeaderTone tone;

  /// Profundidade da curva (px).
  final double curve;

  /// Quanto o fundo escuro desce além do cabeçalho, por trás do conteúdo.
  final double overlap;

  /// Soma a área segura de cima (falso dentro de AppBar/Sheet).
  final bool safeTop;

  /// Cor do fundo no tom e no tema atuais.
  static Color background(BuildContext context, SsHeaderTone tone) {
    final c = SsColors.of(context);
    return tone == SsHeaderTone.brand ? Color.lerp(c.brandDeep, c.headerBg, c.isDark ? .45 : .2)! : c.headerBg;
  }

  @override
  Widget build(BuildContext context) {
    final bg = background(context, tone);
    final top = safeTop ? MediaQuery.paddingOf(context).top : 0.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // O fundo vaza para baixo (overlap) e fecha em curva côncava.
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: -overlap,
          child: IgnorePointer(
            child: ClipPath(
              clipper: _ConcaveClipper(curve),
              child: ColoredBox(color: bg),
            ),
          ),
        ),
        DefaultTextStyle.merge(
          style: const TextStyle(color: AppColors.onDark),
          child: IconTheme.merge(
            data: const IconThemeData(color: AppColors.onDark),
            child: Padding(
              padding: EdgeInsets.fromLTRB(8, top + 8, 8, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        if (leading != null) leading! else const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: leading == null && actions.isEmpty ? TextAlign.start : TextAlign.center,
                            style: const TextStyle(
                              fontSize: AppType.headerTitle,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onDark,
                            ),
                          ),
                        ),
                        ...actions,
                        if (actions.isEmpty && leading != null) const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
                      child: Text(
                        subtitle!,
                        textAlign: leading == null && actions.isEmpty ? TextAlign.start : TextAlign.center,
                        style: const TextStyle(color: AppColors.onDarkMuted, fontSize: AppType.sub),
                      ),
                    ),
                  if (bottom != null) Padding(padding: const EdgeInsets.fromLTRB(8, 12, 8, 0), child: bottom),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Base que sobe no meio (a curva "abraça" o conteúdo de baixo).
class _ConcaveClipper extends CustomClipper<Path> {
  _ConcaveClipper(this.depth);
  final double depth;

  @override
  Path getClip(Size size) => Path()
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..quadraticBezierTo(size.width / 2, size.height - depth * 2, 0, size.height)
    ..close();

  @override
  bool shouldReclip(_ConcaveClipper old) => old.depth != depth;
}

/// Trilho lateral vertical (tablet, painel, app de casa): o item ativo abre um
/// recorte curvo na borda direita do trilho e fica num círculo encaixado nele.
/// O recorte desliza com mola até o item novo, e o círculo estica como gota no
/// caminho ([SsSlidingIndicator]).
class SsSideRail extends StatelessWidget {
  const SsSideRail({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.header,
    this.footer,
  });

  final List<SsNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Fica no topo do trilho (logo, menu).
  final Widget? header;
  final Widget? footer;

  static const width = 72.0;
  static const _itemH = 64.0;
  static const _circle = 46.0;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return SizedBox(
      width: width + _circle / 2,
      child: Column(
        children: [
          if (header != null)
            SizedBox(
              width: width + _circle / 2,
              child: Container(
                width: width,
                margin: const EdgeInsets.only(right: _circle / 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: c.accent,
                child: IconTheme.merge(
                  data: const IconThemeData(color: AppColors.onDark),
                  child: Center(child: header),
                ),
              ),
            ),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // O recorte e o círculo deslizam juntos com mola; no caminho o
                // círculo estica como gota e o recorte acompanha.
                Positioned.fill(
                  child: SsSlidingIndicator(
                    index: currentIndex,
                    axis: Axis.vertical,
                    rectOf: (i, _) =>
                        Rect.fromCenter(center: Offset(width, (i + .5) * _itemH + 8), width: _circle, height: _circle),
                    builder: (context, r, estica) {
                      final afina = 1 - math.min(.14, estica * .25);
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _RailPainter(
                                color: c.accent,
                                cy: r.center.dy,
                                width: width,
                                r: _circle / 2 + 7,
                                rv: r.height / 2 + 7,
                              ),
                            ),
                          ),
                          Positioned.fromRect(
                            rect: Rect.fromCenter(center: r.center, width: _circle * afina, height: r.height),
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: c.surface,
                                  borderRadius: BorderRadius.circular(_circle / 2),
                                  boxShadow: c.tintedShadow(c.accent),
                                ),
                                child: AnimatedSwitcher(
                                  duration: reduceMotion(context) ? Duration.zero : SsMotion.indicator,
                                  switchInCurve: SsMotion.bounce,
                                  transitionBuilder: (child, a) => FadeTransition(
                                    opacity: a,
                                    child: ScaleTransition(scale: a, child: child),
                                  ),
                                  child: Icon(
                                    items[currentIndex].activeIcon ?? items[currentIndex].icon,
                                    key: ValueKey(currentIndex),
                                    color: c.accentText,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 0,
                  width: width,
                  top: 8,
                  child: Column(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        SizedBox(
                          height: _itemH,
                          child: Semantics(
                            button: true,
                            selected: i == currentIndex,
                            label: items[i].label,
                            excludeSemantics: true,
                            child: Tooltip(
                              message: items[i].label,
                              child: InkResponse(
                                onTap: () {
                                  if (i != currentIndex) SsHaptics.tick();
                                  onTap(i);
                                },
                                radius: 28,
                                child: Center(
                                  child: AnimatedOpacity(
                                    duration: SsMotion.fast,
                                    opacity: i == currentIndex ? 0 : 1,
                                    child: Icon(
                                      items[i].icon,
                                      color: AppColors.onDark.withValues(alpha: .85),
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (footer != null)
            Container(
              width: width,
              margin: const EdgeInsets.only(right: _circle / 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: c.accent,
              child: IconTheme.merge(
                data: const IconThemeData(color: AppColors.onDark),
                child: Center(child: footer),
              ),
            ),
        ],
      ),
    );
  }
}

class _RailPainter extends CustomPainter {
  _RailPainter({required this.color, required this.cy, required this.width, required this.r, double? rv})
    : rv = rv ?? r;
  final Color color;
  final double cy;
  final double width;
  final double r;

  /// Raio vertical do recorte (maior que [r] com o círculo esticado).
  final double rv;

  @override
  void paint(Canvas canvas, Size size) {
    const s = 14.0;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(width, 0)
      ..lineTo(width, cy - rv - s)
      ..cubicTo(width, cy - rv - s * .25, width - r * .1, cy - rv, width - r * .35, cy - rv * .92)
      ..arcToPoint(Offset(width - r * .35, cy + rv * .92), radius: Radius.elliptical(r, rv), clockwise: false)
      ..cubicTo(width - r * .1, cy + rv, width, cy + rv + s * .25, width, cy + rv + s)
      ..lineTo(width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RailPainter old) => old.cy != cy || old.rv != rv || old.color != color;
}

/// Sino (ou outro ícone) com ponto de notificação. Quando [count] sobe, o
/// ponto **pulsa uma vez** (cresce e solta um anel). [showCount] põe o número
/// dentro do ponto. Alvo de 48 dp.
class SsBellDot extends StatefulWidget {
  const SsBellDot({
    super.key,
    this.count = 0,
    this.onTap,
    this.icon = Icons.notifications_none_rounded,
    this.showCount = false,
    this.color,
    this.tooltip,
  });

  final int count;
  final VoidCallback? onTap;
  final IconData icon;
  final bool showCount;

  /// Cor do ícone (sem ela, a do tema; num cabeçalho escuro, passe uma clara).
  final Color? color;

  /// Padrão: [SsStrings.notifications].
  final String? tooltip;

  @override
  State<SsBellDot> createState() => _SsBellDotState();
}

class _SsBellDotState extends State<SsBellDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700), value: 1);
  }

  @override
  void didUpdateWidget(SsBellDot old) {
    super.didUpdateWidget(old);
    if (widget.count > old.count && !reduceMotion(context)) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final has = widget.count > 0;
    final s = SsStrings.of(context);
    final tooltip = widget.tooltip ?? s.notifications;
    final label = has ? s.newCount(tooltip, widget.count) : tooltip;
    final txt = widget.count > 99 ? '99+' : '${widget.count}';
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        child: InkResponse(
          onTap: widget.onTap,
          radius: 24,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(widget.icon, size: SsDensity.of(context).iconSize + 6, color: widget.color ?? c.ink),
                if (has)
                  Positioned(
                    right: widget.showCount ? 4 : 11,
                    top: widget.showCount ? 6 : 11,
                    child: AnimatedBuilder(
                      animation: _c,
                      builder: (_, child) {
                        final t = _c.value;
                        final pop = 1 + .45 * math.sin(math.pi * (t / .5).clamp(0.0, 1.0));
                        return Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            if (t < 1)
                              Transform.scale(
                                scale: 1 + 1.6 * t,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: c.accent.withValues(alpha: 1 - t), width: 1.5),
                                  ),
                                ),
                              ),
                            Transform.scale(scale: pop, child: child),
                          ],
                        );
                      },
                      child: Container(
                        constraints: BoxConstraints(minWidth: widget.showCount ? 18 : 10, minHeight: 10),
                        height: widget.showCount ? 18 : 10,
                        padding: EdgeInsets.symmetric(horizontal: widget.showCount ? 5 : 0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.accent,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: c.page, width: 1.5),
                        ),
                        child: widget.showCount
                            ? Text(
                                txt,
                                textScaler: TextScaler.noScaling,
                                style: AppTheme.number(
                                  context,
                                  size: AppType.micro,
                                  weight: FontWeight.w700,
                                  color: c.isDark ? c.page : AppColors.onDark,
                                ),
                              )
                            : null,
                      ),
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

/// Abas de categoria com o contador num círculo **em cima** do rótulo
/// ("12 / Pendentes"). A atual tem o círculo cheio na cor da marca, que
/// desliza com mola de uma aba para a outra (esticando no caminho); rola na
/// horizontal quando não cabe.
class SsCountTabs extends StatefulWidget {
  const SsCountTabs({super.key, required this.tabs, required this.index, required this.onChanged});

  /// (rótulo, contador).
  final List<(String, int)> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  State<SsCountTabs> createState() => _SsCountTabsState();
}

class _SsCountTabsState extends State<SsCountTabs> {
  final _area = GlobalKey();
  List<GlobalKey> _keys = [];

  // Onde fica o círculo de cada aba (as abas têm larguras diferentes, então
  // são medidas depois do quadro). Nulo até a 1ª medida: aí cada aba pinta o
  // próprio fundo.
  List<Rect>? _rects;
  bool _medindo = false;

  void _medir() {
    if (_medindo) return;
    _medindo = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _medindo = false;
      if (!mounted) return;
      final area = _area.currentContext?.findRenderObject() as RenderBox?;
      if (area == null || !area.hasSize) return;
      final rects = <Rect>[];
      for (final k in _keys) {
        final rb = k.currentContext?.findRenderObject() as RenderBox?;
        if (rb == null || !rb.hasSize) return;
        rects.add(rb.localToGlobal(Offset.zero, ancestor: area) & rb.size);
      }
      final antes = _rects;
      if (antes != null &&
          antes.length == rects.length &&
          Iterable.generate(rects.length).every((i) => antes[i] == rects[i])) {
        return;
      }
      setState(() => _rects = rects);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final n = widget.tabs.length;
    if (_keys.length != n) {
      _keys = List.generate(n, (_) => GlobalKey());
      _rects = null;
    }
    _medir();
    final rects = _rects;
    final dur = reduceMotion(context) ? Duration.zero : SsMotion.fast;
    final d = SsDensity.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: d.padX - 4),
      child: Stack(
        key: _area,
        children: [
          if (rects != null) ...[
            // Os fundos cinza ficam por baixo de tudo; o círculo da marca
            // desliza por cima deles e por baixo dos números.
            for (final r in rects)
              Positioned.fromRect(
                rect: r,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(AppRadius.pill)),
                ),
              ),
            Positioned.fill(
              child: SsSlidingIndicator(
                index: widget.index.clamp(0, n - 1),
                rectOf: (i, _) => rects[i].inflate(1.6),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.accent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: c.tintedShadow(c.accent, strength: .8),
                  ),
                ),
              ),
            ),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < n; i++)
                Semantics(
                  button: true,
                  selected: i == widget.index,
                  label: '${widget.tabs[i].$1}, ${widget.tabs[i].$2}',
                  excludeSemantics: true,
                  child: SsPressable(
                    onTap: () {
                      if (i != widget.index) SsHaptics.tick();
                      widget.onChanged(i);
                    },
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: d.iconButton + 32, minHeight: d.minTarget),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: d.space(8), vertical: d.space(6)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              key: _keys[i],
                              constraints: BoxConstraints(minWidth: d.iconButton, minHeight: d.iconButton),
                              padding: EdgeInsets.symmetric(horizontal: d.space(8)),
                              alignment: Alignment.center,
                              // Antes da 1ª medida, a aba pinta o próprio fundo.
                              decoration: rects != null
                                  ? null
                                  : BoxDecoration(
                                      color: i == widget.index ? c.accent : c.field,
                                      borderRadius: BorderRadius.circular(AppRadius.pill),
                                    ),
                              child: SsPop(
                                active: i == widget.index,
                                child: AnimatedDefaultTextStyle(
                                  duration: dur,
                                  style: AppTheme.number(
                                    context,
                                    size: d.font(AppType.set),
                                    weight: FontWeight.w700,
                                    color: i == widget.index ? AppColors.onDark : c.ink2,
                                  ),
                                  child: Text('${widget.tabs[i].$2}'),
                                ),
                              ),
                            ),
                            SizedBox(height: d.space(6)),
                            Text(
                              widget.tabs[i].$1,
                              style: TextStyle(
                                color: i == widget.index ? c.ink : c.muted,
                                fontSize: d.font(AppType.meta),
                                fontWeight: i == widget.index ? FontWeight.w800 : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Barra de topo de fluxo em tela cheia: "3/4" (passo grande em DM Mono, total
/// menor), botão Cancelar e uma barrinha de progresso "minhoca"
/// ([SsWormProgress]): a cabeça dispara com mola levando uma faísca e o corpo
/// alcança. O número novo pula (0,6 → 1,15 → 1) e solta um anel ([SsRipple]).
class SsStepTopBar extends StatelessWidget {
  const SsStepTopBar({super.key, required this.step, required this.total, this.onCancel, this.onBack, this.cancelLabel})
    : assert(step >= 1 && step <= total);

  final int step;
  final int total;
  final VoidCallback? onCancel;
  final VoidCallback? onBack;

  /// Padrão: [SsStrings.cancel].
  final String? cancelLabel;

  /// Pulo do número novo: 0,6 → 1,15 (rápido) → 1 (com mola).
  static final _popPasso = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: .6, end: 1.15).chain(CurveTween(curve: Curves.easeOut)), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: SsMotion.bounce)), weight: 65),
  ]);

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final dur = reduceMotion(context) ? Duration.zero : SsMotion.worm;
    final s = SsStrings.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 56,
          child: Row(
            children: [
              if (onBack != null)
                IconButton(
                  tooltip: s.back,
                  onPressed: onBack,
                  icon: Icon(Icons.arrow_back_rounded, color: c.ink),
                )
              else
                const SizedBox(width: 16),
              Semantics(
                label: s.stepOf(step, total),
                excludeSemantics: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    // O passo novo pula (0,6 → 1,15 → 1) e solta um anel; o antigo apaga.
                    SsRipple(
                      trigger: step,
                      radius: 14,
                      child: AnimatedSwitcher(
                        duration: dur,
                        transitionBuilder: (child, a) => child.key == ValueKey(step)
                            ? FadeTransition(
                                opacity: a.drive(CurveTween(curve: const Interval(0, .3))),
                                child: ScaleTransition(scale: a.drive(_popPasso), child: child),
                              )
                            : FadeTransition(
                                opacity: a.drive(CurveTween(curve: const Interval(.6, 1))),
                                child: child,
                              ),
                        layoutBuilder: (atual, antigos) =>
                            Stack(alignment: Alignment.centerLeft, children: [...antigos, ?atual]),
                        child: Text(
                          '$step',
                          key: ValueKey(step),
                          style: AppTheme.number(context, size: 22, weight: FontWeight.w500, color: c.ink),
                        ),
                      ),
                    ),
                    Text(
                      ' / $total',
                      style: AppTheme.number(context, size: AppType.sub, color: c.muted),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (onCancel != null)
                TextButton.icon(
                  onPressed: onCancel,
                  icon: Icon(Icons.close_rounded, size: 18, color: c.muted),
                  label: Text(
                    (cancelLabel ?? s.cancel).toUpperCase(),
                    style: TextStyle(
                      color: c.muted,
                      fontSize: AppType.meta,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        // A barrinha anda como minhoca: a cabeça (com a faísca) passa um pouco
        // e o corpo alcança.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SsWormProgress(value: step / total),
        ),
      ],
    );
  }
}
