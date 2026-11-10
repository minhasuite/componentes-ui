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

    # Uma mensagem: from: :me (da pessoa, à direita, na cor da marca) ou :ai (do assistente).
    class Message < BaseComponent
      def initialize(from: :ai, text: nil, time: nil, **rest)
        super(**rest)
        @me = from.to_s == "me"
        @text, @time = text, time
      end

      def call
        body = content.presence || simple_format_text(@text)
        tag.div(**root_attrs(class: classes("ss-bubble", ("is-me" if @me), ("is-ai" unless @me)), data: { from: (@me ? "me" : "ai") })) do
          safe_join([body, (tag.small(@time, class: "num") if @time)].compact)
        end
      end

      private

      def simple_format_text(text) = safe_join(text.to_s.split(/\n{2,}/).map { |p| tag.p(safe_join(p.split("\n"), tag.br)) })
    end
  end
end
