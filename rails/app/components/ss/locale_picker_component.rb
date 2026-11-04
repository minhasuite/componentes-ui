module Ss
  # Escolha de idioma: lista com o atual marcado (✓) ou segmented. Nome no próprio idioma
  # (Português, English, Español) com a bandeira (emoji) ou o código.
  #
  #   render Ss::LocalePickerComponent.new(value: I18n.locale, url: idioma_path)            # cada um é um button_to (param locale=)
  #   render Ss::LocalePickerComponent.new(value: "pt-BR", name: "user[locale]", segmented: true)  # rádios dentro do form do app
  #
  # locales: [{ code:, name:, flag: }] (padrão: os 3 da suíte). flags: false mostra o código ("PT").
  class LocalePickerComponent < BaseComponent
    SUITE = [{ code: "pt-BR", name: "Português", flag: "🇧🇷" }, { code: "en", name: "English", flag: "🇺🇸" },
             { code: "es", name: "Español", flag: "🇪🇸" }].freeze

    attr_reader :value, :url, :name, :param, :locales

    def initialize(value:, url: nil, name: "locale", param: :locale, method: :patch, locales: SUITE, segmented: false,
                   flags: true, label: nil, **rest)
      super(**rest)
      @value, @url, @name, @param, @method = value.to_s, url, name, param, method
      @locales = locales.map { |l| l.to_h.transform_keys(&:to_sym) }
      @segmented, @flags, @label = segmented, flags, label
    end

    def segmented? = @segmented
    def current?(l) = l[:code].to_s == value
    def short(code) = code.to_s.split(/[-_]/).first.upcase
    def badge(l) = (@flags && l[:flag].present?) ? l[:flag] : short(l[:code])
    def group_label = @label || ss_t("locale_picker.label", default: "Idioma")
    def id_for(l) = "ss-loc-#{name.to_s.parameterize}-#{l[:code].to_s.parameterize}"

    def option(l)
      inner = safe_join([tag.span(badge(l), class: ["ss-loc-badge", ("is-code" unless @flags && l[:flag].present?)].compact.join(" "), "aria-hidden": true),
                         tag.span(l[:name], class: "ss-loc-name", lang: l[:code]),
                         (tag.span(Ss::CasaIcons.svg(:check), class: "ss-loc-check", "aria-hidden": true) unless segmented?)].compact)
      if url
        button_to(url, method: @method, params: { param => l[:code] }, class: "ss-loc-opt", form_class: "ss-loc-form",
                       aria: { current: (current?(l) ? "true" : nil) }, lang: l[:code]) { inner }
      else
        tag.label(class: "ss-loc-opt", for: id_for(l)) do
          safe_join([tag.input(type: "radio", name:, value: l[:code], id: id_for(l), checked: current?(l), class: "ss-sr"), inner])
        end
      end
    end
  end
end
