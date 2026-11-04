import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ss_controls.dart' show SsSegmented;
import 'ss_fields.dart' show SsSwitch;
import 'ss_async.dart' show SsSelfScrolling;
import 'ss_strings.dart';

// Aba "Mais" padrão da suíte (o modelo é o menu do meu-financeiro).
// Arquivo idêntico em todos os apps: só usa o ColorScheme, então não depende
// dos tokens de cada um (as exceções são o [SsSwitch], que recebe a cor primária,
// e o [SsSegmented] do tema, que lê o SsColors do pacote).
// Ao mudar aqui, copie para os outros apps.
//
// Ordem fixa: busca, perfil, planos, seções do app, "Aparência e sobre",
// "Excluir minha conta" (só com onDeleteAccount) e "Sair".

/// Uma linha do menu. Entra na busca pelo título e pelo subtítulo.
class SsMenuItem {
  const SsMenuItem(
    this.icon,
    this.title, {
    this.subtitle,
    this.onTap,
    this.onLongPress,
    this.danger = false,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Vermelho: só para o que apaga (zerar dados, sair de todos os aparelhos).
  final bool danger;

  /// No lugar da seta (ex.: contador de não lidas, carregando).
  final Widget? trailing;
}

/// Seção recolhível: as linhas e, depois delas, o que não é linha (switches,
/// cartões de integração). [top] vai antes das linhas (seletor de paleta,
/// aviso). Widget solto fica sem cartão: embrulhe em [SsMenuCard] para ter o
/// mesmo cartão das linhas.
class SsMenuSection {
  const SsMenuSection(this.title, this.items, {this.extra = const [], this.open = true, this.top = const []});

  final String title;
  final List<SsMenuItem> items;
  final List<Widget> extra;
  final List<Widget> top;
  final bool open;
}

class SsMenuView extends StatefulWidget implements SsSelfScrolling {
  const SsMenuView({
    super.key,
    required this.name,
    required this.email,
    required this.sections,
    required this.themeMode,
    required this.onThemeMode,
    this.onDeleteAccount,
    required this.onLogout,
    this.badge,
    this.onProfile,
    this.planLabel,
    this.onPlans,
    this.about = const [],
    this.searchOnly = const [],
    this.onRefresh,
    this.appearance = const [],
    this.appearanceOpen = false,
  });

  final String name;
  final String email;

  /// Papel, casa ou grupo, ao lado do nome.
  final String? badge;
  final VoidCallback? onProfile;

  /// "Plano Pro", "Basic · teste grátis até 12/11"…
  final String? planLabel;

  /// Nulo = sem a linha de planos (ex.: funcionário, que não assina).
  final VoidCallback? onPlans;

  final List<SsMenuSection> sections;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeMode;

  /// Termos, privacidade, exclusão de dados, versão: vão em "Aparência e sobre".
  final List<SsMenuItem> about;

  /// Widgets livres em "Aparência e sobre", logo abaixo do tema e antes de
  /// [about]: seletor de paleta ([SsPalettePicker]), [SsMenuSwitch], linha de
  /// idioma ([SsLocalePicker] dentro de um [SsMenuCard]).
  final List<Widget> appearance;

  /// "Aparência e sobre" já aberta (padrão: recolhida).
  final bool appearanceOpen;

  /// Achadas pela busca sem aparecer no menu (telas de outra aba).
  final List<SsMenuItem> searchOnly;

  /// Nulo = sem o botão "Excluir minha conta" (a exclusão mora noutro lugar,
  /// ou o app não tem conta própria).
  final VoidCallback? onDeleteAccount;
  final VoidCallback onLogout;
  final Future<void> Function()? onRefresh;

  @override
  State<SsMenuView> createState() => _SsMenuViewState();
}

class _SsMenuViewState extends State<SsMenuView> {
  final _search = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final str = SsStrings.of(context);
    final w = widget;
    final q = _query.trim().toLowerCase();

    final searchField = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _search,
        textInputAction: TextInputAction.search,
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: str.searchMenu,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: q.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: str.clearSearch,
                  onPressed: () {
                    _search.clear();
                    setState(() => _query = '');
                  },
                ),
        ),
      ),
    );

    final List<Widget> children;
    if (q.isNotEmpty) {
      final all = [for (final sec in w.sections) ...sec.items, ...w.searchOnly, ...w.about];
      final found = all.where((i) => '${i.title} ${i.subtitle ?? ''}'.toLowerCase().contains(q)).toList();
      children = [
        searchField,
        if (found.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              str.menuNothingFound(_query.trim()),
              textAlign: TextAlign.center,
              style: TextStyle(color: s.onSurfaceVariant),
            ),
          ),
        for (final i in found) SsMenuRow(i),
      ];
    } else {
      children = [
        searchField,
        SsMenuCard(
          onTap: w.onProfile,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: s.primaryContainer,
                child: Text(
                  w.name.trim().isEmpty ? '?' : w.name.trim()[0].toUpperCase(),
                  style: TextStyle(color: s.primary, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      w.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w800, color: s.onSurface),
                    ),
                    Text(
                      w.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: s.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (w.badge != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  flex: 0,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 120),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: s.onSurfaceVariant.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      w.badge!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: s.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
              if (w.onProfile != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: s.onSurfaceVariant),
              ],
            ],
          ),
        ),
        if (w.onPlans != null)
          SsMenuCard(
            onTap: w.onPlans,
            child: Row(
              children: [
                Icon(Icons.workspace_premium, color: s.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        str.plansAndSubscription,
                        style: TextStyle(fontWeight: FontWeight.w700, color: s.onSurface),
                      ),
                      if (w.planLabel != null)
                        Text(w.planLabel!, style: TextStyle(color: s.onSurfaceVariant, fontSize: 13)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: s.onSurfaceVariant),
              ],
            ),
          ),
        for (final sec in w.sections)
          if (sec.items.isNotEmpty || sec.extra.isNotEmpty || sec.top.isNotEmpty)
            SsMenuGroup(
              title: sec.title,
              open: sec.open,
              children: [...sec.top, for (final i in sec.items) SsMenuRow(i), ...sec.extra],
            ),
        SsMenuGroup(
          title: str.appearanceAndAbout,
          open: w.appearanceOpen,
          children: [
            SsMenuCard(
              padding: const EdgeInsets.all(12),
              // O segmented da suíte (pílula que desliza com mola).
              child: SsSegmented<ThemeMode>(
                segments: [
                  (ThemeMode.system, str.themeSystem),
                  (ThemeMode.light, str.themeLight),
                  (ThemeMode.dark, str.themeDark),
                ],
                icons: const [Icons.brightness_auto_rounded, Icons.light_mode_rounded, Icons.dark_mode_rounded],
                value: w.themeMode,
                onChanged: w.onThemeMode,
              ),
            ),
            ...w.appearance,
            for (final i in w.about) SsMenuRow(i),
          ],
        ),
        const SizedBox(height: 12),
        if (w.onDeleteAccount != null) ...[
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: w.onDeleteAccount,
              icon: const Icon(Icons.delete_forever_outlined),
              label: Text(str.deleteMyAccount),
              style: FilledButton.styleFrom(
                backgroundColor: s.error,
                foregroundColor: s.onError,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: w.onLogout,
            icon: const Icon(Icons.logout),
            label: Text(str.signOut),
            style: OutlinedButton.styleFrom(
              foregroundColor: s.onSurface,
              side: BorderSide(color: s.outlineVariant),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
      ];
    }

    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: children,
    );
    return w.onRefresh == null ? list : RefreshIndicator(onRefresh: w.onRefresh!, child: list);
  }
}

/// Linha do menu: ícone na bolha, título, subtítulo e seta.
class SsMenuRow extends StatelessWidget {
  const SsMenuRow(this.item, {super.key});
  final SsMenuItem item;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final color = item.danger ? s.error : s.primary;
    return SsMenuCard(
      onTap: item.onTap,
      onLongPress: item.onLongPress,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _MenuIcon(item.icon, color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: item.danger ? s.error : s.onSurface,
                    fontSize: 15,
                  ),
                ),
                if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: s.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          item.trailing ??
              (item.onTap == null ? const SizedBox.shrink() : Icon(Icons.chevron_right, color: s.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// Interruptor no mesmo cartão das linhas, para as preferências das seções.
/// [icon] põe a bolha de ícone das linhas ([SsMenuRow]) à esquerda.
class SsMenuSwitch extends StatelessWidget {
  const SsMenuSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SsMenuCard(
    padding: EdgeInsets.symmetric(horizontal: icon == null ? 4 : 0, vertical: 2),
    // O interruptor da suíte (a bolinha estica, amassa no fim e a cor escorre
    // na trilha), na cor primária do tema.
    child: MergeSemantics(
      child: ListTile(
        // O toque no próprio interruptor já dá o haptic (SsSwitch).
        onTap: onChanged == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onChanged!(!value);
              },
        enabled: onChanged != null,
        leading: icon == null ? null : _MenuIcon(icon!, Theme.of(context).colorScheme.primary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: SsSwitch(value: value, onChanged: onChanged, activeColor: Theme.of(context).colorScheme.primary),
      ),
    ),
  );
}

/// Seção recolhível do menu, com o título em caixa alta.
class SsMenuGroup extends StatelessWidget {
  const SsMenuGroup({super.key, required this.title, required this.children, this.open = true});

  final String title;
  final bool open;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Theme(
      // Sem as linhas que o ExpansionTile desenha ao abrir.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: open,
        maintainState: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        childrenPadding: EdgeInsets.zero,
        title: Text(
          title.toUpperCase(),
          style: TextStyle(color: s.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: .6),
        ),
        children: children,
      ),
    );
  }
}

/// Bolha de ícone das linhas do menu (40 px, fundo na cor a 12%).
class _MenuIcon extends StatelessWidget {
  const _MenuIcon(this.icon, this.color);
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: 40,
    width: 40,
    decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)),
    child: Icon(icon, color: color, size: 20),
  );
}

/// Cartão das linhas do menu: sombra leve no claro, borda no escuro. Público
/// para os widgets livres do [SsMenuView] (`appearance`, `SsMenuSection.top`
/// e `extra`) ficarem no mesmo cartão.
class SsMenuCard extends StatelessWidget {
  const SsMenuCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(20);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: dark ? Border.all(color: s.outlineVariant) : null,
          boxShadow: dark
              ? null
              : const [
                  BoxShadow(color: Color(0x0D1B1640), offset: Offset(0, 1), blurRadius: 2),
                  BoxShadow(color: Color(0x141B1640), offset: Offset(0, 10), blurRadius: 28, spreadRadius: -10),
                ],
        ),
        child: Material(
          color: s.surface,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
