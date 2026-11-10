module Ss
  # Botão flutuante (v0.17, par do SsFab): a ação principal da tela num canto, por cima de tudo, na cor
  # sólida da marca. Fica fixo no canto de baixo (direita; position: :start, esquerda), respeita a área
  # segura do celular (env(safe-area-inset-*)) e sobe sozinho acima da barra fixa de baixo
  # (.ss-sticky-bar). Some na impressão.
  #
  #   render Ss::FabComponent.new(icon: icon("microphone", ""), label: "Falar com a casa", data: { action: "assist#open" })
  #   render Ss::FabComponent.new(icon: svg, label: "Novo pedido", href: new_pedido_path, extended: true)
  #
  # label: (obrigatório) é o nome lido (aria-label) e a dica (title); com extended: true ele também
  # aparece ao lado do ícone (pílula). extended: false (padrão) = círculo só com o ícone; :wide =
  # círculo no celular e pílula com o texto a partir de 640 px (par do SsFab(extendedFrom: 640)).
  # href: vira <a>; sem href, <button type="button"> (a ação vem do data-action do app).
  # lift: ("4.5rem") sobe o botão acima de uma barra do app que a gem não conhece (barra de baixo do
  # quiosque, player); vai na variável --ss-fab-lift. pulse: true liga o anel que pulsa (chamar atenção
  # uma vez; em todas as telas, deixe desligado). static: true tira o fixo (vitrine, dentro de um card).
  #
  # Turbo: renderize uma vez, no layout, fora do <main>. O id (padrão "ss-fab") é estável, então o morph
  # do refresh casa o mesmo nó em vez de criar outro; permanent: true põe data-turbo-permanent (o nó
  # sobrevive à navegação, útil quando o botão guarda estado, como um diálogo aberto).
  class FabComponent < BaseComponent
    EXTENDED = [true, false, :wide].freeze

    def initialize(icon:, label:, href: nil, extended: false, position: :end, lift: nil, pulse: false, static: false,
                   permanent: false, id: "ss-fab", **rest)
      super(id:, **rest)
      @icon, @label, @href = icon, label.to_s, href
      @extended = EXTENDED.include?(extended) ? extended : (extended.to_s == "wide" ? :wide : !!extended)
      @position = position.to_s == "start" ? :start : :end
      @lift = lift.to_s[/\A[\d.]+(px|rem|em|vh)\z/]
      @pulse, @static, @permanent = pulse, static, permanent
    end

    def call
      css = classes("ss-fab", ("is-icon" if @extended == false), ("is-wide" if @extended == :wide),
                    ("is-start" if @position == :start), ("is-static" if @static), ("is-still" unless @pulse))
      attrs = root_attrs(class: css, title: @label, aria: { label: @label }, style: ("--ss-fab-lift: #{@lift}" if @lift),
                         data: ({ turbo_permanent: true } if @permanent))
      body = safe_join([tag.span(@icon.to_s.html_safe, class: "ss-fab-ico", "aria-hidden": "true"),
                        (tag.span(@label, class: "ss-fab-label") unless @extended == false)].compact)
      @href ? link_to(@href, **attrs) { body } : tag.button(type: "button", **attrs) { body }
    end
  end
end
