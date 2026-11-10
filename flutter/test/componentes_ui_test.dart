import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:componentes_ui/componentes_ui.dart';

const verde = SsBrand(
  accentLight: Color(0xFF1BA06A),
  accentHoverLight: Color(0xFF138152),
  accentSoftLight: Color(0xFFE3F6EE),
  accentDark: Color(0xFF4FD39B),
  accentSoftDark: Color(0xFF12301F),
  brandFrom: Color(0xFF22C483),
  brandTo: Color(0xFF1BA06A),
  brandDeep: Color(0xFF0F6B45),
);

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  test('dinheiro e datas em pt-BR', () {
    expect(money(123456), 'R\$\u00A01.234,56');
    expect(money(-5), '-R\$\u00A00,05');
    expect(parseMoney(r'R$ 1.234,56'), 123456);
    expect(parseMoney('12.5'), 1250);
    expect(qty(1.5), '1,5');
    expect(date(DateTime(2026, 10, 6)), '06/10/2026');
  });

  testWidgets('a cor da marca chega aos componentes', (tester) async {
    for (final (brand, cor) in [(SsBrand.violeta, const Color(0xFF5A45E8)), (verde, const Color(0xFF1BA06A))]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(Brightness.light, brand: brand),
          home: Scaffold(
            body: Column(
              children: [
                SsButton(label: 'Salvar', onPressed: () {}),
                const SsCard(child: Text('x')),
                const SsBadge('novo'),
                const SsProgress(.5),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(); // a troca de tema é animada
      final material = tester.widget<Material>(
        find.descendant(of: find.byType(SsButton), matching: find.byType(Material)).first,
      );
      expect(material.color, cor);
      expect(Theme.of(tester.element(find.byType(SsCard))).colorScheme.primary, cor);
    }
  });

  test('SsAmount separa os centavos só quando há ",dd" no fim', () {
    expect(SsAmount.split(r'R$ 1.234,56'), (r'R$ 1.234', ',56'));
    expect(SsAmount.split('38'), ('38', ''));
    expect(SsAmount.split('1,5 mil'), ('1,5 mil', ''));
  });

  test('SsAvatar: iniciais e cor estável pelo nome', () {
    expect(SsAvatar.initials('ana maria souza'), 'AS');
    expect(SsAvatar.initials('  Carla '), 'C');
    expect(SsAvatar.initials(''), '?');
    expect(SsAvatar.seed('Ana Souza'), SsAvatar.seed(' ana souza'));
    expect(SsAvatar.seed('Ana Souza'), isNot(SsAvatar.seed('Bruno Lima')));
  });

  testWidgets('showSsToast aparece, a ação fecha e some sozinho', (t) async {
    var desfez = false;
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (ctx) => TextButton(
            onPressed: () => showSsToast(ctx, 'Salvo', actionLabel: 'Desfazer', onAction: () => desfez = true),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await t.tap(find.text('abrir'));
    // Só a entrada: a borda de contagem anima até o fim do prazo (pumpAndSettle iria até lá).
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Salvo'), findsOneWidget);
    await t.tap(find.text('Desfazer'));
    await t.pump();
    expect(desfez, isTrue);
    expect(find.text('Salvo'), findsNothing);

    await t.tap(find.text('abrir'));
    await t.pump(); // monta o aviso (o prazo de 4 s começa aqui)
    expect(find.text('Salvo'), findsOneWidget);
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
    expect(find.text('Salvo'), findsNothing);
  });
}
