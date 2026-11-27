// v1.13.0 "confiança na IA e suíte": o mesmo registro mudou em dois lugares (offline) e a pessoa escolhe o que fica
// (par do Ss::ConflictResolverComponent). "Sua versão" × "Versão do servidor", campo a campo, com "Ficar com a minha"
// e "Ficar com a do servidor". Abre do SsSyncPanel(conflictCount:, onResolveConflicts:). Gravar é do app.
import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';
import '../density.dart';
import '../format.dart';
import '../motion.dart';
import '../ss_button.dart';
import '../ss_strings.dart';
import 'strings.dart';

/// Um campo do registro nas duas versões, já formatado.
class SsConflictField {
  const SsConflictField({required this.key, required this.label, this.mine, this.theirs});

  final String key;
  final String label;
  final String? mine;
  final String? theirs;

  bool get same => (mine ?? '').trim() == (theirs ?? '').trim();
}

/// De que lado fica o campo.
enum SsConflictSide { mine, theirs }

/// Escolher campo a campo entre a versão do aparelho e a do servidor. Só os campos diferentes aparecem (os iguais
/// viram uma linha "3 campos iguais nas duas versões"). Começa com a sua versão marcada em tudo; [initial] troca.
///
/// ```dart
/// SsConflictResolver(
///   title: 'Pedido 1042', fields: campos, mineAt: local.editadoEm, theirsAt: remoto.editadoEm, theirsBy: 'Ana',
///   onResolve: (escolha) => sync.resolver(pedido, escolha), // Map<String, SsConflictSide>
/// )
/// ```
class SsConflictResolver extends StatefulWidget {
  const SsConflictResolver({
    super.key,
    required this.fields,
    required this.onResolve,
    this.title,
    this.mineAt,
    this.theirsAt,
    this.theirsBy,
    this.initial,
    this.onCancel,
    this.busy = false,
    this.now,
  });

  final List<SsConflictField> fields;
  final void Function(Map<String, SsConflictSide> choice) onResolve;

  /// O registro ("Pedido 1042"); sem ele, "Este registro mudou em dois lugares".
  final String? title;
  final DateTime? mineAt;
  final DateTime? theirsAt;

  /// Quem mudou no servidor.
  final String? theirsBy;
  final Map<String, SsConflictSide>? initial;
  final VoidCallback? onCancel;
  final bool busy;
  final DateTime? now;

  @override
  State<SsConflictResolver> createState() => _SsConflictResolverState();
}

class _SsConflictResolverState extends State<SsConflictResolver> {
  late final Map<String, SsConflictSide> _pick = {
    for (final f in widget.fields) f.key: widget.initial?[f.key] ?? SsConflictSide.mine,
  };

  void _all(SsConflictSide side) => setState(() => _pick.updateAll((_, _) => side));

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final t = SsTrustStrings.of(context);
    final s = SsStrings.of(context);
    final diff = [
      for (final f in widget.fields)
        if (!f.same) f,
    ];
    final same = widget.fields.length - diff.length;
    String side(String label, DateTime? at, [String? by]) => [
      label,
      if (at != null) timeAgo(at, now: widget.now, strings: s),
      if (by != null) SsTrustStrings.fill(t.conflictBy, {'name': by}),
    ].join(' · ');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.sync_problem_rounded, color: c.aquecText),
            SizedBox(width: d.space(8)),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  widget.title ?? t.conflictTitle,
                  style: TextStyle(fontSize: AppType.lg, fontWeight: FontWeight.w800, color: c.ink),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: d.space(4)),
        Text(
          widget.title == null ? t.conflictHint : '${t.conflictTitle}. ${t.conflictHint}',
          style: TextStyle(fontSize: AppType.sub, color: c.muted),
        ),
        SizedBox(height: d.space(12)),
        Wrap(
          spacing: d.space(8),
          runSpacing: d.space(8),
          children: [
            SsButton.ghost(
              label: t.conflictKeepMine,
              small: true,
              expand: false,
              icon: Icons.smartphone_rounded,
              onPressed: widget.busy ? null : () => _all(SsConflictSide.mine),
            ),
            SsButton.ghost(
              label: t.conflictKeepTheirs,
              small: true,
              expand: false,
              icon: Icons.cloud_outlined,
              onPressed: widget.busy ? null : () => _all(SsConflictSide.theirs),
            ),
          ],
        ),
        for (final f in diff) ...[
          SizedBox(height: d.space(16)),
          Semantics(
            header: true,
            child: Text(
              f.label,
              style: TextStyle(fontSize: AppType.meta, fontWeight: FontWeight.w800, color: c.ink2),
            ),
          ),
          SizedBox(height: d.space(6)),
          _Option(
            title: side(t.conflictMine, widget.mineAt),
            value: f.mine,
            selected: _pick[f.key] == SsConflictSide.mine,
            onTap: widget.busy ? null : () => setState(() => _pick[f.key] = SsConflictSide.mine),
          ),
          SizedBox(height: d.space(6)),
          _Option(
            title: side(t.conflictTheirs, widget.theirsAt, widget.theirsBy),
            value: f.theirs,
            selected: _pick[f.key] == SsConflictSide.theirs,
            onTap: widget.busy ? null : () => setState(() => _pick[f.key] = SsConflictSide.theirs),
          ),
        ],
        if (same > 0) ...[
          SizedBox(height: d.space(12)),
          Text(
            same == 1 ? t.conflictSameOne : SsTrustStrings.fill(t.conflictSame, {'count': same}),
            style: TextStyle(fontSize: AppType.meta, color: c.muted),
          ),
        ],
        SizedBox(height: d.space(16)),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: d.space(8),
          runSpacing: d.space(8),
          children: [
            if (widget.onCancel != null)
              SsButton.text(label: s.cancel, onPressed: widget.busy ? null : widget.onCancel),
            SsButton(
              label: t.conflictSave,
              icon: Icons.check_rounded,
              expand: false,
              loading: widget.busy,
              onPressed: () => widget.onResolve(Map.unmodifiable(_pick)),
            ),
          ],
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.title, required this.value, required this.selected, required this.onTap});
  final String title;
  final String? value;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final t = SsTrustStrings.of(context);
    final v = (value ?? '').trim();
    final dur = reduceMotion(context) ? Duration.zero : SsMotion.short;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: '$title: ${v.isEmpty ? t.conflictEmpty : v}',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.field),
        child: AnimatedContainer(
          duration: dur,
          constraints: BoxConstraints(minHeight: d.minTarget),
          padding: EdgeInsets.symmetric(horizontal: d.space(12), vertical: d.space(10)),
          decoration: BoxDecoration(
            color: selected ? c.accentSoft : c.surface,
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(color: selected ? c.accent : c.line, width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: selected ? c.accentText : c.muted,
              ),
              SizedBox(width: d.space(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: AppType.meta, color: c.muted),
                    ),
                    Text(
                      v.isEmpty ? t.conflictEmpty : v,
                      style: TextStyle(
                        fontSize: AppType.set,
                        fontWeight: FontWeight.w600,
                        color: v.isEmpty ? c.muted : c.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
