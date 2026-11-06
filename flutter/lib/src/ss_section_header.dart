import 'package:flutter/material.dart';

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
  const SsSectionHeader(this.title, {super.key, this.subtitle, this.action});

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: d.space(10)),
      child: Row(
        children: [
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
          if (action != null) ...[SizedBox(width: d.gap - 4), action!],
        ],
      ),
    );
  }
}
