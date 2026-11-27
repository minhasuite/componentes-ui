module Ss
  # Foto em tela cheia com zoom (comprovante, foto do cupom, anexo) (v1.10, par do SsImageViewer/showSsImageViewer):
  # uma miniatura (ou o bloco) abre um <dialog> escuro com a barra de cima (×, title:, with_action), a imagem
  # inteira no meio e os botões − / % / + / tamanho original embaixo.
  #
  #   render Ss::ImageViewerComponent.new(src: url_for(nota.foto), title: "cupom.jpg")
  #   render Ss::ImageViewerComponent.new(src: url, title: "Comprovante") do |v|
  #     v.with_trigger { tag.span("Ver comprovante", class: "ss-btn ss-btn-ghost") }
  #     v.with_action { link_to(ss_icon("download"), url, download: true, class: "ss-viewer-btn", "aria-label": "Baixar") }
  #   end
  #
  # Zoom de 1× até max_scale: (4): roda do mouse (no ponto), pinça, duplo clique (2,5× no ponto e volta), os
  # botões e o teclado (+ − 0; setas movem a imagem ampliada). Arrastar move a ampliada. Esc e × fecham (o foco
  # volta à miniatura). O leitor de tela ouve "Zoom 250%". Imagem que não carrega: ícone e "Não deu para abrir a
  # imagem". semantic_label: o nome lido (padrão: title: ou "Imagem"). inline: true desenha o visor aberto no
  # lugar, sem diálogo (vitrine, painel de conferência). Reduzir movimento: o zoom troca sem animar.
  class ImageViewerComponent < BaseComponent
    renders_one :trigger
    renders_many :actions

    def initialize(src:, title: nil, semantic_label: nil, max_scale: 4, thumb_size: 96, inline: false, **rest)
      super(**rest)
      @src, @title, @inline = src, title, inline
      @label = semantic_label || title || ss_t("image_viewer.image", default: "Imagem")
      @max = max_scale.to_f.clamp(1.5, 10)
      @thumb = thumb_size.to_i.clamp(44, 400)
    end

    def before_render = content

    def call
      tag.div(**root_attrs(class: classes("ss-viewer-wrap", ("is-inline" if @inline)),
                           data: { controller: "ss-image-viewer", ss_image_viewer_max_value: @max,
                                   ss_image_viewer_zoom_value: ss_t("image_viewer.zoom", default: "Zoom %{pct}%", pct: "%{pct}") })) do
        safe_join([(opener unless @inline), viewer].compact)
      end
    end

    private

    def opener
      tag.button(type: "button", class: "ss-viewer-trigger", style: "--ts:#{@thumb}px", data: { action: "ss-image-viewer#open", ss_image_viewer_target: "opener" },
                 "aria-label": ss_t("image_viewer.open", default: "Abrir imagem: %{name}", name: @label), "aria-haspopup": "dialog") do
        trigger? ? trigger.to_s : image_tag(@src, alt: "", loading: "lazy", class: "ss-viewer-thumb")
      end
    end

    def viewer
      tag.send(@inline ? :div : :dialog, class: "ss-viewer", "aria-label": @label,
               data: { ss_image_viewer_target: "dialog", action: "close->ss-image-viewer#reset" }) do
        safe_join([bar, stage, tools])
      end
    end

    def bar
      tag.div(class: "ss-viewer-bar") do
        safe_join([
          tag.button(ss_icon("x", size: nil), type: "button", class: "ss-viewer-btn", "aria-label": ss_t("common.close", default: "Fechar"),
                                               data: { action: "ss-image-viewer#close" }),
          tag.strong(@title.to_s, class: "ss-viewer-title"),
          tag.div(safe_join(actions.map(&:to_s)), class: "ss-viewer-actions")
        ])
      end
    end

    def stage
      tag.div(class: "ss-viewer-stage", tabindex: "0", role: "img", "aria-label": @label,
              data: { ss_image_viewer_target: "stage",
                      action: "wheel->ss-image-viewer#wheel pointerdown->ss-image-viewer#down dblclick->ss-image-viewer#double keydown->ss-image-viewer#key" }) do
        safe_join([
          image_tag(@src, alt: "", draggable: "false", class: "ss-viewer-img", data: { ss_image_viewer_target: "img", action: "error->ss-image-viewer#broken" }),
          tag.span(safe_join([ss_icon("photograph", size: nil), tag.span(ss_t("image_viewer.broken", default: "Não deu para abrir a imagem"))]),
                   class: "ss-viewer-broken", hidden: true, data: { ss_image_viewer_target: "fail" })
        ])
      end
    end

    def tools
      tag.div(class: "ss-viewer-tools") do
        safe_join([
          tool("minus", ss_t("image_viewer.zoom_out", default: "Reduzir"), "zoomOut", target: "less"),
          tag.output("100%", class: "ss-viewer-pct num", "aria-live": "polite", data: { ss_image_viewer_target: "pct" }),
          tool("plus", ss_t("image_viewer.zoom_in", default: "Ampliar"), "zoomIn", target: "more"),
          tool("arrows-expand", ss_t("image_viewer.reset", default: "Tamanho original"), "reset")
        ])
      end
    end

    def tool(icon, label, action, target: nil)
      tag.button(ss_icon(icon, size: nil), type: "button", class: "ss-viewer-btn", "aria-label": label,
                                           data: { action: "ss-image-viewer##{action}", ss_image_viewer_target: target }.compact)
    end
  end
end
