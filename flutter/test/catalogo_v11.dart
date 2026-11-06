// Entradas do catálogo da v0.11: densidade (compacta, padrão, confortável) e o
// seletor. As mesmas peças nas três densidades, para comparar.
import 'package:flutter/material.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo.dart';

void _nada() {}

/// Amostra das peças que mais mudam com a densidade (a mesma do `densidade_test`).
class AmostraDensidade extends StatelessWidget {
  const AmostraDensidade({super.key});

  @override
  Widget build(BuildContext context) {
    final d = SsDensity.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(d.cardPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: d.gap,
        children: [
          Row(
            spacing: 8,
            children: [
              const Expanded(
                child: SsButton(label: 'Salvar', icon: Icons.check_rounded, onPressed: _nada),
              ),
              const SsButton(label: 'Pequeno', small: true, expand: false, onPressed: _nada),
              SsIconButton(icon: Icons.edit_outlined, tooltip: 'Editar', onPressed: () {}),
            ],
          ),
          const SsTextField(label: 'Nome', initialValue: 'Luz da sala', icon: Icons.lightbulb_outline_rounded),
          const SsSearchField(hint: 'Buscar'),
          SsSegmented<int>(segments: const [(0, 'Dia'), (1, 'Semana'), (2, 'Mês')], value: 1, onChanged: (_) {}),
          SsChipBar(
            padding: EdgeInsets.zero,
            children: [
              SsFilterChip('Todos', selected: true, count: 24, onTap: () {}),
              SsFilterChip('Luzes', selected: false, onTap: () {}),
              SsFilterChip('Clima', selected: false, onTap: () {}),
            ],
          ),
          SsCard(
            child: Column(
              children: [
                SsSwitchRow(title: 'Avisar no celular', subtitle: 'Push ao abrir', value: true, onChanged: (_) {}),
                const SsListItem(
                  title: 'Conta de luz',
                  subtitle: 'Hoje · Casa',
                  icon: Icons.bolt_rounded,
                  value: r'R$ 182,40',
                  onTap: _nada,
                ),
              ],
            ),
          ),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: SsDeviceTile(
                  icon: Icons.lightbulb_rounded,
                  name: 'Luz da cozinha',
                  state: 'Ligada · 80%',
                  on: true,
                  onTap: _nada,
                  onToggle: (_) {},
                ),
              ),
              Expanded(
                child: SsDeviceTile(
                  icon: Icons.power_outlined,
                  name: 'Tomada',
                  state: 'Desligada',
                  onTap: _nada,
                  onToggle: (_) {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _na(SsDensity d) => SsDensityScope(density: d, child: const AmostraDensidade());

const _amostra = Size(360, 640);

final catalogoV11 = <Componente>[
  Componente(
    'ss-density',
    'SsDensity · SsDensityScope',
    'Densidade da interface (v0.11): compacta, padrão e confortável. Altura dos controles, respiros, espaço entre itens, linha, card, raio, ícone e um leve ajuste de fonte; o par do data-ss-density do web.',
    comportamentos: [
      'Vem do tema (AppTheme.build(b, density: SsDensity.compact)) e muda num trecho com SsDensityScope.',
      'Os Ss* leem SsDensity.of(context): botão 40/48/52, campo 44/52/56, chip 30/34/38, card 12/16/20.',
      'O alvo de toque nunca fica abaixo de 48: no compacto o desenho encolhe e o SsTapTarget mantém a área.',
      'Alinha o ThemeData.visualDensity (os widgets Material que sobram). Claro/escuro e movimento não mudam.',
    ],
    estados: [
      Estado('compacta', 'compacta (compact)', (_) => _na(SsDensity.compact), tamanho: _amostra),
      Estado('padrao', 'padrão (standard)', (_) => _na(SsDensity.standard), tamanho: _amostra),
      Estado('confortavel', 'confortável (comfortable)', (_) => _na(SsDensity.comfortable), tamanho: _amostra),
    ],
  ),
  Componente(
    'ss-density-picker',
    'SsDensityPicker',
    'Escolha de densidade (Compacta, Padrão, Confortável) com a pílula que desliza; o Ss::DensityPickerComponent do web. O app guarda a escolha e reconstrói o tema.',
    comportamentos: [
      'Textos do SsStrings (pt/en/es); ícones de densidade antes de cada opção (icons: false tira).',
      'Só escolhe: onChanged recebe a SsDensity.',
    ],
    estados: [
      Estado(
        'padrao',
        'padrão marcada',
        (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: SsDensityPicker(value: SsDensity.standard, onChanged: (_) {}),
          ),
        ),
      ),
      Estado(
        'compacta',
        'compacta, sem ícones',
        (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: SsDensityPicker(value: SsDensity.compact, icons: false, onChanged: (_) {}),
          ),
        ),
      ),
    ],
  ),
];
