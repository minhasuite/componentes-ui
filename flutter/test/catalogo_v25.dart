// v0.25: rodada 5 da auditoria de UX (meu-gestor-app e minhas-vendas). O que mudou nas peças existentes ([comV25]).
import 'package:componentes_ui/componentes_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'catalogo.dart';

const _abas = [
  SsNavItem(Icons.today_outlined, 'Hoje', activeIcon: Icons.today),
  SsNavItem(Icons.view_kanban_outlined, 'Cards', badge: 3),
  SsNavItem(Icons.checklist_rounded, 'Checklist'),
  SsNavItem(Icons.menu_rounded, 'Mais'),
];

Widget _barra(ThemeData? tema) {
  final barra = Scaffold(
    body: const SizedBox.expand(),
    bottomNavigationBar: SsNavBar(items: _abas, currentIndex: 0, onTap: (_) {}),
  );
  return tema == null ? barra : Theme(data: tema, child: barra);
}

final Map<String, (List<String>, List<Estado>)> _v25 = {
  'ss-nav-bar': (
    [
      'v0.25: todas as abas mostram o rótulo; o da aba atual fica no lugar dela, embaixo do círculo, na tinta da marca '
          '(accentText, negrito). Só o ícone dela sai da barra (está no círculo). Antes a aba atual era só o ícone.',
      'v0.25: o círculo tem anel de 2 px na SsNavBar.ringColor (inkFor(accent): 4,5:1 sobre a barra e a página em toda '
          'paleta; 7:1 no alto contraste) e, no escuro e no OLED, o miolo em field (um degrau acima da barra).',
      'v0.25: o toque está no nó de cada aba no leitor de tela ("Cards, aba 2 de 4", selecionada); antes o '
          'excludeSemantics tirava a ação de tocar.',
    ],
    [
      Estado('rotulo-ativo', 'aba atual com rótulo (v0.25)', (_) => _barra(null), tamanho: const Size(390, 160)),
      Estado(
        'oled',
        'OLED: anel e miolo elevados (v0.25)',
        (_) => _barra(AppTheme.build(Brightness.dark, oled: true)),
        tamanho: const Size(390, 160),
      ),
    ],
  ),
  'ss-collapsible': (
    ['v0.25: o título quebra em até 2 linhas (depois reticências), o mesmo do .ss-collapse-title do web.'],
    [
      Estado(
        'titulo-longo',
        'título longo no celular (v0.25)',
        (_) => const Padding(
          padding: EdgeInsets.all(16),
          child: SsCollapsible(
            title: 'Avançado: kit, margem e vencimento do lote que não vai vender a tempo',
            count: 12,
            label: '2 vencendo hoje',
            labelTone: SsTone.warning,
            child: SizedBox(),
          ),
        ),
        tamanho: const Size(390, 110),
      ),
    ],
  ),
};

List<Componente> comV25(List<Componente> base) => [
  for (final c in base)
    if (_v25[c.slug] case (final comp, final est))
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
