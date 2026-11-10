module Ss
  # Um bloco do Ss::BlockListComponent (criado pelo with_block da lista; ver lá).
  #
  # v0.10.1:
  # - html_id: id do <li> (o id: continua sendo o do dado, em name[id][…] e data-id).
  # - move_url: mover vira button_to no servidor (move_method:, padrão :patch) com o param
  #   direction=up|down (move_param: troca o nome); sem move_url, continua no JS.
  # - toggle_method: (padrão :post) e toggle_params: (params extras) para o toggle_url:.
  # - delete_confirm: "Excluir o passo?" (delete_confirm_title: opcional): excluir vira
  #   button_to com data-turbo-confirm e tom danger, que a Ss::ConfirmDialogComponent mostra.
  #   delete_method: (padrão :delete) troca o verbo do excluir.
  # - duplicable: false tira o Duplicar; deletable: false tira o Excluir.
  class BlockComponent < BaseComponent
    TONES = %i[accent info warn success danger].freeze

    attr_reader :id, :title, :summary, :error, :position, :list

    def initialize(list:, position:, id:, title:, summary: nil, icon: nil, tone: :accent, enabled: true, error: nil,
                   open: false, focused: false, toggle_url: nil, duplicate_url: nil, delete_url: nil, html_id: nil,
                   move_url: nil, move_method: :patch, move_param: :direction, toggle_method: :post, toggle_params: {},
                   delete_confirm: nil, delete_confirm_title: nil, delete_method: :delete, duplicable: true, deletable: true, **rest)
      super(**rest)
      @html_id, @move_url, @move_method, @move_param = html_id, move_url, move_method, move_param
      @toggle_method, @toggle_params = toggle_method, toggle_params.to_h
      @delete_confirm, @delete_confirm_title, @delete_method = delete_confirm, delete_confirm_title, delete_method
      @duplicable, @deletable = duplicable, deletable
      @list, @position, @id, @title, @summary, @icon = list, position, id.to_s, title, summary, icon
      @tone = TONES.include?(t = (tone.to_s == "warning" ? :warn : tone.to_s.to_sym)) ? t : :accent
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
        Ss::SwitchComponent.new(url: @toggle_url, on: enabled?, label: lbl, method: @toggle_method, params: @toggle_params)
      else
        Ss::SwitchComponent.new(name: field(:enabled), checked: enabled?, label: lbl)
      end
    end

    def duplicable? = @duplicable != false
    def deletable? = @deletable != false
    def html_id = @html_id

    # Mover: no servidor (move_url:) ou no JS.
    def move_item(dir)
      key = :"move_#{dir}"
      return menu_item(key, :"arrow_#{dir}") unless @move_url

      menu_item(key, :"arrow_#{dir}", url: @move_url, method: @move_method, params: { @move_param => dir.to_s }, form: true)
    end

    def delete_item
      return menu_item(:delete, :trash, url: @delete_url, method: @delete_method, danger: true) unless @delete_url && @delete_confirm

      data = { turbo_confirm: @delete_confirm, turbo_confirm_tone: "danger", turbo_confirm_title: @delete_confirm_title }.compact
      menu_item(:delete, :trash, url: @delete_url, method: @delete_method, danger: true, form: true, form_data: data)
    end

    def menu_item(key, icon_name, url: nil, method: nil, danger: false, form: false, params: {}, form_data: {})
      inner = safe_join([svg(icon_name), tag.span(l(key))])
      css = ["ss-blk-mi", ("is-danger" if danger)].compact.join(" ")
      if url && form
        button_to(url, method:, params:, class: css, role: "menuitem", form: { class: "ss-blk-mi-form", data: form_data }) { inner }
      elsif url
        link_to(inner, url, class: css, role: "menuitem", data: { turbo_method: method })
      else
        tag.button(inner, type: "button", class: css, role: "menuitem", data: { action: "ss-block-list##{key.to_s.camelize(:lower)}", move: key.to_s.delete_prefix("move_") })
      end
    end
  end
end
