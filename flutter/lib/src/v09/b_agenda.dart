// v0.9 (lote b): agenda — faixa de dias, blocos do dia e lista de vários dias.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../density.dart';
import '../format.dart';
import '../motion.dart';
import '../ss_badge.dart' show SsTone;
import '../ss_calendar.dart';
import '../ss_sheet.dart';
import '../ss_strings.dart';

DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);

/// Faixa horizontal de dias do mês do [selected]: o escolhido vira uma pílula
/// alta na cor da marca, que desliza com mola de um dia para o outro
/// (esticando no caminho), e a faixa rola até ele. [markers] põe
/// pontinhos nos dias com evento. O cabeçalho "Novembro 2026 ⌄" abre o
/// [SsMonthGrid] numa folha para pular para outro mês.
class SsDateStrip extends StatefulWidget {
  const SsDateStrip({
    super.key,
    required this.selected,
    required this.onChanged,
    this.markers = const {},
    this.today,
    this.showHeader = true,
  });

  final DateTime selected;
  final ValueChanged<DateTime> onChanged;

  /// Dia → cores dos pontinhos (até 3), como no [SsMonthGrid].
  final Map<DateTime, List<Color>> markers;

  /// Padrão: hoje do relógio.
  final DateTime? today;
  final bool showHeader;

  @override
  State<SsDateStrip> createState() => _SsDateStripState();
}

class _SsDateStripState extends State<SsDateStrip> {
  static const _w = 56.0;
  static const _gap = 8.0;
  ScrollController? _scroll;
  double _viewport = 0;

  double _offsetFor(DateTime d) => math.max(0, (d.day - 1) * (_w + _gap) - (_viewport - _w) / 2);

  @override
  void didUpdateWidget(SsDateStrip old) {
    super.didUpdateWidget(old);
    final s = _scroll;
    if (_dia(old.selected) == _dia(widget.selected) || s == null || !s.hasClients) return;
    if (old.selected.month != widget.selected.month || old.selected.year != widget.selected.year) {
      s.jumpTo(_offsetFor(widget.selected).clamp(0.0, s.position.maxScrollExtent));
      return;
    }
    final alvo = _offsetFor(widget.selected).clamp(0.0, s.position.maxScrollExtent);
    if (reduceMotion(context)) {
      s.jumpTo(alvo);
    } else {
      s.animateTo(alvo, duration: SsMotion.slow, curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  Future<void> _abrirMes() async {
    var mes = DateTime(widget.selected.year, widget.selected.month);
    final escolhido = await showSsSheet<DateTime>(
      context,
      title: SsStrings.of(context).pickDay,
      child: StatefulBuilder(
        builder: (context, set) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SsMonthSwitcher(month: mes, onChanged: (m) => set(() => mes = m)),
            const SizedBox(height: 8),
            SsMonthGrid(
              month: mes,
              selected: widget.selected,
              today: widget.today,
              markers: widget.markers,
              onMonthChanged: (m) => set(() => mes = m),
              onSelect: (d) => Navigator.of(context).pop(d),
            ),
          ],
        ),
      ),
    );
    if (escolhido != null) widget.onChanged(_dia(escolhido));
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final sel = _dia(widget.selected);
    final hoje = _dia(widget.today ?? DateTime.now());
    final marcas = {for (final e in widget.markers.entries) _dia(e.key): e.value};
    final total = DateTime(sel.year, sel.month + 1, 0).day;
    final dur = reduceMotion(context) ? Duration.zero : SsMotion.slow;
    final s = SsStrings.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader)
          Center(
            child: Semantics(
              button: true,
              label: s.monthOpenCalendar(ssMonthName(sel, s)),
              excludeSemantics: true,
              child: SsPressable(
                onTap: _abrirMes,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ssMonthName(sel, s),
                        style: TextStyle(color: c.ink, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.3),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.keyboard_arrow_down_rounded, color: c.accentText, size: 26),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (widget.showHeader) const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, box) {
            _viewport = box.maxWidth;
            _scroll ??= ScrollController(initialScrollOffset: _offsetFor(sel));
            final pill = c.isDark ? c.brand.accentLight : c.accent;
            return SizedBox(
              height: 104,
              child: SingleChildScrollView(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: total * (_w + _gap) - _gap,
                  height: 104,
                  child: Stack(
                    children: [
                      // A pílula do dia escolhido desliza com mola até o dia novo
                      // (estica no caminho). Trocar de mês não desliza: a chave muda.
                      Positioned.fill(
                        child: SsSlidingIndicator(
                          key: ValueKey(DateTime(sel.year, sel.month)),
                          index: sel.day - 1,
                          rectOf: (i, size) => Rect.fromLTWH(i * (_w + _gap), (size.height - 96) / 2, _w, 96),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              // No escuro, a marca do claro: texto branco pequeno com contraste AA.
                              color: pill,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              boxShadow: c.primaryShadow,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        spacing: _gap,
                        children: [for (var i = 0; i < total; i++) _diaItem(context, c, sel, hoje, marcas, i, dur)],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _diaItem(
    BuildContext context,
    SsColors c,
    DateTime sel,
    DateTime hoje,
    Map<DateTime, List<Color>> marcas,
    int i,
    Duration dur,
  ) {
    final d = DateTime(sel.year, sel.month, i + 1);
    final eSel = d == sel;
    final eHoje = d == hoje;
    final pontos = (marcas[d] ?? const <Color>[]).take(3).toList();
    final fg = eSel ? AppColors.onDark : c.ink;
    final s = SsStrings.of(context);
    return Center(
      child: Semantics(
        button: true,
        selected: eSel,
        label:
            '${s.longDate(d)}'
            '${eHoje ? s.todaySuffix : ''}${pontos.isEmpty ? '' : s.withEvents}',
        excludeSemantics: true,
        child: SsPressable(
          onTap: () {
            if (!eSel) widget.onChanged(d);
          },
          child: AnimatedContainer(
            duration: dur,
            curve: SsMotion.bounce,
            width: _w,
            height: eSel ? 96 : 76,
            decoration: BoxDecoration(
              // O fundo do escolhido é a pílula que desliza (por baixo).
              color: eSel ? c.surface.withValues(alpha: 0) : c.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: eSel ? null : Border.all(color: eHoje ? c.accent : c.line, width: eHoje ? 1.6 : 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${d.day}',
                  textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
                  style: AppTheme.number(context, size: eSel ? 22 : 18, color: fg),
                ),
                const SizedBox(height: 6),
                Text(
                  s.weekdaysShort[d.weekday - 1],
                  textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
                  style: TextStyle(
                    color: eSel ? AppColors.onDark.withValues(alpha: .85) : c.muted,
                    fontSize: AppType.meta,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  height: 5,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 3,
                    children: [
                      for (final p in pontos)
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(color: eSel ? AppColors.onDark : p, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Um bloco do [SsDayAgenda].
class SsAgendaEvent {
  const SsAgendaEvent({
    required this.start,
    required this.end,
    required this.title,
    this.subtitle,
    this.color,
    this.icon,
    this.onTap,
    this.data,
  });

  final TimeOfDay start;
  final TimeOfDay end;
  final String title;
  final String? subtitle;

  /// Tom do bloco (padrão: a paleta da suíte, na ordem).
  final Color? color;
  final IconData? icon;
  final VoidCallback? onTap;

  /// Qualquer coisa do produto (id, modelo) para o [SsDayAgenda.eventBuilder].
  final Object? data;

  int get _ini => start.hour * 60 + start.minute;
  int get _fim => math.max(end.hour * 60 + end.minute, _ini + 15);
}

/// Agenda de um dia: horas à esquerda, linhas tracejadas e os blocos com
/// altura proporcional à duração (os que se sobrepõem dividem a largura).
/// [eventBuilder] troca o bloco padrão por qualquer widget (um card de
/// status, por exemplo), que recebe a altura do bloco pelas restrições.
/// [now] desenha a linha do "agora" na cor da marca.
class SsDayAgenda extends StatelessWidget {
  const SsDayAgenda({
    super.key,
    required this.events,
    this.startHour = 8,
    this.endHour = 20,
    this.hourHeight = 72,
    this.eventBuilder,
    this.now,
  }) : assert(endHour > startHour);

  final List<SsAgendaEvent> events;
  final int startHour, endHour;
  final double hourHeight;
  final Widget Function(BuildContext context, SsAgendaEvent event)? eventBuilder;

  /// Hora atual (nula: sem a linha).
  final TimeOfDay? now;

  static const _gutter = 58.0;
  static const _topPad = 8.0;

  /// Faixas (coluna, colunas do grupo) de cada evento, na ordem de [events].
  static List<(int, int)> lanes(List<SsAgendaEvent> events) {
    final ordem = [for (var i = 0; i < events.length; i++) i]..sort((a, b) => events[a]._ini.compareTo(events[b]._ini));
    final out = List<(int, int)>.filled(events.length, (0, 1));
    var grupo = <int>[];
    var fimGrupo = -1;
    var fins = <int>[];
    void fecha() {
      for (final i in grupo) {
        out[i] = (out[i].$1, fins.length);
      }
      grupo = [];
      fins = [];
    }

    for (final i in ordem) {
      final e = events[i];
      if (e._ini >= fimGrupo) fecha();
      var col = fins.indexWhere((f) => f <= e._ini);
      if (col < 0) {
        col = fins.length;
        fins.add(e._fim);
      } else {
        fins[col] = e._fim;
      }
      out[i] = (col, 1);
      grupo.add(i);
      fimGrupo = math.max(fimGrupo, e._fim);
    }
    fecha();
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final horas = endHour - startHour;
    final altura = horas * hourHeight + _topPad * 2;
    double y(int min) => _topPad + (min - startHour * 60) / 60 * hourHeight;
    final faixas = lanes(events);
    return SizedBox(
      height: altura,
      child: LayoutBuilder(
        builder: (context, box) {
          final largura = box.maxWidth - _gutter;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _GradePainter(
                    horas: horas,
                    hourHeight: hourHeight,
                    top: _topPad,
                    left: _gutter,
                    color: c.muted2.withValues(alpha: c.isDark ? .7 : 1),
                  ),
                ),
              ),
              for (var h = 0; h <= horas; h++)
                Positioned(
                  left: 0,
                  width: _gutter - 10,
                  top: _topPad + h * hourHeight - 7,
                  child: ExcludeSemantics(
                    child: Text(
                      '${two(startHour + h)}:00',
                      textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.2),
                      style: AppTheme.number(context, size: AppType.meta, color: c.muted),
                    ),
                  ),
                ),
              // O "agora" passa por baixo dos blocos (não risca o texto).
              if (now != null && now!.hour * 60 + now!.minute >= startHour * 60 && now!.hour < endHour)
                Positioned(
                  left: _gutter - 13,
                  right: 0,
                  top: y(now!.hour * 60 + now!.minute) - 6,
                  height: 12,
                  child: Semantics(
                    label: SsStrings.of(context).nowAt('${two(now!.hour)}:${two(now!.minute)}'),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: c.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: c.page, width: 2),
                          ),
                        ),
                        Expanded(child: Container(height: 2, color: c.accent)),
                      ],
                    ),
                  ),
                ),
              for (var i = 0; i < events.length; i++)
                if (events[i]._fim > startHour * 60 && events[i]._ini < endHour * 60)
                  Positioned(
                    top: y(math.max(events[i]._ini, startHour * 60)) + 2,
                    height: y(math.min(events[i]._fim, endHour * 60)) - y(math.max(events[i]._ini, startHour * 60)) - 4,
                    left: _gutter + largura / faixas[i].$2 * faixas[i].$1,
                    width: largura / faixas[i].$2 - (faixas[i].$2 > 1 ? 4 : 0),
                    child: SsReveal(
                      index: i,
                      child:
                          eventBuilder?.call(context, events[i]) ??
                          _Bloco(events[i], events[i].color ?? c.series[i % c.series.length]),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _Bloco extends StatelessWidget {
  const _Bloco(this.e, this.cor);
  final SsAgendaEvent e;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final faixa = '${two(e.start.hour)}:${two(e.start.minute)} – ${two(e.end.hour)}:${two(e.end.minute)}';
    return Semantics(
      button: e.onTap != null,
      label: '${e.title}, $faixa${e.subtitle == null ? '' : ', ${e.subtitle}'}',
      excludeSemantics: true,
      child: SsPressable(
        onTap: e.onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Color.alphaBlend(cor.withValues(alpha: c.isDark ? .22 : .14), c.surface),
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: cor),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final baixo = box.maxHeight < 52;
                    return Padding(
                      padding: EdgeInsets.fromLTRB(10, baixo ? 4 : 8, 10, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (e.icon != null) ...[Icon(e.icon, size: 16, color: cor), const SizedBox(width: 6)],
                              Expanded(
                                child: Text(
                                  e.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: c.ink, fontSize: AppType.set, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                          if (!baixo) ...[
                            const SizedBox(height: 3),
                            Text(
                              e.subtitle == null ? faixa : '$faixa · ${e.subtitle}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.number(context, size: AppType.meta, color: c.ink2),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradePainter extends CustomPainter {
  _GradePainter({
    required this.horas,
    required this.hourHeight,
    required this.top,
    required this.left,
    required this.color,
  });

  final int horas;
  final double hourHeight, top, left;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var h = 0; h <= horas; h++) {
      final yy = top + h * hourHeight;
      for (var x = left; x < size.width; x += 7) {
        canvas.drawLine(Offset(x, yy), Offset(math.min(x + 3.5, size.width), yy), p);
      }
    }
  }

  @override
  bool shouldRepaint(_GradePainter old) => old.horas != horas || old.color != color || old.hourHeight != hourHeight;
}

// ---------------------------------------------------------------------------
// SsAgendaList (v0.10.1)
// ---------------------------------------------------------------------------

/// Um compromisso da [SsAgendaList]. [time] vem formatado pelo app
/// ("09:30", "15:00–16:00", "9h–10h").
///
/// v0.10.2: [end] mostra o fim embaixo do início, menor ("15:00" / "16:00"),
/// e [allDay] mostra "Dia todo" ([SsStrings.allDay]) quando [time] vem vazio.
/// A coluna da hora se ajusta ao texto mais largo da lista (ver
/// [SsAgendaList.timeWidth]), então "15:00–16:00" numa linha também cabe.
@immutable
class SsAgendaItem {
  const SsAgendaItem({
    this.time = '',
    required this.title,
    this.end,
    this.allDay = false,
    this.detail,
    this.color,
    this.tone,
    this.onTap,
  });

  final String time;
  final String title;

  /// Fim do compromisso, já formatado ("16:00"): vai na 2ª linha da coluna.
  final String? end;

  /// Dia inteiro: a coluna mostra [time] ou, vazio, "Dia todo".
  final bool allDay;

  /// Linha menor (lugar, pessoa, "Sala 3").
  final String? detail;

  /// Cor da barrinha; ganha de [tone]. Padrão: a cor da marca.
  final Color? color;
  final SsTone? tone;
  final VoidCallback? onTap;
}

/// Um dia da [SsAgendaList]: a data, um rótulo opcional ("Hoje", "Amanhã")
/// e os compromissos (vazio mostra "Nada neste dia").
@immutable
class SsAgendaDay {
  const SsAgendaDay(this.date, {this.label, this.events = const []});

  final DateTime date;

  /// Vai antes da data no cabeçalho ("Hoje · quarta, 4 de novembro").
  final String? label;
  final List<SsAgendaItem> events;
}

/// Agenda de vários dias em lista: cabeçalho de cada dia (rótulo e data por
/// extenso) e as linhas dos compromissos com a hora em DM Mono e a barrinha
/// de cor; dia sem nada mostra [emptyLabel] ("Nada neste dia").
///
/// [weekStrip] põe em cima a faixa de dias ([SsDateStrip], sem o cabeçalho do
/// mês) com pontinho nos dias com compromisso; tocar num dia (na faixa ou no
/// cabeçalho) chama [onSelectDay]. [selected] destaca o dia na faixa e no
/// cabeçalho. [SsAgendaList.sliver] é a mesma lista como sliver (para um
/// `CustomScrollView`).
class SsAgendaList extends StatelessWidget {
  const SsAgendaList({
    super.key,
    required this.days,
    this.weekStrip = false,
    this.selected,
    this.onSelectDay,
    this.emptyLabel,
    this.today,
    this.padding = EdgeInsets.zero,
    this.timeWidth,
  }) : _sliver = false;

  /// A mesma lista como sliver.
  const SsAgendaList.sliver({
    super.key,
    required this.days,
    this.weekStrip = false,
    this.selected,
    this.onSelectDay,
    this.emptyLabel,
    this.today,
    this.padding = EdgeInsets.zero,
    this.timeWidth,
  }) : _sliver = true;

  final List<SsAgendaDay> days;
  final bool weekStrip;
  final DateTime? selected;
  final ValueChanged<DateTime>? onSelectDay;

  /// Texto do dia vazio (padrão: "Nada neste dia" do [SsStrings]).
  final String? emptyLabel;

  /// Hoje da faixa de dias (padrão: o relógio).
  final DateTime? today;
  final EdgeInsetsGeometry padding;

  /// Largura da coluna da hora. Nulo (padrão): a do texto mais largo da
  /// lista (medido com a fonte e a escala de texto da tela), entre 48 e 136;
  /// a hora que passar disso encolhe para caber numa linha ("Dia todo" quebra
  /// em até 2). Todas as linhas usam a mesma
  /// largura, então os títulos ficam alinhados.
  final double? timeWidth;
  final bool _sliver;

  /// Texto da coluna da hora de [e]: a 1ª linha (hora ou "Dia todo").
  static String _hora(SsAgendaItem e, SsStrings s) => e.allDay && e.time.isEmpty ? s.allDay : e.time;

  double _largura(BuildContext context) {
    final s = SsStrings.of(context);
    final escala = MediaQuery.textScalerOf(context);
    final mono = AppTheme.number(context, size: AppType.sub, weight: FontWeight.w600);
    final rotulo = DefaultTextStyle.of(
      context,
    ).style.merge(const TextStyle(fontSize: AppType.meta, fontWeight: FontWeight.w700));
    var maior = 0.0;
    for (final d in days) {
      for (final e in d.events) {
        for (final (texto, estilo) in [
          (_hora(e, s), e.allDay && e.time.isEmpty ? rotulo : mono),
          if (e.end != null) (e.end!, mono),
        ]) {
          if (texto.isEmpty) continue;
          final tp = TextPainter(
            text: TextSpan(text: texto, style: estilo),
            textDirection: TextDirection.ltr,
            textScaler: escala,
            maxLines: 1,
          )..layout();
          maior = math.max(maior, tp.width);
          tp.dispose();
        }
      }
    }
    return (maior + 2).clamp(48.0, 136.0);
  }

  List<Widget> _linhas(BuildContext context) {
    final c = SsColors.of(context);
    final s = SsStrings.of(context);
    final largura = timeWidth ?? _largura(context);
    final sel = selected == null ? null : _dia(selected!);
    final out = <Widget>[];
    if (weekStrip) {
      final base = sel ?? (days.isEmpty ? _dia(today ?? DateTime.now()) : _dia(days.first.date));
      out.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SsDateStrip(
            selected: base,
            today: today,
            showHeader: false,
            markers: {
              for (final d in days)
                if (d.events.isNotEmpty) _dia(d.date): [for (final e in d.events.take(3)) _cor(context, e)],
            },
            onChanged: (d) => onSelectDay?.call(d),
          ),
        ),
      );
    }
    for (final (i, d) in days.indexed) {
      final dia = _dia(d.date);
      final eSel = sel != null && dia == sel;
      final extenso = s.longDate(dia);
      // "Quarta, 4 de novembro" quando abre o cabeçalho.
      final data = d.label == null && extenso.isNotEmpty ? extenso[0].toUpperCase() + extenso.substring(1) : extenso;
      out.add(
        _CabecalhoDia(
          titulo: d.label == null ? data : '${d.label} · $data',
          selecionado: eSel,
          primeiro: i == 0,
          onTap: onSelectDay == null ? null : () => onSelectDay!(dia),
        ),
      );
      if (d.events.isEmpty) {
        out.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 6),
            child: Text(
              emptyLabel ?? s.agendaEmptyDay,
              style: TextStyle(color: c.muted, fontSize: AppType.sub, fontStyle: FontStyle.italic),
            ),
          ),
        );
      } else {
        for (final e in d.events) {
          out.add(_LinhaAgenda(e, _cor(context, e), largura));
        }
      }
    }
    return out;
  }

  static Color _cor(BuildContext context, SsAgendaItem e) =>
      e.color ?? e.tone?.colors(context).solid ?? SsColors.of(context).accent;

  @override
  Widget build(BuildContext context) {
    final linhas = _linhas(context);
    if (_sliver) {
      return SliverPadding(
        padding: padding,
        sliver: SliverList.list(children: linhas),
      );
    }
    return Padding(
      padding: padding,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: linhas),
    );
  }
}

class _CabecalhoDia extends StatelessWidget {
  const _CabecalhoDia({required this.titulo, required this.selecionado, required this.primeiro, this.onTap});
  final String titulo;
  final bool selecionado, primeiro;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final texto = Padding(
      padding: EdgeInsets.fromLTRB(4, primeiro ? 4 : 14, 4, 6),
      child: Row(
        children: [
          if (selecionado) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selecionado ? c.accentText : c.ink2,
                fontSize: AppType.sub,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    return Semantics(
      header: true,
      selected: selecionado,
      button: onTap != null,
      label: titulo,
      excludeSemantics: true,
      child: onTap == null ? texto : SsPressable(onTap: onTap, child: texto),
    );
  }
}

class _LinhaAgenda extends StatelessWidget {
  const _LinhaAgenda(this.e, this.cor, this.largura);
  final SsAgendaItem e;
  final Color cor;
  final double largura;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = SsStrings.of(context);
    final hora = SsAgendaList._hora(e, s);
    final soRotulo = e.allDay && e.time.isEmpty;
    final faixa = e.end == null ? hora : '$hora – ${e.end}';
    final d = SsDensity.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: d.space(6)),
      child: Semantics(
        button: e.onTap != null,
        label: [faixa, e.title, ?e.detail].join(', '),
        excludeSemantics: true,
        child: SsPressable(
          onTap: e.onTap,
          enabled: e.onTap != null,
          child: Container(
            constraints: BoxConstraints(minHeight: d.fieldHeight),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.field),
              border: Border.all(color: c.line),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: cor),
                  Padding(
                    padding: EdgeInsets.fromLTRB(d.padX - 4, d.rowPadV, 0, d.rowPadV),
                    child: Container(
                      width: largura,
                      alignment: AlignmentDirectional.centerStart,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (soRotulo)
                            Text(
                              hora,
                              maxLines: 2,
                              style: TextStyle(
                                color: c.ink2,
                                fontSize: AppType.meta,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            )
                          else
                            // Uma linha sempre: o que não couber na coluna encolhe (não quebra nem corta).
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                hora,
                                maxLines: 1,
                                style: AppTheme.number(
                                  context,
                                  size: AppType.sub,
                                  weight: FontWeight.w600,
                                  color: c.ink2,
                                ),
                              ),
                            ),
                          if (e.end != null)
                            Text(
                              e.end!,
                              maxLines: 1,
                              style: AppTheme.number(context, size: AppType.meta, color: c.muted),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(8, d.rowPadV, d.padX - 4, d.rowPadV),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            e.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: c.ink, fontSize: d.font(AppType.set), fontWeight: FontWeight.w700),
                          ),
                          if (e.detail != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                e.detail!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: c.muted, fontSize: AppType.meta),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (e.onTap != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(Icons.chevron_right_rounded, color: c.muted2, size: 20),
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
