// Textos dos componentes em pt (padrão), en e es. Arquivo escrito à mão a
// partir de uma tabela: ao criar texto novo, acrescente o campo nos três
// idiomas, no construtor e no copyWith.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'format.dart' show two;

/// Textos que os componentes `Ss*` mostram ou falam (leitor de tela). O
/// português é o padrão; [en] e [es] vêm prontos.
///
/// Como cada widget acha o idioma ([SsStrings.of]):
/// 1. um [SsStringsScope] acima dele (troca o objeto ou ajusta alguns textos);
/// 2. o [SsStrings] carregado pelo [SsStrings.delegate] nos
///    `localizationsDelegates` do app;
/// 3. o idioma do `Localizations` (pt, en ou es). Um app sem idioma
///    configurado (o Flutter assume en-US só com os textos padrão do Material)
///    fica em português;
/// 4. português.
///
/// Para trocar textos soltos: `SsStrings.en.copyWith(cancel: 'Dismiss')`,
/// [SsStringsScope.override] ou [SsStringsDelegate] com `apply`.
@immutable
class SsStrings {
  const SsStrings({
    required this.locale,
    required this.offlineError,
    required this.genericError,
    required this.retry,
    required this.loading,
    required this.loadingMore,
    required this.loadMore,
    required this.endOfList,
    required this.loadFailed,
    required this.progressOver,
    required this.moreOptions,
    required this.checked,
    required this.clearSelection,
    required this.selectedCount,
    required this.chatSending,
    required this.chatSent,
    required this.chatNotSent,
    required this.chatThinking,
    required this.chatHint,
    required this.send,
    required this.confirm,
    required this.cancel,
    required this.save,
    required this.name,
    required this.irreversibleWord,
    required this.typeToConfirm,
    required this.pleaseWait,
    required this.cancelling,
    required this.discardTitle,
    required this.discardMessage,
    required this.discard,
    required this.keepEditing,
    required this.photo,
    required this.takePhoto,
    required this.opensCamera,
    required this.chooseFromGallery,
    required this.removePhoto,
    required this.done,
    required this.nothingFound,
    required this.search,
    required this.clear,
    required this.months,
    required this.weekdayInitials,
    required this.weekdaysShort,
    required this.weekdaysLong,
    required this.formatDate,
    required this.formatDayMonth,
    required this.longDatePattern,
    required this.previousMonth,
    required this.nextMonth,
    required this.backToCurrentMonth,
    required this.todaySuffix,
    required this.markersCount,
    required this.nothing,
    required this.less,
    required this.more,
    required this.close,
    required this.commandHint,
    required this.recent,
    required this.nothingFoundFor,
    required this.start,
    required this.next,
    required this.skip,
    required this.pageOf,
    required this.firstSteps,
    required this.countOf,
    required this.allDone,
    required this.planNames,
    required this.yourPlan,
    required this.monthly,
    required this.yearly,
    required this.yearlySavings,
    required this.comparePlans,
    required this.restorePurchases,
    required this.manageSubscription,
    required this.confirmingSubscription,
    required this.mostComplete,
    required this.currentPlan,
    required this.cheapestBadge,
    required this.cheapest,
    required this.wasPrice,
    required this.signInWithGoogle,
    required this.seePlans,
    required this.notNow,
    required this.paidPlanOnly,
    required this.thisMonth,
    required this.quotaUsed,
    required this.limitReached,
    required this.syncAllSaved,
    required this.syncPending,
    required this.syncSending,
    required this.syncFailed,
    required this.offline,
    required this.syncOfflinePending,
    required this.saved,
    required this.waitingToSend,
    required this.sendFailed,
    required this.requiredField,
    required this.enterAmount,
    required this.enterNumber,
    required this.numberRange,
    required this.amount,
    required this.backspaceHold,
    required this.today,
    required this.tomorrow,
    required this.yesterday,
    required this.otherDate,
    required this.pickDate,
    required this.time,
    required this.clearDate,
    required this.choose,
    required this.noTime,
    required this.clearTime,
    required this.offlineBanner,
    required this.backOnline,
    required this.unreadCount,
    required this.addPerson,
    required this.tabOf,
    required this.cardsCount,
    required this.searchMenu,
    required this.clearSearch,
    required this.menuNothingFound,
    required this.plansAndSubscription,
    required this.appearanceAndAbout,
    required this.themeSystem,
    required this.themeLight,
    required this.themeDark,
    required this.deleteMyAccount,
    required this.signOut,
    required this.gaugeCheap,
    required this.gaugeNormal,
    required this.gaugeExpensive,
    required this.gauge,
    required this.days,
    required this.remainingOf,
    required this.remaining,
    required this.undo,
    required this.before,
    required this.after,
    required this.compareLabel,
    required this.stepDone,
    required this.stepNow,
    required this.stepNext,
    required this.stepOf,
    required this.dismissTip,
    required this.back,
    required this.decrease,
    required this.increase,
    required this.target,
    required this.noData,
    required this.chartSummary,
    required this.chartOf,
    required this.yourPoints,
    required this.pointsCount,
    required this.pointsShort,
    required this.towardsLevel,
    required this.pointsToLevel,
    required this.spentEarned,
    required this.buy,
    required this.sell,
    required this.asset,
    required this.changeOf,
    required this.areaChart,
    required this.chartOfLabel,
    required this.total,
    required this.donutSummary,
    required this.flightLabel,
    required this.showBoardingQr,
    required this.itemOf,
    required this.nOfTotal,
    required this.imageOf,
    required this.previousThumbs,
    required this.nextThumbs,
    required this.notifications,
    required this.newCount,
    required this.newItem,
    required this.add,
    required this.newsCount,
    required this.totalClosed,
    required this.missing,
    required this.over,
    required this.shareOf,
    required this.confirmed,
    required this.holdToConfirm,
    required this.slideToConfirm,
    required this.stateLoading,
    required this.stateDone,
    required this.stateFailed,
    required this.totalBalance,
    required this.closeCards,
    required this.openCards,
    required this.taskDone,
    required this.taskPending,
    required this.pickDay,
    required this.monthOpenCalendar,
    required this.withEvents,
    required this.nowAt,
    required this.agoNow,
    required this.agoMinutes,
    required this.agoHours,
    required this.agoYesterday,
    required this.agoDays,
    required this.sending,
    required this.unavailable,
    required this.deviceNoResponse,
    required this.noPermission,
    required this.turnOn,
    required this.turnOff,
    required this.openDetails,
    required this.thermostatLabel,
    required this.thermostatCurrent,
    required this.thermostatOff,
    required this.thermostatHeating,
    required this.thermostatCooling,
    required this.thermostatIdle,
    required this.thermostatMode,
    required this.thermostatModeOff,
    required this.thermostatModeHeat,
    required this.thermostatModeCool,
    required this.thermostatModeAuto,
    required this.codeBackspace,
    required this.codeError,
    required this.codeDigits,
    required this.everyDay,
    required this.weekdaysOnly,
    required this.weekend,
    required this.weekdayPickerLabel,
    required this.weekdaysFull,
    required this.loadingEllipsis,
    required this.logbookEnd,
    required this.logbookEmpty,
    required this.logbookLabel,
    required this.stateBandsEmpty,
    required this.noReadings,
    required this.chartNoReadings,
    required this.showAll,
    required this.chartLoading,
    required this.chartMin,
    required this.chartMax,
    required this.chartLast,
    required this.chartUntil,
    required this.emptyYet,
    required this.sortBy,
    required this.ascending,
    required this.descending,
    required this.searchIcon,
    required this.noIcon,
    required this.noIconFor,
    required this.moveUp,
    required this.moveDown,
    required this.duplicate,
    required this.delete,
    required this.enabled,
    required this.expand,
    required this.collapse,
    required this.dragToReorder,
    required this.dismiss,
    required this.micIdle,
    required this.micListening,
    required this.micProcessing,
    required this.micError,
    required this.lockMessage,
    required this.unlock,
    required this.usePin,
    required this.useBiometrics,
    required this.cameraLive,
    required this.cameraLoading,
    required this.cameraError,
    required this.cameraOffline,
    required this.agoSeconds,
    required this.agoDaysShort,
    required this.play,
    required this.pause,
    required this.previous,
    required this.nextTrack,
    required this.volume,
    required this.position,
    required this.nothingPlaying,
    required this.weatherMin,
    required this.weatherMax,
    required this.humidity,
    required this.wind,
    required this.weatherClear,
    required this.weatherClearNight,
    required this.weatherPartlyCloudy,
    required this.weatherCloudy,
    required this.weatherRain,
    required this.weatherStorm,
    required this.weatherSnow,
    required this.weatherFog,
    required this.weatherWind,
    required this.searching,
    required this.foundCount,
    required this.searchAgain,
    required this.dpadUp,
    required this.dpadDown,
    required this.dpadLeft,
    required this.dpadRight,
    required this.dpadOk,
    required this.dpadHome,
    required this.dpadMenu,
    required this.volumeUp,
    required this.volumeDown,
    required this.mute,
    required this.channelUp,
    required this.channelDown,
    required this.volumeShort,
    required this.channelShort,
    required this.unmute,
    required this.feelsLike,
    required this.rainChance,
    required this.agendaEmptyDay,
    required this.deviceRun,
    required this.holdToTalk,
    required this.localeSystemShort,
    required this.localeSystem,
    required this.unread,
    required this.colorCustom,
    required this.colorPickOther,
    required this.colorHue,
    required this.colorSaturation,
    required this.colorBrightness,
    required this.colorHex,
    required this.colorHexInvalid,
    required this.allDay,
    required this.copy,
    required this.copied,
    required this.dangerZone,
  });

  /// Idioma destes textos (também o do calendário do [SsDateField]).
  final Locale locale;

  // Estados de carregamento e erro (SsAsyncBody, SsInlineAsync, SsErrorView, SsLoadMore)

  final String offlineError;
  final String genericError;
  final String retry;
  final String loading;
  final String loadingMore;
  final String loadMore;
  final String endOfList;
  final String loadFailed;
  final String Function(String pct) progressOver;

  // Menus e seleção

  final String moreOptions;
  final String checked;
  final String clearSelection;

  /// Palavra depois do número na barra de seleção.
  final String Function(int n) selectedCount;

  // Conversa (SsChat*)

  final String chatSending;
  final String chatSent;
  final String chatNotSent;
  final String chatThinking;
  final String chatHint;
  final String send;

  // Diálogos (showSsConfirm, showSsPrompt, ssRunBlocking, SsUnsavedGuard, showSsImageSource)

  final String confirm;
  final String cancel;
  final String save;
  final String name;

  /// Palavra a digitar em showSsConfirmIrreversible.
  final String irreversibleWord;
  final String Function(String word) typeToConfirm;
  final String pleaseWait;
  final String cancelling;
  final String discardTitle;
  final String discardMessage;
  final String discard;
  final String keepEditing;
  final String photo;
  final String takePhoto;
  final String opensCamera;
  final String chooseFromGallery;
  final String removePhoto;

  // Botões e busca

  final String done;
  final String nothingFound;
  final String search;
  final String clear;

  // Datas e calendário

  /// Nomes dos meses (janeiro primeiro), como título ("Outubro 2026").
  final List<String> months;

  /// Iniciais dos dias da semana, começando no domingo (cabeçalho da grade do mês).
  final List<String> weekdayInitials;

  /// Dias da semana abreviados, começando na segunda (DateTime.monday).
  final List<String> weekdaysShort;

  /// Dias da semana por extenso, começando na segunda.
  final List<String> weekdaysLong;

  /// Data curta: 06/10/2026 (en: 10/06/2026).
  final String Function(DateTime d) formatDate;

  /// Dia e mês: 06/10 (en: 10/06).
  final String Function(DateTime d) formatDayMonth;

  /// Molde da data por extenso ([longDate]): "segunda, 5 de outubro".
  final String Function(String weekday, int day, String month) longDatePattern;
  final String previousMonth;
  final String nextMonth;
  final String backToCurrentMonth;

  /// Acrescentado ao rótulo falado do dia de hoje.
  final String todaySuffix;
  final String Function(int n) markersCount;
  final String nothing;
  final String less;
  final String more;

  // Paleta de comandos (SsCommandPalette)

  final String close;
  final String commandHint;
  final String recent;
  final String Function(String query) nothingFoundFor;

  // Boas-vindas (SsOnboarding, SsChecklistCard)

  final String start;
  final String next;
  final String skip;
  final String Function(int page, int total) pageOf;
  final String firstSteps;

  /// "3 de 5".
  final String Function(int done, int total) countOf;
  final String allDone;

  // Planos e assinatura (SsPlansView, SsPlanCard, SsPlanCompareTable, SsPaywall, SsQuota)

  /// Nomes dos três níveis (grátis, pro, max).
  final List<String> planNames;
  final String yourPlan;
  final String monthly;
  final String yearly;
  final String Function(int pct) yearlySavings;
  final String comparePlans;
  final String restorePurchases;
  final String manageSubscription;
  final String confirmingSubscription;
  final String mostComplete;
  final String currentPlan;

  // Ofertas e login

  final String cheapestBadge;
  final String cheapest;
  final String Function(String price) wasPrice;
  final String signInWithGoogle;
  final String seePlans;
  final String notNow;
  final String paidPlanOnly;
  final String thisMonth;

  /// "2 de 3 este mês".
  final String Function(int used, int limit, String period) quotaUsed;
  final String Function(String text) limitReached;

  // Sincronização (SsSyncStatus, SsSyncDot)

  final String syncAllSaved;
  final String Function(int n) syncPending;
  final String syncSending;
  final String syncFailed;
  final String offline;
  final String Function(int n) syncOfflinePending;
  final String saved;
  final String waitingToSend;
  final String sendFailed;

  // Campos e validação (SsValidators, SsMoneyField, SsAmountKeypad, SsDateField, SsChoiceField, SsTimeField)

  final String requiredField;
  final String enterAmount;
  final String enterNumber;
  final String Function(int min, int max) numberRange;
  final String amount;
  final String backspaceHold;
  final String today;
  final String tomorrow;
  final String yesterday;
  final String otherDate;
  final String pickDate;
  final String time;
  final String clearDate;
  final String choose;
  final String noTime;
  final String clearTime;

  // Rede e listas (SsOfflineBanner, SsAvatar, SsAvatarStack)

  final String offlineBanner;
  final String backOnline;
  final String Function(String name, int n) unreadCount;
  final String addPerson;

  // Navegação, kanban e menu (SsNavBar, SsKanban, SsMenuLayout)

  final String Function(String label, int index, int count) tabOf;
  final String Function(String title, int n) cardsCount;
  final String searchMenu;
  final String clearSearch;
  final String Function(String query) menuNothingFound;
  final String plansAndSubscription;
  final String appearanceAndAbout;
  final String themeSystem;
  final String themeLight;
  final String themeDark;
  final String deleteMyAccount;
  final String signOut;

  // Medidores e avisos (SsGauge, SsCountdownRing, showSsUndo)

  final String gaugeCheap;
  final String gaugeNormal;
  final String gaugeExpensive;
  final String gauge;
  final String days;
  final String Function(int left, int total, String unit) remainingOf;
  final String Function(String left, String unit) remaining;
  final String undo;

  // Comparação e linha do tempo (SsCompare, SsTimeline)

  final String before;
  final String after;
  final String Function(String a, String b) compareLabel;
  final String stepDone;
  final String stepNow;
  final String stepNext;
  final String Function(int step, int total) stepOf;

  // Diversos (SsTip, SsScreenHeader, SsStepper, SsLineChart)

  final String dismissTip;
  final String back;
  final String decrease;
  final String increase;
  final String target;
  final String noData;
  final String Function(String min, String max, String last) chartSummary;
  final String Function(String? name) chartOf;

  // Pontos e cotações (SsLevelCard, SsPriceBoard)

  final String yourPoints;
  final String Function(String n) pointsCount;

  /// Sufixo do número grande de pontos.
  final String pointsShort;
  final String Function(String level) towardsLevel;
  final String Function(String n, String level) pointsToLevel;
  final String Function(String title, String spent, int points) spentEarned;
  final String buy;
  final String sell;
  final String asset;
  final String Function(String pct) changeOf;

  // Gráficos v0.9 (SsAreaChart, SsExplodedDonut, SsFloatingBars)

  final String areaChart;
  final String Function(String name) chartOfLabel;
  final String total;
  final String Function(String total, String parts) donutSummary;

  // Cartões e mídia v0.9 (SsFlightCard, SsSnapCarousel, SsThumbRail)

  final String Function(String from, String to, int pct) flightLabel;
  final String showBoardingQr;
  final String Function(int i, int n) itemOf;

  /// "2 de 5" (contador falado).
  final String Function(int i, int n) nOfTotal;
  final String Function(int i, int n) imageOf;
  final String previousThumbs;
  final String nextThumbs;

  // Navegação v0.9 (SsBellDot, SsStepTopBar)

  final String notifications;
  final String Function(String label, int n) newCount;

  // Social v0.9 (SsPeoplePicker, SsStoryAvatar)

  final String newItem;
  final String add;
  final String Function(int n) newsCount;

  // Entradas v0.9 (SsSplitBar, SsHoldToConfirm, SsSlideToConfirm, SsMorphButton)

  final String totalClosed;
  final String missing;
  final String over;
  final String Function(String name) shareOf;
  final String confirmed;
  final String holdToConfirm;
  final String slideToConfirm;
  final String Function(String label) stateLoading;
  final String Function(String label) stateDone;
  final String Function(String label) stateFailed;

  // Cartões v0.9 (SsWalletCard, SsCardStack, SsPopProductCard, SsTaskCard)

  final String totalBalance;
  final String closeCards;
  final String Function(int n) openCards;
  final String taskDone;
  final String taskPending;

  // Agenda v0.9 (SsDateStrip, SsDayAgenda)

  final String pickDay;
  final String Function(String month) monthOpenCalendar;
  final String withEvents;
  final String Function(String time) nowAt;

  // Tempo relativo (timeAgo)

  final String agoNow;
  final String Function(int n) agoMinutes;
  final String Function(int n) agoHours;
  final String agoYesterday;
  final String Function(int n) agoDays;

  // Controles da casa v0.10 (SsDeviceTile, SsThermostat, SsCodeKeypad, SsWeekdayPicker)

  final String sending;
  final String unavailable;
  final String deviceNoResponse;
  final String noPermission;
  final String turnOn;
  final String turnOff;
  final String openDetails;
  final String thermostatLabel;
  final String thermostatCurrent;
  final String thermostatOff;
  final String thermostatHeating;
  final String thermostatCooling;
  final String thermostatIdle;
  final String thermostatMode;
  final String thermostatModeOff;
  final String thermostatModeHeat;
  final String thermostatModeCool;
  final String thermostatModeAuto;
  final String codeBackspace;
  final String codeError;
  final String codeDigits;
  final String everyDay;
  final String weekdaysOnly;
  final String weekend;
  final String weekdayPickerLabel;

  /// Dias da semana por extenso para data completa, começando na segunda
  /// ("quarta-feira").
  final List<String> weekdaysFull;

  // Dados v0.10 (SsLogbook, SsStateBands, SsTimeChart, SsDataTable)

  final String loadingEllipsis;
  final String logbookEnd;
  final String logbookEmpty;
  final String logbookLabel;
  final String stateBandsEmpty;
  final String noReadings;
  final String chartNoReadings;
  final String showAll;
  final String chartLoading;
  final String chartMin;
  final String chartMax;
  final String chartLast;
  final String chartUntil;
  final String emptyYet;
  final String sortBy;
  final String ascending;
  final String descending;

  // Estrutura v0.10 (SsIconPicker, SsBlockList, SsCollapsible)

  final String searchIcon;
  final String noIcon;
  final String Function(String query) noIconFor;
  final String moveUp;
  final String moveDown;
  final String duplicate;
  final String delete;
  final String enabled;
  final String expand;
  final String collapse;
  final String dragToReorder;

  // Casa v0.10 (SsNoticeCard, SsMicButton, SsLockScreen, SsCameraTile, SsMediaPlayer, SsWeatherCard, SsScanRadar, SsDPad)

  final String dismiss;
  final String micIdle;
  final String micListening;
  final String micProcessing;
  final String micError;
  final String lockMessage;
  final String unlock;
  final String usePin;
  final String useBiometrics;
  final String cameraLive;
  final String cameraLoading;
  final String cameraError;
  final String cameraOffline;
  final String Function(int n) agoSeconds;
  final String Function(int n) agoDaysShort;
  final String play;
  final String pause;
  final String previous;
  final String nextTrack;
  final String volume;
  final String position;
  final String nothingPlaying;
  final String weatherMin;
  final String weatherMax;
  final String humidity;
  final String wind;
  final String weatherClear;
  final String weatherClearNight;
  final String weatherPartlyCloudy;
  final String weatherCloudy;
  final String weatherRain;
  final String weatherStorm;
  final String weatherSnow;
  final String weatherFog;
  final String weatherWind;
  final String searching;
  final String Function(int n) foundCount;
  final String searchAgain;
  final String dpadUp;
  final String dpadDown;
  final String dpadLeft;
  final String dpadRight;
  final String dpadOk;
  final String dpadHome;
  final String dpadMenu;
  final String volumeUp;
  final String volumeDown;
  final String mute;
  final String channelUp;
  final String channelDown;
  final String volumeShort;
  final String channelShort;

  /// Leitor de tela do botão de som quando está mudo (SsMediaPlayer).
  final String unmute;

  /// Sensação térmica (SsWeatherCard).
  final String feelsLike;

  /// Chance de chuva em % (SsWeatherCard).
  final String rainChance;

  /// Dia sem compromisso (SsAgendaList).
  final String agendaEmptyDay;

  /// Dica do tile que executa um comando (SsDeviceTile.onPress).
  final String deviceRun;

  /// Dica do botão de segurar para falar (SsCallAction.onHoldStart).
  final String holdToTalk;

  /// SsLocalePicker(systemOption:, segmented:): a opção do sistema, curta.
  final String localeSystemShort;

  /// SsLocalePicker(systemOption:): a opção sem idioma fixo.
  final String localeSystem;

  /// SsNoticeCard(unread:) para o leitor de tela.
  final String unread;

  /// SsColorPicker(free:): a ficha da cor livre.
  final String colorCustom;

  /// Título da folha de cor livre do SsColorPicker.
  final String colorPickOther;
  final String colorHue;
  final String colorSaturation;
  final String colorBrightness;
  final String colorHex;
  final String colorHexInvalid;

  /// Compromisso sem hora (SsAgendaList).
  final String allDay;

  /// Botão de copiar (SsCodeBlock).
  final String copy;

  /// Depois de copiar (SsCodeBlock).
  final String copied;

  /// Título padrão do SsDangerZone.
  final String dangerZone;

  /// "Outubro 2026".
  String monthTitle(DateTime d) => '${months[d.month - 1]} ${d.year}';

  /// "segunda, 5 de outubro" (en: "Monday, October 5").
  String longDate(DateTime d) => longDatePattern(weekdaysLong[d.weekday - 1], d.day, months[d.month - 1]);

  /// Português (padrão).
  static final SsStrings pt = SsStrings(
    locale: const Locale('pt', 'BR'),
    offlineError: 'Sem conexão. Confira a internet e tente de novo.',
    genericError: 'Algo deu errado. Tente de novo.',
    retry: 'Tentar de novo',
    loading: 'Carregando',
    loadingMore: 'Carregando mais',
    loadMore: 'Carregar mais',
    endOfList: 'Fim da lista',
    loadFailed: 'Não deu para carregar.',
    progressOver: (pct) => '$pct, estourou',
    moreOptions: 'Mais opções',
    checked: 'marcado',
    clearSelection: 'Limpar seleção',
    selectedCount: (n) => n == 1 ? 'selecionado' : 'selecionados',
    chatSending: 'Enviando',
    chatSent: 'Enviada',
    chatNotSent: 'Não enviada',
    chatThinking: 'Pensando',
    chatHint: 'Escreva uma mensagem',
    send: 'Enviar',
    confirm: 'Confirmar',
    cancel: 'Cancelar',
    save: 'Salvar',
    name: 'Nome',
    irreversibleWord: 'APAGAR',
    typeToConfirm: (word) => 'Digite $word para confirmar',
    pleaseWait: 'Um instante…',
    cancelling: 'Cancelando…',
    discardTitle: 'Descartar as alterações?',
    discardMessage: 'O que você mudou aqui ainda não foi salvo.',
    discard: 'Descartar',
    keepEditing: 'Continuar editando',
    photo: 'Foto',
    takePhoto: 'Tirar foto',
    opensCamera: 'Abre a câmera',
    chooseFromGallery: 'Escolher da galeria',
    removePhoto: 'Remover foto',
    done: 'Pronto',
    nothingFound: 'Nada encontrado',
    search: 'Buscar',
    clear: 'Limpar',
    months: const [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ],
    weekdayInitials: const ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'],
    weekdaysShort: const ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'],
    weekdaysLong: const ['segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado', 'domingo'],
    formatDate: (d) => '${two(d.day)}/${two(d.month)}/${d.year}',
    formatDayMonth: (d) => '${two(d.day)}/${two(d.month)}',
    longDatePattern: (weekday, day, month) => '$weekday, $day de ${month.toLowerCase()}',
    previousMonth: 'Mês anterior',
    nextMonth: 'Próximo mês',
    backToCurrentMonth: 'Voltar ao mês atual',
    todaySuffix: ', hoje',
    markersCount: (n) => ', $n marcador(es)',
    nothing: 'nada',
    less: 'menos',
    more: 'mais',
    close: 'Fechar',
    commandHint: 'Buscar ação ou tela',
    recent: 'Recentes',
    nothingFoundFor: (query) => 'Nada encontrado para “$query”',
    start: 'Começar',
    next: 'Continuar',
    skip: 'Pular',
    pageOf: (page, total) => 'Página $page de $total',
    firstSteps: 'Primeiros passos',
    countOf: (done, total) => '$done de $total',
    allDone: 'Tudo pronto!',
    planNames: const ['Grátis', 'Pro', 'Max'],
    yourPlan: 'SEU PLANO',
    monthly: 'Mensal',
    yearly: 'Anual',
    yearlySavings: (pct) => 'Anual · −$pct%',
    comparePlans: 'Comparar os planos',
    restorePurchases: 'Restaurar compras',
    manageSubscription: 'Gerenciar assinatura',
    confirmingSubscription: 'Confirmando sua assinatura…',
    mostComplete: 'Mais completo',
    currentPlan: 'Seu plano atual',
    cheapestBadge: 'MAIS BARATA',
    cheapest: 'mais barata',
    wasPrice: (price) => 'antes $price',
    signInWithGoogle: 'Entrar com Google',
    seePlans: 'Ver planos',
    notNow: 'Agora não',
    paidPlanOnly: 'Disponível em plano pago',
    thisMonth: 'este mês',
    quotaUsed: (used, limit, period) => '$used de $limit $period',
    limitReached: (text) => '$text, limite atingido',
    syncAllSaved: 'Tudo salvo',
    syncPending: (n) => n == 1 ? '1 a enviar' : '$n a enviar',
    syncSending: 'Enviando…',
    syncFailed: 'Falhou · Tentar de novo',
    offline: 'Sem conexão',
    syncOfflinePending: (n) => 'Sem conexão · $n a enviar',
    saved: 'Salvo',
    waitingToSend: 'Aguardando envio',
    sendFailed: 'Falhou ao enviar',
    requiredField: 'Campo obrigatório',
    enterAmount: 'Informe um valor',
    enterNumber: 'Informe um número',
    numberRange: (min, max) => 'Use um número de $min a $max',
    amount: 'Valor',
    backspaceHold: 'Apagar (segure para zerar)',
    today: 'Hoje',
    tomorrow: 'Amanhã',
    yesterday: 'Ontem',
    otherDate: 'Outra…',
    pickDate: 'Escolher data',
    time: 'Hora',
    clearDate: 'Limpar data',
    choose: 'Escolher',
    noTime: 'Sem horário',
    clearTime: 'Limpar horário',
    offlineBanner: 'Sem conexão — mostrando o que já foi baixado',
    backOnline: 'De volta online',
    unreadCount: (name, n) => '$name, $n não lidas',
    addPerson: 'Adicionar pessoa',
    tabOf: (label, index, count) => '$label, aba $index de $count',
    cardsCount: (title, n) => '$title, $n ${n == 1 ? 'card' : 'cards'}',
    searchMenu: 'Buscar no menu',
    clearSearch: 'Limpar busca',
    menuNothingFound: (query) => 'Nada encontrado para "$query".',
    plansAndSubscription: 'Planos e assinatura',
    appearanceAndAbout: 'Aparência e sobre',
    themeSystem: 'Sistema',
    themeLight: 'Claro',
    themeDark: 'Escuro',
    deleteMyAccount: 'Excluir minha conta',
    signOut: 'Sair',
    gaugeCheap: 'barato',
    gaugeNormal: 'normal',
    gaugeExpensive: 'caro',
    gauge: 'Medidor',
    days: 'dias',
    remainingOf: (left, total, unit) => 'Faltam $left de $total $unit',
    remaining: (left, unit) => 'Faltam $left $unit',
    undo: 'Desfazer',
    before: 'Antes',
    after: 'Depois',
    compareLabel: (a, b) => 'Comparar $a e $b',
    stepDone: 'feito',
    stepNow: 'agora',
    stepNext: 'a seguir',
    stepOf: (step, total) => 'Passo $step de $total',
    dismissTip: 'Dispensar dica',
    back: 'Voltar',
    decrease: 'Diminuir',
    increase: 'Aumentar',
    target: 'meta',
    noData: 'sem dados',
    chartSummary: (min, max, last) => 'mínimo $min, máximo $max, último $last',
    chartOf: (name) => name == null ? 'Gráfico' : 'Gráfico de $name',
    yourPoints: 'Seus pontos',
    pointsCount: (n) => '$n pontos',
    pointsShort: ' pts',
    towardsLevel: (level) => 'Rumo a $level',
    pointsToLevel: (n, level) => 'Faltam $n para $level',
    spentEarned: (title, spent, points) => '$title: gastou $spent, ganhou $points pontos',
    buy: 'Compra',
    sell: 'Venda',
    asset: 'ATIVO',
    changeOf: (pct) => ', variação $pct',
    areaChart: 'Gráfico de área',
    chartOfLabel: (name) => 'Gráfico de $name',
    total: 'Total',
    donutSummary: (total, parts) => 'Rosca: $total. $parts',
    flightLabel: (from, to, pct) => 'Voo de $from para $to, $pct% do trajeto',
    showBoardingQr: 'Mostrar QR do embarque',
    itemOf: (i, n) => 'Item $i de $n',
    nOfTotal: (i, n) => '$i de $n',
    imageOf: (i, n) => 'Imagem $i de $n',
    previousThumbs: 'Miniaturas anteriores',
    nextThumbs: 'Próximas miniaturas',
    notifications: 'Notificações',
    newCount: (label, n) => '$label: $n nova${n == 1 ? '' : 's'}',
    newItem: 'Novo',
    add: 'Adicionar',
    newsCount: (n) => ', $n ${n == 1 ? 'novidade' : 'novidades'}',
    totalClosed: 'Fechou o total',
    missing: 'Falta',
    over: 'Passou',
    shareOf: (name) => 'Parte de $name',
    confirmed: 'Confirmado',
    holdToConfirm: 'segure para confirmar',
    slideToConfirm: 'arraste até o fim para confirmar',
    stateLoading: (label) => '$label: carregando',
    stateDone: (label) => '$label: concluído',
    stateFailed: (label) => '$label: falhou',
    totalBalance: 'Saldo total',
    closeCards: 'Fechar cartões',
    openCards: (n) => 'Abrir $n cartões',
    taskDone: 'Feito',
    taskPending: 'Pendente',
    pickDay: 'Escolher dia',
    monthOpenCalendar: (month) => 'Mês: $month. Abrir calendário',
    withEvents: ', com eventos',
    nowAt: (time) => 'Agora, $time',
    agoNow: 'agora',
    agoMinutes: (n) => 'há $n min',
    agoHours: (n) => 'há $n h',
    agoYesterday: 'ontem',
    agoDays: (n) => 'há $n dias',
    sending: 'Enviando…',
    unavailable: 'Indisponível',
    deviceNoResponse: 'Não respondeu',
    noPermission: 'Sem permissão',
    turnOn: 'Ligar',
    turnOff: 'Desligar',
    openDetails: 'Abrir detalhes',
    thermostatLabel: 'Temperatura',
    thermostatCurrent: 'Agora',
    thermostatOff: 'Desligado',
    thermostatHeating: 'Aquecendo',
    thermostatCooling: 'Resfriando',
    thermostatIdle: 'No alvo',
    thermostatMode: 'Modo',
    thermostatModeOff: 'Desligado',
    thermostatModeHeat: 'Aquecer',
    thermostatModeCool: 'Resfriar',
    thermostatModeAuto: 'Auto',
    codeBackspace: 'Apagar',
    codeError: 'Código incorreto',
    codeDigits: 'Dígitos digitados',
    everyDay: 'Todos os dias',
    weekdaysOnly: 'Dias úteis',
    weekend: 'Fim de semana',
    weekdayPickerLabel: 'Dias da semana',
    weekdaysFull: const [
      'segunda-feira',
      'terça-feira',
      'quarta-feira',
      'quinta-feira',
      'sexta-feira',
      'sábado',
      'domingo',
    ],
    loadingEllipsis: 'Carregando…',
    logbookEnd: 'Início do registro',
    logbookEmpty: 'Nada registrado ainda',
    logbookLabel: 'Registro de eventos',
    stateBandsEmpty: 'Nenhuma mudança neste período',
    noReadings: 'sem leituras',
    chartNoReadings: 'Sem leituras neste período',
    showAll: 'Ver tudo',
    chartLoading: 'Carregando gráfico',
    chartMin: 'mínimo',
    chartMax: 'máximo',
    chartLast: 'último',
    chartUntil: 'a',
    emptyYet: 'Nada por aqui ainda.',
    sortBy: 'Ordenar por',
    ascending: 'crescente',
    descending: 'decrescente',
    searchIcon: 'Buscar ícone',
    noIcon: 'Sem ícone',
    noIconFor: (query) => 'Nenhum ícone com “$query”',
    moveUp: 'Mover para cima',
    moveDown: 'Mover para baixo',
    duplicate: 'Duplicar',
    delete: 'Excluir',
    enabled: 'Ativo',
    expand: 'Expandir',
    collapse: 'Recolher',
    dragToReorder: 'Arrastar para reordenar',
    dismiss: 'Dispensar',
    micIdle: 'Falar',
    micListening: 'Ouvindo, toque para parar',
    micProcessing: 'Processando',
    micError: 'Erro no microfone, toque para tentar de novo',
    lockMessage: 'O app está bloqueado',
    unlock: 'Desbloquear',
    usePin: 'Usar PIN',
    useBiometrics: 'Usar biometria',
    cameraLive: 'AO VIVO',
    cameraLoading: 'Carregando imagem',
    cameraError: 'Não deu para carregar a imagem',
    cameraOffline: 'Câmera offline',
    agoSeconds: (n) => 'há $n s',
    agoDaysShort: (n) => 'há $n d',
    play: 'Tocar',
    pause: 'Pausar',
    previous: 'Anterior',
    nextTrack: 'Próxima',
    volume: 'Volume',
    position: 'Posição',
    nothingPlaying: 'Nada tocando',
    weatherMin: 'Mín',
    weatherMax: 'Máx',
    humidity: 'Umidade',
    wind: 'Vento',
    weatherClear: 'Céu limpo',
    weatherClearNight: 'Noite limpa',
    weatherPartlyCloudy: 'Parcialmente nublado',
    weatherCloudy: 'Nublado',
    weatherRain: 'Chuva',
    weatherStorm: 'Tempestade',
    weatherSnow: 'Neve',
    weatherFog: 'Neblina',
    weatherWind: 'Ventania',
    searching: 'Procurando…',
    foundCount: (n) => n == 1 ? '1 encontrado' : '$n encontrados',
    searchAgain: 'Procurar de novo',
    dpadUp: 'Cima',
    dpadDown: 'Baixo',
    dpadLeft: 'Esquerda',
    dpadRight: 'Direita',
    dpadOk: 'OK',
    dpadHome: 'Início',
    dpadMenu: 'Menu',
    volumeUp: 'Aumentar volume',
    volumeDown: 'Diminuir volume',
    mute: 'Sem som',
    channelUp: 'Próximo canal',
    channelDown: 'Canal anterior',
    volumeShort: 'VOL',
    channelShort: 'CH',
    unmute: 'Ativar som',
    feelsLike: 'Sensação',
    rainChance: 'Chance de chuva',
    agendaEmptyDay: 'Nada neste dia',
    deviceRun: 'Acionar',
    holdToTalk: 'segure para falar',
    localeSystemShort: 'Auto',
    localeSystem: 'Seguir o sistema',
    unread: 'Não lido',
    colorCustom: 'Personalizada',
    colorPickOther: 'Escolher outra cor',
    colorHue: 'Matiz',
    colorSaturation: 'Saturação',
    colorBrightness: 'Brilho',
    colorHex: 'Código hex',
    colorHexInvalid: 'Use o formato #RRGGBB',
    allDay: 'Dia todo',
    copy: 'Copiar',
    copied: 'Copiado',
    dangerZone: 'Zona de perigo',
  );

  /// Inglês.
  static final SsStrings en = SsStrings(
    locale: const Locale('en'),
    offlineError: 'No connection. Check your internet and try again.',
    genericError: 'Something went wrong. Try again.',
    retry: 'Try again',
    loading: 'Loading',
    loadingMore: 'Loading more',
    loadMore: 'Load more',
    endOfList: 'End of list',
    loadFailed: "Couldn't load.",
    progressOver: (pct) => '$pct, over',
    moreOptions: 'More options',
    checked: 'checked',
    clearSelection: 'Clear selection',
    selectedCount: (n) => 'selected',
    chatSending: 'Sending',
    chatSent: 'Sent',
    chatNotSent: 'Not sent',
    chatThinking: 'Thinking',
    chatHint: 'Write a message',
    send: 'Send',
    confirm: 'Confirm',
    cancel: 'Cancel',
    save: 'Save',
    name: 'Name',
    irreversibleWord: 'DELETE',
    typeToConfirm: (word) => 'Type $word to confirm',
    pleaseWait: 'One moment…',
    cancelling: 'Cancelling…',
    discardTitle: 'Discard changes?',
    discardMessage: "Your changes here haven't been saved.",
    discard: 'Discard',
    keepEditing: 'Keep editing',
    photo: 'Photo',
    takePhoto: 'Take photo',
    opensCamera: 'Opens the camera',
    chooseFromGallery: 'Choose from gallery',
    removePhoto: 'Remove photo',
    done: 'Done',
    nothingFound: 'Nothing found',
    search: 'Search',
    clear: 'Clear',
    months: const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ],
    weekdayInitials: const ['S', 'M', 'T', 'W', 'T', 'F', 'S'],
    weekdaysShort: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    weekdaysLong: const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
    formatDate: (d) => '${two(d.month)}/${two(d.day)}/${d.year}',
    formatDayMonth: (d) => '${two(d.month)}/${two(d.day)}',
    longDatePattern: (weekday, day, month) => '$weekday, $month $day',
    previousMonth: 'Previous month',
    nextMonth: 'Next month',
    backToCurrentMonth: 'Back to current month',
    todaySuffix: ', today',
    markersCount: (n) => ', $n marker(s)',
    nothing: 'nothing',
    less: 'less',
    more: 'more',
    close: 'Close',
    commandHint: 'Search actions or screens',
    recent: 'Recent',
    nothingFoundFor: (query) => 'Nothing found for “$query”',
    start: 'Get started',
    next: 'Continue',
    skip: 'Skip',
    pageOf: (page, total) => 'Page $page of $total',
    firstSteps: 'First steps',
    countOf: (done, total) => '$done of $total',
    allDone: 'All done!',
    planNames: const ['Free', 'Pro', 'Max'],
    yourPlan: 'YOUR PLAN',
    monthly: 'Monthly',
    yearly: 'Yearly',
    yearlySavings: (pct) => 'Yearly · −$pct%',
    comparePlans: 'Compare plans',
    restorePurchases: 'Restore purchases',
    manageSubscription: 'Manage subscription',
    confirmingSubscription: 'Confirming your subscription…',
    mostComplete: 'Most complete',
    currentPlan: 'Your current plan',
    cheapestBadge: 'CHEAPEST',
    cheapest: 'cheapest',
    wasPrice: (price) => 'was $price',
    signInWithGoogle: 'Sign in with Google',
    seePlans: 'See plans',
    notNow: 'Not now',
    paidPlanOnly: 'Available on paid plans',
    thisMonth: 'this month',
    quotaUsed: (used, limit, period) => '$used of $limit $period',
    limitReached: (text) => '$text, limit reached',
    syncAllSaved: 'All saved',
    syncPending: (n) => '$n to send',
    syncSending: 'Sending…',
    syncFailed: 'Failed · Try again',
    offline: 'No connection',
    syncOfflinePending: (n) => 'No connection · $n to send',
    saved: 'Saved',
    waitingToSend: 'Waiting to send',
    sendFailed: 'Failed to send',
    requiredField: 'Required field',
    enterAmount: 'Enter an amount',
    enterNumber: 'Enter a number',
    numberRange: (min, max) => 'Use a number from $min to $max',
    amount: 'Amount',
    backspaceHold: 'Delete (hold to clear)',
    today: 'Today',
    tomorrow: 'Tomorrow',
    yesterday: 'Yesterday',
    otherDate: 'Other…',
    pickDate: 'Pick a date',
    time: 'Time',
    clearDate: 'Clear date',
    choose: 'Choose',
    noTime: 'No time',
    clearTime: 'Clear time',
    offlineBanner: 'No connection — showing what was already downloaded',
    backOnline: 'Back online',
    unreadCount: (name, n) => '$name, $n unread',
    addPerson: 'Add person',
    tabOf: (label, index, count) => '$label, tab $index of $count',
    cardsCount: (title, n) => '$title, $n ${n == 1 ? 'card' : 'cards'}',
    searchMenu: 'Search the menu',
    clearSearch: 'Clear search',
    menuNothingFound: (query) => 'Nothing found for "$query".',
    plansAndSubscription: 'Plans and subscription',
    appearanceAndAbout: 'Appearance and about',
    themeSystem: 'System',
    themeLight: 'Light',
    themeDark: 'Dark',
    deleteMyAccount: 'Delete my account',
    signOut: 'Sign out',
    gaugeCheap: 'cheap',
    gaugeNormal: 'normal',
    gaugeExpensive: 'expensive',
    gauge: 'Gauge',
    days: 'days',
    remainingOf: (left, total, unit) => '$left of $total $unit left',
    remaining: (left, unit) => '$left $unit left',
    undo: 'Undo',
    before: 'Before',
    after: 'After',
    compareLabel: (a, b) => 'Compare $a and $b',
    stepDone: 'done',
    stepNow: 'now',
    stepNext: 'up next',
    stepOf: (step, total) => 'Step $step of $total',
    dismissTip: 'Dismiss tip',
    back: 'Back',
    decrease: 'Decrease',
    increase: 'Increase',
    target: 'target',
    noData: 'no data',
    chartSummary: (min, max, last) => 'minimum $min, maximum $max, last $last',
    chartOf: (name) => name == null ? 'Chart' : 'Chart of $name',
    yourPoints: 'Your points',
    pointsCount: (n) => '$n points',
    pointsShort: ' pts',
    towardsLevel: (level) => 'Towards $level',
    pointsToLevel: (n, level) => '$n to $level',
    spentEarned: (title, spent, points) => '$title: spent $spent, earned $points points',
    buy: 'Buy',
    sell: 'Sell',
    asset: 'ASSET',
    changeOf: (pct) => ', change $pct',
    areaChart: 'Area chart',
    chartOfLabel: (name) => 'Chart of $name',
    total: 'Total',
    donutSummary: (total, parts) => 'Donut: $total. $parts',
    flightLabel: (from, to, pct) => 'Flight from $from to $to, $pct% of the way',
    showBoardingQr: 'Show boarding QR',
    itemOf: (i, n) => 'Item $i of $n',
    nOfTotal: (i, n) => '$i of $n',
    imageOf: (i, n) => 'Image $i of $n',
    previousThumbs: 'Previous thumbnails',
    nextThumbs: 'Next thumbnails',
    notifications: 'Notifications',
    newCount: (label, n) => '$label: $n new',
    newItem: 'New',
    add: 'Add',
    newsCount: (n) => ', $n ${n == 1 ? 'update' : 'updates'}',
    totalClosed: 'Total matched',
    missing: 'Missing',
    over: 'Over',
    shareOf: (name) => 'Share of $name',
    confirmed: 'Confirmed',
    holdToConfirm: 'hold to confirm',
    slideToConfirm: 'slide to the end to confirm',
    stateLoading: (label) => '$label: loading',
    stateDone: (label) => '$label: done',
    stateFailed: (label) => '$label: failed',
    totalBalance: 'Total balance',
    closeCards: 'Close cards',
    openCards: (n) => 'Open $n cards',
    taskDone: 'Done',
    taskPending: 'Pending',
    pickDay: 'Pick a day',
    monthOpenCalendar: (month) => 'Month: $month. Open calendar',
    withEvents: ', with events',
    nowAt: (time) => 'Now, $time',
    agoNow: 'just now',
    agoMinutes: (n) => '$n min ago',
    agoHours: (n) => '$n h ago',
    agoYesterday: 'yesterday',
    agoDays: (n) => '$n days ago',
    sending: 'Sending…',
    unavailable: 'Unavailable',
    deviceNoResponse: 'No response',
    noPermission: 'No permission',
    turnOn: 'Turn on',
    turnOff: 'Turn off',
    openDetails: 'Open details',
    thermostatLabel: 'Temperature',
    thermostatCurrent: 'Now',
    thermostatOff: 'Off',
    thermostatHeating: 'Heating',
    thermostatCooling: 'Cooling',
    thermostatIdle: 'At target',
    thermostatMode: 'Mode',
    thermostatModeOff: 'Off',
    thermostatModeHeat: 'Heat',
    thermostatModeCool: 'Cool',
    thermostatModeAuto: 'Auto',
    codeBackspace: 'Delete',
    codeError: 'Wrong code',
    codeDigits: 'Digits entered',
    everyDay: 'Every day',
    weekdaysOnly: 'Weekdays',
    weekend: 'Weekend',
    weekdayPickerLabel: 'Days of the week',
    weekdaysFull: const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
    loadingEllipsis: 'Loading…',
    logbookEnd: 'Start of the log',
    logbookEmpty: 'Nothing logged yet',
    logbookLabel: 'Event log',
    stateBandsEmpty: 'No changes in this period',
    noReadings: 'no readings',
    chartNoReadings: 'No readings in this period',
    showAll: 'Show all',
    chartLoading: 'Loading chart',
    chartMin: 'minimum',
    chartMax: 'maximum',
    chartLast: 'latest',
    chartUntil: 'to',
    emptyYet: 'Nothing here yet.',
    sortBy: 'Sort by',
    ascending: 'ascending',
    descending: 'descending',
    searchIcon: 'Search icons',
    noIcon: 'No icon',
    noIconFor: (query) => 'No icons matching “$query”',
    moveUp: 'Move up',
    moveDown: 'Move down',
    duplicate: 'Duplicate',
    delete: 'Delete',
    enabled: 'Enabled',
    expand: 'Expand',
    collapse: 'Collapse',
    dragToReorder: 'Drag to reorder',
    dismiss: 'Dismiss',
    micIdle: 'Speak',
    micListening: 'Listening, tap to stop',
    micProcessing: 'Processing',
    micError: 'Microphone error, tap to try again',
    lockMessage: 'The app is locked',
    unlock: 'Unlock',
    usePin: 'Use PIN',
    useBiometrics: 'Use biometrics',
    cameraLive: 'LIVE',
    cameraLoading: 'Loading image',
    cameraError: "Couldn't load the image",
    cameraOffline: 'Camera offline',
    agoSeconds: (n) => '$n s ago',
    agoDaysShort: (n) => '$n d ago',
    play: 'Play',
    pause: 'Pause',
    previous: 'Previous',
    nextTrack: 'Next',
    volume: 'Volume',
    position: 'Position',
    nothingPlaying: 'Nothing playing',
    weatherMin: 'Min',
    weatherMax: 'Max',
    humidity: 'Humidity',
    wind: 'Wind',
    weatherClear: 'Clear sky',
    weatherClearNight: 'Clear night',
    weatherPartlyCloudy: 'Partly cloudy',
    weatherCloudy: 'Cloudy',
    weatherRain: 'Rain',
    weatherStorm: 'Storm',
    weatherSnow: 'Snow',
    weatherFog: 'Fog',
    weatherWind: 'Windy',
    searching: 'Searching…',
    foundCount: (n) => '$n found',
    searchAgain: 'Search again',
    dpadUp: 'Up',
    dpadDown: 'Down',
    dpadLeft: 'Left',
    dpadRight: 'Right',
    dpadOk: 'OK',
    dpadHome: 'Home',
    dpadMenu: 'Menu',
    volumeUp: 'Volume up',
    volumeDown: 'Volume down',
    mute: 'Mute',
    channelUp: 'Next channel',
    channelDown: 'Previous channel',
    volumeShort: 'VOL',
    channelShort: 'CH',
    unmute: 'Unmute',
    feelsLike: 'Feels like',
    rainChance: 'Chance of rain',
    agendaEmptyDay: 'Nothing this day',
    deviceRun: 'Run',
    holdToTalk: 'hold to talk',
    localeSystemShort: 'Auto',
    localeSystem: 'Follow system',
    unread: 'Unread',
    colorCustom: 'Custom',
    colorPickOther: 'Pick another color',
    colorHue: 'Hue',
    colorSaturation: 'Saturation',
    colorBrightness: 'Brightness',
    colorHex: 'Hex code',
    colorHexInvalid: 'Use the #RRGGBB format',
    allDay: 'All day',
    copy: 'Copy',
    copied: 'Copied',
    dangerZone: 'Danger zone',
  );

  /// Espanhol.
  static final SsStrings es = SsStrings(
    locale: const Locale('es'),
    offlineError: 'Sin conexión. Revisa tu internet e inténtalo de nuevo.',
    genericError: 'Algo salió mal. Inténtalo de nuevo.',
    retry: 'Reintentar',
    loading: 'Cargando',
    loadingMore: 'Cargando más',
    loadMore: 'Cargar más',
    endOfList: 'Fin de la lista',
    loadFailed: 'No se pudo cargar.',
    progressOver: (pct) => '$pct, excedido',
    moreOptions: 'Más opciones',
    checked: 'marcado',
    clearSelection: 'Borrar selección',
    selectedCount: (n) => n == 1 ? 'seleccionado' : 'seleccionados',
    chatSending: 'Enviando',
    chatSent: 'Enviado',
    chatNotSent: 'No enviado',
    chatThinking: 'Pensando',
    chatHint: 'Escribe un mensaje',
    send: 'Enviar',
    confirm: 'Confirmar',
    cancel: 'Cancelar',
    save: 'Guardar',
    name: 'Nombre',
    irreversibleWord: 'BORRAR',
    typeToConfirm: (word) => 'Escribe $word para confirmar',
    pleaseWait: 'Un momento…',
    cancelling: 'Cancelando…',
    discardTitle: '¿Descartar los cambios?',
    discardMessage: 'Lo que cambiaste aquí aún no se guardó.',
    discard: 'Descartar',
    keepEditing: 'Seguir editando',
    photo: 'Foto',
    takePhoto: 'Tomar foto',
    opensCamera: 'Abre la cámara',
    chooseFromGallery: 'Elegir de la galería',
    removePhoto: 'Quitar foto',
    done: 'Listo',
    nothingFound: 'No se encontró nada',
    search: 'Buscar',
    clear: 'Borrar',
    months: const [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ],
    weekdayInitials: const ['D', 'L', 'M', 'X', 'J', 'V', 'S'],
    weekdaysShort: const ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'],
    weekdaysLong: const ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'],
    formatDate: (d) => '${two(d.day)}/${two(d.month)}/${d.year}',
    formatDayMonth: (d) => '${two(d.day)}/${two(d.month)}',
    longDatePattern: (weekday, day, month) => '$weekday, $day de ${month.toLowerCase()}',
    previousMonth: 'Mes anterior',
    nextMonth: 'Mes siguiente',
    backToCurrentMonth: 'Volver al mes actual',
    todaySuffix: ', hoy',
    markersCount: (n) => ', $n marcador(es)',
    nothing: 'nada',
    less: 'menos',
    more: 'más',
    close: 'Cerrar',
    commandHint: 'Buscar acción o pantalla',
    recent: 'Recientes',
    nothingFoundFor: (query) => 'No se encontró nada para “$query”',
    start: 'Empezar',
    next: 'Continuar',
    skip: 'Omitir',
    pageOf: (page, total) => 'Página $page de $total',
    firstSteps: 'Primeros pasos',
    countOf: (done, total) => '$done de $total',
    allDone: '¡Todo listo!',
    planNames: const ['Gratis', 'Pro', 'Max'],
    yourPlan: 'TU PLAN',
    monthly: 'Mensual',
    yearly: 'Anual',
    yearlySavings: (pct) => 'Anual · −$pct%',
    comparePlans: 'Comparar los planes',
    restorePurchases: 'Restaurar compras',
    manageSubscription: 'Administrar suscripción',
    confirmingSubscription: 'Confirmando tu suscripción…',
    mostComplete: 'Más completo',
    currentPlan: 'Tu plan actual',
    cheapestBadge: 'MÁS BARATA',
    cheapest: 'más barata',
    wasPrice: (price) => 'antes $price',
    signInWithGoogle: 'Iniciar sesión con Google',
    seePlans: 'Ver planes',
    notNow: 'Ahora no',
    paidPlanOnly: 'Disponible en planes de pago',
    thisMonth: 'este mes',
    quotaUsed: (used, limit, period) => '$used de $limit $period',
    limitReached: (text) => '$text, límite alcanzado',
    syncAllSaved: 'Todo guardado',
    syncPending: (n) => n == 1 ? '1 por enviar' : '$n por enviar',
    syncSending: 'Enviando…',
    syncFailed: 'Falló · Reintentar',
    offline: 'Sin conexión',
    syncOfflinePending: (n) => 'Sin conexión · $n por enviar',
    saved: 'Guardado',
    waitingToSend: 'Esperando envío',
    sendFailed: 'No se pudo enviar',
    requiredField: 'Campo obligatorio',
    enterAmount: 'Ingresa un valor',
    enterNumber: 'Ingresa un número',
    numberRange: (min, max) => 'Usa un número de $min a $max',
    amount: 'Valor',
    backspaceHold: 'Borrar (mantén para poner en cero)',
    today: 'Hoy',
    tomorrow: 'Mañana',
    yesterday: 'Ayer',
    otherDate: 'Otra…',
    pickDate: 'Elegir fecha',
    time: 'Hora',
    clearDate: 'Borrar fecha',
    choose: 'Elegir',
    noTime: 'Sin horario',
    clearTime: 'Borrar horario',
    offlineBanner: 'Sin conexión — mostrando lo que ya se descargó',
    backOnline: 'De nuevo en línea',
    unreadCount: (name, n) => '$name, $n sin leer',
    addPerson: 'Agregar persona',
    tabOf: (label, index, count) => '$label, pestaña $index de $count',
    cardsCount: (title, n) => '$title, $n ${n == 1 ? 'tarjeta' : 'tarjetas'}',
    searchMenu: 'Buscar en el menú',
    clearSearch: 'Borrar búsqueda',
    menuNothingFound: (query) => 'No se encontró nada para "$query".',
    plansAndSubscription: 'Planes y suscripción',
    appearanceAndAbout: 'Apariencia y acerca de',
    themeSystem: 'Sistema',
    themeLight: 'Claro',
    themeDark: 'Oscuro',
    deleteMyAccount: 'Eliminar mi cuenta',
    signOut: 'Cerrar sesión',
    gaugeCheap: 'barato',
    gaugeNormal: 'normal',
    gaugeExpensive: 'caro',
    gauge: 'Indicador',
    days: 'días',
    remainingOf: (left, total, unit) => 'Quedan $left de $total $unit',
    remaining: (left, unit) => 'Quedan $left $unit',
    undo: 'Deshacer',
    before: 'Antes',
    after: 'Después',
    compareLabel: (a, b) => 'Comparar $a y $b',
    stepDone: 'hecho',
    stepNow: 'ahora',
    stepNext: 'a continuación',
    stepOf: (step, total) => 'Paso $step de $total',
    dismissTip: 'Descartar consejo',
    back: 'Volver',
    decrease: 'Disminuir',
    increase: 'Aumentar',
    target: 'meta',
    noData: 'sin datos',
    chartSummary: (min, max, last) => 'mínimo $min, máximo $max, último $last',
    chartOf: (name) => name == null ? 'Gráfico' : 'Gráfico de $name',
    yourPoints: 'Tus puntos',
    pointsCount: (n) => '$n puntos',
    pointsShort: ' pts',
    towardsLevel: (level) => 'Rumbo a $level',
    pointsToLevel: (n, level) => 'Faltan $n para $level',
    spentEarned: (title, spent, points) => '$title: gastó $spent, ganó $points puntos',
    buy: 'Compra',
    sell: 'Venta',
    asset: 'ACTIVO',
    changeOf: (pct) => ', variación $pct',
    areaChart: 'Gráfico de área',
    chartOfLabel: (name) => 'Gráfico de $name',
    total: 'Total',
    donutSummary: (total, parts) => 'Dona: $total. $parts',
    flightLabel: (from, to, pct) => 'Vuelo de $from a $to, $pct% del trayecto',
    showBoardingQr: 'Mostrar QR de embarque',
    itemOf: (i, n) => 'Elemento $i de $n',
    nOfTotal: (i, n) => '$i de $n',
    imageOf: (i, n) => 'Imagen $i de $n',
    previousThumbs: 'Miniaturas anteriores',
    nextThumbs: 'Miniaturas siguientes',
    notifications: 'Notificaciones',
    newCount: (label, n) => '$label: $n nueva${n == 1 ? '' : 's'}',
    newItem: 'Nuevo',
    add: 'Agregar',
    newsCount: (n) => ', $n ${n == 1 ? 'novedad' : 'novedades'}',
    totalClosed: 'Total completo',
    missing: 'Falta',
    over: 'Excede',
    shareOf: (name) => 'Parte de $name',
    confirmed: 'Confirmado',
    holdToConfirm: 'mantén presionado para confirmar',
    slideToConfirm: 'desliza hasta el final para confirmar',
    stateLoading: (label) => '$label: cargando',
    stateDone: (label) => '$label: completado',
    stateFailed: (label) => '$label: falló',
    totalBalance: 'Saldo total',
    closeCards: 'Cerrar tarjetas',
    openCards: (n) => 'Abrir $n tarjetas',
    taskDone: 'Hecho',
    taskPending: 'Pendiente',
    pickDay: 'Elegir día',
    monthOpenCalendar: (month) => 'Mes: $month. Abrir calendario',
    withEvents: ', con eventos',
    nowAt: (time) => 'Ahora, $time',
    agoNow: 'ahora',
    agoMinutes: (n) => 'hace $n min',
    agoHours: (n) => 'hace $n h',
    agoYesterday: 'ayer',
    agoDays: (n) => 'hace $n días',
    sending: 'Enviando…',
    unavailable: 'No disponible',
    deviceNoResponse: 'No respondió',
    noPermission: 'Sin permiso',
    turnOn: 'Encender',
    turnOff: 'Apagar',
    openDetails: 'Abrir detalles',
    thermostatLabel: 'Temperatura',
    thermostatCurrent: 'Ahora',
    thermostatOff: 'Apagado',
    thermostatHeating: 'Calentando',
    thermostatCooling: 'Enfriando',
    thermostatIdle: 'En el objetivo',
    thermostatMode: 'Modo',
    thermostatModeOff: 'Apagado',
    thermostatModeHeat: 'Calor',
    thermostatModeCool: 'Frío',
    thermostatModeAuto: 'Automático',
    codeBackspace: 'Borrar',
    codeError: 'Código incorrecto',
    codeDigits: 'Dígitos ingresados',
    everyDay: 'Todos los días',
    weekdaysOnly: 'Días hábiles',
    weekend: 'Fin de semana',
    weekdayPickerLabel: 'Días de la semana',
    weekdaysFull: const ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'],
    loadingEllipsis: 'Cargando…',
    logbookEnd: 'Inicio del registro',
    logbookEmpty: 'Aún no hay registros',
    logbookLabel: 'Registro de eventos',
    stateBandsEmpty: 'Sin cambios en este período',
    noReadings: 'sin lecturas',
    chartNoReadings: 'Sin lecturas en este período',
    showAll: 'Ver todo',
    chartLoading: 'Cargando gráfico',
    chartMin: 'mínimo',
    chartMax: 'máximo',
    chartLast: 'último',
    chartUntil: 'a',
    emptyYet: 'Aún no hay nada aquí.',
    sortBy: 'Ordenar por',
    ascending: 'ascendente',
    descending: 'descendente',
    searchIcon: 'Buscar ícono',
    noIcon: 'Sin ícono',
    noIconFor: (query) => 'Ningún ícono con “$query”',
    moveUp: 'Subir',
    moveDown: 'Bajar',
    duplicate: 'Duplicar',
    delete: 'Eliminar',
    enabled: 'Activo',
    expand: 'Expandir',
    collapse: 'Contraer',
    dragToReorder: 'Arrastrar para reordenar',
    dismiss: 'Descartar',
    micIdle: 'Hablar',
    micListening: 'Escuchando, toca para detener',
    micProcessing: 'Procesando',
    micError: 'Error del micrófono, toca para reintentar',
    lockMessage: 'La app está bloqueada',
    unlock: 'Desbloquear',
    usePin: 'Usar PIN',
    useBiometrics: 'Usar biometría',
    cameraLive: 'EN VIVO',
    cameraLoading: 'Cargando imagen',
    cameraError: 'No se pudo cargar la imagen',
    cameraOffline: 'Cámara sin conexión',
    agoSeconds: (n) => 'hace $n s',
    agoDaysShort: (n) => 'hace $n d',
    play: 'Reproducir',
    pause: 'Pausar',
    previous: 'Anterior',
    nextTrack: 'Siguiente',
    volume: 'Volumen',
    position: 'Posición',
    nothingPlaying: 'Nada en reproducción',
    weatherMin: 'Mín',
    weatherMax: 'Máx',
    humidity: 'Humedad',
    wind: 'Viento',
    weatherClear: 'Despejado',
    weatherClearNight: 'Noche despejada',
    weatherPartlyCloudy: 'Parcialmente nublado',
    weatherCloudy: 'Nublado',
    weatherRain: 'Lluvia',
    weatherStorm: 'Tormenta',
    weatherSnow: 'Nieve',
    weatherFog: 'Niebla',
    weatherWind: 'Ventoso',
    searching: 'Buscando…',
    foundCount: (n) => n == 1 ? '1 encontrado' : '$n encontrados',
    searchAgain: 'Buscar de nuevo',
    dpadUp: 'Arriba',
    dpadDown: 'Abajo',
    dpadLeft: 'Izquierda',
    dpadRight: 'Derecha',
    dpadOk: 'OK',
    dpadHome: 'Inicio',
    dpadMenu: 'Menú',
    volumeUp: 'Subir volumen',
    volumeDown: 'Bajar volumen',
    mute: 'Silenciar',
    channelUp: 'Canal siguiente',
    channelDown: 'Canal anterior',
    volumeShort: 'VOL',
    channelShort: 'CH',
    unmute: 'Activar sonido',
    feelsLike: 'Sensación',
    rainChance: 'Probabilidad de lluvia',
    agendaEmptyDay: 'Nada este día',
    deviceRun: 'Accionar',
    holdToTalk: 'mantén pulsado para hablar',
    localeSystemShort: 'Auto',
    localeSystem: 'Seguir el sistema',
    unread: 'No leído',
    colorCustom: 'Personalizado',
    colorPickOther: 'Elegir otro color',
    colorHue: 'Tono',
    colorSaturation: 'Saturación',
    colorBrightness: 'Brillo',
    colorHex: 'Código hex',
    colorHexInvalid: 'Usa el formato #RRGGBB',
    allDay: 'Todo el día',
    copy: 'Copiar',
    copied: 'Copiado',
    dangerZone: 'Zona de peligro',
  );

  /// Todos os textos (as funções com argumentos de exemplo), para teste.
  @visibleForTesting
  Map<String, String> get debugSamples => {
    'offlineError': offlineError,
    'genericError': genericError,
    'retry': retry,
    'loading': loading,
    'loadingMore': loadingMore,
    'loadMore': loadMore,
    'endOfList': endOfList,
    'loadFailed': loadFailed,
    'progressOver': progressOver('X'),
    'moreOptions': moreOptions,
    'checked': checked,
    'clearSelection': clearSelection,
    'selectedCount': selectedCount(2),
    'chatSending': chatSending,
    'chatSent': chatSent,
    'chatNotSent': chatNotSent,
    'chatThinking': chatThinking,
    'chatHint': chatHint,
    'send': send,
    'confirm': confirm,
    'cancel': cancel,
    'save': save,
    'name': name,
    'irreversibleWord': irreversibleWord,
    'typeToConfirm': typeToConfirm('X'),
    'pleaseWait': pleaseWait,
    'cancelling': cancelling,
    'discardTitle': discardTitle,
    'discardMessage': discardMessage,
    'discard': discard,
    'keepEditing': keepEditing,
    'photo': photo,
    'takePhoto': takePhoto,
    'opensCamera': opensCamera,
    'chooseFromGallery': chooseFromGallery,
    'removePhoto': removePhoto,
    'done': done,
    'nothingFound': nothingFound,
    'search': search,
    'clear': clear,
    for (var i = 0; i < months.length; i++) 'months[$i]': months[i],
    for (var i = 0; i < weekdayInitials.length; i++) 'weekdayInitials[$i]': weekdayInitials[i],
    for (var i = 0; i < weekdaysShort.length; i++) 'weekdaysShort[$i]': weekdaysShort[i],
    for (var i = 0; i < weekdaysLong.length; i++) 'weekdaysLong[$i]': weekdaysLong[i],
    'formatDate': formatDate(DateTime(2026, 10, 5)),
    'formatDayMonth': formatDayMonth(DateTime(2026, 10, 5)),
    'longDatePattern': longDatePattern('X', 2, 'X'),
    'previousMonth': previousMonth,
    'nextMonth': nextMonth,
    'backToCurrentMonth': backToCurrentMonth,
    'todaySuffix': todaySuffix,
    'markersCount': markersCount(2),
    'nothing': nothing,
    'less': less,
    'more': more,
    'close': close,
    'commandHint': commandHint,
    'recent': recent,
    'nothingFoundFor': nothingFoundFor('X'),
    'start': start,
    'next': next,
    'skip': skip,
    'pageOf': pageOf(2, 2),
    'firstSteps': firstSteps,
    'countOf': countOf(2, 2),
    'allDone': allDone,
    for (var i = 0; i < planNames.length; i++) 'planNames[$i]': planNames[i],
    'yourPlan': yourPlan,
    'monthly': monthly,
    'yearly': yearly,
    'yearlySavings': yearlySavings(2),
    'comparePlans': comparePlans,
    'restorePurchases': restorePurchases,
    'manageSubscription': manageSubscription,
    'confirmingSubscription': confirmingSubscription,
    'mostComplete': mostComplete,
    'currentPlan': currentPlan,
    'cheapestBadge': cheapestBadge,
    'cheapest': cheapest,
    'wasPrice': wasPrice('X'),
    'signInWithGoogle': signInWithGoogle,
    'seePlans': seePlans,
    'notNow': notNow,
    'paidPlanOnly': paidPlanOnly,
    'thisMonth': thisMonth,
    'quotaUsed': quotaUsed(2, 2, 'X'),
    'limitReached': limitReached('X'),
    'syncAllSaved': syncAllSaved,
    'syncPending': syncPending(2),
    'syncSending': syncSending,
    'syncFailed': syncFailed,
    'offline': offline,
    'syncOfflinePending': syncOfflinePending(2),
    'saved': saved,
    'waitingToSend': waitingToSend,
    'sendFailed': sendFailed,
    'requiredField': requiredField,
    'enterAmount': enterAmount,
    'enterNumber': enterNumber,
    'numberRange': numberRange(2, 2),
    'amount': amount,
    'backspaceHold': backspaceHold,
    'today': today,
    'tomorrow': tomorrow,
    'yesterday': yesterday,
    'otherDate': otherDate,
    'pickDate': pickDate,
    'time': time,
    'clearDate': clearDate,
    'choose': choose,
    'noTime': noTime,
    'clearTime': clearTime,
    'offlineBanner': offlineBanner,
    'backOnline': backOnline,
    'unreadCount': unreadCount('X', 2),
    'addPerson': addPerson,
    'tabOf': tabOf('X', 2, 2),
    'cardsCount': cardsCount('X', 2),
    'searchMenu': searchMenu,
    'clearSearch': clearSearch,
    'menuNothingFound': menuNothingFound('X'),
    'plansAndSubscription': plansAndSubscription,
    'appearanceAndAbout': appearanceAndAbout,
    'themeSystem': themeSystem,
    'themeLight': themeLight,
    'themeDark': themeDark,
    'deleteMyAccount': deleteMyAccount,
    'signOut': signOut,
    'gaugeCheap': gaugeCheap,
    'gaugeNormal': gaugeNormal,
    'gaugeExpensive': gaugeExpensive,
    'gauge': gauge,
    'days': days,
    'remainingOf': remainingOf(2, 2, 'X'),
    'remaining': remaining('X', 'X'),
    'undo': undo,
    'before': before,
    'after': after,
    'compareLabel': compareLabel('X', 'X'),
    'stepDone': stepDone,
    'stepNow': stepNow,
    'stepNext': stepNext,
    'stepOf': stepOf(2, 2),
    'dismissTip': dismissTip,
    'back': back,
    'decrease': decrease,
    'increase': increase,
    'target': target,
    'noData': noData,
    'chartSummary': chartSummary('X', 'X', 'X'),
    'chartOf': chartOf('X'),
    'yourPoints': yourPoints,
    'pointsCount': pointsCount('X'),
    'pointsShort': pointsShort,
    'towardsLevel': towardsLevel('X'),
    'pointsToLevel': pointsToLevel('X', 'X'),
    'spentEarned': spentEarned('X', 'X', 2),
    'buy': buy,
    'sell': sell,
    'asset': asset,
    'changeOf': changeOf('X'),
    'areaChart': areaChart,
    'chartOfLabel': chartOfLabel('X'),
    'total': total,
    'donutSummary': donutSummary('X', 'X'),
    'flightLabel': flightLabel('X', 'X', 2),
    'showBoardingQr': showBoardingQr,
    'itemOf': itemOf(2, 2),
    'nOfTotal': nOfTotal(2, 2),
    'imageOf': imageOf(2, 2),
    'previousThumbs': previousThumbs,
    'nextThumbs': nextThumbs,
    'notifications': notifications,
    'newCount': newCount('X', 2),
    'newItem': newItem,
    'add': add,
    'newsCount': newsCount(2),
    'totalClosed': totalClosed,
    'missing': missing,
    'over': over,
    'shareOf': shareOf('X'),
    'confirmed': confirmed,
    'holdToConfirm': holdToConfirm,
    'slideToConfirm': slideToConfirm,
    'stateLoading': stateLoading('X'),
    'stateDone': stateDone('X'),
    'stateFailed': stateFailed('X'),
    'totalBalance': totalBalance,
    'closeCards': closeCards,
    'openCards': openCards(2),
    'taskDone': taskDone,
    'taskPending': taskPending,
    'pickDay': pickDay,
    'monthOpenCalendar': monthOpenCalendar('X'),
    'withEvents': withEvents,
    'nowAt': nowAt('X'),
    'agoNow': agoNow,
    'agoMinutes': agoMinutes(2),
    'agoHours': agoHours(2),
    'agoYesterday': agoYesterday,
    'agoDays': agoDays(2),
    'sending': sending,
    'unavailable': unavailable,
    'deviceNoResponse': deviceNoResponse,
    'noPermission': noPermission,
    'turnOn': turnOn,
    'turnOff': turnOff,
    'openDetails': openDetails,
    'thermostatLabel': thermostatLabel,
    'thermostatCurrent': thermostatCurrent,
    'thermostatOff': thermostatOff,
    'thermostatHeating': thermostatHeating,
    'thermostatCooling': thermostatCooling,
    'thermostatIdle': thermostatIdle,
    'thermostatMode': thermostatMode,
    'thermostatModeOff': thermostatModeOff,
    'thermostatModeHeat': thermostatModeHeat,
    'thermostatModeCool': thermostatModeCool,
    'thermostatModeAuto': thermostatModeAuto,
    'codeBackspace': codeBackspace,
    'codeError': codeError,
    'codeDigits': codeDigits,
    'everyDay': everyDay,
    'weekdaysOnly': weekdaysOnly,
    'weekend': weekend,
    'weekdayPickerLabel': weekdayPickerLabel,
    for (var i = 0; i < weekdaysFull.length; i++) 'weekdaysFull[$i]': weekdaysFull[i],
    'loadingEllipsis': loadingEllipsis,
    'logbookEnd': logbookEnd,
    'logbookEmpty': logbookEmpty,
    'logbookLabel': logbookLabel,
    'stateBandsEmpty': stateBandsEmpty,
    'noReadings': noReadings,
    'chartNoReadings': chartNoReadings,
    'showAll': showAll,
    'chartLoading': chartLoading,
    'chartMin': chartMin,
    'chartMax': chartMax,
    'chartLast': chartLast,
    'chartUntil': chartUntil,
    'emptyYet': emptyYet,
    'sortBy': sortBy,
    'ascending': ascending,
    'descending': descending,
    'searchIcon': searchIcon,
    'noIcon': noIcon,
    'noIconFor': noIconFor('X'),
    'moveUp': moveUp,
    'moveDown': moveDown,
    'duplicate': duplicate,
    'delete': delete,
    'enabled': enabled,
    'expand': expand,
    'collapse': collapse,
    'dragToReorder': dragToReorder,
    'dismiss': dismiss,
    'micIdle': micIdle,
    'micListening': micListening,
    'micProcessing': micProcessing,
    'micError': micError,
    'lockMessage': lockMessage,
    'unlock': unlock,
    'usePin': usePin,
    'useBiometrics': useBiometrics,
    'cameraLive': cameraLive,
    'cameraLoading': cameraLoading,
    'cameraError': cameraError,
    'cameraOffline': cameraOffline,
    'agoSeconds': agoSeconds(2),
    'agoDaysShort': agoDaysShort(2),
    'play': play,
    'pause': pause,
    'previous': previous,
    'nextTrack': nextTrack,
    'volume': volume,
    'position': position,
    'nothingPlaying': nothingPlaying,
    'weatherMin': weatherMin,
    'weatherMax': weatherMax,
    'humidity': humidity,
    'wind': wind,
    'weatherClear': weatherClear,
    'weatherClearNight': weatherClearNight,
    'weatherPartlyCloudy': weatherPartlyCloudy,
    'weatherCloudy': weatherCloudy,
    'weatherRain': weatherRain,
    'weatherStorm': weatherStorm,
    'weatherSnow': weatherSnow,
    'weatherFog': weatherFog,
    'weatherWind': weatherWind,
    'searching': searching,
    'foundCount': foundCount(2),
    'searchAgain': searchAgain,
    'dpadUp': dpadUp,
    'dpadDown': dpadDown,
    'dpadLeft': dpadLeft,
    'dpadRight': dpadRight,
    'dpadOk': dpadOk,
    'dpadHome': dpadHome,
    'dpadMenu': dpadMenu,
    'volumeUp': volumeUp,
    'volumeDown': volumeDown,
    'mute': mute,
    'channelUp': channelUp,
    'channelDown': channelDown,
    'volumeShort': volumeShort,
    'channelShort': channelShort,
    'unmute': unmute,
    'feelsLike': feelsLike,
    'rainChance': rainChance,
    'agendaEmptyDay': agendaEmptyDay,
    'deviceRun': deviceRun,
    'holdToTalk': holdToTalk,
    'localeSystemShort': localeSystemShort,
    'localeSystem': localeSystem,
    'unread': unread,
    'colorCustom': colorCustom,
    'colorPickOther': colorPickOther,
    'colorHue': colorHue,
    'colorSaturation': colorSaturation,
    'colorBrightness': colorBrightness,
    'colorHex': colorHex,
    'colorHexInvalid': colorHexInvalid,
    'allDay': allDay,
    'copy': copy,
    'copied': copied,
    'dangerZone': dangerZone,
  };

  /// Os idiomas prontos.
  static const supportedLocales = [Locale('pt', 'BR'), Locale('en'), Locale('es')];

  /// Para os `localizationsDelegates` do app (pt, en, es).
  static const LocalizationsDelegate<SsStrings> delegate = SsStringsDelegate();

  /// O pronto para [locale] (pelo idioma), ou nulo se não houver.
  static SsStrings? forLocale(Locale locale) => switch (locale.languageCode) {
    'pt' => pt,
    'en' => en,
    'es' => es,
    _ => null,
  };

  /// Os textos para este ponto da árvore (ver a ordem na doc da classe).
  static SsStrings of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SsStringsScope>();
    if (scope?.strings != null) return scope!.strings!;
    final base = _base(context);
    return scope?.apply?.call(base) ?? base;
  }

  static SsStrings _base(BuildContext context) {
    final registrado = Localizations.of<SsStrings>(context, SsStrings);
    if (registrado != null) return registrado;
    final locale = Localizations.maybeLocaleOf(context);
    if (locale == null) return pt;
    // Sem idioma configurado, o Flutter fica em en-US com os textos padrão do
    // Material: aí o app não escolheu inglês, e vale o português.
    if (locale.languageCode == 'en') {
      final material = Localizations.of<MaterialLocalizations>(context, MaterialLocalizations);
      if (material == null || material is DefaultMaterialLocalizations) return pt;
    }
    return forLocale(locale) ?? pt;
  }

  SsStrings copyWith({
    Locale? locale,
    String? offlineError,
    String? genericError,
    String? retry,
    String? loading,
    String? loadingMore,
    String? loadMore,
    String? endOfList,
    String? loadFailed,
    String Function(String pct)? progressOver,
    String? moreOptions,
    String? checked,
    String? clearSelection,
    String Function(int n)? selectedCount,
    String? chatSending,
    String? chatSent,
    String? chatNotSent,
    String? chatThinking,
    String? chatHint,
    String? send,
    String? confirm,
    String? cancel,
    String? save,
    String? name,
    String? irreversibleWord,
    String Function(String word)? typeToConfirm,
    String? pleaseWait,
    String? cancelling,
    String? discardTitle,
    String? discardMessage,
    String? discard,
    String? keepEditing,
    String? photo,
    String? takePhoto,
    String? opensCamera,
    String? chooseFromGallery,
    String? removePhoto,
    String? done,
    String? nothingFound,
    String? search,
    String? clear,
    List<String>? months,
    List<String>? weekdayInitials,
    List<String>? weekdaysShort,
    List<String>? weekdaysLong,
    String Function(DateTime d)? formatDate,
    String Function(DateTime d)? formatDayMonth,
    String Function(String weekday, int day, String month)? longDatePattern,
    String? previousMonth,
    String? nextMonth,
    String? backToCurrentMonth,
    String? todaySuffix,
    String Function(int n)? markersCount,
    String? nothing,
    String? less,
    String? more,
    String? close,
    String? commandHint,
    String? recent,
    String Function(String query)? nothingFoundFor,
    String? start,
    String? next,
    String? skip,
    String Function(int page, int total)? pageOf,
    String? firstSteps,
    String Function(int done, int total)? countOf,
    String? allDone,
    List<String>? planNames,
    String? yourPlan,
    String? monthly,
    String? yearly,
    String Function(int pct)? yearlySavings,
    String? comparePlans,
    String? restorePurchases,
    String? manageSubscription,
    String? confirmingSubscription,
    String? mostComplete,
    String? currentPlan,
    String? cheapestBadge,
    String? cheapest,
    String Function(String price)? wasPrice,
    String? signInWithGoogle,
    String? seePlans,
    String? notNow,
    String? paidPlanOnly,
    String? thisMonth,
    String Function(int used, int limit, String period)? quotaUsed,
    String Function(String text)? limitReached,
    String? syncAllSaved,
    String Function(int n)? syncPending,
    String? syncSending,
    String? syncFailed,
    String? offline,
    String Function(int n)? syncOfflinePending,
    String? saved,
    String? waitingToSend,
    String? sendFailed,
    String? requiredField,
    String? enterAmount,
    String? enterNumber,
    String Function(int min, int max)? numberRange,
    String? amount,
    String? backspaceHold,
    String? today,
    String? tomorrow,
    String? yesterday,
    String? otherDate,
    String? pickDate,
    String? time,
    String? clearDate,
    String? choose,
    String? noTime,
    String? clearTime,
    String? offlineBanner,
    String? backOnline,
    String Function(String name, int n)? unreadCount,
    String? addPerson,
    String Function(String label, int index, int count)? tabOf,
    String Function(String title, int n)? cardsCount,
    String? searchMenu,
    String? clearSearch,
    String Function(String query)? menuNothingFound,
    String? plansAndSubscription,
    String? appearanceAndAbout,
    String? themeSystem,
    String? themeLight,
    String? themeDark,
    String? deleteMyAccount,
    String? signOut,
    String? gaugeCheap,
    String? gaugeNormal,
    String? gaugeExpensive,
    String? gauge,
    String? days,
    String Function(int left, int total, String unit)? remainingOf,
    String Function(String left, String unit)? remaining,
    String? undo,
    String? before,
    String? after,
    String Function(String a, String b)? compareLabel,
    String? stepDone,
    String? stepNow,
    String? stepNext,
    String Function(int step, int total)? stepOf,
    String? dismissTip,
    String? back,
    String? decrease,
    String? increase,
    String? target,
    String? noData,
    String Function(String min, String max, String last)? chartSummary,
    String Function(String? name)? chartOf,
    String? yourPoints,
    String Function(String n)? pointsCount,
    String? pointsShort,
    String Function(String level)? towardsLevel,
    String Function(String n, String level)? pointsToLevel,
    String Function(String title, String spent, int points)? spentEarned,
    String? buy,
    String? sell,
    String? asset,
    String Function(String pct)? changeOf,
    String? areaChart,
    String Function(String name)? chartOfLabel,
    String? total,
    String Function(String total, String parts)? donutSummary,
    String Function(String from, String to, int pct)? flightLabel,
    String? showBoardingQr,
    String Function(int i, int n)? itemOf,
    String Function(int i, int n)? nOfTotal,
    String Function(int i, int n)? imageOf,
    String? previousThumbs,
    String? nextThumbs,
    String? notifications,
    String Function(String label, int n)? newCount,
    String? newItem,
    String? add,
    String Function(int n)? newsCount,
    String? totalClosed,
    String? missing,
    String? over,
    String Function(String name)? shareOf,
    String? confirmed,
    String? holdToConfirm,
    String? slideToConfirm,
    String Function(String label)? stateLoading,
    String Function(String label)? stateDone,
    String Function(String label)? stateFailed,
    String? totalBalance,
    String? closeCards,
    String Function(int n)? openCards,
    String? taskDone,
    String? taskPending,
    String? pickDay,
    String Function(String month)? monthOpenCalendar,
    String? withEvents,
    String Function(String time)? nowAt,
    String? agoNow,
    String Function(int n)? agoMinutes,
    String Function(int n)? agoHours,
    String? agoYesterday,
    String Function(int n)? agoDays,
    String? sending,
    String? unavailable,
    String? deviceNoResponse,
    String? noPermission,
    String? turnOn,
    String? turnOff,
    String? openDetails,
    String? thermostatLabel,
    String? thermostatCurrent,
    String? thermostatOff,
    String? thermostatHeating,
    String? thermostatCooling,
    String? thermostatIdle,
    String? thermostatMode,
    String? thermostatModeOff,
    String? thermostatModeHeat,
    String? thermostatModeCool,
    String? thermostatModeAuto,
    String? codeBackspace,
    String? codeError,
    String? codeDigits,
    String? everyDay,
    String? weekdaysOnly,
    String? weekend,
    String? weekdayPickerLabel,
    List<String>? weekdaysFull,
    String? loadingEllipsis,
    String? logbookEnd,
    String? logbookEmpty,
    String? logbookLabel,
    String? stateBandsEmpty,
    String? noReadings,
    String? chartNoReadings,
    String? showAll,
    String? chartLoading,
    String? chartMin,
    String? chartMax,
    String? chartLast,
    String? chartUntil,
    String? emptyYet,
    String? sortBy,
    String? ascending,
    String? descending,
    String? searchIcon,
    String? noIcon,
    String Function(String query)? noIconFor,
    String? moveUp,
    String? moveDown,
    String? duplicate,
    String? delete,
    String? enabled,
    String? expand,
    String? collapse,
    String? dragToReorder,
    String? dismiss,
    String? micIdle,
    String? micListening,
    String? micProcessing,
    String? micError,
    String? lockMessage,
    String? unlock,
    String? usePin,
    String? useBiometrics,
    String? cameraLive,
    String? cameraLoading,
    String? cameraError,
    String? cameraOffline,
    String Function(int n)? agoSeconds,
    String Function(int n)? agoDaysShort,
    String? play,
    String? pause,
    String? previous,
    String? nextTrack,
    String? volume,
    String? position,
    String? nothingPlaying,
    String? weatherMin,
    String? weatherMax,
    String? humidity,
    String? wind,
    String? weatherClear,
    String? weatherClearNight,
    String? weatherPartlyCloudy,
    String? weatherCloudy,
    String? weatherRain,
    String? weatherStorm,
    String? weatherSnow,
    String? weatherFog,
    String? weatherWind,
    String? searching,
    String Function(int n)? foundCount,
    String? searchAgain,
    String? dpadUp,
    String? dpadDown,
    String? dpadLeft,
    String? dpadRight,
    String? dpadOk,
    String? dpadHome,
    String? dpadMenu,
    String? volumeUp,
    String? volumeDown,
    String? mute,
    String? channelUp,
    String? channelDown,
    String? volumeShort,
    String? channelShort,
    String? unmute,
    String? feelsLike,
    String? rainChance,
    String? agendaEmptyDay,
    String? deviceRun,
    String? holdToTalk,
    String? localeSystemShort,
    String? localeSystem,
    String? unread,
    String? colorCustom,
    String? colorPickOther,
    String? colorHue,
    String? colorSaturation,
    String? colorBrightness,
    String? colorHex,
    String? colorHexInvalid,
    String? allDay,
    String? copy,
    String? copied,
    String? dangerZone,
  }) => SsStrings(
    locale: locale ?? this.locale,
    offlineError: offlineError ?? this.offlineError,
    genericError: genericError ?? this.genericError,
    retry: retry ?? this.retry,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMore: loadMore ?? this.loadMore,
    endOfList: endOfList ?? this.endOfList,
    loadFailed: loadFailed ?? this.loadFailed,
    progressOver: progressOver ?? this.progressOver,
    moreOptions: moreOptions ?? this.moreOptions,
    checked: checked ?? this.checked,
    clearSelection: clearSelection ?? this.clearSelection,
    selectedCount: selectedCount ?? this.selectedCount,
    chatSending: chatSending ?? this.chatSending,
    chatSent: chatSent ?? this.chatSent,
    chatNotSent: chatNotSent ?? this.chatNotSent,
    chatThinking: chatThinking ?? this.chatThinking,
    chatHint: chatHint ?? this.chatHint,
    send: send ?? this.send,
    confirm: confirm ?? this.confirm,
    cancel: cancel ?? this.cancel,
    save: save ?? this.save,
    name: name ?? this.name,
    irreversibleWord: irreversibleWord ?? this.irreversibleWord,
    typeToConfirm: typeToConfirm ?? this.typeToConfirm,
    pleaseWait: pleaseWait ?? this.pleaseWait,
    cancelling: cancelling ?? this.cancelling,
    discardTitle: discardTitle ?? this.discardTitle,
    discardMessage: discardMessage ?? this.discardMessage,
    discard: discard ?? this.discard,
    keepEditing: keepEditing ?? this.keepEditing,
    photo: photo ?? this.photo,
    takePhoto: takePhoto ?? this.takePhoto,
    opensCamera: opensCamera ?? this.opensCamera,
    chooseFromGallery: chooseFromGallery ?? this.chooseFromGallery,
    removePhoto: removePhoto ?? this.removePhoto,
    done: done ?? this.done,
    nothingFound: nothingFound ?? this.nothingFound,
    search: search ?? this.search,
    clear: clear ?? this.clear,
    months: months ?? this.months,
    weekdayInitials: weekdayInitials ?? this.weekdayInitials,
    weekdaysShort: weekdaysShort ?? this.weekdaysShort,
    weekdaysLong: weekdaysLong ?? this.weekdaysLong,
    formatDate: formatDate ?? this.formatDate,
    formatDayMonth: formatDayMonth ?? this.formatDayMonth,
    longDatePattern: longDatePattern ?? this.longDatePattern,
    previousMonth: previousMonth ?? this.previousMonth,
    nextMonth: nextMonth ?? this.nextMonth,
    backToCurrentMonth: backToCurrentMonth ?? this.backToCurrentMonth,
    todaySuffix: todaySuffix ?? this.todaySuffix,
    markersCount: markersCount ?? this.markersCount,
    nothing: nothing ?? this.nothing,
    less: less ?? this.less,
    more: more ?? this.more,
    close: close ?? this.close,
    commandHint: commandHint ?? this.commandHint,
    recent: recent ?? this.recent,
    nothingFoundFor: nothingFoundFor ?? this.nothingFoundFor,
    start: start ?? this.start,
    next: next ?? this.next,
    skip: skip ?? this.skip,
    pageOf: pageOf ?? this.pageOf,
    firstSteps: firstSteps ?? this.firstSteps,
    countOf: countOf ?? this.countOf,
    allDone: allDone ?? this.allDone,
    planNames: planNames ?? this.planNames,
    yourPlan: yourPlan ?? this.yourPlan,
    monthly: monthly ?? this.monthly,
    yearly: yearly ?? this.yearly,
    yearlySavings: yearlySavings ?? this.yearlySavings,
    comparePlans: comparePlans ?? this.comparePlans,
    restorePurchases: restorePurchases ?? this.restorePurchases,
    manageSubscription: manageSubscription ?? this.manageSubscription,
    confirmingSubscription: confirmingSubscription ?? this.confirmingSubscription,
    mostComplete: mostComplete ?? this.mostComplete,
    currentPlan: currentPlan ?? this.currentPlan,
    cheapestBadge: cheapestBadge ?? this.cheapestBadge,
    cheapest: cheapest ?? this.cheapest,
    wasPrice: wasPrice ?? this.wasPrice,
    signInWithGoogle: signInWithGoogle ?? this.signInWithGoogle,
    seePlans: seePlans ?? this.seePlans,
    notNow: notNow ?? this.notNow,
    paidPlanOnly: paidPlanOnly ?? this.paidPlanOnly,
    thisMonth: thisMonth ?? this.thisMonth,
    quotaUsed: quotaUsed ?? this.quotaUsed,
    limitReached: limitReached ?? this.limitReached,
    syncAllSaved: syncAllSaved ?? this.syncAllSaved,
    syncPending: syncPending ?? this.syncPending,
    syncSending: syncSending ?? this.syncSending,
    syncFailed: syncFailed ?? this.syncFailed,
    offline: offline ?? this.offline,
    syncOfflinePending: syncOfflinePending ?? this.syncOfflinePending,
    saved: saved ?? this.saved,
    waitingToSend: waitingToSend ?? this.waitingToSend,
    sendFailed: sendFailed ?? this.sendFailed,
    requiredField: requiredField ?? this.requiredField,
    enterAmount: enterAmount ?? this.enterAmount,
    enterNumber: enterNumber ?? this.enterNumber,
    numberRange: numberRange ?? this.numberRange,
    amount: amount ?? this.amount,
    backspaceHold: backspaceHold ?? this.backspaceHold,
    today: today ?? this.today,
    tomorrow: tomorrow ?? this.tomorrow,
    yesterday: yesterday ?? this.yesterday,
    otherDate: otherDate ?? this.otherDate,
    pickDate: pickDate ?? this.pickDate,
    time: time ?? this.time,
    clearDate: clearDate ?? this.clearDate,
    choose: choose ?? this.choose,
    noTime: noTime ?? this.noTime,
    clearTime: clearTime ?? this.clearTime,
    offlineBanner: offlineBanner ?? this.offlineBanner,
    backOnline: backOnline ?? this.backOnline,
    unreadCount: unreadCount ?? this.unreadCount,
    addPerson: addPerson ?? this.addPerson,
    tabOf: tabOf ?? this.tabOf,
    cardsCount: cardsCount ?? this.cardsCount,
    searchMenu: searchMenu ?? this.searchMenu,
    clearSearch: clearSearch ?? this.clearSearch,
    menuNothingFound: menuNothingFound ?? this.menuNothingFound,
    plansAndSubscription: plansAndSubscription ?? this.plansAndSubscription,
    appearanceAndAbout: appearanceAndAbout ?? this.appearanceAndAbout,
    themeSystem: themeSystem ?? this.themeSystem,
    themeLight: themeLight ?? this.themeLight,
    themeDark: themeDark ?? this.themeDark,
    deleteMyAccount: deleteMyAccount ?? this.deleteMyAccount,
    signOut: signOut ?? this.signOut,
    gaugeCheap: gaugeCheap ?? this.gaugeCheap,
    gaugeNormal: gaugeNormal ?? this.gaugeNormal,
    gaugeExpensive: gaugeExpensive ?? this.gaugeExpensive,
    gauge: gauge ?? this.gauge,
    days: days ?? this.days,
    remainingOf: remainingOf ?? this.remainingOf,
    remaining: remaining ?? this.remaining,
    undo: undo ?? this.undo,
    before: before ?? this.before,
    after: after ?? this.after,
    compareLabel: compareLabel ?? this.compareLabel,
    stepDone: stepDone ?? this.stepDone,
    stepNow: stepNow ?? this.stepNow,
    stepNext: stepNext ?? this.stepNext,
    stepOf: stepOf ?? this.stepOf,
    dismissTip: dismissTip ?? this.dismissTip,
    back: back ?? this.back,
    decrease: decrease ?? this.decrease,
    increase: increase ?? this.increase,
    target: target ?? this.target,
    noData: noData ?? this.noData,
    chartSummary: chartSummary ?? this.chartSummary,
    chartOf: chartOf ?? this.chartOf,
    yourPoints: yourPoints ?? this.yourPoints,
    pointsCount: pointsCount ?? this.pointsCount,
    pointsShort: pointsShort ?? this.pointsShort,
    towardsLevel: towardsLevel ?? this.towardsLevel,
    pointsToLevel: pointsToLevel ?? this.pointsToLevel,
    spentEarned: spentEarned ?? this.spentEarned,
    buy: buy ?? this.buy,
    sell: sell ?? this.sell,
    asset: asset ?? this.asset,
    changeOf: changeOf ?? this.changeOf,
    areaChart: areaChart ?? this.areaChart,
    chartOfLabel: chartOfLabel ?? this.chartOfLabel,
    total: total ?? this.total,
    donutSummary: donutSummary ?? this.donutSummary,
    flightLabel: flightLabel ?? this.flightLabel,
    showBoardingQr: showBoardingQr ?? this.showBoardingQr,
    itemOf: itemOf ?? this.itemOf,
    nOfTotal: nOfTotal ?? this.nOfTotal,
    imageOf: imageOf ?? this.imageOf,
    previousThumbs: previousThumbs ?? this.previousThumbs,
    nextThumbs: nextThumbs ?? this.nextThumbs,
    notifications: notifications ?? this.notifications,
    newCount: newCount ?? this.newCount,
    newItem: newItem ?? this.newItem,
    add: add ?? this.add,
    newsCount: newsCount ?? this.newsCount,
    totalClosed: totalClosed ?? this.totalClosed,
    missing: missing ?? this.missing,
    over: over ?? this.over,
    shareOf: shareOf ?? this.shareOf,
    confirmed: confirmed ?? this.confirmed,
    holdToConfirm: holdToConfirm ?? this.holdToConfirm,
    slideToConfirm: slideToConfirm ?? this.slideToConfirm,
    stateLoading: stateLoading ?? this.stateLoading,
    stateDone: stateDone ?? this.stateDone,
    stateFailed: stateFailed ?? this.stateFailed,
    totalBalance: totalBalance ?? this.totalBalance,
    closeCards: closeCards ?? this.closeCards,
    openCards: openCards ?? this.openCards,
    taskDone: taskDone ?? this.taskDone,
    taskPending: taskPending ?? this.taskPending,
    pickDay: pickDay ?? this.pickDay,
    monthOpenCalendar: monthOpenCalendar ?? this.monthOpenCalendar,
    withEvents: withEvents ?? this.withEvents,
    nowAt: nowAt ?? this.nowAt,
    agoNow: agoNow ?? this.agoNow,
    agoMinutes: agoMinutes ?? this.agoMinutes,
    agoHours: agoHours ?? this.agoHours,
    agoYesterday: agoYesterday ?? this.agoYesterday,
    agoDays: agoDays ?? this.agoDays,
    sending: sending ?? this.sending,
    unavailable: unavailable ?? this.unavailable,
    deviceNoResponse: deviceNoResponse ?? this.deviceNoResponse,
    noPermission: noPermission ?? this.noPermission,
    turnOn: turnOn ?? this.turnOn,
    turnOff: turnOff ?? this.turnOff,
    openDetails: openDetails ?? this.openDetails,
    thermostatLabel: thermostatLabel ?? this.thermostatLabel,
    thermostatCurrent: thermostatCurrent ?? this.thermostatCurrent,
    thermostatOff: thermostatOff ?? this.thermostatOff,
    thermostatHeating: thermostatHeating ?? this.thermostatHeating,
    thermostatCooling: thermostatCooling ?? this.thermostatCooling,
    thermostatIdle: thermostatIdle ?? this.thermostatIdle,
    thermostatMode: thermostatMode ?? this.thermostatMode,
    thermostatModeOff: thermostatModeOff ?? this.thermostatModeOff,
    thermostatModeHeat: thermostatModeHeat ?? this.thermostatModeHeat,
    thermostatModeCool: thermostatModeCool ?? this.thermostatModeCool,
    thermostatModeAuto: thermostatModeAuto ?? this.thermostatModeAuto,
    codeBackspace: codeBackspace ?? this.codeBackspace,
    codeError: codeError ?? this.codeError,
    codeDigits: codeDigits ?? this.codeDigits,
    everyDay: everyDay ?? this.everyDay,
    weekdaysOnly: weekdaysOnly ?? this.weekdaysOnly,
    weekend: weekend ?? this.weekend,
    weekdayPickerLabel: weekdayPickerLabel ?? this.weekdayPickerLabel,
    weekdaysFull: weekdaysFull ?? this.weekdaysFull,
    loadingEllipsis: loadingEllipsis ?? this.loadingEllipsis,
    logbookEnd: logbookEnd ?? this.logbookEnd,
    logbookEmpty: logbookEmpty ?? this.logbookEmpty,
    logbookLabel: logbookLabel ?? this.logbookLabel,
    stateBandsEmpty: stateBandsEmpty ?? this.stateBandsEmpty,
    noReadings: noReadings ?? this.noReadings,
    chartNoReadings: chartNoReadings ?? this.chartNoReadings,
    showAll: showAll ?? this.showAll,
    chartLoading: chartLoading ?? this.chartLoading,
    chartMin: chartMin ?? this.chartMin,
    chartMax: chartMax ?? this.chartMax,
    chartLast: chartLast ?? this.chartLast,
    chartUntil: chartUntil ?? this.chartUntil,
    emptyYet: emptyYet ?? this.emptyYet,
    sortBy: sortBy ?? this.sortBy,
    ascending: ascending ?? this.ascending,
    descending: descending ?? this.descending,
    searchIcon: searchIcon ?? this.searchIcon,
    noIcon: noIcon ?? this.noIcon,
    noIconFor: noIconFor ?? this.noIconFor,
    moveUp: moveUp ?? this.moveUp,
    moveDown: moveDown ?? this.moveDown,
    duplicate: duplicate ?? this.duplicate,
    delete: delete ?? this.delete,
    enabled: enabled ?? this.enabled,
    expand: expand ?? this.expand,
    collapse: collapse ?? this.collapse,
    dragToReorder: dragToReorder ?? this.dragToReorder,
    dismiss: dismiss ?? this.dismiss,
    micIdle: micIdle ?? this.micIdle,
    micListening: micListening ?? this.micListening,
    micProcessing: micProcessing ?? this.micProcessing,
    micError: micError ?? this.micError,
    lockMessage: lockMessage ?? this.lockMessage,
    unlock: unlock ?? this.unlock,
    usePin: usePin ?? this.usePin,
    useBiometrics: useBiometrics ?? this.useBiometrics,
    cameraLive: cameraLive ?? this.cameraLive,
    cameraLoading: cameraLoading ?? this.cameraLoading,
    cameraError: cameraError ?? this.cameraError,
    cameraOffline: cameraOffline ?? this.cameraOffline,
    agoSeconds: agoSeconds ?? this.agoSeconds,
    agoDaysShort: agoDaysShort ?? this.agoDaysShort,
    play: play ?? this.play,
    pause: pause ?? this.pause,
    previous: previous ?? this.previous,
    nextTrack: nextTrack ?? this.nextTrack,
    volume: volume ?? this.volume,
    position: position ?? this.position,
    nothingPlaying: nothingPlaying ?? this.nothingPlaying,
    weatherMin: weatherMin ?? this.weatherMin,
    weatherMax: weatherMax ?? this.weatherMax,
    humidity: humidity ?? this.humidity,
    wind: wind ?? this.wind,
    weatherClear: weatherClear ?? this.weatherClear,
    weatherClearNight: weatherClearNight ?? this.weatherClearNight,
    weatherPartlyCloudy: weatherPartlyCloudy ?? this.weatherPartlyCloudy,
    weatherCloudy: weatherCloudy ?? this.weatherCloudy,
    weatherRain: weatherRain ?? this.weatherRain,
    weatherStorm: weatherStorm ?? this.weatherStorm,
    weatherSnow: weatherSnow ?? this.weatherSnow,
    weatherFog: weatherFog ?? this.weatherFog,
    weatherWind: weatherWind ?? this.weatherWind,
    searching: searching ?? this.searching,
    foundCount: foundCount ?? this.foundCount,
    searchAgain: searchAgain ?? this.searchAgain,
    dpadUp: dpadUp ?? this.dpadUp,
    dpadDown: dpadDown ?? this.dpadDown,
    dpadLeft: dpadLeft ?? this.dpadLeft,
    dpadRight: dpadRight ?? this.dpadRight,
    dpadOk: dpadOk ?? this.dpadOk,
    dpadHome: dpadHome ?? this.dpadHome,
    dpadMenu: dpadMenu ?? this.dpadMenu,
    volumeUp: volumeUp ?? this.volumeUp,
    volumeDown: volumeDown ?? this.volumeDown,
    mute: mute ?? this.mute,
    channelUp: channelUp ?? this.channelUp,
    channelDown: channelDown ?? this.channelDown,
    volumeShort: volumeShort ?? this.volumeShort,
    channelShort: channelShort ?? this.channelShort,
    unmute: unmute ?? this.unmute,
    feelsLike: feelsLike ?? this.feelsLike,
    rainChance: rainChance ?? this.rainChance,
    agendaEmptyDay: agendaEmptyDay ?? this.agendaEmptyDay,
    deviceRun: deviceRun ?? this.deviceRun,
    holdToTalk: holdToTalk ?? this.holdToTalk,
    localeSystemShort: localeSystemShort ?? this.localeSystemShort,
    localeSystem: localeSystem ?? this.localeSystem,
    unread: unread ?? this.unread,
    colorCustom: colorCustom ?? this.colorCustom,
    colorPickOther: colorPickOther ?? this.colorPickOther,
    colorHue: colorHue ?? this.colorHue,
    colorSaturation: colorSaturation ?? this.colorSaturation,
    colorBrightness: colorBrightness ?? this.colorBrightness,
    colorHex: colorHex ?? this.colorHex,
    colorHexInvalid: colorHexInvalid ?? this.colorHexInvalid,
    allDay: allDay ?? this.allDay,
    copy: copy ?? this.copy,
    copied: copied ?? this.copied,
    dangerZone: dangerZone ?? this.dangerZone,
  );
}

/// Carrega o [SsStrings] do idioma (pt, en, es). Com [apply], ajusta textos
/// em todos os idiomas: `SsStringsDelegate(apply: (s) => s.copyWith(...))`.
class SsStringsDelegate extends LocalizationsDelegate<SsStrings> {
  const SsStringsDelegate({this.apply});

  final SsStrings Function(SsStrings base)? apply;

  @override
  bool isSupported(Locale locale) => SsStrings.forLocale(locale) != null;

  @override
  Future<SsStrings> load(Locale locale) {
    final base = SsStrings.forLocale(locale) ?? SsStrings.pt;
    return SynchronousFuture(apply?.call(base) ?? base);
  }

  @override
  bool shouldReload(SsStringsDelegate old) => old.apply != apply;
}

/// Troca os textos dos componentes abaixo dele, por cima do idioma do app.
/// [SsStringsScope] fixa um objeto inteiro; [SsStringsScope.override] ajusta
/// o do idioma atual: `SsStringsScope.override(apply: (s) => s.copyWith(cancel: 'Voltar'), child: ...)`.
class SsStringsScope extends InheritedWidget {
  const SsStringsScope({super.key, required SsStrings this.strings, required super.child}) : apply = null;

  const SsStringsScope.override({
    super.key,
    required SsStrings Function(SsStrings base) this.apply,
    required super.child,
  }) : strings = null;

  final SsStrings? strings;
  final SsStrings Function(SsStrings base)? apply;

  @override
  bool updateShouldNotify(SsStringsScope old) => old.strings != strings || old.apply != apply;
}

/// Moeda e números: símbolo, separadores e locale. O padrão é o real em
/// pt-BR ("R$ 1.234,56"), independente do idioma dos textos; o app troca com
/// [SsFormatsScope] (ex.: [SsFormats.usd]).
@immutable
class SsFormats {
  const SsFormats({
    this.currencySymbol = r'R$',
    this.decimalSeparator = ',',
    this.thousandsSeparator = '.',
    this.symbolAfter = false,
    this.symbolSpace = true,
    this.locale = const Locale('pt', 'BR'),
  });

  /// Real: "R$ 1.234,56".
  static const brl = SsFormats();

  /// Dólar: "$1,234.56".
  static const usd = SsFormats(
    currencySymbol: r'$',
    decimalSeparator: '.',
    thousandsSeparator: ',',
    symbolSpace: false,
    locale: Locale('en', 'US'),
  );

  /// Euro: "1.234,56 €".
  static const eur = SsFormats(currencySymbol: '€', symbolAfter: true, locale: Locale('es', 'ES'));

  final String currencySymbol;
  final String decimalSeparator;
  final String thousandsSeparator;

  /// Símbolo depois do número ("10,00 €").
  final bool symbolAfter;

  /// Espaço entre símbolo e número.
  final bool symbolSpace;

  /// Locale dos números (para o app que formata com `intl`).
  final Locale locale;

  /// O que vai antes do número ("R$ "), ou vazio.
  String get prefix => symbolAfter ? '' : (symbolSpace ? '$currencySymbol ' : currencySymbol);

  /// O que vai depois do número (" €"), ou vazio.
  String get suffix => symbolAfter ? (symbolSpace ? ' $currencySymbol' : currencySymbol) : '';

  /// Inteiro com milhar: 1234 → "1.234".
  String integer(int n) {
    final s = n.abs().toString();
    final b = StringBuffer(n < 0 ? '-' : '');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(thousandsSeparator);
      b.write(s[i]);
    }
    return b.toString();
  }

  /// Centavos sem o símbolo: 123456 → "1.234,56".
  String amount(int cents) =>
      '${cents < 0 ? '-' : ''}${integer(cents.abs() ~/ 100)}$decimalSeparator${two(cents.abs() % 100)}';

  /// Centavos com o símbolo: "R$ 1.234,56"; nulo vira "—".
  String money(int? cents) {
    if (cents == null) return '—';
    return '${cents < 0 ? '-' : ''}$prefix${amount(cents.abs())}$suffix';
  }

  /// Texto → centavos ("1.234,56" → 123456), ou nulo se não der. Sem o
  /// separador decimal no texto, o ponto também vale como decimal ("12.5").
  int? parseMoney(String text) {
    var t = text.replaceAll(RegExp(r'[^0-9,.]'), '');
    if (t.isEmpty) return null;
    if (t.contains(decimalSeparator)) {
      t = t.replaceAll(thousandsSeparator, '').replaceAll(decimalSeparator, '.');
    } else if (decimalSeparator == '.') {
      t = t.replaceAll(thousandsSeparator, '');
    }
    final v = double.tryParse(t);
    return v == null ? null : (v * 100).round();
  }

  SsFormats copyWith({
    String? currencySymbol,
    String? decimalSeparator,
    String? thousandsSeparator,
    bool? symbolAfter,
    bool? symbolSpace,
    Locale? locale,
  }) => SsFormats(
    currencySymbol: currencySymbol ?? this.currencySymbol,
    decimalSeparator: decimalSeparator ?? this.decimalSeparator,
    thousandsSeparator: thousandsSeparator ?? this.thousandsSeparator,
    symbolAfter: symbolAfter ?? this.symbolAfter,
    symbolSpace: symbolSpace ?? this.symbolSpace,
    locale: locale ?? this.locale,
  );

  /// O do [SsFormatsScope] acima, ou [brl].
  static SsFormats of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SsFormatsScope>()?.formats ?? brl;

  @override
  bool operator ==(Object other) =>
      other is SsFormats &&
      other.currencySymbol == currencySymbol &&
      other.decimalSeparator == decimalSeparator &&
      other.thousandsSeparator == thousandsSeparator &&
      other.symbolAfter == symbolAfter &&
      other.symbolSpace == symbolSpace &&
      other.locale == locale;

  @override
  int get hashCode =>
      Object.hash(currencySymbol, decimalSeparator, thousandsSeparator, symbolAfter, symbolSpace, locale);
}

/// Troca a moeda e os separadores dos componentes abaixo dele.
class SsFormatsScope extends InheritedWidget {
  const SsFormatsScope({super.key, required this.formats, required super.child});

  final SsFormats formats;

  @override
  bool updateShouldNotify(SsFormatsScope old) => old.formats != formats;
}
