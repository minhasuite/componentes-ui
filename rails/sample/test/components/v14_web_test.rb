require "test_helper"

# v0.14 · o que o minha-automacao pediu para não sobrar peça genérica no CSS do produto
# (par do SsNote, do SsTaskItem e do SsIconTile(image:); o resto é classe só do web).
class V14WebTest < ComponentTest
  CSS = Pathname(ComponentesUi::Engine.root).join("app/assets/tailwind/componentes_ui")
  SVG = %(<svg viewBox="0 0 24 24"><path d="M0 0h24v24"/></svg>).freeze

  test "nota: frase, ícone e tom" do
    render_inline(Ss::NoteComponent.new(text: "Nenhum alerta aberto", icon: SVG, tone: :success, css: "mt-2"))
    assert_selector "p.ss-note.mt-2[data-tone=success]:not([role])"
    assert_selector ".ss-note .ss-note-ico[aria-hidden=true] svg"
    assert_selector ".ss-note > span:last-child", text: "Nenhum alerta aberto"
    render_inline(Ss::NoteComponent.new(tone: :danger)) { "O robô parou" }
    assert_selector "p.ss-note[data-tone=danger][role=status]", text: "O robô parou"
    render_inline(Ss::NoteComponent.new(text: "Só texto", tone: :roxo))
    assert_selector "p.ss-note:not([data-tone])", text: "Só texto"
    assert_no_selector ".ss-note-ico"
  end

  test "css da v0.14 importado, com os tokens do card" do
    css = CSS.join("v14_web.css").read
    [".ss-note[data-tone=\"danger\"]", ".ss-btn.is-on-grad", "button.ss-item", ".ss-icon-tile.is-heat", ".ss-icon-tile > img",
     ".is-flush", ".ss-cam-actions > [aria-pressed=\"true\"]", ".ss-label-chip", "--ss-bars-h", ".ss-bar.is-empty",
     ".ss-checklist [role=\"checkbox\"]", ".ss-checklist-x", ".ss-swatch > input", "--ss-swatch-wall"].each { assert_includes css, _1 }
    engine = CSS.join("engine.css").read
    assert_includes engine, '@import "./v14_web.css";'
    assert_includes engine, "var(--ss-card-bg, var(--surface))"
    assert_includes CSS.join("v10_controles.css").read, "var(--ss-card-filter, none)"
  end

  test "v0.14.1: rótulo com ícone, painel rebaixado e quadro de arrastar" do
    css = CSS.join("v14_web.css").read
    [".ss-label:has(> svg)", ".ss-value-row > :first-child:has(> svg)", ".ss-card.is-soft", ".ss-kanban.is-wrap",
     ".ss-kanban-col", ".ss-kanban-col.is-over", ".ss-kanban-head", ".ss-kanban-card", ".ss-kanban-card.is-dragging"].each { assert_includes css, _1 }
  end

  test "v0.14.1: icon: no slider padrão e no campo −/+" do
    render_inline(Ss::RangeComponent.new(name: "b", label: "Brilho", icon: SVG))
    assert_selector ".ss-range-head > label svg"
    assert_selector ".ss-range-head > label", text: "Brilho"
    render_inline(Ss::StepperInputComponent.new(name: "t", label: "Alvo", icon: SVG))
    assert_selector "label.ss-label svg"
    assert_selector "label.ss-label", text: "Alvo"
    render_inline(Ss::StepperInputComponent.new(name: "t", label: "Sem"))
    assert_no_selector "label.ss-label svg"
  end

  test "player e etapas sem moldura pelo css:" do
    render_inline(Ss::MediaPlayerComponent.new(title: "Aquarela", state: :playing, css: "is-flush"))
    assert_selector ".ss-card.ss-media.is-flush"
    render_inline(Ss::JobProgressComponent.new(id: "j", title: "Importando", state: :running, css: "is-flush"))
    assert_selector ".ss-job.is-flush"
  end
end
