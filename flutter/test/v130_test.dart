import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// v1.3 · alça do menu sempre à vista na borda e a aparência (tema, preto total, cores, densidade).
const _abas = [SsNavItem(Icons.home_outlined, 'Início'), SsNavItem(Icons.receipt_long_outlined, 'Pedidos')];

Widget _casca() => MaterialApp(
  theme: AppTheme.light,
  home: SsNavScaffold(
    peek: false,
    navBar: SsNavBar(items: _abas, currentIndex: 0, onTap: (_) {}),
    sideMenu: const SsSideMenu(title: 'Meu App'),
    body: const SizedBox.expand(),
  ),
);

/// A pílula da alça (Container de 5 px de largura com a borda direita arredondada).
Finder get _alca =>
    find.byWidgetPredicate((w) => w is Container && w.constraints?.maxWidth == 5 && w.constraints?.maxHeight == 56);

class _Memoria {
  String? valor;
  int gravacoes = 0;
}

SsAppearanceController _controlador(_Memoria m, {SsBrand? brand}) => SsAppearanceController(
  brand: brand ?? SsBrand.ambar,
  read: () async => m.valor,
  write: (v) async {
    m.valor = v;
    m.gravacoes++;
  },
);

void main() {
  testWidgets('alça na borda com o menu fechado; tocar abre; invisível com o menu aberto', (t) async {
    await t.pumpWidget(_casca());
    await t.pumpAndSettle();
    expect(_alca, findsOneWidget);
    expect(t.getTopLeft(_alca).dx, 0); // encostada na borda esquerda
    await t.tap(_alca);
    await t.pumpAndSettle();
    expect(t.state<SsSideMenuHostState>(find.byType(SsSideMenuHost)).isOpen, isTrue);
    // Com o menu aberto a alça fica invisível (segue na árvore para o arraste não se perder).
    final cor = (t.widget<Container>(_alca).decoration! as BoxDecoration).color!;
    expect(cor.a, 0);
  });

  testWidgets('arrastar a partir da alça também abre o menu', (t) async {
    await t.pumpWidget(_casca());
    await t.pumpAndSettle();
    final g = await t.startGesture(t.getCenter(_alca));
    for (var i = 0; i < 10; i++) {
      await g.moveBy(const Offset(30, 0));
      await t.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await t.pumpAndSettle();
    expect(t.state<SsSideMenuHostState>(find.byType(SsSideMenuHost)).isOpen, isTrue);
  });

  test('SsAppearance: grava e lê; texto ruim vira o padrão', () {
    const a = SsAppearance(paleta: 'eucalipto', themeMode: ThemeMode.dark, oled: true, density: SsDensity.compact);
    expect(SsAppearance.fromJson(a.toJson()), a);
    expect(SsAppearance.fromJson(null), const SsAppearance());
    expect(SsAppearance.fromJson('{lixo'), const SsAppearance());
    // Paleta que não existe mais: volta para a cor do app, mantendo o resto.
    final semPaleta = SsAppearance.fromJson('{"paleta":"nao-existe","tema":"dark"}');
    expect(semPaleta.paleta, isNull);
    expect(semPaleta.themeMode, ThemeMode.dark);
  });

  test('controlador: lê o guardado, troca a marca do tema e guarda a troca', () async {
    final m = _Memoria()..valor = const SsAppearance(paleta: 'eucalipto').toJson();
    final c = _controlador(m);
    await c.load();
    expect(c.value.paleta, 'eucalipto');
    expect(c.effectiveBrand, SsPaleta.porSlug('eucalipto')!.brand);
    expect(c.theme(Brightness.light).extension<SsBrand>(), SsPaleta.porSlug('eucalipto')!.brand);

    await c.set(c.value.copyWith(clearPaleta: true));
    expect(c.effectiveBrand, SsBrand.ambar); // a cor do app
    expect(m.gravacoes, 1);
    expect(SsAppearance.fromJson(m.valor).paleta, isNull);
    // Tema em cache por combinação (mesmo objeto).
    expect(identical(c.theme(Brightness.dark), c.theme(Brightness.dark)), isTrue);
  });

  testWidgets('painel: escolher Escuro, ligar o preto total e uma paleta; "Cor do app" primeiro', (t) async {
    final m = _Memoria();
    final c = _controlador(m);
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SsAppearancePanel(controller: c),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Preto total'), findsOneWidget); // tema do sistema: o preto total aparece
    await t.tap(find.text('Claro'));
    await t.pumpAndSettle();
    expect(c.value.themeMode, ThemeMode.light);
    expect(find.text('Preto total'), findsNothing); // no claro não faz sentido
    await t.tap(find.text('Escuro'));
    await t.pumpAndSettle();
    await t.tap(find.text('Preto total'));
    await t.pumpAndSettle();
    expect(c.value.oled, isTrue);

    // A 1ª ficha é a cor do app, marcada; trocar para outra paleta grava o slug.
    final picker = t.widget<SsPalettePicker>(find.byType(SsPalettePicker));
    expect(picker.paletas.first.nome, 'Cor do app');
    expect(picker.value, SsBrand.ambar);
    picker.onChanged(SsPaleta.porSlug('eucalipto')!);
    await t.pumpAndSettle();
    expect(c.value.paleta, 'eucalipto');
    picker.onChanged(picker.paletas.first);
    await t.pumpAndSettle();
    expect(c.value.paleta, isNull);
    expect(SsAppearance.fromJson(m.valor), c.value);
  });
}
