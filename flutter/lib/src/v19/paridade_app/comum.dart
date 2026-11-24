// v1.9 · paridade_app: o que as peças desta área dividem.

/// Onde o componente guarda o "já vi" (tour, novidades): o app injeta o dele
/// (SharedPreferences, secure storage, Drift). Faz o papel do `localStorage`
/// no web e usa as mesmas chaves (`ss-tour:<id>`, `ss-whats-new:<id>`).
///
/// `class PrefsSeenStore extends SsSeenStore { … read/write no SharedPreferences … }`
abstract class SsSeenStore {
  const SsSeenStore();

  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// [SsSeenStore] em memória: testes, vitrine e quando o app não quer lembrar
/// entre aberturas (vale só enquanto o app está aberto).
class SsMemorySeenStore extends SsSeenStore {
  SsMemorySeenStore([Map<String, String>? initial]) : _m = {...?initial};

  final Map<String, String> _m;

  /// O que está guardado (para conferir em teste).
  Map<String, String> get values => Map.unmodifiable(_m);

  @override
  Future<String?> read(String key) async => _m[key];

  @override
  Future<void> write(String key, String value) async => _m[key] = value;
}

/// Troca `{nome}` pelo valor (os textos do [SsStrings] desta área).
String ssFill(String template, Map<String, Object?> values) =>
    template.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) => '${values[m[1]] ?? m[0]}');
