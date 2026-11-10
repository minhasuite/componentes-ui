// v0.19.1: o que o minhas-compras-app e o minhas-viagens-app ainda montavam
// com peça crua do Material (conteúdo das abas, dica ao segurar, diálogo em
// tela cheia) ou com cor/fonte literal (cor que vem de dado, glifo de ícone
// pintado no canvas).
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../ss_strings.dart';
import '../v10/tela_barra.dart';

// ── Conteúdo das abas ──────────────────────────────────────────────────────

/// O conteúdo das abas do [SsTabsUnderline] (e do [SsCountTabs]): uma página
/// por aba, que segue o mesmo [controller] e troca de aba ao arrastar de lado.
/// Sem [controller], usa o `DefaultTabController` de cima. No lugar do
/// `TabBarView` do Material.
///
/// ```dart
/// SsTabsUnderline(tabs: abas, index: _tabs.index, onChanged: _tabs.animateTo),
/// Expanded(child: SsTabsView(controller: _tabs, children: [painel, historico, lojas])),
/// ```
///
/// [swipe] `false` desliga o arrastar (aba com mapa ou carrossel de lado);
/// as abas continuam trocando pelo toque no [SsTabsUnderline]. Com uma chave
/// de `PageStorageKey` em cada filho, cada aba guarda a própria rolagem.
class SsTabsView extends StatelessWidget {
  const SsTabsView({super.key, this.controller, required this.children, this.swipe = true});

  final TabController? controller;
  final List<Widget> children;
  final bool swipe;

  @override
  Widget build(BuildContext context) => TabBarView(
    controller: controller,
    physics: swipe ? null : const NeverScrollableScrollPhysics(),
    children: children,
  );
}

// ── Dica ao segurar / passar o mouse ───────────────────────────────────────

/// Dica curta que aparece ao **segurar** (toque) ou ao **passar o mouse** /
/// focar pelo teclado, em cima do [child] (embaixo com [below]): fundo de
/// tinta (o texto do tema, invertido), texto 12/600, raio 8, sombra do card.
/// O leitor de tela lê a [message] junto do [child]. Par do
/// `Ss::TooltipComponent` do web. No lugar do `Tooltip` do Material.
///
/// Não confundir com o [SsTip] (a dica dispensável com ×, dentro da tela).
/// Botão de ícone já tem a dele (`SsIconButton(tooltip:)`).
class SsTooltip extends StatelessWidget {
  const SsTooltip({super.key, required this.message, required this.child, this.below = false});

  final String message;
  final Widget child;

  /// Mostra embaixo do [child] (o padrão é em cima, como no web).
  final bool below;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final rapido = reduceMotion(context);
    return Tooltip(
      message: message,
      preferBelow: below,
      verticalOffset: 22,
      triggerMode: TooltipTriggerMode.longPress,
      waitDuration: const Duration(milliseconds: 250),
      showDuration: const Duration(milliseconds: 1800),
      exitDuration: rapido ? Duration.zero : SsMotion.fast,
      padding: EdgeInsets.symmetric(horizontal: d.space(10), vertical: d.space(6)),
      margin: EdgeInsets.symmetric(horizontal: d.padX),
      decoration: BoxDecoration(
        // Claro: tinta escura com texto branco; escuro: o campo com borda.
        color: c.isDark ? c.field : c.ink,
        borderRadius: BorderRadius.circular(8),
        border: c.isDark ? Border.all(color: c.line) : null,
        boxShadow: AppShadows.card,
      ),
      textStyle: TextStyle(
        fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
        color: c.isDark ? c.ink : c.surface,
        fontSize: d.font(AppType.meta),
        fontWeight: FontWeight.w600,
        height: AppType.snug,
      ),
      child: child,
    );
  }
}

// ── Tela cheia ─────────────────────────────────────────────────────────────

/// Abre [child] numa tela cheia por cima de tudo ([SsFullscreenPage]): barra
/// com o × ([SsStrings.close]), o [title] e as [actions]; o voltar do sistema
/// fecha. Para mostrar algo grande e sozinho: a frase para quem está do outro
/// lado do balcão, o código de embarque, o QR. No lugar do
/// `showDialog(builder: (_) => Dialog.fullscreen(child: ...))`.
///
/// [dismissOnTap] fecha com um toque em qualquer lugar (o leitor de tela diz
/// "Toque para fechar"). Sobe de baixo com fade; com "reduzir movimento",
/// aparece sem animar. Devolve o que a tela passar ao `Navigator.pop`.
Future<T?> showSsFullscreen<T>(
  BuildContext context, {
  String? title,
  required Widget child,
  List<Widget> actions = const [],
  bool dismissOnTap = false,
  bool useRootNavigator = true,
}) {
  final reduzir = reduceMotion(context);
  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
    PageRouteBuilder<T>(
      fullscreenDialog: true,
      transitionDuration: reduzir ? Duration.zero : SsMotion.base,
      reverseTransitionDuration: reduzir ? Duration.zero : SsMotion.fast,
      pageBuilder: (_, _, _) =>
          SsFullscreenPage(title: title, actions: actions, dismissOnTap: dismissOnTap, child: child),
      transitionsBuilder: (_, a, _, page) {
        final curva = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curva,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, .04), end: Offset.zero).animate(curva),
            child: page,
          ),
        );
      },
    ),
  );
}

/// A tela do [showSsFullscreen] (pública para quem monta a rota sozinho ou
/// usa no `go_router`): fundo da página, [SsTopBar] com × e [title], e o
/// [child] na área segura.
class SsFullscreenPage extends StatelessWidget {
  const SsFullscreenPage({
    super.key,
    this.title,
    required this.child,
    this.actions = const [],
    this.dismissOnTap = false,
  });

  final String? title;
  final Widget child;
  final List<Widget> actions;

  /// Um toque em qualquer lugar do conteúdo fecha.
  final bool dismissOnTap;

  @override
  Widget build(BuildContext context) {
    final s = SsStrings.of(context);
    final fechar = Navigator.of(context).maybePop;
    Widget corpo = SafeArea(top: false, child: child);
    if (dismissOnTap) {
      corpo = Semantics(
        button: true,
        hint: s.tapToClose,
        onTap: fechar,
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: fechar, child: corpo),
      );
    }
    return Scaffold(
      backgroundColor: SsColors.of(context).page,
      appBar: SsTopBar(
        title: title,
        leading: SsIconButton(icon: Icons.close_rounded, tooltip: s.close, onPressed: fechar),
        actions: actions,
      ),
      body: corpo,
    );
  }
}

// ── Cor que vem de dado ────────────────────────────────────────────────────

/// Cor que é **dado**, não estilo: "#E43225" vindo da API (cor média da foto)
/// ou a cor de marca de um terceiro guardada no app como dado (monograma da
/// loja, do site). Aceita `#RGB`, `#RRGGBB` e `#RRGGBBAA` (a ordem do CSS),
/// com ou sem `#`; lança [FormatException] se não for cor. Para o que pode
/// vir errado (resposta da API), use [ssTryColorFromHex].
///
/// Cor de **estilo** (fundo, texto, borda da tela) continua só por token:
/// `SsColors.of(context)`, [AppColors], a paleta do [SsBrand].
Color ssColorFromHex(String hex) =>
    ssTryColorFromHex(hex) ?? (throw FormatException('cor hex inválida (use #RRGGBB)', hex));

/// Como o [ssColorFromHex], mas devolve nulo quando [hex] é nulo ou não é cor.
Color? ssTryColorFromHex(String? hex) {
  var h = (hex ?? '').trim();
  if (h.startsWith('#')) h = h.substring(1);
  if (!RegExp(r'^([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$').hasMatch(h)) return null;
  if (h.length == 3) h = h.split('').map((x) => '$x$x').join();
  final rgb = int.parse(h.substring(0, 6), radix: 16);
  final a = h.length == 8 ? int.parse(h.substring(6), radix: 16) : 0xFF;
  return Color((a << 24) | rgb);
}

/// Cor que é dado, como inteiro `0xRRGGBB` (24 bits, opaca): o que a API
/// manda em número. O que passar de 24 bits é ignorado.
Color ssColorFromRgb(int rgb) => Color(0xFF000000 | (rgb & 0xFFFFFF));

// ── Glifo de ícone no canvas ───────────────────────────────────────────────

/// Estilo de texto que desenha o glifo de [icon] (fonte e pacote dele), para
/// um `TextPainter` num `CustomPainter`. No lugar do
/// `TextStyle(fontFamily: icon.fontFamily, package: icon.fontPackage, ...)`.
/// Widget comum usa `Icon`; o canvas pinta com [ssPaintIcon].
TextStyle ssIconTextStyle(IconData icon, {double size = 24, Color? color}) => TextStyle(
  inherit: false,
  fontFamily: icon.fontFamily,
  package: icon.fontPackage,
  fontFamilyFallback: icon.fontFamilyFallback,
  fontSize: size,
  height: AppType.solid,
  color: color,
);

/// Pinta o glifo de [icon] no [canvas] com o centro em [center], girado de
/// [angle] radianos (o avião que segue a rota, a seta do vento).
void ssPaintIcon(
  Canvas canvas,
  IconData icon,
  Offset center, {
  double size = 24,
  required Color color,
  double angle = 0,
  TextDirection textDirection = TextDirection.ltr,
}) {
  final glifo = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: ssIconTextStyle(icon, size: size, color: color),
    ),
    textDirection: textDirection,
  )..layout();
  canvas
    ..save()
    ..translate(center.dx, center.dy)
    ..rotate(angle);
  glifo.paint(canvas, Offset(-glifo.width / 2, -glifo.height / 2));
  canvas.restore();
  glifo.dispose();
}
