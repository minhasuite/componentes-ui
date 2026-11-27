// v1.13.0 "confiança na IA e suíte": o retorno do valor falado (par do ss-spoken-amount do web). O SsMoneyField(onVoice:)
// mostra embaixo do campo o que ouviu e o que entendeu; o reconhecimento de voz é do app.
import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';
import '../density.dart';
import '../ss_strings.dart';
import 'strings.dart';

/// "Ouvi “doze e cinquenta” · R\$ 12,50" (ou "Não entendi o valor em “…”", em âmbar), região viva para o leitor de
/// tela. [cents] nulo = não entendeu; [listening] mostra "Ouvindo…".
class SsSpokenAmount extends StatelessWidget {
  const SsSpokenAmount({super.key, this.text, this.cents, this.listening = false, this.formats});

  final String? text;
  final int? cents;
  final bool listening;
  final SsFormats? formats;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final t = SsTrustStrings.of(context);
    final f = formats ?? SsFormats.of(context);
    final ok = cents != null;
    final heard = text ?? '';
    final msg = listening
        ? t.voiceListening
        : ok
        ? '${SsTrustStrings.fill(t.voiceHeard, {'text': heard})} · ${f.money(cents)}'
        : SsTrustStrings.fill(t.voiceNotUnderstood, {'text': heard});
    final color = listening || ok ? c.muted : c.aquecText;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: EdgeInsets.only(top: d.space(4)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(listening ? Icons.graphic_eq_rounded : Icons.mic_none_rounded, size: 16, color: color),
            SizedBox(width: d.space(6)),
            Expanded(
              child: Text(
                msg,
                style: TextStyle(fontSize: AppType.meta, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
