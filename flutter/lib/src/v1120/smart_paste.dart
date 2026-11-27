// v1.12.0 "Kit Brasil": o colar inteligente (par do Ss::SmartPasteComponent). A pessoa cola qualquer coisa; o
// [SsPasteDetector] diz o que é e o cartão mostra o resumo e as ações que o app registrou para aquele tipo.
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../ss_badge.dart';
import '../ss_button.dart';
import '../ss_card.dart';
import '../ss_fields.dart';
import '../ss_strings.dart';
import '../v10/tela_barra.dart' show SsIconButton;
import 'br.dart';
import 'paste_detector.dart';
import 'strings.dart';

/// Uma ação que o app oferece para um tipo colado ("Pagar boleto", "Salvar contato").
class SsPasteAction {
  const SsPasteAction(this.label, this.onPressed, {this.icon, this.primary = false});

  final String label;

  /// Recebe o que foi reconhecido (o valor normalizado em `match.value`, os detalhes em `match.fields`).
  final void Function(SsPasteMatch match) onPressed;
  final IconData? icon;

  /// A ação principal (botão cheio); sem nenhuma marcada, a 1ª.
  final bool primary;
}

/// O ícone de cada tipo (o mesmo desenho do `ss_icon` do web).
IconData ssPasteIcon(SsPasteType t) => switch (t) {
  SsPasteType.pix => Icons.pix,
  SsPasteType.pixKey => Icons.key_outlined,
  SsPasteType.boleto => Icons.receipt_long_outlined,
  SsPasteType.nfe => Icons.description_outlined,
  SsPasteType.cpf => Icons.badge_outlined,
  SsPasteType.cnpj => Icons.business_outlined,
  SsPasteType.cep => Icons.place_outlined,
  SsPasteType.phone => Icons.phone_outlined,
  SsPasteType.email => Icons.alternate_email_rounded,
  SsPasteType.url => Icons.link_rounded,
  SsPasteType.money => Icons.payments_outlined,
  SsPasteType.date => Icons.event_outlined,
  SsPasteType.text => Icons.notes_rounded,
};

/// Campo que recebe o que for colado e reconhece o tipo: Pix (copia e cola ou chave), boleto, chave de NF-e,
/// CPF/CNPJ, CEP, telefone, e-mail, link, valor em R$, data ou texto livre. Embaixo, o cartão "Isso parece um
/// boleto de R$ 123,45 com vencimento em 10/12/2026" e as [actions] que o app registrou para o tipo (e para os
/// do `also`: um CPF válido também mostra as de [SsPasteType.pixKey]).
///
/// ```dart
/// SsSmartPaste(actions: {
///   SsPasteType.boleto: [SsPasteAction('Pagar boleto', (m) => pagar(m.value), icon: Icons.payments_outlined)],
///   SsPasteType.pix: [SsPasteAction('Pagar Pix', (m) => pix(m.value))],
/// })
/// ```
///
/// Com [showPasteButton], o botão "Colar" lê a área de transferência. [onDetected] avisa a cada mudança.
class SsSmartPaste extends StatefulWidget {
  const SsSmartPaste({
    super.key,
    this.actions = const {},
    this.controller,
    this.initialValue,
    this.onDetected,
    this.label,
    this.hint,
    this.showPasteButton = true,
    this.today,
  });

  final Map<SsPasteType, List<SsPasteAction>> actions;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<SsPasteMatch?>? onDetected;
  final String? label;
  final String? hint;
  final bool showPasteButton;

  /// Hoje (o ciclo do vencimento do boleto, o ano da data sem ano); teste e catálogo.
  final DateTime? today;

  @override
  State<SsSmartPaste> createState() => _SsSmartPasteState();
}

class _SsSmartPasteState extends State<SsSmartPaste> {
  late final TextEditingController _ctrl = widget.controller ?? TextEditingController(text: widget.initialValue);
  SsPasteMatch? _m;

  @override
  void initState() {
    super.initState();
    _m = SsPasteDetector.detect(_ctrl.text, today: widget.today);
  }

  @override
  void dispose() {
    if (widget.controller == null) _ctrl.dispose();
    super.dispose();
  }

  void _changed(String v) {
    final m = SsPasteDetector.detect(v, today: widget.today);
    setState(() => _m = m);
    widget.onDetected?.call(m);
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final t = data?.text;
    if (t == null || !mounted) return;
    _ctrl.text = t;
    SsHaptics.selection();
    _changed(t);
  }

  void _clear() {
    _ctrl.clear();
    _changed('');
  }

  @override
  Widget build(BuildContext context) {
    final br = SsBrStrings.of(context);
    final dur = reduceMotion(context) ? Duration.zero : SsMotion.medium;
    final m = _m;
    final temTexto = _ctrl.text.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SsTextField(
          label: widget.label ?? br.pasteLabel,
          controller: _ctrl,
          hint: widget.hint ?? br.pasteHint,
          icon: Icons.content_paste_rounded,
          minLines: 1,
          maxLines: 4,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.multiline,
          onChanged: _changed,
          suffix: temTexto
              ? SsIconButton(icon: Icons.close_rounded, tooltip: br.pasteClear, onPressed: _clear)
              : (widget.showPasteButton
                    ? SsIconButton(icon: Icons.content_paste_go_rounded, tooltip: br.pastePaste, onPressed: _paste)
                    : null),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: dur,
          switchInCurve: SsMotion.enter,
          switchOutCurve: SsMotion.exit,
          layoutBuilder: (atual, antigos) => Stack(alignment: Alignment.topCenter, children: [...antigos, ?atual]),
          child: m == null
              ? _Vazio(key: const ValueKey('vazio'), text: br.pasteEmpty)
              : _Cartao(key: ValueKey('${m.type.key}/${m.value}/${m.valid}'), match: m, actions: widget.actions),
        ),
      ],
    );
  }
}

class _Vazio extends StatelessWidget {
  const _Vazio({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: TextStyle(color: c.muted, fontSize: d.font(AppType.sub)),
      ),
    );
  }
}

class _Cartao extends StatelessWidget {
  const _Cartao({super.key, required this.match, required this.actions});
  final SsPasteMatch match;
  final Map<SsPasteType, List<SsPasteAction>> actions;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final br = SsBrStrings.of(context);
    final s = SsStrings.of(context);
    final f = SsFormats.of(context);
    final m = match;
    final resumo = SsPasteDetector.summary(m, br: br, strings: s, formats: f);
    final tone = m.valid ? SsTone.accent : SsTone.warning;
    final cores = tone.colors(context);
    // DV errado: sem ações (não oferece "Pagar" para um boleto que não confere).
    final lista = [
      if (m.valid)
        for (final t in m.types) ...?actions[t],
    ];
    final principal = lista.indexWhere((a) => a.primary);
    final iPrincipal = principal < 0 ? 0 : principal;
    final detalhe = switch (m.type) {
      SsPasteType.boleto => m.display,
      SsPasteType.nfe => SsBr.formatNfeKey(m.value),
      SsPasteType.pix => (m.fields['city'] as String?),
      _ => null,
    };
    return SsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: cores.soft, borderRadius: BorderRadius.circular(AppRadius.thumb)),
                child: Icon(m.valid ? ssPasteIcon(m.type) : Icons.warning_amber_rounded, color: cores.text, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    resumo,
                    style: TextStyle(
                      color: c.ink,
                      fontSize: d.font(AppType.body),
                      fontWeight: FontWeight.w700,
                      height: AppType.leading,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (detalhe != null && detalhe.isNotEmpty && m.type != SsPasteType.pix) ...[
            const SizedBox(height: 8),
            Text(
              detalhe,
              style: AppTheme.number(context, size: d.font(AppType.meta), color: c.muted).copyWith(height: 1.5),
            ),
          ],
          if (m.also.contains(SsPasteType.pixKey)) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: SsBadge(
                br.keyTypes[m.type.key] == null ? br.pixKey : '${br.pixKey} · ${br.keyTypes[m.type.key]}',
                variant: SsBadgeVariant.muted,
                icon: Icons.pix,
              ),
            ),
          ],
          if (lista.isNotEmpty) ...[
            const SizedBox(height: 12),
            Semantics(
              container: true,
              label: br.pasteActions,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < lista.length; i++)
                    i == iPrincipal
                        ? SsButton(
                            label: lista[i].label,
                            icon: lista[i].icon,
                            small: true,
                            expand: false,
                            onPressed: () => lista[i].onPressed(m),
                          )
                        : SsButton.ghost(
                            label: lista[i].label,
                            icon: lista[i].icon,
                            small: true,
                            expand: false,
                            onPressed: () => lista[i].onPressed(m),
                          ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
