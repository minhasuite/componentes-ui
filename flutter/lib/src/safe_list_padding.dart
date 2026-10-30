import 'package:flutter/material.dart';

/// Padding de lista que respeita a barra de navegação do sistema.
///
/// Existe porque `EdgeInsets.all(16)` numa lista rolável esconde o último item
/// atrás da navegação do Android: com os 3 botões, a barra come ~48px, e o que
/// fica embaixo dela é justamente o botão de ação do último card. Foi visto na
/// tela de calistenia — o "Começar" da última rotina ficava inalcançável.
///
/// Telas de aba não sofrem (a `bottomNavigationBar` já reserva o espaço); quem
/// sofre é tela empurrada, que vai até a borda de baixo.
///
/// Usa `viewPadding` e não `padding`: `padding` zera quando o teclado abre, e
/// aí a lista encolheria o respiro justamente enquanto alguém digita.
EdgeInsets safeListPadding(BuildContext context, {double horizontal = 16, double top = 16, double bottom = 16}) {
  final sistema = MediaQuery.viewPaddingOf(context).bottom;
  return EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom + sistema);
}
