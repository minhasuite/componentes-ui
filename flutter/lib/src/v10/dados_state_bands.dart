// v0.10 (dados): faixas de estado no tempo (liga/desliga, aberto/fechado, os
// estados de um aspirador em 24 h) e o eixo do tempo que o gráfico também usa.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../motion_view.dart';
import '../ss_badge.dart';
import '../ss_strings.dart';
import 'dados_formato.dart';

/// Um trecho de uma faixa: de [from] a [to] no estado [state] (a chave: `on`,
/// `closed`, `cleaning`). [label] é o texto do balão (padrão: [state]).
class SsStateSegment {
  const SsStateSegment(this.from, this.to, this.state, {this.label});

  final DateTime from;
  final DateTime to;
  final String state;
  final String? label;

  String get text => label ?? state;
}

/// Uma linha do [SsStateBands]: o nome, os trechos e, se quiser, o estado de
/// agora à direita ([current]).
class SsStateRow {
  const SsStateRow(this.label, this.segments, {this.current});

  final String label;
  final List<SsStateSegment> segments;
  final String? current;
}

/// Tom de um estado: o do mapa [tones] do app; senão, ligado/aberto saem na
/// marca, desligado/fechado no neutro e erro no perigo; o resto fica nulo (a
/// faixa usa a paleta de séries, na ordem em que o estado aparece). O Rails
/// usa a mesma regra.
SsTone? ssStateTone(String state, [Map<String, SsTone> tones = const {}]) {
  final t = tones[state];
  if (t != null) return t;
  final s = state.toLowerCase();
  const on = {'on', 'open', 'true', 'ligado', 'ligada', 'aberto', 'aberta', 'home', 'playing', 'unlocked', 'detected'};
  const off = {'off', 'closed', 'false', 'desligado', 'desligada', 'fechado', 'fechada', 'idle', 'locked', 'clear'};
  const ruim = {'error', 'erro', 'problem', 'jammed'};
  const nada = {'unavailable', 'unknown', 'indisponível', 'desconhecido'};
  if (on.contains(s)) return SsTone.accent;
  if (off.contains(s) || nada.contains(s)) return SsTone.neutral;
  if (ruim.contains(s)) return SsTone.danger;
  return null;
}

/// Cor de cada estado de [rows]: tom ([ssStateTone]) ou, sem tom, a paleta de
/// séries na ordem em que o estado aparece. O neutro usa o `muted2` (aparece
/// sobre o fundo da faixa sem gritar).
Map<String, Color> ssStateColors(BuildContext context, List<SsStateRow> rows, Map<String, SsTone> tones) {
  final c = SsColors.of(context);
  final out = <String, Color>{};
  var livre = 1; // a 0 é a marca, que já é o "ligado"
  for (final r in rows) {
    for (final s in r.segments) {
      if (out.containsKey(s.state)) continue;
      final t = ssStateTone(s.state, tones);
      out[s.state] = switch (t) {
        null => c.series[livre++ % c.series.length],
        SsTone.neutral => c.muted2,
        _ => t.colors(context).solid,
      };
    }
  }
  return out;
}

/// Eixo do tempo de [from] a [to] com as marcas "inteligentes"
/// ([SsTimeFormat.ticks]): horas num dia, dias numa semana, meses num ano.
/// A meia-noite (ou janeiro) sai em negrito. Uma marca a cada ~72 px.
class SsTimeAxis extends StatelessWidget {
  const SsTimeAxis({super.key, required this.from, required this.to, this.locale, this.height = 18, this.utcOffset});

  final DateTime from;
  final DateTime to;

  /// Idioma das marcas (padrão: o do `Localizations`).
  final Locale? locale;
  final double height;

  /// Fuso fixo das horas e datas (ex.: `Duration(hours: -3)`, o do site);
  /// nulo = o do aparelho. Ver [SsTimeFormat.utcOffset].
  final Duration? utcOffset;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final fmt = SsTimeFormat.of(context, locale, utcOffset);
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, box) => CustomPaint(
            size: Size(box.maxWidth, height),
            painter: _AxisPainter(
              ticks: fmt.ticks(from, to, maxTicks: math.max(2, (box.maxWidth / 72).floor())),
              from: from,
              to: to,
              style: AppTheme.number(context, size: SsDensity.of(context).font(AppType.micro), color: c.muted),
              major: AppTheme.number(
                context,
                size: SsDensity.of(context).font(AppType.micro),
                weight: FontWeight.w700,
                color: c.ink2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AxisPainter extends CustomPainter {
  _AxisPainter({required this.ticks, required this.from, required this.to, required this.style, required this.major});

  final List<SsTimeTick> ticks;
  final DateTime from, to;
  final TextStyle style, major;

  @override
  void paint(Canvas canvas, Size size) {
    final span = to.difference(from).inMilliseconds;
    if (span <= 0) return;
    var ultimo = -double.infinity;
    for (final t in ticks) {
      final x = size.width * t.at.difference(from).inMilliseconds / span;
      final tp = TextPainter(
        text: TextSpan(text: t.label, style: t.major ? major : style),
        textDirection: TextDirection.ltr,
      )..layout();
      // Centrado na marca, sem sair da borda nem encostar no anterior.
      final left = (x - tp.width / 2).clamp(0.0, math.max(0.0, size.width - tp.width)).toDouble();
      if (left < ultimo + 6) continue;
      tp.paint(canvas, Offset(left, (size.height - tp.height) / 2));
      ultimo = left + tp.width;
    }
  }

  @override
  bool shouldRepaint(_AxisPainter old) => old.ticks.length != ticks.length || old.from != from || old.to != to;
}

/// Faixas de estado no tempo: uma linha por item (nome + trechos coloridos
/// pelo estado) sobre o mesmo intervalo, com o eixo do tempo embaixo. Tocar
/// (ou passar o mouse) num trecho mostra o balão com o estado, o horário e a
/// duração. Entra da esquerda para a direita quando aparece na tela.
///
/// Embaixo de um [SsTimeChart] com o mesmo `from`/`to` e [labelOnTop], as
/// faixas ficam alinhadas ao gráfico (ou passe `bands:` ao próprio gráfico).
///
/// `SsStateBands(rows: [SsStateRow('Luz da sala', [SsStateSegment(a, b, 'on', label: 'Ligada')])], from: ini, to: fim)`
class SsStateBands extends StatefulWidget {
  const SsStateBands({
    super.key,
    required this.rows,
    this.from,
    this.to,
    this.tones = const {},
    this.labelOnTop = false,
    this.labelWidth = 112,
    this.barHeight = 22,
    this.axis = true,
    this.locale,
    this.title,
    this.emptyText,
    this.noDataText,
    this.utcOffset,
  });

  final List<SsStateRow> rows;

  /// Fuso fixo das horas e datas (ex.: `Duration(hours: -3)`, o do site);
  /// nulo = o do aparelho. Ver [SsTimeFormat.utcOffset].
  final Duration? utcOffset;

  /// Intervalo do eixo (padrão: do 1º trecho ao último).
  final DateTime? from;
  final DateTime? to;

  /// Estado → tom ([ssStateTone] completa o que faltar).
  final Map<String, SsTone> tones;

  /// Nome em cima da faixa (a faixa ocupa a largura toda, alinhada ao
  /// gráfico) em vez de numa coluna à esquerda. Em largura estreita
  /// (< 3 × [labelWidth], o celular) o nome já vai em cima.
  final bool labelOnTop;
  final double labelWidth;
  final double barHeight;

  /// Mostra o eixo do tempo embaixo.
  final bool axis;

  /// Idioma do horário e da duração (padrão: o do `Localizations`).
  final Locale? locale;

  /// Nome do conjunto para o leitor de tela.
  final String? title;

  /// Textos (padrão: os do [SsStrings] do idioma).
  final String? emptyText;
  final String? noDataText;

  /// Intervalo efetivo de [rows] (o [from]/[to] dado ou o dos trechos).
  static (DateTime, DateTime)? rangeOf(List<SsStateRow> rows, DateTime? from, DateTime? to) {
    DateTime? a = from, b = to;
    for (final r in rows) {
      for (final s in r.segments) {
        if (from == null && (a == null || s.from.isBefore(a))) a = s.from;
        if (to == null && (b == null || s.to.isAfter(b))) b = s.to;
      }
    }
    if (a == null || b == null || !b.isAfter(a)) return null;
    return (a, b);
  }

  @override
  State<SsStateBands> createState() => _SsStateBandsState();
}

class _SsStateBandsState extends State<SsStateBands> {
  // Trecho aberto no balão: (linha, trecho).
  (int, int)? _sel;

  void _escolhe(int row, int? seg) {
    final novo = seg == null ? null : (row, seg);
    if (novo == _sel) return;
    if (novo != null) SsHaptics.tick();
    setState(() => _sel = novo);
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final range = SsStateBands.rangeOf(widget.rows, widget.from, widget.to);
    if (widget.rows.isEmpty || range == null) {
      return Container(
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(AppRadius.thumb)),
        child: Text(
          widget.emptyText ?? SsStrings.of(context).stateBandsEmpty,
          style: TextStyle(color: c.muted, fontSize: SsDensity.of(context).font(AppType.sub)),
        ),
      );
    }
    final (from, to) = range;
    final cores = ssStateColors(context, widget.rows, widget.tones);
    final fmt = SsTimeFormat.of(context, widget.locale, widget.utcOffset);
    // Estreito (celular): o nome vai em cima, como no Rails abaixo de 640 px.
    return LayoutBuilder(
      builder: (context, box) {
        final top = widget.labelOnTop || box.maxWidth < widget.labelWidth * 3;
        return _corpo(context, from, to, cores, fmt, top);
      },
    );
  }

  Widget _corpo(
    BuildContext context,
    DateTime from,
    DateTime to,
    Map<String, Color> cores,
    SsTimeFormat fmt,
    bool top,
  ) {
    return Semantics(
      container: true,
      label: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.rows.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == widget.rows.length - 1 ? 0 : 8),
              child: SsStateBandRow(
                row: widget.rows[i],
                from: from,
                to: to,
                colors: cores,
                fmt: fmt,
                labelOnTop: top,
                currentWidth: widget.rows.any((r) => r.current != null) ? 84 : null,
                labelWidth: widget.labelWidth,
                barHeight: widget.barHeight,
                selected: _sel?.$1 == i ? _sel!.$2 : null,
                onSelect: (s) => _escolhe(i, s),
                noDataText: widget.noDataText,
                index: i,
              ),
            ),
          if (widget.axis)
            Padding(
              padding: EdgeInsets.only(
                left: top ? 0 : widget.labelWidth + 10,
                right: top || widget.rows.every((r) => r.current == null) ? 0 : 84 + 10,
                top: 6,
              ),
              child: SsTimeAxis(from: from, to: to, locale: widget.locale, utcOffset: widget.utcOffset),
            ),
        ],
      ),
    );
  }
}

/// Uma linha do [SsStateBands] (o [SsTimeChart] usa a mesma, com o nome em
/// cima). Público só para o gráfico; o app usa o [SsStateBands].
class SsStateBandRow extends StatelessWidget {
  const SsStateBandRow({
    super.key,
    required this.row,
    required this.from,
    required this.to,
    required this.colors,
    required this.fmt,
    this.labelOnTop = false,
    this.labelWidth = 112,
    this.barHeight = 22,
    this.selected,
    this.onSelect,
    this.noDataText,
    this.index = 0,
    this.currentWidth,
  });

  final SsStateRow row;
  final DateTime from, to;
  final Map<String, Color> colors;
  final SsTimeFormat fmt;
  final bool labelOnTop;
  final double labelWidth;
  final double barHeight;
  final int? selected;
  final ValueChanged<int?>? onSelect;

  /// Faixa sem trechos (padrão: o do [SsStrings]).
  final String? noDataText;
  final int index;

  /// Largura da coluna do estado de agora (todas as linhas iguais, para as
  /// faixas alinharem); nula = sem a coluna.
  final double? currentWidth;

  int? _segAt(double dx, double w) {
    final span = to.difference(from).inMilliseconds;
    final t = from.add(Duration(milliseconds: (dx / w * span).round()));
    for (var i = 0; i < row.segments.length; i++) {
      final s = row.segments[i];
      if (!t.isBefore(s.from) && t.isBefore(s.to)) return i;
    }
    return null;
  }

  /// Resumo para o leitor de tela: tempo em cada estado.
  String _resumo(String noDataText) {
    final tempo = <String, Duration>{};
    for (final s in row.segments) {
      final a = s.from.isBefore(from) ? from : s.from;
      final b = s.to.isAfter(to) ? to : s.to;
      if (b.isAfter(a)) tempo[s.text] = (tempo[s.text] ?? Duration.zero) + b.difference(a);
    }
    if (tempo.isEmpty) return '${row.label}: $noDataText';
    return '${row.label}: ${tempo.entries.map((e) => '${e.key} ${fmt.duration(e.value)}').join(', ')}'
        '${row.current == null ? '' : '. ${row.current}'}';
  }

  @override
  Widget build(BuildContext context) {
    final noDataText = this.noDataText ?? SsStrings.of(context).noReadings;
    final c = SsColors.of(context);
    final nome = Text(
      row.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: labelOnTop ? AppType.label : AppType.sub,
        fontWeight: FontWeight.w600,
        color: labelOnTop ? c.muted : c.ink,
      ),
    );
    final barra = LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final sel = selected;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _toque(
              w,
              Container(
                height: barHeight,
                decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(7)),
                clipBehavior: Clip.antiAlias,
                child: row.segments.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            noDataText,
                            style: TextStyle(fontSize: SsDensity.of(context).font(AppType.label), color: c.muted),
                          ),
                        ),
                      )
                    // Entra da esquerda para a direita (em cascata por linha).
                    : SsTweenInView(
                        end: 1,
                        // Atraso dentro da própria curva (um quadro só basta para começar).
                        duration: Duration(milliseconds: 700 + math.min(index, 8) * 60),
                        curve: Interval(
                          math.min(index, 8) * 60 / (700 + math.min(index, 8) * 60),
                          1,
                          curve: Curves.easeOutCubic,
                        ),
                        builder: (_, t, _) => CustomPaint(
                          size: Size(w, barHeight),
                          painter: _BandPainter(
                            segments: row.segments,
                            from: from,
                            to: to,
                            colors: colors,
                            t: t,
                            selected: sel,
                            ring: c.ink,
                          ),
                        ),
                      ),
              ),
            ),
            if (sel != null && sel < row.segments.length)
              _balao(context, row.segments[sel], w, colors[row.segments[sel].state] ?? c.accent),
          ],
        );
      },
    );
    return Semantics(
      label: _resumo(noDataText),
      excludeSemantics: true,
      child: labelOnTop
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(padding: const EdgeInsets.only(bottom: 3), child: nome),
                barra,
              ],
            )
          : Row(
              children: [
                SizedBox(width: labelWidth, child: nome),
                const SizedBox(width: 10),
                Expanded(child: barra),
                if (currentWidth != null) ...[
                  const SizedBox(width: 10),
                  SizedBox(
                    width: currentWidth,
                    child: Text(
                      row.current ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: SsDensity.of(context).font(AppType.meta),
                        color: c.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  // Sem [onSelect] (dentro do gráfico), quem trata o toque é o cursor dele.
  Widget _toque(double w, Widget child) {
    final sel = onSelect;
    if (sel == null) return child;
    return MouseRegion(
      onHover: (e) => sel(_segAt(e.localPosition.dx, w)),
      onExit: (_) => sel(null),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) {
          final s = _segAt(d.localPosition.dx, w);
          sel(s == selected ? null : s);
        },
        child: child,
      ),
    );
  }

  Widget _balao(BuildContext context, SsStateSegment s, double w, Color cor) {
    final c = SsColors.of(context);
    final span = to.difference(from).inMilliseconds;
    final meio = (s.from.difference(from).inMilliseconds + s.to.difference(from).inMilliseconds) / 2 / span * w;
    const largura = 176.0;
    return Positioned(
      left: (meio - largura / 2).clamp(0.0, math.max(0.0, w - largura)),
      bottom: barHeight + 6,
      width: largura,
      child: IgnorePointer(
        child: Container(
          padding: _respiro(context, 10, 7, 10, 7),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppRadius.thumb),
            border: Border.all(color: c.line),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      s.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: SsDensity.of(context).font(AppType.meta),
                        fontWeight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '${fmt.when(s.from)} – ${fmt.hm(s.to)} · ${fmt.duration(s.to.difference(s.from))}',
                style: AppTheme.number(context, size: SsDensity.of(context).font(AppType.micro), color: c.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BandPainter extends CustomPainter {
  _BandPainter({
    required this.segments,
    required this.from,
    required this.to,
    required this.colors,
    required this.t,
    required this.selected,
    required this.ring,
  });

  final List<SsStateSegment> segments;
  final DateTime from, to;
  final Map<String, Color> colors;
  final double t;
  final int? selected;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final span = to.difference(from).inMilliseconds;
    if (span <= 0) return;
    double x(DateTime d) => (size.width * d.difference(from).inMilliseconds / span).clamp(0.0, size.width);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * t, size.height));
    for (var i = 0; i < segments.length; i++) {
      final s = segments[i];
      final a = x(s.from), b = x(s.to);
      if (b <= a) continue;
      // Pelo menos 1 px: trecho curto (um pulso) não some.
      final r = Rect.fromLTRB(a, 0, math.max(b, a + 1), size.height);
      canvas.drawRect(r, Paint()..color = colors[s.state] ?? ring);
      if (i == selected) {
        canvas.drawRect(
          r.deflate(1),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = ring.withValues(alpha: .7),
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BandPainter old) =>
      old.t != t || old.selected != selected || old.segments != segments || old.from != from || old.to != to;
}

/// Respiro na escala da densidade (0,75 / 1 / 1,2).
EdgeInsets _respiro(BuildContext context, double l, double t, double r, double b) {
  final d = SsDensity.of(context);
  return EdgeInsets.fromLTRB(d.space(l), d.space(t), d.space(r), d.space(b));
}
