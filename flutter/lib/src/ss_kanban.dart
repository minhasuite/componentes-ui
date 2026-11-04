import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'motion_view.dart';

/// Uma coluna do [SsKanban]: [id] estável, [title], os [items] na ordem e a
/// cor da bolinha do cabeçalho (sem ela, a da marca).
class SsKanbanColumn<T> {
  const SsKanbanColumn({required this.id, required this.title, required this.items, this.color});

  final String id;
  final String title;
  final List<T> items;
  final Color? color;
}

/// Quadro kanban: colunas lado a lado (rolagem horizontal que para em cada
/// coluna), cabeçalho com a contagem e cards arrastáveis no toque longo (o
/// card levanta e inclina, a coluna alvo destaca e o lugar do drop aparece
/// tracejado; perto da borda o quadro rola sozinho). Precisa de altura
/// definida (ex.: `Expanded`). [onMove] recebe o índice no destino já
/// sem o item (pronto para `removeAt` + `insert`); quem chama atualiza as listas.
/// Os cards chegam em cascata, subindo com mola, quando a coluna aparece.
class SsKanban<T extends Object> extends StatefulWidget {
  const SsKanban({
    super.key,
    required this.columns,
    required this.cardBuilder,
    required this.onMove,
    this.columnWidth = 280,
  });

  final List<SsKanbanColumn<T>> columns;
  final Widget Function(BuildContext context, T item) cardBuilder;
  final void Function(T item, String fromColumn, String toColumn, int index) onMove;
  final double columnWidth;

  @override
  State<SsKanban<T>> createState() => _SsKanbanState<T>();
}

class _Arrasto<T> {
  const _Arrasto(this.item, this.col, this.index);
  final T item;
  final String col;
  final int index;
}

const _gap = 12.0;

class _SsKanbanState<T extends Object> extends State<SsKanban<T>> {
  final _scroll = ScrollController();
  (String, int)? _alvo;
  Size? _tamanho;
  Timer? _rolagem;

  @override
  void dispose() {
    _rolagem?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _entra(String col, int i) {
    if (_alvo != (col, i)) setState(() => _alvo = (col, i));
  }

  void _sai(String col, int i) {
    if (_alvo == (col, i)) setState(() => _alvo = null);
  }

  void _solta(_Arrasto<T> d, String col, int i) {
    setState(() => _alvo = null);
    final index = d.col == col && d.index < i ? i - 1 : i;
    if (d.col == col && index == d.index) return;
    HapticFeedback.lightImpact();
    widget.onMove(d.item, d.col, col, index);
  }

  /// Perto da borda, rola enquanto o dedo estiver lá.
  void _borda(Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final x = box.globalToLocal(global).dx;
    final v = x < 56 ? -10.0 : (x > box.size.width - 56 ? 10.0 : 0.0);
    if (v == 0) return _paraRolagem();
    _rolagem ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_scroll.hasClients) return;
      final p = _scroll.position;
      final nx = (p.pixels + v).clamp(p.minScrollExtent, p.maxScrollExtent);
      if (nx != p.pixels) _scroll.jumpTo(nx);
    });
  }

  void _paraRolagem() {
    _rolagem?.cancel();
    _rolagem = null;
  }

  void _fim() {
    _paraRolagem();
    if (mounted) setState(() => _alvo = null);
    if (_scroll.hasClients) (_scroll.position as ScrollPositionWithSingleContext).goBallistic(0);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      physics: _Encaixe(widget.columnWidth + _gap),
      padding: const EdgeInsets.symmetric(horizontal: 16 - _gap / 2),
      itemCount: widget.columns.length,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: _gap / 2),
        child: SizedBox(width: widget.columnWidth, child: _coluna(widget.columns[i])),
      ),
    );
  }

  Widget _coluna(SsKanbanColumn<T> col) {
    final c = SsColors.of(context);
    final destacada = _alvo?.$1 == col.id;
    final n = col.items.length;
    return DragTarget<_Arrasto<T>>(
      onWillAcceptWithDetails: (_) {
        _entra(col.id, n);
        return true;
      },
      onLeave: (_) => _sai(col.id, n),
      onAcceptWithDetails: (d) => _solta(d.data, col.id, n),
      builder: (context, _, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: destacada ? c.accentSoft : c.field,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: destacada ? c.accent.withValues(alpha: .5) : c.line, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              label: '${col.title}, $n ${n == 1 ? 'card' : 'cards'}',
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 8),
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(color: col.color ?? c.accent, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        col.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.ink, fontSize: AppType.set, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(99)),
                      child: Text(
                        '$n',
                        style: AppTheme.number(context, size: AppType.meta, color: c.muted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                children: [
                  for (var i = 0; i < n; i++) _card(col, i),
                  if (_alvo == (col.id, n)) _Vaga(altura: _tamanho?.height),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(SsKanbanColumn<T> col, int i) {
    final item = col.items[i];
    final card = widget.cardBuilder(context, item);
    final largura = widget.columnWidth - 20;
    // O alvo do card inclui a vaga acima dele: senão a vaga empurra o card,
    // o dedo sai do alvo e ela pisca.
    return DragTarget<_Arrasto<T>>(
      onWillAcceptWithDetails: (_) {
        _entra(col.id, i);
        return true;
      },
      onLeave: (_) => _sai(col.id, i),
      onAcceptWithDetails: (d) => _solta(d.data, col.id, i),
      builder: (context, _, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_alvo == (col.id, i)) _Vaga(altura: _tamanho?.height),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            // Os cards chegam em cascata, com mola, quando a coluna aparece.
            child: SsInViewReveal(
              index: i,
              child: Builder(
                builder: (cardCtx) => LongPressDraggable<_Arrasto<T>>(
                  data: _Arrasto(item, col.id, i),
                  hapticFeedbackOnStart: false,
                  onDragStarted: () {
                    HapticFeedback.mediumImpact();
                    _tamanho = cardCtx.size;
                  },
                  onDragUpdate: (d) => _borda(d.globalPosition),
                  onDragEnd: (_) => _fim(),
                  feedback: Transform.rotate(
                    angle: 2 * math.pi / 180,
                    child: Transform.scale(
                      scale: 1.03,
                      child: Material(
                        type: MaterialType.transparency,
                        child: Container(
                          width: largura,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x40000000),
                                blurRadius: 24,
                                offset: Offset(0, 14),
                                spreadRadius: -6,
                              ),
                            ],
                          ),
                          child: card,
                        ),
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(opacity: .3, child: card),
                  child: card,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lugar onde o card vai cair: retângulo tracejado na cor da marca.
class _Vaga extends StatelessWidget {
  const _Vaga({this.altura});
  final double? altura;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: CustomPaint(
      painter: _Tracejado(SsColors.of(context).accent),
      child: SizedBox(height: (altura ?? 72) - 8),
    ),
  );
}

class _Tracejado extends CustomPainter {
  _Tracejado(this.cor);
  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(AppRadius.card));
    canvas.drawRRect(rr, Paint()..color = cor.withValues(alpha: .08));
    final pen = Paint()
      ..color = cor.withValues(alpha: .6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final m in (Path()..addRRect(rr.deflate(.8))).computeMetrics()) {
      for (double d = 0; d < m.length; d += 10) {
        canvas.drawPath(m.extractPath(d, math.min(d + 5, m.length)), pen);
      }
    }
  }

  @override
  bool shouldRepaint(_Tracejado old) => old.cor != cor;
}

/// Rolagem que para no começo de uma coluna (como o PageView, com passo próprio).
class _Encaixe extends ScrollPhysics {
  const _Encaixe(this.passo, {super.parent});
  final double passo;

  @override
  _Encaixe applyTo(ScrollPhysics? ancestor) => _Encaixe(passo, parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tol = toleranceFor(position);
    var coluna = position.pixels / passo;
    if (velocity < -tol.velocity) {
      coluna -= .5;
    } else if (velocity > tol.velocity) {
      coluna += .5;
    }
    final alvo = (coluna.roundToDouble() * passo).clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((alvo - position.pixels).abs() < tol.distance) return null;
    return ScrollSpringSimulation(spring, position.pixels, alvo, velocity, tolerance: tol);
  }

  @override
  bool get allowImplicitScrolling => false;
}
