module Ss
  # Formas de capturar (v1.9 · produto, par do SsCaptureHub): grade de opções com ícone, título e descrição (câmera,
  # galeria, colar texto, código de barras, arquivo), a destacada no gradiente e a indisponível com o motivo; embaixo,
  # o envio de arquivo (Ss::FileDropComponent: arrastar, escolher e colar com Ctrl+V) e o colar texto.
  #
  #   render Ss::CaptureHubComponent.new(
  #     upload: { url: leituras_path, name: "leitura[arquivos][]", accept: "image/*,.pdf,.xml" },
  #     paste: { url: leituras_texto_path, name: "leitura[texto]" },
  #     options: [{ kind: :camera, title: "Foto do cupom", description: "Cupom fiscal ou print do pedido.", highlighted: true },
  #               { kind: :paste, group: "Compra" }, { kind: :file, group: "Compra", description: "XML da NF-e" },
  #               { kind: :barcode, group: "Produto", href: leitor_path },
  #               { kind: :gallery, group: "Produto", disabled_reason: "No plano Pro ou Max", disabled_href: planos_path }])
  #
  # options: [{ kind: (:camera, :gallery, :paste, :barcode, :file ou :custom; dá ícone, título e descrição padrão do
  # I18n componentes_ui.capture_hub.*), title:, description:, icon:, href:, method: (button_to), highlighted:,
  # disabled_reason:, disabled_href:, group:, data: }]. Sem href:, :camera/:gallery/:file abrem o seletor de arquivo do
  # upload: (a câmera com capture="environment" e só imagem; a galeria só imagem) e enviam ao escolher; :paste abre o
  # campo de colar texto. Sem upload:/paste: e sem href:, a opção é um <button> com o data: do app.
  # upload: { url:, name:, accept:, multiple: (false), label:, hint:, http_method: (:post) }; paste: { url:, name:,
  # label:, placeholder:, http_method: }. Colar (Ctrl+V) em qualquer ponto da peça: arquivo vai para o upload; texto,
  # para o campo de colar.
  class CaptureHubComponent < BaseComponent
    KINDS = %i[camera gallery paste barcode file custom].freeze
    ICONS = { camera: "camera", gallery: "photograph", paste: "clipboard", barcode: "qrcode", file: "upload", custom: "plus-circle" }.freeze
    DEFAULTS = {
      camera_title: "Tirar foto", camera_text: "Use a câmera do aparelho",
      gallery_title: "Da galeria", gallery_text: "Escolha uma foto já tirada",
      paste_title: "Colar texto", paste_text: "Cole o texto que você copiou",
      barcode_title: "Código de barras", barcode_text: "Aponte para o código",
      file_title: "Enviar arquivo", file_text: "PDF, XML ou imagem"
    }.freeze

    def initialize(options: [], upload: nil, paste: nil, id: nil, label: nil, **rest)
      super(**rest)
      @options = Array(options).map { |o| o.to_h.transform_keys(&:to_sym) }
      @upload = upload&.to_h&.transform_keys(&:to_sym)
      @paste = paste&.to_h&.transform_keys(&:to_sym)
      @id = id || "ss-capture-#{SecureRandom.hex(3)}"
      @label = label
    end

    def call
      tag.section(**root_attrs(id: @id, class: classes("ss-capture"), "aria-label": @label || ss_t("capture_hub.label", default: "Formas de adicionar"),
                               data: { controller: "ss-capture-hub", action: "paste->ss-capture-hub#paste" })) do
        safe_join([highlights, grids, paste_form, upload_form].compact)
      end
    end

    def self.kind(o) = KINDS.find { _1.to_s == o[:kind].to_s } || :custom

    private

    def kind(o) = self.class.kind(o)
    def disabled?(o) = o[:disabled_reason].present?
    def title(o) = o[:title].presence || (kind(o) == :custom ? "" : ss_t("capture_hub.#{kind(o)}.title", default: DEFAULTS[:"#{kind(o)}_title"]))
    def description(o) = o[:description].presence || (kind(o) == :custom ? nil : ss_t("capture_hub.#{kind(o)}.text", default: DEFAULTS[:"#{kind(o)}_text"]))

    def highlights
      hs = @options.select { _1[:highlighted] && !disabled?(_1) }
      safe_join(hs.map { option(_1, highlight: true) }) if hs.any?
    end

    def grids
      resto = @options.reject { _1[:highlighted] && !disabled?(_1) }
      return if resto.empty?

      safe_join(resto.chunk_while { |a, b| a[:group] == b[:group] }.map do |grupo|
        g = grupo.first[:group]
        safe_join([(tag.h3(g, class: "ss-capture-group") if g.present?), tag.div(safe_join(grupo.map { option(_1) }), class: "ss-capture-grid")].compact)
      end)
    end

    def option(o, highlight: false)
      k = kind(o)
      css = ["ss-capture-opt", ("is-highlight" if highlight), ("is-disabled" if disabled?(o))].compact.join(" ")
      desc = disabled?(o) ? o[:disabled_reason] : description(o)
      body = safe_join([
        tag.span(ss_icon(o[:icon].presence || ICONS[k], size: nil), class: "ss-icon-tile#{" is-on-grad" if highlight}", "aria-hidden": "true"),
        tag.span(class: "ss-capture-text") do
          safe_join([(tag.span(ss_t("capture_hub.recommended", default: "Recomendado"), class: "ss-capture-eyebrow") if highlight),
                     tag.span(title(o), class: "ss-capture-title"), (tag.span(desc, class: "ss-capture-note") if desc.present?),
                     (tag.span(ss_t("capture_hub.unavailable", default: "Indisponível"), class: "ss-sr") if disabled?(o))].compact)
        end,
        (tag.span(ss_icon("lock-closed", size: :xs), class: "ss-capture-lock", "aria-hidden": "true") if disabled?(o)),
        (tag.span(ss_icon("arrow-right", size: :sm), class: "ss-capture-go", "aria-hidden": "true") if highlight)
      ].compact)

      if disabled?(o)
        return link_to(body, o[:disabled_href], class: css) if o[:disabled_href]

        return tag.div(body, class: css, "aria-disabled": "true", role: "group")
      end
      if o[:href]
        return render(ButtonComponent.new(href: o[:href], method: o[:method], variant: :bare, css:, form: { class: "contents" })) { body } if o[:method].present? && o[:method].to_s != "get"

        return link_to(body, o[:href], class: css, data: o[:data])
      end
      action = if @upload && %i[camera gallery file].include?(k)
                 { action: "ss-capture-hub#choose", ss_capture_hub_kind_param: k.to_s }
               elsif @paste && k == :paste
                 { action: "ss-capture-hub#showPaste" }
               else
                 {}
               end
      tag.button(body, type: "button", class: "ss-btn-bare #{css}", data: (o[:data] || {}).merge(action))
    end

    def paste_form
      return unless @paste

      fid = "#{@id}-paste"
      form_with(url: @paste[:url], method: @paste[:http_method] || :post, class: "ss-capture-paste ss-card ss-card-pad", html: { hidden: true, id: fid },
                data: { ss_capture_hub_target: "pasteForm" }) do
        safe_join([
          tag.label(@paste[:label] || ss_t("capture_hub.paste.title", default: "Colar texto"), for: "#{fid}-text", class: "ss-label"),
          tag.textarea("", id: "#{fid}-text", name: @paste[:name] || "text", rows: 5, class: "ss-input",
                           placeholder: @paste[:placeholder] || ss_t("capture_hub.paste.text", default: "Cole o texto que você copiou"),
                           data: { ss_capture_hub_target: "text" }),
          tag.div(class: "ss-capture-paste-actions") do
            safe_join([render(ButtonComponent.new(label: ss_t("common.cancel", default: "Cancelar"), variant: :ghost, size: :sm, data: { action: "ss-capture-hub#hidePaste" })),
                       render(ButtonComponent.new(label: ss_t("capture_hub.send", default: "Enviar"), type: :submit, size: :sm))])
          end
        ])
      end
    end

    def upload_form
      return unless @upload

      form_with(url: @upload[:url], method: @upload[:http_method] || :post, multipart: true, class: "ss-capture-upload",
                data: { ss_capture_hub_target: "uploadForm" }) do
        safe_join([
          render(FileDropComponent.new(name: @upload[:name] || "file", label: @upload[:label] || ss_t("capture_hub.file.title", default: "Enviar arquivo"),
                                       hint: @upload[:hint] || ss_t("capture_hub.drop_hint", default: "Arraste, cole (Ctrl+V) ou clique para escolher"),
                                       accept: @upload[:accept], multiple: @upload[:multiple] || false, id: "#{@id}-file",
                                       data: { ss_capture_hub_target: "drop" })),
          tag.div(render(ButtonComponent.new(label: ss_t("capture_hub.send", default: "Enviar"), type: :submit, size: :sm, icon: "upload")), class: "ss-capture-upload-actions")
        ])
      end
    end
  end
end
