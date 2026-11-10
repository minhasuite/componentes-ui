# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "componentes_ui/conformidade"

# O verificador que os produtos chamam no teste "100% componentes_ui".
class ConformidadeTest < ActiveSupport::TestCase
  def produto(gemfile:, arquivos:)
    dir = Dir.mktmpdir("conformidade")
    File.write(File.join(dir, "Gemfile"), gemfile)
    arquivos.each do |nome, texto|
      caminho = File.join(dir, nome)
      FileUtils.mkdir_p(File.dirname(caminho))
      File.write(caminho, texto)
    end
    dir
  end

  GEM_OK = %(gem "componentes_ui", git: "https://github.com/minhasuite/componentes-ui.git", glob: "rails/*.gemspec", tag: "v0.19.0"\n)

  test "produto limpo passa" do
    dir = produto(gemfile: GEM_OK, arquivos: {
      "app/views/web/x.html.erb" => <<~ERB,
        <%# Comentário pode citar text-white (cor em comentário não conta; tag crua conta até em comentário). %>
        <%= ss_form_with model: @x do |f| %><%= f.ss_text_field :nome %><%= f.hidden_field :id %><% end %>
        <%= render Ss::ButtonComponent.new(label: "Salvar") %>
        <div class="ss-card text-on-accent grid gap-4"></div>
      ERB
      "app/assets/tailwind/application.css" => %(@import "tailwindcss";\n@import "../builds/tailwind/componentes_ui";\n),
      "app/javascript/controllers/x_controller.js" => %(this.element.classList.add("is-open")\n)
    })
    assert_empty ComponentesUi::Conformidade.verificar(dir)
  end

  test "reprova cada regra" do
    dir = produto(
      gemfile: %(gem "componentes_ui", path: "../componentes-ui/rails"\ngem "minha_suite_ui"\n),
      arquivos: {
        "app/views/web/x.html.erb" => <<~ERB,
          <div class="btn btn-primary text-white" style="color: #ff0000"></div>
          <button type="button">Ok</button>
          <%= button_to "Apagar", "/x" %>
          <%= form_with url: "/x" do |f| %><%= f.text_field :nome %><% end %>
          <%= render Ui::BadgeComponent.new(type: :x) %>
          <td class="md:opacity-0 md:group-hover:opacity-100"></td>
        ERB
        "app/assets/tailwind/financeiro.css" => %(.mf-hero { color: red; }\n),
        "app/javascript/controllers/x_controller.js" => %(import "chart.js"\nel.classList.add("hidden")\nel.style.color = "red"\ndocument.createElement("button")\n)
      }
    )
    regras = ComponentesUi::Conformidade.verificar(dir).map { |v| v.regra.split(":").first }.uniq
    %w[gemfile gem-antiga daisyui cor-paleta cor-literal tag-crua helper-tag-crua campo-fora-do-ss hover-tailwind3
       css-proprio grafico-fora-da-gem js-classe-fora-da-gem js-estilo-inline js-tag-crua].each do |r|
      assert_includes regras, r
    end
  end
end
