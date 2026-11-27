# Vitrine: uma página por assunto, em app/views/vitrine/<slug>.html.erb, organizada pelas
# categorias de uso (as mesmas, com os mesmos nomes, ícones e ordem, da vitrine do app:
# flutter/example/lib/categorias.dart). A 1ª linha de cada página diz título, categoria e ordem:
#   <%# titulo: Tabela de dados | grupo: Listas e tabelas | ordem: 10 %>
# e, opcionais:
#   tambem: Comércio e finanças; Tempo e agenda   (a página mistura assuntos: aparece também lá)
#   versao: 1.9                                   (peça da onda atual: aparece também em Novidades)
# Grupo fora de GRUPOS faz o test/vitrine_test.rb falhar (nenhuma página fica fora do menu).
class VitrineController < ApplicationController
  # A onda cujas páginas entram em "Novidades".
  NOVIDADES = "1.14".freeze

  # nome, ícone (ss_icon) e para que serve; na ordem do menu.
  CATEGORIAS = [
    ["Novidades (v#{NOVIDADES})", "sparkles", "O que chegou nesta versão."],
    ["Fundação", "color-swatch", "Tema, cores, paletas, tipografia, densidade, aparência e ícones."],
    ["Navegação e moldura", "template", "Barras, abas, menus, cabeçalhos e a casca da tela."],
    ["Ações e botões", "cursor-click", "Botões, menus de ação, confirmar e seleção."],
    ["Formulários e entrada", "pencil-alt", "Campos, escolhas, sliders e passo a passo."],
    ["Listas e tabelas", "view-list", "Itens, linhas, tabelas, quadros e históricos."],
    ["Dados e gráficos", "chart-bar", "Indicadores, gráficos, anéis e barras."],
    ["Cards e painéis", "collection", "Cards, heróis, mosaicos e painéis."],
    ["Retorno e estados", "badge-check", "Aviso, vazio, carregando, erro, offline, sincronização, diálogos e folhas."],
    ["Movimento e transições", "lightning-bolt", "A mola da suíte, entradas, números que rolam e transições de tela."],
    ["Conversa, IA e avisos", "chat-alt-2", "Chat, assistente, notificações, dicas e ajuda."],
    ["Tempo e agenda", "calendar", "Datas, horas, calendário, agenda e cronograma."],
    ["Casa e automação", "home", "Aparelhos, clima, energia, câmeras e controles."],
    ["Comércio e finanças", "shopping-bag", "Dinheiro, preço, oferta, carteira, ingresso e plano."],
    ["Mídia e captura", "photograph", "Foto, câmera, galeria, carrossel e anexos."],
    ["Telas montadas", "device-mobile", "Telas inteiras feitas só com peças da gem."]
  ].map { |nome, icone, descricao| { nome:, icone:, descricao: }.freeze }.freeze

  GRUPO_NOVIDADES = CATEGORIAS.first[:nome]
  GRUPOS = ["Início", *CATEGORIAS.map { _1[:nome] }].freeze

  helper_method :paginas, :pagina_atual, :menu, :contagem

  # v1.12.0: o endereço e a razão social de exemplo do Kit Brasil (dados fictícios; no produto, o endpoint dele).
  DEMO_CEP = { "01310100" => { street: "Avenida Paulista", district: "Bela Vista", city: "São Paulo", state: "SP" } }.freeze
  DEMO_CNPJ = { "11222333000181" => "Loja Exemplo Comércio Ltda", "12ABC34501DE35" => "Exemplo Alfanumérico S.A." }.freeze

  def cep
    a = DEMO_CEP[params[:cep].to_s.gsub(/\D/, "")]
    a ? render(json: a) : head(:not_found)
  end

  def cnpj
    n = DEMO_CNPJ[params[:cnpj].to_s.upcase.gsub(/[^0-9A-Z]/, "")]
    n ? render(json: { name: n }) : head(:not_found)
  end

  # v1.13.0: a resposta de exemplo do "Explicar com IA" (no produto, a IA dele) e o rascunho do "Continuar no
  # celular" (no produto, guardado com um token; aqui vai no próprio link pelo ComponentesUi::Handoff).
  def explicar
    sleep 0.6 unless Rails.env.test?
    render json: { text: "Os gastos de novembro somam R$ 1.240,00, 18% acima de outubro. A maior parte veio de Mercado (R$ 512,40) e Restaurantes (R$ 268,90); sem eles, o mês ficaria dentro da média." }
  end

  def continuar
    estado = params.to_unsafe_h.except("controller", "action", "authenticity_token").slice("demo_continuar")
    render json: Ss::ContinueOnComponent.payload(ComponentesUi::Handoff.link("#{request.base_url}/vitrine/pecas_v1130", estado))
  end

  def show
    @pagina = params[:pagina].to_s
    raise ActionController::RoutingError, "não achei" unless paginas.any? { |p| p[:slug] == @pagina }

    # v1.7: ?tela=1 abre a peça de tela cheia (entrada) sem a moldura da vitrine, para conferir em 390 e 1440;
    # ?tema=claro|escuro|oled, ?paleta=<slug> e ?contraste=alto vão no <html> (layout "tela").
    render @pagina, layout: (params[:tela].present? ? "tela" : "application")
  end

  # Todas as páginas (uma vez cada), na ordem do grupo principal.
  def self.paginas
    Dir[Rails.root.join("app/views/vitrine/*.html.erb")].filter_map do |f|
      slug = File.basename(f, ".html.erb")
      next if slug.start_with?("_")

      meta = File.open(f, &:gets).to_s[/<%#(.*)%>/, 1].to_s
      h = meta.split("|").to_h { |kv| kv.split(":", 2).map(&:strip) }
      grupo = h["grupo"] || "Início"
      tambem = h["tambem"].to_s.split(";").map(&:strip).reject(&:empty?)
      tambem << GRUPO_NOVIDADES if h["versao"] == NOVIDADES
      componentes = File.read(f).scan(/Ss::(\w+)Component\b/).flatten.uniq
      { slug:, titulo: h["titulo"] || slug.humanize, grupo:, grupos: [grupo, *tambem].uniq,
        ordem: h["ordem"].to_i, componentes: }
    end.sort_by { |p| [GRUPOS.index(p[:grupo]) || 99, p[:ordem], p[:titulo]] }
  end

  private

  def pagina_atual = @pagina

  def paginas = @paginas ||= self.class.paginas

  # [[grupo, [páginas]]] na ordem de GRUPOS: a página aparece em cada grupo dela.
  def menu
    @menu ||= GRUPOS.filter_map do |g|
      ps = paginas.select { _1[:grupos].include?(g) }.sort_by { |p| [p[:grupo] == g ? 0 : 1, p[:ordem], p[:titulo]] }
      [g, ps] if ps.any?
    end
  end

  # Páginas e componentes Ss::* distintos de uma categoria.
  def contagem(grupo)
    ps = menu.to_h[grupo] || []
    { paginas: ps.size, componentes: ps.flat_map { _1[:componentes] }.uniq.size }
  end
end
