// Idioma dos componentes (SsStrings): textos completos em pt/en/es, escolha
// do idioma com e sem o delegate, override por escopo e widgets em inglês.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:componentes_ui/componentes_ui.dart';

const _locales = [Locale('pt', 'BR'), Locale('en'), Locale('es')];

/// App com idioma configurado; [delegate] liga o SsStrings.delegate.
Widget _app(Widget child, {Locale locale = const Locale('en'), bool delegate = true}) => MaterialApp(
  locale: locale,
  supportedLocales: _locales,
  localizationsDelegates: [
    if (delegate) SsStrings.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

/// Guarda o SsStrings que o widget enxerga.
class _Pega extends StatelessWidget {
  const _Pega(this.onStrings);
  final ValueChanged<SsStrings> onStrings;

  @override
  Widget build(BuildContext context) {
    onStrings(SsStrings.of(context));
    return const SizedBox();
  }
}

Future<SsStrings> _ver(WidgetTester t, Widget Function(Widget pega) app) async {
  late SsStrings s;
  await t.pumpWidget(app(_Pega((v) => s = v)));
  return s;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('textos', () {
    for (final (nome, s) in [('pt', SsStrings.pt), ('en', SsStrings.en), ('es', SsStrings.es)]) {
      test('$nome não tem texto vazio', () {
        final vazios = [
          for (final e in s.debugSamples.entries)
            if (e.value.trim().isEmpty) e.key,
        ];
        expect(vazios, isEmpty);
        expect(s.months, hasLength(12));
        expect(s.weekdayInitials, hasLength(7));
        expect(s.weekdaysShort, hasLength(7));
        expect(s.weekdaysLong, hasLength(7));
        expect(s.planNames, hasLength(3));
      });
    }

    test('os três idiomas têm as mesmas chaves e en/es são traduzidos', () {
      final pt = SsStrings.pt.debugSamples, en = SsStrings.en.debugSamples, es = SsStrings.es.debugSamples;
      expect(en.keys, pt.keys);
      expect(es.keys, pt.keys);
      expect(en['cancel'], 'Cancel');
      expect(es['cancel'], 'Cancelar');
      expect(SsStrings.en.agoMinutes(5), '5 min ago');
      expect(SsStrings.es.agoDays(3), 'hace 3 días');
      expect(SsStrings.en.longDate(DateTime(2026, 10, 5)), 'Monday, October 5');
      expect(SsStrings.pt.longDate(DateTime(2026, 10, 5)), 'segunda, 5 de outubro');
    });

    test('funções de fora do contexto continuam em pt sem SsStrings', () {
      final agora = DateTime(2026, 10, 6, 12);
      expect(timeAgo(agora.subtract(const Duration(minutes: 5)), now: agora), 'há 5 min');
      expect(timeAgo(agora.subtract(const Duration(minutes: 5)), now: agora, strings: SsStrings.en), '5 min ago');
      expect(timeAgo(agora.subtract(const Duration(days: 1)), now: agora, strings: SsStrings.es), 'ayer');
      expect(ssMonthName(DateTime(2026, 10)), 'Outubro 2026');
      expect(ssMonthName(DateTime(2026, 10), SsStrings.en), 'October 2026');
      expect(SsSyncStatus.label(SsSyncState.pending, 3, SsStrings.en), '3 to send');
      expect(SsValidators.required('', SsStrings.es), 'Campo obligatorio');
      expect(date(DateTime(2026, 10, 6), SsStrings.en), '10/06/2026');
      expect(SsDateField.shortcuts(DateTime(2026, 10, 29), SsStrings.en)[2].$1, 'Mon 11/02');
    });

    test('copyWith troca só o que foi passado', () {
      final s = SsStrings.en.copyWith(cancel: 'Dismiss', agoMinutes: (n) => '${n}m');
      expect(s.cancel, 'Dismiss');
      expect(s.agoMinutes(3), '3m');
      expect(s.confirm, 'Confirm');
      expect(s.locale, const Locale('en'));
    });
  });

  group('formatos', () {
    test('real é o padrão e não muda', () {
      expect(money(123456), r'R$ 1.234,56');
      expect(money(-5), r'-R$ 0,05');
      expect(parseMoney(r'R$ 1.234,56'), 123456);
      expect(parseMoney('12.5'), 1250);
      expect(qty(1.5), '1,5');
    });

    test('dólar e euro', () {
      expect(money(123456, SsFormats.usd), r'$1,234.56');
      expect(money(-5, SsFormats.usd), r'-$0.05');
      expect(parseMoney(r'$1,234.56', SsFormats.usd), 123456);
      expect(money(123456, SsFormats.eur), '1.234,56 €');
      expect(qty(1.5, SsFormats.usd), '1.5');
    });
  });

  group('SsStrings.of', () {
    testWidgets('sem idioma configurado fica em pt', (t) async {
      final s = await _ver(t, (w) => MaterialApp(home: w));
      expect(s, same(SsStrings.pt));
    });

    testWidgets('com o delegate, segue o locale do app', (t) async {
      expect(await _ver(t, (w) => _app(w)), same(SsStrings.en));
      expect(await _ver(t, (w) => _app(w, locale: const Locale('es'))), same(SsStrings.es));
      expect(await _ver(t, (w) => _app(w, locale: const Locale('pt', 'BR'))), same(SsStrings.pt));
    });

    testWidgets('sem o delegate, escolhe pelo idioma do Localizations', (t) async {
      expect(await _ver(t, (w) => _app(w, delegate: false)), same(SsStrings.en));
      expect(await _ver(t, (w) => _app(w, locale: const Locale('es'), delegate: false)), same(SsStrings.es));
    });

    testWidgets('delegate com apply ajusta em todos os idiomas', (t) async {
      final s = await _ver(
        t,
        (w) => MaterialApp(
          locale: const Locale('es'),
          supportedLocales: _locales,
          localizationsDelegates: [
            SsStringsDelegate(apply: (s) => s.copyWith(retry: '¡Otra vez!')),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: w,
        ),
      );
      expect(s.retry, '¡Otra vez!');
      expect(s.cancel, 'Cancelar');
    });

    testWidgets('o escopo ganha do delegate', (t) async {
      final fixo = await _ver(t, (w) => _app(SsStringsScope(strings: SsStrings.es, child: w)));
      expect(fixo, same(SsStrings.es));

      final ajustado = await _ver(
        t,
        (w) => _app(
          SsStringsScope.override(
            apply: (s) => s.copyWith(cancel: 'Nope'),
            child: w,
          ),
        ),
      );
      expect(ajustado.cancel, 'Nope');
      expect(ajustado.confirm, 'Confirm');
    });
  });

  group('widgets em inglês', () {
    testWidgets('SsErrorView, SsAsyncBody e SsLoadMore', (t) async {
      await t.pumpWidget(
        _app(
          Column(
            children: [
              Expanded(
                child: SsAsyncBody<int>(
                  value: AsyncValue<int>.error(Exception('x'), StackTrace.empty),
                  data: (_) => const SizedBox(),
                  isOffline: (_) => true,
                  onRetry: () {},
                ),
              ),
              const SsLoadMore(hasMore: true),
              const SsLoadMore(hasMore: false),
            ],
          ),
        ),
      );
      expect(find.text('No connection. Check your internet and try again.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Load more'), findsOneWidget);
      expect(find.text('End of list'), findsOneWidget);
    });

    testWidgets('SsConfirmDialog e SsPromptDialog', (t) async {
      await t.pumpWidget(_app(const SsConfirmDialog(title: 'Delete?')));
      await t.pumpAndSettle();
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await t.pumpWidget(_app(const SsPromptDialog(title: 'Rename')));
      await t.pumpAndSettle();
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
    });

    testWidgets('passar o rótulo ainda manda', (t) async {
      await t.pumpWidget(_app(const SsConfirmDialog(title: 'Sair?', confirmLabel: 'Sim', cancelLabel: 'Não')));
      await t.pumpAndSettle();
      expect(find.text('Sim'), findsOneWidget);
      expect(find.text('Não'), findsOneWidget);
    });

    testWidgets('SsDateField, SsSearchField e SsMonthSwitcher', (t) async {
      await t.pumpWidget(
        _app(
          Column(
            children: [
              SsDateField(value: null, onChanged: (_) {}),
              const SsSearchField(),
              SsMonthSwitcher(month: DateTime(2026, 10), onChanged: (_) {}),
            ],
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Tomorrow'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.byTooltip('Previous month'), findsOneWidget);
    });

    testWidgets('SsSyncStatus e SsOfflineBanner em espanhol', (t) async {
      await t.pumpWidget(
        _app(
          locale: const Locale('es'),
          const Column(
            children: [
              SsSyncStatus(state: SsSyncState.synced),
              Expanded(child: SsOfflineBanner(offline: true, child: SizedBox())),
            ],
          ),
        ),
      );
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Todo guardado'), findsOneWidget);
      expect(find.textContaining('Sin conexión'), findsOneWidget);
    });

    testWidgets('SsMoneyField com SsFormatsScope', (t) async {
      await t.pumpWidget(
        _app(
          SsFormatsScope(
            formats: SsFormats.usd,
            child: SsMoneyField(label: 'Price', cents: 123456, onChanged: (_) {}),
          ),
        ),
      );
      expect(find.text('1,234.56'), findsOneWidget);
    });
  });
  group('widgets da v0.10 em en e es', () {
    testWidgets('SsDeviceTile indisponível e stateLine', (t) async {
      await t.pumpWidget(
        _app(
          const Column(
            children: [
              SsDeviceTile(icon: Icons.lightbulb, name: 'Lamp', status: SsDeviceStatus.unavailable),
              SsDeviceTile(icon: Icons.lightbulb, name: 'Plug', status: SsDeviceStatus.error),
            ],
          ),
        ),
      );
      expect(find.text('Unavailable'), findsOneWidget);
      expect(find.text('No response'), findsOneWidget);
      await t.pumpWidget(
        _app(
          locale: const Locale('es'),
          const SsDeviceTile(icon: Icons.lightbulb, name: 'Lámpara', status: SsDeviceStatus.unavailable),
        ),
      );
      expect(find.text('No disponible'), findsOneWidget);
      const tile = SsDeviceTile(icon: Icons.abc, name: 'x', state: 'On', status: SsDeviceStatus.pending);
      expect(tile.stateLine(), 'On · Enviando…');
      expect(tile.stateLine(SsStrings.en), 'On · Sending…');
    });

    testWidgets('SsLogbook vazio e com hoje/ontem', (t) async {
      await t.pumpWidget(_app(const SsLogbook(entries: [])));
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Nothing logged yet'), findsOneWidget);
      await t.pumpWidget(_app(locale: const Locale('es'), const SsLogbook(entries: [])));
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Aún no hay registros'), findsOneWidget);
      final agora = DateTime(2026, 11, 4, 15);
      await t.pumpWidget(
        _app(
          SsLogbook(
            now: agora,
            entries: [
              SsLogEntry(at: agora.subtract(const Duration(hours: 1)), title: 'a'),
              SsLogEntry(at: agora.subtract(const Duration(days: 1)), title: 'b'),
            ],
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('YESTERDAY'), findsOneWidget);
      expect(find.text('Start of the log'), findsOneWidget);
    });

    testWidgets('SsCodeKeypad', (t) async {
      Future<bool> nega(String _) async => false;
      await t.pumpWidget(_app(SingleChildScrollView(child: SsCodeKeypad(length: 1, onSubmit: nega))));
      expect(find.bySemanticsLabel('Delete'), findsOneWidget);
      await t.tap(find.text('1'));
      await t.pump();
      await t.pump();
      expect(find.text('Wrong code'), findsOneWidget);
      await t.pumpAndSettle();

      await t.pumpWidget(
        _app(
          locale: const Locale('es'),
          SingleChildScrollView(child: SsCodeKeypad(onSubmit: nega)),
        ),
      );
      expect(find.bySemanticsLabel('Borrar'), findsOneWidget);
      expect(find.text('Confirmar'), findsOneWidget);
      await t.pumpAndSettle();
    });

    testWidgets('SsThermostat: modos e rótulos; rótulo passado ainda manda', (t) async {
      await t.pumpWidget(_app(SingleChildScrollView(child: SsThermostat(target: 21, current: 20, onChanged: (_) {}))));
      for (final m in ['Off', 'Heat', 'Cool', 'Auto']) {
        expect(find.text(m), findsOneWidget);
      }
      expect(find.bySemanticsLabel('Increase'), findsOneWidget);
      expect(find.text('Now 20°'), findsOneWidget);
      await t.pumpWidget(
        _app(
          locale: const Locale('es'),
          SingleChildScrollView(
            child: SsThermostat(target: 21, onChanged: (_) {}, lessLabel: 'Menos'),
          ),
        ),
      );
      for (final m in ['Apagado', 'Calor', 'Frío', 'Automático']) {
        expect(find.text(m), findsOneWidget);
      }
      expect(find.bySemanticsLabel('Menos'), findsOneWidget);
      expect(find.bySemanticsLabel('Aumentar'), findsOneWidget);
      expect(SsThermostatMode.heat.labelIn(), 'Aquecer');
      expect(const SsThermostatMode('dry', 'Dry').labelIn(SsStrings.es), 'Dry');
      await t.pumpAndSettle();
    });

    testWidgets('SsWeekdayPicker', (t) async {
      await t.pumpWidget(_app(SsWeekdayPicker(value: const {1}, onChanged: (_) {})));
      expect(find.text('Every day'), findsOneWidget);
      expect(find.text('Weekdays'), findsOneWidget);
      expect(find.text('Weekend'), findsOneWidget);
      expect(find.text('M'), findsOneWidget);
      expect(find.text('W'), findsOneWidget);
      await t.pumpWidget(
        _app(
          locale: const Locale('es'),
          SsWeekdayPicker(value: const {}, onChanged: (_) {}),
        ),
      );
      expect(find.text('Todos los días'), findsOneWidget);
      expect(find.text('Fin de semana'), findsOneWidget);
      expect(find.text('X'), findsOneWidget);
    });

    testWidgets('SsWeatherCard, SsScanRadar e SsClock', (t) async {
      await t.pumpWidget(
        _app(
          SingleChildScrollView(
            child: Column(
              children: [
                const SsWeatherCard(temperature: 21, condition: SsWeatherCondition.rain, humidity: 80),
                const SsScanRadar(state: SsScanState.empty, animate: false),
                SsClock(now: DateTime(2026, 11, 4, 9, 5)),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Rain'), findsWidgets);
      expect(find.text('Humidity'), findsOneWidget);
      expect(find.text('Nothing found'), findsOneWidget);
      expect(find.text('Wednesday, November 4'), findsOneWidget);
      await t.pumpWidget(
        _app(
          locale: const Locale('es'),
          SingleChildScrollView(
            child: Column(
              children: [
                const SsScanRadar(state: SsScanState.empty, animate: false, onRetry: _nada),
                SsClock(now: DateTime(2026, 11, 4, 9, 5)),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Buscar de nuevo'), findsOneWidget);
      expect(find.text('miércoles, 4 de noviembre'), findsOneWidget);
      expect(SsCameraTile.formatAge(const Duration(seconds: 12), SsStrings.en), '12 s ago');
      expect(SsScanRadar.foundPt(3), '3 encontrados');
      expect(SsStrings.en.foundCount(3), '3 found');
    });
  });
}

void _nada() {}
