# Gera o estado "sem-dados-zero" do Ss::BarChartComponent no catálogo (rails/catalogo/index.html), v1.14.7: tudo zero
# (7 dias sem uso) é o vazio de sempre. Entra na <section data-comp="ss-barc">, depois do estado "agrupado".
#   bin/rails runner script/catalogo_v1147.rb > /tmp/v1147.html
include ComponentesUi::Helpers
require "action_dispatch/testing/test_request"
CTRL = ApplicationController.new.tap { |c| c.request = ActionDispatch::TestRequest.create("PATH_INFO" => "/vitrine/x"); c.response = ActionDispatch::Response.new }
def view = (@view ||= CTRL.view_context)
def clean(html) = html.to_s.gsub(/<!-- (BEGIN|END) [^>]*-->/, "").gsub(/\n\s*/, "").gsub(/ss-[a-z]+-\d{4,}/) { |m| m.sub(/\d+\z/, "cat") }
def r(c, &blk) = clean(view.render(c, &blk))

bar = r(Ss::BarChartComponent.new(title: "Uso por dia", labels: %w[seg ter qua qui sex sáb dom], show_title: true,
                                  series: [{ name: "Uso", values: [0] * 7 }], empty: "Sem uso nesta semana"))
print %(  <div data-estado="sem-dados-zero" data-titulo="sem dados (tudo zero: 7 dias sem uso)"><div class="ss-card ss-card-pad" style="width:430px">#{bar}</div></div>\n)
