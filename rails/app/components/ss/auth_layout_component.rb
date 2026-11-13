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
  class AuthLayoutComponent < BaseComponent
    VARIANTS = %i[sheet wall pad].freeze

    attr_reader :product, :tagline, :title, :subtitle, :note, :brand_href, :links, :date

    def initialize(product:, title:, tagline: nil, subtitle: nil, variant: :sheet, date: nil, note: nil,
                   brand: nil, brand_href: nil, links: [], **opts)
      super(**opts)
      @product, @title, @tagline, @subtitle, @note = product, title, tagline, subtitle, note
      @variant = VARIANTS.include?(variant.to_s.to_sym) ? variant.to_s.to_sym : :sheet
      @date = (date || Date.current).to_date
      @brand, @brand_href, @links = brand, brand_href, Array(links)
    end

    def variant = @variant

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
      classes("ss-auth", "is-#{@variant}")
    end

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
