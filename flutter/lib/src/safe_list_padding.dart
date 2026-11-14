import 'package:flutter/material.dart';

import 'v10/tela.dart' show SsFab;

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
///
/// v0.24 (auditoria de UX, U08/U12): `fab: true` soma o espaço do botão
/// flutuante ([SsFab.clearance]): o fim da lista sobe acima dele, e o último
/// item (o botão "Registrar chegada", a legenda) não fica por baixo.
EdgeInsets safeListPadding(
  BuildContext context, {
  double horizontal = 16,
  double top = 16,
  double bottom = 16,
  bool fab = false,
}) {
  final sistema = MediaQuery.viewPaddingOf(context).bottom;
  final botao = fab ? SsFab.clearance(context) : 0.0;
  return EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom + sistema + botao);
}
