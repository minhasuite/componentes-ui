module VitrineHelper
  # Bloco de demonstração: título, para que serve e o código de uso.
  #   <%= demo "Ss::TabsComponent", "Abas com indicador que desliza", uso: 'render Ss::TabsComponent.new(...)' do %> ... <% end %>
  def demo(titulo, descricao = nil, uso: nil, &block)
    tag.section(class: "vt-demo") do
      safe_join([tag.h3(titulo), (tag.p(descricao) if descricao), (tag.code(uso) if uso), capture(&block)].compact)
    end
  end
end
