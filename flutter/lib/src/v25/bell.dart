import 'package:material_ui/material_ui.dart';

import '../ss_strings.dart';
import '../v10/tela_barra.dart';

/// v0.25 · Sino de avisos da barra de cima (par do `Ss::NotificationBellComponent` do web): o [SsIconButton]
/// com o número de não lidos no selo vermelho ("99+" acima de 99; 0 some) e o nome lido com a contagem.
/// O que abre ao tocar (folha com os últimos avisos ou a central) é do app, em [onPressed].
///
/// v1.9.3: o leitor de tela lê um nó só, "Notificações, 3 não lidas" (o plural de
/// [SsStrings.notifUnreadCount]: "1 não lida"; en "3 unread", es "3 no leídas"), e não mais só o número do
/// selo. O nome padrão é [SsStrings.notifications]. Com texto grande, o selo não cresce além de 1,3× e
/// "99+" cabe no alvo do botão.
///
/// `SsNotificationBell(count: 3, onPressed: () => context.push('/avisos'))`
class SsNotificationBell extends StatelessWidget {
  const SsNotificationBell({super.key, required this.count, this.onPressed, this.label, this.unreadLabel});

  final int count;
  final VoidCallback? onPressed;

  /// Nome do botão (dica e leitor de tela). Padrão: [SsStrings.notifications] ("Notificações").
  final String? label;

  /// Nome com a contagem; recebe o texto do selo ("3", "99+"). Padrão:
  /// "[label], [SsStrings.notifUnreadCount]" com o número de verdade ("Notificações, 120 não lidas").
  final String Function(String n)? unreadLabel;

  static String countText(int n) => n > 99 ? '99+' : '$n';

  /// Teto da escala de texto do selo (com 1,6× o "99+" passava da borda do botão).
  static const badgeMaxScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final s = SsStrings.of(context);
    final n = count < 0 ? 0 : count;
    final text = countText(n);
    final nome = label ?? s.notifications;
    final tip = n == 0 ? nome : (unreadLabel?.call(text) ?? '$nome, ${s.notifUnreadCount(n)}');
    return Semantics(
      container: true,
      button: true,
      enabled: onPressed != null,
      label: tip,
      onTap: onPressed,
      excludeSemantics: true,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: badgeMaxScale,
        child: SsIconButton(
          icon: n == 0 ? Icons.notifications_none_rounded : Icons.notifications_rounded,
          tooltip: tip,
          badge: n == 0 ? null : text,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
