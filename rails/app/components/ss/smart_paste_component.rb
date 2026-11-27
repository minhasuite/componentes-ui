module Ss
  # v1.12.0 "Kit Brasil" (par do SsSmartPaste): o colar inteligente. A pessoa cola qualquer coisa e o campo
  # reconhece o tipo (ComponentesUi::PasteDetector no servidor, o ssDetect do ss_br.js ao vivo): Pix copia e cola
  # ou chave, boleto, chave de NF-e, CPF/CNPJ, CEP, telefone, e-mail, link, valor em R$, data ou texto livre. O
  # cartão diz "Isso parece um boleto de R$ 123,45 com vencimento em 10/12/2026" e mostra as ações que o produto
  # registrou para o tipo (e para os do also: CPF, CNPJ, telefone e e-mail válidos também mostram as de :pix_key).
  #
  #   render Ss::SmartPasteComponent.new(actions: {
  #     boleto: [{ label: "Pagar boleto", href: pagar_boletos_path, method: :post, icon: "cash", primary: true }],
  #     pix: [{ label: "Pagar Pix", href: "/pix/novo?codigo=%{value}" }],
  #     url: [{ label: "Abrir", href: "%{value}", target: "_blank" }]
  #   })
  #
  # Ação: href: com %{value} e %{type} (vão escapados para URL); method: :get (link, padrão) ou :post/:patch (form
  # com o token do Rails e os campos value e type, o nome do param em param:, padrão "paste"); icon: (ss_icon),
  # primary: (botão cheio; sem nenhum, o 1º), target:. name:/value: dão nome e conteúdo ao <textarea>. today:
  # fixa o "hoje" (teste e vitrine).
  class SmartPasteComponent < BaseComponent
    ICONS = { pix: "qrcode", pix_key: "key", boleto: "receipt-tax", nfe: "document-text", cpf: "identification",
              cnpj: "office-building", cep: "location-marker", phone: "phone", email: "at-symbol", url: "link",
              money: "cash", date: "calendar", text: "menu-alt-2", invalid: "exclamation" }.freeze

    attr_reader :name, :value

    def initialize(actions: {}, name: "paste", value: nil, label: nil, hint: nil, param: "paste", today: nil, paste_button: true, **opts)
      super(**opts)
      @actions = actions.to_h.transform_keys(&:to_s).transform_values { |list| Array(list).map { |a| normalize(a) } }
      @name = name
      @value = value
      @label = label
      @hint = hint
      @param = param
      @today = today
      @paste_button = paste_button
    end

    def t(key, **o) = ss_t("br.#{key}", **o)
    def label = @label || t("paste_label")
    def hint = @hint || t("paste_hint")
    def paste_button? = @paste_button
    def uid = @uid ||= "ss-paste-#{object_id}"
    def match = @match ||= ComponentesUi::PasteDetector.detect(@value, **(@today ? { today: @today } : {}))

    def normalize(a)
      a = a.to_h.transform_keys(&:to_sym)
      { label: a[:label].to_s, href: a[:href].to_s, method: (a[:method] || :get).to_s.downcase, icon: a[:icon]&.to_s,
        primary: !!a[:primary], target: a[:target]&.to_s }.compact
    end

    # Os textos e os ícones que o JS usa para montar o cartão igual ao do servidor.
    def texts
      { summary: I18n.t("componentes_ui.br.paste_summary"), what: I18n.t("componentes_ui.br.paste_what"),
        invalid: I18n.t("componentes_ui.br.paste_invalid"), key_types: I18n.t("componentes_ui.br.key_types"),
        pix_key: t("pix_key"), actions: t("paste_actions"), empty: t("paste_empty"), currency: ss_currency }
    end

    # Os ícones dos tipos e os das ações ("action:cash"), em SVG.
    def icons
      @icons ||= ICONS.transform_values { |n| ss_icon(n, size: nil).to_s }.merge(
        @actions.values.flatten.filter_map { _1[:icon] }.uniq.to_h { |n| ["action:#{n}", ss_icon(n, size: :xs).to_s] }
      )
    end

    def root
      data = { controller: "ss-smart-paste", ss_smart_paste_actions_value: @actions.to_json,
               ss_smart_paste_texts_value: texts.to_json, ss_smart_paste_icons_value: icons.to_json,
               ss_smart_paste_param_value: @param, ss_smart_paste_token_value: token }
      data[:ss_smart_paste_today_value] = @today.iso8601 if @today
      root_attrs(class: classes("ss-smart-paste"), data:)
    end

    def token
      @token ||= (helpers.protect_against_forgery? ? helpers.form_authenticity_token : "").to_s
    rescue StandardError
      @token = ""
    end

    # ── O cartão (o mesmo desenho que o ss-smart-paste monta no navegador) ──────────
    def card(m)
      # DV errado: sem ações (não oferece "Pagar" para um boleto que não confere).
      list = m.valid ? m.types.flat_map { |ty| @actions[ty.to_s] || [] } : []
      primary = list.index { _1[:primary] } || 0
      detail = { boleto: m.fields[:display], nfe: ComponentesUi::Br.format_nfe_key(m.value) }[m.type]
      also = m.also.include?(:pix_key) ? [t("pix_key"), t("key_types.#{m.type}", default: "")].reject(&:blank?).join(" · ") : nil
      tag.div(class: "ss-card ss-paste-card", data: { type: m.type, valid: m.valid.to_s }) do
        safe_join([
          tag.div(class: "ss-paste-head") do
            safe_join([tag.span(icons[m.valid ? m.type : :invalid].html_safe, class: "ss-paste-icon", "aria-hidden": "true"),
                       tag.p(ss_paste_summary(m), class: "ss-paste-summary")])
          end,
          (tag.p(detail, class: "ss-paste-detail num") if detail.present?),
          (tag.span(also, class: "ss-badge ss-badge-muted ss-paste-also") if also),
          (tag.div(safe_join(list.each_with_index.map { |a, i| action(a, m, i == primary) }), class: "ss-paste-actions", role: "group", "aria-label": t("paste_actions")) if list.any?)
        ].compact)
      end
    end

    def interpolate(href, m) = href.gsub("%{value}", ERB::Util.url_encode(m.value)).gsub("%{type}", m.type.to_s)

    def action(a, m, primary)
      css = "ss-btn ss-btn-sm #{primary ? "ss-btn-primary" : "ss-btn-ghost"}"
      body = safe_join([(icons["action:#{a[:icon]}"].html_safe if a[:icon]), tag.span(a[:label])].compact)
      href = interpolate(a[:href], m)
      if a[:method] == "get"
        tag.a(body, class: css, href:, target: a[:target], rel: ("noopener" if a[:target]))
      else
        tag.form(action: href, method: "post", class: "ss-paste-form") do
          safe_join([(tag.input(type: "hidden", name: "_method", value: a[:method]) unless a[:method] == "post"),
                     (tag.input(type: "hidden", name: "authenticity_token", value: token) if token.present?),
                     tag.input(type: "hidden", name: "#{@param}[value]", value: m.value),
                     tag.input(type: "hidden", name: "#{@param}[type]", value: m.type.to_s),
                     tag.button(body, type: "submit", class: css)].compact)
        end
      end
    end
  end
end
