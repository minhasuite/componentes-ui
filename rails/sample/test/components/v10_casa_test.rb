require "test_helper"

# v0.10 (casa): câmera, player, aviso com ações, microfone, fluxo de energia, controle remoto,
# clima, relógio e radar de busca.
class V10CasaTest < ComponentTest
  test "câmera: estados por data-state, selo, idade, retry e slots" do
    render_inline(Ss::CameraTileComponent.new(title: "Garagem", image_url: "/snap.jpg")) do |c|
      c.with_action { "<button class='x'>Tela cheia</button>".html_safe }
    end
    assert_selector "figure.ss-cam[data-state=live][data-controller~=ss-camera][aria-label='Garagem, AO VIVO']"
    assert_selector ".ss-cam-frame img[src='/snap.jpg']"
    assert_selector ".ss-cam-live", text: "AO VIVO"
    assert_selector ".ss-cam-actions button.x"

    render_inline(Ss::CameraTileComponent.new(title: "Quintal", state: :stale, age: 12)) { |c| c.with_frame { "<video></video>".html_safe } }
    assert_selector ".ss-cam[data-state=stale][data-ss-camera-age-value='12'] .ss-cam-frame video"
    assert_selector ".ss-cam-age [data-ss-camera-target=age]", text: "há 12 s"
    render_inline(Ss::CameraTileComponent.new(title: "X", state: :stale, age: 185))
    assert_selector ".ss-cam-age", text: "há 3 min"

    render_inline(Ss::CameraTileComponent.new(title: "Portão", state: :offline, retry_url: "/cam/1/retry"))
    assert_selector ".ss-cam[data-state=offline] form[action='/cam/1/retry'] button.ss-cam-retry", text: "Tentar de novo"
    render_inline(Ss::CameraTileComponent.new(title: "Portão", state: :error, retry_button: true, labels: { retry: "Retry" }))
    assert_selector "button.ss-cam-retry[data-action='ss-camera#retry']", text: "Retry"
    render_inline(Ss::CameraTileComponent.new(title: "Y", state: :nope))
    assert_selector ".ss-cam[data-state=live]"
  end

  test "player: comandos com button_to, tempos e estados" do
    render_inline(Ss::MediaPlayerComponent.new(title: "Águas de Março", subtitle: "Elis", state: :playing, position: 97, duration: 212,
                                               volume: 0.45, source: "Spotify · Sala", play_url: "/m/play", pause_url: "/m/pause",
                                               next_url: "/m/next", volume_url: "/m/vol"))
    assert_selector ".ss-media[data-state=playing][data-ss-media-playing-value=true]"
    assert_selector "form[action='/m/pause'] button.ss-media-play[aria-label=Pausar]"
    assert_selector "form[action='/m/next'] button[aria-label='Próxima']"
    assert_selector "button.ss-media-btn[disabled][aria-label=Anterior]"
    assert_selector ".ss-media-times", text: "1:37"
    assert_selector ".ss-media-times", text: "3:32"
    assert_selector "form[action='/m/vol'] input[type=range][name=volume][value='45'][aria-label=Volume]"
    assert_selector ".ss-media-src", text: "Spotify · Sala"
    assert_equal "1:02:03", Ss::MediaPlayerComponent.fmt(3723)

    render_inline(Ss::MediaPlayerComponent.new(state: :idle, play_url: "/m/play"))
    assert_selector ".ss-media-title", text: "Nada tocando"
    render_inline(Ss::MediaPlayerComponent.new(state: :buffering, title: "Rádio"))
    assert_selector "button.ss-media-play.is-buffering[disabled][aria-label=Carregando] .ss-media-spin"
    render_inline(Ss::MediaPlayerComponent.new(state: :unavailable, play_url: "/m/play", next_url: "/m/next"))
    assert_selector ".ss-media[data-state=unavailable] .ss-media-title", text: "Indisponível"
    assert_no_selector "form[action='/m/play']"
    assert_no_selector "form[action='/m/next']"
  end

  test "aviso: tom, ações (1ª cheia), hora e dispensar" do
    render_inline(Ss::NoticeCardComponent.new(title: "Porta aberta", text: "Há 10 min", tone: :warn, time: "14:32",
                                              actions: [{ label: "Fechar", url: "/fechar" }, { label: "Ver", url: "/ver", method: :get }],
                                              dismiss_url: "/aviso/1"))
    assert_selector ".ss-notice[data-tone=warn][role=status]"
    assert_selector "form[action='/fechar'] button.ss-btn-primary", text: "Fechar"
    assert_selector "a.ss-btn-ghost[href='/ver']", text: "Ver"
    assert_selector "time.ss-notice-time", text: "14:32"
    assert_selector "form[action='/aviso/1'] input[name=_method][value=delete]", visible: :all
    assert_selector "form[action='/aviso/1'] button.ss-notice-x[aria-label=Dispensar]"
    render_inline(Ss::NoticeCardComponent.new(title: "Vazamento", tone: :critical, dismissible: true))
    assert_selector ".ss-notice[data-tone=critical][role=alert][data-controller=ss-notice] button.ss-notice-x[data-action='ss-notice#dismiss']"
    render_inline(Ss::NoticeCardComponent.new(title: "Ok", tone: :success))
    assert_no_selector ".ss-notice-x"
    assert_no_selector ".ss-notice-actions"
  end

  test "aviso v0.10.1: card-link, imagem, não lido e rodapé (texto e slot)" do
    render_inline(Ss::NoticeCardComponent.new(title: "Encomenda", text: "Chegou na portaria", url: "/avisos/9", unread: true,
                                              image_url: "/foto.jpg", image_alt: "Pacote", footer: "Respondido: Sim",
                                              actions: [{ label: "Ok", url: "/ok" }], dismiss_url: "/avisos/9"))
    assert_selector ".ss-notice.is-link.is-unread"
    assert_selector ".ss-notice-head .ss-notice-dot + .ss-notice-title a.ss-notice-link[href='/avisos/9']", text: "Encomenda"
    assert_selector ".ss-notice-title .ss-sr", text: "não lido", visible: :all
    assert_selector "img.ss-notice-img[src='/foto.jpg'][alt=Pacote][loading=lazy]"
    assert_selector ".ss-notice-foot", text: "Respondido: Sim"
    # Nada interativo dentro do link: ações e dispensar ficam fora dele.
    assert_no_selector "a.ss-notice-link a, a.ss-notice-link button, a.ss-notice-link form"
    assert_selector ".ss-notice-actions form[action='/ok'] button"
    assert_selector "form[action='/avisos/9'] button.ss-notice-x"

    render_inline(Ss::NoticeCardComponent.new(title: "Pergunta", footer: "ignorado")) { |n| n.with_footer { "<b>Confirmado</b>".html_safe } }
    assert_selector ".ss-notice-foot b", text: "Confirmado"
    assert_no_text "ignorado"
    assert_no_selector ".ss-notice.is-link, .ss-notice.is-unread, .ss-notice-dot, .ss-notice-img, a.ss-notice-link"
    render_inline(Ss::NoticeCardComponent.new(title: "Sem nada"))
    assert_no_selector ".ss-notice-foot"
  end

  test "microfone: estado, nível e rótulos" do
    render_inline(Ss::MicButtonComponent.new(state: :listening, level: 0.6, size: 64))
    assert_selector ".ss-mic[data-controller=ss-mic][data-ss-mic-state-value=listening][style*='--level: 0.6'][style*='--size: 64px']"
    assert_selector "button.ss-mic-btn[aria-label='Ouvindo, toque para parar'][data-action='ss-mic#press'] .ss-mic-ring", count: 3
    render_inline(Ss::MicButtonComponent.new(state: :processing, labels: { processing: "Thinking" }))
    assert_selector ".ss-mic[data-state=processing] button[aria-label=Thinking] .ss-mic-arc"
    labels = JSON.parse(page.find(".ss-mic")["data-ss-mic-labels-value"])
    assert_equal "Falar", labels["idle"]
    render_inline(Ss::MicButtonComponent.new(state: :bogus, level: 7))
    assert_selector ".ss-mic[data-state=idle][style*='--level: 1.0']"
  end

  test "fluxo de energia: nós, ligações no sentido da energia, parado" do
    c = { id: :casa, kind: :home, label: "Casa", value: "2,4 kW" }
    around = [{ id: :solar, kind: :solar, label: "Solar", value: "3,8 kW" }, { id: :rede, kind: :grid, label: "Rede", value: "1,4 kW" },
              { id: :bat, kind: :battery, label: "Bateria", value: "1 kW", caption: "72%" }]
    render_inline(Ss::FlowDiagramComponent.new(center: c, around:, links: [{ from: :solar, to: :casa, power: 3800 },
                                                                            { from: :casa, to: :rede, power: -1400 },
                                                                            { from: :bat, to: :casa, power: 0 }]))
    assert_selector ".ss-flow[role=img]:not(.is-static)"
    assert_selector ".ss-flow-node", count: 4
    assert_selector ".ss-flow-node.is-center[data-kind=home]", text: "2,4 kW"
    assert_selector ".ss-flow-node[data-kind=battery]", text: "Bateria · 72%"
    assert_selector ".ss-flow-link.is-on", count: 2
    assert_selector ".ss-flow-link.is-on .ss-flow-dot", count: 6
    assert_selector ".ss-flow-link:not(.is-on) line", count: 1
    assert_includes page.find(".ss-flow")["aria-label"], "Casa 2,4 kW"
    # power negativo: a energia vai de rede para casa, então a cor é a da rede.
    styles = page.all(".ss-flow-link.is-on").map { |g| g["style"] }
    assert_includes styles, "--c: var(--ss-info)"
    # Mais potência, mais rápido.
    durs = page.all(".ss-flow-link.is-on").map { |g| g.first(".ss-flow-dot")["style"][/--dur: ([\d.]+)s/, 1].to_f }
    assert_operator durs[0], :<, durs[1]

    render_inline(Ss::FlowDiagramComponent.new(center: c, around:, links: [{ from: :solar, to: :casa, power: 100 }], animate: false))
    assert_selector ".ss-flow.is-static .ss-flow-arrow"
  end

  test "controle remoto: teclas com button_to, gangorras e sem url" do
    render_inline(Ss::DPadComponent.new(url: "/tv/remoto", volume: true, channel: true))
    assert_selector ".ss-dpad[data-controller=ss-dpad][tabindex='0'][role=group]"
    assert_selector "form[action='/tv/remoto'] input[name=key][value=up]", visible: :all
    assert_selector "form[action='/tv/remoto'] button.ss-dpad-key.is-ok[aria-label=OK]", text: "OK"
    assert_selector "button[data-key=volume_up][aria-label='Aumentar volume']"
    assert_selector "button[data-key=channel_down]"
    assert_selector "button.ss-dpad-key", count: 12
    render_inline(Ss::DPadComponent.new(disabled: true, labels: { up: "Up" }))
    assert_selector ".ss-dpad.is-disabled button[data-key=up][aria-label=Up][disabled][data-action='ss-dpad#press']"
    assert_no_selector "form"
    assert_no_selector ".ss-dpad-rocker"
  end

  test "clima: dados, ícones e previsão" do
    render_inline(Ss::WeatherCardComponent.new(temperature: 26.6, condition: :rain, location: "SP", min: 18, max: 29, humidity: 80, wind: 12,
                                               forecast: [{ label: "Ter", condition: :clear, temp: 30, min: 20 },
                                                          { label: "15h", condition: :storm, temp: 22, precip: 70 }]))
    assert_selector ".ss-wx[data-condition=rain] .ss-wx-temp", text: "27°"
    assert_selector ".ss-wx-cond", text: "Chuva"
    assert_selector ".ss-wx-minmax", text: "Máx 29°  ·  Mín 18°"
    assert_selector ".ss-wx-pills li", text: "80%"
    assert_selector ".ss-wx-pills li", text: "12 km/h"
    assert_selector ".ss-wx-strip li[aria-label='Ter, Céu limpo, 30° / 20°']"
    assert_selector ".ss-wx-strip li[aria-label='15h, Tempestade, 22°, 70%'] small.is-rain", text: "70%"
    assert_selector "svg.ss-wx-ico", count: 3
    render_inline(Ss::WeatherCardComponent.new(temperature: 10, condition: :tornado, condition_text: "Estranho"))
    assert_selector ".ss-wx[data-condition=cloudy] .ss-wx-cond", text: "Estranho"
  end

  test "relógio: hora, data em pt-BR, segundos e fixo" do
    now = Time.new(2026, 11, 4, 9, 5, 4)
    render_inline(Ss::ClockComponent.new(now:, seconds: true))
    assert_selector ".ss-clock.is-seconds[data-controller=ss-clock][role=timer]"
    assert_selector "[data-ss-clock-target=h]", text: "09"
    assert_selector "[data-ss-clock-target=m]", text: "05"
    assert_selector ".ss-clock-dot[data-on=true]"
    assert_selector ".ss-clock-date", text: "quarta-feira, 4 de novembro"
    render_inline(Ss::ClockComponent.new(now: Time.new(2026, 11, 4, 21, 5), hour12: true, date: false, fixed: true))
    assert_no_selector "[data-controller]"
    assert_selector "[data-ss-clock-target=h]", text: "9"
    assert_selector ".ss-clock-ampm", text: "PM"
    assert_no_selector ".ss-clock-date"
  end

  test "radar: procurando, achou N, nada com retry" do
    render_inline(Ss::ScanRadarComponent.new(items: [{ label: "Lâmpada" }]))
    assert_selector ".ss-radar[data-state=searching] .ss-radar-wave", count: 3
    assert_selector ".ss-radar-status[role=status]", text: "Procurando…"
    assert_selector ".ss-radar-chip", text: "Lâmpada"
    render_inline(Ss::ScanRadarComponent.new(state: :found, items: [{ label: "A", url: "/a" }, { label: "B" }, { label: "C" }]))
    assert_no_selector ".ss-radar-wave"
    assert_selector ".ss-radar-status", text: "3 encontrados"
    assert_selector "a.ss-radar-chip[href='/a']"
    render_inline(Ss::ScanRadarComponent.new(state: :found, items: [{ label: "A" }]))
    assert_selector ".ss-radar-status", text: "1 encontrado"
    render_inline(Ss::ScanRadarComponent.new(state: :empty, retry_url: "/buscar"))
    assert_selector ".ss-radar[data-state=empty] .ss-radar-status", text: "Nada encontrado"
    assert_selector "form[action='/buscar'] button", text: "Procurar de novo"
  end

  test "radar compacto: em linha, 72 px e achados em fila ao lado" do
    render_inline(Ss::ScanRadarComponent.new(compact: true, items: [{ label: "Lâmpada" }, { label: "Tomada" }]))
    assert_selector ".ss-radar.is-compact[style*='--size: 72px'][data-state=searching]"
    assert_selector ".ss-radar-side .ss-radar-status", text: "Procurando…"
    assert_selector ".ss-radar-side .ss-radar-items .ss-radar-chip", count: 2
    assert_no_selector ".ss-radar-field .ss-radar-items"
    render_inline(Ss::ScanRadarComponent.new(compact: true, size: 96, state: :empty, retry_url: "/b"))
    assert_selector ".ss-radar.is-compact[style*='--size: 96px'] .ss-radar-side form[action='/b'] button", text: "Procurar de novo"
    render_inline(Ss::ScanRadarComponent.new(items: [{ label: "A" }]))
    assert_selector ".ss-radar[style*='--size: 240px'] .ss-radar-field .ss-radar-items"
    assert_no_selector ".ss-radar-side, .ss-radar.is-compact"
  end
  test "player v0.10.1: liga/desliga, volume_param, −/+ de volume, mudo e o slot do que tocar" do
    render_inline(Ss::MediaPlayerComponent.new(title: "T", state: :idle, power: false, power_url: "/p", volume: 0.3, volume_url: "/v",
                                               volume_param: "value", volume_up_url: "/up", volume_down_url: "/down",
                                               mute_url: "/mute", muted: true)) { |m| m.with_media_picker { "<ul class='fontes'></ul>".html_safe } }
    assert_selector "form[action='/p'] button.ss-media-power[aria-pressed=false][aria-label=Ligar]"
    assert_selector "form[action='/v'] input[type=range][name=value]"
    assert_selector "form[action='/up'] button[aria-label='Aumentar volume']"
    assert_selector "form[action='/down'] button[aria-label='Diminuir volume']"
    assert_selector "form[action='/mute'] button.ss-media-mute.is-on[aria-pressed=true][aria-label='Tirar do mudo']"
    assert_selector ".ss-media-picker ul.fontes"
    render_inline(Ss::MediaPlayerComponent.new(state: :playing, title: "T", power: true, power_url: "/p", volume: 0.5, volume_url: "/v"))
    assert_selector "button.ss-media-power.is-on[aria-label=Desligar]"
    assert_selector "input[type=range][name=volume]"
    render_inline(Ss::MediaPlayerComponent.new(state: :unavailable, power: true, power_url: "/p"))
    assert_selector "button.ss-media-power[disabled]"
    render_inline(Ss::MediaPlayerComponent.new(state: :idle))
    assert_no_selector ".ss-media-power, .ss-media-vol, .ss-media-picker"
  end

  test "controle v0.10.1: sem a linha de navegação, keys: e extra_buttons:" do
    render_inline(Ss::DPadComponent.new(url: "/tv", nav_row: false, keys: { ok: "select" },
                                        extra_buttons: [{ name: "netflix", label: "Netflix" }, { label: "sem nome" }]))
    assert_no_selector "[data-key=back], [data-key=home], [data-key=menu]"
    assert_selector "form[action='/tv'] input[name=key][value=select]", visible: :all
    assert_selector "button[data-key=ok][data-value=select]"
    assert_selector "form input[name=key][value=up]", visible: :all
    assert_selector ".ss-dpad-row.is-extra button.is-extra[data-value=netflix]", text: "Netflix", count: 1
    assert_selector "form input[name=key][value=netflix]", visible: :all
    render_inline(Ss::DPadComponent.new(nav_row: false, mute: true))
    assert_selector ".ss-dpad-row.is-nav [data-key=mute]"
    assert_no_selector "[data-key=home]"
  end

  test "clima v0.10.1: chance de chuva de agora, sensação e chuva no diário" do
    render_inline(Ss::WeatherCardComponent.new(temperature: 24, condition: :rain, rain_chance: 80, feels_like: 26, max: 27,
                                               forecast: [{ label: "Ter", condition: :rain, temp: 25, min: 18, rain_chance: 60 }]))
    assert_selector ".ss-wx-cond .ss-wx-rain svg"
    assert_selector ".ss-wx-rain", text: "80%"
    assert_selector ".ss-wx-now[aria-label*='Chance de chuva 80%']"
    assert_selector ".ss-wx-minmax", text: "Sensação 26°"
    assert_selector ".ss-wx-strip li small.is-rain svg"
    assert_selector ".ss-wx-strip li small.is-rain", text: "60%"
  end

  test "relógio v0.10.1: segundos em dígitos e fit" do
    render_inline(Ss::ClockComponent.new(now: Time.zone.local(2026, 11, 4, 14, 32, 7), seconds: :digits, fit: true, fixed: true))
    assert_selector ".ss-clock.is-fit.is-digits .ss-clock-sec", text: "07"
    assert_no_selector ".ss-clock-dot"
    assert_selector ".ss-clock[aria-label^='14:32:07']"
    render_inline(Ss::ClockComponent.new(now: Time.zone.local(2026, 11, 4, 14, 32, 8), seconds: true, fixed: true))
    assert_selector ".ss-clock-dot"
    assert_no_selector ".ss-clock-sec, .ss-clock.is-fit"
  end
end
