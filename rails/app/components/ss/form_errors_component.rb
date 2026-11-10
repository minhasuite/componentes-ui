module Ss
  # Resumo dos erros do formulário (v0.18): o Ss::CalloutComponent de perigo no topo, com o título
  # "Confira os campos" e a lista das mensagens (o erro de cada campo continua embaixo dele, pelo
  # ss_form_with). Não aparece sem erro.
  #
  #   <%= render Ss::FormErrorsComponent.new(record: @conta) %>
  #   <%= render Ss::FormErrorsComponent.new(errors: ["Valor inválido"], title: "Não deu para salvar") %>
  #
  # record: qualquer coisa com errors.full_messages (ActiveModel); errors: lista de textos (soma com o
  # record); title: troca o título; base_only: true lista só os erros sem campo (errors[:base]) quando
  # os dos campos já aparecem embaixo de cada um.
  class FormErrorsComponent < BaseComponent
    def initialize(record: nil, errors: nil, title: nil, base_only: false, **rest)
      super(**rest)
      @title = title || ss_t("form_errors.title", default: "Confira os campos")
      msgs = []
      if record.respond_to?(:errors)
        msgs += base_only ? Array(record.errors[:base]) : record.errors.full_messages
      end
      @messages = (msgs + Array(errors)).map(&:to_s).reject(&:blank?).uniq
    end

    def render? = @messages.any?

    def call
      render(Ss::CalloutComponent.new(tone: :danger, title: @title, css: classes("ss-form-errors"), **@attrs)) do
        tag.ul(safe_join(@messages.map { |m| tag.li(m) }))
      end
    end
  end
end
