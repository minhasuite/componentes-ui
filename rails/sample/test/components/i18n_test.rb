require "test_helper"

# i18n da gem (v0.10): os textos saem de config/locales/componentes_ui.{pt-BR,en,es}.yml.
# 1. Os três YAML têm exatamente as mesmas chaves (o spec do produto exige o mesmo).
#    Não confere se toda chamada ss_t/I18n.t tem chave: o default: pt-BR cobre a falta.
# 2. Heurística: palavras pt conhecidas não aparecem fixas no código da gem fora de um
#    default: (Ruby ou JS), de comentário, de constante/hash de reserva (FOO = …) ou do
#    atalho text(:chave, "pt") dos componentes da v0.10.
class I18nTest < ActiveSupport::TestCase
  GEM = Pathname(ComponentesUi::Engine.root)
  LOCALES = %w[pt-BR en es].freeze

  # { "a" => { "b" => 1 } } → { "a.b" => 1 } (lista fica como valor).
  def flat(hash, prefix = nil, out = {})
    hash.each do |k, v|
      key = [prefix, k].compact.join(".")
      v.is_a?(Hash) ? flat(v, key, out) : out[key] = v
    end
    out
  end

  def yaml(locale)
    path = GEM.join("config/locales/componentes_ui.#{locale}.yml")
    assert path.exist?, "falta #{path}"
    data = YAML.load_file(path)
    assert data.key?(locale), "#{path.basename} precisa começar por #{locale}:"
    flat(data[locale].fetch("componentes_ui"))
  end

  test "pt-BR, en e es têm as mesmas chaves" do
    base = yaml("pt-BR")
    assert_operator base.size, :>=, 100
    LOCALES.drop(1).each do |loc|
      other = yaml(loc)
      assert_equal [], (base.keys - other.keys).sort, "chaves do pt-BR que faltam no #{loc}"
      assert_equal [], (other.keys - base.keys).sort, "chaves do #{loc} que não existem no pt-BR"
      base.each do |k, v|
        assert_equal v.size, other[k].size, "#{loc}.#{k}: lista com tamanho diferente" if v.is_a?(Array)
        assert_equal v.to_s.scan(/%\{\w+\}/).sort, other[k].to_s.scan(/%\{\w+\}/).sort, "#{loc}.#{k}: interpolações diferentes"
      end
    end
  end

  test "a engine carrega os YAML e o texto muda com o idioma" do
    assert_equal "Fechar", I18n.t("componentes_ui.common.close", locale: :"pt-BR")
    assert_equal "Close", I18n.t("componentes_ui.common.close", locale: :en)
    assert_equal "Cerrar", I18n.t("componentes_ui.common.close", locale: :es)
  end

  # Texto pt que não pode ficar fixo (string, texto entre tags). Lista curta de propósito:
  # são os rótulos de interface que a gem tinha.
  PT_WORDS = %w[Fechar Buscar Desfazer Voltar Cancelar Salvar Salvando Excluir Remover Próximo Avançar Concluir
                Copiar Copiado Carregando Hoje Ontem Pular Selecionar Paginação Página Recolher Expandir
                obrigatório Digite Escolha Nada\ encontrado Tentar\ de\ novo Novidades Atalhos Variação Período
                Indisponível Enviando… Ligar Desligar Aumentar Diminuir Carregar\ mais Dispensar Procurando…].freeze

  # Arquivos fora desta conferência (nenhum por enquanto).
  SKIP = %w[].freeze

  test "nenhuma palavra pt conhecida fixa fora de default:" do
    files = Dir[GEM.join("app/components/**/*.{rb,erb}")] + Dir[GEM.join("app/javascript/componentes_ui/**/*.js")] +
            Dir[GEM.join("lib/componentes_ui/*.rb")]
    words = Regexp.union(PT_WORDS.map { |w| /(?<![\p{L}_-])#{Regexp.escape(w)}(?![\p{L}_])/ })
    hits = files.reject { |f| SKIP.any? { f.include?(_1) } }.flat_map do |f|
      File.readlines(f).each_with_index.filter_map do |line, i|
        code = line.strip
        next if code.start_with?("#", "//", "<%#", "*", "/*")
        next if code.include?("default:") # o texto pt de reserva fica no default: (Ruby e JS)
        next if code.match?(/\A[A-Z][A-Z0-9_]* = /) # constante de reserva (SHORTCUTS, THEMES, STATES…)
        # Continuação de hash de reserva em várias linhas (DEFAULTS = { a: "…",\n b: "…" }.freeze).
        next if code.match?(/\A(\w+: "[^"]*",?\s*)+(\}\.freeze)?\z/)

        # Atalho do componente com o pt de reserva na posição: text(:retry, "Tentar de novo").
        code = code.gsub(/\b\w+\(:\w+, "[^"]*"/, "")

        # Só dentro de string ("…", '…', `…`) ou de texto entre tags (>…<).
        literal = code.scan(/"[^"]*"|'[^']*'|`[^`]*`|>[^<>]*</).join(" ")
        "#{Pathname(f).relative_path_from(GEM)}:#{i + 1}: #{code[0, 120]}" if literal.match?(words)
      end
    end
    assert_equal [], hits, "texto pt fixo (use ss_t(..., default:) ou data-*-value):\n#{hits.join("\n")}"
  end
end

# Os componentes mudam de texto e de formato com o idioma da página.
class I18nRenderTest < ComponentTest
  test "toast, drawer e qr em en e es" do
    I18n.with_locale(:en) { render_inline(Ss::ToastComponent.new(message: "x", undo_url: "/u")) }
    assert_selector "button", text: "Undo"
    assert_selector ".ss-toast-close[aria-label='Close notice']"
    I18n.with_locale(:es) { render_inline(Ss::DrawerComponent.new(title: "x")) }
    assert_selector ".ss-drawer-x[aria-label=Cerrar]"
    render_inline(Ss::QrCardComponent.new(code: "abc", hint: false))
    assert_selector "h3", text: "Pague com Pix"
    assert_no_selector ".ss-qrcard-hint"
  end

  test "parâmetro do app vence o idioma" do
    I18n.with_locale(:en) { render_inline(Ss::ToastComponent.new(message: "x", undo_url: "/u", undo_label: "Voltar atrás")) }
    assert_selector "button", text: "Voltar atrás"
  end

  test "número e dinheiro no formato do idioma e na moeda da config" do
    rows = [{ id: 1, total: 1234.5, qtd: 2.5, dia: Date.new(2026, 10, 31) }]
    table = lambda do
      Ss::DataTableComponent.new(rows:, id: "t", caption: "T", tools: false).tap do |t|
        t.column :total, "Total", format: :money
        t.column :qtd, "Qtd", format: :number
        t.column :dia, "Dia", format: :date
      end
    end
    render_inline(table.call)
    assert_selector "td[data-col=total] .ss-amount", text: "R$ 1.234,50"
    assert_selector "td[data-col=qtd]", text: "2,5"
    assert_selector "td[data-col=dia] time", text: "31/10/2026"
    I18n.with_locale(:en) { render_inline(table.call) }
    assert_selector "td[data-col=total] .ss-amount small", text: ".50"
    assert_selector "td[data-col=total]", text: "R$1,234.50"
    assert_selector "td[data-col=dia] time", text: "10/31/2026"
    begin
      ComponentesUi.config.currency = "EUR"
      I18n.with_locale(:es) { render_inline(Ss::CountUpComponent.new(value: 1234.5, format: :money)) }
      assert_selector ".ss-sr", text: "1.234,50 €"
      assert_selector "[data-ss-count-up-currency-value=EUR]"
    ensure
      ComponentesUi.config.currency = "BRL"
    end
  end

  test "dias da semana e textos do controller saem do idioma" do
    I18n.with_locale(:en) do
      render_inline(Ss::ComboboxComponent.new(name: "c", label: "C", options: []))
    end
    assert_selector "[data-ss-combobox-empty-label-value='Nothing found']"
    assert_selector "input[placeholder='Type to search…']"
    I18n.with_locale(:es) do
      render_inline(Ss::GanttComponent.new(tasks: [], start: Date.new(2026, 11, 1), days: 7))
    end
    assert_selector ".ss-gantt-day small", text: "X" # miércoles
  end
end

# v0.10: os componentes novos (casa, controles, dados, estrutura) em en e es, sem texto pt vazando.
class I18nV10RenderTest < ComponentTest
  SECTIONS = %w[block_list camera_tile clock code_keypad d_pad device_tile icon_picker locale_picker logbook media_player
                mic_button notice_card scan_radar state_bands stepper_input switch thermostat time_series_chart weather_card
                weekday_picker].freeze
  T0 = Time.zone.parse("2026-11-04 10:00")
  NOW = Time.zone.parse("2026-11-04 14:30")
  SVG = "<svg viewBox='0 0 24 24'></svg>".html_safe

  def strings(locale)
    I18n.t("componentes_ui", locale:).slice(*SECTIONS.map(&:to_sym))
  end

  def flat(h, out = {}, prefix = nil)
    h.each { |k, v| v.is_a?(Hash) ? flat(v, out, "#{prefix}#{k}.") : out["#{prefix}#{k}"] = v.to_s }
    out
  end

  # Trechos pt (sem as interpolações) que mudam no idioma pedido, mais os nomes pt dos dias.
  def leaks(locale)
    pt = flat(strings(:"pt-BR"))
    other = flat(strings(locale))
    # (Um trecho pt que também é texto do idioma pedido, como "Apagar" em es, fica de fora.)
    split = ->(v) { v.split(/%\{\w+\}/).map(&:strip) }
    frags = pt.flat_map { |k, v| v == other[k] ? [] : split.(v) }.select { _1.length >= 4 } - other.values.flat_map(&split)
    frags += I18n.t("componentes_ui.date.weekdays", locale: :"pt-BR").map(&:capitalize) - I18n.t("componentes_ui.date.weekdays", locale:).map(&:capitalize)
    Regexp.union(frags.uniq.map { |w| /(?<![\p{L}])#{Regexp.escape(w)}(?![\p{L}])/ })
  end

  def renders
    serie = { name: "S1", unit: "°C", points: [[T0, 20.0], [T0 + 40.minutes, 25.5]] }
    luz = { label: "L1", segments: [{ from: T0, to: T0 + 2.hours, state: "on", label: "On" }] }
    eventos = [{ at: NOW - 1.hour, title: "E1" }, { at: NOW - 1.day, title: "E2" }, { at: NOW - 3.days, title: "E3" }]
    [
      Ss::DeviceTileComponent.new(name: "D1", status: :unavailable, url: "/d", toggle_url: "/t"),
      Ss::DeviceTileComponent.new(name: "D2", state: "x", on: true, status: :error, url: "/d", toggle_url: "/t"),
      Ss::DeviceTileComponent.new(name: "D3", state: "x", status: :locked),
      Ss::SwitchComponent.new(url: "/s", on: false, label: "S"),
      Ss::ThermostatComponent.new(target: 22.5, current: 20, mode: "heat", url: "/c"),
      Ss::ThermostatComponent.new(target: 22, mode: "off", pending: true),
      Ss::CodeKeypadComponent.new(url: "/a", length: 4, error: true),
      Ss::CodeKeypadComponent.new(success: true),
      Ss::StepperInputComponent.new(name: "n", label: "N", value: 1),
      Ss::WeekdayPickerComponent.new(name: "d", selected: [1, 2]),
      Ss::TimeSeriesChartComponent.new(title: "C", series: [serie], bands: [luz], zoomed: true, reset_url: "/r"),
      Ss::TimeSeriesChartComponent.new(title: "C", series: [], loading: true),
      Ss::TimeSeriesChartComponent.new(title: "C", series: [], from: T0, to: T0 + 1.hour),
      Ss::StateBandsComponent.new(rows: [luz, { label: "L2", segments: [] }], from: T0, to: T0 + 4.hours),
      Ss::StateBandsComponent.new(rows: []),
      Ss::LogbookComponent.new(entries: eventos, now: NOW, lazy: false, more_url: "/mais"),
      Ss::LogbookComponent.new(entries: eventos, now: NOW),
      Ss::LogbookComponent.new(entries: [], now: NOW),
      Ss::LogbookComponent.new(entries: eventos, now: NOW, error: nil, retry_url: "/r", loading: true),
      Ss::CameraTileComponent.new(title: "K", state: :stale, age: 90, retry_button: true),
      Ss::CameraTileComponent.new(title: "K", state: :error, retry_url: "/r"),
      Ss::CameraTileComponent.new(title: "K", state: :offline),
      Ss::CameraTileComponent.new(title: "K", state: :live),
      Ss::MediaPlayerComponent.new(state: :playing, title: "M", position: 10, duration: 100, volume: 0.5, play_url: "/p",
                                   pause_url: "/p", next_url: "/n", previous_url: "/v", volume_url: "/v", seek_url: "/s"),
      Ss::MediaPlayerComponent.new(state: :idle),
      Ss::MediaPlayerComponent.new(state: :unavailable),
      Ss::NoticeCardComponent.new(title: "N", dismiss_url: "/x"),
      Ss::MicButtonComponent.new(state: :listening),
      Ss::MicButtonComponent.new(state: :error),
      Ss::DPadComponent.new(url: "/tv", volume: true, channel: true, mute: true),
      Ss::WeatherCardComponent.new(temperature: 26, condition: :partly_cloudy, min: 18, max: 29, humidity: 80, wind: 12,
                                   forecast: [{ label: "1", condition: :storm, temp: 25, precip: 70 }]),
      Ss::ClockComponent.new(now: NOW, fixed: true),
      Ss::ScanRadarComponent.new(state: :searching),
      Ss::ScanRadarComponent.new(state: :empty, retry_url: "/r"),
      Ss::ScanRadarComponent.new(items: [{ label: "I1" }, { label: "I2" }]),
      Ss::IconPickerComponent.new(name: "i", icons: [["bulb", SVG]], allow_none: true),
      Ss::LocalePickerComponent.new(value: "en", name: "l"),
      Ss::LocalePickerComponent.new(value: nil, name: "l", system_option: true),
      Ss::NoticeCardComponent.new(title: "N", url: "/n", unread: true, footer: "F"),
      Ss::ScanRadarComponent.new(state: :empty, retry_url: "/r", compact: true),
      Ss::TimeSeriesChartComponent.new(title: "C", series: [serie], legend: :always, show_values: true),
      Ss::MediaPlayerComponent.new(state: :idle, power: false, power_url: "/p", volume: 0.2, mute_url: "/m", volume_up_url: "/u", volume_down_url: "/d"),
      Ss::WeatherCardComponent.new(temperature: 20, condition: :rain, rain_chance: 40, feels_like: 19),
      Ss::LogbookComponent.new(entries: eventos, now: NOW, end_url: "/h"),
      Ss::AgendaListComponent.new(days: [{ date: NOW.to_date, events: [] }, { date: NOW.to_date + 1, events: [] }], now: NOW, week_strip: true)
    ]
  end

  %i[en es].each do |loc|
    test "componentes v0.10 sem texto pt em #{loc}" do
      re = leaks(loc)
      # Controle: em pt-BR a mesma conta acha o texto pt.
      assert_match re, render_inline(Ss::DeviceTileComponent.new(name: "D", status: :unavailable)).to_html
      I18n.with_locale(loc) do
        renders.each do |c|
          html = render_inline(c).to_html
          refute html.match?(re), "#{c.class} em #{loc}: pt vazando (#{html[re]})"
        end
        html = render_inline(Ss::BlockListComponent.new(name: "b")) { |l| l.with_block(id: "a", title: "A", delete_url: "/a") }.to_html
        refute html.match?(re), "BlockList em #{loc}: pt vazando (#{html[re]})"
      end
    end
  end

  test "textos v0.10 mudam com o idioma" do
    I18n.with_locale(:en) do
      render_inline(Ss::DeviceTileComponent.new(name: "D", status: :unavailable))
      assert_selector ".ss-device-state", text: "Unavailable"
      render_inline(Ss::LogbookComponent.new(entries: [], now: NOW))
      assert_text "Nothing logged yet"
      render_inline(Ss::ThermostatComponent.new(target: 22.5, mode: "heat"))
      assert_text "Heat"
      assert_text "Cool"
      assert_text "22.5°"
      render_inline(Ss::WeekdayPickerComponent.new(name: "d"))
      assert_selector ".ss-weekday-day:first-child input[aria-label=Monday]"
      assert_selector ".ss-weekday-day:first-child span", text: "M"
      render_inline(Ss::ClockComponent.new(now: NOW, fixed: true))
      assert_selector ".ss-clock-date", text: "Wednesday, November 4", visible: :all
    end
    I18n.with_locale(:es) do
      render_inline(Ss::DeviceTileComponent.new(name: "D", status: :unavailable))
      assert_selector ".ss-device-state", text: "No disponible"
      render_inline(Ss::LogbookComponent.new(entries: [], now: NOW, lazy: false))
      assert_text "Aún no hay registros"
      render_inline(Ss::ThermostatComponent.new(target: 22.5, mode: "heat"))
      assert_text "Calor"
      assert_text "22,5°"
      render_inline(Ss::CodeKeypadComponent.new(error: true))
      assert_text "Código incorrecto"
      render_inline(Ss::WeekdayPickerComponent.new(name: "d"))
      assert_selector ".ss-weekday-day:nth-child(3) input[aria-label=Miércoles]"
      assert_selector ".ss-weekday-day:nth-child(3) span", text: "X"
      render_inline(Ss::ClockComponent.new(now: NOW, fixed: true))
      assert_selector ".ss-clock-date", text: "miércoles, 4 de noviembre", visible: :all
    end
  end
end
