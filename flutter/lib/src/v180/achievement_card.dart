import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';
import '../density.dart';
import '../ss_card.dart';
import '../ss_progress.dart';
import '../ss_strings.dart';

/// v1.8 · Cartão de conquista (par do `Ss::AchievementCardComponent` do web): o medalhão com o ícone, o título,
/// a regra ([description]) e o rodapé. Conquistada ([earned]): medalhão na cor da marca e o selo "Conquistada"
/// com o [caption] ("em 12/11"). Ainda não: medalhão apagado e, com [progress] (0 a 1), a barra fina e o
/// [progressLabel] ("12 de 30 dias").
///
/// Para grade de 2 colunas no celular (360 dp) e texto grande: nada tem altura fixa e o texto quebra. O leitor
/// de tela lê um nó só: "Conquista: Título. Conquistada em 12/11. A regra." (ou "Falta: 12 de 30 dias.").
///
/// ```dart
/// SsAchievementCard(title: '30 dias seguidos', description: 'Sequência de 30 dias escalados com tudo feito.',
///   progress: 12 / 30, progressLabel: '12 de 30 dias')
/// ```
class SsAchievementCard extends StatelessWidget {
  const SsAchievementCard({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.verified_outlined,
    this.earned = false,
    this.caption,
    this.progress,
    this.progressLabel,
    this.onTap,
  });

  final String title;

  /// A regra da conquista, à vista ("Cubra o primeiro turno aberto").
  final String description;

  /// Padrão: o "trophy" do conjunto da suíte (`SsIcons.named('trophy')`, o mesmo do web).
  final IconData icon;
  final bool earned;

  /// Ao lado do selo quando conquistada ("em 12/11").
  final String? caption;

  /// 0 a 1, só quando ainda não foi conquistada.
  final double? progress;

  /// O quanto falta, em texto ("12 de 30 dias").
  final String? progressLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = SsStrings.of(context);
    final d = SsDensity.of(context);
    final medal = d.iconTile + 8;
    final pending = !earned && (progress != null || progressLabel != null);
    final label = [
      '${s.achievementLabel}: $title.',
      if (earned) '${s.achievementEarned}${caption == null ? '' : ' $caption'}.',
      if (pending && progressLabel != null) '${s.achievementMissing}: $progressLabel.',
      description,
    ].join(' ');
    return Semantics(
      container: true,
      button: onTap != null,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: SsCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: medal,
              height: medal,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: earned ? c.accentSoft : c.field,
                border: Border.all(color: earned ? c.accentText : c.line, width: 1.5),
              ),
              child: Icon(icon, size: medal * .5, color: earned ? c.accentText : c.muted),
            ),
            SizedBox(height: d.gap),
            Text(
              title,
              style: TextStyle(
                color: earned ? c.ink : c.ink2,
                fontSize: AppType.body,
                fontWeight: FontWeight.w800,
                height: AppType.snug,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(color: c.muted, fontSize: AppType.sub, height: AppType.leading),
            ),
            if (earned) ...[
              SizedBox(height: d.gap),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // O selo do SsBadge, mas que quebra a linha com texto grande (o SsBadge termina em "…").
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(AppRadius.pill)),
                    // Ícone como parte do texto: com letra grande a linha quebra depois dele, nunca no meio da palavra.
                    child: Text.rich(
                      TextSpan(
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(Icons.check_rounded, size: 14, color: c.accentText),
                            ),
                          ),
                          TextSpan(text: s.achievementEarned),
                        ],
                      ),
                      style: TextStyle(color: c.accentText, fontSize: AppType.label, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (caption != null)
                    Text(
                      caption!,
                      style: TextStyle(color: c.muted, fontSize: AppType.meta),
                    ),
                ],
              ),
            ] else if (pending) ...[
              SizedBox(height: d.gap),
              if (progress != null) SsProgress(progress!.clamp(0.0, 1.0), height: 6),
              if (progressLabel != null) ...[
                if (progress != null) const SizedBox(height: 4),
                Text(
                  progressLabel!,
                  style: TextStyle(color: c.muted, fontSize: AppType.meta),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
