// Entradas do catálogo das paletas: o seletor (SsPalettePicker). As paletas em
// si (SsBrand.paletas e o gradiente de 4 paradas) estão em catalogo_v09_a.dart.
import 'package:flutter/material.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo.dart';

/// Seletor com estado próprio; [para] troca a paleta logo depois do 1º quadro
/// (o anel aparece no meio do deslize).
class _Picker extends StatefulWidget {
  const _Picker(this.inicio, {this.para, this.nomes = true});
  final SsBrand inicio;
  final SsBrand? para;
  final bool nomes;

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  late SsBrand v = widget.inicio;

  @override
  void initState() {
    super.initState();
    if (widget.para != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => v = widget.para!);
      });
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    // O tema segue a paleta escolhida (como no app): o anel sai na cor dela.
    data: AppTheme.build(Theme.of(context).brightness, brand: v),
    child: Builder(
      builder: (context) => ColoredBox(
        color: SsColors.of(context).page,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Text(
                  'Paleta · ${SsPaleta.of(v)?.nome ?? 'própria'}',
                  style: TextStyle(color: SsColors.of(context).ink, fontWeight: FontWeight.w800),
                ),
              ),
              SsPalettePicker(value: v, showNames: widget.nomes, onChanged: (p) => setState(() => v = p.brand)),
            ],
          ),
        ),
      ),
    ),
  );
}

final catalogoPaletas = <Componente>[
  Componente(
    'ss-palette-picker',
    'SsPalettePicker',
    'Seletor de paleta: faixa rolável de fichas redondas com o gradiente de 4 paradas de cada uma das '
        '${SsPaleta.todas.length} paletas (SsPaleta.todas, as mesmas do Rails, geradas de paletas/paletas.json). '
        'É a parte de paleta do Ss::ThemeSwitcherComponent.',
    comportamentos: [
      'A marcada ganha um anel na cor da marca que desliza de uma ficha a outra com a mola (SsSlidingIndicator).',
      'Nome embaixo de cada ficha (a marcada em negrito, na cor da marca); showNames: false deixa só o tooltip.',
      'Abre com a marcada à vista e rola até ela quando a marca muda por fora.',
      'Toque vibra (tick) e chama onChanged com a SsPaleta (slug, nome, família e brand).',
      'Leitor de tela: cada ficha é um botão com o nome e o estado selecionado.',
    ],
    estados: [
      Estado('padrao', 'violeta marcada', (_) => const _Picker(SsBrand.violeta), tamanho: const Size(360, 132)),
      Estado(
        'rolada',
        'marcada no fim da faixa (rola até ela)',
        (_) => _Picker(SsPaleta.todas.last.brand),
        tamanho: const Size(360, 132),
      ),
      Estado(
        'deslizando',
        'anel no meio do deslize',
        (_) => const _Picker(SsBrand.violeta, para: SsBrand.safira),
        tamanho: const Size(360, 132),
        aguarde: 120,
      ),
      Estado(
        'sem-nomes',
        'showNames: false',
        (_) => const _Picker(SsBrand.eucalipto, nomes: false),
        tamanho: const Size(360, 112),
      ),
    ],
  ),
];
