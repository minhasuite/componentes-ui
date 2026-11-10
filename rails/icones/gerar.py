#!/usr/bin/env python3
"""Gera o conjunto de ícones da gem e a lista de nomes do pacote Flutter (v0.15).

Fonte: rails/icones/outline/*.svg (Heroicons v1 outline, MIT, + 9 de casa no mesmo traço),
rails/icones/solid/*.svg (alguns cheios) e rails/icones/aliases.json (nomes da v2 → v1).
Saída: rails/lib/componentes_ui/icons.rb e flutter/lib/src/v15/icon_names.g.dart.
Roda no host (só biblioteca padrão): python3 rails/icones/gerar.py [--check]
"""
import json
import re
import sys
from pathlib import Path

AQUI = Path(__file__).resolve().parent
RAIZ = AQUI.parent.parent
RB = RAIZ / "rails/lib/componentes_ui/icons.rb"
DART = RAIZ / "flutter/lib/src/v15/icon_names.g.dart"


def miolo(arq: Path) -> str:
    s = arq.read_text()
    m = re.search(r"<svg[^>]*>(.*)</svg>", s, re.S)
    if not m:
        sys.exit(f"sem <svg>: {arq}")
    corpo = re.sub(r"\s+", " ", m.group(1)).strip().replace("> <", "><")
    if "'" in corpo or "#{" in corpo:
        sys.exit(f"caractere proibido em {arq}")
    return corpo


def carrega(pasta: str) -> dict:
    return {a.stem: miolo(a) for a in sorted((AQUI / pasta).glob("*.svg"))}


def main() -> None:
    check = "--check" in sys.argv
    outline, solid = carrega("outline"), carrega("solid")
    aliases = {k: v for k, v in json.loads((AQUI / "aliases.json").read_text()).items() if k != "_" and k != v}
    for k, v in aliases.items():
        if v not in outline:
            sys.exit(f"alias {k} → {v}: {v} não existe")
        if k in outline:
            sys.exit(f"alias {k} esconde um ícone do conjunto")
    falta = [n for n in solid if n not in outline]
    if falta:
        sys.exit(f"cheio sem contorno: {falta}")

    def hash_rb(d: dict) -> str:
        return "\n".join(f"      '{k}' => '{v}'," for k, v in d.items())

    rb = f"""# Gerado por rails/icones/gerar.py (não edite à mão). Heroicons v1 (MIT, Refactoring UI Inc.,
# rails/icones/LICENSE-heroicons) + ícones de casa no mesmo traço. Uso: ss_icon / Ss::IconComponent.
module ComponentesUi
  module Icons
    # Contorno: viewBox 0 0 24 24, stroke=currentColor.
    OUTLINE = {{
{hash_rb(outline)}
    }}.freeze

    # Cheio: viewBox 0 0 20 20, fill=currentColor.
    SOLID = {{
{hash_rb(solid)}
    }}.freeze

    # Nome da v2 (ou de uso) → nome do conjunto.
    ALIASES = {{
{hash_rb(aliases)}
    }}.freeze
  end
end
"""
    nomes = ",\n".join(f"  '{n}'" for n in outline)
    alias_dart = ",\n".join(f"  '{k}': '{v}'" for k, v in aliases.items())
    cheios = ",\n".join(f"  '{n}'" for n in solid)
    dart = f"""// Gerado por rails/icones/gerar.py (não edite à mão): os mesmos nomes do ss_icon da gem.
part of 'icons.dart';

const _ssIconNames = <String>[
{nomes},
];

const _ssIconSolid = <String>{{
{cheios},
}};

const _ssIconAliases = <String, String>{{
{alias_dart},
}};
"""
    if check:
        ruins = [str(p) for p, t in ((RB, rb), (DART, dart)) if not p.exists() or p.read_text() != t]
        if ruins:
            sys.exit("atrasado: " + ", ".join(ruins) + " (rode python3 rails/icones/gerar.py)")
        print(f"ok: {len(outline)} ícones, {len(solid)} cheios, {len(aliases)} apelidos")
        return
    RB.write_text(rb)
    DART.write_text(dart)
    print(f"{len(outline)} ícones, {len(solid)} cheios, {len(aliases)} apelidos → {RB.relative_to(RAIZ)}, {DART.relative_to(RAIZ)}")


if __name__ == "__main__":
    main()
