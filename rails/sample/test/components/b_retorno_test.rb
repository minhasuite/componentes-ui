require "test_helper"

class BRetornoTest < ComponentTest
  test "toast e pilha (com atalho de turbo stream)" do
    render_inline(Ss::ToastStackComponent.new(toasts: [{ message: "Salvo", tone: :good }]))
    assert_selector "#ss-toasts.ss-toasts[aria-live=polite] .ss-toast.is-good[role=status][data-controller=ss-toast]", text: "Salvo"
    render_inline(Ss::ToastComponent.new(message: "Excluído", undo_url: "/desfazer", duration: 7))
    assert_selector ".ss-toast .ss-toast-timer", text: "7"
    assert_selector ".ss-toast form[action='/desfazer'] button", text: "Desfazer"
    assert_selector ".ss-toast[data-ss-toast-duration-value='7000']"
    render_inline(Ss::ToastComponent.new(message: "Falhou", tone: :bad))
    assert_selector ".ss-toast.is-bad[role=alert]"
    stream = Struct.new(:calls) { def append(target, c) = (calls << [target, c]) }.new([])
    Ss::ToastStackComponent.append(stream, message: "Oi")
    assert_equal "ss-toasts", stream.calls[0][0]
    assert_kind_of Ss::ToastComponent, stream.calls[0][1]
  end

  test "exclusão confirmada: dialog danger com botão travado" do
    render_inline(Ss::ConfirmDangerComponent.new(name: "Mercado", url: "/clientes/1", title: "Excluir?"))
    assert_selector "[data-controller=ss-confirm][data-ss-confirm-name-value=Mercado]"
    assert_selector "dialog.ss-dialog.is-danger h2", text: "Excluir?", visible: :all
    assert_selector "dialog form[action='/clientes/1'] input[name=_method][value=delete]", visible: :all
    assert_selector "dialog button[type=submit][disabled]", visible: :all
  end

  test "esqueleto por forma e como turbo-frame lazy" do
    render_inline(Ss::SkeletonComponent.new(shape: :table, rows: 3, cols: 4))
    assert_selector ".ss-skel.is-table[role=status][aria-busy=true] .ss-skel-row", count: 4
    render_inline(Ss::SkeletonComponent.new(shape: :list, rows: 2, frame: { id: "f", src: "/ultimos" }))
    assert_selector "turbo-frame#f[loading=lazy][src='/ultimos'] .ss-skel.is-list .ss-skel-item", count: 2
  end

  test "job: estados" do
    render_inline(Ss::JobProgressComponent.new(id: "j", title: "Importação", state: :running, progress: 0.42, steps: %w[Ler Validar Gravar], current_step: 1))
    assert_selector "#j.ss-job[data-state=running] [role=progressbar][aria-valuenow='42']"
    assert_selector ".ss-job-steps li.is-done", text: "Ler"
    assert_selector ".ss-job-steps li.is-current", text: "Validar"
    render_inline(Ss::JobProgressComponent.new(id: "j", title: "x", state: :queued))
    assert_selector ".ss-job-bar.is-indet"
    render_inline(Ss::JobProgressComponent.new(id: "j", title: "x", state: :done, result_url: "/r"))
    assert_selector "a[href='/r']", text: "Abrir resultado"
    render_inline(Ss::JobProgressComponent.new(id: "j", title: "x", state: :failed, error: "Arquivo vazio"))
    assert_selector ".ss-job-error", text: "Arquivo vazio"
    assert_no_selector "[role=progressbar]"
  end

  test "vazio ilustrado: variantes e ações" do
    render_inline(Ss::EmptyStateComponent.new(variant: :busca, title: "Nada", text: "Tire filtros", primary: { label: "Limpar", url: "?" }))
    assert_selector ".ss-empty-state[data-variant=busca] .ss-empty-art svg"
    assert_selector "h3", text: "Nada"
    assert_selector "a.ss-btn-primary[href='?']", text: "Limpar"
    render_inline(Ss::EmptyStateComponent.new(variant: :erro, title: "Erro"))
    assert_selector ".ss-empty-state[role=alert]"
  end

  test "popover, tooltip, tour, novidades e atalhos" do
    render_inline(Ss::PopoverComponent.new(label: "Ajuda", id: "p1", title: "Título")) { "Corpo" }
    assert_selector "button[popovertarget=p1]", text: "Ajuda"
    assert_selector "div#p1[popover=auto].ss-popover", text: "Corpo", visible: :all

    render_inline(Ss::TooltipComponent.new(text: "Exportar")) { "<button>x</button>".html_safe }
    assert_selector ".ss-tooltip-host[data-controller=ss-tooltip] [role=tooltip]", text: "Exportar", visible: :all

    render_inline(Ss::TourComponent.new(id: "t1", steps: [{ target: "a", title: "A" }]))
    assert_selector "[data-controller=ss-tour][data-ss-tour-key-value='ss-tour:t1']"
    assert_selector ".ss-tour-layer[hidden] [role=dialog]", visible: :all

    render_inline(Ss::WhatsNewComponent.new(id: "fin", items: [{ id: "n1", date: Date.new(2026, 11, 4), title: "IA" }]))
    assert_selector "button.ss-wn-bell[popovertarget=ss-wn-fin]"
    assert_selector "li[data-id=n1] time[datetime='2026-11-04']", visible: :all

    c = Ss::ShortcutsComponent.new(groups: [{ title: "Ir para", items: [{ keys: "g p", label: "Pedidos", url: "/p" }, { keys: "/", label: "Buscar" }] }])
    render_inline(c)
    assert_equal [{ keys: "g p", url: "/p" }], c.bindings
    assert_selector "dialog.ss-sc-dialog kbd.ss-kbd", text: "g", visible: :all
    assert_selector "[data-action*='keydown@document->ss-shortcuts#key']"
  end
end
