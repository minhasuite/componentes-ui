module Ss
  # Divisão em partes: um slider por parte; as partes somam 100%. Mexer numa redistribui nas
  # outras (na proporção delas). Com total: (em centavos) mostra o valor de cada uma.
  # Cada parte manda name[key] = porcentagem inteira.
  #   render Ss::SplitAllocatorComponent.new(name: "divisao", total: 18_000,
  #     items: [{ key: "ana", label: "Ana", value: 50 }, { key: "bia", label: "Bia", value: 50 }])
  class SplitAllocatorComponent < BaseComponent
    attr_reader :name, :items, :total, :legend

    def initialize(name:, items:, total: nil, legend: "Divisão", **rest)
      super(**rest)
      @name, @total, @legend = name, total, legend
      @items = normalize(items.map { |i| i.to_h.transform_keys(&:to_sym) })
    end

    def money(cents)
      reais = (cents.to_i / 100).to_s.reverse.scan(/\d{1,3}/).join(".").reverse
      "R$ #{reais},#{format("%02d", cents.to_i % 100)}"
    end

    def part_value(pct) = total ? (total * pct / 100.0).round : nil

    private

    # Garante soma 100 (sobra vai para a última parte).
    def normalize(list)
      vals = list.map { |i| i[:value].to_i.clamp(0, 100) }
      vals = Array.new(list.size, 100 / [list.size, 1].max) if vals.sum.zero?
      vals = vals.map { |v| (v * 100.0 / vals.sum).floor }
      vals[-1] += 100 - vals.sum if vals.any?
      list.each_with_index.map { |i, idx| i.merge(value: vals[idx]) }
    end
  end
end
