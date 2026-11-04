import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme.dart';
import 'motion.dart';
import 'ss_strings.dart';

/// Pílula escura (igual nos dois temas) com ícone, texto curto e uma ação
/// ("Desfazer") na cor da marca. Use [showSsToast]; o widget é público para o
/// catálogo e para testes. Com ação e [countdown], uma borda fina se esvazia
/// durante o tempo do aviso (a "contagem do desfazer"; parada com menos
/// movimento).
class SsToast extends StatelessWidget {
  const SsToast(this.message, {super.key, this.icon, this.tone, this.actionLabel, this.onAction, this.countdown});

  final String message;
  final IconData? icon;

  /// Cor do ícone (sucesso, erro); sem ela, a da marca.
  final Color? tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Tempo do aviso, para a borda de contagem (só com [actionLabel]).
  final Duration? countdown;

  static const background = Color(0xFF1A1826);

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    Widget pilula = Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
        boxShadow: const [BoxShadow(color: Color(0x40000000), offset: Offset(0, 10), blurRadius: 30, spreadRadius: -8)],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 20, color: tone ?? c.brand.accentDark), const SizedBox(width: 10)],
            Flexible(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.onDark, fontSize: AppType.set, fontWeight: FontWeight.w600),
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(width: 6),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: c.brand.accentDark,
                  shape: const StadiumBorder(),
                  textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: AppType.set),
                ),
                child: Text(actionLabel!),
              ),
            ] else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
    if (actionLabel != null && countdown != null) {
      final borda = c.brand.accentDark.withValues(alpha: .85);
      pilula = reduceMotion(context)
          ? CustomPaint(foregroundPainter: _Contagem(1, borda), child: pilula)
          : TweenAnimationBuilder<double>(
              tween: Tween(begin: 1, end: 0),
              duration: countdown!,
              builder: (_, t, child) => CustomPaint(foregroundPainter: _Contagem(t, borda), child: child),
              child: pilula,
            );
    }
    return Semantics(liveRegion: true, child: pilula);
  }
}

/// Borda da pílula desenhada só na fração [t] (1 = cheia), a partir do topo.
class _Contagem extends CustomPainter {
  const _Contagem(this.t, this.cor);
  final double t;
  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final r = Radius.circular(size.height / 2);
    final rect = (Offset.zero & size).deflate(1);
    // Começa no meio do topo e anda no sentido horário.
    final path = Path()
      ..moveTo(rect.center.dx, rect.top)
      ..lineTo(rect.right - r.x, rect.top)
      ..arcToPoint(Offset(rect.right - r.x, rect.bottom), radius: r)
      ..lineTo(rect.left + r.x, rect.bottom)
      ..arcToPoint(Offset(rect.left + r.x, rect.top), radius: r)
      ..close();
    final m = path.computeMetrics().first;
    canvas.drawPath(
      m.extractPath(0, m.length * t),
      Paint()
        ..color = cor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_Contagem old) => old.t != t || old.cor != cor;
}

void Function([bool acted])? _fecharAtual;

/// Mostra um [SsToast] subindo de baixo com mola, acima da barra de abas, por
/// [duration]. Um novo substitui o anterior. Tocar na ação fecha o aviso;
/// arrastar para baixo ou para o lado dispensa (no [showSsUndo], dispensar
/// conta como não desfeito).
void showSsToast(
  BuildContext context,
  String message, {
  IconData? icon,
  Color? tone,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
  double bottom = 104,
}) => _mostrar(
  context,
  message,
  icon: icon,
  tone: tone,
  actionLabel: actionLabel,
  onAction: onAction,
  duration: duration,
  bottom: bottom,
);

/// Aviso com "Desfazer" e a contagem na borda. Devolve `true` se a pessoa
/// desfez: quem chama só executa a exclusão de verdade quando volta `false`
/// (também volta `false` se outro aviso tomar o lugar).
///
/// `if (!await showSsUndo(context, 'Pedido excluído')) await api.excluir(p);`
Future<bool> showSsUndo(
  BuildContext context,
  String message, {
  String? label,
  IconData? icon = Icons.delete_outline,
  Duration duration = const Duration(seconds: 5),
  double bottom = 104,
}) {
  final r = Completer<bool>();
  _mostrar(
    context,
    message,
    icon: icon,
    actionLabel: label ?? SsStrings.of(context).undo,
    onAction: () {},
    duration: duration,
    bottom: bottom,
    onClosed: r.complete,
  );
  return r.future;
}

void _mostrar(
  BuildContext context,
  String message, {
  IconData? icon,
  Color? tone,
  String? actionLabel,
  VoidCallback? onAction,
  required Duration duration,
  required double bottom,
  void Function(bool acted)? onClosed,
}) {
  _fecharAtual?.call();
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  var fechado = false;
  void fechar([bool acted = false]) {
    if (fechado) return;
    fechado = true;
    if (entry.mounted) entry.remove();
    if (_fecharAtual == fechar) _fecharAtual = null;
    onClosed?.call(acted);
  }

  entry = OverlayEntry(
    builder: (ctx) => Positioned(
      left: 16,
      right: 16,
      bottom: bottom + MediaQuery.viewPaddingOf(ctx).bottom,
      child: Center(
        child: _Entrada(
          duration: duration,
          onDone: fechar,
          child: SsToast(
            message,
            icon: icon,
            tone: tone,
            actionLabel: actionLabel,
            countdown: duration,
            onAction: onAction == null
                ? null
                : () {
                    fechar(true);
                    onAction();
                  },
          ),
        ),
      ),
    ),
  );
  _fecharAtual = fechar;
  overlay.insert(entry);
}

/// Entrada com mola de baixo, saída ao fim de [duration] e arrasto para
/// dispensar: puxar para baixo ou para o lado além do limite (ou com
/// velocidade) joga o aviso para fora; soltar antes volta com mola.
class _Entrada extends StatefulWidget {
  const _Entrada({required this.child, required this.duration, required this.onDone});

  final Widget child;
  final Duration duration;
  final VoidCallback onDone;

  @override
  State<_Entrada> createState() => _EntradaState();
}

class _EntradaState extends State<_Entrada> with TickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: SsMotion.indicator);

  /// Volta (ou saída) depois de soltar o arrasto: de [_de] até [_para].
  late final _solta = AnimationController(vsync: this, duration: SsMotion.indicator);
  Offset _drag = Offset.zero;
  Offset _de = Offset.zero, _para = Offset.zero;
  Curve _curva = SsMotion.bounce;
  bool _arrastando = false, _venceu = false, _saindo = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _solta.addListener(() => setState(() => _drag = Offset.lerp(_de, _para, _curva.transform(_solta.value))!));
    _timer = Timer(widget.duration, () {
      if (_arrastando) {
        _venceu = true;
      } else {
        _sai();
      }
    });
  }

  Future<void> _sai() async {
    if (!mounted || _saindo) return;
    _saindo = true;
    await _c.reverse();
    if (mounted) widget.onDone();
  }

  void _move(DragUpdateDetails d) {
    if (_saindo) return;
    _arrastando = true;
    _solta.stop();
    var n = _drag + d.delta;
    // Para cima resiste (não é para onde ele vai).
    if (n.dy < 0) n = Offset(n.dx, _drag.dy + d.delta.dy * .2);
    setState(() => _drag = n);
  }

  void _larga(DragEndDetails d) {
    _arrastando = false;
    if (_saindo) return;
    final v = d.velocity.pixelsPerSecond;
    final w = MediaQuery.sizeOf(context).width;
    final lado = _drag.dx.abs() > 90 || v.dx.abs() > 700;
    final baixo = _drag.dy > 36 || v.dy > 600;
    _de = _drag;
    if (lado || baixo) {
      // Sai na direção do gesto e fecha.
      _saindo = true;
      _para = lado ? Offset(_drag.dx.sign * w, _drag.dy) : Offset(_drag.dx, 160);
      _curva = Curves.easeIn;
      _solta.duration = const Duration(milliseconds: 220);
      _solta.forward(from: 0).whenComplete(() {
        if (mounted) widget.onDone();
      });
      return;
    }
    _para = Offset.zero;
    _curva = SsMotion.bounce;
    _solta.duration = SsMotion.indicator;
    _solta.forward(from: 0);
    if (_venceu) _sai();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    _solta.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semMov = reduceMotion(context);
    final w = MediaQuery.sizeOf(context).width;
    // Some conforme se afasta (no lado conta mais que para baixo).
    final longe = (_drag.dx.abs() / (w * .6) + _drag.dy.clamp(0, 400) / 160).clamp(0.0, 1.0);
    Widget child = GestureDetector(
      onPanUpdate: _move,
      onPanEnd: _larga,
      onPanCancel: () => _larga(DragEndDetails()),
      child: Transform.translate(
        offset: _drag,
        child: Transform.rotate(
          angle: semMov ? 0 : _drag.dx / w * .12,
          child: Opacity(opacity: 1 - longe * .8, child: widget.child),
        ),
      ),
    );
    if (semMov) return child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        // Entra com mola (passa um pouco e assenta); sai em linha reta.
        final t = _c.status == AnimationStatus.reverse
            ? Curves.easeIn.transform(_c.value)
            : SsMotion.bounce.transform(_c.value);
        return Opacity(
          opacity: (_c.value * 1.6).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 48 * (1 - t)),
            child: Transform.scale(scale: .9 + .1 * t, child: child),
          ),
        );
      },
      child: child,
    );
  }
}
