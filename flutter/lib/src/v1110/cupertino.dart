// v1.11.0: as variantes da Apple das peças do pacote (não exportado; as peças chamam daqui quando
// `SsPlatform.cupertino(context, adaptive: …)`). As peças Cupertino vêm do pacote `cupertino_ui` (no
// Flutter 3.50 o `package:flutter/cupertino.dart` está obsoleto, como o Material saiu para o `material_ui`).
//
// Tudo passa por [ssCupertinoTheme]: brilho, cor da marca e a fonte do tema (Manrope) no lugar da fonte do
// sistema, para a peça do iOS falar a mesma língua visual do resto do app.
import 'package:cupertino_ui/cupertino_ui.dart'
    show
        CupertinoActionSheet,
        CupertinoActionSheetAction,
        CupertinoAlertDialog,
        CupertinoColors,
        CupertinoDatePicker,
        CupertinoDatePickerMode,
        CupertinoDialogAction,
        CupertinoSliverRefreshControl,
        CupertinoTextThemeData,
        CupertinoTheme,
        CupertinoThemeData,
        DatePickerDateOrder,
        showCupertinoDialog,
        showCupertinoModalPopup;
import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart' show SsHaptics;
import '../motion_view.dart';
import '../ss_strings.dart';

/// A fonte do tema (a Manrope do pacote).
String? ssThemeFont(BuildContext context) => Theme.of(context).textTheme.bodyMedium?.fontFamily;

/// [child] com o `CupertinoTheme` da suíte: brilho do tema, a marca como cor primária e a Manrope.
Widget ssCupertinoTheme(BuildContext context, Widget child) {
  final c = SsColors.of(context);
  final font = ssThemeFont(context);
  final texto = TextStyle(fontFamily: font, color: c.ink, fontSize: 17, letterSpacing: -.2);
  return CupertinoTheme(
    data: CupertinoThemeData(
      brightness: c.isDark ? Brightness.dark : Brightness.light,
      primaryColor: c.accent,
      primaryContrastingColor: AppColors.onDark,
      scaffoldBackgroundColor: c.surface,
      barBackgroundColor: c.surface,
      textTheme: CupertinoTextThemeData(
        primaryColor: c.accent,
        textStyle: texto,
        actionTextStyle: texto.copyWith(color: c.accent),
        pickerTextStyle: texto.copyWith(fontSize: 21),
        dateTimePickerTextStyle: texto.copyWith(fontSize: 21),
      ),
    ),
    child: child,
  );
}

// ── Roda de data e hora numa folha ────────────────────────────────────────

/// Folha com a roda do `CupertinoDatePicker`: Cancelar à esquerda, o título no meio e Confirmar à direita
/// (a ação principal, na cor da marca). Devolve o valor da roda ou nulo.
Future<DateTime?> ssWheelSheet(
  BuildContext context, {
  required CupertinoDatePickerMode mode,
  required DateTime initial,
  DateTime? minimum,
  DateTime? maximum,
  bool use24h = true,
  String? title,
  String? confirmText,
  String? cancelText,
  bool Function(DateTime day)? selectableDayPredicate,
}) {
  final s = SsStrings.of(context);
  return showModalBottomSheet<DateTime>(
    context: context,
    useSafeArea: true,
    showDragHandle: false,
    sheetAnimationStyle: SsOverlayMotion.sheet(context),
    builder: (context) => WheelSheetView(
      mode: mode,
      initial: initial,
      minimum: minimum,
      maximum: maximum,
      use24h: use24h,
      title: title ?? (mode == CupertinoDatePickerMode.time ? s.pickTime : s.pickDate),
      confirmText: confirmText ?? s.confirm,
      cancelText: cancelText ?? s.cancel,
      selectableDayPredicate: selectableDayPredicate,
    ),
  );
}

/// O corpo da [ssWheelSheet] (o catálogo mostra solto).
class WheelSheetView extends StatefulWidget {
  const WheelSheetView({
    super.key,
    required this.mode,
    required this.initial,
    required this.minimum,
    required this.maximum,
    required this.use24h,
    required this.title,
    required this.confirmText,
    required this.cancelText,
    required this.selectableDayPredicate,
  });

  final CupertinoDatePickerMode mode;
  final DateTime initial;
  final DateTime? minimum;
  final DateTime? maximum;
  final bool use24h;
  final String title;
  final String confirmText;
  final String cancelText;
  final bool Function(DateTime day)? selectableDayPredicate;

  @override
  State<WheelSheetView> createState() => _WheelSheetState();
}

class _WheelSheetState extends State<WheelSheetView> {
  late DateTime _v = widget.initial;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final font = ssThemeFont(context);
    final s = SsStrings.of(context);
    TextStyle botao(bool forte) => TextStyle(
      fontFamily: font,
      fontSize: d.font(AppType.body),
      fontWeight: forte ? FontWeight.w800 : FontWeight.w600,
      color: forte ? c.accent : c.ink2,
    );
    final data = widget.mode == CupertinoDatePickerMode.date;
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(widget.cancelText, style: botao(false)),
                ),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        fontFamily: font,
                        color: c.ink,
                        fontSize: d.font(AppType.body),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  key: const ValueKey('ss-wheel-confirm'),
                  onPressed: () {
                    SsHaptics.selection();
                    Navigator.pop(context, _v);
                  },
                  child: Text(widget.confirmText, style: botao(true)),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: c.line),
          SizedBox(
            // A roda do iOS tem 216 de altura; com texto grande ela cresce junto.
            height: 216 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4),
            child: ssCupertinoTheme(
              context,
              CupertinoDatePicker(
                key: const ValueKey('ss-wheel'),
                mode: widget.mode,
                initialDateTime: _v,
                minimumDate: widget.minimum,
                maximumDate: widget.maximum,
                use24hFormat: widget.use24h,
                dateOrder: data && s.locale.languageCode != 'en' ? DatePickerDateOrder.dmy : null,
                selectableDayPredicate: widget.selectableDayPredicate,
                onDateTimeChanged: (v) => _v = v,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Folha de ação ─────────────────────────────────────────────────────────

/// Uma linha da folha de ação.
typedef SsChoice<T> = ({String label, T value, bool destructive, bool checked, IconData? icon});

/// A folha de ação do iOS (`CupertinoActionSheet`): as escolhas, a destrutiva em vermelho e o Cancelar
/// separado embaixo. Devolve o valor da linha tocada ou nulo.
Future<T?> ssActionSheet<T>(
  BuildContext context, {
  String? title,
  String? message,
  required List<SsChoice<T>> choices,
  String? cancelLabel,
}) {
  SsHaptics.light();
  return showCupertinoModalPopup<T>(
    context: context,
    builder: (ctx) => ssActionSheetView<T>(
      context,
      title: title,
      message: message,
      choices: choices,
      cancelLabel: cancelLabel,
      onDone: (v) => Navigator.pop(ctx, v),
    ),
  );
}

/// O desenho da [ssActionSheet] (o catálogo mostra solto). [onDone] recebe a escolha, ou nulo no Cancelar.
Widget ssActionSheetView<T>(
  BuildContext context, {
  String? title,
  String? message,
  required List<SsChoice<T>> choices,
  String? cancelLabel,
  required void Function(T? value) onDone,
}) {
  final s = SsStrings.of(context);
  final font = ssThemeFont(context);
  final c = SsColors.of(context);
  final vermelho = CupertinoColors.systemRed.resolveFrom(context);
  Widget linha(SsChoice<T> e) => CupertinoActionSheetAction(
    isDestructiveAction: e.destructive,
    onPressed: () => onDone(e.value),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (e.icon != null) ...[
          Icon(e.icon, size: 20, color: e.destructive ? vermelho : c.accent),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            e.label,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: font),
          ),
        ),
        if (e.checked) ...[const SizedBox(width: 8), Icon(Icons.check_rounded, size: 20, color: c.accent)],
      ],
    ),
  );
  return ssCupertinoTheme(
    context,
    CupertinoActionSheet(
      title: title == null ? null : Text(title, style: TextStyle(fontFamily: font)),
      message: message == null ? null : Text(message, style: TextStyle(fontFamily: font)),
      actions: [for (final e in choices) linha(e)],
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => onDone(null),
        child: Text(cancelLabel ?? s.cancel, style: TextStyle(fontFamily: font)),
      ),
    ),
  );
}

// ── Confirmação ───────────────────────────────────────────────────────────

/// O alerta do iOS (`CupertinoAlertDialog`): Cancelar à esquerda e a confirmação à direita; com [danger],
/// a confirmação em vermelho (destrutiva) e o Cancelar em negrito (a escolha segura).
Future<bool> ssCupertinoConfirm(
  BuildContext context, {
  required String title,
  String? message,
  String? confirmLabel,
  String? cancelLabel,
  bool danger = false,
  IconData? icon,
}) async {
  final r = await showCupertinoDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => ssCupertinoConfirmView(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      danger: danger,
      icon: icon,
      onDone: (v) => Navigator.pop(ctx, v),
    ),
  );
  return r ?? false;
}

/// O desenho do [ssCupertinoConfirm] (o catálogo mostra solto).
Widget ssCupertinoConfirmView(
  BuildContext context, {
  required String title,
  String? message,
  String? confirmLabel,
  String? cancelLabel,
  bool danger = false,
  IconData? icon,
  required void Function(bool ok) onDone,
}) {
  final s = SsStrings.of(context);
  final font = ssThemeFont(context);
  final c = SsColors.of(context);
  return ssCupertinoTheme(
    context,
    CupertinoAlertDialog(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 28, color: danger ? CupertinoColors.systemRed.resolveFrom(context) : c.accent),
            const SizedBox(height: 8),
          ],
          Text(title, style: TextStyle(fontFamily: font)),
        ],
      ),
      content: message == null ? null : Text(message, style: TextStyle(fontFamily: font)),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: danger,
          onPressed: () => onDone(false),
          child: Text(
            cancelLabel ?? s.cancel,
            style: TextStyle(fontFamily: font, fontWeight: danger ? FontWeight.w700 : null),
          ),
        ),
        CupertinoDialogAction(
          key: const ValueKey('ss-confirm-ok'),
          isDefaultAction: !danger,
          isDestructiveAction: danger,
          onPressed: () {
            if (danger) SsHaptics.warning();
            onDone(true);
          },
          child: Text(
            confirmLabel ?? s.confirm,
            style: TextStyle(fontFamily: font, fontWeight: danger ? null : FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

// ── Puxar para atualizar ──────────────────────────────────────────────────

/// Rolagem com elástico que rola sempre (o puxar do iOS precisa do vão do elástico, até com lista curta).
const ssBouncingAlways = AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());

/// O controle de puxar do iOS (a rodinha no vão do elástico), no tema da suíte.
Widget ssCupertinoRefresh(BuildContext context, Future<void> Function() onRefresh) => CupertinoSliverRefreshControl(
  key: const ValueKey('ss-cupertino-refresh'),
  onRefresh: onRefresh,
  builder: (ctx, mode, pulled, trigger, extent) => ssCupertinoTheme(
    context,
    CupertinoSliverRefreshControl.buildRefreshIndicator(ctx, mode, pulled, trigger, extent),
  ),
);
