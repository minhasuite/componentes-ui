// v1.12.0: gerador de QR Code pequeno e puro-Dart (sem pacote), para o Pix copia e cola e o QR da consulta da
// NF-e. Modo byte (UTF-8), versões 1 a 40, correção L/M/Q/H (padrão M, a do Pix) e a máscara de menor
// penalidade (ISO/IEC 18004, a mesma conta do gerador de Nayuki). Dá a mesma matriz que o ComponentesUi::Qr da
// gem para o mesmo texto (o teste confere).
import 'dart:convert';

import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';

/// Nível de correção de erro do QR.
enum SsQrEcc {
  low(1, 0),
  medium(0, 1),
  quartile(3, 2),
  high(2, 3);

  const SsQrEcc(this.formatBits, this.row);
  final int formatBits;

  /// A linha das tabelas de blocos.
  final int row;
}

/// A matriz de um QR Code: `SsQrCode.encode('000201…')`, [size] × [size], [dark] por linha e coluna.
class SsQrCode {
  SsQrCode._(this.version, this.size, this._modules);

  /// Versão (1 a 40).
  final int version;

  /// Módulos por lado (17 + 4 × versão).
  final int size;
  final List<List<bool>> _modules;

  /// O módulo da linha [y] e coluna [x] é escuro?
  bool dark(int x, int y) => _modules[y][x];

  /// As linhas (true = escuro), para teste e exportar.
  List<List<bool>> get rows => [for (final r in _modules) List.unmodifiable(r)];

  static const _eccPerBlock = [
    [
      -1,
      7,
      10,
      15,
      20,
      26,
      18,
      20,
      24,
      30,
      18,
      20,
      24,
      26,
      30,
      22,
      24,
      28,
      30,
      28,
      28,
      28,
      28,
      30,
      30,
      26,
      28,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
    ], //
    [
      -1,
      10,
      16,
      26,
      18,
      24,
      16,
      18,
      22,
      22,
      26,
      30,
      22,
      22,
      24,
      24,
      28,
      28,
      26,
      26,
      26,
      26,
      28,
      28,
      28,
      28,
      28,
      28,
      28,
      28,
      28,
      28,
      28,
      28,
      28,
      28,
      28,
      28,
      28,
      28,
      28,
    ],
    [
      -1,
      13,
      22,
      18,
      26,
      18,
      24,
      18,
      22,
      20,
      24,
      28,
      26,
      24,
      20,
      30,
      24,
      28,
      28,
      26,
      30,
      28,
      30,
      30,
      30,
      30,
      28,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
    ],
    [
      -1,
      17,
      28,
      22,
      16,
      22,
      28,
      26,
      26,
      24,
      28,
      24,
      28,
      22,
      24,
      24,
      30,
      28,
      28,
      26,
      28,
      30,
      24,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
    ],
  ];
  static const _numBlocks = [
    [
      -1,
      1,
      1,
      1,
      1,
      1,
      2,
      2,
      2,
      2,
      4,
      4,
      4,
      4,
      4,
      6,
      6,
      6,
      6,
      7,
      8,
      8,
      9,
      9,
      10,
      12,
      12,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      19,
      20,
      21,
      22,
      24,
      25,
    ], //
    [
      -1,
      1,
      1,
      1,
      2,
      2,
      4,
      4,
      4,
      5,
      5,
      5,
      8,
      9,
      9,
      10,
      10,
      11,
      13,
      14,
      16,
      17,
      17,
      18,
      20,
      21,
      23,
      25,
      26,
      28,
      29,
      31,
      33,
      35,
      37,
      38,
      40,
      43,
      45,
      47,
      49,
    ],
    [
      -1,
      1,
      1,
      2,
      2,
      4,
      4,
      6,
      6,
      8,
      8,
      8,
      10,
      12,
      16,
      12,
      17,
      16,
      18,
      21,
      20,
      23,
      23,
      25,
      27,
      29,
      34,
      34,
      35,
      38,
      40,
      43,
      45,
      48,
      51,
      53,
      56,
      59,
      62,
      65,
      68,
    ],
    [
      -1,
      1,
      1,
      2,
      4,
      4,
      4,
      5,
      6,
      8,
      8,
      11,
      11,
      16,
      16,
      18,
      16,
      19,
      21,
      25,
      25,
      25,
      34,
      30,
      32,
      35,
      37,
      40,
      42,
      45,
      48,
      51,
      54,
      57,
      60,
      63,
      66,
      70,
      74,
      77,
      81,
    ],
  ];

  /// O QR de [text] (UTF-8). Lança [ArgumentError] se não couber nem na versão 40.
  static SsQrCode encode(String text, {SsQrEcc ecc = SsQrEcc.medium}) => _Encoder(utf8.encode(text), ecc).build();

  static int _rawModules(int v) {
    var r = (16 * v + 128) * v + 64;
    if (v >= 2) {
      final na = v ~/ 7 + 2;
      r -= (25 * na - 10) * na - 55;
      if (v >= 7) r -= 36;
    }
    return r;
  }

  static int _dataCodewords(int v, SsQrEcc e) => _rawModules(v) ~/ 8 - _eccPerBlock[e.row][v] * _numBlocks[e.row][v];
}

class _Encoder {
  _Encoder(this.bytes, this.ecc);
  final List<int> bytes;
  final SsQrEcc ecc;
  late int version;
  late int size;
  late List<List<bool>> m;
  late List<List<bool>> fn;

  SsQrCode build() {
    final v = [for (var v = 1; v <= 40; v++) v]
        .where((v) => bytes.length * 8 + 4 + (v < 10 ? 8 : 16) <= SsQrCode._dataCodewords(v, ecc) * 8);
    if (v.isEmpty) throw ArgumentError('texto longo demais para um QR (${bytes.length} bytes)');
    version = v.first;
    size = version * 4 + 17;
    m = List.generate(size, (_) => List.filled(size, false));
    fn = List.generate(size, (_) => List.filled(size, false));
    _functionPatterns();
    _codewords(_addEcc(_dataBits()));
    var best = 0, bestP = 1 << 30;
    for (var mask = 0; mask < 8; mask++) {
      _applyMask(mask);
      _format(mask);
      final p = _penalty();
      if (p < bestP) {
        best = mask;
        bestP = p;
      }
      _applyMask(mask);
    }
    _applyMask(best);
    _format(best);
    return SsQrCode._(version, size, m);
  }

  List<int> _dataBits() {
    final bits = <int>[];
    void push(int val, int n) {
      for (var i = n - 1; i >= 0; i--) {
        bits.add((val >> i) & 1);
      }
    }

    push(4, 4);
    push(bytes.length, version < 10 ? 8 : 16);
    for (final b in bytes) {
      push(b, 8);
    }
    final cap = SsQrCode._dataCodewords(version, ecc) * 8;
    push(0, cap - bits.length < 4 ? cap - bits.length : 4);
    push(0, (8 - bits.length % 8) % 8);
    for (var i = 0; bits.length < cap; i++) {
      push(i.isEven ? 0xEC : 0x11, 8);
    }
    return [for (var i = 0; i < bits.length; i += 8) bits.sublist(i, i + 8).fold<int>(0, (a, b) => (a << 1) | b)];
  }

  static int _mul(int x, int y) {
    var z = 0;
    for (var i = 7; i >= 0; i--) {
      z = (z << 1) ^ ((z >> 7) * 0x11D);
      z ^= ((y >> i) & 1) * x;
    }
    return z & 0xFF;
  }

  static List<int> _divisor(int degree) {
    final r = [...List.filled(degree - 1, 0), 1];
    var root = 1;
    for (var k = 0; k < degree; k++) {
      for (var j = 0; j < r.length; j++) {
        r[j] = _mul(r[j], root);
        if (j + 1 < r.length) r[j] ^= r[j + 1];
      }
      root = _mul(root, 0x02);
    }
    return r;
  }

  static List<int> _remainder(List<int> data, List<int> div) {
    final r = List.filled(div.length, 0, growable: true);
    for (final b in data) {
      final f = b ^ r.removeAt(0);
      r.add(0);
      for (var i = 0; i < div.length; i++) {
        r[i] ^= _mul(div[i], f);
      }
    }
    return r;
  }

  List<int> _addEcc(List<int> data) {
    final nb = SsQrCode._numBlocks[ecc.row][version];
    final eccLen = SsQrCode._eccPerBlock[ecc.row][version];
    final raw = SsQrCode._rawModules(version) ~/ 8;
    final short = nb - raw % nb;
    final shortLen = raw ~/ nb;
    final div = _divisor(eccLen);
    var k = 0;
    final blocks = <List<int>>[];
    for (var i = 0; i < nb; i++) {
      final len = shortLen - eccLen + (i < short ? 0 : 1);
      final dat = data.sublist(k, k + len);
      k += len;
      final e = _remainder(dat, div);
      blocks.add([...dat, if (i < short) 0, ...e]);
    }
    final out = <int>[];
    for (var i = 0; i < blocks[0].length; i++) {
      for (var j = 0; j < blocks.length; j++) {
        if (i != shortLen - eccLen || j >= short) out.add(blocks[j][i]);
      }
    }
    return out;
  }

  void _set(int x, int y, bool dark) {
    m[y][x] = dark;
    fn[y][x] = true;
  }

  List<int> _alignPositions() {
    if (version == 1) return const [];
    final na = version ~/ 7 + 2;
    final step = (version * 8 + na * 3 + 5) ~/ (na * 4 - 4) * 2;
    final r = [6];
    var pos = size - 7;
    for (var i = 0; i < na - 1; i++) {
      r.insert(1, pos);
      pos -= step;
    }
    return r;
  }

  void _functionPatterns() {
    for (var i = 0; i < size; i++) {
      _set(6, i, i.isEven);
      _set(i, 6, i.isEven);
    }
    for (final (x, y) in [(3, 3), (size - 4, 3), (3, size - 4)]) {
      for (var dy = -4; dy <= 4; dy++) {
        for (var dx = -4; dx <= 4; dx++) {
          final xx = x + dx, yy = y + dy;
          if (xx < 0 || yy < 0 || xx >= size || yy >= size) continue;
          final dist = dx.abs() > dy.abs() ? dx.abs() : dy.abs();
          _set(xx, yy, dist != 2 && dist != 4);
        }
      }
    }
    final pos = _alignPositions();
    final n = pos.length;
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < n; j++) {
        if ((i == 0 && j == 0) || (i == 0 && j == n - 1) || (i == n - 1 && j == 0)) continue;
        for (var dy = -2; dy <= 2; dy++) {
          for (var dx = -2; dx <= 2; dx++) {
            _set(pos[i] + dx, pos[j] + dy, (dx.abs() > dy.abs() ? dx.abs() : dy.abs()) != 1);
          }
        }
      }
    }
    _format(0);
    _version();
  }

  static bool _bit(int v, int i) => ((v >> i) & 1) != 0;

  void _format(int mask) {
    final data = (ecc.formatBits << 3) | mask;
    var rem = data;
    for (var i = 0; i < 10; i++) {
      rem = (rem << 1) ^ ((rem >> 9) * 0x537);
    }
    final bits = ((data << 10) | rem) ^ 0x5412;
    for (var i = 0; i <= 5; i++) {
      _set(8, i, _bit(bits, i));
    }
    _set(8, 7, _bit(bits, 6));
    _set(8, 8, _bit(bits, 7));
    _set(7, 8, _bit(bits, 8));
    for (var i = 9; i < 15; i++) {
      _set(14 - i, 8, _bit(bits, i));
    }
    for (var i = 0; i < 8; i++) {
      _set(size - 1 - i, 8, _bit(bits, i));
    }
    for (var i = 8; i < 15; i++) {
      _set(8, size - 15 + i, _bit(bits, i));
    }
    _set(8, size - 8, true);
  }

  void _version() {
    if (version < 7) return;
    var rem = version;
    for (var i = 0; i < 12; i++) {
      rem = (rem << 1) ^ ((rem >> 11) * 0x1F25);
    }
    final bits = (version << 12) | rem;
    for (var i = 0; i < 18; i++) {
      final b = _bit(bits, i);
      final a = size - 11 + i % 3, c = i ~/ 3;
      _set(a, c, b);
      _set(c, a, b);
    }
  }

  void _codewords(List<int> data) {
    var i = 0;
    for (var right = size - 1; right >= 1; right -= 2) {
      if (right == 6) right = 5;
      for (var vert = 0; vert < size; vert++) {
        for (var j = 0; j < 2; j++) {
          final x = right - j;
          final up = ((right + 1) & 2) == 0;
          final y = up ? size - 1 - vert : vert;
          if (fn[y][x] || i >= data.length * 8) continue;
          m[y][x] = _bit(data[i >> 3], 7 - (i & 7));
          i++;
        }
      }
    }
  }

  void _applyMask(int mask) {
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final inv = switch (mask) {
          0 => (x + y) % 2 == 0,
          1 => y % 2 == 0,
          2 => x % 3 == 0,
          3 => (x + y) % 3 == 0,
          4 => (x ~/ 3 + y ~/ 2) % 2 == 0,
          5 => x * y % 2 + x * y % 3 == 0,
          6 => (x * y % 2 + x * y % 3) % 2 == 0,
          _ => ((x + y) % 2 + x * y % 3) % 2 == 0,
        };
        if (inv && !fn[y][x]) m[y][x] = !m[y][x];
      }
    }
  }

  void _addHistory(int run, List<int> h) {
    if (h[0] == 0) run += size;
    h.removeLast();
    h.insert(0, run);
  }

  int _count(List<int> h) {
    final n = h[1];
    final core = n > 0 && h[2] == n && h[3] == n * 3 && h[4] == n && h[5] == n;
    return (core && h[0] >= n * 4 && h[6] >= n ? 1 : 0) + (core && h[6] >= n * 4 && h[0] >= n ? 1 : 0);
  }

  int _terminate(bool color, int run, List<int> h) {
    if (color) {
      _addHistory(run, h);
      run = 0;
    }
    _addHistory(run + size, h);
    return _count(h);
  }

  int _linePenalty(bool Function(int a, int b) get) {
    var r = 0;
    for (var a = 0; a < size; a++) {
      var color = false;
      var run = 0;
      final h = List.filled(7, 0, growable: true);
      for (var b = 0; b < size; b++) {
        if (get(a, b) == color) {
          run++;
          if (run == 5) {
            r += 3;
          } else if (run > 5) {
            r++;
          }
        } else {
          _addHistory(run, h);
          if (!color) r += _count(h) * 40;
          color = get(a, b);
          run = 1;
        }
      }
      r += _terminate(color, run, h) * 40;
    }
    return r;
  }

  int _penalty() {
    var r = _linePenalty((y, x) => m[y][x]) + _linePenalty((x, y) => m[y][x]);
    for (var y = 0; y < size - 1; y++) {
      for (var x = 0; x < size - 1; x++) {
        final c = m[y][x];
        if (c == m[y][x + 1] && c == m[y + 1][x] && c == m[y + 1][x + 1]) r += 3;
      }
    }
    var dark = 0;
    for (final row in m) {
      for (final v in row) {
        if (v) dark++;
      }
    }
    final total = size * size;
    final k = ((dark * 20 - total * 10).abs() + total - 1) ~/ total - 1;
    return r + k * 10;
  }
}

/// O QR desenhado: módulos na tinta [color] (padrão: a tinta escura do tema claro, `AppColors.inkLight`), fundo [background] (padrão: o papel
/// claro, `AppColors.onDark`: o QR precisa de fundo claro para o leitor, também no tema escuro) e a zona de
/// silêncio de [margin] módulos. Quadrado, do tamanho que o pai der (ou [size]).
class SsQrImage extends StatelessWidget {
  SsQrImage({
    super.key,
    required this.data,
    this.size,
    this.color,
    this.background,
    this.margin = 2,
    this.semanticLabel,
  }) : code = SsQrCode.encode(data);

  /// O texto do QR (Pix copia e cola, URL da consulta).
  final String data;
  final SsQrCode code;
  final double? size;
  final Color? color;
  final Color? background;
  final int margin;

  /// Nome do QR no leitor de tela (sem ele, o QR fica fora da semântica: quem usa diz o que é).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final paint = CustomPaint(
      painter: _QrPainter(code, color ?? AppColors.inkLight, background ?? AppColors.onDark, margin),
      child: const SizedBox.expand(),
    );
    final box = AspectRatio(aspectRatio: 1, child: paint);
    final sized = size == null ? box : SizedBox.square(dimension: size, child: paint);
    return semanticLabel == null
        ? ExcludeSemantics(child: sized)
        : Semantics(
            image: true,
            label: semanticLabel,
            child: ExcludeSemantics(child: sized),
          );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.code, this.color, this.background, this.margin);
  final SsQrCode code;
  final Color color;
  final Color background;
  final int margin;

  @override
  void paint(Canvas canvas, Size s) {
    final n = code.size + margin * 2;
    final cell = s.shortestSide / n;
    canvas.drawRect(Offset.zero & s, Paint()..color = background);
    final p = Paint()
      ..color = color
      ..isAntiAlias = false;
    final path = Path();
    for (var y = 0; y < code.size; y++) {
      for (var x = 0; x < code.size; x++) {
        if (code.dark(x, y)) {
          path.addRect(Rect.fromLTWH((x + margin) * cell, (y + margin) * cell, cell + .01, cell + .01));
        }
      }
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_QrPainter old) => old.code != code || old.color != color || old.background != background;
}
