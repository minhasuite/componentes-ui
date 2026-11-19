module Ss
  # Tela de entrada "Folhinha" (v0.22, par do SsAuthLayout.folhinha): a folhinha de parede do comércio com a
  # data de hoje, o formulário (o bloco) e a faixa do patrocinador na cor do produto (--accent). Serve para
  # entrar, criar conta, esqueci a senha e o "link enviado": o formulário e os avisos são do produto, com as
  # peças de sempre (ss_form_with, Ss::GoogleButtonComponent, Ss::CalloutComponent, Ss::TextLinkComponent).
  #
  #   render(Ss::AuthLayoutComponent.new(product: "Meu Gestor", tagline: "A loja em dia, sem planilha.",
  #                                      title: "Entrar", subtitle: "no Meu Gestor")) do
  #     ss_form_with(url: login_path) { |f| … }
  #   end
  #
  # variant: :sheet (padrão; a folha pendurada com o formulário dentro), :wall (a folhinha grande na parede à
  # esquerda e o formulário numa coluna à direita; no celular a folhinha encolhe em cima) ou :pad (bloco de
  # destacar: faixa do produto colada em cima, folha picotada e a de amanhã aparecendo por baixo).
  # date: (padrão Date.current) é o dia da folhinha; domingo sai em --danger, como no calendário de parede.
  # note: linha curta ao lado do dia (só :sheet). brand: e brand_href: são a marca do topo (padrão
  # "MinhaSuite", sem link); links: [[rótulo, href], …] vai embaixo (termos, privacidade).
  # O título e o número usam --ss-font-display (Big Shoulders Display): carregue com ss_display_font_tag no
  # <head>; sem ela, caem para a fonte do texto.
  # motion: true (v1.4, só :wall; controlador ss-auth): ao enviar o formulário ou tocar em "Entrar com o Google", a
  # folhinha se solta do pino e cai, e por baixo aparece a folha seguinte com a saudação da hora, "Abrindo o
  # <produto>…" e o carimbo "Em dia". O envio não espera a animação. error: true faz a folha tremer ao abrir (use
  # quando a página volta com o erro de login). Com "reduzir movimento", a folha só some e nada treme.
  #
  # v1.7 · variant: :cartaz (par do SsAuthLayout.cartaz; proposta "Cartaz + papel" de 19/11/2026): metade cartaz na
  # cor funda da paleta do produto (--brand-deep; no escuro, misturada à página) com a marca, o nome do produto, o
  # tagline: grande na fonte de exibição, a linha de dados (facts:, em DM Mono) e a palavra gigante (word:, padrão a
  # última palavra do produto) cortada pela borda; a outra metade é o papel (--page) com "Parte da MinhaSuite", o
  # título, o formulário e os links. layout: :split (único por enquanto; no celular o cartaz vira uma faixa em cima).
  # icon: (nome do ss_icon) vai antes do nome do produto. Ao abrir, uma passada de cor varre o cartaz uma vez; com
  # "reduzir movimento", não. date:, note: e motion: não valem no :cartaz (sem folhinha).
  #
  #   render(Ss::AuthLayoutComponent.new(product: "Minhas Vendas", tagline: "A venda não para.", variant: :cartaz,
  #                                      word: "vendas", facts: %w[Web Windows Caixa App], icon: "chart-bar",
  #                                      title: "Entrar", subtitle: "no Minhas Vendas")) { … }
  class AuthLayoutComponent < BaseComponent
    VARIANTS = %i[sheet wall pad cartaz].freeze
    LAYOUTS = %i[split].freeze

    attr_reader :product, :tagline, :title, :subtitle, :note, :brand_href, :links, :date, :facts, :icon

    def initialize(product:, title:, tagline: nil, subtitle: nil, variant: :sheet, date: nil, note: nil,
                   brand: nil, brand_href: nil, links: [], motion: false, error: false,
                   word: nil, layout: :split, facts: [], icon: nil, **opts)
      super(**opts)
      @motion, @error = motion, error
      @product, @title, @tagline, @subtitle, @note = product, title, tagline, subtitle, note
      @variant = VARIANTS.include?(variant.to_s.to_sym) ? variant.to_s.to_sym : :sheet
      @layout = LAYOUTS.include?(layout.to_s.to_sym) ? layout.to_s.to_sym : :split
      @date = (date || Date.current).to_date
      @brand, @brand_href, @links = brand, brand_href, Array(links)
      @word, @facts, @icon = word, Array(facts).compact_blank, icon
    end

    def variant = @variant
    def layout = @layout

    # A palavra gigante do cartaz (decorativa, fora do leitor de tela): a dada ou a última do nome do produto.
    def word
      w = @word.presence || product.to_s.split.last.to_s
      w.downcase
    end

    def brand
      @brand || safe_join(["Minha", tag.b("Suite")])
    end

    def month = month_name(@date)
    def weekday = day_name(@date)
    def sunday? = @date.sunday?
    def tomorrow = @date + 1
    def tomorrow_weekday = day_name(tomorrow)

    def part_of
      ss_t("auth.part_of", brand: brand_text, default: "Parte da #{brand_text}")
    end

    def root_classes
      classes("ss-auth", "is-#{@variant}", ("is-#{@layout}" if @variant == :cartaz))
    end

    # Movimento só na :wall, onde a folhinha é separada do formulário.
    def motion? = @motion && @variant == :wall

    def root_data
      return {} unless motion?
      { controller: "ss-auth", action: "submit->ss-auth#leave click->ss-auth#click",
        ss_auth_error_value: @error ? "true" : "false",
        ss_auth_greetings_value: greetings.to_json }
    end

    # Manhã (até 11h), tarde (até 17h) e noite; o controlador escolhe pela hora de quem abre a página.
    def greetings
      Array(ss_t("auth.greetings", default: ["Bom dia", "Boa tarde", "Boa noite"]))
    end

    def opening = ss_t("auth.opening", product: product, default: "Abrindo o #{product}…")
    def stamp = ss_t("auth.stamp", default: "Em dia")

    private

    def brand_text = @brand.is_a?(String) ? @brand : "MinhaSuite"

    def month_name(d)
      Array(ss_t("auth.months", default: PT_MONTHS))[d.month - 1] || PT_MONTHS[d.month - 1]
    end

    def day_name(d)
      Array(ss_t("auth.days", default: PT_DAYS))[d.wday] || PT_DAYS[d.wday]
    end

    PT_MONTHS = %w[Janeiro Fevereiro Março Abril Maio Junho Julho Agosto Setembro Outubro Novembro Dezembro].freeze
    PT_DAYS = %w[Domingo Segunda-feira Terça-feira Quarta-feira Quinta-feira Sexta-feira Sábado].freeze
  end
end
