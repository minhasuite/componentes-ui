// Entradas do catálogo do movimento (lote a): indicadores que deslizam com
// mola, toque que volta com mola e interruptores/caixas. Todas são demos vivas
// (toque para trocar e ver a animação); os estados com "para" trocam o valor
// logo depois do 1º quadro, para a captura pegar o movimento no meio.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo.dart';

void _nada() {}
Widget _pad(Widget w) => Padding(
  padding: const EdgeInsets.all(16),
  child: Center(child: w),
);

const _abas4 = [
  SsNavItem(Icons.home_outlined, 'Início', activeIcon: Icons.home_rounded),
  SsNavItem(Icons.pie_chart_outline_rounded, 'Relatórios', activeIcon: Icons.pie_chart_rounded),
  SsNavItem(Icons.credit_card_outlined, 'Cartões', activeIcon: Icons.credit_card_rounded),
  SsNavItem(Icons.person_outline_rounded, 'Perfil', activeIcon: Icons.person_rounded),
];

/// Demo viva: guarda o valor e deixa o componente trocá-lo. Com [para], troca
/// sozinho logo depois do 1º quadro (ou depois de [apos], quando o componente
/// precisa de um quadro para se medir).
class _Vivo<T> extends StatefulWidget {
  const _Vivo(this.inicio, this.build, {this.para, this.apos});
  final T inicio;
  final T? para;
  final Duration? apos;
  final Widget Function(T valor, ValueChanged<T> muda) build;

  @override
  State<_Vivo<T>> createState() => _VivoState<T>();
}

class _VivoState<T> extends State<_Vivo<T>> {
  late T v = widget.inicio;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final para = widget.para;
    if (para == null) return;
    void troca() {
      if (mounted) setState(() => v = para);
    }

    if (widget.apos != null) {
      _timer = Timer(widget.apos!, troca);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => troca());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.build(v, (n) => setState(() => v = n));
}

/// Quatro vagas e o indicador puro (para ver o movimento sem componente).
Widget _vagas(int i, ValueChanged<int> muda) => Builder(
  builder: (context) {
    final c = SsColors.of(context);
    return SizedBox(
      height: 48,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
          ),
          Positioned.fill(
            child: SsSlidingIndicator(
              index: i,
              count: 4,
              padding: const EdgeInsets.all(4),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: c.tintedShadow(c.accent),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var k = 0; k < 4; k++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => muda(k),
                    child: Center(
                      child: Text(
                        '${k + 1}',
                        style: AppTheme.number(context, size: AppType.body, color: k == i ? AppColors.onDark : c.ink2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  },
);

Widget _segmented(int v, ValueChanged<int> muda) =>
    SsSegmented<int>(segments: const [(0, 'Dia'), (1, 'Semana'), (2, 'Mês')], value: v, onChanged: muda);

const _filtros = ['Todos', 'Pagos', 'Pendentes', 'Atrasados'];

Widget _chips(Set<String> marcados, ValueChanged<Set<String>> muda) => SsChipBar(
  children: [
    for (final f in _filtros)
      SsFilterChip(
        f,
        selected: marcados.contains(f),
        icon: f == 'Atrasados' ? Icons.schedule_rounded : null,
        count: f == 'Pendentes' ? 4 : null,
        onTap: () => muda(marcados.contains(f) ? ({...marcados}..remove(f)) : {...marcados, f}),
      ),
  ],
);

Widget _calendario(DateTime sel, ValueChanged<DateTime> muda) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    SsMonthSwitcher(month: sel, onChanged: (m) => muda(DateTime(m.year, m.month, 1))),
    SsMonthGrid(
      month: sel,
      selected: sel,
      today: DateTime(2026, 11, 4),
      onSelect: muda,
      onMonthChanged: (m) => muda(DateTime(m.year, m.month, 1)),
    ),
  ],
);

Widget _toggles(bool v, ValueChanged<bool> muda) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SsSwitch(value: v, onChanged: muda),
        SsSwitch(value: !v, onChanged: (n) => muda(!n)),
        const SsSwitch(value: true, onChanged: null),
      ],
    ),
    SsSwitchRow(
      title: 'Lembrete diário',
      subtitle: 'Às 20:00',
      icon: Icons.notifications_none_rounded,
      value: v,
      onChanged: muda,
    ),
    SsMenuSwitch(label: 'Modo compacto', subtitle: 'Menu da aba Mais', value: v, onChanged: muda),
  ],
);

Widget _checks(bool v, ValueChanged<bool> muda) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    SsCheckRow(title: 'Lembrar de mim', value: v, onChanged: muda),
    SsCheckRow(title: 'Aceito os termos', subtitle: 'Leia antes de marcar', value: !v, onChanged: (n) => muda(!n)),
    SsChoiceList<int>(
      options: const {0: 'Dinheiro', 1: 'Pix', 2: 'Cartão'},
      selected: v ? 1 : 2,
      onSelect: (k) => muda(k == 1),
    ),
  ],
);

Widget _efeitos(bool v, ValueChanged<bool> muda) => GestureDetector(
  behavior: HitTestBehavior.opaque,
  onTap: () => muda(!v),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SsCheckBox(value: v),
          SsCheckBox(value: v, circle: true, borderWidth: 2),
          SsRipple(
            trigger: v,
            child: Builder(
              builder: (context) => Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: SsColors.of(context).accent, shape: BoxShape.circle),
              ),
            ),
          ),
          SsBurst(trigger: v, child: const SizedBox.square(dimension: 24)),
        ],
      ),
      const SizedBox(height: 24),
      SsWormProgress(value: v ? .75 : .25),
    ],
  ),
);

Widget _selecao(Set<int> marcados, ValueChanged<Set<int>> muda) => Stack(
  children: [
    ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (var i = 0; i < 3; i++)
          SsSelectable(
            selected: marcados.contains(i),
            selecting: marcados.isNotEmpty,
            onToggle: () => muda(marcados.contains(i) ? ({...marcados}..remove(i)) : {...marcados, i}),
            child: SsListItem(
              title: 'Pedido ${1040 + i}',
              subtitle: 'Mercado Bom Preço',
              icon: Icons.receipt_long_outlined,
              value: r'R$ 120,00',
              onTap: _nada,
            ),
          ),
      ],
    ),
    Align(
      alignment: Alignment.bottomCenter,
      child: SsSelectionBar(
        count: marcados.length,
        actions: [SsContextAction(Icons.delete_outline_rounded, 'Excluir', _nada, destructive: true)],
        onClear: () => muda(<int>{}),
      ),
    ),
  ],
);

final catalogoMovA = <Componente>[
  Componente(
    'mov-sliding-indicator',
    'SsSlidingIndicator',
    'O indicador que desliza com mola entre itens, a base do segmented, das abas, da faixa de datas e do trilho lateral. Toque num número para ver.',
    comportamentos: [
      'A ponta da frente sai na hora e a de trás espera ~16%: o indicador estica no sentido do movimento e afina no outro, como gota.',
      'Passa um pouco do alvo (no máximo 22% do próprio tamanho) e assenta com a mola da suíte (SsMotion.bounce, 460 ms).',
      'Troca no meio do caminho continua de onde ele está, sem teleportar.',
      'count divide em vagas iguais (com padding); rectOf serve para itens de tamanhos diferentes; builder desenha a camada inteira.',
      'Com menos movimento, pula direto.',
    ],
    estados: [
      Estado('toque', 'toque para trocar', (_) => _pad(_Vivo<int>(0, _vagas))),
      Estado('esticando', 'da 1 para a 4: esticado', (_) => _pad(_Vivo<int>(0, _vagas, para: 3)), aguarde: 150),
      Estado('assentando', 'da 1 para a 4: passou e volta', (_) => _pad(_Vivo<int>(0, _vagas, para: 3)), aguarde: 330),
    ],
  ),
  Componente(
    'mov-segmented',
    'SsSegmented (movimento)',
    'Segmented: toque para trocar. A pílula desliza até a opção nova esticando no caminho.',
    comportamentos: [
      'A pílula desliza com SsSlidingIndicator: estica no meio, passa um pouco e assenta com mola.',
      'O texto da opção escolhida troca de cor e peso em 200 ms.',
      'Haptic de seleção; opção desabilitada não reage.',
    ],
    estados: [
      Estado('toque', 'toque para trocar', (_) => _pad(_Vivo<int>(0, _segmented))),
      Estado('esticando', 'de Dia para Mês: esticada', (_) => _pad(_Vivo<int>(0, _segmented, para: 2)), aguarde: 150),
    ],
  ),
  Componente(
    'mov-filter-chip',
    'SsFilterChip (movimento)',
    'Filtros: toque para marcar e desmarcar. O chip dá um pulinho e o ✓ se desenha.',
    comportamentos: [
      'Ao marcar, o chip encolhe para 90% e volta com mola solta (SsPop, passa ~25%).',
      'O ✓ se desenha em 280 ms (traço curto, depois o longo); ao desmarcar some em 120 ms.',
      'Sem ícone, a vaga do ✓ abre deslizando; com ícone, o ícone encolhe e o ✓ toma o lugar.',
      'O toque afunda e volta com mola (SsPressable).',
    ],
    estados: [
      Estado(
        'toque',
        'toque para marcar',
        (_) => _Vivo<Set<String>>(const {'Todos'}, _chips),
        tamanho: const Size(420, 72),
      ),
      Estado(
        'marcando',
        'marcando "Pagos": pulinho e ✓',
        (_) => _Vivo<Set<String>>(const {'Todos'}, _chips, para: const {'Todos', 'Pagos'}),
        tamanho: const Size(420, 72),
        aguarde: 110,
      ),
    ],
  ),
  Componente(
    'mov-tabs-underline',
    'SsTabsUnderline (movimento)',
    'Abas sublinhadas: toque para trocar. O traço viaja como minhoca, com rastro de brilho, e amassa ao chegar.',
    comportamentos: [
      'Minhoca (SsMotion.worm, 520 ms): a ponta da frente dispara e a de trás vem ~90 ms depois com a mola; no meio o traço cobre as duas abas e afina de 3 para 2 px.',
      'Ao chegar, amassa: ~8% mais largo e um pouco mais grosso, e assenta.',
      'Rastro: atrás da cabeça vai um brilho da marca (do transparente à marca a 35%) que apaga ao longo da viagem.',
      'Rótulo novo: sobe 2 px e volta com mola enquanto a cor passa para a da marca; o antigo só apaga para o tom suave.',
      'Troca no meio continua de onde o traço está. Com menos movimento, pula direto.',
    ],
    estados: [
      Estado(
        'toque',
        'toque para trocar',
        (_) => _pad(
          _Vivo<int>(
            0,
            (v, muda) =>
                SsTabsUnderline(tabs: const ['Tudo', 'Entradas', 'Saídas', 'Metas'], index: v, onChanged: muda),
          ),
        ),
      ),
      Estado(
        'esticando',
        'da 1 para a 4: esticado',
        (_) => _pad(
          _Vivo<int>(
            0,
            (v, muda) =>
                SsTabsUnderline(tabs: const ['Tudo', 'Entradas', 'Saídas', 'Metas'], index: v, onChanged: muda),
            para: 3,
          ),
        ),
        aguarde: 150,
      ),
      Estado(
        'amassando',
        'da 1 para a 4: chegando, amassado',
        (_) => _pad(
          _Vivo<int>(
            0,
            (v, muda) =>
                SsTabsUnderline(tabs: const ['Tudo', 'Entradas', 'Saídas', 'Metas'], index: v, onChanged: muda),
            para: 3,
          ),
        ),
        aguarde: 440,
      ),
    ],
  ),
  Componente(
    'mov-count-tabs',
    'SsCountTabs (movimento)',
    'Abas com contador: toque para trocar. O círculo da marca desliza de um contador para o outro.',
    comportamentos: [
      'As abas têm larguras diferentes: cada contador é medido depois do quadro e o círculo desliza entre as medidas.',
      'No caminho estica e afina; ao chegar o número dá um pulinho (SsPop).',
      'Antes da 1ª medida, cada aba pinta o próprio fundo (sem salto visual).',
    ],
    estados: [
      Estado(
        'toque',
        'toque para trocar',
        (_) => _Vivo<int>(
          0,
          (v, muda) => SsCountTabs(
            tabs: const [('Todas', 24), ('Pendentes', 8), ('Feitas', 14), ('Atrasadas', 2)],
            index: v,
            onChanged: muda,
          ),
        ),
      ),
      Estado(
        'deslizando',
        'de Todas para Feitas: no caminho',
        (_) => _Vivo<int>(
          0,
          (v, muda) => SsCountTabs(
            tabs: const [('Todas', 24), ('Pendentes', 8), ('Feitas', 14), ('Atrasadas', 2)],
            index: v,
            onChanged: muda,
          ),
          para: 2,
          apos: const Duration(milliseconds: 50),
        ),
        aguarde: 200,
      ),
    ],
  ),
  Componente(
    'mov-side-rail',
    'SsSideRail (movimento)',
    'Trilho lateral: toque para trocar. O círculo e o recorte deslizam juntos.',
    comportamentos: [
      'O círculo estica na vertical como gota no caminho e o recorte estica junto (raio elíptico).',
      'Passa um pouco do item e assenta com mola; o ícone novo cresce com mola.',
    ],
    estados: [
      Estado(
        'toque',
        'toque para trocar',
        (_) => _Vivo<int>(
          0,
          (v, muda) => Row(
            children: [
              SsSideRail(items: _abas4, currentIndex: v, onTap: muda),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
        tamanho: const Size(360, 340),
      ),
      Estado(
        'esticando',
        'do 1 para o 4: esticado',
        (_) => _Vivo<int>(
          0,
          (v, muda) => Row(
            children: [
              SsSideRail(items: _abas4, currentIndex: v, onTap: muda),
              const Expanded(child: SizedBox()),
            ],
          ),
          para: 3,
        ),
        tamanho: const Size(360, 340),
        aguarde: 160,
      ),
    ],
  ),
  Componente(
    'mov-step-top-bar',
    'SsStepTopBar (movimento)',
    'Topo de fluxo: toque em "Próximo" para avançar. A barrinha anda como minhoca com uma faísca e o número pula.',
    comportamentos: [
      'Barrinha (SsWormProgress, 520 ms): a cabeça dispara com a mola e passa um pouco; o corpo alcança ~90 ms depois, com um rastro claro (marca a 35%) entre os dois.',
      'Faísca: um ponto branco (90%) com brilho da marca vai na cabeça e se apaga no fim.',
      'Número: o novo pula (0,6 → 1,15 → 1) e solta um anel da marca (0 → 1,8×, apagando); o antigo apaga.',
      'Voltar um passo faz o mesmo ao contrário. Com menos movimento, tudo pula direto.',
    ],
    estados: [
      Estado(
        'toque',
        'toque em Próximo',
        (_) => _Vivo<int>(
          1,
          (v, muda) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SsStepTopBar(step: v, total: 4, onCancel: _nada, onBack: v > 1 ? () => muda(v - 1) : null),
              const SizedBox(height: 12),
              SsButton(label: 'Próximo', expand: false, small: true, onPressed: () => muda(v % 4 + 1)),
            ],
          ),
        ),
        tamanho: const Size(360, 130),
      ),
      Estado(
        'avancando',
        'do 1 para o 2: subindo',
        (_) => _Vivo<int>(1, (v, muda) => SsStepTopBar(step: v, total: 4, onCancel: _nada), para: 2),
        tamanho: const Size(360, 80),
        aguarde: 120,
      ),
      Estado(
        'faisca',
        'do 2 para o 4: a faísca na cabeça',
        (_) => _Vivo<int>(2, (v, muda) => SsStepTopBar(step: v, total: 4, onCancel: _nada), para: 4),
        tamanho: const Size(360, 80),
        aguarde: 200,
      ),
    ],
  ),
  Componente(
    'mov-date-strip',
    'SsDateStrip (movimento)',
    'Faixa de dias: toque num dia. A pílula alta desliza até ele.',
    comportamentos: [
      'A pílula é um SsSlidingIndicator: estica no caminho, passa um pouco e assenta; a faixa rola até centralizar.',
      'O dia escolhido cresce (76 → 96) com mola.',
      'Trocar de mês (pelo calendário) não desliza: a pílula já aparece no lugar.',
    ],
    estados: [
      Estado(
        'toque',
        'toque num dia',
        (_) => _Vivo<DateTime>(
          DateTime(2026, 11, 12),
          (v, muda) => SsDateStrip(selected: v, today: DateTime(2026, 11, 11), onChanged: muda),
        ),
        tamanho: const Size(360, 180),
      ),
      Estado(
        'deslizando',
        'do 12 para o 14: no caminho',
        (_) => _Vivo<DateTime>(
          DateTime(2026, 11, 12),
          (v, muda) => SsDateStrip(selected: v, today: DateTime(2026, 11, 11), onChanged: muda),
          para: DateTime(2026, 11, 14),
        ),
        tamanho: const Size(360, 180),
        aguarde: 150,
      ),
    ],
  ),
  Componente(
    'mov-calendario',
    'SsMonthSwitcher e SsMonthGrid (movimento)',
    'Calendário: troque de mês nas setas e toque num dia.',
    comportamentos: [
      'O nome do mês entra do lado da troca e assenta com mola (passa um pouco do meio).',
      'O dia escolhido enche na cor da marca e dá um pulinho (SsPop).',
    ],
    estados: [
      Estado(
        'toque',
        'toque para escolher',
        (_) => _Vivo<DateTime>(DateTime(2026, 11, 12), _calendario),
        tamanho: const Size(360, 400),
      ),
      Estado(
        'escolhendo',
        'escolhendo o dia 20: pulinho',
        (_) => _Vivo<DateTime>(DateTime(2026, 11, 12), _calendario, para: DateTime(2026, 11, 20)),
        tamanho: const Size(360, 400),
        aguarde: 90,
      ),
      Estado(
        'trocando',
        'indo para dezembro: o nome entra pela direita',
        (_) => _Vivo<DateTime>(DateTime(2026, 11, 12), _calendario, para: DateTime(2026, 12, 1)),
        tamanho: const Size(360, 400),
        aguarde: 120,
      ),
    ],
  ),
  Componente(
    'mov-toque',
    'Toque com mola',
    'SsPressable, SsButton, SsActionButton, SsCard e SsListItem: segure e solte para sentir a volta com mola.',
    comportamentos: [
      'No toque afunda rápido (100 ms, para 97%; 98% em card e item de lista).',
      'Ao soltar volta com SsMotion.bounce (420 ms): passa um tiquinho do tamanho e assenta.',
      'Se o dedo anda (virou rolagem), solta na hora: a lista não rola encolhida.',
      'SsActionButton: o "Pronto" verde chega com a mesma mola; o carregando cruza com um pulinho.',
      'Com menos movimento, não afunda.',
    ],
    estados: [
      Estado(
        'toque',
        'segure e solte',
        (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SsButton(label: 'Salvar', icon: Icons.check_rounded, onPressed: _nada),
              const SizedBox(height: 10),
              SsActionButton(
                label: 'Enviar',
                variant: SsButtonVariant.ghost,
                onPressed: () => Future<void>.delayed(const Duration(milliseconds: 700)),
              ),
              const SizedBox(height: 10),
              SsCard(
                onTap: _nada,
                child: const SsListItem(title: 'Cartão tocável', subtitle: 'SsCard com onTap', icon: Icons.credit_card),
              ),
              const SizedBox(height: 6),
              const SsListItem(
                title: 'Item de lista',
                subtitle: 'SsListItem com onTap',
                icon: Icons.shopping_bag_outlined,
                value: r'R$ 42,90',
                onTap: _nada,
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 330),
      ),
    ],
  ),
  Componente(
    'mov-switch',
    'SsSwitch, SsSwitchRow e SsMenuSwitch',
    'Interruptores: toque para ligar e desligar. Líquido: a bolinha estica, amassa no fim e a cor escorre na trilha.',
    comportamentos: [
      'Viagem (520 ms): na 1ª metade a bolinha estica até 1,45× a largura (a ponta de trás fica para trás) e afina.',
      'Bate no fim e amassa (0,82 de largura × 1,12 de altura, encostada na parede) e volta com a mola (SsMotion.bounce).',
      'Trilha: a cor da marca escorre a partir de onde a bolinha saiu (círculo crescendo, recortado na pílula); ao desligar, escoa de volta.',
      'Ligado, um ✓ da marca entra girando (−90° → 0) e pula na bolinha; desligado, a bolinha fica lisa.',
      'Halo: ao bater no fim, um anel da marca se abre em volta da bolinha e some (SsRipple).',
      'Haptic de seleção no toque. Trocar no meio continua de onde a bolinha e a cor estão.',
      'SsSwitchRow e SsMenuSwitch usam o SsSwitch; tocar na linha alterna. onChanged nulo deixa apagado.',
      'Leitor de tela: interruptor com estado ligado/desligado. Com menos movimento, pula direto.',
      'SsMenuSwitch(icon:) põe a bolha de ícone das linhas do menu à esquerda.',
    ],
    estados: [
      Estado('toque', 'toque para alternar', (_) => _Vivo<bool>(false, _toggles), tamanho: const Size(360, 240)),
      Estado(
        'ligando',
        'ligando: a gota no meio do caminho',
        (_) => _Vivo<bool>(false, _toggles, para: true),
        tamanho: const Size(360, 240),
        aguarde: 100,
      ),
      Estado(
        'amassando',
        'ligando: bateu no fim, amassada, com o halo',
        (_) => _Vivo<bool>(false, _toggles, para: true),
        tamanho: const Size(360, 240),
        aguarde: 300,
      ),
      Estado(
        'menu-com-icone',
        'SsMenuSwitch com icon',
        (_) => _pad(
          SsMenuSwitch(
            label: 'Notificações',
            subtitle: 'Avisos da casa',
            icon: Icons.notifications_none_rounded,
            value: true,
            onChanged: (_) {},
          ),
        ),
        tamanho: const Size(360, 110),
      ),
    ],
  ),
  Componente(
    'mov-check',
    'SsCheckRow, SsChoiceList e SsCheckMark',
    'Caixas e escolhas: toque para marcar. A caixa antecipa, pula, enche do centro, desenha o ✓ e estoura.',
    comportamentos: [
      'SsCheckRow usa o SsCheckBox. Marcando: encolhe para 0,85 (80 ms), pula para 1,12 e assenta com mola.',
      'A cor da marca inunda do centro como um círculo crescendo; o ✓ se desenha logo depois (traço curto e depois o longo).',
      'Estouro (SsBurst): 7 risquinhos da marca saem ~14 px do contorno e somem, uma vez (~450 ms).',
      'Desmarcando: o ✓ se desfaz rápido, a cor encolhe para o centro e a caixa balança (−6° → 4° → 0).',
      'SsChoiceList: a escolha é um ✓ (não bolinha de rádio): some da anterior e se desenha na nova, com pulinho (SsPop).',
      'SsCheckMark: o ✓ é um traço que se desenha em 280 ms e some em 120 ms.',
      'Montado já marcado, aparece pronto (sem animar à toa). Com menos movimento, troca direto.',
    ],
    estados: [
      Estado('toque', 'toque para marcar', (_) => _pad(_Vivo<bool>(false, _checks)), tamanho: const Size(360, 330)),
      Estado(
        'marcando',
        'marcando: o ✓ se desenhando',
        (_) => _pad(_Vivo<bool>(false, _checks, para: true)),
        tamanho: const Size(360, 330),
        aguarde: 120,
      ),
      Estado(
        'estourando',
        'marcando: o estouro em volta da caixa',
        (_) => _pad(_Vivo<bool>(false, _checks, para: true)),
        tamanho: const Size(360, 330),
        aguarde: 260,
      ),
    ],
  ),
  Componente(
    'mov-selecao',
    'SsSelectable e SsSelectionBar (movimento)',
    'Seleção múltipla: segure um item para começar e toque nos outros.',
    comportamentos: [
      'O círculo de ✓ entra com mola; é um SsCheckBox redondo: ao marcar, pula, a cor inunda do centro, o ✓ se desenha e estoura; ao desmarcar, desfaz e balança.',
      'A barra sobe de baixo com SsMotion.bounce (passa um pouco e assenta); desce reto.',
      'O item afunda e volta com mola no toque (SsListItem com onTap).',
    ],
    estados: [
      Estado('toque', 'segure um item', (_) => _Vivo<Set<int>>(const {}, _selecao), tamanho: const Size(360, 320)),
      Estado(
        'subindo',
        'selecionando: a barra subindo',
        (_) => _Vivo<Set<int>>(const {}, _selecao, para: const {0}),
        tamanho: const Size(360, 320),
        aguarde: 160,
      ),
    ],
  ),
  Componente(
    'mov-efeitos',
    'SsRipple, SsBurst, SsWormProgress e SsCheckBox',
    'Os efeitos de uma vez só que os componentes usam. Toque para tocar de novo.',
    comportamentos: [
      'SsRipple: anel da marca que se abre de begin até scale × o raio (padrão 0 → 1,8×) e apaga, quando trigger muda com play ligado; delay opcional.',
      'SsBurst: count risquinhos (padrão 7) saem do contorno, andam distance px (padrão 14) e somem em ~450 ms.',
      'SsWormProgress: barra de progresso minhoca (cabeça com mola e faísca, corpo alcança).',
      'SsCheckBox: caixa (ou círculo) que antecipa, pula, enche do centro, desenha o ✓ e estoura; ao desmarcar, balança.',
      'Nenhum toca ao montar nem anima para sempre; com menos movimento, nada toca.',
    ],
    estados: [
      Estado('toque', 'toque para marcar', (_) => _pad(_Vivo<bool>(false, _efeitos)), tamanho: const Size(360, 120)),
      Estado(
        'tocando',
        'marcando: anel, estouro e faísca',
        (_) => _pad(_Vivo<bool>(false, _efeitos, para: true)),
        tamanho: const Size(360, 120),
        aguarde: 180,
      ),
    ],
  ),
  Componente(
    'mov-stepper',
    'SsStepper (movimento)',
    'Ajuste numérico: toque em − e +. O número rola e assenta com mola.',
    comportamentos: [
      'O número novo entra do lado da mudança e assenta com SsMotion.bounce (400 ms).',
      'Os botões afundam para 90% e voltam com mola ao soltar.',
    ],
    estados: [
      Estado(
        'toque',
        'toque em − e +',
        (_) => _pad(_Vivo<num>(2, (v, muda) => SsStepper(value: v, onChanged: muda, unit: 'kg', label: 'Peso'))),
        tamanho: const Size(360, 110),
      ),
      Estado(
        'subindo',
        'de 2 para 3: chegando',
        (_) => _pad(_Vivo<num>(2, (v, muda) => SsStepper(value: v, onChanged: muda, unit: 'kg'), para: 3)),
        tamanho: const Size(360, 90),
        aguarde: 120,
      ),
    ],
  ),
];
