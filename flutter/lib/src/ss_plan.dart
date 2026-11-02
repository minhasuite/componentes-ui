import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'ss_button.dart';
import 'ss_sheet.dart';

/// Abre a folha "chegou no limite do plano" ([SsPlanLimit]). "Ver planos"
/// fecha a folha e chama [onUpgrade]; "Agora não" só fecha. Com
/// [secondaryLabel] e [onSecondary], o segundo botão vira essa ação (ex.:
/// "Apagar um antigo") e também fecha a folha.
Future<void> showSsPlanLimit(
  BuildContext context, {
  required String title,
  required String message,
  required VoidCallback onUpgrade,
  String upgradeLabel = 'Ver planos',
  String? secondaryLabel,
  VoidCallback? onSecondary,
}) => showSsSheet<void>(
  context,
  child: SsPlanLimit(
    title: title,
    message: message,
    onUpgrade: onUpgrade,
    upgradeLabel: upgradeLabel,
    secondaryLabel: secondaryLabel,
    onSecondary: onSecondary,
  ),
);

/// Corpo da folha de limite do plano (o que o [showSsPlanLimit] mostra).
class SsPlanLimit extends StatelessWidget {
  const SsPlanLimit({
    super.key,
    required this.title,
    required this.message,
    required this.onUpgrade,
    this.upgradeLabel = 'Ver planos',
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String message;
  final VoidCallback onUpgrade;
  final String upgradeLabel;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        const _Cadeado(size: 64),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.ink, fontSize: AppType.lg, fontWeight: FontWeight.w800, height: 1.25),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: c.muted, fontSize: AppType.set, height: 1.45),
        ),
        const SizedBox(height: 20),
        SsButton(
          label: upgradeLabel,
          icon: Icons.workspace_premium_outlined,
          onPressed: () {
            Navigator.maybePop(context);
            onUpgrade();
          },
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () {
            Navigator.maybePop(context);
            onSecondary?.call();
          },
          child: Text(onSecondary == null ? 'Agora não' : secondaryLabel ?? 'Agora não'),
        ),
      ],
    );
  }
}

/// Cadeado num círculo com o gradiente da marca.
class _Cadeado extends StatelessWidget {
  const _Cadeado({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.brandFrom, c.brandDeep],
        ),
        boxShadow: c.primaryShadow,
      ),
      child: Icon(Icons.lock_rounded, color: AppColors.onDark, size: size * .45),
    );
  }
}

/// Card de recurso bloqueado no plano atual, no lugar do recurso: cadeado,
/// nome ([feature]), o que ganha ([text]) e "Ver planos".
class SsPlanLocked extends StatelessWidget {
  const SsPlanLocked({
    super.key,
    required this.feature,
    required this.text,
    required this.onUpgrade,
    this.upgradeLabel = 'Ver planos',
  });

  final String feature;
  final String text;
  final VoidCallback onUpgrade;
  final String upgradeLabel;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: c.accent.withValues(alpha: .35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _Cadeado(size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature,
                      style: TextStyle(color: c.ink, fontSize: AppType.md, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Disponível em plano pago',
                      style: TextStyle(color: c.accentText, fontSize: AppType.meta, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: TextStyle(color: c.ink2, fontSize: AppType.sub, height: 1.45),
          ),
          const SizedBox(height: 12),
          SsButton(label: upgradeLabel, small: true, expand: false, onPressed: onUpgrade),
        ],
      ),
    );
  }
}

/// Cota de uso: gomos + "2 de 3 este mês". Fica no tom da marca, vira aviso
/// (aquecimento) quando falta 1 e erro quando acabou. Com [limit] acima de 10,
/// barra contínua no lugar dos gomos.
class SsQuota extends StatelessWidget {
  const SsQuota({super.key, required this.used, required this.limit, this.label = 'este mês'});

  final int used;
  final int limit;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final resta = limit - used;
    final (cor, texto, icone) = resta <= 0
        ? (AppColors.danger, c.dangerText, Icons.block_rounded)
        : resta == 1
        ? (AppColors.aquecFg, c.aquecText, Icons.warning_amber_rounded)
        : (c.accent, c.muted, null);
    final frase = '${used.clamp(0, limit)} de $limit $label';
    return Semantics(
      label: resta <= 0 ? '$frase, limite atingido' : frase,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 84,
              height: 6,
              child: limit > 10
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: limit == 0 ? 1 : (used / limit).clamp(0.0, 1.0),
                        backgroundColor: c.field,
                        color: cor,
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < limit; i++) ...[
                          if (i > 0) const SizedBox(width: 3),
                          Expanded(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: i < used ? cor : c.field,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
            const SizedBox(width: 8),
            if (icone != null) ...[Icon(icone, size: 14, color: cor), const SizedBox(width: 4)],
            Text(
              frase,
              style: TextStyle(color: texto, fontSize: AppType.meta, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
