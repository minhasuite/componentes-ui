// v1.9 · produto: central de notificações (par do Ss::NotificationCenterComponent do web). Generaliza o que
// minhas-vendas-app, meu-cultivo-app e meu-personal-app montaram à mão: lista paginada por dia, lida/não lida,
// tocar marca lida e abre, "marcar todas", deslizar para ler/arquivar, puxar para atualizar, vazio e erro.
import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

import '../../app_theme.dart';
import '../../density.dart';
import '../../format.dart';
import '../../motion.dart';
import '../../safe_list_padding.dart';
import '../../ss_async.dart';
import '../../ss_badge.dart';
import '../../ss_button.dart';
import '../../ss_controls.dart' show SsSegmented;
import '../../ss_empty_state.dart';
import '../../ss_list.dart';
import '../../ss_strings.dart';
import '../../ss_swipe.dart';
import '../../ss_toast.dart';
import '../../v10/tela_barra.dart' show SsSpinner;

/// Um aviso da central. [id] é o do servidor; [data] leva o que o app precisa para abrir o destino
/// (rota, tipo e id do registro): o pacote não olha dentro.
@immutable
class SsNotificationItem {
  const SsNotificationItem({
    required this.id,
    required this.title,
    this.body,
    this.createdAt,
    this.read = false,
    this.icon,
    this.tone,
    this.data,
    this.level,
    this.image,
    this.actions = const [],
    this.onMute,
    this.muteLabel,
  });

  final String id;
  final String title;
  final String? body;

  /// Quando chegou (agrupa por dia e mostra a hora). Nulo: sem grupo e sem hora.
  final DateTime? createdAt;
  final bool read;

  /// Ícone no quadradinho tonal (padrão: o sino).
  final IconData? icon;

  /// Tom do quadradinho (padrão: a marca).
  final SsTone? tone;
  final Object? data;

  /// v1.9.2: nível do aviso. Aviso e crítico ganham o tom semântico (âmbar, vermelho) no quadradinho e no
  /// contorno, o ícone do nível e um selo com o nome ("Aviso", "Crítico"; também lido pelo leitor de tela).
  /// O [tone]/[icon] passados ganham. Nulo: como antes.
  final SsNotificationLevel? level;

  /// v1.9.2: foto do aviso (instantâneo da câmera), embaixo do texto, 16:9 na largura da linha. O app monta
  /// (`SsNetImage(url, width: double.infinity, radius: 0)`): o pacote não busca nada.
  final Widget? image;

  /// v1.9.2: botões de resposta embaixo do aviso (o 1º cheio, os outros fantasma). Tocar marca o aviso como
  /// lido (como abrir) e chama a ação; depois de responder, o app relê ([SsNotificationCenterController.refresh]).
  final List<SsNotificationAction> actions;

  /// v1.9.2: "Silenciar" (cala a origem): botão fantasma com o sino cortado, depois das [actions]. Escolher
  /// por quanto tempo é do app (`showSsPicker`).
  final VoidCallback? onMute;

  /// Padrão: [SsStrings.notifMute].
  final String? muteLabel;

  bool get unread => !read;

  /// Tem botões dentro (a linha deixa de ser um botão só no leitor de tela).
  bool get hasButtons => actions.isNotEmpty || onMute != null;

  SsNotificationItem copyWith({bool? read}) => SsNotificationItem(
    id: id,
    title: title,
    body: body,
    createdAt: createdAt,
    read: read ?? this.read,
    icon: icon,
    tone: tone,
    data: data,
    level: level,
    image: image,
    actions: actions,
    onMute: onMute,
    muteLabel: muteLabel,
  );
}

/// v1.9.2: nível de um [SsNotificationItem] (o `level:` do `Ss::NotificationCenterComponent`).
enum SsNotificationLevel {
  info,
  warning,
  critical;

  SsTone get tone => switch (this) {
    info => SsTone.info,
    warning => SsTone.warning,
    critical => SsTone.danger,
  };

  IconData get icon => switch (this) {
    info => Icons.info_outline_rounded,
    warning => Icons.warning_amber_rounded,
    critical => Icons.error_outline_rounded,
  };

  String label(SsStrings s) => switch (this) {
    info => s.notifLevelInfo,
    warning => s.notifLevelWarning,
    critical => s.notifLevelCritical,
  };
}

/// v1.9.2: botão de resposta de um aviso ("Sim", "Abrir portão"). [onPressed] nulo = desabilitado.
@immutable
class SsNotificationAction {
  const SsNotificationAction(this.label, this.onPressed, {this.icon});
  final String label;
  final FutureOr<void> Function()? onPressed;
  final IconData? icon;
}

/// Uma página da central: os [items], se há mais ([hasMore]) e, se o servidor contar, o total de não
/// lidas ([unreadCount], que vale mais que contar os itens carregados).
@immutable
class SsNotificationPage {
  const SsNotificationPage(this.items, {this.hasMore = false, this.unreadCount});

  final List<SsNotificationItem> items;
  final bool hasMore;
  final int? unreadCount;
}

/// Comandos da central de fora dela (o "marcar todas" ou o atualizar na barra de cima do app) e o número
/// de não lidas para o sino ([unreadCount], ouvível).
class SsNotificationCenterController extends ChangeNotifier {
  _SsNotificationCenterState? _state;
  int _unread = 0;

  /// Não lidas (do servidor, se a página trouxe; senão as carregadas), já com o que se marcou aqui.
  int get unreadCount => _unread;

  /// Os avisos carregados até agora.
  List<SsNotificationItem> get items => List.unmodifiable(_state?._items ?? const []);

  Future<void> refresh() async => _state?._reload();
  Future<void> markAllRead() async => _state?._markAll();

  /// v1.14.2: a aba à vista (com [SsNotificationCenter.loadArchived]).
  SsNotificationView get view => _state?._view ?? SsNotificationView.inbox;

  /// v1.14.2: troca para a caixa de entrada ou para as arquivadas (sem [SsNotificationCenter.loadArchived],
  /// não faz nada).
  Future<void> show(SsNotificationView view) async => _state?._setView(view);

  void _setUnread(int n) {
    if (n == _unread) return;
    _unread = n;
    notifyListeners();
  }
}

/// v1.14.2: as abas da central com [SsNotificationCenter.loadArchived].
enum SsNotificationView { inbox, archived }

/// Central de notificações: lista paginada agrupada por dia ("Hoje", "Ontem", "segunda, 5 de outubro"),
/// com o aviso não lido em negrito e com o ponto, e a faixa de cima com "3 não lidas · Marcar todas como
/// lidas". A fonte de dados é do app, sem HTTP aqui:
///
/// - [load] devolve a página `n` (começa em 1); pede a próxima sozinha perto do fim (o [SsLoadMore] no
///   rodapé) e de novo ao puxar para atualizar. Aviso repetido entre páginas não duplica (mesmo [id]).
/// - Tocar: se não lida, marca na hora ([markRead], otimista; falha de marcar não impede abrir) e chama
///   [onOpen] com o item (o app navega pelo `data`).
/// - Deslizar para a direita marca lida ([markRead]); para a esquerda arquiva ([archive], o item sai e
///   volta se falhar). Sem o callback, o lado não existe. O leitor de tela tem as duas como ações.
/// - [markAllRead]: otimista; se falhar, volta e avisa.
/// - Vazio: [SsEmptyState] com [emptyTitle]/[emptyText]; erro da 1ª página: o mesmo com "Tentar de novo"
///   ([errorText] traduz o erro; padrão [SsStrings.genericError]).
///
/// - v1.9.2, aviso rico (no [SsNotificationItem], tudo opcional): [SsNotificationItem.level] (tom e selo),
///   [SsNotificationItem.image], [SsNotificationItem.actions] (botões de resposta) e
///   [SsNotificationItem.onMute] ("Silenciar"). Responder marca como lido.
///
/// - v1.14.2, desfazer do arquivar: com [unarchive], o aviso "Notificação arquivada" ganha "Desfazer" (o
///   [showSsUndo]); desfazer chama o [unarchive] e o item volta crescendo ao mesmo lugar (a animação do
///   [SsUndoableRemoval]). Sem [unarchive], o aviso fica sem botão, como antes. O app não precisa mais do
///   `showSsUndo` por cima do aviso do pacote.
/// - v1.14.2, arquivadas: com [loadArchived], o topo ganha "Caixa de entrada | Arquivadas" ([SsSegmented]).
///   As arquivadas vêm do [loadArchived] (página `n`, relida a cada vez que a aba abre), sem a faixa de não
///   lidas e sem contar no sino; deslizar para a esquerda (ou a ação do leitor de tela) é "Desarquivar"
///   ([unarchive]): o item sai, a caixa de entrada é relida e, se falhar, ele volta e avisa.
///   [initialView] abre direto numa aba; o [SsNotificationCenterController.show] troca de fora.
///
/// O sino da barra de cima é o [SsNotificationBell] (ou o [SsBellDot]) com o
/// [SsNotificationCenterController.unreadCount]; [onUnreadChanged] avisa a cada mudança.
///
/// `SsNotificationCenter(load: repo.pagina, markRead: repo.marcarLida, markAllRead: repo.marcarTodas, onOpen: (n) => context.push(rota(n)))`
class SsNotificationCenter extends StatefulWidget {
  const SsNotificationCenter({
    super.key,
    required this.load,
    this.markRead,
    this.markAllRead,
    this.archive,
    this.unarchive,
    this.loadArchived,
    this.initialView = SsNotificationView.inbox,
    this.archivedEmptyTitle,
    this.archivedEmptyText,
    this.onOpen,
    this.onUnreadChanged,
    this.controller,
    this.showHeader = true,
    this.groupByDay = true,
    this.emptyTitle,
    this.emptyText,
    this.emptyIcon = Icons.notifications_none_rounded,
    this.errorText,
    this.padding,
    this.now,
  });

  final Future<SsNotificationPage> Function(int page) load;
  final Future<void> Function(String id)? markRead;
  final Future<void> Function()? markAllRead;
  final Future<void> Function(String id)? archive;

  /// v1.14.2: devolve o aviso à caixa de entrada. Liga o "Desfazer" do aviso de arquivar e, nas arquivadas,
  /// o "Desarquivar".
  final Future<void> Function(String id)? unarchive;

  /// v1.14.2: a página `n` (começa em 1) das arquivadas. Com ele, a aba "Arquivadas" aparece.
  final Future<SsNotificationPage> Function(int page)? loadArchived;

  /// v1.14.2: a aba que abre (só vale com [loadArchived]).
  final SsNotificationView initialView;

  /// v1.14.2: o vazio das arquivadas (padrão [SsStrings.notifArchivedEmptyTitle]/[SsStrings.notifArchivedEmptyText]).
  final String? archivedEmptyTitle;
  final String? archivedEmptyText;
  final FutureOr<void> Function(SsNotificationItem item)? onOpen;
  final ValueChanged<int>? onUnreadChanged;
  final SsNotificationCenterController? controller;

  /// A faixa de cima com a contagem e o "Marcar todas como lidas" (falso quando o app põe na barra).
  final bool showHeader;
  final bool groupByDay;
  final String? emptyTitle;
  final String? emptyText;
  final IconData emptyIcon;
  final String Function(Object error)? errorText;

  /// Sem ele, [safeListPadding].
  final EdgeInsets? padding;

  /// Relógio (testes e catálogo); padrão `DateTime.now()`.
  final DateTime Function()? now;

  /// Rótulo do grupo do dia [d]: "Hoje", "Ontem", "segunda, 5 de outubro" (no ano) ou a data inteira.
  static String dayLabel(DateTime d, DateTime now, SsStrings s) {
    final dia = DateTime(d.year, d.month, d.day);
    final hoje = DateTime(now.year, now.month, now.day);
    final diff = hoje.difference(dia).inDays;
    if (diff == 0) return s.today;
    if (diff == 1) return s.yesterday;
    if (d.year == now.year) return s.longDate(d);
    return s.formatDate(d);
  }

  @override
  State<SsNotificationCenter> createState() => _SsNotificationCenterState();
}

class _SsNotificationCenterState extends State<SsNotificationCenter> {
  final _items = <SsNotificationItem>[];
  var _page = 0;
  var _hasMore = false;
  var _loading = true;
  var _loadingMore = false;
  var _moreFailed = false;
  Object? _error;
  int? _serverUnread;
  // Marcações feitas aqui desde a última página com contagem do servidor.
  var _readHere = 0;

  // v1.14.2: a aba e a lista das arquivadas (não contam no sino).
  late var _view = widget.loadArchived == null ? SsNotificationView.inbox : widget.initialView;
  final _arq = <SsNotificationItem>[];
  var _arqPage = 0;
  var _arqHasMore = false;
  var _arqLoading = false;
  var _arqLoaded = false;
  var _arqLoadingMore = false;
  var _arqMoreFailed = false;
  Object? _arqError;
  // Itens que voltaram (desfazer do arquivar, ou de volta das arquivadas): entram crescendo.
  final _voltando = <String>{};

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _reload();
    if (_view == SsNotificationView.archived) _reloadArchived();
  }

  Future<void> _setView(SsNotificationView v) async {
    if (widget.loadArchived == null || v == _view) return;
    setState(() => _view = v);
    if (v == SsNotificationView.archived) await _reloadArchived();
  }

  Future<void> _reloadArchived() async {
    final load = widget.loadArchived;
    if (load == null) return;
    setState(() {
      _arqLoading = !_arqLoaded || _arq.isEmpty;
      _arqError = null;
    });
    try {
      final p = await load(1);
      if (!mounted) return;
      setState(() {
        _arq
          ..clear()
          ..addAll(_dedupe(p.items, const {}));
        _arqPage = 1;
        _arqHasMore = p.hasMore;
        _arqMoreFailed = false;
        _arqLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _arqError = e);
      if (_arq.isNotEmpty) showSsToast(context, _errorText(e), icon: Icons.cloud_off_outlined);
    } finally {
      if (mounted) setState(() => _arqLoading = false);
    }
  }

  Future<void> _moreArchived() async {
    final load = widget.loadArchived;
    if (load == null || _arqLoadingMore || !_arqHasMore) return;
    setState(() {
      _arqLoadingMore = true;
      _arqMoreFailed = false;
    });
    try {
      final p = await load(_arqPage + 1);
      if (!mounted) return;
      setState(() {
        _arq.addAll(_dedupe(p.items, _arq.map((n) => n.id).toSet()));
        _arqPage++;
        _arqHasMore = p.hasMore;
      });
    } catch (_) {
      if (mounted) setState(() => _arqMoreFailed = true);
    } finally {
      if (mounted) setState(() => _arqLoadingMore = false);
    }
  }

  // Nas arquivadas: devolve à caixa de entrada (otimista; falhou, volta e avisa).
  Future<void> _unarchiveFromArchived(SsNotificationItem n) async {
    final i = _arq.indexWhere((x) => x.id == n.id);
    if (i < 0 || widget.unarchive == null) return;
    setState(() => _arq.removeAt(i));
    try {
      await widget.unarchive!(n.id);
      if (!mounted) return;
      showSsToast(context, _s.notifUnarchived, icon: Icons.unarchive_outlined);
      _voltando.add(n.id);
      unawaited(_reload());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _arq.insert(i.clamp(0, _arq.length), n);
        _voltando.add(n.id);
      });
      showSsToast(context, _errorText(e), icon: Icons.error_outline_rounded, tone: AppColors.danger);
    }
  }

  @override
  void didUpdateWidget(SsNotificationCenter old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      if (old.controller?._state == this) old.controller?._state = null;
      widget.controller?._state = this;
      _syncUnread();
    }
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) widget.controller?._state = null;
    super.dispose();
  }

  int get _unread {
    if (_serverUnread != null) return (_serverUnread! - _readHere).clamp(0, 1 << 30);
    return _items.where((n) => n.unread).length;
  }

  void _syncUnread() {
    final n = _unread;
    widget.controller?._setUnread(n);
    widget.onUnreadChanged?.call(n);
  }

  SsStrings get _s => SsStrings.of(context);

  String _errorText(Object e) => widget.errorText?.call(e) ?? _s.genericError;

  Future<void> _reload() async {
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    try {
      final p = await widget.load(1);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(_dedupe(p.items, const {}));
        _page = 1;
        _hasMore = p.hasMore;
        _moreFailed = false;
        _serverUnread = p.unreadCount;
        _readHere = 0;
      });
      _syncUnread();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
      if (_items.isNotEmpty) showSsToast(context, _errorText(e), icon: Icons.cloud_off_outlined);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Iterable<SsNotificationItem> _dedupe(List<SsNotificationItem> novos, Set<String> vistos) {
    final ja = {...vistos};
    return novos.where((n) => ja.add(n.id));
  }

  Future<void> _more() async {
    if (_loadingMore || !_hasMore) return;
    setState(() {
      _loadingMore = true;
      _moreFailed = false;
    });
    try {
      final p = await widget.load(_page + 1);
      if (!mounted) return;
      setState(() {
        // Aviso novo no meio da rolagem empurra a página: sem repetir linha.
        _items.addAll(_dedupe(p.items, _items.map((n) => n.id).toSet()));
        _page++;
        _hasMore = p.hasMore;
        if (p.unreadCount != null) {
          _serverUnread = p.unreadCount;
          _readHere = 0;
        }
      });
      _syncUnread();
    } catch (_) {
      if (mounted) setState(() => _moreFailed = true);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _setRead(SsNotificationItem n, bool read) {
    final i = _items.indexWhere((x) => x.id == n.id);
    if (i < 0) return;
    setState(() {
      _items[i] = _items[i].copyWith(read: read);
      _readHere += read ? 1 : -1;
    });
    _syncUnread();
  }

  Future<void> _markOne(SsNotificationItem n) async {
    if (!n.unread || widget.markRead == null) return;
    _setRead(n, true);
    try {
      await widget.markRead!(n.id);
    } catch (_) {
      // Marcar como lida é secundário; abrir o destino é o que importa.
    }
  }

  Future<void> _open(SsNotificationItem n) async {
    await _markOne(n);
    await widget.onOpen?.call(n.copyWith(read: true));
  }

  // v1.9.2: responder ao aviso também o dá por lido (como abrir).
  Future<void> _act(SsNotificationItem n, SsNotificationAction a) async {
    unawaited(_markOne(n));
    await a.onPressed?.call();
  }

  Future<void> _markAll() async {
    if (widget.markAllRead == null) return;
    final antes = List.of(_items);
    final antesServer = _serverUnread, antesAqui = _readHere;
    setState(() {
      for (var i = 0; i < _items.length; i++) {
        _items[i] = _items[i].copyWith(read: true);
      }
      if (_serverUnread != null) _readHere = _serverUnread!;
    });
    _syncUnread();
    try {
      await widget.markAllRead!();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(antes);
        _serverUnread = antesServer;
        _readHere = antesAqui;
      });
      _syncUnread();
      showSsToast(context, _errorText(e), icon: Icons.error_outline_rounded, tone: AppColors.danger);
    }
  }

  Future<void> _archive(SsNotificationItem n) async {
    final i = _items.indexWhere((x) => x.id == n.id);
    if (i < 0) return;
    setState(() {
      _items.removeAt(i);
      if (n.unread) _readHere++;
    });
    _syncUnread();
    try {
      await widget.archive!(n.id);
    } catch (e) {
      if (!mounted) return;
      _devolve(n, i);
      showSsToast(context, _errorText(e), icon: Icons.error_outline_rounded, tone: AppColors.danger);
      return;
    }
    if (!mounted) return;
    _arqLoaded = false; // a aba das arquivadas relê ao abrir
    if (widget.unarchive == null) {
      showSsToast(context, _s.notifArchived, icon: Icons.archive_outlined);
      return;
    }
    // v1.14.2: "Desfazer" no próprio aviso; desfez, o item volta crescendo e o servidor desarquiva.
    final desfez = await showSsUndo(context, _s.notifArchived, icon: Icons.archive_outlined);
    if (!desfez || !mounted) return;
    SsHaptics.selection();
    _devolve(n, i);
    try {
      await widget.unarchive!(n.id);
    } catch (e) {
      if (!mounted) return;
      final j = _items.indexWhere((x) => x.id == n.id);
      if (j >= 0) {
        setState(() {
          _items.removeAt(j);
          if (n.unread) _readHere++;
        });
        _syncUnread();
      }
      showSsToast(context, _errorText(e), icon: Icons.error_outline_rounded, tone: AppColors.danger);
    }
  }

  // Põe o item de volta na posição [i] da caixa de entrada, entrando crescendo.
  void _devolve(SsNotificationItem n, int i) {
    if (_items.any((x) => x.id == n.id)) return;
    setState(() {
      _items.insert(i.clamp(0, _items.length), n);
      if (n.unread) _readHere--;
      _voltando.add(n.id);
    });
    _syncUnread();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loadArchived == null) return _inbox(context);
    final s = _s;
    final d = SsDensity.of(context);
    final arquivadas = _view == SsNotificationView.archived;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(d.space(16), d.space(8), d.space(16), d.space(4)),
          child: SsSegmented<SsNotificationView>(
            segments: [(SsNotificationView.inbox, s.notifInbox), (SsNotificationView.archived, s.notifArchivedTab)],
            icons: const [Icons.inbox_outlined, Icons.archive_outlined],
            value: _view,
            onChanged: _setView,
          ),
        ),
        Expanded(child: arquivadas ? _archived(context) : _inbox(context)),
      ],
    );
  }

  Widget _archived(BuildContext context) {
    final s = _s;
    if (_arqLoading && _arq.isEmpty) return const Center(child: SsSpinner());
    if (_arqError != null && _arq.isEmpty) {
      return SsPullToRefresh(
        onRefresh: _reloadArchived,
        child: SsEmptyState(
          icon: Icons.cloud_off_outlined,
          title: s.loadFailed,
          subtitle: _errorText(_arqError!),
          actionLabel: s.retry,
          onAction: _reloadArchived,
        ),
      );
    }
    if (_arq.isEmpty) {
      return SsPullToRefresh(
        onRefresh: _reloadArchived,
        child: SsEmptyState(
          icon: Icons.archive_outlined,
          title: widget.archivedEmptyTitle ?? s.notifArchivedEmptyTitle,
          subtitle: widget.archivedEmptyText ?? s.notifArchivedEmptyText,
        ),
      );
    }
    final c = SsColors.of(context);
    return _lista(
      context,
      // Arquivada não conta: sem o ponto e sem o negrito de não lida.
      itens: [for (final n in _arq) n.copyWith(read: true)],
      header: null,
      hasMore: _arqHasMore,
      loadingMore: _arqLoadingMore,
      moreFailed: _arqMoreFailed,
      onMore: _moreArchived,
      onRefresh: _reloadArchived,
      tile: (n) {
        final tile = SsNotificationTile(item: n, onTap: widget.onOpen == null ? null : () => widget.onOpen!(n));
        if (widget.unarchive == null) return tile;
        return SsSwipeAction(
          key: ValueKey('ss-notif-arq-${n.id}'),
          end: SsSwipeSide(
            icon: Icons.unarchive_outlined,
            label: s.notifUnarchive,
            color: c.accent,
            destructive: true,
            onTrigger: () => _unarchiveFromArchived(_arq.firstWhere((x) => x.id == n.id, orElse: () => n)),
          ),
          child: tile,
        );
      },
    );
  }

  Widget _inbox(BuildContext context) {
    final s = _s;
    if (_loading) return const Center(child: SsSpinner());
    if (_error != null && _items.isEmpty) {
      return SsPullToRefresh(
        onRefresh: _reload,
        child: SsEmptyState(
          icon: Icons.cloud_off_outlined,
          title: s.loadFailed,
          subtitle: _errorText(_error!),
          actionLabel: s.retry,
          onAction: _reload,
        ),
      );
    }
    if (_items.isEmpty) {
      return SsPullToRefresh(
        onRefresh: _reload,
        child: SsEmptyState(
          icon: widget.emptyIcon,
          title: widget.emptyTitle ?? s.notifEmptyTitle,
          subtitle: widget.emptyText ?? s.notifEmptyText,
        ),
      );
    }

    final unread = _unread;
    final header = widget.showHeader && unread > 0
        ? _Faixa(unread: unread, onMarkAll: widget.markAllRead == null ? null : _markAll)
        : null;
    return _lista(
      context,
      itens: _items,
      header: header,
      hasMore: _hasMore,
      loadingMore: _loadingMore,
      moreFailed: _moreFailed,
      onMore: _more,
      onRefresh: _reload,
      tile: (n) => _comDeslize(n, SsNotificationTile(item: n, onTap: () => _open(n), onAction: (a) => _act(n, a))),
    );
  }

  // A lista agrupada por dia, com a faixa de cima ([header]), o "carregar mais" e o puxar para atualizar.
  Widget _lista(
    BuildContext context, {
    required List<SsNotificationItem> itens,
    required Widget? header,
    required bool hasMore,
    required bool loadingMore,
    required bool moreFailed,
    required Future<void> Function() onMore,
    required Future<void> Function() onRefresh,
    required Widget Function(SsNotificationItem n) tile,
  }) {
    final s = _s;
    final now = widget.now?.call() ?? DateTime.now();
    final linhas = <Object>[]; // String (cabeçalho do dia) ou SsNotificationItem
    String? diaAtual;
    for (final n in itens) {
      if (widget.groupByDay && n.createdAt != null) {
        final rotulo = SsNotificationCenter.dayLabel(n.createdAt!.toLocal(), now, s);
        if (rotulo != diaAtual) {
          linhas.add(rotulo);
          diaAtual = rotulo;
        }
      }
      linhas.add(n);
    }
    final comFaixa = header != null;
    final total = linhas.length + (comFaixa ? 1 : 0) + 1;

    // scrollable: o NotificationListener esconde o ListView do SsPullToRefresh (o contorno que os apps
    // faziam na v1.3.1); sem ele, a lista ganharia um SingleChildScrollView em volta (altura sem limite).
    return SsPullToRefresh(
      onRefresh: onRefresh,
      scrollable: true,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.depth == 0 && n.metrics.extentAfter < 400 && !moreFailed) onMore();
          return false;
        },
        child: ListView.builder(
          padding: widget.padding ?? safeListPadding(context),
          itemCount: total,
          itemBuilder: (context, i) {
            if (comFaixa && i == 0) return header;
            final j = i - (comFaixa ? 1 : 0);
            if (j == linhas.length) {
              return SsLoadMore(hasMore: hasMore, loading: loadingMore, onLoadMore: onMore, endLabel: s.notifEnd);
            }
            final l = linhas[j];
            if (l is String) return SsGroupHeader(l);
            final n = l as SsNotificationItem;
            return _Volta(
              key: ValueKey('ss-notif-volta-${n.id}'),
              animate: _voltando.remove(n.id),
              child: Padding(padding: const EdgeInsets.only(bottom: 8), child: tile(n)),
            );
          },
        ),
      ),
    );
  }

  Widget _comDeslize(SsNotificationItem n, Widget tile) {
    final s = _s;
    final c = SsColors.of(context);
    final ler = n.unread && widget.markRead != null;
    final arquivar = widget.archive != null;
    if (!ler && !arquivar) return tile;
    return SsSwipeAction(
      key: ValueKey('ss-notif-${n.id}'),
      start: ler
          ? SsSwipeSide(icon: Icons.done_rounded, label: s.notifMarkRead, color: c.accent, onTrigger: () => _markOne(n))
          : null,
      end: arquivar
          ? SsSwipeSide(
              icon: Icons.archive_outlined,
              label: s.notifArchive,
              color: c.muted,
              destructive: true,
              onTrigger: () => _archive(n),
            )
          : null,
      child: tile,
    );
  }
}

/// v1.14.2: o item que volta (desfazer do arquivar) entra crescendo no lugar, como no [SsUndoableRemoval]:
/// altura, opacidade e escala ([SsMotion.medium], [SsMotion.enter]); com menos movimento, aparece direto.
class _Volta extends StatefulWidget {
  const _Volta({super.key, required this.animate, required this.child});
  final bool animate;
  final Widget child;

  @override
  State<_Volta> createState() => _VoltaState();
}

class _VoltaState extends State<_Volta> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, value: widget.animate ? 0 : 1, duration: SsMotion.medium);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.value == 0 && !_c.isAnimating) {
      if (reduceMotion(context)) {
        _c.value = 1;
      } else {
        _c.animateTo(1, curve: SsMotion.enter);
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizeTransition(
    sizeFactor: _c,
    alignment: AlignmentDirectional.topStart,
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Opacity(
        opacity: _c.value.clamp(0.0, 1.0),
        child: Transform.scale(scale: lerpDouble(.94, 1, _c.value), child: child),
      ),
      child: widget.child,
    ),
  );
}

/// "3 não lidas" e o "Marcar todas como lidas" no alto da lista.
class _Faixa extends StatelessWidget {
  const _Faixa({required this.unread, this.onMarkAll});
  final int unread;
  final VoidCallback? onMarkAll;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = SsStrings.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Semantics(
              liveRegion: true,
              child: Text(
                s.notifUnreadCount(unread),
                style: TextStyle(color: c.accentText, fontSize: AppType.meta, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          if (onMarkAll != null)
            SsButton(
              label: s.notifMarkAllRead,
              icon: Icons.done_all_rounded,
              variant: SsButtonVariant.ghost,
              small: true,
              expand: false,
              onPressed: onMarkAll,
            ),
        ],
      ),
    );
  }
}

/// Uma linha da central (também serve na folha do sino): quadradinho tonal com o ícone, título (negrito e
/// na cor do texto quando não lido), o corpo em até 3 linhas, a hora e o ponto de não lido. Lida, apaga um
/// pouco. Um nó só no leitor de tela: "Título. Corpo. 14:05. não lida".
///
/// v1.9.2 (aviso rico, tudo opcional no [SsNotificationItem]): o selo do nível (aviso/crítico, com o tom no
/// quadradinho e no contorno), a [SsNotificationItem.image] embaixo do texto e, com botões
/// ([SsNotificationItem.actions], [SsNotificationItem.onMute]), a faixa de botões embaixo: aí o topo continua
/// sendo o toque de abrir e cada botão é um nó próprio. [onAction] troca o que o toque de um botão faz (a
/// central marca o aviso como lido antes); sem ele, chama o `onPressed` da ação.
class SsNotificationTile extends StatelessWidget {
  const SsNotificationTile({super.key, required this.item, this.onTap, this.time, this.onAction});

  final SsNotificationItem item;
  final VoidCallback? onTap;

  /// Texto da hora; padrão `HH:mm` do [SsNotificationItem.createdAt].
  final String? time;

  /// v1.9.2: toque num botão de resposta (padrão: `action.onPressed`).
  final void Function(SsNotificationAction action)? onAction;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    final n = item;
    final nivel = n.level;
    final tom = (n.tone ?? nivel?.tone ?? SsTone.accent).colors(context);
    // O selo só quando o nível pede atenção ("Informação" em todo aviso seria ruído).
    final selo = nivel == null || nivel == SsNotificationLevel.info ? null : nivel.label(s);
    final hora =
        time ??
        (n.createdAt == null ? null : '${two(n.createdAt!.toLocal().hour)}:${two(n.createdAt!.toLocal().minute)}');
    // v1.9.3: sem ".." quando o corpo (ou o título) já termina em pontuação.
    final rotulo = ssJoinSentences([
      ?selo,
      n.title,
      if (n.body != null && n.body!.isNotEmpty) n.body!,
      ?hora,
      if (n.unread) s.notifUnread,
    ]);
    final contorno = selo != null
        ? Color.alphaBlend(tom.solid.withValues(alpha: n.unread ? .55 : .35), c.line)
        : n.unread
        ? Color.alphaBlend(c.accent.withValues(alpha: .35), c.line)
        : c.line;
    final pad = EdgeInsets.symmetric(horizontal: d.space(12), vertical: d.space(10));
    final topo = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Opacity(
          opacity: n.unread ? 1 : .7,
          child: SsIconTile(n.icon ?? nivel?.icon ?? Icons.notifications_none_rounded, size: 40, tone: tom.solid),
        ),
        SizedBox(width: d.space(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      n.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: n.unread ? c.ink : c.ink2,
                        fontSize: d.font(AppType.body),
                        fontWeight: n.unread ? FontWeight.w800 : FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                  if (hora != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      hora,
                      style: AppTheme.number(context, size: AppType.label, color: c.muted),
                    ),
                  ],
                  if (n.unread) ...[
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                      ),
                    ),
                  ],
                ],
              ),
              if (selo != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: SsBadge(
                    selo,
                    micro: true,
                    icon: nivel!.icon,
                    variant: nivel == SsNotificationLevel.critical ? SsBadgeVariant.danger : SsBadgeVariant.warning,
                  ),
                ),
              if (n.body != null && n.body!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  n.body!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.muted, fontSize: AppType.sub, height: 1.35),
                ),
              ],
              if (n.image != null)
                Padding(
                  padding: EdgeInsets.only(top: d.space(10)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.thumb),
                    child: AspectRatio(aspectRatio: 16 / 9, child: n.image),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    final deco = BoxDecoration(
      color: c.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      border: Border.all(color: contorno),
      boxShadow: n.unread && !c.isDark ? AppShadows.card : null,
    );
    Widget tocavel(Widget child, {double scale = .98}) => Semantics(
      button: onTap != null,
      label: rotulo,
      excludeSemantics: true,
      child: SsPressable(onTap: onTap, enabled: onTap != null, scale: scale, child: child),
    );
    if (!n.hasButtons) {
      return tocavel(
        Container(
          constraints: BoxConstraints(minHeight: d.minTarget + 8),
          padding: pad,
          decoration: deco,
          child: topo,
        ),
      );
    }
    void tocar(SsNotificationAction a) => onAction != null ? onAction!(a) : a.onPressed?.call();
    return Container(
      constraints: BoxConstraints(minHeight: d.minTarget + 8),
      decoration: deco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Com botões embaixo, o topo não encolhe no toque (os botões ficariam parados ao lado).
          tocavel(Padding(padding: pad, child: topo), scale: 1),
          Padding(
            // Alinhado ao texto (quadradinho de 40 + o respiro).
            padding: EdgeInsets.fromLTRB(d.space(12) + 40 + d.space(12), 0, d.space(12), d.space(10)),
            child: Wrap(
              spacing: d.space(8),
              runSpacing: d.space(8),
              children: [
                for (final (i, a) in n.actions.indexed)
                  SsButton(
                    label: a.label,
                    icon: a.icon,
                    small: true,
                    expand: false,
                    variant: i == 0 ? SsButtonVariant.primary : SsButtonVariant.ghost,
                    onPressed: a.onPressed == null ? null : () => tocar(a),
                  ),
                if (n.onMute != null)
                  SsButton(
                    label: n.muteLabel ?? s.notifMute,
                    icon: Icons.notifications_off_outlined,
                    small: true,
                    expand: false,
                    variant: SsButtonVariant.ghost,
                    onPressed: n.onMute,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// v1.9.3: junta frases para o leitor de tela com ". ", sem repetir a pontuação de quem já termina em
/// ".", "!", "?", "…" ou ":" ("Chegou o boleto.. 10:30" vira "Chegou o boleto. 10:30"). Partes vazias saem.
String ssJoinSentences(Iterable<String> parts) {
  final b = StringBuffer();
  for (final raw in parts) {
    final p = raw.trim();
    if (p.isEmpty) continue;
    if (b.isNotEmpty) {
      final t = b.toString();
      b.write(RegExp(r'[.!?…:;]$').hasMatch(t) ? ' ' : '. ');
    }
    b.write(p);
  }
  return b.toString();
}
