module Ss
  # Chat com o assistente (v0.15, par do SsChatBubble + SsThinking + SsChatInput): lista de
  # mensagens (role="log"), o "pensando" e o campo de envio, sobre o .ss-chat/.ss-bubble/.ss-thinking.
  #
  #   <%= render(Ss::ChatComponent.new(id: "assistente", url: assistente_mensagens_path, placeholder: "Pergunte ou peça um lançamento")) do |chat| %>
  #     <% chat.with_message(from: :me, text: "Gastei 45 no mercado com o Nubank", time: "14:05") %>
  #     <% chat.with_message(from: :ai) do %>
  #       Posso lançar assim?
  #       <%= render Ss::ChatActionComponent.new(title: "Lançar despesa", rows: [["Valor", "R$ 45,00"], ["Cartão", "Nubank"]],
  #             confirm_url: confirmar_path(acao), cancel_url: cancelar_path(acao)) %>
  #     <% end %>
  #   <% end %>
  #
  # O formulário posta name: (padrão "message") em url: pelo Turbo; a resposta (turbo_stream)
  # faz append em "<id>-messages" (Ss::ChatComponent.messages_id(id)). Ao enviar, a bolha da pessoa
  # entra na hora (echo: true, padrão; a resposta não deve repetir) e o "pensando" aparece até
  # chegar mensagem nova do assistente (ou o envio falhar). Enter envia, Shift+Enter quebra linha.
  # thinking: true já começa pensando. empty: slot do que aparece sem mensagem nenhuma.
  #
  # v0.26, conversa entre pessoas (cliente e atendente, ex.: atendimento do WhatsApp): from: :them é a outra
  # pessoa (à esquerda, na superfície, sem ser a IA); author: põe quem escreveu no alto da bolha; status: mostra
  # enviando/enviada/entregue/lida/não enviada no rodapé, ao lado do horário. O bloco (content) entra DENTRO do log,
  # depois do slot messages: o produto pode intercalar mensagens e separadores de dia renderizando direto, e o
  # Turbo Stream append em "<id>-messages" continua caindo no mesmo lugar. O slot empty só aparece sem mensagem
  # nenhuma e com o bloco vazio.
  #
  #   <%= render(Ss::ChatComponent.new(id: "conversa", url: mensagens_path, echo: false)) do %>
  #     <%= render Ss::ChatDividerComponent.new(label: "Hoje") %>
  #     <%= render Ss::ChatComponent::Message.new(from: :them, author: "Mercado Sabor Caseiro", text: "O pedido saiu?", time: "09:10") %>
  #     <%= render Ss::ChatComponent::Message.new(from: :me, author: "Ana · pelo celular", text: "Saiu hoje cedo.", time: "09:12", status: :read) %>
  #   <% end %>
  #
  # Mídia na bolha (bloco da Message): <img>, <video controls> ou <audio controls> com class="ss-bubble-media"
  # (largura até a da bolha, cantos arredondados; o áudio ocupa a bolha, com 16rem no mínimo) e documento como
  # linha-link com ícone e nome:
  #
  #   <%= render Ss::ChatComponent::Message.new(from: :them, time: "09:20") do %>
  #     <img class="ss-bubble-media" src="..." alt="Foto do produto"><p>Chegou assim</p>
  #   <% end %>
  #   <%= render Ss::ChatComponent::Message.new(from: :me, time: "09:21", status: :delivered) do %>
  #     <a class="ss-bubble-file" href="..." download><svg aria-hidden="true">...</svg><span>boleto-2904.pdf</span><span class="ss-bubble-file-meta">PDF · 84 KB</span></a>
  #   <% end %>
  class ChatComponent < BaseComponent
    renders_many :messages, "Ss::ChatComponent::Message"
    renders_one :empty

    attr_reader :id, :url, :name

    def self.messages_id(id) = "#{id}-messages"

    def initialize(id:, url: nil, name: "message", placeholder: nil, thinking: false, echo: true, disabled: false, max_length: 2000,
                   label: nil, http_method: :post, **rest)
      super(**rest)
      @id, @url, @name, @placeholder, @thinking, @echo, @disabled, @max_length, @label, @http_method =
        id, url, name, placeholder, thinking, echo, disabled, max_length, label, http_method
    end

    def messages_id = self.class.messages_id(id)
    def thinking? = @thinking
    def disabled? = @disabled
    def placeholder = @placeholder || ss_t("chat.placeholder", default: "Escreva uma mensagem")
    def label = @label || ss_t("chat.label", default: "Conversa")
    def send_label = ss_t("chat.send", default: "Enviar")
    def thinking_label = ss_t("chat.thinking", default: "Pensando")
    def http_method = @http_method
    def max_length = @max_length
    def echo? = @echo

    # O slot empty só quando não há mensagem nenhuma (nem no slot, nem no bloco).
    def log_content = content.presence
    def show_empty? = empty? && messages.none? && log_content.blank?

    # Uma mensagem: from: :me (da pessoa, à direita, na cor da marca), :ai (do assistente) ou, v0.26, :them
    # (a outra pessoa numa conversa entre pessoas: à esquerda, na superfície). author: legenda no alto da bolha;
    # status: :sending, :sent, :delivered, :read ou :failed (ícone no rodapé, com o nome para o leitor de tela).
    class Message < BaseComponent
      FROM = %i[me ai them].freeze
      STATUSES = %i[sending sent delivered read failed].freeze
      # Ícones do rodapé (24×24, traço em currentColor): relógio, ✓, ✓✓ e alerta.
      ICONS = {
        sending: %(<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>),
        sent: %(<path d="m5 12.5 4.5 4.5L19 7.5"/>),
        delivered: %(<path d="m2.5 12.5 4.5 4.5L16.5 7.5"/><path d="m11.5 16 1 1 9.5-9.5"/>),
        failed: %(<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5v5.5m0 3.2v.1"/>)
      }.tap { |h| h[:read] = h[:delivered] }.freeze
      LABELS = { sending: "Enviando", sent: "Enviada", delivered: "Entregue", read: "Lida", failed: "Não enviada" }.freeze

      attr_reader :from, :status

      def initialize(from: :ai, text: nil, time: nil, status: nil, author: nil, **rest)
        super(**rest)
        @from = FROM.find { |f| f.to_s == from.to_s } || :ai
        @status = STATUSES.find { |s| s.to_s == status.to_s }
        @text, @time, @author = text, time, author
      end

      def call
        body = content.presence || simple_format_text(@text)
        tag.div(**root_attrs(class: classes("ss-bubble", "is-#{@from}"), data: { from: @from.to_s })) do
          safe_join([author_tag, body, footer].compact)
        end
      end

      private

      def author_tag = (tag.span(@author, class: "ss-bubble-author") if @author.present?)

      # Sem status, o rodapé é o de antes (<small class="num">14:05</small>).
      def footer
        return tag.small(@time, class: "num") if @status.nil? && @time
        return unless @status

        tag.small(class: "num ss-bubble-foot") do
          safe_join([(tag.span(@time, class: "ss-bubble-time") if @time), status_tag].compact)
        end
      end

      def status_tag
        label = ss_t("chat.status.#{@status}", default: LABELS[@status])
        icon = tag.svg(ICONS[@status].html_safe, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", "stroke-width": 2,
                       "stroke-linecap": "round", "stroke-linejoin": "round", "aria-hidden": true, focusable: "false")
        # Não enviada: o texto fica à vista (é preciso agir); nos outros, só para o leitor de tela.
        text = @status == :failed ? tag.span(label) : tag.span(label, class: "ss-sr")
        tag.span(safe_join([icon, text]), class: "ss-bubble-status", data: { status: @status.to_s }, title: label)
      end

      def simple_format_text(text) = safe_join(text.to_s.split(/\n{2,}/).map { |p| tag.p(safe_join(p.split("\n"), tag.br)) })
    end
  end
end
