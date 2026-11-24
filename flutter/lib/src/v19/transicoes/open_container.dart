import 'package:material_ui/material_ui.dart';

import '../../app_theme.dart';
import '../../motion.dart';
import 'predictive_back.dart';

/// De onde a tela aberta sai: o retângulo do cartão (no Navigator), o que ele
/// mostra e o aviso de esconder o cartão enquanto a tela está aberta.
class _Origem {
  _Origem(this.rect, this.closed, this.radius);
  Rect rect;
  WidgetBuilder closed;
  double radius;
  final aberto = ValueNotifier<bool>(false);
}

final _origens = <Object, _Origem>{};

/// Lista → detalhe (container transform): o cartão cresce até virar a tela e,
/// ao voltar (botão, seta ou o gesto preditivo do Android 14+), encolhe de
/// novo para o lugar dele. Enquanto a tela está aberta, o cartão some daqui
/// (é ele que "voa").
///
/// Dois jeitos de abrir:
///  * [openBuilder]: o próprio container empurra a [SsOpenRoute];
///  * go_router: dê um [tag] (`'pedido-12'`), abra pela rota em [onOpen]
///    (`() => context.push('/pedidos/12')`) e, no `GoRoute`, use
///    `pageBuilder: (c, s) => SsOpenPage(tag: 'pedido-${s.pathParameters['id']}', child: ...)`.
///
/// [closedBuilder] recebe o `open` para pôr no toque do cartão. Com "reduzir
/// movimento", a tela só aparece (sem crescer).
class SsOpenContainer<T> extends StatefulWidget {
  const SsOpenContainer({
    super.key,
    required this.closedBuilder,
    this.openBuilder,
    this.onOpen,
    this.tag,
    this.onClosed,
    this.radius = AppRadius.card,
  }) : assert(openBuilder != null || onOpen != null, 'Dê openBuilder ou onOpen (go_router).');

  final Widget Function(BuildContext context, VoidCallback open) closedBuilder;
  final WidgetBuilder? openBuilder;

  /// Abre por fora (go_router): o container só guarda de onde sai.
  final VoidCallback? onOpen;

  /// O mesmo do [SsOpenPage.tag] (go_router). Padrão: um por container.
  final Object? tag;

  /// Chamado quando a tela aberta por [openBuilder] fecha (com o resultado).
  final ValueChanged<T?>? onClosed;

  /// Raio do cartão fechado (vai a 0 na tela cheia).
  final double radius;

  @override
  State<SsOpenContainer<T>> createState() => _SsOpenContainerState<T>();
}

class _SsOpenContainerState<T> extends State<SsOpenContainer<T>> {
  late final Object _proprio = Object();
  Object get _tag => widget.tag ?? _proprio;
  _Origem? _origem;

  _Origem _registra() {
    final nav = Navigator.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final navBox = nav.context.findRenderObject() as RenderBox?;
    final rect = box != null && navBox != null && box.hasSize
        ? box.localToGlobal(Offset.zero, ancestor: navBox) & box.size
        : Rect.zero;
    Widget fechado(BuildContext c) => widget.closedBuilder(c, () {});
    final o = _origens[_tag];
    if (o != null) {
      o
        ..rect = rect
        ..closed = fechado
        ..radius = widget.radius;
      return _ouve(o);
    }
    return _ouve(_origens[_tag] = _Origem(rect, fechado, widget.radius));
  }

  _Origem _ouve(_Origem o) {
    if (!identical(o, _origem)) {
      _origem?.aberto.removeListener(_muda);
      _origem = o..aberto.addListener(_muda);
    }
    return o;
  }

  void _muda() {
    if (mounted) setState(() {});
  }

  Future<void> _abrir() async {
    _registra();
    if (widget.onOpen != null) return widget.onOpen!();
    final r = await Navigator.of(context).push<T>(SsOpenRoute<T>(tag: _tag, builder: widget.openBuilder!));
    widget.onClosed?.call(r);
  }

  @override
  void dispose() {
    _origem?.aberto.removeListener(_muda);
    final o = _origens[_tag];
    if (identical(o, _origem) && !(o?.aberto.value ?? false)) _origens.remove(_tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aberto = _origem?.aberto.value ?? false;
    // Fica no lugar (mesmo tamanho), só invisível: a lista não pula.
    return Opacity(opacity: aberto ? 0 : 1, child: widget.closedBuilder(context, _abrir));
  }
}

/// Rota do container transform: cresce do retângulo do [SsOpenContainer] de
/// mesmo [tag] até a tela e volta encolhendo. O gesto de voltar preditivo
/// (Android 14+) leva a tela de volta ao cartão junto com o dedo. Sem origem
/// conhecida (link direto, tag que não está na tela), sobe e aparece.
class SsOpenRoute<T> extends PageRoute<T> {
  SsOpenRoute({required this.builder, this.tag, super.settings});

  final WidgetBuilder builder;
  final Object? tag;

  bool _rapido = false;
  _Origem? get _origem => tag == null ? null : _origens[tag];

  @override
  void install() {
    _rapido = reduceMotion(navigator!.context);
    super.install();
  }

  @override
  TickerFuture didPush() {
    _origem?.aberto.value = true;
    return super.didPush();
  }

  @override
  void dispose() {
    // Só depois da volta (a rota é descartada quando a animação termina).
    _origem?.aberto.value = false;
    super.dispose();
  }

  @override
  Duration get transitionDuration => _rapido ? SsMotion.short : const Duration(milliseconds: 460); // 460/380: ritmo próprio do container

  @override
  Duration get reverseTransitionDuration => _rapido ? SsMotion.short : const Duration(milliseconds: 380);

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) =>
      builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final o = _origem;
    if (_rapido) return FadeTransition(opacity: animation, child: child);
    if (o == null || o.rect.isEmpty) {
      return SsBackGestureListener(
        route: this,
        builder: (context, phase, _, edge) => phase != SsBackPhase.idle
            ? SsBackShrink(animation: animation, edge: edge, child: child)
            : const FadeUpwardsPageTransitionsBuilder().buildTransitions(
                this,
                context,
                animation,
                secondaryAnimation,
                child,
              ),
      );
    }
    return SsBackGestureListener(
      route: this,
      builder: (context, _, _, _) =>
          _Transformacao(route: this, origem: o, animation: animation, cor: SsColors.of(context).surface, child: child),
    );
  }
}

/// Página do go_router com o container transform: mesmo [tag] do
/// [SsOpenContainer] que abriu. `GoRoute(path: ':id', pageBuilder: (c, s) =>
/// SsOpenPage(key: s.pageKey, tag: 'pedido-${s.pathParameters['id']}', child: PedidoPage(...)))`.
class SsOpenPage<T> extends Page<T> {
  const SsOpenPage({
    required this.tag,
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Object tag;
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    // Lê sempre a página atual (o go_router troca a Page sem trocar a rota).
    late final SsOpenRoute<T> rota;
    rota = SsOpenRoute<T>(tag: tag, settings: this, builder: (_) => (rota.settings as SsOpenPage<T>).child);
    return rota;
  }
}

class _Transformacao extends StatelessWidget {
  const _Transformacao({
    required this.route,
    required this.origem,
    required this.animation,
    required this.cor,
    required this.child,
  });

  final ModalRoute<dynamic> route;
  final _Origem origem;
  final Animation<double> animation;
  final Color cor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curva = CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn, reverseCurve: Curves.easeInCubic);
    return LayoutBuilder(
      builder: (context, box) {
        final tela = box.biggest;
        final de = origem.rect;
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, aberta) {
            // No gesto, a tela segue o dedo sem curva (senão pula ao soltar).
            final t = route.popGestureInProgress ? animation.value : curva.value;
            final r = Rect.lerp(de, Offset.zero & tela, t)!;
            // Crossfade: o fechado some no primeiro terço, o aberto entra depois.
            final sai = (1 - t / .3).clamp(0.0, 1.0);
            final entra = ((t - .2) / .5).clamp(0.0, 1.0);
            return Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(color: AppColors.scrim.withValues(alpha: .25 * t)),
                  ),
                ),
                Positioned.fromRect(
                  rect: r,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(origem.radius * (1 - t)),
                    child: ColoredBox(
                      color: cor,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Sempre no Stack (só a opacidade muda): senão o aberto troca de posição e perde o estado.
                          Opacity(
                            opacity: sai,
                            child: IgnorePointer(
                              child: FittedBox(
                                fit: BoxFit.fitWidth,
                                alignment: Alignment.topLeft,
                                child: SizedBox.fromSize(
                                  size: de.size,
                                  child: Material(color: cor, child: origem.closed(context)),
                                ),
                              ),
                            ),
                          ),
                          Opacity(
                            opacity: entra,
                            child: FittedBox(
                              fit: BoxFit.fitWidth,
                              alignment: Alignment.topLeft,
                              child: SizedBox.fromSize(size: tela, child: aberta),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
