// v0.15: linha de progresso (par do Ss::ProgressRowComponent da gem).
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../density.dart';
import '../format.dart';
import '../motion_view.dart';
import '../ss_strings.dart';
import 'privacy.dart';

/// Limite (orçamento, cartão) ou meta (economia).
enum SsProgressKind { limit, goal }

/// Estado da linha: na marca, aviso, estourou, meta batida.
enum SsProgressTone { ok, warn, over, done }

/// Rótulo, "gasto de limite", % e a barra no tom do estado: orçamento por
/// categoria, limite do cartão, meta de economia. [SsProgressKind.limit]: até
/// [warnAt] (80%) fica na marca (ou em [color]), dali a 100% aviso e acima
/// disso estouro, em vermelho ("R$ 120 acima"). [SsProgressKind.goal]: 100% é
/// sucesso, verde ("Meta batida"). A barra enche com a mola quando entra na
/// tela. [caption] troca o texto da direita embaixo. O web é o
/// `Ss::ProgressRowComponent`.
///
/// `SsProgressRow(label: 'Mercado', value: 720, limit: 1000, format: (v) => money((v * 100).round()))`
class SsProgressRow extends StatelessWidget {
  const SsProgressRow({
    super.key,
    required this.label,
    required this.value,
    required this.limit,
    this.kind = SsProgressKind.limit,
    this.format,
    this.icon,
    this.caption,
    this.onTap,
    this.warnAt = .8,
    this.color,
  });

  final String label;
  final double value;
  final double limit;
  final SsProgressKind kind;
  final String Function(double value)? format;
  final IconData? icon;
  final String? caption;
  final VoidCallback? onTap;
  final double warnAt;
  final Color? color;

  double get ratio => limit > 0 ? math.max(0, value / limit) : (value > 0 ? double.infinity : 0);

  SsProgressTone get tone {
    final r = ratio;
    if (kind == SsProgressKind.goal) return r >= 1 ? SsProgressTone.done : SsProgressTone.ok;
    if (r > 1) return SsProgressTone.over;
    if (r >= warnAt) return SsProgressTone.warn;
    return SsProgressTone.ok;
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    final f = SsFormats.of(context);
    String fmt(double v) => format?.call(v) ?? qty(v, f);
    final t = tone;
    final (cor, texto) = switch (t) {
      SsProgressTone.ok => (color ?? c.accent, c.muted),
      SsProgressTone.warn => (AppColors.aquecFg, c.aquecText),
      SsProgressTone.over => (AppColors.danger, c.dangerText),
      SsProgressTone.done => (AppColors.success, c.successText),
    };
    final pct = ratio.isInfinite ? 100 : (ratio * 100).round();
    final resto = (limit - value).abs();
    final direita =
        caption ??
        switch (t) {
          SsProgressTone.over => s.progressOverBy(fmt(resto)),
          SsProgressTone.done => s.goalReached,
          _ => kind == SsProgressKind.goal ? s.progressToGo(fmt(resto)) : s.progressLeft(fmt(resto)),
        };
    final gasto = s.progressOf(fmt(value), fmt(limit));
    final forte = t != SsProgressTone.ok;
    final oculto = SsPrivacyScope.hiddenOf(context);

    final corpo = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 18, color: c.muted), const SizedBox(width: 8)],
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: d.font(AppType.body), fontWeight: FontWeight.w700, color: c.ink),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              oculto ? '•••' : '$pct%',
              style: AppTheme.number(
                context,
                size: AppType.meta,
                color: forte ? texto : c.ink2,
                weight: forte ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: d.space(6)),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: SizedBox(
            height: 8,
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: c.field)),
                SsTweenInView(
                  end: math.min(ratio, 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutBack,
                  builder: (_, v, _) => FractionallySizedBox(
                    widthFactor: v.clamp(0.0, 1.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(AppRadius.pill)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: d.space(6)),
        Row(
          children: [
            Expanded(
              child: Text(
                oculto ? '•••' : gasto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.number(context, size: AppType.meta, color: c.muted),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              oculto && caption == null && t != SsProgressTone.done ? '•••' : direita,
              style: TextStyle(
                fontSize: AppType.meta,
                color: forte ? texto : c.muted,
                fontWeight: forte ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
    final semantica = oculto ? '$label, ${s.hiddenValue}' : '$label, $pct%, $gasto, $direita';
    final tile = Semantics(label: semantica, button: onTap != null, excludeSemantics: true, child: corpo);
    if (onTap == null) return tile;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.field),
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: tile),
    );
  }
}
