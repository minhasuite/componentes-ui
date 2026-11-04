#!/usr/bin/env python3
"""Gera as paletas do Lista Clara nos dois lados a partir de paletas/paletas.json.

    python3 paletas/gerar.py           # confere o contraste e escreve os arquivos
    python3 paletas/gerar.py --check   # só confere (contraste e se os gerados estão em dia)

Escreve:
  flutter/lib/src/paletas.g.dart                        consts SsBrand e mapa (part de app_theme.dart)
  flutter/lib/src/app_theme.dart                        só o trecho entre // <paletas> e // </paletas>
  rails/app/assets/tailwind/componentes_ui/paletas.css  :root[data-palette=…] e [data-swatch=…]
  rails/lib/componentes_ui/paletas.rb                   ComponentesUi::PALETAS (slug → nome)

Regras de acessibilidade (falha se quebrar):
  accentLight e accentHoverLight ≥ 4,5:1 sobre o branco e as páginas claras;
  accentDark ≥ 4,5:1 sobre a página e a superfície escuras (Flutter, Rails e OLED);
  o --grad do Rails (botão primário, texto branco) ≥ 4,5:1 em todas as paradas;
  soft claro é um tom bem claro e soft escuro um tom bem escuro.
Só avisa: accent sobre o próprio soft (selo) abaixo de 4,5 e brandTo sob texto branco abaixo de 3.
"""
import json
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
JSON = RAIZ / "paletas" / "paletas.json"
DART_G = RAIZ / "flutter/lib/src/paletas.g.dart"
DART_TEMA = RAIZ / "flutter/lib/src/app_theme.dart"
CSS = RAIZ / "rails/app/assets/tailwind/componentes_ui/paletas.css"
RUBY = RAIZ / "rails/lib/componentes_ui/paletas.rb"

AVISO = "gerado por paletas/gerar.py a partir de paletas/paletas.json, não edite"

# Fundos (AppColors no Flutter, engine.css e v09_fundacao.css no Rails).
FUNDOS_CLAROS = {"branco": "#ffffff", "página Flutter": "#eef0f6", "página Rails": "#f6f5fb", "campo Flutter": "#f4f5fa"}
FUNDOS_ESCUROS = {
    "página Flutter": "#0f1017", "superfície Flutter": "#171925",
    "página Rails": "#0e0d16", "superfície Rails": "#16142a",
    "OLED": "#000000", "superfície OLED": "#0b0b10", "superfície OLED Rails": "#0a0a0d",
}
CAMPOS = ["stops", "accentLight", "accentHoverLight", "accentSoftLight", "accentDark", "accentSoftDark",
          "brandFrom", "brandTo", "brandDeep"]
HEX = re.compile(r"^#[0-9a-f]{6}$")


# ── cor ────────────────────────────────────────────────────────────────────
def rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


def hexa(c):
    return "#" + "".join(f"{max(0, min(255, round(v))):02x}" for v in c)


def mistura(a, b, t):
    """a com t de b (0 = a, 1 = b), em sRGB como o color-mix(in srgb)."""
    ra, rb = rgb(a), rgb(b)
    return hexa([x + (y - x) * t for x, y in zip(ra, rb)])


def luminancia(h):
    def canal(v):
        v /= 255
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = (canal(v) for v in rgb(h))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contraste(a, b):
    la, lb = luminancia(a), luminancia(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


def rgba(h, a):
    r, g, b = rgb(h)
    return f"rgba({r}, {g}, {b}, {a})"


# ── leitura e conferência ─────────────────────────────────────────────────
def carregar():
    dados = json.loads(JSON.read_text(encoding="utf-8"))
    familias, paletas = dados["familias"], dados["paletas"]
    for p in paletas:
        for k in CAMPOS:
            v = p[k]
            if k == "stops":
                p[k] = [s.lower() for s in v]
            else:
                p[k] = v.lower()
    return familias, paletas


def grad_rails(p):
    """3 paradas do --grad (fundo do botão primário, texto branco): hover → accent → accent
    puxado para o brandFrom até onde o branco ainda passa 4,5:1."""
    l, h = p["accentLight"], p["accentHoverLight"]
    fim = l
    for t in (0.5, 0.4, 0.3, 0.2, 0.1):
        c = mistura(l, p["brandFrom"], t)
        if contraste(c, "#ffffff") >= 4.5:
            fim = c
            break
    return [h, l, fim]


def conferir(familias, paletas):
    erros, avisos = [], []
    vistos = {"slug": set(), "nome": set(), "dartName": set()}
    padroes = [p for p in paletas if p.get("padrao")]
    if len(padroes) != 1 or paletas[0] is not padroes[0]:
        erros.append("precisa de exatamente uma paleta com \"padrao\": true, e ela vem primeiro")
    for p in paletas:
        n = p.get("slug", "?")
        for k in ("slug", "nome", "dartName"):
            if p[k] in vistos[k]:
                erros.append(f"{n}: {k} repetido ({p[k]})")
            vistos[k].add(p[k])
        if not re.match(r"^[a-z0-9]+(-[a-z0-9]+)*$", p["slug"]) or p["slug"] == "none":
            erros.append(f"{n}: slug inválido")
        if "'" in p["nome"] or "\\" in p["nome"]:
            erros.append(f"{n}: nome sem aspas simples nem barra invertida")
        if not re.match(r"^[a-z][A-Za-z0-9]*$", p["dartName"]):
            erros.append(f"{n}: dartName inválido")
        if p.get("familia") not in familias:
            erros.append(f"{n}: família {p.get('familia')!r} fora de \"familias\"")
        if len(p["stops"]) != 4:
            erros.append(f"{n}: stops precisa de 4 cores")
        for k in CAMPOS:
            for v in (p[k] if k == "stops" else [p[k]]):
                if not HEX.match(v):
                    erros.append(f"{n}: {k} {v!r} não é #rrggbb")
    if erros:
        return erros, avisos

    for p in paletas:
        n = p["slug"]
        for campo in ("accentLight", "accentHoverLight"):
            for nome, bg in FUNDOS_CLAROS.items():
                c = contraste(p[campo], bg)
                if c < 4.5:
                    erros.append(f"{n}: {campo} {p[campo]} sobre {nome} {bg} = {c:.2f} (< 4,5)")
        for nome, bg in FUNDOS_ESCUROS.items():
            c = contraste(p["accentDark"], bg)
            if c < 4.5:
                erros.append(f"{n}: accentDark {p['accentDark']} sobre {nome} {bg} = {c:.2f} (< 4,5)")
        for s in grad_rails(p):
            c = contraste(s, "#ffffff")
            if c < 4.5:
                erros.append(f"{n}: parada {s} do --grad com texto branco = {c:.2f} (< 4,5)")
        if luminancia(p["accentSoftLight"]) < 0.75:
            erros.append(f"{n}: accentSoftLight {p['accentSoftLight']} escuro demais para um tom suave")
        if luminancia(p["accentSoftDark"]) > 0.05:
            erros.append(f"{n}: accentSoftDark {p['accentSoftDark']} claro demais para o escuro")
        if (c := contraste(p["accentHoverLight"], p["accentSoftLight"])) < 4.5:
            avisos.append(f"{n}: texto da marca sobre o soft claro = {c:.2f}")
        if (c := contraste(p["accentDark"], p["accentSoftDark"])) < 4.5:
            avisos.append(f"{n}: accentDark sobre o soft escuro = {c:.2f}")
        if (c := contraste(p["brandTo"], "#ffffff")) < 3:
            avisos.append(f"{n}: brandTo {p['brandTo']} com texto branco = {c:.2f} (< 3)")
    return erros, avisos


# ── Flutter ───────────────────────────────────────────────────────────────
def cor(h):
    return f"Color(0xFF{h[1:].upper()})"


def derivados(p):
    return [p["brandDeep"], p["brandTo"], p["brandFrom"], p["accentDark"]]


def dart_g(familias, paletas):
    out = [f"// {AVISO}.", "// Para mudar ou criar paleta: edite o JSON e rode `python3 paletas/gerar.py`.",
           "part of 'app_theme.dart';", ""]
    for p in paletas:
        out.append(f"const _{p['dartName']} = SsBrand(")
        for k in CAMPOS[1:]:
            out.append(f"  {k}: {cor(p[k])},")
        # A padrão deriva as paradas da marca (como a marca de um produto); se o JSON
        # pedir outras, elas entram.
        if not p.get("padrao") or p["stops"] != derivados(p):
            out.append(f"  stops: [{', '.join(cor(s) for s in p['stops'])}],")
        out.append(");")
        out.append("")
    out.append("const _ssPaletasMapa = <String, SsBrand>{")
    for p in paletas:
        out.append(f"  '{p['nome']}': _{p['dartName']},")
    out.append("};")
    out.append("")
    out.append("const _ssPaletasLista = <SsPaleta>[")
    for p in paletas:
        out.append(f"  SsPaleta(slug: '{p['slug']}', nome: '{p['nome']}', familia: '{p['familia']}', brand: _{p['dartName']}),")
    out.append("];")
    out.append("")
    out.append("const _ssFamilias = <String>[" + ", ".join(f"'{f}'" for f in familias) + "];")
    out.append("")
    return "\n".join(out)


def dart_trecho(paletas):
    out = [f"  // <paletas> {AVISO}."]
    for p in paletas:
        out.append(f"  /// {p['descricao']}")
        out.append(f"  static const {p['dartName']} = _{p['dartName']};")
        out.append("")
    out.append(f"  /// Paletas prontas por nome em pt-BR ({len(paletas)}, a violeta primeiro, agrupadas por família):")
    out.append("  /// seletor de aparência e vitrine. Com slug e família: [SsPaleta.todas].")
    out.append("  static const paletas = _ssPaletasMapa;")
    out.append("  // </paletas>")
    return "\n".join(out)


def dart_tema(atual, paletas):
    padrao = re.compile(r"  // <paletas>.*?// </paletas>", re.S)
    if not padrao.search(atual):
        raise SystemExit("app_theme.dart: não achei os marcadores // <paletas> … // </paletas> no SsBrand")
    return padrao.sub(lambda _: dart_trecho(paletas), atual, count=1)


# ── Rails ─────────────────────────────────────────────────────────────────
def css(familias, paletas):
    padrao = paletas[0]
    s = lambda p: p["stops"]
    g4 = lambda p: f"linear-gradient(120deg, {s(p)[0]} 0%, {s(p)[1]} 35%, {s(p)[2]} 70%, {s(p)[3]} 100%)"
    out = [f"/* {AVISO}.",
           "   Para mudar ou criar paleta: edite o JSON e rode `python3 paletas/gerar.py` (gera também o Flutter",
           "   e o ComponentesUi::PALETAS). Importado por v09_fundacao.css.",
           "   Cada paleta: claro em :root[data-palette=x]; escuro em [data-theme=dark] e na preferência do",
           "   sistema. Accent claro ≥ 4,5:1 sobre branco e página; accent escuro ≥ 4,5:1 sobre a página",
           "   escura; --grad (botão primário) ≥ 4,5:1 com texto branco. Os 4 tons crus ficam em --p1…--p4",
           "   (usados pelo .ss-swatch e pelo seletor de paleta). Sem data-palette vale a padrão (engine.css). */",
           "",
           f"/* {padrao['nome']} (padrão): só ganha o gradiente de 4 paradas. */",
           f":root {{ --grad-4: {g4(padrao)}; }}",
           ""]
    for p in paletas:
        sel = f'[data-swatch="{p["slug"]}"]' + ("" if p.get("padrao") else f', :root[data-palette="{p["slug"]}"]')
        out.append(f"{sel} {{ --p1: {s(p)[0]}; --p2: {s(p)[1]}; --p3: {s(p)[2]}; --p4: {s(p)[3]}; }}")
    out.append("")
    outras = [p for p in paletas if not p.get("padrao")]
    for p in outras:
        g = grad_rails(p)
        out += [f':root[data-palette="{p["slug"]}"] {{',
                f"  --accent: {p['accentLight']}; --accent-hover: {p['accentHoverLight']}; --accent-soft: {p['accentSoftLight']};",
                f"  --grad: linear-gradient(135deg, {g[0]} 0%, {g[1]} 55%, {g[2]} 100%);",
                f"  --grad-soft: linear-gradient(135deg, {rgba(p['brandTo'], '.10')}, {rgba(s(p)[2], '.10')});",
                f"  --grad-4: {g4(p)};",
                f"  --glow: {rgba(p['brandFrom'], '.10')};",
                f"  --shadow-hover: 0 2px 4px rgba(30, 26, 56, .05), 0 18px 40px -16px {rgba(p['brandTo'], '.32')};",
                "}"]

    def escuro(p):
        g = grad_rails(p)
        return (f"--accent: {p['accentDark']}; --accent-hover: {mistura(p['accentDark'], '#ffffff', .2)}; "
                f"--accent-soft: {p['accentSoftDark']}; --glow: {rgba(p['brandFrom'], '.16')};\n"
                f"    --grad: linear-gradient(135deg, {g[0]} 0%, {g[1]} 55%, {g[2]} 100%); "
                f"--shadow-hover: 0 0 0 1px {rgba(p['accentDark'], '.26')}, 0 20px 44px -18px {rgba(p['brandTo'], '.5')};")

    out += ["", "/* Escuro das paletas: tema explícito… */"]
    for p in outras:
        out.append(f':root[data-theme="dark"][data-palette="{p["slug"]}"] {{ {escuro(p)} }}')
    out += ["", "/* …e preferência do sistema (mesmos valores). */", "@media (prefers-color-scheme: dark) {"]
    for p in outras:
        out.append(f'  :root:not([data-theme="light"])[data-palette="{p["slug"]}"] {{ {escuro(p)} }}')
    out.append("}")
    out.append("")
    return "\n".join(out)


def ruby(familias, paletas):
    q = lambda v: json.dumps(v, ensure_ascii=False)
    out = [f"# {AVISO}.", "# Para mudar ou criar paleta: edite o JSON e rode `python3 paletas/gerar.py`.",
           "module ComponentesUi", "  # slug → nome (pt-BR), na ordem do seletor (agrupada por família).",
           "  # O slug é o valor de data-palette no <html>; a padrão não tem data-palette.",
           "  PALETAS = {"]
    for p in paletas:
        out.append(f"    {q(p['slug'])} => {q(p['nome'])},")
    out += ["  }.freeze", "", f"  PALETA_PADRAO = {q(paletas[0]['slug'])}", "",
            "  # slug → família.", "  PALETA_FAMILIA = {"]
    for p in paletas:
        out.append(f"    {q(p['slug'])} => {q(p['familia'])},")
    out += ["  }.freeze", "", "  PALETA_FAMILIAS = [" + ", ".join(q(f) for f in familias) + "].freeze", "end", ""]
    return "\n".join(out)


# ── main ──────────────────────────────────────────────────────────────────
def main():
    so_conferir = "--check" in sys.argv
    familias, paletas = carregar()
    erros, avisos = conferir(familias, paletas)
    for a in avisos:
        print(f"aviso: {a}")
    if erros:
        for e in erros:
            print(f"ERRO: {e}", file=sys.stderr)
        sys.exit(1)

    alvos = {
        DART_G: dart_g(familias, paletas),
        DART_TEMA: dart_tema(DART_TEMA.read_text(encoding="utf-8"), paletas),
        CSS: css(familias, paletas),
        RUBY: ruby(familias, paletas),
    }
    velhos = [a for a, conteudo in alvos.items() if not a.exists() or a.read_text(encoding="utf-8") != conteudo]
    if so_conferir:
        if velhos:
            print("desatualizados (rode python3 paletas/gerar.py): " + ", ".join(str(a.relative_to(RAIZ)) for a in velhos),
                  file=sys.stderr)
            sys.exit(1)
        print(f"ok: {len(paletas)} paletas, contraste e gerados em dia")
        return
    for a in velhos:
        a.write_text(alvos[a], encoding="utf-8")
        print(f"escrito {a.relative_to(RAIZ)}")
    print(f"ok: {len(paletas)} paletas ({len(velhos)} arquivo(s) mudaram)")


if __name__ == "__main__":
    main()
