// v1.9 · movimento: o skeleton que vira conteúdo. O SsAsyncBody, o SsInlineAsync e o
// SsAsyncSliver usam esta troca em vez de trocar seco.
import 'package:material_ui/material_ui.dart';

import '../../motion.dart';

/// Troca de estado (carregando → dado, erro → dado) com crossfade e a subida curta de quem chega
/// ([SsMotion.medium], [SsMotion.enter], [SsMotion.distMedium]). [stateKey] diz qual estado é: o
/// mesmo estado com dado novo (revalidou) não anima. Com menos movimento, troca direto.
///
/// O layout é o do filho: os estados ficam empilhados só durante a troca, cada um com as
/// restrições do pai (como se estivesse sozinho).
///
/// `SsSkeletonSwitch(stateKey: carregando ? 'skeleton' : 'dado', child: carregando ? const SkeletonList() : Lista(l))`
class SsSkeletonSwitch extends StatelessWidget {
  const SsSkeletonSwitch({super.key, required this.stateKey, required this.child, this.duration = SsMotion.medium});

  final Object stateKey;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final filho = KeyedSubtree(key: ValueKey<Object>(stateKey), child: child);
    return AnimatedSwitcher(
      duration: reduceMotion(context) ? Duration.zero : duration,
      switchInCurve: SsMotion.enter,
      switchOutCurve: SsMotion.exit,
      layoutBuilder: (atual, anteriores) =>
          Stack(fit: StackFit.passthrough, alignment: AlignmentDirectional.topStart, children: [...anteriores, ?atual]),
      transitionBuilder: ssContentEntrance,
      child: filho,
    );
  }
}

/// A transição da troca: aparece e sobe [SsMotion.distMedium]; quem sai só esmaece (a mesma
/// estrutura nos dois sentidos, para o estado do filho não se perder no meio).
Widget ssContentEntrance(Widget child, Animation<double> animation) => FadeTransition(
  opacity: animation,
  child: AnimatedBuilder(
    animation: animation,
    builder: (_, filho) => Transform.translate(
      offset: Offset(0, animation.status == AnimationStatus.reverse ? 0 : (1 - animation.value) * SsMotion.distMedium),
      child: filho,
    ),
    child: child,
  ),
);

/// O mesmo para sliver: o conteúdo entra esmaecendo quando [play] (o sliver não sobe: mudar a
/// posição dele mexeria na rolagem). Usado pelo [SsAsyncSliver] quando o dado chega depois do
/// skeleton.
class SsSliverEntrance extends StatefulWidget {
  const SsSliverEntrance({super.key, required this.sliver, this.play = true, this.duration = SsMotion.medium});

  final Widget sliver;
  final bool play;
  final Duration duration;

  @override
  State<SsSliverEntrance> createState() => _SsSliverEntranceState();
}

class _SsSliverEntranceState extends State<SsSliverEntrance> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.duration, value: widget.play ? 0 : 1);
  late final _t = CurvedAnimation(parent: _c, curve: SsMotion.enter);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.value < 1 && !_c.isAnimating) {
      if (reduceMotion(context)) {
        _c.value = 1;
      } else {
        _c.forward();
      }
    }
  }

  @override
  void dispose() {
    _t.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SliverFadeTransition(opacity: _t, sliver: widget.sliver);
}
