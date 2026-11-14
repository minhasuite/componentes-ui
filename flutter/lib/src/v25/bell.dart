import 'package:flutter/material.dart';

import '../v10/tela_barra.dart';

/// v0.25 · Sino de avisos da barra de cima (par do `Ss::NotificationBellComponent` do web): o [SsIconButton]
/// com o número de não lidos no selo vermelho ("99+" acima de 99; 0 some) e o nome lido com a contagem.
/// O que abre ao tocar (folha com os últimos avisos ou a central) é do app, em [onPressed].
///
/// `SsNotificationBell(count: 3, onPressed: () => context.push('/avisos'))`
class SsNotificationBell extends StatelessWidget {
  const SsNotificationBell({super.key, required this.count, this.onPressed, this.label = 'Avisos', this.unreadLabel});

  final int count;
  final VoidCallback? onPressed;

  /// Nome do botão (dica e leitor de tela).
  final String label;

  /// Nome com a contagem ("Avisos, 3 não lidos"); padrão: "[label], [n] não lidos".
  final String Function(String n)? unreadLabel;

  static String countText(int n) => n > 99 ? '99+' : '$n';

  @override
  Widget build(BuildContext context) {
    final n = count < 0 ? 0 : count;
    final text = countText(n);
    final tip = n == 0 ? label : (unreadLabel?.call(text) ?? '$label, $text não lidos');
    return SsIconButton(
      icon: n == 0 ? Icons.notifications_none_rounded : Icons.notifications_rounded,
      tooltip: tip,
      badge: n == 0 ? null : text,
      onPressed: onPressed,
    );
  }
}
