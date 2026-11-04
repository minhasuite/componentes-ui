module Ss
  # Um bloco do Ss::BlockListComponent (criado pelo with_block da lista; ver lá).
  class BlockComponent < BaseComponent
    TONES = %i[accent info warn success danger].freeze

    attr_reader :id, :title, :summary, :error, :position, :list

    def initialize(list:, position:, id:, title:, summary: nil, icon: nil, tone: :accent, enabled: true, error: nil,
                   open: false, focused: false, toggle_url: nil, duplicate_url: nil, delete_url: nil, **rest)
      super(**rest)
      @list, @position, @id, @title, @summary, @icon = list, position, id.to_s, title, summary, icon
      @tone = TONES.include?(tone.to_s.to_sym) ? tone.to_s.to_sym : :accent
      @enabled, @error, @open, @focused = enabled, error, open, focused
      @toggle_url, @duplicate_url, @delete_url = toggle_url, duplicate_url, delete_url
    end

    def tone = @tone
    def enabled? = !!@enabled
    def open? = !!@open
    def focused? = !!@focused
    def invalid? = error.present?
    def field(key) = "#{list.name}[#{id}][#{key}]"
    def icon = (@icon || Ss::CasaIcons.svg(:puzzle)).to_s.html_safe
    def l(key, **vars) = list.label(key, **vars)
    def svg(name) = Ss::CasaIcons.svg(name)

    def switch
      lbl = l(:enabled, title:)
      if @toggle_url
        Ss::SwitchComponent.new(url: @toggle_url, on: enabled?, label: lbl)
      else
        Ss::SwitchComponent.new(name: field(:enabled), checked: enabled?, label: lbl)
      end
    end

    def menu_item(key, icon_name, url: nil, method: nil, danger: false)
      inner = safe_join([svg(icon_name), tag.span(l(key))])
      css = ["ss-blk-mi", ("is-danger" if danger)].compact.join(" ")
      if url
        link_to(inner, url, class: css, role: "menuitem", data: { turbo_method: method })
      else
        tag.button(inner, type: "button", class: css, role: "menuitem", data: { action: "ss-block-list##{key.to_s.camelize(:lower)}", move: key.to_s.delete_prefix("move_") })
      end
    end
  end
end
