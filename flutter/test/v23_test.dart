import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// v0.23 · showSsTimePicker: o relógio do pacote com os textos do SsStrings.
void main() {
  Widget app(Widget child, {Locale locale = const Locale('pt')}) => MaterialApp(
    theme: AppTheme.light,
    locale: locale,
    supportedLocales: const [Locale('pt'), Locale('en'), Locale('es')],
    localizationsDelegates: const [
      SsStrings.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  );

  testWidgets('abre com "Escolher hora", 24 h, e devolve a hora ao confirmar', (tester) async {
    TimeOfDay? escolhida;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => SsButton(
            label: 'Hora',
            onPressed: () async =>
                escolhida = await showSsTimePicker(context, initialTime: const TimeOfDay(hour: 18, minute: 30)),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Hora'));
    await tester.pumpAndSettle();
    expect(find.text('Escolher hora'), findsOneWidget);
    expect(find.text('18'), findsWidgets);
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(escolhida, const TimeOfDay(hour: 18, minute: 30));
  });

  testWidgets('cancelar devolve nulo; textos em inglês', (tester) async {
    TimeOfDay? escolhida = const TimeOfDay(hour: 1, minute: 0);
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) =>
              SsButton(label: 'Time', onPressed: () async => escolhida = await showSsTimePicker(context)),
        ),
        locale: const Locale('en'),
      ),
    );
    await tester.tap(find.text('Time'));
    await tester.pumpAndSettle();
    expect(find.text('Pick a time'), findsOneWidget);
    await tester.tap(find.text(SsStrings.en.cancel));
    await tester.pumpAndSettle();
    expect(escolhida, isNull);
  });
}
