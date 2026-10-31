import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'motion.dart';

/// Um lado do [SsSwipeAction]: o fundo [color] com [icon] e [label] que
/// aparece ao deslizar, e o que acontece ao soltar depois do limite.
/// [destructive]: o item sai encolhendo (excluir, arquivar).
class SsSwipeSide {
  const SsSwipeSide({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTrigger,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTrigger;
  final bool destructive;
}

/// Deslizar o item para os lados para uma ação rápida. [start] é o lado que
/// aparece ao puxar para a direita; [end], para a esquerda. Até o limite (35%
/// da largura) o fundo cresce com o ícone; depois dele o item resiste
/// (elástico), dá um tique e o ícone dá um "pop". Soltar depois do limite
/// chama `onTrigger`; antes, o item volta com mola.
///
/// No lado destrutivo o item encolhe a altura e então `onTrigger` é chamado:
/// remova o item da lista ali mesmo (otimista, com "desfazer"). Se ele não
/// sair, volta ao lugar. O leitor de tela aciona os lados pelas ações
/// personalizadas, com o [SsSwipeSide.label].
///
/// `SsSwipeAction(key: ValueKey(i.id), end: SsSwipeSide(icon: Icons.delete_outline, label: 'Excluir', color: AppColors.danger, destructive: true, onTrigger: () => remover(i)), child: ...)`
class SsSwipeAction extends StatefulWidget {
  const SsSwipeAction({super.key, required this.child, this.start, this.end});

  final Widget child;
  final SsSwipeSide? start;
  final SsSwipeSide? end;

  /// Fração da largura que arma a ação.
  static const threshold = .35;

  /// Deslocamento mostrado para um arrasto [raw] numa largura [width]: igual
  /// até o limite, depois cresce cada vez menos (no máximo +25% da largura).
  static double rubber(double raw, double width) {
    final limit = width * threshold;
    final a = raw.abs();
    if (a <= limit) return raw;
    final over = a - limit;
    final cap = width * .25;
    return raw.sign * (limit + over * cap / (over + cap));
  }

  @override
  State<SsSwipeAction> createState() => _SsSwipeActionState();
}

class _SsSwipeActionState extends State<SsSwipeAction> with TickerProviderStateMixin {
  late final _dx = AnimationController.unbounded(vsync: this);
  late final _size = AnimationController(vsync: this, value: 1, duration: const Duration(milliseconds: 240));
  double _raw = 0;
  double _width = 1;
  bool _armed = false;
  bool _busy = false;

  static const _spring = SpringDescription(mass: 1, stiffness: 520, damping: 30);

  @override
  void dispose() {
    _dx.dispose();
    _size.dispose();
    super.dispose();
  }

  SsSwipeSide? _sideFor(double dx) => dx > 0 ? widget.start : (dx < 0 ? widget.end : null);

  void _onStart(DragStartDetails _) {
    if (_busy) return;
    _dx.stop();
    _raw = _dx.value;
  }

  void _onUpdate(DragUpdateDetails d) {
    if (_busy) return;
    _raw += d.primaryDelta ?? 0;
    if (_sideFor(_raw) == null) _raw = 0;
    _dx.value = SsSwipeAction.rubber(_raw, _width);
    final armed = _raw.abs() >= _width * SsSwipeAction.threshold;
    if (armed != _armed) {
      if (armed) HapticFeedback.mediumImpact();
      setState(() => _armed = armed);
    }
  }

  void _onEnd(DragEndDetails d) {
    if (_busy) return;
    final side = _sideFor(_raw);
    if (_armed && side != null) {
      _trigger(side, d.primaryVelocity ?? 0);
    } else {
      _back(d.primaryVelocity ?? 0);
    }
  }

  void _back(double velocity) {
    _raw = 0;
    if (_armed) setState(() => _armed = false);
    if (reduceMotion(context)) {
      _dx.value = 0;
    } else {
      _dx.animateWith(SpringSimulation(_spring, _dx.value, 0, velocity));
    }
  }

  Future<void> _trigger(SsSwipeSide side, [double velocity = 0]) async {
    if (!side.destructive) {
      side.onTrigger();
      _back(velocity);
      return;
    }
    _busy = true;
    final reduce = reduceMotion(context);
    final sign = identical(side, widget.start) ? 1.0 : -1.0;
    if (reduce) {
      _dx.value = sign * _width;
      _size.value = 0;
    } else {
      await _dx.animateTo(sign * _width, duration: const Duration(milliseconds: 160), curve: Curves.easeIn);
      await _size.animateTo(0, curve: Curves.easeInOut);
    }
    if (!mounted) return;
    side.onTrigger();
    // O app não tirou o item (cancelou, deu erro): ele volta. O setState
    // garante o quadro em que a checagem roda.
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _busy = false;
      _raw = 0;
      _dx.value = 0;
      _size.value = 1;
      setState(() => _armed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.start;
    final end = widget.end;
    return Semantics(
      customSemanticsActions: {
        if (start != null) CustomSemanticsAction(label: start.label): () => _trigger(start),
        if (end != null) CustomSemanticsAction(label: end.label): () => _trigger(end),
      },
      child: SizeTransition(
        sizeFactor: _size,
        alignment: AlignmentDirectional.topStart,
        child: LayoutBuilder(
          builder: (context, box) {
            _width = box.maxWidth.isFinite && box.maxWidth > 0 ? box.maxWidth : 1;
            return GestureDetector(
              onHorizontalDragStart: _onStart,
              onHorizontalDragUpdate: _onUpdate,
              onHorizontalDragEnd: _onEnd,
              child: ClipRect(
                child: AnimatedBuilder(
                  animation: _dx,
                  child: widget.child,
                  builder: (context, child) {
                    // A mola para a ~0,001 px do zero: crava o zero.
                    final dx = _dx.value.abs() < .5 ? 0.0 : _dx.value;
                    final side = _sideFor(dx);
                    return SizedBox(
                      width: box.maxWidth.isFinite ? box.maxWidth : null,
                      child: Stack(
                        fit: StackFit.passthrough,
                        children: [
                          if (side != null) Positioned.fill(child: _background(side, dx)),
                          Transform.translate(offset: Offset(dx, 0), child: child),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _background(SsSwipeSide side, double dx) {
    final progress = (dx.abs() / (_width * SsSwipeAction.threshold)).clamp(0.0, 1.0);
    final reduce = reduceMotion(context);
    return ExcludeSemantics(
      child: ColoredBox(
        color: side.color.withValues(alpha: .55 + .45 * progress),
        child: Align(
          alignment: dx > 0 ? Alignment.centerLeft : Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Opacity(
              opacity: progress < .25 ? progress * 4 : 1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pop ao armar/desarmar: a chave nova reinicia o tween.
                  TweenAnimationBuilder<double>(
                    key: ValueKey(_armed),
                    tween: Tween(begin: _armed && !reduce ? 1.35 : 1, end: 1),
                    duration: reduce ? Duration.zero : const Duration(milliseconds: 260),
                    curve: Curves.easeOutBack,
                    builder: (_, pop, _) => Transform.scale(
                      scale: (.7 + .3 * progress) * pop,
                      child: Icon(side.icon, color: AppColors.onDark, size: 24),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    side.label,
                    style: const TextStyle(
                      color: AppColors.onDark,
                      fontSize: AppType.label,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
