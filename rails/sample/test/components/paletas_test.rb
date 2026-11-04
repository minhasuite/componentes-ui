require "test_helper"

# Paletas: a fonte é paletas/paletas.json (gerar.py escreve o CSS, o Ruby e o Flutter).
# Toda paleta de ComponentesUi::PALETAS precisa ter regra no CSS, senão o seletor
# mostra uma paleta que não muda nada.
class PaletasTest < ActiveSupport::TestCase
  GEM = Pathname(ComponentesUi::Engine.root)
  CSS = GEM.join("app/assets/tailwind/componentes_ui/paletas.css")

  def css
    @css ||= begin
      built = Rails.root.join("app/assets/builds/tailwind/componentes_ui.css")
      [CSS.read, (built.read if built.exist?)].compact.join("\n")
    end
  end

  test "cada slug tem [data-swatch] e, fora a padrão, [data-palette] claro e escuro" do
    assert_operator ComponentesUi::PALETAS.size, :>=, 20
    ComponentesUi::PALETAS.each_key do |slug|
      assert_includes css, %([data-swatch="#{slug}"]), "falta [data-swatch=#{slug}]"
      next if slug == ComponentesUi::PALETA_PADRAO
      assert_includes css, %(:root[data-palette="#{slug}"] {), "falta :root[data-palette=#{slug}]"
      assert_includes css, %(:root[data-theme="dark"][data-palette="#{slug}"]), "falta o escuro de #{slug}"
    end
  end

  test "o CSS não tem paleta fora de PALETAS" do
    slugs = CSS.read.scan(/data-palette="([a-z0-9-]+)"/).flatten.uniq
    assert_equal [], slugs - ComponentesUi::PALETAS.keys
  end

  test "família de toda paleta está na lista, e o seletor usa as mesmas paletas" do
    assert_equal ComponentesUi::PALETAS.keys, ComponentesUi::PALETA_FAMILIA.keys
    assert ComponentesUi::PALETA_FAMILIA.values.all? { ComponentesUi::PALETA_FAMILIAS.include?(_1) }
    assert_equal ComponentesUi::PALETAS.values, Ss::ThemeSwitcherComponent::PALETTES.values.map(&:first)
    assert_equal "none", Ss::ThemeSwitcherComponent::PALETTES.keys.first
  end
end
