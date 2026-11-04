module Ss
  # Período: dois input type=date + atalhos (Hoje, 7 dias, Este mês, Mês passado).
  #   render Ss::DateRangeComponent.new(from_name: "de", to_name: "ate", from: params[:de], to: params[:ate])
  class DateRangeComponent < BaseComponent
    # Rótulos pt-BR de reserva; o texto sai de componentes_ui.date_range.shortcuts.<chave>.
    SHORTCUTS = { "today" => "Hoje", "7d" => "7 dias", "month" => "Este mês", "last_month" => "Mês passado" }.freeze

    attr_reader :from_name, :to_name, :from, :to, :legend, :shortcuts, :id

    def initialize(from_name:, to_name:, from: nil, to: nil, legend: nil, shortcuts: SHORTCUTS.keys, id: nil, **rest)
      super(**rest)
      @from_name, @to_name, @from, @to, @legend, @shortcuts = from_name, to_name, from, to, legend, shortcuts
      @legend ||= ss_t("date_range.legend", default: "Período")
      @id = id || "ss-range-#{SecureRandom.hex(3)}"
    end

    def shortcut_label(key) = ss_t("date_range.shortcuts.#{key}", default: SHORTCUTS.fetch(key))
  end
end
