// v1.13.0 "confiança na IA e suíte": os textos das peças novas (explicar o valor, prévia da ação da IA, desde a
// última visita, continuar no outro aparelho, a suíte, o conflito, o valor falado e o modo discreto automático).
// As mesmas chaves, em snake_case, estão no `componentes_ui.trust.*` da gem. O idioma segue o do [SsStrings].
import 'package:material_ui/material_ui.dart';

import '../ss_strings.dart';

/// Textos da v1.13: `SsTrustStrings.of(context)` (pt, en ou es pelo idioma do [SsStrings]). Moldes com `%{x}`
/// passam pelo [fill].
class SsTrustStrings {
  const SsTrustStrings({
    required this.explainOpen,
    required this.explainHint,
    required this.explainTitle,
    required this.explainComposition,
    required this.explainMore,
    required this.explainSeeAll,
    required this.explainAskAi,
    required this.explainThinking,
    required this.explainAiError,
    required this.explainRetry,
    required this.explainAiNote,
    required this.previewTitle,
    required this.previewSubtitle,
    required this.previewSelected,
    required this.previewSelectAll,
    required this.previewSelectNone,
    required this.previewApply,
    required this.previewAdjust,
    required this.previewCancel,
    required this.previewBefore,
    required this.previewAfter,
    required this.previewAdded,
    required this.previewRemoved,
    required this.previewChanged,
    required this.previewEmpty,
    required this.previewApplied,
    required this.previewAppliedOne,
    required this.previewNone,
    required this.previewReview,
    required this.previewInclude,
    required this.sinceTitle,
    required this.sinceToday,
    required this.sinceYesterday,
    required this.sinceWeekday,
    required this.sinceDate,
    required this.sinceGotIt,
    required this.sinceOpen,
    required this.continuePhone,
    required this.continueComputer,
    required this.continuePhoneHint,
    required this.continueComputerHint,
    required this.continueLink,
    required this.continueCopy,
    required this.continueCopied,
    required this.continueShare,
    required this.continueQr,
    required this.continueLong,
    required this.suiteTitle,
    required this.suiteOpen,
    required this.suiteYours,
    required this.suiteDiscover,
    required this.suiteDiscoverAction,
    required this.suiteCurrent,
    required this.suiteUsed,
    required this.suiteNever,
    required this.suiteBadge,
    required this.suiteBadgeOne,
    required this.conflictTitle,
    required this.conflictHint,
    required this.conflictMine,
    required this.conflictTheirs,
    required this.conflictBy,
    required this.conflictKeepMine,
    required this.conflictKeepTheirs,
    required this.conflictSave,
    required this.conflictSame,
    required this.conflictSameOne,
    required this.conflictEmpty,
    required this.conflictCount,
    required this.conflictCountOne,
    required this.conflictResolve,
    required this.voiceSpeak,
    required this.voiceListening,
    required this.voiceHeard,
    required this.voiceNotUnderstood,
    required this.privacyAuto,
    required this.privacyReasons,
  });

  /// O nome do gesto/botão que abre a explicação ("Ver de onde vem este valor").
  final String explainOpen;

  /// A dica do leitor de tela no app ("Toque e segure para ver de onde vem").
  final String explainHint;
  final String explainTitle;
  final String explainComposition;

  /// "e mais %{count}".
  final String explainMore;
  final String explainSeeAll;
  final String explainAskAi;
  final String explainThinking;
  final String explainAiError;
  final String explainRetry;
  final String explainAiNote;

  final String previewTitle;
  final String previewSubtitle;

  /// "%{count} de %{total} marcadas".
  final String previewSelected;
  final String previewSelectAll;
  final String previewSelectNone;
  final String previewApply;
  final String previewAdjust;
  final String previewCancel;
  final String previewBefore;
  final String previewAfter;
  final String previewAdded;
  final String previewRemoved;
  final String previewChanged;
  final String previewEmpty;

  /// "%{count} alterações aplicadas" (e o [previewAppliedOne]).
  final String previewApplied;
  final String previewAppliedOne;
  final String previewNone;
  final String previewReview;

  /// "Incluir %{title}" (o nome da caixa de marcar de cada alteração).
  final String previewInclude;

  final String sinceTitle;

  /// "Desde hoje às %{time}".
  final String sinceToday;

  /// "Desde ontem às %{time}".
  final String sinceYesterday;

  /// "Desde %{weekday} às %{time}".
  final String sinceWeekday;

  /// "Desde %{date}".
  final String sinceDate;
  final String sinceGotIt;
  final String sinceOpen;

  final String continuePhone;
  final String continueComputer;
  final String continuePhoneHint;
  final String continueComputerHint;
  final String continueLink;
  final String continueCopy;
  final String continueCopied;
  final String continueShare;
  final String continueQr;
  final String continueLong;

  final String suiteTitle;
  final String suiteOpen;
  final String suiteYours;
  final String suiteDiscover;
  final String suiteDiscoverAction;
  final String suiteCurrent;

  /// "Usado %{ago}" (com o "há 3 dias" do tempo relativo).
  final String suiteUsed;
  final String suiteNever;

  /// "%{count} avisos" (e o [suiteBadgeOne]).
  final String suiteBadge;
  final String suiteBadgeOne;

  final String conflictTitle;
  final String conflictHint;
  final String conflictMine;
  final String conflictTheirs;

  /// "por %{name}".
  final String conflictBy;
  final String conflictKeepMine;
  final String conflictKeepTheirs;
  final String conflictSave;

  /// "%{count} campos iguais nas duas versões" (e o [conflictSameOne]).
  final String conflictSame;
  final String conflictSameOne;
  final String conflictEmpty;

  /// "%{count} registros em conflito" (e o [conflictCountOne]).
  final String conflictCount;
  final String conflictCountOne;
  final String conflictResolve;

  final String voiceSpeak;
  final String voiceListening;

  /// "Ouvi “%{text}”".
  final String voiceHeard;

  /// "Não entendi o valor em “%{text}”. Fale de novo ou digite."
  final String voiceNotUnderstood;

  final String privacyAuto;

  /// share, background, face_down → o motivo do modo discreto automático.
  final Map<String, String> privacyReasons;

  /// O texto com %{x} trocado pelos valores.
  static String fill(String template, Map<String, Object> values) =>
      template.replaceAllMapped(RegExp(r'%\{(\w+)\}'), (m) => '${values[m.group(1)] ?? ''}');

  static SsTrustStrings of(BuildContext context) => forLocale(SsStrings.of(context).locale);

  static SsTrustStrings forLocale(Locale l) => switch (l.languageCode) {
    'en' => en,
    'es' => es,
    _ => pt,
  };

  static const pt = SsTrustStrings(
    explainOpen: 'Ver de onde vem este valor',
    explainHint: 'Toque e segure para ver de onde vem',
    explainTitle: 'De onde vem este valor',
    explainComposition: 'O que compõe',
    explainMore: 'e mais %{count}',
    explainSeeAll: 'Ver todos',
    explainAskAi: 'Explicar com IA',
    explainThinking: 'A IA está analisando os números…',
    explainAiError: 'Não deu para explicar agora.',
    explainRetry: 'Tentar de novo',
    explainAiNote: 'Explicação da IA. Confira com os números acima.',
    previewTitle: 'Antes de aplicar',
    previewSubtitle: 'Confira o que a IA vai mudar. Desmarque o que não quer.',
    previewSelected: '%{count} de %{total} marcadas',
    previewSelectAll: 'Marcar todas',
    previewSelectNone: 'Desmarcar todas',
    previewApply: 'Aplicar',
    previewAdjust: 'Ajustar',
    previewCancel: 'Cancelar',
    previewBefore: 'Antes',
    previewAfter: 'Depois',
    previewAdded: 'Novo',
    previewRemoved: 'Removido',
    previewChanged: 'Alterado',
    previewEmpty: '(vazio)',
    previewApplied: '%{count} alterações aplicadas',
    previewAppliedOne: '1 alteração aplicada',
    previewNone: 'Marque ao menos uma alteração para aplicar.',
    previewReview: 'Ver alterações',
    previewInclude: 'Incluir %{title}',
    sinceTitle: 'Enquanto você esteve fora',
    sinceToday: 'Desde hoje às %{time}',
    sinceYesterday: 'Desde ontem às %{time}',
    sinceWeekday: 'Desde %{weekday} às %{time}',
    sinceDate: 'Desde %{date}',
    sinceGotIt: 'Entendi',
    sinceOpen: 'Ver',
    continuePhone: 'Continuar no celular',
    continueComputer: 'Continuar no computador',
    continuePhoneHint: 'Aponte a câmera do celular para o código. Abre nesta mesma tela, do jeito que está.',
    continueComputerHint: 'Abra este endereço no navegador do computador. Abre nesta mesma tela, do jeito que está.',
    continueLink: 'Endereço',
    continueCopy: 'Copiar link',
    continueCopied: 'Link copiado',
    continueShare: 'Compartilhar',
    continueQr: 'QR Code para abrir no outro aparelho',
    continueLong: 'O endereço é longo. Se o código não ler, use o link.',
    suiteTitle: 'Apps da suíte',
    suiteOpen: 'Abrir os apps da suíte',
    suiteYours: 'Seus apps',
    suiteDiscover: 'Conheça também',
    suiteDiscoverAction: 'Conhecer',
    suiteCurrent: 'Você está aqui',
    suiteUsed: 'Usado %{ago}',
    suiteNever: 'Ainda não usado',
    suiteBadge: '%{count} avisos',
    suiteBadgeOne: '1 aviso',
    conflictTitle: 'Este registro mudou em dois lugares',
    conflictHint: 'Escolha, campo a campo, o que fica.',
    conflictMine: 'Sua versão',
    conflictTheirs: 'Versão do servidor',
    conflictBy: 'por %{name}',
    conflictKeepMine: 'Ficar com a minha',
    conflictKeepTheirs: 'Ficar com a do servidor',
    conflictSave: 'Salvar escolha',
    conflictSame: '%{count} campos iguais nas duas versões',
    conflictSameOne: '1 campo igual nas duas versões',
    conflictEmpty: '(vazio)',
    conflictCount: '%{count} registros em conflito',
    conflictCountOne: '1 registro em conflito',
    conflictResolve: 'Resolver',
    voiceSpeak: 'Falar o valor',
    voiceListening: 'Ouvindo…',
    voiceHeard: 'Ouvi “%{text}”',
    voiceNotUnderstood: 'Não entendi o valor em “%{text}”. Fale de novo ou digite.',
    privacyAuto: 'Valores ocultos automaticamente',
    privacyReasons: {
      'share': 'tela compartilhada',
      'background': 'app em segundo plano',
      'face_down': 'celular virado para baixo',
    },
  );

  static const en = SsTrustStrings(
    explainOpen: 'See where this number comes from',
    explainHint: 'Touch and hold to see where it comes from',
    explainTitle: 'Where this number comes from',
    explainComposition: 'What makes it up',
    explainMore: 'and %{count} more',
    explainSeeAll: 'See all',
    explainAskAi: 'Explain with AI',
    explainThinking: 'The AI is looking at the numbers…',
    explainAiError: 'Could not explain right now.',
    explainRetry: 'Try again',
    explainAiNote: 'AI explanation. Check it against the numbers above.',
    previewTitle: 'Before applying',
    previewSubtitle: 'Check what the AI will change. Uncheck what you do not want.',
    previewSelected: '%{count} of %{total} selected',
    previewSelectAll: 'Select all',
    previewSelectNone: 'Clear all',
    previewApply: 'Apply',
    previewAdjust: 'Adjust',
    previewCancel: 'Cancel',
    previewBefore: 'Before',
    previewAfter: 'After',
    previewAdded: 'New',
    previewRemoved: 'Removed',
    previewChanged: 'Changed',
    previewEmpty: '(empty)',
    previewApplied: '%{count} changes applied',
    previewAppliedOne: '1 change applied',
    previewNone: 'Select at least one change to apply.',
    previewReview: 'Review changes',
    previewInclude: 'Include %{title}',
    sinceTitle: 'While you were away',
    sinceToday: 'Since today at %{time}',
    sinceYesterday: 'Since yesterday at %{time}',
    sinceWeekday: 'Since %{weekday} at %{time}',
    sinceDate: 'Since %{date}',
    sinceGotIt: 'Got it',
    sinceOpen: 'View',
    continuePhone: 'Continue on your phone',
    continueComputer: 'Continue on your computer',
    continuePhoneHint: 'Point your phone camera at the code. It opens this same screen, as it is now.',
    continueComputerHint: 'Open this address in your computer browser. It opens this same screen, as it is now.',
    continueLink: 'Address',
    continueCopy: 'Copy link',
    continueCopied: 'Link copied',
    continueShare: 'Share',
    continueQr: 'QR code to open on the other device',
    continueLong: 'The address is long. If the code does not scan, use the link.',
    suiteTitle: 'Suite apps',
    suiteOpen: 'Open the suite apps',
    suiteYours: 'Your apps',
    suiteDiscover: 'You may also like',
    suiteDiscoverAction: 'Learn more',
    suiteCurrent: 'You are here',
    suiteUsed: 'Used %{ago}',
    suiteNever: 'Not used yet',
    suiteBadge: '%{count} notices',
    suiteBadgeOne: '1 notice',
    conflictTitle: 'This record changed in two places',
    conflictHint: 'Choose, field by field, what stays.',
    conflictMine: 'Your version',
    conflictTheirs: 'Server version',
    conflictBy: 'by %{name}',
    conflictKeepMine: 'Keep mine',
    conflictKeepTheirs: 'Keep the server one',
    conflictSave: 'Save choice',
    conflictSame: '%{count} fields are the same in both versions',
    conflictSameOne: '1 field is the same in both versions',
    conflictEmpty: '(empty)',
    conflictCount: '%{count} records in conflict',
    conflictCountOne: '1 record in conflict',
    conflictResolve: 'Resolve',
    voiceSpeak: 'Say the amount',
    voiceListening: 'Listening…',
    voiceHeard: 'Heard “%{text}”',
    voiceNotUnderstood: 'Could not get the amount in “%{text}”. Say it again or type it.',
    privacyAuto: 'Values hidden automatically',
    privacyReasons: {'share': 'screen shared', 'background': 'app in the background', 'face_down': 'phone face down'},
  );

  static const es = SsTrustStrings(
    explainOpen: 'Ver de dónde viene este valor',
    explainHint: 'Mantén pulsado para ver de dónde viene',
    explainTitle: 'De dónde viene este valor',
    explainComposition: 'Qué lo compone',
    explainMore: 'y %{count} más',
    explainSeeAll: 'Ver todos',
    explainAskAi: 'Explicar con IA',
    explainThinking: 'La IA está analizando los números…',
    explainAiError: 'No se pudo explicar ahora.',
    explainRetry: 'Intentar de nuevo',
    explainAiNote: 'Explicación de la IA. Compárala con los números de arriba.',
    previewTitle: 'Antes de aplicar',
    previewSubtitle: 'Revisa lo que la IA va a cambiar. Desmarca lo que no quieras.',
    previewSelected: '%{count} de %{total} marcadas',
    previewSelectAll: 'Marcar todas',
    previewSelectNone: 'Desmarcar todas',
    previewApply: 'Aplicar',
    previewAdjust: 'Ajustar',
    previewCancel: 'Cancelar',
    previewBefore: 'Antes',
    previewAfter: 'Después',
    previewAdded: 'Nuevo',
    previewRemoved: 'Eliminado',
    previewChanged: 'Cambiado',
    previewEmpty: '(vacío)',
    previewApplied: '%{count} cambios aplicados',
    previewAppliedOne: '1 cambio aplicado',
    previewNone: 'Marca al menos un cambio para aplicar.',
    previewReview: 'Ver cambios',
    previewInclude: 'Incluir %{title}',
    sinceTitle: 'Mientras no estabas',
    sinceToday: 'Desde hoy a las %{time}',
    sinceYesterday: 'Desde ayer a las %{time}',
    sinceWeekday: 'Desde el %{weekday} a las %{time}',
    sinceDate: 'Desde el %{date}',
    sinceGotIt: 'Entendido',
    sinceOpen: 'Ver',
    continuePhone: 'Continuar en el móvil',
    continueComputer: 'Continuar en el ordenador',
    continuePhoneHint: 'Apunta la cámara del móvil al código. Abre esta misma pantalla, tal como está.',
    continueComputerHint: 'Abre esta dirección en el navegador del ordenador. Abre esta misma pantalla, tal como está.',
    continueLink: 'Dirección',
    continueCopy: 'Copiar enlace',
    continueCopied: 'Enlace copiado',
    continueShare: 'Compartir',
    continueQr: 'Código QR para abrir en el otro dispositivo',
    continueLong: 'La dirección es larga. Si el código no se lee, usa el enlace.',
    suiteTitle: 'Apps de la suite',
    suiteOpen: 'Abrir las apps de la suite',
    suiteYours: 'Tus apps',
    suiteDiscover: 'Conoce también',
    suiteDiscoverAction: 'Conocer',
    suiteCurrent: 'Estás aquí',
    suiteUsed: 'Usada %{ago}',
    suiteNever: 'Aún sin usar',
    suiteBadge: '%{count} avisos',
    suiteBadgeOne: '1 aviso',
    conflictTitle: 'Este registro cambió en dos lugares',
    conflictHint: 'Elige, campo por campo, qué se queda.',
    conflictMine: 'Tu versión',
    conflictTheirs: 'Versión del servidor',
    conflictBy: 'por %{name}',
    conflictKeepMine: 'Quedarme con la mía',
    conflictKeepTheirs: 'Quedarme con la del servidor',
    conflictSave: 'Guardar elección',
    conflictSame: '%{count} campos iguales en las dos versiones',
    conflictSameOne: '1 campo igual en las dos versiones',
    conflictEmpty: '(vacío)',
    conflictCount: '%{count} registros en conflicto',
    conflictCountOne: '1 registro en conflicto',
    conflictResolve: 'Resolver',
    voiceSpeak: 'Decir el valor',
    voiceListening: 'Escuchando…',
    voiceHeard: 'Oí “%{text}”',
    voiceNotUnderstood: 'No entendí el valor en “%{text}”. Dilo de nuevo o escríbelo.',
    privacyAuto: 'Valores ocultos automáticamente',
    privacyReasons: {
      'share': 'pantalla compartida',
      'background': 'app en segundo plano',
      'face_down': 'móvil boca abajo',
    },
  );

  /// "18h" / "18h30" (pt), "6 PM" / "6:30 PM" (en), "18:00" (es).
  String clock(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    if (identical(this, en)) {
      final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
      return '${d.minute == 0 ? '$h' : '$h:${two(d.minute)}'} ${d.hour < 12 ? 'AM' : 'PM'}';
    }
    if (identical(this, es)) return '${d.hour}:${two(d.minute)}';
    return d.minute == 0 ? '${d.hour}h' : '${d.hour}h${two(d.minute)}';
  }
}
