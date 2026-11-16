// v0.28 (meulog): faixa de status por dia, par do Ss::DayStripComponent do web.
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../ss_badge.dart' show SsTone;
import '../ss_strings.dart';
import '../v191/pecas.dart' show SsTooltip;

/// A situação de um dia na [SsDayStrip].
enum SsDayTone { ok, warn, bad, none }

/// Um dia da [SsDayStrip]: a [label] (a data como o app quer ler), a situação
/// e o [text] da dica ("2 falhas em 288").
@immutable
class SsDay {
  const SsDay(this.label, this.tone, {this.text});

  final String label;
  final SsDayTone tone;
  final String? text;
}

/// Faixa de status por dia, como numa página de status: um traço por dia, com
/// respiro entre eles (não encostam). Lê-se padrão, não valor ("cai toda
/// segunda"). Dia sem dado ([SsDayTone.none]) é vazado, não verde: "não olhei"
/// não é "estava no ar". Toque longo (ou o mouse) mostra a data e o texto; o
/// leitor de tela ouve o [title] e um resumo (quantos dias fora e instáveis).
///
/// `SsDayStrip(title: 'Disponibilidade, 30 dias', days: dias, startLabel: 'há 30 dias', endLabel: 'hoje')`
class SsDayStrip extends StatelessWidget {
  const SsDayStrip({
    super.key,
    required this.days,
    required this.title,
    this.startLabel,
    this.endLabel,
    this.height = 32,
    this.showTitle = false,
  });

  final List<SsDay> days;
  final String title;

  /// As pontas embaixo (padrão: o rótulo do primeiro e do último dia).
  final String? startLabel;
  final String? endLabel;

  /// Altura dos traços.
  final double height;

  /// Mostra o [title] em cima (sem ele, só para o leitor de tela).
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();
    final c = SsColors.of(context);
    final s = SsStrings.of(context);
    String nome(SsDayTone t) => switch (t) {
      SsDayTone.ok => s.dayStripOk,
      SsDayTone.warn => s.dayStripWarn,
      SsDayTone.bad => s.dayStripBad,
      SsDayTone.none => s.dayStripNone,
    };
    Color? cor(SsDayTone t) => switch (t) {
      SsDayTone.ok => c.success,
      SsDayTone.warn => SsTone.warning.colors(context).solid,
      SsDayTone.bad => c.danger,
      SsDayTone.none => null,
    };
    final fora = days.where((d) => d.tone == SsDayTone.bad).length;
    final instaveis = days.where((d) => d.tone == SsDayTone.warn).length;
    final resumo = '$title: ${days.length} · ${s.dayStripBad} $fora · ${s.dayStripWarn} $instaveis';
    return Semantics(
      container: true,
      label: resumo,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showTitle) ...[
              Text(
                title,
                style: TextStyle(color: c.ink, fontSize: AppType.sub, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
            ],
            SizedBox(
              height: height,
              child: Row(
                children: [
                  for (var i = 0; i < days.length; i++) ...[
                    if (i > 0) const SizedBox(width: 3),
                    Expanded(
                      child: SsTooltip(
                        message: [days[i].label, nome(days[i].tone), ?days[i].text].join(' · '),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: cor(days[i].tone),
                            borderRadius: BorderRadius.circular(3),
                            border: days[i].tone == SsDayTone.none ? Border.all(color: c.line, width: 1.5) : null,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  startLabel ?? days.first.label,
                  style: AppTheme.number(context, size: AppType.sub - 1, color: c.muted),
                ),
                Text(
                  endLabel ?? days.last.label,
                  style: AppTheme.number(context, size: AppType.sub - 1, color: c.muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
