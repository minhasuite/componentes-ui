module Ss
  # Assistente com IA (v1.9 · produto, par do SsAssistantView), montado sobre o Ss::ChatComponent: lista de conversas ao
  # lado (abrir, nova, apagar com confirmação), atalhos em chips no topo (e no vazio), o histórico em bolhas, o cartão de
  # ação sugerida (Ss::ChatActionComponent), a resposta "pendente" que se busca sozinha (polling), o plano sem direito e
  # a cota.
  #
  #   render Ss::AssistantComponent.new(id: "assistente", url: assistente_mensagens_path,
  #     messages: [{ from: :me, text: "Monte um treino de 4 dias", time: "14:02" },
  #                { from: :ai, text: "Posso montar assim?", time: "14:02",
  #                  action: { title: "Montar este treino", confirm_url: montar_path, confirm_label: "Montar treino" } },
  #                { status: :pending, poll_url: assistente_mensagem_path(m) }],
  #     shortcuts: [{ label: "Resumo da semana", icon: "chart-bar" }, { label: "Metas", href: insight_path(:metas) }],
  #     conversations: @conversas.map { |c| { id: c.id, title: c.title, subtitle: "há 2 h", href: conversa_path(c), delete_href: conversa_path(c) } },
  #     current_conversation_id: @conversa.id, new_conversation_href: new_conversa_path,
  #     quota: { used: 3, limit: 10, label: "Mensagens este mês" })
  #
  # messages: [{ from: :me/:ai, text:, time:, status: (:pending, :failed ou nada), poll_url: (do pendente), error:
  # (do failed), retry_href: (do failed; POST), action: { args do Ss::ChatActionComponent; icon: aceita o nome do ss_icon } }]. O bloco vai dentro do
  # log, depois das mensagens (separador de dia, mensagem com mídia).
  #
  # Pendente: a bolha com os três pontos (role=status, "Respondendo") e data-url=poll_url. O controller ss-assistant
  # pede a URL a cada every: ms (2 s; pausa com a aba escondida) com Accept text/html: 204 ou corpo vazio = ainda
  # pensando; HTML = troca a bolha por ele (outra pendente continua). A resposta do envio (turbo_stream append em
  # "<id>-messages") também pode trazer uma pendente: ela começa a perguntar sozinha. Pare em max_polls: tentativas
  # (padrão 90): vira a bolha de erro.
  #
  # Atalhos: shortcuts: [{ label:, prompt: (texto enviado; padrão o label), icon:, href: (link no lugar de enviar) }]:
  # tocar escreve o prompt no campo e envia. locked: { feature:, text:, href:, label: } troca a conversa pelo cartão
  # do plano (sem campo). quota: { used:, limit:, label: } mostra a barra (.ss-quota; .is-low falta 1, .is-out
  # acabou) e, acabada, trava o campo com "Mensagens do mês esgotadas" (disabled: força). Textos do I18n
  # (componentes_ui.assistant.*).
  class AssistantComponent < BaseComponent
    def initialize(id:, url: nil, messages: [], shortcuts: [], conversations: nil, current_conversation_id: nil,
                   new_conversation_href: nil, delete_method: :delete, quota: nil, locked: nil, disabled: false, thinking: false,
                   empty_title: nil, empty_text: nil, placeholder: nil, every: 2000, max_polls: 90, label: nil, **rest)
      super(**rest)
      @id, @url = id.to_s, url
      @messages = Array(messages).map { |m| m.to_h.transform_keys(&:to_sym) }
      @shortcuts = Array(shortcuts).map { |s| s.to_h.transform_keys(&:to_sym) }
      @conversations = conversations&.map { |c| c.to_h.transform_keys(&:to_sym) }
      @current, @new_href, @delete_method = current_conversation_id&.to_s, new_conversation_href, delete_method
      @quota = quota&.to_h&.transform_keys(&:to_sym)
      @locked = locked&.to_h&.transform_keys(&:to_sym)
      @disabled, @thinking = disabled, thinking
      @empty_title, @empty_text, @placeholder, @every, @max_polls, @label = empty_title, empty_text, placeholder, every.to_i, max_polls.to_i, label
    end

    def call
      tag.div(**root_attrs(id: "#{@id}-assistant", class: classes("ss-assistant", ("has-side" if @conversations)),
                           data: { controller: "ss-assistant", ss_assistant_every_value: @every, ss_assistant_max_value: @max_polls,
                                   ss_assistant_failed_value: t_("failed", "Não deu para responder agora.") })) do
        safe_join([side, tag.div(main, class: "ss-assistant-main")].compact)
      end
    end

    def exhausted? = @quota && @quota[:limit].to_i.positive? && @quota[:used].to_i >= @quota[:limit].to_i

    private

    def t_(key, default, **opts) = ss_t("assistant.#{key}", default:, **opts)

    # ── Conversas ───────────────────────────────────────────────
    def side
      return unless @conversations

      tag.aside(class: "ss-assistant-side", "aria-label": t_("conversations", "Conversas")) do
        head = tag.div(class: "ss-assistant-side-head") do
          safe_join([tag.h2(t_("conversations", "Conversas"), class: "ss-assistant-side-title"),
                     (render(IconButtonComponent.new(icon: "plus", label: t_("new", "Nova conversa"), href: @new_href)) if @new_href)].compact)
        end
        list = if @conversations.empty?
                 tag.p(t_("no_conversations", "Nenhuma conversa ainda"), class: "ss-assistant-side-empty")
               else
                 tag.ul(safe_join(@conversations.map { conversation(_1) }), class: "ss-assistant-convs")
               end
        safe_join([head, list])
      end
    end

    def conversation(c)
      atual = c[:id].to_s == @current
      texto = safe_join([tag.span(c[:title].presence || t_("untitled", "Conversa"), class: "ss-assistant-conv-title"),
                         (tag.span(c[:subtitle], class: "ss-assistant-conv-sub") if c[:subtitle].present?)].compact)
      abrir = c[:href] ? link_to(texto, c[:href], class: "ss-assistant-conv", "aria-current": (atual ? "page" : nil)) : tag.span(texto, class: "ss-assistant-conv")
      apagar = if c[:delete_href]
                 nome = t_("delete", "Apagar conversa")
                 button_to(c[:delete_href], method: @delete_method, class: "ss-icon-btn is-sm is-danger", title: nome, "aria-label": nome,
                                            form: { class: "contents", data: { turbo_confirm: t_("delete_confirm", "Apagar esta conversa?"),
                                                                               turbo_confirm_tone: "danger", turbo_confirm_button: nome } }) do
                   ss_icon("trash", size: nil)
                 end
               end
      tag.li(safe_join([abrir, apagar].compact), class: ["ss-assistant-conv-row", ("is-current" if atual)].compact.join(" "))
    end

    # ── Conversa ────────────────────────────────────────────────
    def main
      return locked_card if @locked

      safe_join([shortcuts_bar, chat, quota_bar].compact)
    end

    def disabled? = @disabled || exhausted?

    def chat
      placeholder = disabled? ? t_("exhausted", "Mensagens do mês esgotadas") : @placeholder
      extra = content
      render(ChatComponent.new(id: @id, url: @url, placeholder:, disabled: disabled?, thinking: @thinking, label: @label)) do |c|
        c.with_empty { empty_block } if @messages.empty? && extra.blank?
        safe_join([*@messages.map { message(_1) }, extra].compact)
      end
    end

    def empty_block
      tag.div(class: "ss-assistant-empty") do
        safe_join([
          tag.span(ss_icon("sparkles", size: nil), class: "ss-assistant-mark", "aria-hidden": "true"),
          tag.p(@empty_title || t_("empty_title", "Como posso ajudar?"), class: "ss-assistant-empty-title"),
          (tag.p(@empty_text, class: "ss-assistant-empty-text") if @empty_text.present?),
          (chips("ss-assistant-chips is-center") if @shortcuts.any?)
        ].compact)
      end
    end

    def message(m)
      case m[:status]&.to_sym
      when :pending then pending(m)
      when :failed then failed(m)
      else
        bubble = render(ChatComponent::Message.new(from: m[:from] || :ai, text: m[:text], time: m[:time], status: m[:delivery], author: m[:author]))
        act = m[:action] && render(ChatActionComponent.new(**action_args(m[:action])))
        safe_join([bubble, act].compact)
      end
    end

    # icon: pode ser o nome do ss_icon ("sparkles"); o ChatActionComponent quer o SVG.
    def action_args(a)
      h = a.to_h.transform_keys(&:to_sym)
      h[:icon] = ss_icon(h[:icon].to_s, size: nil) if h[:icon].present? && !(h[:icon].respond_to?(:html_safe?) && h[:icon].html_safe?)
      h
    end

    def pending(m)
      tag.div(class: "ss-bubble is-ai is-pending", role: "status", "aria-label": t_("thinking", "Respondendo"),
              data: { from: "ai", ss_assistant_target: "pending", url: m[:poll_url] }.compact) do
        tag.span(tag.i + tag.i + tag.i, class: "ss-thinking", "aria-hidden": "true")
      end
    end

    def failed(m)
      tag.div(class: "ss-bubble is-ai is-failed", data: { from: "ai" }) do
        safe_join([tag.p(m[:error].presence || t_("failed", "Não deu para responder agora.")),
                   (render(ButtonComponent.new(label: ss_t("common.retry", default: "Tentar de novo"), icon: "refresh", href: m[:retry_href], method: :post,
                                               variant: :ghost, size: :sm, form: { class: "contents" })) if m[:retry_href]),
                   (tag.small(m[:time], class: "num") if m[:time])].compact)
      end
    end

    def shortcuts_bar
      return if @shortcuts.empty? || (@messages.empty? && content.blank?)

      tag.div(chips("ss-assistant-chips"), class: "ss-assistant-top")
    end

    def chips(css)
      tag.div(class: css, role: "group", "aria-label": t_("shortcuts", "Sugestões")) do
        safe_join(@shortcuts.map do |s|
          inner = safe_join([(ss_icon(s[:icon], size: :xs) if s[:icon].present?), tag.span(s[:label])].compact)
          if s[:href]
            link_to(inner, s[:href], class: "ss-chip")
          else
            tag.button(inner, type: "button", class: "ss-chip", disabled: disabled? || nil, "aria-pressed": "false",
                              data: { action: "ss-assistant#pick", ss_assistant_prompt_param: s[:prompt].presence || s[:label] })
          end
        end)
      end
    end

    def quota_bar
      return unless @quota && @quota[:limit].to_i.positive?

      used, limit = @quota[:used].to_i, @quota[:limit].to_i
      left = limit - used
      state = left <= 0 ? "is-out" : (left == 1 ? "is-low" : nil)
      tag.div(class: ["ss-quota", "ss-assistant-quota", state].compact.join(" "), style: "--v:#{[used.to_f / limit, 1].min.round(3)}") do
        safe_join([tag.span(@quota[:label] || t_("quota", "Mensagens este mês")),
                   tag.b(t_("quota_of", "%{used} de %{limit}", used: [used, limit].min, limit:)), tag.i])
      end
    end

    def locked_card
      l = @locked
      tag.div(class: "ss-card ss-card-pad ss-assistant-locked") do
        safe_join([
          tag.span(ss_icon("lock-closed", size: nil), class: "ss-assistant-lock", "aria-hidden": "true"),
          tag.div(class: "ss-assistant-locked-head") do
            safe_join([tag.h2(l[:feature], class: "ss-assistant-locked-title"), tag.p(t_("paid_only", "Só nos planos pagos"), class: "ss-assistant-locked-tag")])
          end,
          tag.p(l[:text], class: "ss-assistant-locked-text"),
          (render(ButtonComponent.new(label: l[:label] || t_("see_plans", "Ver planos"), href: l[:href], size: :sm)) if l[:href])
        ].compact)
      end
    end
  end
end
