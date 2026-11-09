# Vitrine: uma página por grupo de componentes, em app/views/vitrine/<slug>.html.erb.
# A 1ª linha de cada página diz título, grupo e ordem:
#   <%# titulo: Tabelas | grupo: Dados | ordem: 10 %>
class VitrineController < ApplicationController
  GRUPOS = ["Início", "Fundação", "Layout", "Formulários", "Dados", "Retorno", "Cards", "Acabamento", "Casa e automação", "Tela (v0.10.2)", "Tela (v0.10.3)", "Densidade (v0.11)", "Cards e casa (v0.12)", "Catálogo"].freeze

  helper_method :paginas, :pagina_atual

  def show
    @pagina = params[:pagina].to_s
    raise ActionController::RoutingError, "não achei" unless paginas.any? { |p| p[:slug] == @pagina }

    render @pagina
  end

  private

  def pagina_atual = @pagina

  def paginas
    @paginas ||= Dir[Rails.root.join("app/views/vitrine/*.html.erb")].filter_map do |f|
      slug = File.basename(f, ".html.erb")
      next if slug.start_with?("_")

      meta = File.open(f, &:gets).to_s[/<%#(.*)%>/, 1].to_s
      h = meta.split("|").to_h { |kv| kv.split(":", 2).map(&:strip) }
      { slug:, titulo: h["titulo"] || slug.humanize, grupo: h["grupo"] || "Início", ordem: h["ordem"].to_i }
    end.sort_by { |p| [GRUPOS.index(p[:grupo]) || 99, p[:ordem], p[:titulo]] }
  end
end
