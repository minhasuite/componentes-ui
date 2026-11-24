// Toda peça do catálogo tem categoria na vitrine (example/lib/categorias.dart).
// Falhou aqui: a peça nova não bate com o mapa nem com nenhuma palavra; ponha o
// slug no mapa `_porSlug` da categoria de uso dela.
import 'package:flutter_test/flutter_test.dart';

// O mapa mora no app da vitrine (example/lib); o teste fica aqui, junto do catálogo que ele confere.
// ignore: avoid_relative_lib_imports
import '../example/lib/categorias.dart';
import 'catalogo.dart';

void main() {
  test('toda peça do catálogo cai numa categoria de uso', () {
    final sem = [
      for (final c in catalogo)
        if (categoriaDe(c.slug, c.nome) == null) '${c.slug} (${c.nome})',
    ];
    expect(sem, isEmpty, reason: 'Sem categoria na vitrine: ponha em example/lib/categorias.dart');
  });

  test('nenhuma peça vai para Novidades direto e toda categoria de uso tem peça', () {
    final usadas = {for (final c in catalogo) categoriaDe(c.slug, c.nome)};
    expect(usadas.contains(novidades), isFalse);
    for (final cat in categorias.where((c) => c != novidades)) {
      expect(usadas.contains(cat), isTrue, reason: '${cat.nome} ficou vazia');
    }
  });

  test('ids únicos e Novidades com peças da onda atual', () {
    expect(categorias.map((c) => c.id).toSet().length, categorias.length);
    expect(catalogo.where((c) => ehNovidade(c.nome, c.descricao)), isNotEmpty);
  });
}
