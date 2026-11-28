// v1.9 · paridade_app: código de verificação (par do Ss::OtpInputComponent).
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../app_theme.dart';
import '../../density.dart';
import '../../motion.dart';
import '../../ss_fields.dart' show SsFieldLabel;
import '../../ss_strings.dart';

/// Código de verificação: uma caixinha por dígito, o foco anda sozinho,
/// apagar volta, e **colar o código inteiro** (ou o que vier do SMS pelo
/// autofill, `AutofillHints.oneTimeCode`) preenche todas de uma vez. Por baixo
/// é um campo só (o leitor de tela ouve "Código de verificação" e o que já foi
/// digitado), então teclado numérico, colar e autofill funcionam como num
/// campo comum. Ao completar [length] dígitos chama [onCompleted]. Par do
/// `Ss::OtpInputComponent` (o `ss-otp:complete` do web).
///
/// `SsOtpField(onCompleted: (code) => confirmar(code))`
class SsOtpField extends StatefulWidget {
  const SsOtpField({
    super.key,
    this.length = 6,
    this.onCompleted,
    this.onChanged,
    this.controller,
    this.label,
    this.errorText,
    this.autofocus = false,
    this.enabled = true,
  }) : assert(length > 0);

  final int length;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;

  /// Para ler ou limpar de fora (`controller.clear()` depois de um código errado).
  final TextEditingController? controller;

  /// Padrão: [SsStrings.otpLabel]. Vazio (`''`) esconde o rótulo visível.
  final String? label;

  /// Código errado: caixas na cor do erro e o texto embaixo.
  final String? errorText;
  final bool autofocus;
  final bool enabled;

  @override
  State<SsOtpField> createState() => _SsOtpFieldState();
}

class _SsOtpFieldState extends State<SsOtpField> {
  TextEditingController? _proprio;
  TextEditingController get _c => widget.controller ?? (_proprio ??= TextEditingController());
  final _foco = FocusNode();

  @override
  void initState() {
    super.initState();
    _c.addListener(_mudou);
    _foco.addListener(_mudou);
  }

  @override
  void didUpdateWidget(SsOtpField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      (old.controller ?? _proprio)?.removeListener(_mudou);
      _c.addListener(_mudou);
    }
  }

  @override
  void dispose() {
    _c.removeListener(_mudou);
    _proprio?.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _mudou() {
    if (mounted) setState(() {});
  }

  void _texto(String v) {
    widget.onChanged?.call(v);
    if (v.length == widget.length) {
      SsHaptics.light();
      widget.onCompleted?.call(v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    final rotulo = widget.label ?? s.otpLabel;
    final codigo = _c.text;
    final focado = _foco.hasFocus;
    final erro = widget.errorText != null;
    final atual = codigo.length.clamp(0, widget.length - 1);
    final reduz = reduceMotion(context);

    Widget caixa(int i, double lado) {
      final ch = i < codigo.length ? codigo[i] : '';
      final ativo = focado && i == atual;
      final borda = erro ? c.danger : (ativo ? c.accent : c.line);
      return AnimatedContainer(
        duration: reduz ? Duration.zero : SsMotion.fast,
        width: lado,
        height: lado + 8,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(d.radiusField),
          border: Border.all(color: borda, width: ativo || erro ? 2 : 1),
          boxShadow: ativo ? [BoxShadow(color: c.accent.withValues(alpha: .18), blurRadius: 0, spreadRadius: 3)] : null,
        ),
        child: ch.isEmpty
            ? Text(
                '·',
                style: TextStyle(fontSize: AppType.lg, color: c.muted2),
              )
            : Text(ch, style: AppTheme.number(context, size: 22, color: c.ink)),
      );
    }

    final campo = TextField(
      controller: _c,
      focusNode: _foco,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(widget.length)],
      onChanged: _texto,
      showCursor: false,
      enableSuggestions: false,
      autocorrect: false,
      style: const TextStyle(color: AppColors.transparent, fontSize: 1),
      // v1.14.6: o campo é invisível; sem isso ele herdava do inputDecorationTheme a borda de foco
      // (o .collapsed só zera `border`) e desenhava um traço colorido sob o rótulo.
      decoration: const InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        filled: false,
        contentPadding: EdgeInsets.zero,
        counterText: '',
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rotulo.isNotEmpty) ExcludeSemantics(child: SsFieldLabel(rotulo)),
        Stack(
          children: [
            // As caixas dividem a largura (até controlHeight + 8 cada), numa linha só.
            LayoutBuilder(
              builder: (context, k) {
                final cabe = (k.maxWidth - 8 * (widget.length - 1)) / widget.length;
                final lado = cabe.clamp(28.0, d.controlHeight + 8);
                return ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [for (var i = 0; i < widget.length; i++) caixa(i, lado)],
                  ),
                );
              },
            ),
            // O campo de verdade, invisível, por cima das caixas (toque, colar, autofill).
            Positioned.fill(
              child: MergeSemantics(
                child: Semantics(label: rotulo, child: campo),
              ),
            ),
          ],
        ),
        if (erro) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: TextStyle(fontSize: AppType.meta, color: c.dangerText),
          ),
        ],
      ],
    );
  }
}
