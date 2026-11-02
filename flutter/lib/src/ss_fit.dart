import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Valor (dinheiro, número, data curta) que nunca quebra linha: encolhe para
/// caber na largura que sobrou, em vez de virar "R$ 1.2" + "34,00".
///
/// `SsFit(Text(money(total)), alignment: Alignment.centerLeft)`
class SsFit extends StatelessWidget {
  const SsFit(this.child, {super.key, this.alignment = Alignment.centerRight});

  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) => FittedBox(fit: BoxFit.scaleDown, alignment: alignment, child: child);
}

/// Título de AppBar que não corta: curto (até 22 letras) encolhe para caber
/// numa linha; longo (nome de viagem, de produto) vai menor em até 2 linhas.
/// Anunciado como cabeçalho pelo leitor de tela.
///
/// `AppBar(title: SsFitTitle(viagem.nome))`
class SsFitTitle extends StatelessWidget {
  const SsFitTitle(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: text.length <= 22
        ? SsFit(Text(text, maxLines: 1, style: style), alignment: Alignment.centerLeft)
        : Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: (style ?? DefaultTextStyle.of(context).style).copyWith(fontSize: AppType.lg, height: 1.15),
          ),
  );
}

/// Dois botões lado a lado, divididos ao meio; com fonte grande (> 1,15×)
/// um embaixo do outro, para o rótulo não virar "Verificar ag…".
///
/// `SsButtonPair(first: SsButton(...), second: SsButton(...))`
class SsButtonPair extends StatelessWidget {
  const SsButtonPair({super.key, required this.first, required this.second, this.gap = 8});

  final Widget first;
  final Widget second;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.textScalerOf(context).scale(10) > 11.5) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          first,
          SizedBox(height: gap),
          second,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: first),
        SizedBox(width: gap),
        Expanded(child: second),
      ],
    );
  }
}
