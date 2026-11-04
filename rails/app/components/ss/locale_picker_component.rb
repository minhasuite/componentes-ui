module Ss
  # Escolha de idioma: lista com o atual marcado (✓) ou segmented. Nome no próprio idioma
  # (Português, English, Español) com a bandeira (emoji) ou o código.
  #
  #   render Ss::LocalePickerComponent.new(value: I18n.locale, url: idioma_path)            # cada um é um button_to (param locale=)
  #   render Ss::LocalePickerComponent.new(value: "pt-BR", name: "user[locale]", segmented: true)  # rádios dentro do form do app
  #
  # locales: [{ code:, name:, flag: }] (padrão: os 3 da suíte). flags: false mostra o código ("PT").
  # system_option: true (v0.10.1) põe antes a opção "Seguir o sistema" com valor vazio, marcada
  # quando value é nil/vazio (como o SsLocalePicker(systemOption:)). Texto: locale_picker.system
  # (ou system_label:).
  class LocalePickerComponent < BaseComponent
    SUITE = [{ code: "pt-BR", name: "Português", flag: "🇧🇷" }, { code: "en", name: "English", flag: "🇺🇸" },
             { code: "es", name: "Español", flag: "🇪🇸" }].freeze

    attr_reader :value, :url, :name, :param, :locales

    def initialize(value:, url: nil, name: "locale", param: :locale, method: :patch, locales: SUITE, segmented: false,
                   flags: true, label: nil, system_option: false, system_label: nil, form: nil, button_data: nil, **rest)
      super(**rest)
      @form, @button_data = form.to_h.transform_keys(&:to_sym), button_data.to_h
      @value, @url, @name, @param, @method = value.to_s, url, name, param, method
      @locales = locales.map { |l| l.to_h.transform_keys(&:to_sym) }
      @segmented, @flags, @label = segmented, flags, label
      @system_option, @system_label = system_option, system_label
    end

    SYSTEM_ICON = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="12" rx="2"/><path d="M8 20h8M12 16v4"/></svg>'

    def system_option? = !!@system_option
    def system_label = @system_label || ss_t("locale_picker.system", default: "Seguir o sistema")

    # Opções na ordem: a do sistema (code "", se pedida) e os idiomas.
    def options
      sys = { code: "", name: system_label, system: true }
      system_option? ? [sys, *locales] : locales
    end

    # v0.10.1: form: (atributos de cada <form> do button_to, ex. { data: { turbo: false } }) e
    # button_data: (data-* do botão). A classe ss-loc-form fica sempre.
    def form_attrs = @form.merge(class: ["ss-loc-form", @form[:class]].compact.join(" "))

    def segmented? = @segmented
    def current?(l) = l[:code].to_s == value
    def short(code) = code.to_s.split(/[-_]/).first.upcase
    def badge(l) = (@flags && l[:flag].present?) ? l[:flag] : short(l[:code])
    def group_label = @label || ss_t("locale_picker.label", default: "Idioma")
    def id_for(l) = "ss-loc-#{name.to_s.parameterize}-#{l[:system] ? "system" : l[:code].to_s.parameterize}"

    def badge_tag(l)
      return tag.span(SYSTEM_ICON.html_safe, class: "ss-loc-badge is-system", "aria-hidden": true) if l[:system]

      tag.span(badge(l), class: ["ss-loc-badge", ("is-code" unless @flags && l[:flag].present?)].compact.join(" "), "aria-hidden": true)
    end

    def option(l)
      lang = l[:system] ? nil : l[:code]
      inner = safe_join([badge_tag(l),
                         tag.span(l[:name], class: "ss-loc-name", lang:),
                         (tag.span(Ss::CasaIcons.svg(:check), class: "ss-loc-check", "aria-hidden": true) unless segmented?)].compact)
      if url
        button_to(url, method: @method, params: { param => l[:code] }, class: "ss-loc-opt", form: form_attrs, data: @button_data.presence,
                       aria: { current: (current?(l) ? "true" : nil) }, lang:) { inner }
      else
        tag.label(class: "ss-loc-opt", for: id_for(l)) do
          safe_join([tag.input(type: "radio", name:, value: l[:code], id: id_for(l), checked: current?(l), class: "ss-sr"), inner])
        end
      end
    end
  end
end
