// v0.11 (densidade) nas peças da v0.10: tamanhos por SsDensity, alvo de toque
// de 48 no compacto e nada estourando em caixa estreita nas três densidades.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _app(Widget child, SsDensity d, {double width = 360}) => MaterialApp(
  // Sem transição de tema: a SsDensity troca no quadro seguinte.
  themeAnimationDuration: Duration.zero,
  theme: AppTheme.build(Brightness.light, density: d),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: width,
        child: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(8), child: child),
        ),
      ),
    ),
  ),
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const densidades = {
    SsDensity.compact: 'compact',
    SsDensity.standard: 'standard',
    SsDensity.comfortable: 'comfortable',
  };

  testWidgets('SsThermostat: anel 200/220/240 e −/+ 44/48/52 pela densidade', (tester) async {
    const anel = {'compact': 200.0, 'standard': 220.0, 'comfortable': 240.0};
    const passo = {'compact': 44.0, 'standard': 48.0, 'comfortable': 52.0};
    for (final e in densidades.entries) {
      await tester.pumpWidget(_app(SsThermostat(target: 22, onChanged: (_) {}), e.key));
      final ring = tester.getSize(
        find.descendant(of: find.byType(SsThermostat), matching: find.byType(CustomPaint)).first,
      );
      expect(ring.width, anel[e.value], reason: e.value);
      final menos = find.byTooltip(SsStrings.pt.decrease);
      expect(tester.getSize(find.descendant(of: menos, matching: find.byType(Container)).first).width, passo[e.value]);
    }
    // size explícito continua valendo.
    await tester.pumpWidget(_app(SsThermostat(target: 22, size: 180, onChanged: (_) {}), SsDensity.comfortable));
    expect(
      tester.getSize(find.descendant(of: find.byType(SsThermostat), matching: find.byType(CustomPaint)).first).width,
      180,
    );
  });

  testWidgets('SsThermostat compacto: toque fora do desenho do −, dentro dos 48, ainda vale', (tester) async {
    double? alvo;
    await tester.pumpWidget(_app(SsThermostat(target: 22, onChanged: (v) => alvo = v), SsDensity.compact));
    final menos = find.byTooltip(SsStrings.pt.decrease);
    final caixa = tester.getRect(find.descendant(of: menos, matching: find.byType(Container)).first);
    expect(caixa.height, 44);
    // 1 px acima da borda de cima do desenho (dentro da sobra de 2 px até 48).
    await tester.tapAt(Offset(caixa.center.dx, caixa.top - 1));
    await tester.pump(const Duration(seconds: 1));
    expect(alvo, 21.5);
  });

  testWidgets('SsIconButton: desenho 36/40/44 e alvo de 48 em todas', (tester) async {
    const visual = {'compact': 36.0, 'standard': 40.0, 'comfortable': 44.0};
    for (final e in densidades.entries) {
      await tester.pumpWidget(
        _app(
          Row(
            children: [SsIconButton(icon: Icons.delete_outline, tooltip: 'Excluir', onPressed: () {})],
          ),
          e.key,
        ),
      );
      final layout = tester.getSize(find.byType(IconButton));
      expect(layout.height, greaterThanOrEqualTo(48), reason: e.value);
      final material = tester.getSize(
        find.descendant(of: find.byType(IconButton), matching: find.byType(Material)).first,
      );
      expect(material.width, visual[e.value], reason: e.value);
    }
  });

  testWidgets('SsFab e SsCodeKeypad seguem a densidade', (tester) async {
    const fab = {'compact': 48.0, 'standard': 56.0, 'comfortable': 60.0};
    const tecla = {'compact': 48.0, 'standard': 56.0, 'comfortable': 60.0};
    for (final e in densidades.entries) {
      await tester.pumpWidget(_app(SsFab(icon: Icons.add, label: 'Seção', onPressed: () {}), e.key));
      expect(tester.getSize(find.byType(SsFab)).height, fab[e.value], reason: e.value);

      await tester.pumpWidget(_app(SsCodeKeypad(length: 4, onSubmit: (_) async => true), e.key));
      final k = find.ancestor(of: find.text('5'), matching: find.byType(Container)).first;
      expect(tester.getSize(k).height, tecla[e.value], reason: e.value);
    }
  });

  testWidgets('SsDeviceTile, SsDataTable, SsWeekdayPicker e SsDPad cabem estreitos nas três densidades', (
    tester,
  ) async {
    for (final e in densidades.entries) {
      await tester.pumpWidget(
        _app(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SsDeviceTile(
                      icon: Icons.lightbulb_outline,
                      name: 'Luz da sala de jantar',
                      state: 'Ligada · 80%',
                      on: true,
                      onToggle: (_) {},
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: SsDeviceTile(icon: Icons.lock_outline, name: 'Portão', status: SsDeviceStatus.locked),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SsWeekdayPicker(value: const {1, 2, 3}, onChanged: (_) {}),
              const SizedBox(height: 8),
              SsDataTable(
                stackBelow: 0,
                columns: const [SsDataColumn('Nome'), SsDataColumn('Valor', numeric: true)],
                rows: const [
                  SsDataRow([Text('Sala'), Text('21,5')]),
                ],
              ),
              const SizedBox(height: 8),
              const SsCallout(title: 'Faltam campos', message: 'Escolha o aparelho', actions: [Text('ok')]),
              const SizedBox(height: 8),
              SsButtonGroup(
                buttons: [
                  SsGroupButton(icon: Icons.arrow_upward, tooltip: 'Abrir', onPressed: () {}),
                  SsGroupButton(icon: Icons.stop, tooltip: 'Parar', onPressed: () {}),
                ],
              ),
              const SizedBox(height: 8),
              const Center(child: SsDPad(extraButtons: [SsDPadButton('netflix', 'Netflix')])),
            ],
          ),
          e.key,
          width: 340,
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull, reason: e.value);
    }
  });
}
