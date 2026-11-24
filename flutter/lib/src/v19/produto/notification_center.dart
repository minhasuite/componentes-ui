// v1.9 · produto: central de notificações (par do Ss::NotificationCenterComponent do web). Generaliza o que
// minhas-vendas-app, meu-cultivo-app e meu-personal-app montaram à mão: lista paginada por dia, lida/não lida,
// tocar marca lida e abre, "marcar todas", deslizar para ler/arquivar, puxar para atualizar, vazio e erro.
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../app_theme.dart';
import '../../density.dart';
import '../../format.dart';
import '../../motion.dart';
import '../../safe_list_padding.dart';
import '../../ss_async.dart';
import '../../ss_badge.dart';
import '../../ss_button.dart';
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

  bool get unread => !read;

  SsNotificationItem copyWith({bool? read}) => SsNotificationItem(
    id: id,
    title: title,
    body: body,
    createdAt: createdAt,
    read: read ?? this.read,
    icon: icon,
    tone: tone,
    data: data,
  );
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

  void _setUnread(int n) {
    if (n == _unread) return;
    _unread = n;
    notifyListeners();
  }
}

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

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _reload();
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
      if (mounted) showSsToast(context, _s.notifArchived, icon: Icons.archive_outlined);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items.insert(i.clamp(0, _items.length), n);
        if (n.unread) _readHere--;
      });
      _syncUnread();
      showSsToast(context, _errorText(e), icon: Icons.error_outline_rounded, tone: AppColors.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
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

    final now = widget.now?.call() ?? DateTime.now();
    final linhas = <Object>[]; // String (cabeçalho do dia) ou SsNotificationItem
    String? diaAtual;
    for (final n in _items) {
      if (widget.groupByDay && n.createdAt != null) {
        final rotulo = SsNotificationCenter.dayLabel(n.createdAt!.toLocal(), now, s);
        if (rotulo != diaAtual) {
          linhas.add(rotulo);
          diaAtual = rotulo;
        }
      }
      linhas.add(n);
    }
    final unread = _unread;
    final header = widget.showHeader && unread > 0;
    final total = linhas.length + (header ? 1 : 0) + 1;

    // scrollable: o NotificationListener esconde o ListView do SsPullToRefresh (o contorno que os apps
    // faziam na v1.3.1); sem ele, a lista ganharia um SingleChildScrollView em volta (altura sem limite).
    return SsPullToRefresh(
      onRefresh: _reload,
      scrollable: true,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.depth == 0 && n.metrics.extentAfter < 400 && !_moreFailed) _more();
          return false;
        },
        child: ListView.builder(
          padding: widget.padding ?? safeListPadding(context),
          itemCount: total,
          itemBuilder: (context, i) {
            if (header && i == 0) {
              return _Faixa(unread: unread, onMarkAll: widget.markAllRead == null ? null : _markAll);
            }
            final j = i - (header ? 1 : 0);
            if (j == linhas.length) {
              return SsLoadMore(hasMore: _hasMore, loading: _loadingMore, onLoadMore: _more, endLabel: s.notifEnd);
            }
            final l = linhas[j];
            if (l is String) return SsGroupHeader(l);
            final n = l as SsNotificationItem;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _comDeslize(n, SsNotificationTile(item: n, onTap: () => _open(n))),
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
class SsNotificationTile extends StatelessWidget {
  const SsNotificationTile({super.key, required this.item, this.onTap, this.time});

  final SsNotificationItem item;
  final VoidCallback? onTap;

  /// Texto da hora; padrão `HH:mm` do [SsNotificationItem.createdAt].
  final String? time;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    final n = item;
    final tom = (n.tone ?? SsTone.accent).colors(context);
    final hora =
        time ??
        (n.createdAt == null ? null : '${two(n.createdAt!.toLocal().hour)}:${two(n.createdAt!.toLocal().minute)}');
    final rotulo = [
      n.title,
      if (n.body != null && n.body!.isNotEmpty) n.body!,
      ?hora,
      if (n.unread) s.notifUnread,
    ].join('. ');
    return Semantics(
      button: onTap != null,
      label: rotulo,
      excludeSemantics: true,
      child: SsPressable(
        onTap: onTap,
        enabled: onTap != null,
        scale: .98,
        child: Container(
          constraints: BoxConstraints(minHeight: d.minTarget + 8),
          padding: EdgeInsets.symmetric(horizontal: d.space(12), vertical: d.space(10)),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: n.unread ? Color.alphaBlend(c.accent.withValues(alpha: .35), c.line) : c.line),
            boxShadow: n.unread && !c.isDark ? AppShadows.card : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Opacity(
                opacity: n.unread ? 1 : .7,
                child: SsIconTile(n.icon ?? Icons.notifications_none_rounded, size: 40, tone: tom.solid),
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
                    if (n.body != null && n.body!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        n.body!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.muted, fontSize: AppType.sub, height: 1.35),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
