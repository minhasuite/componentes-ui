// v1.9 · UX transversal: a barra de baixo que some ao rolar para baixo e volta ao rolar para cima
// (SsNavBar(hideOnScroll:) e SsNavScaffold(hideNavOnScroll:)).
import 'package:material_ui/material_ui.dart';

import '../../motion.dart';

/// Quanto rolar (px) num sentido antes de esconder ou mostrar: sem isso a barra pisca a cada tremida do dedo.
const ssHideOnScrollSlop = 24.0;

/// A regra de esconder ao rolar, para a [SsNavBar] e o [SsNavScaffold]: rolar a lista principal (vertical,
/// profundidade 0) para baixo esconde ([visibility] vai a 0); para cima, ou chegar ao topo, mostra (1).
/// Leitor de tela ligado ([MediaQueryData.accessibleNavigation]): nunca esconde. Reduzir movimento: troca
/// sem animar.
class SsScrollHide {
  SsScrollHide(TickerProvider vsync)
    : visibility = AnimationController(vsync: vsync, value: 1, duration: SsMotion.base);

  /// 1 mostrando, 0 escondida.
  final AnimationController visibility;

  double _acc = 0;
  bool _reduce = false;
  bool _locked = false;

  /// Chame no build (ou no didChangeDependencies) com o contexto da barra.
  void configure(BuildContext context) {
    _reduce = reduceMotion(context);
    _locked = MediaQuery.maybeAccessibleNavigationOf(context) ?? false;
    if (_locked) show();
  }

  bool get hidden => visibility.value < 1 && (visibility.status == AnimationStatus.reverse || visibility.value == 0);

  /// Para o `NotificationListener<ScrollNotification>` ou o `ScrollNotificationObserver`. Não consome a notificação.
  bool handle(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    final m = n.metrics;
    if (m.pixels <= m.minScrollExtent + 1) {
      _acc = 0;
      show();
      return false;
    }
    if (n is! ScrollUpdateNotification) return false;
    final delta = n.scrollDelta ?? 0;
    if (delta == 0) return false;
    if ((delta > 0) != (_acc > 0)) _acc = 0;
    _acc += delta;
    if (_acc > ssHideOnScrollSlop) hide();
    if (_acc < -ssHideOnScrollSlop) show();
    return false;
  }

  void show() {
    if (visibility.value == 1 && !visibility.isAnimating) return;
    _reduce ? visibility.value = 1 : visibility.forward();
  }

  void hide() {
    if (_locked || (visibility.value == 0 && !visibility.isAnimating)) return;
    _reduce ? visibility.value = 0 : visibility.reverse();
  }

  void dispose() => visibility.dispose();
}

/// A barra recortada pela [visibility]: desce para fora da tela (a altura encolhe por cima, a parte de cima da
/// barra fica à mostra até sumir). Escondida, sai do foco do teclado.
class SsHideOnScrollBox extends AnimatedWidget {
  const SsHideOnScrollBox({super.key, required Animation<double> visibility, required this.child})
    : super(listenable: visibility);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final v = (listenable as Animation<double>).value.clamp(0.0, 1.0);
    if (v == 1) return child;
    return ExcludeFocus(
      excluding: v == 0,
      child: ClipRect(
        child: Align(alignment: Alignment.topCenter, heightFactor: Curves.easeOut.transform(v), child: child),
      ),
    );
  }
}

/// O [SsNavScaffold] cuida do esconder: a [SsNavBar] dentro dele não escuta a rolagem sozinha.
class SsNavHideScope extends InheritedWidget {
  const SsNavHideScope({super.key, required super.child});

  static bool of(BuildContext context) => context.getInheritedWidgetOfExactType<SsNavHideScope>() != null;

  @override
  bool updateShouldNotify(SsNavHideScope old) => false;
}
