// v1.9 · paridade_app: cronograma leve (par do Ss::GanttComponent).
import 'package:material_ui/material_ui.dart';

import '../../app_theme.dart';
import '../../motion.dart';
import '../../ss_badge.dart' show SsTone;
import '../../ss_strings.dart';
import 'comum.dart';

/// Uma tarefa do [SsGantt]: de [from] a [to] (inclusive), [progress] de 0 a 1.
class SsGanttTask {
  const SsGanttTask({
    required this.label,
    required this.from,
    required this.to,
    this.progress = 0,
    this.tone = SsTone.accent,
  });

  final String label;
  final DateTime from;
  final DateTime to;
  final double progress;
  final SsTone tone;
}

/// Gantt leve: uma barra por tarefa numa grade de [days] dias a partir de
/// [start], hoje marcado (coluna tingida e o número num círculo) e o
/// progresso pintado dentro da barra. Os nomes ficam fixos à esquerda e os
/// dias rolam de lado. Tarefa fora da janela fica só com o nome; a que passa
/// da borda é cortada nela. Par do `Ss::GanttComponent` (mesmos parâmetros).
///
/// `SsGantt(start: hoje.subtract(const Duration(days: 3)), tasks: [SsGanttTask(label: 'Levantamento', from: d1, to: d2, progress: .6)])`
class SsGantt extends StatelessWidget {
  const SsGantt({
    super.key,
    required this.tasks,
    required this.start,
    this.days = 14,
    this.today,
    this.label,
    this.dayWidth = 36,
    this.labelWidth = 112,
  });

  final List<SsGanttTask> tasks;
  final DateTime start;
  final int days;

  /// Padrão: hoje.
  final DateTime? today;

  /// Nome do grupo para o leitor de tela. Padrão: [SsStrings.ganttLabel].
  final String? label;
  final double dayWidth;
  final double labelWidth;

  static const _rowH = 44.0;
  static const _barH = 30.0;

  static DateTime _d(DateTime d) => DateTime(d.year, d.month, d.day);
  // Em UTC: o horário de verão não come um dia da conta.
  static int _diff(DateTime a, DateTime b) =>
      DateTime.utc(a.year, a.month, a.day).difference(DateTime.utc(b.year, b.month, b.day)).inDays;

  /// Colunas da barra na janela: [início, fim exclusivo] (0 = 1º dia), ou nulo
  /// se a tarefa não aparece. Mesma conta do `span_for` do web.
  static (int, int)? spanFor(SsGanttTask t, DateTime start, int days) {
    final fim = _diff(t.to, start);
    final ini = _diff(t.from, start);
    if (fim < 0 || ini >= days) return null;
    final a = ini.clamp(0, days);
    final b = (fim + 1).clamp(0, days);
    return (a, b < a + 1 ? a + 1 : b);
  }

  static int pct(SsGanttTask t) => (t.progress.clamp(0.0, 1.0) * 100).round();

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = SsStrings.of(context);
    final hoje = _d(today ?? DateTime.now());
    final dias = [for (var i = 0; i < days; i++) DateTime(start.year, start.month, start.day + i)];
    final iHoje = _diff(hoje, start);
    final mostraHoje = iHoje >= 0 && iHoje < days;
    final reduz = reduceMotion(context);
    final scaler = MediaQuery.textScalerOf(context);
    // Inicial do dia (texto micro, com a entrelinha da fonte) + o círculo de 24 + respiro.
    final headH = scaler.scale(AppType.micro) * 1.7 + 26 + 14;

    Widget cabecalho(int i) {
      final d = dias[i];
      final fds = d.weekday >= DateTime.saturday;
      final eHoje = i == iHoje;
      return SizedBox(
        width: dayWidth,
        height: headH,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              s.weekdayInitials[d.weekday % 7],
              style: TextStyle(fontSize: AppType.micro, fontWeight: FontWeight.w700, color: c.muted),
            ),
            const SizedBox(height: 2),
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: eHoje ? BoxDecoration(color: c.accentSolid, shape: BoxShape.circle) : null,
              child: Text(
                '${d.day}',
                style: AppTheme.number(
                  context,
                  size: AppType.sub,
                  color: eHoje ? AppColors.onDark : (fds ? c.muted : c.ink2),
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget barra(SsGanttTask t) {
      final span = spanFor(t, start, days);
      if (span == null) return const SizedBox(height: _rowH);
      final (a, b) = span;
      final tom = t.tone.colors(context);
      final p = pct(t);
      final fill = Color.alphaBlend(tom.solid.withValues(alpha: .42), c.surface);
      final resto = Color.alphaBlend(tom.solid.withValues(alpha: .14), c.surface);
      final largura = (b - a) * dayWidth - 4;
      Widget corpo = Container(
        width: largura,
        height: _barH,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: tom.solid.withValues(alpha: .35)),
          gradient: LinearGradient(colors: [fill, fill, resto, resto], stops: [0, p / 100, p / 100, 1]),
        ),
        child: Text(
          '$p%',
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: AppTheme.number(context, size: AppType.label, color: c.ink),
        ),
      );
      if (!reduz) {
        corpo = TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: const Cubic(.2, .8, .2, 1),
          builder: (_, v, child) =>
              Transform(alignment: Alignment.centerLeft, transform: Matrix4.diagonal3Values(v, 1, 1), child: child),
          child: corpo,
        );
      }
      final f = s.formatDayMonth;
      return SizedBox(
        height: _rowH,
        child: Stack(
          children: [
            Positioned(
              left: a * dayWidth + 2,
              top: (_rowH - _barH) / 2,
              child: Semantics(
                label: ssFill(s.ganttBar, {'label': t.label, 'from': f(t.from), 'to': f(t.to), 'pct': p}),
                excludeSemantics: true,
                child: Tooltip(message: '${t.label}: ${f(t.from)} – ${f(t.to)}, $p%', child: corpo),
              ),
            ),
          ],
        ),
      );
    }

    final grade = SizedBox(
      width: days * dayWidth,
      child: Stack(
        children: [
          // Linhas verticais dos dias e a coluna de hoje.
          Positioned.fill(
            child: CustomPaint(
              painter: _GradePainter(days: days, dayWidth: dayWidth, top: headH, color: c.line),
            ),
          ),
          if (mostraHoje)
            Positioned(
              left: iHoje * dayWidth,
              top: 0,
              bottom: 0,
              width: dayWidth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(child: Row(children: [for (var i = 0; i < days; i++) cabecalho(i)])),
              for (final t in tasks) barra(t),
            ],
          ),
        ],
      ),
    );

    return Semantics(
      container: true,
      label: label ?? s.ganttLabel,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: c.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: labelWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: headH),
                  for (final t in tasks)
                    SizedBox(
                      height: _rowH,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ExcludeSemantics(
                          child: Text(
                            t.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: AppType.sub, fontWeight: FontWeight.w700, color: c.ink),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: grade),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradePainter extends CustomPainter {
  _GradePainter({required this.days, required this.dayWidth, required this.top, required this.color});
  final int days;
  final double dayWidth;
  final double top;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, top), Offset(size.width, top), p);
    for (var i = 1; i < days; i++) {
      final x = i * dayWidth;
      canvas.drawLine(Offset(x, top), Offset(x, size.height), p);
    }
  }

  @override
  bool shouldRepaint(_GradePainter old) =>
      old.days != days || old.dayWidth != dayWidth || old.top != top || old.color != color;
}
