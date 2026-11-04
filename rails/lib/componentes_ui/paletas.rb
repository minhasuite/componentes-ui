# gerado por paletas/gerar.py a partir de paletas/paletas.json, não edite.
# Para mudar ou criar paleta: edite o JSON e rode `python3 paletas/gerar.py`.
module ComponentesUi
  # slug → nome (pt-BR), na ordem do seletor (agrupada por família).
  # O slug é o valor de data-palette no <html>; a padrão não tem data-palette.
  PALETAS = {
    "violeta" => "Violeta",
    "tokyo-night" => "Noite de Tóquio",
    "safira" => "Safira",
    "meia-noite" => "Meia-noite",
    "vinho" => "Vinho",
    "ameixa" => "Ameixa",
    "ardosia" => "Ardósia",
    "neon-pop" => "Neon pop",
    "cereja" => "Cereja",
    "coral" => "Coral",
    "laranja" => "Laranja",
    "turquesa" => "Turquesa",
    "marple" => "Marple",
    "terracota" => "Terracota",
    "por-do-sol" => "Pôr do sol",
    "ambar" => "Âmbar",
    "cafe" => "Café",
    "violet-dusk" => "Crepúsculo",
    "lavanda" => "Lavanda",
    "pessego" => "Pêssego",
    "algodao-doce" => "Algodão-doce",
    "oceano" => "Oceano",
    "artico" => "Ártico",
    "menta" => "Menta",
    "eucalipto" => "Eucalipto",
    "floresta" => "Floresta",
    "oliva" => "Oliva",
    "salvia" => "Sálvia",
  }.freeze

  PALETA_PADRAO = "violeta"

  # slug → família.
  PALETA_FAMILIA = {
    "violeta" => "Profundas",
    "tokyo-night" => "Profundas",
    "safira" => "Profundas",
    "meia-noite" => "Profundas",
    "vinho" => "Profundas",
    "ameixa" => "Profundas",
    "ardosia" => "Profundas",
    "neon-pop" => "Vivas",
    "cereja" => "Vivas",
    "coral" => "Vivas",
    "laranja" => "Vivas",
    "turquesa" => "Vivas",
    "marple" => "Quentes",
    "terracota" => "Quentes",
    "por-do-sol" => "Quentes",
    "ambar" => "Quentes",
    "cafe" => "Quentes",
    "violet-dusk" => "Pastel",
    "lavanda" => "Pastel",
    "pessego" => "Pastel",
    "algodao-doce" => "Pastel",
    "oceano" => "Frias",
    "artico" => "Frias",
    "menta" => "Frias",
    "eucalipto" => "Natureza",
    "floresta" => "Natureza",
    "oliva" => "Natureza",
    "salvia" => "Natureza",
  }.freeze

  PALETA_FAMILIAS = ["Profundas", "Vivas", "Quentes", "Pastel", "Frias", "Natureza"].freeze
end
