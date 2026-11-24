import 'package:flutter/services.dart' show PredictiveBackEvent, SwipeEdge;
import 'package:material_ui/material_ui.dart';

import '../../motion.dart';

/// Fase do gesto de voltar preditivo (Android 14+).
enum SsBackPhase { idle, start, update, commit, cancel }

/// Desenha a rota conforme o gesto: [progress] vai de 0 (dedo na borda) a 1
/// (atravessou a tela); [edge] é a borda de onde o dedo saiu.
typedef SsBackGestureBuilder = Widget Function(
  BuildContext context,
  SsBackPhase phase,
  double progress,
  SwipeEdge? edge,
);

// Uma rota só tem um dono do gesto (o binding avisa todos os observadores).
final _emGesto = <Route<dynamic>>{};

/// Ouve o gesto de voltar preditivo do Android 14+ para a [route] e redesenha
/// com [builder] enquanto o dedo arrasta. Só a rota do topo responde; rota que
/// não pode sair (`PopScope(canPop: false)`, a primeira) e "reduzir movimento"
/// deixam o gesto com o sistema (volta normal, sem prévia).
///
/// [drivesRoute] verdadeiro: o gesto move a animação da própria rota (página,
/// [SsOpenRoute]): soltou, a rota termina de sair; desistiu, volta. Falso: só
/// o desenho acompanha (folha, diálogo) e, ao soltar, chama `maybePop`.
///
/// O app precisa de `android:enableOnBackInvokedCallback="true"` no
/// `<application>` do `AndroidManifest.xml` (veja `docs/v19/transicoes.md`).
class SsBackGestureListener extends StatefulWidget {
  const SsBackGestureListener({super.key, required this.route, required this.builder, this.drivesRoute = true});

  final ModalRoute<dynamic> route;
  final SsBackGestureBuilder builder;
  final bool drivesRoute;

  @override
  State<SsBackGestureListener> createState() => _SsBackGestureListenerState();
}

class _SsBackGestureListenerState extends State<SsBackGestureListener>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  SsBackPhase _phase = SsBackPhase.idle;
  double _progress = 0;
  SwipeEdge? _edge;
  bool _meu = false;

  // Desistiu (sem mover a rota): o desenho volta ao lugar sozinho.
  late final AnimationController _volta = AnimationController(
    vsync: this,
    duration: SsMotion.short,
  )..addListener(_aoVoltar);
  double _de = 0;

  void _aoVoltar() {
    if (!mounted) return;
    setState(() => _progress = _de * (1 - Curves.easeOutCubic.transform(_volta.value)));
    if (_volta.isCompleted) setState(() => _phase = SsBackPhase.idle);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_meu) _emGesto.remove(widget.route);
    _volta.dispose();
    super.dispose();
  }

  bool get _pode {
    final r = widget.route;
    return mounted && r.isCurrent && r.popGestureEnabled && !reduceMotion(context) && !_emGesto.contains(r);
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    if (backEvent.isButtonEvent || !_pode) return false;
    _meu = true;
    _emGesto.add(widget.route);
    _volta.stop();
    if (widget.drivesRoute) widget.route.handleStartBackGesture(progress: 1 - backEvent.progress);
    setState(() {
      _phase = SsBackPhase.start;
      _progress = backEvent.progress;
      _edge = backEvent.swipeEdge;
    });
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    if (!_meu) return;
    if (widget.drivesRoute) widget.route.handleUpdateBackGestureProgress(progress: 1 - backEvent.progress);
    setState(() {
      _phase = SsBackPhase.update;
      _progress = backEvent.progress;
    });
  }

  @override
  void handleCommitBackGesture() {
    if (!_meu) return;
    _meu = false;
    _emGesto.remove(widget.route);
    setState(() => _phase = SsBackPhase.commit);
    if (widget.drivesRoute) {
      widget.route.handleCommitBackGesture();
    } else {
      widget.route.navigator?.maybePop();
    }
  }

  @override
  void handleCancelBackGesture() {
    if (!_meu) return;
    _meu = false;
    _emGesto.remove(widget.route);
    if (widget.drivesRoute) {
      widget.route.handleCancelBackGesture();
      setState(() => _phase = SsBackPhase.cancel);
    } else {
      _phase = SsBackPhase.cancel;
      _de = _progress;
      _volta.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gesto que move a rota: vale enquanto o Navigator diz que há gesto.
    final fase = widget.drivesRoute && !widget.route.popGestureInProgress ? SsBackPhase.idle : _phase;
    return widget.builder(context, fase, fase == SsBackPhase.idle ? 0 : _progress, _edge);
  }
}

/// A página encolhe enquanto o dedo arrasta (até 90%, com cantos redondos e um
/// passo para o lado do gesto) e mostra a anterior por trás; soltou, some.
/// [animation] é a da rota (1 = aberta), que o gesto move.
class SsBackShrink extends StatelessWidget {
  const SsBackShrink({super.key, required this.animation, required this.child, this.edge, this.radius = 28});

  final Animation<double> animation;
  final SwipeEdge? edge;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    child: child,
    builder: (context, child) {
      final v = animation.value.clamp(0.0, 1.0);
      final p = 1 - v;
      final cedo = Curves.easeOutCubic.transform((p * 2.5).clamp(0.0, 1.0));
      final lado = edge == SwipeEdge.right ? -1.0 : 1.0;
      final passo = (MediaQuery.sizeOf(context).width / 20 - 8).clamp(0.0, 40.0);
      return Opacity(
        // Some só no fim (o commit leva a rota até 0).
        opacity: (v * 3).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(lado * passo * cedo, 0),
          child: Transform.scale(
            scale: 1 - .1 * cedo,
            child: ClipRRect(borderRadius: BorderRadius.circular(radius * cedo), child: child),
          ),
        ),
      );
    },
  );
}

/// Transição de página da suíte com o voltar preditivo do Android 14+: a ida
/// e a volta pelo botão são as do [fallback] (padrão: a de sempre, subir e
/// aparecer); durante o gesto de voltar, a página encolhe ([SsBackShrink]) e
/// mostra a anterior. Já vem no `AppTheme.build` (Android); fora dele:
/// `PageTransitionsTheme(builders: {TargetPlatform.android: SsPredictiveBackPageTransitionsBuilder()})`.
class SsPredictiveBackPageTransitionsBuilder extends PageTransitionsBuilder {
  const SsPredictiveBackPageTransitionsBuilder({this.fallback = const FadeUpwardsPageTransitionsBuilder()});

  final PageTransitionsBuilder fallback;

  @override
  Duration get transitionDuration => fallback.transitionDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition => fallback.delegatedTransition;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => SsBackGestureListener(
    route: route,
    builder: (context, phase, _, edge) {
      // O filho da rota tem GlobalKey: trocar de embrulho não perde o estado da tela.
      if (phase != SsBackPhase.idle) return SsBackShrink(animation: animation, edge: edge, child: child);
      return fallback.buildTransitions(route, context, animation, secondaryAnimation, child);
    },
  );
}

/// Como a folha ou o diálogo reage ao gesto de voltar.
enum SsPredictiveBackStyle {
  /// Desce um pouco e encolhe a partir de baixo.
  sheet,

  /// Encolhe no centro.
  dialog,
}

/// Prévia do voltar preditivo numa folha ou num diálogo: enquanto o dedo
/// arrasta, o conteúdo encolhe (e a folha desce um pouco); soltou, fecha
/// (`maybePop`, respeita o `PopScope`); desistiu, volta. O [SsSheet] e o
/// [SsRouteScale] (diálogos do pacote) já usam. Fora de rota não faz nada.
class SsPredictiveBackScope extends StatelessWidget {
  const SsPredictiveBackScope({super.key, required this.child, this.style = SsPredictiveBackStyle.sheet});

  final Widget child;
  final SsPredictiveBackStyle style;

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route == null) return child;
    return SsBackGestureListener(
      route: route,
      drivesRoute: false,
      builder: (context, phase, progress, _) {
        final e = Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0));
        final folha = style == SsPredictiveBackStyle.sheet;
        // Sempre o mesmo embrulho (identidade parado): o conteúdo não perde o estado.
        final m = Matrix4.translationValues(0, folha ? 48 * e : 0, 0);
        return Transform(
          transform: m,
          child: Transform.scale(
            scale: 1 - (folha ? .06 : .1) * e,
            alignment: folha ? Alignment.bottomCenter : Alignment.center,
            child: child,
          ),
        );
      },
    );
  }
}
