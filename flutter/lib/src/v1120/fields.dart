// v1.12.0 "Kit Brasil": os campos brasileiros (pares do f.ss_pix_key, f.ss_boleto, f.ss_cep e f.ss_document da
// gem). Todos são um SsTextField por baixo (rótulo, validação ao sair, alvo de 48, densidade); o que é do
// Brasil fica aqui: máscara, dígito verificador e o retorno embaixo do campo. Buscar CEP ou CNPJ é do app
// (`onLookup`); ler o código de barras com a câmera também (`onScan`).
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';
import '../density.dart';
import '../ss_badge.dart';
import '../ss_fields.dart';
import '../ss_strings.dart';
import '../v10/tela_barra.dart' show SsIconButton, SsSpinner;
import '../v20/pecas.dart' show SsMask;
import 'br.dart';
import 'strings.dart';

/// A linha de retorno embaixo de um campo do kit (tipo detectado, razão social, vencimento).
class _Retorno extends StatelessWidget {
  const _Retorno({required this.text, this.icon, this.tone = SsTone.neutral, this.badge});
  final String text;
  final IconData? icon;
  final SsTone tone;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final cores = tone.colors(context);
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 6, left: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (badge != null) ...[
              SsBadge(badge!, variant: tone == SsTone.success ? SsBadgeVariant.success : SsBadgeVariant.muted),
              const SizedBox(width: 8),
            ] else if (icon != null) ...[
              Icon(icon, size: 16, color: tone == SsTone.neutral ? c.muted : cores.solid),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tone == SsTone.neutral || tone == SsTone.success ? c.ink2 : cores.text,
                  fontSize: d.font(AppType.sub),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mantém o controlador (o do app ou um próprio).
mixin _Controlado<T extends StatefulWidget> on State<T> {
  TextEditingController? get externo;
  late final TextEditingController ctrl = externo ?? TextEditingController();

  void descartar() {
    if (externo == null) ctrl.dispose();
  }
}

// ── Chave Pix ─────────────────────────────────────────────────────────

/// Campo de chave Pix: detecta o tipo enquanto digita (CPF, CNPJ, telefone, e-mail ou aleatória), mostra o tipo
/// embaixo, formata ao sair (CPF/CNPJ com pontuação, telefone com DDD) e valida. [onChanged] recebe a chave
/// normalizada (a que vai para a API: dígitos, +55…, e-mail em minúscula) e o tipo, ou nulos enquanto inválida.
/// [type] prende num tipo só (o campo recusa os outros).
class SsPixKeyField extends StatefulWidget {
  const SsPixKeyField({
    super.key,
    this.label,
    this.controller,
    this.initialValue,
    this.type,
    this.onChanged,
    this.required = false,
    this.enabled = true,
    this.hideLabel = false,
  });

  final String? label;
  final TextEditingController? controller;
  final String? initialValue;
  final SsPixKeyType? type;
  final void Function(String? key, SsPixKeyType? type)? onChanged;

  /// Vazio é erro ("Chave Pix inválida").
  final bool required;
  final bool enabled;
  final bool hideLabel;

  @override
  State<SsPixKeyField> createState() => _SsPixKeyFieldState();
}

class _SsPixKeyFieldState extends State<SsPixKeyField> with _Controlado {
  @override
  TextEditingController? get externo => widget.controller;
  final _focus = FocusNode();
  SsPixKeyType? _tipo;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null && widget.initialValue != null) ctrl.text = widget.initialValue!;
    _tipo = _detect(ctrl.text);
    _focus.addListener(() {
      if (_focus.hasFocus || _tipo == null) return;
      final shown = SsBr.pixKeyDisplay(ctrl.text, _tipo);
      if (shown != ctrl.text) ctrl.text = shown;
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    descartar();
    super.dispose();
  }

  SsPixKeyType? _detect(String v) {
    final t = SsBr.pixKeyType(v);
    return widget.type == null || t == widget.type ? t : null;
  }

  void _changed(String v) {
    final t = _detect(v);
    setState(() => _tipo = t);
    widget.onChanged?.call(t == null ? null : SsBr.pixKeyNormalize(v, t), t);
  }

  @override
  Widget build(BuildContext context) {
    final br = SsBrStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SsTextField(
          label: widget.label ?? br.pixKey,
          hideLabel: widget.hideLabel,
          controller: ctrl,
          focusNode: _focus,
          hint: br.pixKeyHint,
          icon: Icons.pix,
          enabled: widget.enabled,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: widget.type == SsPixKeyType.email
              ? TextInputType.emailAddress
              : (widget.type == SsPixKeyType.cpf || widget.type == SsPixKeyType.cnpj
                    ? TextInputType.number
                    : TextInputType.text),
          onChanged: _changed,
          validator: (v) {
            final s = (v ?? '').trim();
            if (s.isEmpty) return widget.required ? br.pixKeyInvalid : null;
            return _detect(s) == null ? br.pixKeyInvalid : null;
          },
        ),
        if (_tipo != null)
          _Retorno(text: SsBr.pixKeyDisplay(ctrl.text, _tipo), badge: br.keyTypes[_tipo!.key], tone: SsTone.success),
      ],
    );
  }
}

// ── Boleto ────────────────────────────────────────────────────────────

/// Máscara da linha digitável: 47 dígitos em 5 blocos (bancário) ou 48 em 4 (arrecadação, começa com 8).
class SsBoletoMask extends TextInputFormatter {
  const SsBoletoMask();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var d = SsBr.digits(newValue.text);
    if (d.length == 44) d = SsBr.boletoLineFromBarcode(d) ?? d; // colou o código de barras
    final out = SsBr.formatBoleto(d);
    final end = newValue.selection.end.clamp(0, newValue.text.length);
    final antes = SsBr.digits(newValue.text.substring(0, end)).length;
    var pos = 0, n = 0;
    while (pos < out.length && n < antes) {
      if (RegExp(r'\d').hasMatch(out[pos])) n++;
      pos++;
    }
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: d.length == SsBr.digits(newValue.text).length ? pos : out.length),
    );
  }
}

/// Campo da linha digitável do boleto: máscara (47 bancário, 48 conta de consumo), dígitos verificadores
/// (módulo 10 e 11), e embaixo o tipo, o valor e o vencimento lidos da linha. Com [onScan], o botão "Ler código
/// de barras" no campo: o app abre a câmera e devolve o código (44 dígitos) ou a linha, e o campo preenche.
/// [onChanged] recebe o boleto quando a linha está completa e válida (nulo enquanto não).
class SsBoletoField extends StatefulWidget {
  const SsBoletoField({
    super.key,
    this.label,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onScan,
    this.required = false,
    this.enabled = true,
    this.today,
  });

  final String? label;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<SsBoleto?>? onChanged;

  /// A câmera do app: devolve o código lido (ou nulo se a pessoa desistiu).
  final Future<String?> Function()? onScan;
  final bool required;
  final bool enabled;

  /// Hoje (o ciclo do fator de vencimento e o "venceu"); teste e catálogo.
  final DateTime? today;

  @override
  State<SsBoletoField> createState() => _SsBoletoFieldState();
}

class _SsBoletoFieldState extends State<SsBoletoField> with _Controlado {
  @override
  TextEditingController? get externo => widget.controller;
  SsBoleto? _b;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null && widget.initialValue != null) {
      ctrl.text = SsBr.formatBoleto(widget.initialValue);
    }
    _b = _parse(ctrl.text);
  }

  @override
  void dispose() {
    descartar();
    super.dispose();
  }

  SsBoleto? _parse(String v) {
    final d = SsBr.digits(v);
    if (d.length != 47 && !(d.length == 48 && d.startsWith('8'))) return null;
    return SsBoleto.parse(d, today: widget.today);
  }

  void _changed(String v) {
    final b = _parse(v);
    setState(() => _b = b);
    widget.onChanged?.call(b != null && b.valid ? b : null);
  }

  Future<void> _scan() async {
    final code = await widget.onScan!();
    if (code == null || !mounted) return;
    var d = SsBr.digits(code);
    if (d.length == 44) d = SsBr.boletoLineFromBarcode(d) ?? d;
    ctrl.text = SsBr.formatBoleto(d);
    _changed(ctrl.text);
  }

  String? _validar(String? v, SsBrStrings br) {
    final d = SsBr.digits(v);
    if (d.isEmpty) return widget.required ? br.boletoIncomplete : null;
    final b = _parse(d);
    if (b == null) return br.boletoIncomplete;
    return b.valid ? null : br.boletoInvalid;
  }

  @override
  Widget build(BuildContext context) {
    final br = SsBrStrings.of(context);
    final s = SsStrings.of(context);
    final f = SsFormats.of(context);
    final b = _b;
    Widget? retorno;
    if (b != null && b.valid) {
      final hoje = widget.today ?? DateTime.now();
      final ref = DateTime(hoje.year, hoje.month, hoje.day);
      final venc = b.dueDate == null ? null : DateTime(b.dueDate!.year, b.dueDate!.month, b.dueDate!.day);
      final vencido = venc != null && venc.isBefore(ref);
      final partes = [
        b.amountCents == null ? br.boletoNoAmount : f.money(b.amountCents),
        if (venc != null)
          SsBrStrings.fill(vencido ? br.boletoOverdue : br.boletoDue, {'date': s.formatDate(venc)})
        else if (b.kind == SsBoletoKind.bank)
          br.boletoNoDue,
      ];
      retorno = _Retorno(
        badge: b.kind == SsBoletoKind.bank ? br.boletoBank : br.boletoCollection,
        text: partes.join(' · '),
        tone: vencido ? SsTone.warning : SsTone.success,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SsTextField(
          label: widget.label ?? br.boleto,
          controller: ctrl,
          hint: br.boletoHint,
          icon: Icons.receipt_long_outlined,
          enabled: widget.enabled,
          keyboardType: TextInputType.number,
          inputFormatters: const [SsBoletoMask()],
          style: AppTheme.number(
            context,
            size: SsDensity.of(context).font(AppType.sub),
            color: SsColors.of(context).ink,
          ),
          maxLines: 2,
          minLines: 1,
          onChanged: _changed,
          validator: (v) => _validar(v, br),
          suffix: widget.onScan == null
              ? null
              : SsIconButton(
                  icon: Icons.qr_code_scanner_rounded,
                  tooltip: br.boletoScan,
                  onPressed: widget.enabled ? _scan : null,
                ),
        ),
        ?retorno,
      ],
    );
  }
}

// ── CEP ───────────────────────────────────────────────────────────────

/// O endereço que o `onLookup` do [SsCepField] devolve.
class SsAddress {
  const SsAddress({this.street, this.district, this.city, this.state, this.complement});

  /// Logradouro.
  final String? street;

  /// Bairro.
  final String? district;
  final String? city;

  /// UF ("SP").
  final String? state;
  final String? complement;
}

/// Campo de CEP: máscara 00000-000 e, com os 8 dígitos, o [onLookup] do app (o endpoint dele; o pacote não chama
/// serviço externo). Achou: preenche os controladores ligados ([street], [district], [city], [state]) e chama
/// [onAddress]. Não achou ou falhou: diz embaixo e deixa preencher à mão. Resposta velha não passa por cima da
/// nova (digitou outro CEP no meio).
class SsCepField extends StatefulWidget {
  const SsCepField({
    super.key,
    this.label,
    this.controller,
    this.initialValue,
    this.onLookup,
    this.onAddress,
    this.street,
    this.district,
    this.city,
    this.state,
    this.required = false,
    this.enabled = true,
    this.autoLookup = false,
  });

  final String? label;
  final TextEditingController? controller;
  final String? initialValue;

  /// Busca já ao abrir quando o campo vem preenchido (falso: só quando a pessoa digita, para não trocar o
  /// endereço que ela já ajustou).
  final bool autoLookup;

  /// CEP (8 dígitos) → endereço; nulo = não achou; erro = falhou.
  final Future<SsAddress?> Function(String cep)? onLookup;
  final ValueChanged<SsAddress>? onAddress;
  final TextEditingController? street;
  final TextEditingController? district;
  final TextEditingController? city;
  final TextEditingController? state;
  final bool required;
  final bool enabled;

  @override
  State<SsCepField> createState() => _SsCepFieldState();
}

enum _Busca { nada, buscando, achou, naoAchou, erro }

class _SsCepFieldState extends State<SsCepField> with _Controlado {
  @override
  TextEditingController? get externo => widget.controller;
  var _busca = _Busca.nada;
  var _seq = 0;
  String? _ultimo;
  SsAddress? _endereco;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null && widget.initialValue != null) ctrl.text = SsBr.formatCep(widget.initialValue);
    if (widget.autoLookup && ctrl.text.isNotEmpty) scheduleMicrotask(() => _changed(ctrl.text));
  }

  @override
  void dispose() {
    descartar();
    super.dispose();
  }

  Future<void> _changed(String v) async {
    final d = SsBr.digits(v);
    if (d.length != 8 || !SsBr.cepValid(d)) {
      if (_busca != _Busca.nada) setState(() => _busca = _Busca.nada);
      _ultimo = null;
      return;
    }
    if (d == _ultimo || widget.onLookup == null) return;
    _ultimo = d;
    final eu = ++_seq;
    setState(() => _busca = _Busca.buscando);
    try {
      final a = await widget.onLookup!(d);
      if (!mounted || eu != _seq) return;
      if (a == null) {
        setState(() => _busca = _Busca.naoAchou);
        return;
      }
      void put(TextEditingController? c, String? v) {
        if (c != null && v != null && v.isNotEmpty) c.text = v;
      }

      put(widget.street, a.street);
      put(widget.district, a.district);
      put(widget.city, a.city);
      put(widget.state, a.state);
      setState(() {
        _busca = _Busca.achou;
        _endereco = a;
      });
      widget.onAddress?.call(a);
    } catch (_) {
      if (mounted && eu == _seq) setState(() => _busca = _Busca.erro);
    }
  }

  @override
  Widget build(BuildContext context) {
    final br = SsBrStrings.of(context);
    final a = _endereco;
    final retorno = switch (_busca) {
      _Busca.nada => null,
      _Busca.buscando => _Retorno(text: br.cepLooking, icon: Icons.search_rounded),
      _Busca.achou => _Retorno(
        text: [
          a?.street,
          a?.district,
          [a?.city, a?.state].whereType<String>().where((s) => s.isNotEmpty).join('/'),
        ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
        icon: Icons.place_outlined,
        tone: SsTone.success,
      ),
      _Busca.naoAchou => _Retorno(text: br.cepNotFound, icon: Icons.info_outline_rounded, tone: SsTone.warning),
      _Busca.erro => _Retorno(text: br.cepError, icon: Icons.cloud_off_rounded, tone: SsTone.warning),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SsTextField(
          label: widget.label ?? br.cep,
          controller: ctrl,
          hint: '00000-000',
          mask: SsMask.cep,
          enabled: widget.enabled,
          autofillHints: const [AutofillHints.postalCode],
          onChanged: _changed,
          suffix: _busca == _Busca.buscando
              ? Padding(
                  padding: const EdgeInsets.all(14),
                  child: SsSpinner(size: 18, semanticsLabel: br.cepLooking),
                )
              : null,
          validator: (v) {
            final d = SsBr.digits(v);
            if (d.isEmpty) return widget.required ? br.cepInvalid : null;
            return SsBr.cepValid(d) ? null : br.cepInvalid;
          },
        ),
        ?retorno,
      ],
    );
  }
}

// ── CPF ou CNPJ ───────────────────────────────────────────────────────

/// Qual documento o [SsDocumentField] aceita.
enum SsDocumentKind { any, cpf, cnpj }

/// Campo de CPF ou CNPJ: a máscara do `SsMask.document` (o CNPJ alfanumérico de 2026 também), a detecção do tipo,
/// os dígitos verificadores e, com [onLookup] (CNPJ → razão social, o endpoint do app), a razão social embaixo.
/// [onChanged] recebe o documento só com os caracteres que contam e o tipo ("cpf"/"cnpj") quando válido.
class SsDocumentField extends StatefulWidget {
  const SsDocumentField({
    super.key,
    this.label,
    this.controller,
    this.initialValue,
    this.kind = SsDocumentKind.any,
    this.onChanged,
    this.onLookup,
    this.required = false,
    this.enabled = true,
  });

  final String? label;
  final TextEditingController? controller;
  final String? initialValue;
  final SsDocumentKind kind;
  final void Function(String? document, String? kind)? onChanged;

  /// CNPJ (14) → razão social; nulo = não achou.
  final Future<String?> Function(String cnpj)? onLookup;
  final bool required;
  final bool enabled;

  @override
  State<SsDocumentField> createState() => _SsDocumentFieldState();
}

class _SsDocumentFieldState extends State<SsDocumentField> with _Controlado {
  @override
  TextEditingController? get externo => widget.controller;
  String? _razao;
  var _busca = _Busca.nada;
  var _seq = 0;
  String? _ultimo;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null && widget.initialValue != null) {
      ctrl.text = SsMask.document.format(widget.initialValue!);
    }
    if (ctrl.text.isNotEmpty) scheduleMicrotask(() => _changed(ctrl.text, notify: false));
  }

  @override
  void dispose() {
    descartar();
    super.dispose();
  }

  bool _aceita(String? kind) => kind != null && (widget.kind == SsDocumentKind.any || widget.kind.name == kind);

  Future<void> _changed(String v, {bool notify = true}) async {
    final raw = SsBr.alnum(v);
    final kind = SsBr.documentKind(raw);
    final ok = _aceita(kind) && SsBr.documentValid(raw);
    if (notify) widget.onChanged?.call(ok ? raw : null, ok ? kind : null);
    if (!ok || kind != 'cnpj' || widget.onLookup == null) {
      if (_busca != _Busca.nada || _razao != null) {
        setState(() {
          _busca = _Busca.nada;
          _razao = null;
        });
      }
      _ultimo = null;
      return;
    }
    if (raw == _ultimo) return;
    _ultimo = raw;
    final eu = ++_seq;
    setState(() => _busca = _Busca.buscando);
    try {
      final r = await widget.onLookup!(raw);
      if (!mounted || eu != _seq) return;
      setState(() {
        _razao = r;
        _busca = r == null ? _Busca.naoAchou : _Busca.achou;
      });
    } catch (_) {
      if (mounted && eu == _seq) setState(() => _busca = _Busca.erro);
    }
  }

  @override
  Widget build(BuildContext context) {
    final br = SsBrStrings.of(context);
    final label =
        widget.label ??
        switch (widget.kind) {
          SsDocumentKind.cpf => 'CPF',
          SsDocumentKind.cnpj => 'CNPJ',
          SsDocumentKind.any => br.document,
        };
    final retorno = switch (_busca) {
      _Busca.buscando => _Retorno(text: br.documentLooking, icon: Icons.search_rounded),
      _Busca.achou => _Retorno(text: _razao!, icon: Icons.business_outlined, tone: SsTone.success),
      _Busca.naoAchou => _Retorno(text: br.documentNotFound, icon: Icons.info_outline_rounded, tone: SsTone.warning),
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SsTextField(
          label: label,
          controller: ctrl,
          mask: SsMask.document,
          enabled: widget.enabled,
          // O CNPJ alfanumérico tem letra: teclado de texto quando aceita CNPJ.
          keyboardType: widget.kind == SsDocumentKind.cpf ? TextInputType.number : TextInputType.visiblePassword,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: _changed,
          validator: (v) {
            final raw = SsBr.alnum(v);
            if (raw.isEmpty) {
              return widget.required ? (widget.kind == SsDocumentKind.cnpj ? br.cnpjInvalid : br.cpfInvalid) : null;
            }
            final kind = SsBr.documentKind(raw);
            if (widget.kind == SsDocumentKind.cpf && kind != 'cpf') return br.cpfInvalid;
            if (widget.kind == SsDocumentKind.cnpj && kind != 'cnpj') return br.cnpjInvalid;
            if (SsBr.documentValid(raw)) return null;
            return kind == 'cnpj' ? br.cnpjInvalid : br.cpfInvalid;
          },
        ),
        ?retorno,
      ],
    );
  }
}
