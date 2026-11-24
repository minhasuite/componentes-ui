// v1.9 · paridade_app: passeio guiado (par do Ss::TourComponent).
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../app_theme.dart';
import '../../motion.dart';
import '../../ss_button.dart';
import '../../ss_strings.dart';
import 'comum.dart';

/// Um passo do [SsTour]: o [target] é a `GlobalKey` do widget destacado (o
/// `data-tour-step` do web).
class SsTourStep {
  const SsTourStep({required this.target, required this.title, this.text});

  final GlobalKey target;
  final String title;
  final String? text;
}

/// Passeio guiado: escurece a tela com um recorte em volta do alvo de cada
/// passo e mostra o balão com "n de total", título, texto e Pular / Voltar /
/// Próximo (no último, Concluir). O recorte vai de um alvo ao outro com mola
/// e o alvo rola para a vista. Passo cujo alvo não está montado é pulado
/// (como no web). O voltar do sistema encerra (igual a Pular).
///
/// "Mostrar uma vez": com [store], abre sozinho ([autostart]) só se a chave
/// `ss-tour:<id>` ainda não foi gravada, e grava `"1"` ao concluir ou pular
/// (mesma chave e valor do `localStorage` do web). Para abrir pelo botão
/// ("Ver tour"), use uma `GlobalKey<SsTourState>` e `start()`, ou o
/// [SsTour.show] solto.
///
/// ```dart
/// SsTour(id: 'painel-v2', store: prefsStore, steps: [SsTourStep(target: kpisKey, title: 'Seus números', text: '…')], child: tela)
/// ```
class SsTour extends StatefulWidget {
  const SsTour({
    super.key,
    required this.id,
    required this.steps,
    required this.child,
    this.store,
    this.autostart = true,
    this.onFinish,
    this.useRootNavigator = true,
  });

  final String id;
  final List<SsTourStep> steps;
  final Widget child;

  /// Onde lembrar que já viu. Nulo: não lembra (e não abre sozinho).
  final SsSeenStore? store;

  /// Abre sozinho depois do 1º quadro se ainda não viu.
  final bool autostart;

  /// `true` = concluiu; `false` = pulou.
  final ValueChanged<bool>? onFinish;

  /// Ver [SsTour.show].
  final bool useRootNavigator;

  /// Chave do "já vi" ([SsSeenStore]); a mesma do web.
  static String keyFor(String id) => 'ss-tour:$id';

  /// Abre o passeio agora (sem olhar o "já vi"). Devolve `true` se concluiu,
  /// `false` se pulou ou se nenhum alvo estava na tela. [useRootNavigator]
  /// falso cobre só o navegador mais próximo (como no `showDialog`).
  static Future<bool> show(
    BuildContext context, {
    required List<SsTourStep> steps,
    bool useRootNavigator = true,
  }) async {
    final validos = steps.where((s) => s.target.currentContext != null).toList();
    if (validos.isEmpty) return false;
    final r = await Navigator.of(context, rootNavigator: useRootNavigator).push<bool>(
      PageRouteBuilder<bool>(
        opaque: false,
        barrierDismissible: false,
        transitionDuration: reduceMotion(context) ? Duration.zero : SsMotion.base,
        reverseTransitionDuration: reduceMotion(context) ? Duration.zero : SsMotion.fast,
        pageBuilder: (_, _, _) => _TourLayer(steps: validos),
        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      ),
    );
    return r ?? false;
  }

  @override
  State<SsTour> createState() => SsTourState();
}

class SsTourState extends State<SsTour> {
  bool _aberto = false;

  @override
  void initState() {
    super.initState();
    if (widget.autostart && widget.store != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _talvez());
    }
  }

  Future<void> _talvez() async {
    final visto = await widget.store!.read(SsTour.keyFor(widget.id));
    if (!mounted || visto == '1') return;
    await start();
  }

  /// Abre o passeio (o botão "Ver tour"). Grava o "já vi" ao terminar.
  Future<bool> start() async {
    if (_aberto) return false;
    _aberto = true;
    final ok = await SsTour.show(context, steps: widget.steps, useRootNavigator: widget.useRootNavigator);
    _aberto = false;
    await widget.store?.write(SsTour.keyFor(widget.id), '1');
    widget.onFinish?.call(ok);
    return ok;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _TourLayer extends StatefulWidget {
  const _TourLayer({required this.steps});
  final List<SsTourStep> steps;

  @override
  State<_TourLayer> createState() => _TourLayerState();
}

class _TourLayerState extends State<_TourLayer> {
  int _i = 0;
  final _pop = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ir(0));
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  Future<void> _ir(int i) async {
    setState(() => _i = i);
    final ctx = widget.steps[i].target.currentContext;
    if (ctx != null && ctx.mounted) {
      await Scrollable.ensureVisible(
        ctx,
        alignment: .5,
        duration: reduceMotion(context) ? Duration.zero : SsMotion.base,
      );
    }
    if (!mounted) return;
    _medir();
    _pop.requestFocus();
  }

  void _fim(bool ok) => Navigator.of(context).pop(ok);

  Rect? _rect;
  Size? _tela;

  // Mede o alvo depois do quadro (nunca durante o build), em coordenadas da tela.
  void _medir() {
    if (!mounted) return;
    final box = widget.steps[_i].target.currentContext?.findRenderObject();
    final r = box is RenderBox && box.attached && box.hasSize
        ? (box.localToGlobal(Offset.zero) & box.size).inflate(8)
        : null;
    if (r != _rect) setState(() => _rect = r);
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = SsStrings.of(context);
    final step = widget.steps[_i];
    final n = widget.steps.length;
    final ultimo = _i == n - 1;
    final tela = MediaQuery.sizeOf(context);
    if (tela != _tela) {
      // Girou a tela ou mudou o tamanho: mede de novo no próximo quadro.
      _tela = tela;
      WidgetsBinding.instance.addPostFrameCallback((_) => _medir());
    }
    final alvo = _rect;
    final dur = reduceMotion(context) ? Duration.zero : SsMotion.indicator;
    final tamanho = MediaQuery.sizeOf(context);
    final buraco = alvo ?? Rect.zero;

    final balao = Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: step.title,
      liveRegion: true,
      child: Focus(
        focusNode: _pop,
        child: Material(
          color: c.surface,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ssFill(s.tourCount, {'n': _i + 1, 'total': n}),
                  style: AppTheme.number(context, size: AppType.meta, color: c.accentText),
                ),
                const SizedBox(height: 4),
                Text(
                  step.title,
                  style: TextStyle(fontSize: AppType.md, fontWeight: FontWeight.w800, color: c.ink),
                ),
                if (step.text != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    step.text!,
                    style: TextStyle(fontSize: AppType.set, height: AppType.leading, color: c.ink2),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (!ultimo) SsButton.text(label: s.skip, onPressed: () => _fim(false)),
                    const Spacer(),
                    if (_i > 0) ...[
                      SsButton.ghost(label: s.back, expand: false, onPressed: () => _ir(_i - 1)),
                      const SizedBox(width: 8),
                    ],
                    SsButton(
                      label: ultimo ? s.tourDone : s.tourNext,
                      expand: false,
                      onPressed: ultimo ? () => _fim(true) : () => _ir(_i + 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _fim(false);
      },
      child: Material(
        type: MaterialType.transparency,
        // Até medir o 1º alvo, só segura o toque (o véu nasce já no lugar, sem voar do meio).
        child: alvo == null
            ? const AbsorbPointer(child: SizedBox.expand())
            : TweenAnimationBuilder<Rect?>(
                tween: RectTween(begin: buraco, end: buraco),
                duration: dur,
                curve: SsMotion.bounce,
                builder: (context, r, _) {
                  final rr = r ?? buraco;
                  return Stack(
                    children: [
                      // Toque fora do balão não faz nada (como no web).
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {},
                          child: ExcludeSemantics(
                            child: CustomPaint(
                              painter: _Recorte(hole: rr, ring: c.accent),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: SafeArea(
                          child: CustomSingleChildLayout(
                            delegate: _Posicao(rr, MediaQuery.paddingOf(context)),
                            child: SizedBox(width: math.min(320, tamanho.width - 24), child: balao),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

/// Véu escuro com o recorte arredondado e o anel da marca em volta.
class _Recorte extends CustomPainter {
  _Recorte({required this.hole, required this.ring});
  final Rect hole;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(hole, const Radius.circular(14));
    final veu = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(rr);
    canvas.drawPath(veu, Paint()..color = AppColors.scrim.withValues(alpha: .58));
    if (hole.width > 0) {
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = ring,
      );
    }
  }

  @override
  bool shouldRepaint(_Recorte old) => old.hole != hole || old.ring != ring;
}

/// O balão embaixo do alvo (ou em cima, se não couber), preso nas bordas.
class _Posicao extends SingleChildLayoutDelegate {
  _Posicao(this.hole, this.pad);
  final Rect hole;
  final EdgeInsets pad;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size child) {
    // O SafeArea desloca a área: o recorte está em coordenadas da tela.
    final h = hole.shift(Offset(-pad.left, -pad.top));
    var top = h.bottom + 12;
    if (top + child.height > size.height - 12) top = math.max(12.0, h.top - 12 - child.height);
    final double left = h.left.clamp(12.0, math.max(12.0, size.width - child.width - 12));
    return Offset(left, top.clamp(12.0, math.max(12.0, size.height - child.height - 12)).toDouble());
  }

  @override
  bool shouldRelayout(_Posicao old) => old.hole != hole || old.pad != pad;
}
