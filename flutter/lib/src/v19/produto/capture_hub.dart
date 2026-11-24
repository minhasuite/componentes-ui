// v1.9 · produto: formas de capturar (par do Ss::CaptureHubComponent do web). Generaliza a folha "O que você quer
// registrar?" do minhas-compras-app (scan_sheet.dart): opção destacada no gradiente, grade de blocos com ícone,
// título e descrição, e a opção indisponível com o motivo.
import 'package:material_ui/material_ui.dart';

import '../../app_theme.dart';
import '../../density.dart';
import '../../motion.dart';
import '../../section.dart';
import '../../ss_hero.dart';
import '../../ss_list.dart';
import '../../ss_sheet.dart';
import '../../ss_strings.dart';

/// Tipo da opção: dá o ícone, o título e a descrição padrão (do [SsStrings]). [custom] não tem padrão.
enum SsCaptureKind { camera, gallery, paste, barcode, file, custom }

/// Uma forma de capturar. Sem [title]/[description]/[icon], vale o padrão do [kind].
///
/// - [highlighted]: o bloco grande no gradiente da marca, no alto (o jeito principal: "Foto do cupom").
/// - [disabledReason]: apagada, com cadeado e o motivo no lugar da descrição ("No plano Pro", "Sem câmera").
///   Com [onDisabledTap] continua tocável (abrir os planos); sem ele, não responde.
/// - [group]: título da seção ("Compra", "Produto"); opções seguidas do mesmo grupo ficam juntas.
@immutable
class SsCaptureOption {
  const SsCaptureOption({
    this.kind = SsCaptureKind.custom,
    this.onTap,
    this.icon,
    this.title,
    this.description,
    this.highlighted = false,
    this.disabledReason,
    this.onDisabledTap,
    this.group,
  });

  final SsCaptureKind kind;
  final VoidCallback? onTap;
  final IconData? icon;
  final String? title;
  final String? description;
  final bool highlighted;
  final String? disabledReason;
  final VoidCallback? onDisabledTap;
  final String? group;

  bool get disabled => disabledReason != null || onTap == null;

  static IconData defaultIcon(SsCaptureKind k) => switch (k) {
    SsCaptureKind.camera => Icons.photo_camera_outlined,
    SsCaptureKind.gallery => Icons.photo_library_outlined,
    SsCaptureKind.paste => Icons.content_paste_rounded,
    SsCaptureKind.barcode => Icons.qr_code_scanner_rounded,
    SsCaptureKind.file => Icons.upload_file_outlined,
    SsCaptureKind.custom => Icons.add_circle_outline_rounded,
  };

  String titleIn(SsStrings s) =>
      title ??
      switch (kind) {
        SsCaptureKind.camera => s.captureCamera,
        SsCaptureKind.gallery => s.captureGallery,
        SsCaptureKind.paste => s.capturePaste,
        SsCaptureKind.barcode => s.captureBarcode,
        SsCaptureKind.file => s.captureFile,
        SsCaptureKind.custom => '',
      };

  String? descriptionIn(SsStrings s) =>
      description ??
      switch (kind) {
        SsCaptureKind.camera => s.captureCameraHint,
        SsCaptureKind.gallery => s.captureGalleryHint,
        SsCaptureKind.paste => s.capturePasteHint,
        SsCaptureKind.barcode => s.captureBarcodeHint,
        SsCaptureKind.file => s.captureFileHint,
        SsCaptureKind.custom => null,
      };
}

/// Grade das formas de capturar: as [options] destacadas no alto (bloco largo no gradiente) e as outras em
/// [columns] colunas (padrão 2; 1 com texto grande ou tela estreita), cada uma com ícone tonal, título e
/// descrição, separadas por [SsCaptureOption.group]. Indisponível: cadeado, o motivo e "Indisponível" no
/// leitor de tela. Alvo de toque de 48 no mínimo; sem altura fixa (o texto quebra). Na folha, use
/// [showSsCaptureHub].
///
/// `SsCaptureHub(options: [SsCaptureOption(kind: SsCaptureKind.camera, highlighted: true, title: 'Foto do cupom', onTap: foto), SsCaptureOption(kind: SsCaptureKind.barcode, onTap: ler)])`
class SsCaptureHub extends StatelessWidget {
  const SsCaptureHub({super.key, required this.options, this.columns});

  final List<SsCaptureOption> options;

  /// Colunas da grade (nulo: 2, ou 1 com texto 1,15× ou largura abaixo de 300).
  final int? columns;

  @override
  Widget build(BuildContext context) {
    final destaques = options.where((o) => o.highlighted && !o.disabled).toList();
    final resto = options.where((o) => !(o.highlighted && !o.disabled)).toList();
    final blocos = <Widget>[];
    for (final o in destaques) {
      blocos.add(Padding(padding: const EdgeInsets.only(bottom: 10), child: _Destaque(o)));
    }
    // Grupos seguidos: cabeçalho + grade.
    var i = 0;
    while (i < resto.length) {
      final g = resto[i].group;
      final doGrupo = <SsCaptureOption>[];
      while (i < resto.length && resto[i].group == g) {
        doGrupo.add(resto[i++]);
      }
      if (g != null) blocos.add(SsSection(g));
      blocos.add(_Grade(doGrupo, columns: columns));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: blocos);
  }
}

class _Grade extends StatelessWidget {
  const _Grade(this.options, {this.columns});
  final List<SsCaptureOption> options;
  final int? columns;

  @override
  Widget build(BuildContext context) {
    final grande = MediaQuery.textScalerOf(context).scale(10) > 11.5;
    return LayoutBuilder(
      builder: (_, box) {
        final cols = columns ?? (grande || box.maxWidth < 300 ? 1 : 2);
        final w = (box.maxWidth - 10 * (cols - 1)) / cols;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [for (final o in options) SizedBox(width: w, child: _Bloco(o))],
        );
      },
    );
  }
}

class _Bloco extends StatelessWidget {
  const _Bloco(this.o);
  final SsCaptureOption o;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    final titulo = o.titleIn(s);
    final desc = o.disabledReason ?? o.descriptionIn(s);
    final tap = o.disabled ? o.onDisabledTap : o.onTap;
    final rotulo = [titulo, ?desc, if (o.disabled) s.captureUnavailable].join('. ');
    return Semantics(
      button: tap != null,
      enabled: !o.disabled,
      label: rotulo,
      excludeSemantics: true,
      child: SsPressable(
        onTap: tap,
        enabled: tap != null,
        child: Opacity(
          opacity: o.disabled ? .6 : 1,
          child: Container(
            constraints: BoxConstraints(minHeight: d.space(104).clamp(d.minTarget, 200)),
            padding: EdgeInsets.all(d.space(12)),
            decoration: BoxDecoration(
              color: o.disabled ? c.field : c.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: c.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SsIconTile(
                      o.icon ?? SsCaptureOption.defaultIcon(o.kind),
                      size: 36,
                      tone: o.disabled ? c.muted : null,
                    ),
                    const Spacer(),
                    if (o.disabled) Icon(Icons.lock_outline_rounded, size: 16, color: c.muted),
                  ],
                ),
                SizedBox(height: d.space(8)),
                Text(
                  titulo,
                  style: TextStyle(color: c.ink, fontWeight: FontWeight.w800, fontSize: d.font(AppType.body)),
                ),
                if (desc != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TextStyle(
                      color: o.disabledReason != null ? c.ink2 : c.muted,
                      fontSize: AppType.label,
                      height: AppType.snug,
                      fontWeight: o.disabledReason != null ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Destaque extends StatelessWidget {
  const _Destaque(this.o);
  final SsCaptureOption o;

  @override
  Widget build(BuildContext context) {
    final s = SsStrings.of(context);
    final titulo = o.titleIn(s);
    final desc = o.descriptionIn(s);
    return SsHeroCard.custom(
      onTap: o.onTap,
      radius: AppRadius.cardActive,
      padding: const EdgeInsets.all(18),
      semanticLabel: [titulo, ?desc, s.captureRecommended].join('. '),
      child: Row(
        children: [
          SsIconTile(o.icon ?? SsCaptureOption.defaultIcon(o.kind), size: 56, onGradient: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.captureRecommended.toUpperCase(),
                  style: const TextStyle(fontSize: AppType.micro, fontWeight: FontWeight.w800, letterSpacing: .8),
                ),
                Text(
                  titulo,
                  style: const TextStyle(fontSize: AppType.lg, fontWeight: FontWeight.w800),
                ),
                if (desc != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: AppType.meta, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded),
        ],
      ),
    );
  }
}

/// Abre o [SsCaptureHub] numa folha. Tocar numa opção fecha a folha antes de chamar o `onTap` (o fluxo abre
/// sobre quem chamou, não sobre a folha que sai); a indisponível com `onDisabledTap` também fecha.
Future<void> showSsCaptureHub(
  BuildContext context, {
  required List<SsCaptureOption> options,
  String? title,
  String? subtitle,
  IconData? icon,
}) => showSsSheet<void>(
  context,
  title: title,
  subtitle: subtitle,
  icon: icon,
  child: Builder(
    builder: (sheet) {
      VoidCallback? fechaE(VoidCallback? f) => f == null
          ? null
          : () {
              Navigator.of(sheet).pop();
              f();
            };
      return SsCaptureHub(
        options: [
          for (final o in options)
            SsCaptureOption(
              kind: o.kind,
              onTap: fechaE(o.onTap),
              icon: o.icon,
              title: o.title,
              description: o.description,
              highlighted: o.highlighted,
              disabledReason: o.disabledReason,
              onDisabledTap: fechaE(o.onDisabledTap),
              group: o.group,
            ),
        ],
      );
    },
  ),
);
