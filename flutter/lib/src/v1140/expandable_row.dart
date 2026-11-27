// v1.14.0 "interface e animação": a linha da lista que se abre no lugar para a edição rápida. Par do
// Ss::ExpandableRowComponent.
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../ss_button.dart';
import '../ss_list.dart';
import 'strings.dart';

/// Linha de lista que se expande **no lugar** para a edição rápida (o valor de um lançamento, a quantidade de um
/// item), sem abrir outra tela: o toque abre os campos do [editor] embaixo da linha, com a altura animada
/// ([SsMotion.medium], [SsMotion.standard]) e o foco no primeiro campo; Salvar chama [onSave] (o botão fica
/// carregando enquanto espera; `false` mantém aberto, para mostrar o erro no campo), Cancelar ou Esc fecha e
/// chama [onCancel]. A seta gira ao abrir. Com "reduzir movimento", abre e fecha sem animar.
///
/// [expanded] + [onExpandedChanged] deixam o app controlar (só uma aberta por vez na lista); sem eles, a linha
/// cuida de si.
///
/// ```dart
/// SsExpandableRow(
///   title: 'Mercado Bom Preço', subtitle: '26/11', value: money(21490),
///   editor: (context) => SsMoneyField(label: 'Valor', cents: v, onChanged: (x) => v = x),
///   onSave: () async => api.salvar(v),
/// )
/// ```
class SsExpandableRow extends StatefulWidget {
  const SsExpandableRow({
    super.key,
    required this.title,
    required this.editor,
    this.subtitle,
    this.value,
    this.icon,
    this.leading,
    this.onSave,
    this.onCancel,
    this.expanded,
    this.onExpandedChanged,
    this.saveLabel,
    this.cancelLabel,
  });

  final String title;
  final String? subtitle;
  final String? value;
  final IconData? icon;
  final Widget? leading;

  /// Os campos da edição rápida (montados só enquanto aberta).
  final WidgetBuilder editor;

  /// Salvar: `false` mantém aberta; `true`, `null` ou nada fecha.
  final FutureOr<bool?> Function()? onSave;
  final VoidCallback? onCancel;
  final bool? expanded;
  final ValueChanged<bool>? onExpandedChanged;

  /// Padrão: [SsInterfaceStrings.expandSave] e [SsInterfaceStrings.expandCancel].
  final String? saveLabel;
  final String? cancelLabel;

  @override
  State<SsExpandableRow> createState() => _SsExpandableRowState();
}

class _SsExpandableRowState extends State<SsExpandableRow> {
  bool _local = false;
  bool _saving = false;
  final _scope = FocusScopeNode(debugLabel: 'SsExpandableRow');
  final _row = FocusNode(debugLabel: 'SsExpandableRow.row');

  bool get _open => widget.expanded ?? _local;

  @override
  void didUpdateWidget(SsExpandableRow old) {
    super.didUpdateWidget(old);
    if (widget.expanded == true && old.expanded != true) _focusFirst();
  }

  @override
  void dispose() {
    _scope.dispose();
    _row.dispose();
    super.dispose();
  }

  void _set(bool v) {
    if (widget.expanded == null) setState(() => _local = v);
    widget.onExpandedChanged?.call(v);
    if (v) {
      _focusFirst();
    } else {
      _row.requestFocus();
    }
  }

  // O foco vai ao primeiro campo do editor no quadro em que ele aparece.
  void _focusFirst() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_open) return;
      final primeiro = _scope.traversalDescendants.where((n) => n.canRequestFocus && !n.skipTraversal).firstOrNull;
      (primeiro ?? _scope).requestFocus();
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    bool? ok;
    try {
      ok = await widget.onSave?.call();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted || ok == false) return;
    SsHaptics.success();
    _set(false);
  }

  void _cancel() {
    widget.onCancel?.call();
    _set(false);
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final t = SsInterfaceStrings.of(context);
    final reduce = reduceMotion(context);
    final open = _open;
    final seta = AnimatedRotation(
      turns: open ? .5 : 0,
      duration: reduce ? Duration.zero : SsMotion.medium,
      curve: SsMotion.standard,
      child: Icon(Icons.expand_more_rounded, color: c.muted),
    );
    return AnimatedContainer(
      duration: reduce ? Duration.zero : SsMotion.medium,
      curve: SsMotion.standard,
      decoration: BoxDecoration(
        color: open ? c.surface : c.surface.withValues(alpha: 0),
        borderRadius: BorderRadius.circular(d.radiusCard),
        border: Border.all(color: open ? c.line : c.line.withValues(alpha: 0)),
        boxShadow: open ? AppShadows.card : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            expanded: open,
            hint: open ? null : SsInterfaceStrings.fill(t.expandLabel, {'title': widget.title}),
            child: Focus(
              focusNode: _row,
              skipTraversal: true,
              child: SsListItem(
                title: widget.title,
                subtitle: widget.subtitle,
                value: widget.value,
                icon: widget.icon,
                leading: widget.leading,
                trailing: seta,
                onTap: () => _set(!open),
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: reduce ? Duration.zero : SsMotion.medium,
              curve: SsMotion.standard,
              alignment: Alignment.topCenter,
              child: !open
                  ? const SizedBox(width: double.infinity)
                  : CallbackShortcuts(
                      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _cancel},
                      child: FocusScope(
                        node: _scope,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(d.cardPad, 4, d.cardPad, d.cardPad),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Builder(builder: widget.editor),
                              SizedBox(height: d.gap),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  SsButton(
                                    label: widget.cancelLabel ?? t.expandCancel,
                                    variant: SsButtonVariant.ghost,
                                    expand: false,
                                    onPressed: _saving ? null : _cancel,
                                  ),
                                  const SizedBox(width: 8),
                                  SsButton(
                                    label: widget.saveLabel ?? t.expandSave,
                                    expand: false,
                                    loading: _saving,
                                    onPressed: widget.onSave == null ? null : _save,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
