// Vitrine do componentes_ui: todos os componentes do catálogo ao vivo (os mesmos
// estados que a skill `componentes` exporta em SVG), mais telas montadas.
// Rodar: ver example/README.md.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'catalogo/catalogo.dart';
import 'catalogo/catalogo_v09_a.dart';
import 'catalogo/catalogo_v09_b.dart';
import 'catalogo/catalogo_mov_a.dart';
import 'catalogo/catalogo_mov_b.dart';
import 'catalogo/catalogo_v10_controles.dart';
import 'catalogo/catalogo_v10_dados.dart';
import 'catalogo/catalogo_v10_casa.dart';
import 'catalogo/catalogo_v10_estrutura.dart';
import 'catalogo/catalogo_v102.dart';
import 'catalogo/catalogo_v11.dart';
import 'catalogo/catalogo_v12.dart';
import 'catalogo/catalogo_v13.dart';
import 'catalogo/catalogo_v14.dart';
import 'aparencia.dart';
import 'telas/tela_demo.dart';
import 'telas/telas_a.dart';
import 'telas/telas_b.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const ProviderScope(child: Vitrine()));
}

class Vitrine extends StatefulWidget {
  const Vitrine({super.key});

  @override
  State<Vitrine> createState() => _VitrineState();
}

class _VitrineState extends State<Vitrine> {
  final aparencia = Aparencia();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: aparencia,
      builder: (context, _) => MaterialApp(
        title: 'Lista Clara · vitrine',
        debugShowCheckedModeBanner: false,
        theme: aparencia.tema(Brightness.light),
        darkTheme: aparencia.tema(Brightness.dark),
        themeMode: aparencia.modo,
        home: AparenciaScope(aparencia: aparencia, child: const _Inicio()),
      ),
    );
  }
}

class _Inicio extends StatefulWidget {
  const _Inicio();

  @override
  State<_Inicio> createState() => _InicioState();
}

class _InicioState extends State<_Inicio> {
  String _busca = '';

  bool _bate(String texto) =>
      _busca.isEmpty || foldAccents(texto.toLowerCase()).contains(foldAccents(_busca.toLowerCase()));

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final novos = {
      for (final x in [...catalogoV09A, ...catalogoV09B]) x.slug,
    };
    final casa = {
      for (final x in [...catalogoV10Controles, ...catalogoV10Dados, ...catalogoV10Casa, ...catalogoV10Estrutura])
        x.slug,
    };
    final v14 = {for (final x in catalogoV14) x.slug};
    final v14Lista = catalogo.where((x) => v14.contains(x.slug) && _bate('${x.nome} ${x.descricao}')).toList();
    final v13 = {for (final x in catalogoV13) x.slug};
    final v13Lista = catalogo.where((x) => v13.contains(x.slug) && _bate('${x.nome} ${x.descricao}')).toList();
    final v12 = {for (final x in catalogoV12) x.slug};
    final v12Lista = catalogo.where((x) => v12.contains(x.slug) && _bate('${x.nome} ${x.descricao}')).toList();
    final v11 = {for (final x in catalogoV11) x.slug};
    final v11Lista = catalogo.where((x) => v11.contains(x.slug) && _bate('${x.nome} ${x.descricao}')).toList();
    final v102 = {for (final x in catalogoV102) x.slug};
    final v102Lista = catalogo.where((x) => v102.contains(x.slug) && _bate('${x.nome} ${x.descricao}')).toList();
    final casaLista = catalogo.where((x) => casa.contains(x.slug) && _bate('${x.nome} ${x.descricao}')).toList();
    final mov = {
      for (final x in [...catalogoMovA, ...catalogoMovB]) x.slug,
    };
    final movimento = catalogo.where((x) => mov.contains(x.slug) && _bate('${x.nome} ${x.descricao}')).toList();
    final telas = [...telasA, ...telasB].where((t) => _bate('${t.titulo} ${t.descricao}')).toList();
    final v09 = catalogo.where((x) => novos.contains(x.slug) && _bate('${x.nome} ${x.descricao}')).toList();
    final antigos = catalogo
        .where(
          (x) =>
              !novos.contains(x.slug) &&
              !mov.contains(x.slug) &&
              !casa.contains(x.slug) &&
              !v102.contains(x.slug) &&
              !v11.contains(x.slug) &&
              !v12.contains(x.slug) &&
              !v13.contains(x.slug) &&
              !v14.contains(x.slug) &&
              _bate('${x.nome} ${x.descricao}'),
        )
        .toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: [
                    Text(
                      'Lista Clara',
                      style: TextStyle(fontSize: AppType.screenTitle, fontWeight: FontWeight.w800, color: c.ink),
                    ),
                    Text(
                      'componentes_ui v0.14.0 · ${catalogo.length} componentes, ${v09.length} novos, ${movimento.length} de movimento',
                      style: TextStyle(color: c.muted),
                    ),
                    const AparenciaBar(),
                    SsSearchField(hint: 'Buscar componente', onChanged: (v) => setState(() => _busca = v)),
                  ],
                ),
              ),
            ),
            if (telas.isNotEmpty) ...[
              const _Titulo('Telas montadas'),
              SliverList.builder(itemCount: telas.length, itemBuilder: (context, i) => _TelaTile(telas[i])),
            ],
            if (v14Lista.isNotEmpty) ...[
              const _Titulo('Painéis (v0.14)'),
              SliverList.builder(
                itemCount: v14Lista.length,
                itemBuilder: (context, i) => _CompTile(v14Lista[i], novo: true),
              ),
            ],
            if (v13Lista.isNotEmpty) ...[
              const _Titulo('Painéis (v0.13)'),
              SliverList.builder(
                itemCount: v13Lista.length,
                itemBuilder: (context, i) => _CompTile(v13Lista[i], novo: true),
              ),
            ],
            if (v12Lista.isNotEmpty) ...[
              const _Titulo('Cards e casa (v0.12)'),
              SliverList.builder(
                itemCount: v12Lista.length,
                itemBuilder: (context, i) => _CompTile(v12Lista[i], novo: true),
              ),
            ],
            if (v11Lista.isNotEmpty) ...[
              const _Titulo('Densidade (v0.11)'),
              SliverList.builder(
                itemCount: v11Lista.length,
                itemBuilder: (context, i) => _CompTile(v11Lista[i], novo: true),
              ),
            ],
            if (v102Lista.isNotEmpty) ...[
              const _Titulo('Novos na v0.10.2 (tela)'),
              SliverList.builder(
                itemCount: v102Lista.length,
                itemBuilder: (context, i) => _CompTile(v102Lista[i], novo: true),
              ),
            ],
            if (casaLista.isNotEmpty) ...[
              const _Titulo('Casa e automação (v0.10)'),
              SliverList.builder(
                itemCount: casaLista.length,
                itemBuilder: (context, i) => _CompTile(casaLista[i], novo: true),
              ),
            ],
            if (movimento.isNotEmpty) ...[
              const _Titulo('Movimento (toque para ver)'),
              SliverList.builder(
                itemCount: movimento.length,
                itemBuilder: (context, i) => _CompTile(movimento[i], novo: true),
              ),
            ],
            if (v09.isNotEmpty) ...[
              const _Titulo('Novos na v0.9'),
              SliverList.builder(itemCount: v09.length, itemBuilder: (context, i) => _CompTile(v09[i], novo: true)),
            ],
            const _Titulo('Todos os componentes'),
            SliverList.builder(itemCount: antigos.length, itemBuilder: (context, i) => _CompTile(antigos[i])),
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
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
    child: Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 8), child: SsGroupHeader(texto)),
  );
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
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => AparenciaScope.copy(context, Builder(builder: tela.build)))),
    ),
  );
}

class _CompTile extends StatelessWidget {
  const _CompTile(this.comp, {this.novo = false});
  final Componente comp;
  final bool novo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: SsListItem(
      icon: novo ? Icons.auto_awesome_rounded : Icons.widgets_outlined,
      title: comp.nome,
      subtitle: comp.descricao,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => AparenciaScope.copy(context, _ComponentePage(comp)))),
    ),
  );
}

class _ComponentePage extends StatelessWidget {
  const _ComponentePage(this.comp);
  final Componente comp;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(comp.nome), actions: const [AparenciaBar(compacta: true), SizedBox(width: 8)]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        children: [
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
      ),
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
          Text(
            estado.titulo,
            style: TextStyle(fontFamily: 'DM Mono', fontSize: 12, color: c.muted),
          ),
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
                      child: HeroControllerScope.none(
                        child: Navigator(
                          key: ValueKey('${comp.slug}/${estado.slug}/${Theme.of(context).brightness}'),
                          onGenerateRoute: (_) => PageRouteBuilder<void>(
                            pageBuilder: (context, _, _) => Scaffold(body: Builder(builder: estado.build)),
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
