// v1.14.0 "interface e animação": a troca de aba sem corte seco (eixo compartilhado / fade through) e a peça
// que voa de uma aba para a outra quando aparece nas duas. Par das View Transitions da Ss::AppShellComponent
// (`ss_tab_hero` no web).
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import '../motion.dart';

/// O movimento da troca: [fadeThrough] (a tela nova aparece crescendo de 92%, sem sentido: abas sem ordem),
/// [horizontal] (desliza do lado da aba escolhida) e [vertical] (sobe).
enum SsSharedAxis { fadeThrough, horizontal, vertical }

/// Troca de conteúdo com o movimento de eixo compartilhado: quando [transitionKey] muda (a aba atual), o [child]
/// novo entra esmaecendo e crescendo de leve ([SsSharedAxis.fadeThrough]) ou deslizando [SsMotion.distLarge] no
/// sentido da troca ([index] maior que o anterior vem da direita), em [SsMotion.medium] com [SsMotion.enter].
/// O [child] é o mesmo widget (o `IndexedStack`/`StatefulShellRoute` das abas guarda o estado de cada uma): só a
/// chegada anima, sem montar as duas telas juntas.
///
/// Junto, cada [SsTabHero] que aparece com a mesma `tag` na aba que sai e na que entra voa do lugar antigo ao
/// novo. O [SsNavScaffold] já usa (`tabTransition:`); fora dele:
/// `SsSharedAxisTransition(transitionKey: aba, index: aba, child: IndexedStack(index: aba, children: telas))`.
/// Com "reduzir movimento", troca seco e sem voo.
class SsSharedAxisTransition extends StatefulWidget {
  const SsSharedAxisTransition({
    super.key,
    required this.transitionKey,
    required this.child,
    this.index,
    this.axis = SsSharedAxis.fadeThrough,
    this.enabled = true,
  });

  final Object transitionKey;
  final Widget child;

  /// Posição da aba (para o sentido do deslize); nulo: sem sentido.
  final int? index;
  final SsSharedAxis axis;
  final bool enabled;

  @override
  State<SsSharedAxisTransition> createState() => _SsSharedAxisTransitionState();
}

class _SsSharedAxisTransitionState extends State<SsSharedAxisTransition> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: SsMotion.medium, value: 1);
  int _sentido = 1;

  @override
  void didUpdateWidget(SsSharedAxisTransition old) {
    super.didUpdateWidget(old);
    if (old.transitionKey == widget.transitionKey || !widget.enabled || reduceMotion(context)) return;
    _sentido = (widget.index ?? 0) >= (old.index ?? 0) ? 1 : -1;
    // Onde estavam as peças da aba que sai, antes de a nova ser montada.
    final antes = SsTabHero._snapshot();
    _c.forward(from: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) SsTabHero._fly(context, antes);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (_, child) {
      final t = SsMotion.enter.transform(_c.value);
      if (t >= 1) return child!;
      final Widget movido = switch (widget.axis) {
        SsSharedAxis.fadeThrough => Transform.scale(scale: .92 + .08 * t, child: child),
        SsSharedAxis.horizontal => Transform.translate(
          offset: Offset(_sentido * SsMotion.distLarge * (1 - t), 0),
          child: child,
        ),
        SsSharedAxis.vertical => Transform.translate(offset: Offset(0, SsMotion.distLarge * (1 - t)), child: child),
      };
      return Opacity(opacity: t, child: movido);
    },
  );
}

/// Peça que aparece nas duas abas (o saldo no Início e no Extrato, o avatar no Perfil e no menu): na troca de aba
/// dentro do [SsSharedAxisTransition] (ou do [SsNavScaffold]), ela **voa** do lugar e do tamanho que tinha na aba
/// que saiu até o da aba que entrou ([SsMotion.medium], [SsMotion.standard]), em vez de sumir e reaparecer. Sem
/// par na outra aba, nada voa. A `tag` é única por aba (como a do `Hero`). Par do `ss_tab_hero(nome)` do web
/// (o `view-transition-name`).
///
/// `SsTabHero(tag: 'saldo', child: SsAmount(money(saldo)))`.
class SsTabHero extends StatefulWidget {
  const SsTabHero({super.key, required this.tag, required this.child});

  final Object tag;
  final Widget child;

  static final _vivos = <_SsTabHeroState>{};

  /// As peças da aba à vista agora: tag → (estado, retângulo na tela).
  static Map<Object, (_SsTabHeroState, Rect)> _snapshot() => {
    for (final h in _vivos)
      if (h._ativo && h._rect() != null) h.widget.tag: (h, h._rect()!),
  };

  static void _fly(BuildContext context, Map<Object, (_SsTabHeroState, Rect)> antes) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    for (final h in _vivos.toList()) {
      final de = antes[h.widget.tag];
      if (de == null || identical(de.$1, h) || !h._ativo) continue;
      final para = h._rect();
      if (para == null || para == de.$2) continue;
      h._voar(overlay, de.$2, para);
    }
  }

  @override
  State<SsTabHero> createState() => _SsTabHeroState();
}

class _SsTabHeroState extends State<SsTabHero> with SingleTickerProviderStateMixin {
  bool _tique = true;
  bool _escondido = false;
  late final _c = AnimationController(vsync: this, duration: SsMotion.medium);
  OverlayEntry? _voo;

  @override
  void initState() {
    super.initState();
    SsTabHero._vivos.add(this);
  }

  @override
  void dispose() {
    SsTabHero._vivos.remove(this);
    _voo?.remove();
    _c.dispose();
    super.dispose();
  }

  /// À vista: com os tiques ligados e fora de `Offstage` e das vagas escondidas de um `IndexedStack` (as abas que
  /// guardam o estado continuam montadas e medidas).
  bool get _ativo {
    if (!_tique) return false;
    RenderObject? no = context.findRenderObject();
    while (no != null) {
      final pai = no.parent;
      if (pai is RenderOffstage && pai.offstage) return false;
      if (pai is RenderIndexedStack) {
        var i = 0;
        RenderBox? filho = pai.firstChild;
        while (filho != null && !identical(filho, no)) {
          filho = pai.childAfter(filho);
          i++;
        }
        if (filho != null && pai.index != i) return false;
      }
      no = pai;
    }
    return true;
  }

  Rect? _rect() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _voar(OverlayState overlay, Rect de, Rect para) {
    _voo?.remove();
    setState(() => _escondido = true);
    final curva = CurvedAnimation(parent: _c, curve: SsMotion.standard);
    _voo = OverlayEntry(
      builder: (_) => AnimatedBuilder(
        animation: curva,
        builder: (_, child) {
          final r = Rect.lerp(de, para, curva.value)!;
          return Positioned.fromRect(
            rect: r,
            child: IgnorePointer(
              child: FittedBox(
                fit: BoxFit.fill,
                child: SizedBox(width: para.width, height: para.height, child: child),
              ),
            ),
          );
        },
        child: ExcludeSemantics(child: widget.child),
      ),
    );
    overlay.insert(_voo!);
    _c.forward(from: 0).whenComplete(() {
      _voo?.remove();
      _voo = null;
      if (mounted) setState(() => _escondido = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    _tique = TickerMode.valuesOf(context).enabled;
    return Opacity(opacity: _escondido ? 0 : 1, child: widget.child);
  }
}
