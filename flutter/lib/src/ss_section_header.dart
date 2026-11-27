import 'package:material_ui/material_ui.dart';

import 'app_theme.dart';
import 'density.dart';

/// Título de bloco dentro de uma tela de detalhe ("Histórico", "Diário"),
/// com uma linha de explicação e uma ação qualquer à direita (botão, "+").
/// Diferente do [SsSection] (rótulo curto em caixa alta): aqui o título é
/// frase e o [subtitle] diz por que o bloco existe. O título cede espaço e a
/// [action] nunca sai da tela em fonte grande.
///
/// `SsSectionHeader('Diário', subtitle: 'O que você notou', action: botao)`
class SsSectionHeader extends StatelessWidget {
  const SsSectionHeader(this.title, {super.key, this.subtitle, this.action, this.icon});

  final String title;
  final String? subtitle;
  final Widget? action;

  /// Ícone antes do título, na cor da marca (v0.13; o `Ss::SectionHeaderComponent`).
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: d.space(10)),
      // v1.9.2: o toque na sobra de 48 em volta da linha chega à ação (a linha é mais baixa que 48).
      child: SsTapTarget(
        minSize: Size(0, d.minTarget),
        child: Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 20, color: c.accent), SizedBox(width: d.gap - 4)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      maxLines: 2,
                      style: TextStyle(
                        color: c.ink,
                        fontSize: d.font(AppType.md),
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        maxLines: 2,
                        style: TextStyle(color: c.muted, fontSize: d.font(AppType.sub), fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
            // v1.9.2: a ação ("Ver todos", "+") com 48 de toque e no leitor de tela, sem mudar o desenho. É um
            // alvo só: para várias ações, monte cada uma com o próprio alvo (SsButton, SsIconButton) num Row.
            if (action != null) ...[
              SizedBox(width: d.gap - 4),
              SsTapTarget(semantics: !(action is Flex || action is Wrap), child: action!),
            ],
          ],
        ),
      ),
    );
  }
}
