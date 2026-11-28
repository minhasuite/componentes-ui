// v1.14.0 "interface e animação": a folha de baixo com alturas fixas (detentes) e a mola entre elas. É o que o
// `showSsSheet(detents: [.33, .5, 1])` monta; par do Ss::DrawerComponent(detents:) do web no celular.
import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';
import '../motion.dart';
import '../motion_view.dart';
import '../ss_sheet.dart';
import '../ss_strings.dart';
import '../v19/transicoes/predictive_back.dart';
import 'strings.dart';

/// Corpo da folha com alturas fixas: [detents] em fração da altura disponível (ex. `[.33, .5, 1]`), começando em
/// `detents[initial]`. Arrastar a alça (ou o conteúdo quando ele está no topo) leva a folha junto do dedo; ao
/// soltar, ela vai para a altura mais perto de onde o gesto a levaria (a velocidade conta) com uma mola de verdade
/// ([spring]: passa um pouco e assenta). Abaixo da menor, com [dismissible], fecha. No leitor de tela, a alça diz a
/// altura ("50% da tela") e as ações de aumentar e diminuir trocam de altura; no teclado, ↑ e ↓ com o foco nela.
/// Com "reduzir movimento", troca de altura sem mola.
///
/// Normalmente pelo `showSsSheet(context, detents: [.33, .5, 1], child: ...)`.
class SsDetentSheet extends StatefulWidget {
  const SsDetentSheet({
    super.key,
    required this.child,
    required this.detents,
    this.initial = 0,
    this.title,
    this.subtitle,
    this.icon,
    this.dismissible = true,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 16),
    this.onDetentChanged,
  }) : assert(detents.length > 0);

  final Widget child;
  final List<double> detents;
  final int initial;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final bool dismissible;
  final EdgeInsetsGeometry padding;
  final ValueChanged<int>? onDetentChanged;

  /// A mola entre as alturas (~10% além do ponto e assenta), a mesma sensação do [SsMotion.bounce].
  static final spring = SpringDescription.withDampingRatio(mass: 1, stiffness: 420, ratio: .72);

  /// A altura (índice de [detents]) para onde a folha vai ao soltar em [fraction] com a velocidade [velocity]
  /// (fração por segundo, positiva para cima). Nulo: fecha (abaixo da menor, descendo).
  static int? target(List<double> detents, double fraction, double velocity, {bool dismissible = true}) {
    final ds = [...detents]..sort();
    // Para onde o gesto levaria em ~120 ms.
    final alvo = fraction + velocity * .12;
    if (dismissible && alvo < ds.first * .6) return null;
    var best = 0;
    for (var i = 1; i < ds.length; i++) {
      if ((ds[i] - alvo).abs() < (ds[best] - alvo).abs()) best = i;
    }
    return detents.indexOf(ds[best]);
  }

  @override
  State<SsDetentSheet> createState() => _SsDetentSheetState();
}

class _SsDetentSheetState extends State<SsDetentSheet> with SingleTickerProviderStateMixin {
  late final _h = AnimationController.unbounded(vsync: this, value: _ds[_idx]);
  late int _idx = widget.initial.clamp(0, widget.detents.length - 1);
  double _max = 1;
  bool _arrastando = false;

  List<double> get _ds => widget.detents;

  @override
  void dispose() {
    _h.dispose();
    super.dispose();
  }

  void _drag(double dy) {
    _arrastando = true;
    _h.stop();
    final topo = _ds.reduce(math.max);
    // Acima da maior, resiste (vai a um terço do dedo).
    final passo = -dy / _max;
    final v = _h.value + (_h.value > topo && passo > 0 ? passo / 3 : passo);
    _h.value = v.clamp(0.0, 1.05);
  }

  void _solta(double velocityPx) {
    _arrastando = false;
    final v = -velocityPx / _max;
    final i = SsDetentSheet.target(_ds, _h.value, v, dismissible: widget.dismissible);
    if (i == null) {
      Navigator.maybePop(context);
      return;
    }
    _vai(i, velocity: v);
  }

  void _vai(int i, {double velocity = 0}) {
    final mudou = i != _idx;
    setState(() => _idx = i);
    if (mudou) {
      SsHaptics.selection();
      widget.onDetentChanged?.call(i);
    }
    if (reduceMotion(context)) {
      _h.value = _ds[i];
      return;
    }
    _h.animateWith(SpringSimulation(SsDetentSheet.spring, _h.value, _ds[i], velocity));
  }

  void _passo(int dir) {
    final ordem = [for (var i = 0; i < _ds.length; i++) i]..sort((a, b) => _ds[a].compareTo(_ds[b]));
    final k = ordem.indexOf(_idx) + dir;
    if (k >= 0 && k < ordem.length) _vai(ordem[k]);
  }

  /// A altura vizinha da atual (dir 1 = a de cima), ou a própria.
  double _vizinho(int dir) {
    final ordem = [..._ds]..sort();
    final k = (ordem.indexOf(_ds[_idx]) + dir).clamp(0, ordem.length - 1);
    return ordem[k];
  }

  bool _onScroll(ScrollNotification n) {
    // O conteúdo no topo puxado para baixo arrasta a folha; ao soltar, ela assenta.
    if (n is OverscrollNotification && n.dragDetails != null && n.overscroll < 0) {
      _drag(-n.overscroll);
    } else if (n is ScrollEndNotification && _arrastando) {
      _solta(n.dragDetails?.velocity.pixelsPerSecond.dy ?? 0);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final t = SsInterfaceStrings.of(context);
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    final topo = _ds.reduce(math.max);
    final pct = (_ds[_idx] * 100).round();
    final ordem = [..._ds]..sort();
    final podeSubir = _ds[_idx] < ordem.last;
    final podeDescer = _ds[_idx] > ordem.first;

    final alca = Semantics(
      container: true,
      button: true,
      label: t.sheetHandle,
      hint: t.sheetHint,
      value: SsInterfaceStrings.fill(t.sheetSize, {'percent': pct}),
      increasedValue: podeSubir ? SsInterfaceStrings.fill(t.sheetSize, {'percent': (_vizinho(1) * 100).round()}) : null,
      decreasedValue: podeDescer
          ? SsInterfaceStrings.fill(t.sheetSize, {'percent': (_vizinho(-1) * 100).round()})
          : null,
      onIncrease: podeSubir ? () => _passo(1) : null,
      onDecrease: podeDescer ? () => _passo(-1) : null,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowUp): () => _passo(1),
          const SingleActivator(LogicalKeyboardKey.arrowDown): () => _passo(-1),
        },
        child: Focus(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // Tocar sobe uma altura; na maior, volta à menor.
            onTap: () => podeSubir ? _passo(1) : _vai(_ds.indexOf(ordem.first)),
            // Alvo de 48 (a pílula é de 38 × 5, no meio).
            child: SizedBox(
              height: 48,
              child: Center(
                child: Container(
                  width: 38,
                  height: 5,
                  decoration: BoxDecoration(color: c.muted2, borderRadius: BorderRadius.circular(AppRadius.pill)),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return SsPredictiveBackScope(
      child: LayoutBuilder(
        builder: (context, box) {
          _max = box.maxHeight.isFinite ? box.maxHeight : MediaQuery.sizeOf(context).height;
          return GestureDetector(
            // A alça e o cabeçalho arrastam a folha.
            onVerticalDragUpdate: (d) => _drag(d.delta.dy),
            onVerticalDragEnd: (d) => _solta(d.velocity.pixelsPerSecond.dy),
            child: AnimatedBuilder(
              animation: _h,
              builder: (context, child) {
                final h = (_max * _h.value.clamp(0.0, topo * 1.05)).clamp(0.0, _max);
                // Muito baixa (no gesto de fechar, no fim da mola), o conteúdo não encolhe: é recortado.
                return SizedBox(
                  height: h,
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.topCenter,
                      minHeight: 0,
                      maxHeight: math.max(h, 160),
                      child: child,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: EdgeInsets.only(bottom: kb),
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      alca,
                      if (widget.title != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                          child: SsSheetHeader(widget.title!, subtitle: widget.subtitle, icon: widget.icon),
                        ),
                      Expanded(
                        child: NotificationListener<ScrollNotification>(
                          onNotification: _onScroll,
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            padding: widget.padding.add(const EdgeInsets.only(top: 8)),
                            child: widget.child,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// O `showSsSheet(detents:)`: a folha modal com o [SsDetentSheet] dentro.
Future<T?> showSsDetentSheet<T>(
  BuildContext context, {
  required Widget child,
  required List<double> detents,
  int initial = 0,
  String? title,
  String? subtitle,
  IconData? icon,
  bool dismissible = true,
  EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(20, 0, 20, 16),
  bool useRootNavigator = true,
}) => showModalBottomSheet<T>(
  context: context,
  // v1.14.3: por cima da barra de abas (ver [showSsSheet]).
  useRootNavigator: useRootNavigator,
  isScrollControlled: true,
  useSafeArea: true,
  isDismissible: dismissible,
  // O arrastar é da folha (com as alturas); o do sistema fecharia direto.
  enableDrag: false,
  showDragHandle: false,
  barrierLabel: SsStrings.of(context).close,
  sheetAnimationStyle: SsOverlayMotion.sheet(context),
  builder: (context) => SsDetentSheet(
    detents: detents,
    initial: initial,
    title: title,
    subtitle: subtitle,
    icon: icon,
    dismissible: dismissible,
    padding: padding,
    child: child,
  ),
);
