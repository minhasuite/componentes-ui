// Categorias de uso da vitrine: as mesmas (nome, ícone e ordem) da vitrine web
// (`rails/sample/app/controllers/vitrine_controller.rb`, GRUPOS).
//
// Cada peça do catálogo (`test/catalogo.dart`) cai numa categoria pelo mapa
// [_porSlug]; sem entrada, por palavra no slug/nome ([_porPalavra]). Peça nova
// que não cair em nenhuma faz o `test/categorias_test.dart` falhar: ponha o slug
// no mapa. "Novidades" é à parte: a peça fica na categoria dela e também
// aparece lá (ver [ehNovidade]).
//
// Sem import do catálogo de propósito: o teste do pacote importa este arquivo
// direto e o catálogo pelo caminho de lá (não pelo link `lib/catalogo`).
import 'package:componentes_ui/componentes_ui.dart';
import 'package:material_ui/material_ui.dart';

class Categoria {
  const Categoria(this.id, this.nome, this.icone, this.descricao);
  final String id;
  final String nome;

  /// Nome do ícone no conjunto da suíte (o mesmo do `ss_icon` da gem).
  final String icone;
  final String descricao;

  IconData get iconData => SsIcons.named(icone);
}

/// A onda cujas peças entram em "Novidades".
const versaoNovidades = '1.14';

const novidades = Categoria('novidades', 'Novidades (v$versaoNovidades)', 'sparkles', 'O que chegou nesta versão.');
const fundacao = Categoria(
  'fundacao',
  'Fundação',
  'color-swatch',
  'Tema, cores, paletas, tipografia, densidade, aparência e ícones.',
);
const navegacao = Categoria(
  'navegacao',
  'Navegação e moldura',
  'template',
  'Barras, abas, menus, cabeçalhos e a casca da tela.',
);
const acoes = Categoria('acoes', 'Ações e botões', 'cursor-click', 'Botões, menus de ação, confirmar e seleção.');
const formularios = Categoria(
  'formularios',
  'Formulários e entrada',
  'pencil-alt',
  'Campos, escolhas, sliders e passo a passo.',
);
const listas = Categoria('listas', 'Listas e tabelas', 'view-list', 'Itens, linhas, tabelas, quadros e históricos.');
const dados = Categoria('dados', 'Dados e gráficos', 'chart-bar', 'Indicadores, gráficos, anéis e barras.');
const cards = Categoria('cards', 'Cards e painéis', 'collection', 'Cards, heróis, mosaicos e painéis.');
const retorno = Categoria(
  'retorno',
  'Retorno e estados',
  'badge-check',
  'Aviso, vazio, carregando, erro, offline, sincronização, diálogos e folhas.',
);
const movimento = Categoria(
  'movimento',
  'Movimento e transições',
  'lightning-bolt',
  'A mola da suíte, entradas, números que rolam e transições de tela.',
);
const conversa = Categoria(
  'conversa',
  'Conversa, IA e avisos',
  'chat-alt-2',
  'Chat, assistente, notificações, dicas e ajuda.',
);
const tempo = Categoria('tempo', 'Tempo e agenda', 'calendar', 'Datas, horas, calendário, agenda e cronograma.');
const casa = Categoria('casa', 'Casa e automação', 'home', 'Aparelhos, clima, energia, câmeras e controles.');
const comercio = Categoria(
  'comercio',
  'Comércio e finanças',
  'shopping-bag',
  'Dinheiro, preço, oferta, carteira, ingresso e plano.',
);
const midia = Categoria('midia', 'Mídia e captura', 'photograph', 'Foto, câmera, galeria, carrossel e anexos.');
const telas = Categoria('telas', 'Telas montadas', 'device-mobile', 'Telas inteiras feitas só com peças do pacote.');

/// Na ordem do menu (a mesma do web).
const categorias = <Categoria>[
  novidades,
  fundacao,
  navegacao,
  acoes,
  formularios,
  listas,
  dados,
  cards,
  retorno,
  movimento,
  conversa,
  tempo,
  casa,
  comercio,
  midia,
  telas,
];

/// A categoria de uso da peça (nunca "Novidades"); nula = não achou (o teste acusa).
Categoria? categoriaDe(String slug, String nome) {
  final explicita = _porSlug[slug];
  if (explicita != null) return explicita;
  final texto = '$slug ${nome.toLowerCase()}';
  for (final (padrao, cat) in _porPalavra) {
    if (padrao.hasMatch(texto)) return cat;
  }
  return null;
}

/// Peça da onda atual pela marca que o catálogo já usa na descrição ("(v1.9, par do …)",
/// "(v1.9)"). A vitrine junta com as peças que os `comV19*` do catálogo acrescentam.
bool ehNovidade(String nome, String descricao) =>
    RegExp('\\(v${RegExp.escape(versaoNovidades)}[,)]').hasMatch(descricao) || nome.contains('v$versaoNovidades');

/// Reserva por palavra (peça nova sem entrada no mapa), na ordem: a 1ª que bate vale.
final _porPalavra = <(RegExp, Categoria)>[
  (RegExp(r'^mov-|motion|transi|morph|burst|confetti'), movimento),
  (RegExp(r'chat|assist|\bai\b|ai-|notifica|bell|tip\b|tour|help'), conversa),
  (RegExp(r'chart|bars|ring|gauge|graf|kpi|stat|odomet|heat'), dados),
  (RegExp(r'date|day|month|agenda|time|calend|clock|gantt|week'), tempo),
  (RegExp(r'device|thermostat|camera-tile|dpad|weather|casa'), casa),
  (RegExp(r'price|money|amount|wallet|pix|deal|offer|ticket|plan'), comercio),
  (RegExp(r'photo|image|media|capture|carousel|story|thumb|gallery'), midia),
  (RegExp(r'toast|empty|error|loading|loader|skeleton|sheet|dialog|confirm|offline|sync|undo|spinner'), retorno),
  (RegExp(r'button|fab|action|swipe|hold|menu-action|selection'), acoes),
  (RegExp(r'nav|menu|tab|header|rail|scaffold|split|shell|search-menu|scroll'), navegacao),
  (RegExp(r'field|picker|input|slider|check|switch|radio|otp|form|wizard|stepper'), formularios),
  (RegExp(r'list|table|row|kanban|audit|log'), listas),
  (RegExp(r'card|tile|hero|bento|mosaic|grid|panel'), cards),
  (RegExp(r'palette|color|theme|density|icon|brand|appearance|a11y|font'), fundacao),
  (RegExp(r'screen|auth|onboarding|lock'), telas),
];

final _porSlug = <String, Categoria>{
  // Fundação
  for (final s in [
    'ss-paletas', 'ss-gradient4', 'ss-oled', 'ss-tinted-shadow', 'ss-glass', 'ss-glow', 'ss-texture', //
    'ss-squircle', 'ss-palette-picker', 'ss-density', 'ss-density-picker', 'ss-brand-from-colors', 'ss-icons',
    'ss-series-ink', 'ss-high-contrast', 'ss-appearance-panel', 'ss-icon-tile', 'ss-icon-tile-image',
    'ss-shape-icon', 'ss-locale-picker', 'ss-aurora-background', 'ss-fit', 'ss-fit-title', 'ss-prose',
    'ss-code-block', 'ss-divider', 'ss-link-text', 'ss-monogram', 'ss-field-label-icon',
    'ss-platform', // v1.11
  ])
    s: fundacao,
  // Navegação e moldura
  for (final s in [
    'ss-nav-bar', 'ss-nav-bar-centro', 'ss-side-rail', 'ss-screen-header', 'ss-tabs-underline', //
    'ss-curved-header', 'ss-count-tabs', 'ss-step-top-bar', 'ss-top-bar', 'ss-command-palette', 'ss-tabs-view',
    'ss-side-menu', 'ss-nav-scaffold', 'ss-split', 'ss-aside-layout', 'ss-section', 'ss-section-header',
    'ss-section-icon', 'ss-fullscreen',
    'ss-side-menu-ios', 'ss-nav-bar-ios', // v1.11
    'ss-continue-on', 'ss-suite-switcher', // v1.13
    'ss-nav-animated-icon', 'ss-collapse-tint', // v1.14
  ])
    s: navegacao,
  // Ações e botões
  for (final s in [
    'ss-button', 'ss-action-button', 'ss-overflow-menu', 'ss-context-menu', 'ss-fab', 'ss-speed-dial', //
    'ss-icon-button', 'ss-button-pair', 'ss-button-group', 'ss-hex-button', 'ss-morph-button',
    'ss-hold-to-confirm', 'ss-swipe-to-confirm', 'ss-sticky-action-bar', 'ss-danger-zone', 'ss-selection-bar',
    'ss-selectable', 'ss-call-controls',
    'ss-apple-button', 'ss-action-sheet', // v1.11
  ])
    s: acoes,
  // Formulários e entrada
  for (final s in [
    'ss-segmented', 'ss-segmented-on-dark', 'ss-filter-chip', 'ss-search-field', 'ss-text-field', //
    'ss-money-field', 'ss-amount-keypad', 'ss-choice-field', 'ss-switch-row', 'ss-stepper', 'ss-picker',
    'ss-unsaved-guard', 'ss-check-row', 'ss-vertical-slider', 'ss-dial', 'ss-people-picker', 'ss-slider',
    'ss-icon-picker', 'ss-color-picker', 'ss-field-group', 'ss-money-field-expression', 'ss-input-chip',
    'ss-radio-group', 'ss-repeater', 'ss-editable-value', 'ss-wizard', 'ss-otp', 'ss-tag-input',
    'ss-step-heading', 'ss-terms-notice', 'ss-v102-params',
    'ss-switch-ios', // v1.11
    'ss-pix-key-field', 'ss-boleto-field', 'ss-cep-field', 'ss-document-field', // v1.12
    'ss-spoken-amount', // v1.13
  ])
    s: formularios,
  // Listas e tabelas
  for (final s in [
    'ss-expandable-row', // v1.14
    'ss-list-item', 'ss-paged-list', 'ss-pull-to-refresh', 'ss-swipe-action', 'ss-value-row', 'ss-value-tile', //
    'ss-rows', 'ss-reorderable-list', 'ss-data-table', 'ss-block-list', 'ss-collapsible', 'ss-compare-table',
    'ss-kanban', 'ss-avatar', 'ss-avatar-extras', 'ss-task-item', 'ss-audit',
    'ss-filter-bar', 'ss-filter-sheet', 'ss-tree-view', // v1.10
  ])
    s: listas,
  // Dados e gráficos
  for (final s in [
    'ss-stat-card', 'ss-sparkline', 'ss-rings', 'ss-pill-bars', 'ss-line-chart', 'ss-gauge', 'ss-progress', //
    'ss-proportion-bar', 'ss-area-chart', 'ss-exploded-donut', 'ss-big-ring', 'ss-floating-bars',
    'ss-chart-scrub', 'ss-period-compare', 'ss-kpi-odometer', // v1.14
    'ss-time-chart', 'ss-state-bands', 'ss-kpi-card', 'ss-bar-chart', 'ss-progress-row', 'ss-chart-legend',
    'ss-diverging-bars', 'ss-day-strip', 'ss-duo-stat', 'ss-heat-calendar', 'ss-odometer', 'ss-card-header-rank',
  ])
    s: dados,
  // Cards e painéis
  for (final s in [
    'ss-card', 'ss-hero', 'ss-aurora-card', 'ss-mosaic-grid', 'ss-boarding-pass', 'ss-card-stack', //
    'ss-status-tab-card', 'ss-goal-card', 'ss-feature-tile', 'ss-profile-hero', 'ss-masonry', 'ss-mosaic-facts',
    'ss-photo-card', 'ss-note', 'ss-illustration-stage', 'ss-achievement', 'ss-review', 'ss-person', 'ss-bento',
    'ss-seal', 'ss-rating', 'ss-page-dots',
  ])
    s: cards,
  // Retorno e estados
  for (final s in [
    'ss-empty-state', 'ss-error-view', 'skeleton', 'ss-toast', 'ss-async-body', 'ss-inline-async', //
    'ss-confirm', 'ss-prompt', 'ss-run-blocking', 'ss-sheet', 'ss-sheet-header', 'ss-offline-banner', 'ss-undo',
    'ss-linear-loader', 'ss-highlight', 'ss-sync', 'ss-async-sliver', 'ss-spinner', 'ss-skeleton-switch',
    'ss-job-progress', 'ss-popover', // v1.10
    'ss-confirm-ios', 'ss-sheet-ios', // v1.11
    'ss-since-last-visit', 'ss-conflict-resolver', 'ss-privacy-auto', // v1.13
    'ss-detent-sheet', 'ss-skeleton-of', 'ss-success-check', // v1.14
    'ss-undoable-removal', 'ss-illustration', 'ss-skeleton', 'ss-badge', 'ss-status-badge', 'ss-dot',
  ])
    s: retorno,
  // Movimento e transições (os `mov-*` caem aqui pela palavra)
  for (final s in [
    'ss-motion', 'ss-fly-to', 'ss-hero-flight', 'ss-shimmer-glass', 'ss-open-card', 'ss-open-container', //
    'ss-predictive-back', 'ss-celebrate',
    'ss-shared-axis', 'ss-mesh-background', 'ss-tilt-card', // v1.14
  ])
    s: movimento,
  // Conversa, IA e avisos
  for (final s in [
    'ss-chat', 'ss-chat-action-card', 'ss-chat-divider', 'ss-ai-insight-card', 'ss-assistant', 'ss-mic-button', //
    'ss-pulse-avatar', 'ss-quote', 'ss-notice-card', 'ss-callout', 'ss-tip', 'ss-tooltip',
    'ss-notification-bell', 'ss-bell-dot', 'ss-notification-center', 'ss-whats-new', 'ss-tour',
    'ss-checklist-card', 'ss-help-menu',
    'ss-explain', 'ss-ai-action-preview', // v1.13
  ])
    s: conversa,
  // Tempo e agenda
  for (final s in [
    'ss-month-switcher', 'ss-month-grid', 'ss-timeline', 'ss-countdown-ring', 'ss-date-strip', 'ss-day-agenda', //
    'ss-agenda-list', 'ss-agenda-list-hora', 'ss-day-agenda-all-day', 'ss-weekday-picker', 'ss-date-picker',
    'ss-time-picker', 'ss-date-range', 'ss-gantt', 'ss-clock', 'ss-date-field', 'ss-date-time-field',
    'ss-time-field',
    'ss-date-wheel', // v1.11
  ])
    s: tempo,
  // Casa e automação
  for (final s in [
    'ss-device-tile', 'ss-device-tile-v012', 'ss-thermostat', 'ss-code-keypad', 'ss-logbook', 'ss-camera-tile', //
    'ss-flow-diagram', 'ss-dpad', 'ss-weather-card', 'ss-scan-radar', 'ss-cue',
  ])
    s: casa,
  // Comércio e finanças
  for (final s in [
    'ss-amount', 'ss-offer-card', 'ss-deal-badge', 'ss-ticket-card', 'ss-wallet-card', 'ss-qr-card', //
    'ss-recurring-card', 'ss-pop-out-card', 'ss-level-card', 'ss-price-board', 'ss-privacy', 'ss-plan',
    'ss-split-slider', 'ss-product-card', // v1.10
    'ss-pix-card', 'ss-nfe-card', 'ss-smart-paste', 'ss-qr-image', // v1.12
  ])
    s: comercio,
  // Mídia e captura
  for (final s in [
    'ss-image-source', 'ss-net-image', 'ss-compare', 'ss-attach-bar', 'ss-snap-carousel', 'ss-thumb-rail', //
    'ss-story-ring', 'ss-shareable', 'ss-media-player', 'ss-image-viewer', 'ss-capture-hub',
  ])
    s: midia,
  // Telas montadas (peças que já são a tela inteira; as `telas/` da vitrine entram também)
  for (final s in [
    'vitrine', 'ss-plans', 'ss-menu', 'ss-onboarding', 'ss-lock-screen', 'ss-auth-folhinha', 'ss-auth-cartaz', //
    'ss-hero-splash', 'ss-illustrated-split',
  ])
    s: telas,
};
