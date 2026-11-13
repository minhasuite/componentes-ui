import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'ss_strings.dart';

/// Variação da tela de entrada "Folhinha" (v0.22, par do `variant:` do `Ss::AuthLayoutComponent`).
enum SsAuthVariant {
  /// A folha pendurada: data no alto, o formulário no bloco e a faixa do produto embaixo.
  sheet,

  /// A parede: folhinha grande à esquerda e o formulário numa coluna à direita (largura ≥ 840);
  /// mais estreito, a folhinha encolhe em cima do formulário.
  wall,

  /// O bloco de destacar: faixa do produto colada em cima, folha picotada e a de amanhã por baixo.
  pad,
}

/// Tela de entrada "Folhinha" (v0.22). Use pelo [SsAuthLayout.folhinha]; o formulário e os avisos são do
/// app ([SsTextField], [SsButton], [SsCallout], [SsGoogleButton]…), passados em `children`.
class SsAuthFolhinha extends StatelessWidget {
  const SsAuthFolhinha({
    super.key,
    required this.product,
    required this.title,
    required this.children,
    this.subtitle,
    this.tagline,
    this.variant = SsAuthVariant.sheet,
    this.date,
    this.note,
    this.brand = const ('Minha', 'Suite'),
    this.footer = const [],
  });

  /// Nome do produto, na faixa do patrocinador (cor da marca do tema).
  final String product;

  /// Título do bloco ("Entrar", "Criar conta"…), na fonte de exibição.
  final String title;
  final String? subtitle;

  /// Frase curta do produto, ao lado do nome na faixa.
  final String? tagline;
  final List<Widget> children;
  final SsAuthVariant variant;

  /// Dia da folhinha (padrão: hoje). Domingo sai na cor de perigo, como no calendário de parede.
  final DateTime? date;

  /// Linha curta ao lado do dia (só [SsAuthVariant.sheet]).
  final String? note;

  /// Marca do topo: as duas partes do nome (a segunda na cor de perigo, como o "Suite" do site).
  final (String, String) brand;

  /// Links de baixo (termos, privacidade), já montados pelo app.
  final List<Widget> footer;

  DateTime get _dia => date ?? DateTime.now();

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return ColoredBox(
      color: c.page,
      child: SafeArea(
        child: switch (variant) {
          SsAuthVariant.wall => _parede(context),
          SsAuthVariant.pad => _palco(context, _bloco(context)),
          SsAuthVariant.sheet => _palco(context, _folha(context)),
        },
      ),
    );
  }

  // ---- Partes ----

  Widget _marca(BuildContext context, {TextAlign align = TextAlign.center}) {
    final c = SsColors.of(context);
    final st = AppTheme.display(context, size: 28, color: c.ink);
    return Semantics(
      header: false,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: brand.$1, style: st),
            TextSpan(
              text: brand.$2,
              style: st.copyWith(color: c.danger),
            ),
          ],
        ),
        textAlign: align,
      ),
    );
  }

  String _mes(BuildContext context) => SsStrings.of(context).months[_dia.month - 1];

  String _semana(BuildContext context, DateTime d) {
    final s = SsStrings.of(context).weekdaysFull[d.weekday - 1];
    return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  }

  Widget _cabecalho(BuildContext context, {EdgeInsets padding = const EdgeInsets.fromLTRB(28, 34, 28, 0)}) {
    final c = SsColors.of(context);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              _mes(context),
              style: AppTheme.display(context, size: 32, weight: FontWeight.w800, color: c.ink),
            ),
          ),
          Text(
            '${_dia.year}',
            style: TextStyle(fontWeight: FontWeight.w700, color: c.muted, fontSize: AppType.md),
          ),
        ],
      ),
    );
  }

  Widget _numero(BuildContext context, DateTime d, double size, {Color? color}) {
    final c = SsColors.of(context);
    final dom = d.weekday == DateTime.sunday;
    return Text(
      '${d.day}',
      style: AppTheme.display(context, size: size, color: color ?? (dom ? c.danger : c.ink)).copyWith(height: .8),
    );
  }

  Widget _corpo(BuildContext context, {EdgeInsets padding = const EdgeInsets.fromLTRB(28, 24, 28, 28)}) {
    final c = SsColors.of(context);
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: AppTheme.display(context, size: 40, color: c.ink)),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: TextStyle(color: c.muted, fontSize: AppType.body),
            ),
          ],
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _faixa(
    BuildContext context, {
    BorderRadius? radius,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
  }) {
    final c = SsColors.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: c.accentSolid, borderRadius: radius),
      child: Row(
        children: [
          Expanded(
            child: Text(product, style: AppTheme.display(context, size: 24, color: AppColors.onDark)),
          ),
          if (tagline != null) ...[
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                tagline!,
                textAlign: TextAlign.end,
                style: TextStyle(color: AppColors.onDark.withValues(alpha: .85), fontSize: AppType.set),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<BoxShadow> _sombra(SsColors c) => [
    BoxShadow(color: c.ink.withValues(alpha: .06), offset: const Offset(0, 1), blurRadius: 1),
    BoxShadow(
      color: c.ink.withValues(alpha: c.isDark ? .5 : .3),
      offset: const Offset(0, 18),
      blurRadius: 40,
      spreadRadius: -18,
    ),
  ];

  /// Furo do prego acima da folha.
  Widget _prego(SsColors c) => Center(
    child: Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: c.page,
        shape: BoxShape.circle,
        border: Border.all(color: c.line, width: 2),
      ),
    ),
  );

  /// Folhas de baixo, aparecendo sob a da frente.
  List<Widget> _folhasDeBaixo(SsColors c) => [
    for (final m in [6.0, 12.0])
      Container(
        margin: EdgeInsets.symmetric(horizontal: m),
        height: 6,
        decoration: BoxDecoration(
          color: c.surface,
          boxShadow: [BoxShadow(color: c.ink.withValues(alpha: .14), blurRadius: 2, offset: const Offset(0, 1))],
        ),
      ),
  ];

  Widget _palco(BuildContext context, Widget miolo) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 56),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _marca(context),
            const SizedBox(height: 18),
            miolo,
            if (footer.isNotEmpty) ...[
              const SizedBox(height: 18),
              Wrap(alignment: WrapAlignment.center, spacing: 18, runSpacing: 8, children: footer),
            ],
          ],
        ),
      ),
    ),
  );

  // ---- Variações ----

  Widget _folha(BuildContext context) {
    final c = SsColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _prego(c),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(color: c.surface, boxShadow: _sombra(c)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _cabecalho(context),
              Container(
                padding: const EdgeInsets.fromLTRB(28, 4, 28, 20),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: c.ink, width: 2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _numero(context, _dia, 104),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _semana(context, _dia),
                              style: TextStyle(
                                color: c.ink,
                                fontWeight: FontWeight.w800,
                                fontSize: AppType.headerTitle,
                              ),
                            ),
                            if (note != null)
                              Text(
                                note!,
                                style: TextStyle(color: c.muted, fontWeight: FontWeight.w700, fontSize: AppType.body),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _corpo(context),
              _faixa(context),
            ],
          ),
        ),
        ..._folhasDeBaixo(c),
      ],
    );
  }

  Widget _bloco(BuildContext context) {
    final c = SsColors.of(context);
    final amanha = _dia.add(const Duration(days: 1));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _faixa(
          context,
          radius: const BorderRadius.vertical(top: Radius.circular(12)),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 14),
        ),
        Container(
          decoration: BoxDecoration(color: c.surface, boxShadow: _sombra(c)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomPaint(size: const Size.fromHeight(4), painter: _Picote(c.page)),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    _numero(context, _dia, 52),
                    const Spacer(),
                    Text(
                      '${_semana(context, _dia)}, ${_mes(context)}',
                      style: TextStyle(color: c.muted, fontWeight: FontWeight.w700, fontSize: AppType.body),
                    ),
                  ],
                ),
              ),
              _corpo(context),
            ],
          ),
        ),
        ExcludeSemantics(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            decoration: BoxDecoration(color: c.surface, boxShadow: _sombra(c)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                _numero(context, amanha, 32, color: c.muted),
                const Spacer(),
                Text(
                  _semana(context, amanha),
                  style: TextStyle(color: c.muted, fontWeight: FontWeight.w700, fontSize: AppType.set),
                ),
              ],
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          height: 8,
          decoration: BoxDecoration(
            color: c.surface,
            boxShadow: [BoxShadow(color: c.ink.withValues(alpha: .14), blurRadius: 2, offset: const Offset(0, 1))],
          ),
        ),
      ],
    );
  }

  Widget _parede(BuildContext context) {
    final c = SsColors.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final largo = box.maxWidth >= 840;
        final folhinha = ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _prego(c),
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(color: c.surface, boxShadow: _sombra(c)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _cabecalho(context, padding: EdgeInsets.fromLTRB(32, largo ? 40 : 26, 32, 0)),
                    const SizedBox(height: 8),
                    Center(child: _numero(context, _dia, largo ? 260 : 128)),
                    SizedBox(height: largo ? 20 : 12),
                    Text(
                      _semana(context, _dia),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.ink, fontWeight: FontWeight.w700, fontSize: AppType.headerTitle),
                    ),
                    SizedBox(height: largo ? 28 : 16),
                    _faixa(context, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18)),
                  ],
                ),
              ),
              ..._folhasDeBaixo(c),
            ],
          ),
        );
        final painel = ColoredBox(
          color: c.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  SsStrings.of(context).authPartOf('${brand.$1}${brand.$2}'),
                  style: TextStyle(color: c.muted, fontSize: AppType.body),
                ),
                if (largo) const Spacer(),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _corpo(context, padding: const EdgeInsets.symmetric(vertical: 32)),
                ),
                if (largo) const Spacer(),
                if (footer.isNotEmpty) Wrap(spacing: 18, runSpacing: 8, children: footer),
              ],
            ),
          ),
        );
        if (largo) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(48, 32, 48, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _marca(context, align: TextAlign.start),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: folhinha),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 560, child: painel),
            ],
          );
        }
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _marca(context, align: TextAlign.start),
                    const SizedBox(height: 12),
                    folhinha,
                  ],
                ),
              ),
              painel,
            ],
          ),
        );
      },
    );
  }
}

/// Picote no alto da folha do bloco: meias-luas na cor da parede, a cada 16 px.
class _Picote extends CustomPainter {
  _Picote(this.cor);
  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = cor;
    for (double x = 8; x < size.width; x += 16) {
      canvas.drawCircle(Offset(x, 0), 4, p);
    }
  }

  @override
  bool shouldRepaint(_Picote old) => old.cor != cor;
}
