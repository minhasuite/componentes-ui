module Ss
  # Tile de câmera: o quadro (imagem parada em image_url: ou o <video> WebRTC do app no slot frame),
  # título, selo "AO VIVO", idade do quadro parado ("há 12 s") e ações por cima (slot actions).
  # Não faz WebRTC: o player é do app.
  #
  #   render Ss::CameraTileComponent.new(title: "Garagem", state: :stale, image_url: snap_url, age: 12,
  #            retry_url: camera_retry_path(c)) do |t|
  #     t.with_frame { tag.video(autoplay: true, muted: true, playsinline: true, data: { controller: "webrtc" }) }
  #     t.with_action { tag.button(icone, class: "ss-cam-act", aria: { label: "Tela cheia" }) }
  #   end
  #
  # state: :loading (esqueleto com brilho) | :live | :stale | :error | :offline. Tudo fica no HTML e
  # o CSS mostra pelo data-state: o JS do app troca em el.dataset.state = "live" quando o vídeo
  # conecta, sem render de novo. age: segundos (ou Duration) do quadro; o controller ss-camera faz a
  # idade andar de segundo em segundo (quadro novo: el.dataset.ssCameraAgeValue = 0). retry_url:
  # vira button_to; sem ele, retry_button: true mostra um botão que dispara "ss-camera:retry" (bubbles).
  #
  # v0.10.1: status: "Gravando" (ou with_status { … }) põe um selo de texto ao lado do título,
  # em qualquer estado. O título continua à vista com a câmera offline/com erro.
  class CameraTileComponent < BaseComponent
    STATES = %i[loading live stale error offline].freeze
    DEFAULTS = { live: "AO VIVO", loading: "Carregando imagem", error: "Não deu para carregar a imagem",
                 offline: "Câmera offline", retry: "Tentar de novo", age_s: "há %{n} s", age_min: "há %{n} min",
                 age_h: "há %{n} h", age_d: "há %{n} d" }.freeze

    renders_one :frame
    renders_one :status
    renders_many :actions

    attr_reader :title, :state, :image_url, :retry_url, :url

    def initialize(title:, state: :live, image_url: nil, age: nil, retry_url: nil, retry_button: false, url: nil,
                   aspect: "16 / 9", labels: {}, status: nil, **rest)
      super(**rest)
      @status_text = status
      @title, @image_url, @retry_url, @retry, @url, @aspect = title, image_url, retry_url, retry_button, url, aspect
      @state = STATES.include?(state.to_s.to_sym) ? state.to_s.to_sym : :live
      @age = age&.to_i
      @labels = labels.to_h.transform_keys(&:to_sym)
    end

    def label(key, **vars)
      text = @labels[key] || ss_t("camera_tile.#{key}", default: DEFAULTS[key], **vars)
      vars.empty? ? text : I18n.interpolate(text, vars)
    end

    # "há 12 s", "há 3 min", "há 2 h", "há 1 d".
    def age_text
      return nil if @age.nil?
      s = @age
      return label(:age_s, n: s) if s < 60
      return label(:age_min, n: s / 60) if s < 3600
      return label(:age_h, n: s / 3600) if s < 86_400

      label(:age_d, n: s / 86_400)
    end

    def status_text = status? ? status : @status_text.presence

    def retry? = retry_url.present? || @retry
    def aspect_css = @aspect.to_s.match?(%r{\A[\d.\s/]+\z}) ? @aspect : "16 / 9"

    def aria_label
      extra = case state
              when :live then label(:live)
              when :stale then age_text
              when :loading then label(:loading)
              else label(state)
              end
      [title, extra].compact.join(", ")
    end

    def icon(name) = Ss::CasaIcons.svg(name)

    # ss-camera: a idade anda sozinha (a partir de quando o quadro foi tirado) e o retry sem URL
    # vira evento. Os moldes de texto vão junto para o JS falar o mesmo idioma.
    def controller_data
      own = @attrs.to_h[:data].to_h
      ctrl = [own[:controller] || own["controller"], "ss-camera"].compact.join(" ")
      tpl = %i[age_s age_min age_h age_d].to_h { |k| [k, label(k, n: "{n}")] }
      { state:, controller: ctrl, ss_camera_age_value: @age, ss_camera_labels_value: tpl.to_json }.compact
    end
  end
end
