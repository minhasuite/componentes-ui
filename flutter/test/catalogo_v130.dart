// v1.3: a seção de Aparência (tema, preto total, cores e densidade) e a alça do menu na borda.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'catalogo.dart';

SsAppearanceController _c(SsAppearance v) =>
    SsAppearanceController(brand: SsBrand.ambar, read: () async => null, write: (_) async {}, initial: v);

Widget _painel(SsAppearance v) => SingleChildScrollView(
  padding: const EdgeInsets.all(16),
  child: SsAppearancePanel(controller: _c(v)),
);

final List<Componente> _novos = [
  Componente(
    'ss-appearance-panel',
    'SsAppearancePanel + SsAppearanceController',
    'Aparência escolhida pela pessoa, igual em todos os apps (v1.3): tema, preto total, cores e densidade.',
    comportamentos: [
      'Tema: Claro, Escuro ou do sistema (SsSegmented). O preto total (OLED) só aparece quando o escuro pode valer.',
      'Cores: a 1ª ficha é a cor do app (a marca do produto, o padrão); depois as paletas da suíte, agrupadas.',
      'Densidade: compacta, padrão ou confortável.',
      'O SsAppearanceController guarda num texto (o app diz onde: read/write) e monta os temas em cache por combinação; o MaterialApp ouve o controlador.',
      'No web, o par é o Ss::ThemeSwitcherComponent com ss_theme_head no <head> (aplica antes da 1ª pintura).',
    ],
    estados: [
      Estado(
        'padrao',
        'cor do app, tema do sistema',
        (_) => _painel(const SsAppearance()),
        tamanho: const Size(390, 520),
      ),
      Estado(
        'escuro-paleta',
        'escuro com preto total e outra paleta',
        (_) => _painel(const SsAppearance(themeMode: ThemeMode.dark, oled: true, paleta: 'eucalipto')),
        tamanho: const Size(390, 520),
      ),
    ],
  ),
];

List<Componente> comV130(List<Componente> base) => [...base, ..._novos];
