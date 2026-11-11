// v0.20: o que o minhas-vendas e o meu-gestor acharam ao migrar para 100% de
// componentização: máscara brasileira no campo, barra fixa com resumo e linhas
// repetíveis de formulário (pares do ss-mask, do StickyActionBarComponent com
// summary e do RepeaterComponent do web).
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../ss_button.dart';
import '../ss_strings.dart';
import '../v10/tela_barra.dart' show SsIconButton;

enum _SsMaskKind { document, phone, cep }

/// Máscara brasileira enquanto digita (o `ss-mask` do web, mesma conta):
///
/// - [SsMask.document]: CPF `000.000.000-00` até 11 caracteres; com 12 ou
///   mais, ou com letra, CNPJ `00.000.000/0000-00` (o CNPJ alfanumérico de
///   2026 entra: letras em maiúscula nas 12 primeiras posições).
/// - [SsMask.phone]: `(00) 0000-0000` ou, com 11 dígitos, `(00) 00000-0000`.
/// - [SsMask.cep]: `00000-000`.
///
/// Use no `SsTextField(mask: SsMask.document)` (põe o teclado numérico) ou em
/// qualquer `inputFormatters:`. [SsMask.format] formata um texto pronto (para
/// mostrar) e [SsMask.unmask] tira a pontuação (para mandar à API).
class SsMask extends TextInputFormatter {
  const SsMask._(this._kind);

  final _SsMaskKind _kind;

  static const document = SsMask._(_SsMaskKind.document);
  static const phone = SsMask._(_SsMaskKind.phone);
  static const cep = SsMask._(_SsMaskKind.cep);

  /// Teclado sugerido (o app pode trocar pelo `keyboardType:` do campo).
  TextInputType get keyboardType => _kind == _SsMaskKind.phone ? TextInputType.phone : TextInputType.number;

  /// Tamanho máximo já formatado (18 no CNPJ, 15 no telefone, 9 no CEP).
  int get maxLength => switch (_kind) {
    _SsMaskKind.document => 18,
    _SsMaskKind.phone => 15,
    _SsMaskKind.cep => 9,
  };

  bool _significant(String ch) =>
      _kind == _SsMaskKind.document ? RegExp(r'[0-9A-Za-z]').hasMatch(ch) : RegExp(r'\d').hasMatch(ch);

  /// Só os caracteres que contam ("123.456.789-01" → "12345678901").
  String unmask(String text) {
    final b = StringBuffer();
    for (final ch in text.split('')) {
      if (_significant(ch)) b.write(ch.toUpperCase());
    }
    return b.toString();
  }

  /// O texto formatado (parcial enquanto incompleto: "1234" → "123.4").
  String format(String text) {
    var raw = unmask(text);
    switch (_kind) {
      case _SsMaskKind.cep:
        raw = _cap(raw, 8);
        return _join(raw, const [5], const ['-']);
      case _SsMaskKind.phone:
        raw = _cap(raw, 11);
        if (raw.isEmpty) return '';
        if (raw.length <= 2) return '($raw';
        final rest = raw.substring(2);
        final cut = raw.length <= 10 ? 4 : 5;
        return '(${raw.substring(0, 2)}) ${_join(rest, [cut], const ['-'])}';
      case _SsMaskKind.document:
        final cnpj = raw.length > 11 || RegExp('[A-Z]').hasMatch(raw);
        if (!cnpj) return _join(raw, const [3, 6, 9], const ['.', '.', '-']);
        // CNPJ: 12 primeiros alfanuméricos, 2 últimos dígitos.
        raw = _cap(raw, 14);
        if (raw.length > 12) {
          raw = raw.substring(0, 12) + raw.substring(12).replaceAll(RegExp(r'\D'), '');
        }
        return _join(raw, const [2, 5, 8, 12], const ['.', '.', '/', '-']);
    }
  }

  static String _cap(String s, int n) => s.length > n ? s.substring(0, n) : s;

  static String _join(String raw, List<int> cuts, List<String> seps) {
    final b = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final k = cuts.indexOf(i);
      if (k >= 0) b.write(seps[k]);
      b.write(raw[i]);
    }
    return b.toString();
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final out = format(newValue.text);
    // O cursor fica depois do mesmo número de caracteres que contam.
    final end = newValue.selection.end.clamp(0, newValue.text.length);
    final antes = unmask(newValue.text.substring(0, end)).length;
    var pos = 0;
    var n = 0;
    while (pos < out.length && n < antes) {
      if (_significant(out[pos])) n++;
      pos++;
    }
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: pos),
    );
  }
}

/// Barra fixa de ações embaixo da tela (par do `Ss::StickyActionBarComponent`):
/// à esquerda o [summary] (conteúdo livre: "3 itens · R$ 120,00") ou a
/// [message]; à direita as [actions] (botões). Com [visible] falso ela desce e
/// some (formulário sem alteração). Vai no `bottomNavigationBar:` do
/// `Scaffold` ou no fim de uma `Column`; respeita a área segura.
///
/// `SsStickyActionBar(summary: SsAmount(total), actions: [SsButton(label: 'Fechar pedido', expand: false, onPressed: ...)])`
class SsStickyActionBar extends StatelessWidget {
  const SsStickyActionBar({super.key, this.summary, this.message, this.actions = const [], this.visible = true});

  /// Conteúdo livre à esquerda (resumo, total, contagem).
  final Widget? summary;

  /// Texto à esquerda quando não há [summary] ("Alterações não salvas").
  final String? message;
  final List<Widget> actions;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final dur = reduceMotion(context) ? Duration.zero : SsMotion.base;
    final esquerda =
        summary ??
        (message == null
            ? null
            : Text(
                message!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: c.ink2, fontSize: d.font(AppType.sub), fontWeight: FontWeight.w700),
              ));
    final barra = Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.line)),
        boxShadow: c.isDark ? null : AppShadows.card,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: d.padX, vertical: d.gap),
          child: Row(
            children: [
              if (esquerda != null)
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: DefaultTextStyle.merge(
                      style: TextStyle(color: c.ink, fontSize: d.font(AppType.body), fontWeight: FontWeight.w700),
                      child: esquerda,
                    ),
                  ),
                )
              else
                const Spacer(),
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0 || esquerda != null) SizedBox(width: d.gap - 4),
                actions[i],
              ],
            ],
          ),
        ),
      ),
    );
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 1),
      duration: dur,
      curve: SsMotion.bounce,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: dur,
        child: IgnorePointer(
          ignoring: !visible,
          child: ExcludeSemantics(excluding: !visible, child: barra),
        ),
      ),
    );
  }
}

/// Linhas repetíveis de formulário (itens do pedido, telefones, parcelas): uma
/// linha por item com o × de tirar à direita e "Adicionar" embaixo. Par do
/// `Ss::RepeaterComponent` + `ss-repeater` do web. O estado (a lista) é do app:
/// [onAdd] acrescenta e [onRemove] tira pelo índice; o widget só desenha.
/// [minItems] esconde o × quando sobrar só esse tanto.
///
/// `SsRepeater(itemCount: itens.length, itemBuilder: (ctx, i) => ItemForm(itens[i]), onAdd: () => setState(() => itens.add(Item())), onRemove: (i) => setState(() => itens.removeAt(i)))`
///
/// v0.20.3: [header] põe o cabeçalho uma vez em cima ("PRODUTO", "QTD"…), com
/// a mesma largura das linhas (o × tem a sua coluna); [flex] divide a largura
/// das células do cabeçalho (padrão: 1 cada) e [SsRepeater.cells] monta a linha
/// com os mesmos flex. Com [header] o × fica no meio da linha. Os campos da
/// linha usam `SsTextField(label: 'Qtd', hideLabel: true)` (o rótulo continua
/// para o leitor de tela). Par do `RepeaterComponent(header:, columns:)`.
class SsRepeater extends StatelessWidget {
  const SsRepeater({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.onAdd,
    this.onRemove,
    this.addLabel,
    this.removeLabel,
    this.minItems = 0,
    this.spacing,
    this.header,
    this.flex,
  });

  /// v0.20.3: cabeçalho único (texto de cada coluna; vazio = célula vazia).
  final List<String>? header;

  /// v0.20.3: flex de cada coluna do [header] (o mesmo que a linha usa).
  final List<int>? flex;

  /// v0.20.3: a linha com as colunas no mesmo [flex] do cabeçalho:
  /// `itemBuilder: (ctx, i) => SsRepeater.cells([produto, qtd, total], flex: const [4, 1, 2])`.
  static Widget cells(List<Widget> children, {List<int>? flex, double? spacing}) => Builder(
    builder: (context) {
      final gap = spacing ?? SsDensity.of(context).gap - 4;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: gap,
        children: [
          for (var i = 0; i < children.length; i++)
            Expanded(flex: flex != null && i < flex.length ? flex[i] : 1, child: children[i]),
        ],
      );
    },
  );

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final VoidCallback? onAdd;
  final ValueChanged<int>? onRemove;

  /// Padrão: [SsStrings.addRow] ("Adicionar").
  final String? addLabel;

  /// Padrão: [SsStrings.removeRow] ("Remover linha").
  final String? removeLabel;
  final int minItems;

  /// Espaço entre as linhas (padrão: o respiro da densidade).
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    final gap = spacing ?? d.gap;
    final c = SsColors.of(context);
    final tira = onRemove != null && itemCount > minItems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (header != null)
          ExcludeSemantics(
            child: Container(
              margin: EdgeInsets.only(bottom: gap),
              padding: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.line)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SsRepeater.cells([
                      for (final h in header!)
                        Text(
                          h.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.muted,
                            fontSize: d.font(AppType.label),
                            fontWeight: FontWeight.w800,
                            letterSpacing: AppType.trackingTight,
                          ),
                        ),
                    ], flex: flex),
                  ),
                  // A coluna do × (do mesmo tamanho do botão, invisível).
                  if (tira)
                    IgnorePointer(
                      child: Opacity(
                        opacity: 0,
                        child: SsIconButton(
                          icon: Icons.close_rounded,
                          tooltip: removeLabel ?? SsStrings.of(context).removeRow,
                          onPressed: () {},
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        for (var i = 0; i < itemCount; i++)
          Padding(
            padding: EdgeInsets.only(bottom: gap),
            child: Row(
              crossAxisAlignment: header != null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                Expanded(child: itemBuilder(context, i)),
                if (tira)
                  SsIconButton(
                    icon: Icons.close_rounded,
                    tooltip: '${removeLabel ?? s.removeRow} ${i + 1}',
                    onPressed: () => onRemove!(i),
                  ),
              ],
            ),
          ),
        if (onAdd != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SsButton.text(label: addLabel ?? s.addRow, icon: Icons.add_rounded, onPressed: onAdd),
          ),
      ],
    );
  }
}

/// Um link no meio do texto do [SsLinkText] (par do `a.ss-link` /
/// `Ss::TextLinkComponent` do web). [external] avisa o leitor de tela que sai
/// do app (o app abre a URL no [onTap]).
@immutable
class SsTextLink {
  const SsTextLink(this.text, {required this.onTap, this.external = false});

  final String text;
  final VoidCallback onTap;
  final bool external;
}

/// Parágrafo com links no meio ("Ao criar a conta você concorda com os
/// termos e a privacidade"): [children] mistura `String` e [SsTextLink]. O
/// link é texto de verdade (quebra junto da linha), na cor da marca em 700,
/// tocável e lido como link; os reconhecedores de toque são do widget (nada
/// para o app descartar).
///
/// `SsLinkText(['Li e aceito os ', SsTextLink('termos', onTap: abrirTermos), '.'])`
class SsLinkText extends StatefulWidget {
  const SsLinkText(this.children, {super.key, this.style, this.textAlign});

  final List<Object> children;

  /// Estilo do texto comum (padrão: 12/500 no `muted`).
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  State<SsLinkText> createState() => _SsLinkTextState();
}

class _SsLinkTextState extends State<SsLinkText> {
  final _recs = <TapGestureRecognizer>[];

  void _limpa() {
    for (final r in _recs) {
      r.dispose();
    }
    _recs.clear();
  }

  @override
  void dispose() {
    _limpa();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    _limpa();
    final base = widget.style ?? TextStyle(color: c.muted, fontSize: d.font(AppType.meta), fontWeight: FontWeight.w500);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          for (final p in widget.children)
            if (p is SsTextLink)
              TextSpan(
                text: p.text,
                semanticsLabel: p.external ? '${p.text} (${s.opensExternal})' : null,
                style: TextStyle(color: c.accentText, fontWeight: FontWeight.w700),
                recognizer: (TapGestureRecognizer()..onTap = p.onTap).also(_recs.add),
              )
            else
              TextSpan(text: '$p'),
        ],
      ),
      textAlign: widget.textAlign,
    );
  }
}

extension on TapGestureRecognizer {
  TapGestureRecognizer also(void Function(TapGestureRecognizer) f) {
    f(this);
    return this;
  }
}

/// "Ao continuar, você concorda com os Termos de uso e a Política de
/// privacidade." com os dois links (pt/en/es pelo [SsStrings]); par do
/// `Ss::TermsNoticeComponent`. O app abre a URL em [onOpen] (o pacote não
/// depende do url_launcher). [text] troca a frase: use `{terms}` e `{privacy}`
/// onde entram os links ("Ao criar a conta você concorda com os {terms}…").
class SsTermsNotice extends StatelessWidget {
  const SsTermsNotice({
    super.key,
    required this.termsUrl,
    required this.privacyUrl,
    required this.onOpen,
    this.text,
    this.textAlign = TextAlign.center,
  });

  final String termsUrl;
  final String privacyUrl;
  final ValueChanged<String> onOpen;
  final String? text;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final s = SsStrings.of(context);
    final partes = <Object>[];
    final re = RegExp(r'\{(terms|privacy)\}');
    final frase = text ?? s.termsNotice;
    var i = 0;
    for (final m in re.allMatches(frase)) {
      if (m.start > i) partes.add(frase.substring(i, m.start));
      partes.add(
        m.group(1) == 'terms'
            ? SsTextLink(s.termsOfUse, external: true, onTap: () => onOpen(termsUrl))
            : SsTextLink(s.privacyPolicy, external: true, onTap: () => onOpen(privacyUrl)),
      );
      i = m.end;
    }
    if (i < frase.length) partes.add(frase.substring(i));
    return SsLinkText(partes, textAlign: textAlign);
  }
}

/// Valor que se edita ao toque (preço novo, meta, limite): o [label] pequeno
/// em cima, o [value] (em DM Mono com [mono]) e "editar" na cor da marca
/// embaixo; o toque chama [onEdit] (o app abre o diálogo/folha). Par do
/// `Ss::EditableValueComponent`. Lido como "Preço novo: R$ 12,90, editar".
///
/// `SsEditableValue(label: 'novo', value: money(preco), onEdit: () => editarPreco(item))`
class SsEditableValue extends StatelessWidget {
  const SsEditableValue({
    super.key,
    required this.value,
    this.label,
    this.onEdit,
    this.mono = true,
    this.editLabel,
    this.alignment = CrossAxisAlignment.end,
  });

  final String value;
  final String? label;
  final VoidCallback? onEdit;
  final bool mono;

  /// Padrão: [SsStrings.editValue] ("Editar").
  final String? editLabel;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final edit = editLabel ?? SsStrings.of(context).editValue;
    final valor = mono
        ? AppTheme.number(context, size: d.font(AppType.md), color: c.ink)
        : TextStyle(color: c.ink, fontSize: d.font(AppType.md), fontWeight: FontWeight.w800);
    return Semantics(
      button: true,
      enabled: onEdit != null,
      label: '${label == null ? '' : '$label: '}$value, $edit',
      excludeSemantics: true,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(d.radiusField),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: d.minTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: alignment,
              children: [
                if (label != null)
                  Text(
                    label!,
                    style: TextStyle(color: c.muted, fontSize: d.font(AppType.micro)),
                  ),
                Text(value, style: valor),
                if (onEdit != null)
                  Text(
                    edit.toLowerCase(),
                    style: TextStyle(color: c.accentText, fontSize: d.font(AppType.meta), fontWeight: FontWeight.w700),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
