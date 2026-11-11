// v0.21 (pedido do minha-automacao, "beleza" dos painéis): micro-animações
// padronizadas ([catalogoV21]: ss-cue) e o brilho real no tile ([comV21]).
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';

import 'catalogo.dart';

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

/// Liga [active] depois de montar, para a captura pegar o aceno no meio.
class _Acena extends StatefulWidget {
  const _Acena(this.kind, this.child, {this.color});
  final SsCueKind kind;
  final Widget child;
  final Color? color;

  @override
  State<_Acena> createState() => _AcenaState();
}

class _AcenaState extends State<_Acena> {
  bool _on = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _on = true);
    });
  }

  @override
  Widget build(BuildContext context) => SsCue(kind: widget.kind, active: _on, color: widget.color, child: widget.child);
}

final catalogoV21 = <Componente>[
  Componente(
    'ss-cue',
    'SsCue',
    'Micro-animação de mudança de estado da casa: ligou, abriu, alguém chegou. Par do ss-cue do web (mesmos tipos e tempo).',
    comportamentos: [
      'Toca uma vez quando active vira verdadeiro (620 ms); nada na primeira pintura nem ao desligar.',
      'on: pulo .94 → 1 pela mola e halo na cor (color:, a cor real da lâmpada) que cresce e some.',
      'open: o filho gira até ~28° pela borda esquerda, como uma porta, e volta.',
      'arrive: sobe 8 px e aparece com a mola (pessoa que chegou).',
      'Não muda o layout (só transforma e pinta por cima). "Remover animações" desliga tudo.',
    ],
    estados: [
      Estado(
        'ligou',
        'ligou (no meio do aceno)',
        (_) => _pad(
          const _Acena(
            SsCueKind.on,
            SsDeviceTile(icon: Icons.lightbulb_outline_rounded, name: 'Luz da sala', state: 'Ligada · 80%', on: true),
            color: AppColors.aquecFg,
          ),
        ),
        tamanho: const Size(360, 110),
        aguarde: 180,
      ),
      Estado(
        'abriu',
        'abriu (porta)',
        (_) => _pad(const _Acena(SsCueKind.open, SsIconTile(Icons.door_front_door_outlined))),
        tamanho: const Size(160, 110),
        aguarde: 200,
      ),
      Estado(
        'chegou',
        'chegou alguém',
        (_) => _pad(const _Acena(SsCueKind.arrive, SsAvatar('Ana Souza'))),
        tamanho: const Size(160, 110),
        aguarde: 120,
      ),
    ],
  ),
];

final _v21 = <String, (List<String>, List<Estado>)>{
  'ss-device-tile': (
    ['level: brilho real (0 a 1, o dimmer da lâmpada): a tinta e o halo de ligado acompanham (35% a 100%).'],
    [
      Estado(
        'brilho',
        'brilho real: 15% e 100% na cor da lâmpada',
        (_) => _pad(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SsDeviceTile(
                icon: Icons.lightbulb_outline_rounded,
                name: 'Abajur',
                state: 'Ligado · 15%',
                on: true,
                level: .15,
                color: ssColorFromRgb(0xFFAA5A),
              ),
              const SizedBox(height: 12),
              SsDeviceTile(
                icon: Icons.lightbulb_outline_rounded,
                name: 'Fita de LED',
                state: 'Ligada · 100%',
                on: true,
                level: 1,
                color: ssColorFromRgb(0x5078FF),
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 200),
      ),
    ],
  ),
};

List<Componente> comV21(List<Componente> base) => [
  for (final c in base)
    if (_v21[c.slug] case (final comp, final est))
      Componente(
        c.slug,
        c.nome,
        c.descricao,
        comportamentos: [...c.comportamentos, ...comp],
        estados: [...c.estados, ...est],
      )
    else
      c,
];
