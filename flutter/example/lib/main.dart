// Vitrine do componentes_ui ("Componentes da Suíte"): todas as peças do catálogo ao vivo (os
// mesmos estados que a skill `componentes` exporta em SVG) e telas montadas, organizadas por
// categoria de uso, as mesmas da vitrine web (demo.minhasuite.com).
// Rodar: example/tool/vitrine.sh (web) ou flutter build apk.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'aparencia.dart';
import 'catalogo/catalogo.dart';
import 'catalogo/catalogo_v1110.dart';
import 'categorias.dart';
import 'telas/tela_demo.dart';
import 'telas/telas_a.dart';
import 'telas/telas_b.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const ProviderScope(child: Vitrine()));
}

const _demoUrl = 'https://demo.minhasuite.com';
const _repoUrl = 'https://github.com/minhasuite/componentes-ui';

/// Peças da onda atual: as que o `comV1110` do catálogo acrescenta (aplicado a uma lista
/// vazia) mais as marcadas "(v1.11…)" na descrição. Onda nova de peças = trocar o `comV*` aqui.
final Set<String> _novas = {
  for (final onda in [comV1110])
    for (final c in onda(const <Componente>[])) c.slug,
  for (final c in catalogo)
    if (ehNovidade(c.nome, c.descricao)) c.slug,
};

final List<TelaDemo> _telas = [...telasA, ...telasB];

bool ehNova(Componente c) => _novas.contains(c.slug);

/// Peças da categoria, na ordem do catálogo. Sem categoria (o teste acusa) vai para a Fundação.
List<Componente> pecasDe(Categoria cat) => [
  for (final c in catalogo)
    if (cat == novidades ? ehNova(c) : (categoriaDe(c.slug, c.nome) ?? fundacao) == cat) c,
];

Categoria categoriaDaPeca(Componente c) => categoriaDe(c.slug, c.nome) ?? fundacao;

int _total(Categoria cat) => pecasDe(cat).length + (cat == telas ? _telas.length : 0);

class Vitrine extends StatelessWidget {
  const Vitrine({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: aparencia,
    builder: (context, _) => MaterialApp(
      title: 'Componentes da Suíte',
      debugShowCheckedModeBanner: false,
      theme: aparencia.theme(Brightness.light),
      darkTheme: aparencia.theme(Brightness.dark),
      themeMode: aparencia.value.themeMode,
      home: const _Inicio(),
    ),
  );
}

/// Largura máxima do conteúdo em tela larga (a grade não estica até a borda).
Widget _medida(Widget child, {double max = 1180}) => Align(
  alignment: Alignment.topCenter,
  child: ConstrainedBox(
    constraints: BoxConstraints(maxWidth: max),
    child: SizedBox(width: double.infinity, child: child),
  ),
);

class _Inicio extends StatefulWidget {
  const _Inicio();

  @override
  State<_Inicio> createState() => _InicioState();
}

class _InicioState extends State<_Inicio> {
  String _busca = '';

  bool _bate(String texto) => foldAccents(texto.toLowerCase()).contains(foldAccents(_busca.trim().toLowerCase()));

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final buscando = _busca.trim().isNotEmpty;
    final pecas = buscando ? catalogo.where((x) => _bate('${x.nome} ${x.slug} ${x.descricao}')).toList() : const [];
    final telasAchadas = buscando ? _telas.where((t) => _bate('${t.titulo} ${t.descricao}')).toList() : const [];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _medida(
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      // Barra de cima: aparência e "Sobre" (o título fica inteiro embaixo).
                      Row(
                        children: [
                          const Spacer(),
                          const AparenciaBar(),
                          SsIconButton(
                            icon: Icons.info_outline_rounded,
                            tooltip: 'Sobre',
                            onPressed: () =>
                                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const _Sobre())),
                          ),
                        ],
                      ),
                      Text(
                        'Componentes da Suíte',
                        style: TextStyle(
                          fontSize: AppType.screenTitle,
                          fontWeight: FontWeight.w800,
                          color: c.ink,
                          height: 1.15,
                        ),
                      ),
                      Text(
                        'Lista Clara · componentes_ui v$ssComponentesUiVersion',
                        style: AppTheme.number(context, size: 12, color: c.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _medida(
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SsBadge('${catalogo.length} peças', mono: true),
                      SsBadge('${_telas.length} telas montadas', variant: SsBadgeVariant.muted, mono: true),
                      SsBadge(
                        '${_novas.length} novas na v$versaoNovidades',
                        icon: Icons.auto_awesome_rounded,
                        variant: SsBadgeVariant.muted,
                        mono: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _medida(
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: SsSearchField(hint: 'Buscar componente ou tela', onChanged: (v) => setState(() => _busca = v)),
                ),
              ),
            ),
            if (buscando) ...[
              if (pecas.isEmpty && telasAchadas.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: SsEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Nada com "${_busca.trim()}"',
                      subtitle: 'Tente o nome da peça (ex. SsButton) ou o que ela faz.',
                    ),
                  ),
                ),
              if (telasAchadas.isNotEmpty) ...[
                _Titulo('Telas montadas · ${telasAchadas.length}'),
                SliverList.builder(
                  itemCount: telasAchadas.length,
                  itemBuilder: (context, i) => _medida(_TelaTile(telasAchadas[i])),
                ),
              ],
              if (pecas.isNotEmpty) ...[
                _Titulo('Componentes · ${pecas.length}'),
                SliverList.builder(
                  itemCount: pecas.length,
                  itemBuilder: (context, i) => _medida(_CompTile(pecas[i] as Componente, comCategoria: true)),
                ),
              ],
            ] else ...[
              const _Titulo('Categorias'),
              SliverToBoxAdapter(child: _medida(const _GradeCategorias())),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
      ),
    );
  }
}

/// As categorias em grade (2 colunas no celular, 3 no tablet, 4 na tela larga). Cada cartão
/// abre a categoria crescendo até a tela (container transform, [SsOpenContainer]).
class _GradeCategorias extends StatelessWidget {
  const _GradeCategorias();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 1024 ? 4 : (box.maxWidth >= 600 ? 3 : 2);
        final linhas = <List<Categoria>>[
          for (var i = 0; i < categorias.length; i += cols)
            categorias.sublist(i, (i + cols).clamp(0, categorias.length)),
        ];
        return Column(
          spacing: 12,
          children: [
            for (final linha in linhas)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    for (var j = 0; j < cols; j++)
                      Expanded(child: j < linha.length ? _CategoriaCard(linha[j]) : const SizedBox()),
                  ],
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _CategoriaCard extends StatelessWidget {
  const _CategoriaCard(this.cat);
  final Categoria cat;

  @override
  Widget build(BuildContext context) {
    final n = _total(cat);
    return SsOpenContainer<void>(
      tag: 'categoria-${cat.id}',
      radius: AppRadius.cardActive,
      openBuilder: (_) => _CategoriaPage(cat),
      closedBuilder: (context, open) => Semantics(
        button: true,
        label: '${cat.nome}, $n ${n == 1 ? 'peça' : 'peças'}',
        excludeSemantics: true,
        child: SsFeatureTile(
          icon: cat.iconData,
          title: cat.nome,
          text: '$n ${n == 1 ? 'peça' : 'peças'}',
          tone: cat == novidades ? SsColors.of(context).accent : null,
          onTap: open,
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
    child: _medida(Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 8), child: SsGroupHeader(texto))),
  );
}

/// A categoria: a lista das peças (e das telas, em "Telas montadas"). No celular a peça abre
/// numa página (com o voltar preditivo do tema); em tela larga, lista e peça lado a lado.
class _CategoriaPage extends StatefulWidget {
  const _CategoriaPage(this.cat);
  final Categoria cat;

  @override
  State<_CategoriaPage> createState() => _CategoriaPageState();
}

class _CategoriaPageState extends State<_CategoriaPage> {
  Componente? _sel;

  @override
  Widget build(BuildContext context) {
    final cat = widget.cat;
    final pecas = pecasDe(cat);
    final c = SsColors.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(cat.nome), actions: const [AparenciaBar(densidade: false), SizedBox(width: 4)]),
      body: LayoutBuilder(
        builder: (context, box) {
          final larga = box.maxWidth >= ssWideBreakpoint;
          final atual = _sel ?? (larga && pecas.isNotEmpty ? pecas.first : null);
          final lista = ListView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 48),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(cat.descricao, style: TextStyle(color: c.ink2, height: 1.4)),
              ),
              if (cat == telas) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: SsGroupHeader('Telas da vitrine · ${_telas.length}'),
                ),
                for (final t in _telas) _TelaTile(t),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: SsGroupHeader('Peças de tela inteira · ${pecas.length}'),
                ),
              ],
              for (final p in pecas)
                _CompTile(
                  p,
                  comCategoria: cat == novidades,
                  marcado: larga && identical(p, atual),
                  onTap: larga
                      ? () => setState(() => _sel = p)
                      : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _ComponentePage(p))),
                ),
            ],
          );
          if (!larga) return lista;
          return SsSplitView(
            list: lista,
            detail: atual == null ? null : _ComponenteCorpo(atual, key: ValueKey(atual.slug), titulo: true),
            onBack: () => setState(() => _sel = null),
          );
        },
      ),
    );
  }
}

class _TelaTile extends StatelessWidget {
  const _TelaTile(this.tela);
  final TelaDemo tela;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: SsListItem(
      icon: tela.icone ?? Icons.phone_iphone_rounded,
      title: tela.titulo,
      subtitle: tela.descricao,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: tela.build)),
    ),
  );
}

class _CompTile extends StatelessWidget {
  const _CompTile(this.comp, {this.comCategoria = false, this.marcado = false, this.onTap});
  final Componente comp;

  /// Mostra a categoria de uso no subtítulo (busca e Novidades).
  final bool comCategoria;
  final bool marcado;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cat = categoriaDaPeca(comp);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SsListItem(
        icon: ehNova(comp) ? Icons.auto_awesome_rounded : cat.iconData,
        title: comp.nome,
        subtitle: comCategoria ? '${cat.nome} · ${comp.descricao}' : comp.descricao,
        tone: marcado ? SsColors.of(context).accent : null,
        trailing: Icon(marcado ? Icons.arrow_forward_rounded : Icons.chevron_right_rounded),
        onTap:
            onTap ?? () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _ComponentePage(comp))),
      ),
    );
  }
}

class _ComponentePage extends StatelessWidget {
  const _ComponentePage(this.comp);
  final Componente comp;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(comp.nome), actions: const [AparenciaBar(densidade: false), SizedBox(width: 4)]),
    body: _ComponenteCorpo(comp),
  );
}

/// Descrição, comportamentos e os estados do catálogo.
class _ComponenteCorpo extends StatelessWidget {
  const _ComponenteCorpo(this.comp, {super.key, this.titulo = false});
  final Componente comp;

  /// Põe o nome em cima (no detalhe da tela larga, que não tem barra própria).
  final bool titulo;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final cat = categoriaDaPeca(comp);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
      children: [
        if (titulo)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              comp.nome,
              style: TextStyle(fontSize: AppType.lg, fontWeight: FontWeight.w800, color: c.ink),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SsBadge(cat.nome, icon: cat.iconData, variant: SsBadgeVariant.muted),
            if (ehNova(comp)) SsBadge('Novo na v$versaoNovidades', icon: Icons.auto_awesome_rounded),
          ],
        ),
        const SizedBox(height: 12),
        Text(comp.descricao, style: TextStyle(color: c.ink2, height: 1.4)),
        const SizedBox(height: 12),
        for (final b in comp.comportamentos)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 8),
                  child: Icon(Icons.circle, size: 6, color: c.accent),
                ),
                Expanded(
                  child: Text(b, style: TextStyle(color: c.muted, fontSize: 13)),
                ),
              ],
            ),
          ),
        for (final e in comp.estados) _EstadoView(comp, e),
      ],
    );
  }
}

/// Um estado do catálogo, no tamanho dele (encolhe para caber), com Navigator e
/// Scaffold próprios: folha, diálogo e aviso abrem dentro da moldura.
class _EstadoView extends StatelessWidget {
  const _EstadoView(this.comp, this.estado);
  final Componente comp;
  final Estado estado;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(estado.titulo, style: AppTheme.number(context, size: 12, color: c.muted).copyWith(height: 1.3)),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, box) {
              final w = estado.tamanho.width;
              final escala = box.maxWidth < w ? box.maxWidth / w : 1.0;
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: w * escala,
                  height: estado.tamanho.height * escala,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: c.line),
                  ),
                  child: FittedBox(
                    child: SizedBox.fromSize(
                      size: estado.tamanho,
                      // v1.11.0: o estado pode forçar a plataforma (a variante do iOS das peças adaptativas).
                      child: HeroControllerScope.none(
                        child: _comPlataforma(
                          context,
                          estado.plataforma,
                          Navigator(
                            key: ValueKey('${comp.slug}/${estado.slug}/${Theme.of(context).brightness}'),
                            onGenerateRoute: (_) => PageRouteBuilder<void>(
                              pageBuilder: (context, _, _) => Scaffold(body: Builder(builder: estado.build)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// O [child] com a plataforma do tema trocada (nula: a do aparelho).
Widget _comPlataforma(BuildContext context, TargetPlatform? p, Widget child) => p == null
    ? child
    : Theme(
        data: Theme.of(context).copyWith(platform: p),
        child: child,
      );

class _Sobre extends StatelessWidget {
  const _Sobre();

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final texto = TextStyle(color: c.ink2, height: 1.45);
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
        children: [
          Text(
            'Componentes da Suíte',
            style: TextStyle(fontSize: AppType.lg, fontWeight: FontWeight.w800, color: c.ink),
          ),
          const SizedBox(height: 8),
          Text(
            'A demonstração oficial do Lista Clara, o design system da MinhaSuite: as mesmas peças que os apps '
            'da suíte usam, ao vivo, em claro, escuro e OLED, com as paletas e as densidades. '
            'O pacote é o componentes_ui v$ssComponentesUiVersion.',
            style: texto,
          ),
          const SizedBox(height: 20),
          const SsGroupHeader('A vitrine do web'),
          const SizedBox(height: 8),
          Text('As mesmas categorias, com os componentes Rails e o código de uso.', style: texto),
          const SizedBox(height: 8),
          const SsCodeBlock(_demoUrl),
          const SizedBox(height: 20),
          const SsGroupHeader('O código'),
          const SizedBox(height: 8),
          Text('O repositório do pacote Flutter e da gem Rails.', style: texto),
          const SizedBox(height: 8),
          const SsCodeBlock(_repoUrl),
        ],
      ),
    );
  }
}
