module Ss
  # Folha A4 para recibo, pedido ou relatório: cabeçalho com marca, dados das partes,
  # tabela de itens, totais e rodapé. Na tela parece uma folha; na impressão (@media
  # print) sai limpa, em preto, sem a moldura do app (.ss-no-print some).
  #   render Ss::PrintLayoutComponent.new(title: "Pedido", number: "1042", date: "04/11/2026",
  #       company: { name: "Loja Centro", lines: ["CNPJ 00.000.000/0001-00", "Rua A, 10"] },
  #       customer: { label: "Cliente", name: "Mercado Bom Preço", lines: ["CPF …"] },
  #       columns: [["Item"], ["Qtd", :r], ["Valor", :r]], rows: [["Arroz 5 kg", "2", "R$ 50,00"]],
  #       totals: [["Subtotal", "R$ 50,00"], ["Total", "R$ 50,00", :strong]]) do |p|
  #     p.with_brand { image_tag "logo.svg", alt: "" }
  #     p.with_notes { "Obrigado pela preferência." }
  #     p.with_footer { "Documento sem valor fiscal." }
  #   end
  class PrintLayoutComponent < BaseComponent
    renders_one :brand
    renders_one :notes
    renders_one :footer

    def initialize(title:, number: nil, date: nil, company: {}, customer: nil, columns: [], rows: [], totals: [], **opts)
      super(**opts)
      @title = title
      @number = number
      @date = date
      @company = company || {}
      @customer = customer
      @columns = columns.map { Array(_1) }
      @rows = rows
      @totals = totals
    end

    def right?(i) = @columns[i]&.include?(:r)
  end
end
