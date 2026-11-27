require "test_helper"

# A vitrine por categoria de uso (as mesmas do app, flutter/example/lib/categorias.dart).
# Página nova com grupo fora de VitrineController::GRUPOS falha aqui: nenhuma fica fora do menu.
class VitrineTest < ActionDispatch::IntegrationTest
  PAGINAS = VitrineController.paginas

  test "toda página está num grupo do menu (e os 'tambem' também existem)" do
    PAGINAS.each do |p|
      p[:grupos].each { |g| assert_includes VitrineController::GRUPOS, g, "#{p[:slug]}: grupo #{g.inspect} fora de GRUPOS" }
    end
  end

  test "as categorias são as do app, na mesma ordem, e nenhuma fica vazia" do
    nomes = ["Novidades (v#{VitrineController::NOVIDADES})", "Fundação", "Navegação e moldura", "Ações e botões",
             "Formulários e entrada", "Listas e tabelas", "Dados e gráficos", "Cards e painéis", "Retorno e estados",
             "Movimento e transições", "Conversa, IA e avisos", "Tempo e agenda", "Casa e automação",
             "Comércio e finanças", "Mídia e captura", "Telas montadas"]
    assert_equal nomes, VitrineController::CATEGORIAS.map { _1[:nome] }
    nomes.each { |g| assert PAGINAS.any? { _1[:grupos].include?(g) }, "#{g} sem página" }
  end

  test "páginas da onda atual entram em Novidades" do
    novas = PAGINAS.select { _1[:grupos].include?(VitrineController::GRUPO_NOVIDADES) }.map { _1[:slug] }
    assert_includes novas, "pecas_v1120"
    refute_includes novas, "pecas_v1110"
  end

  test "início mostra a suíte, o app, o APK e a grade das categorias" do
    get "/"
    assert_response :success
    assert_select "a[href='/app/']", text: /Ver a vitrine do app/
    assert_select "a[href='/componentes-demo.apk']", text: /Baixar o APK/
    assert_select "a[href^='https://www.minhasuite.com/']", minimum: 5
    assert_select ".vt-cat", VitrineController::CATEGORIAS.size
    assert_match ComponentesUi::VERSION, response.body
  end

  test "toda página abre e o menu tem o link de todas" do
    PAGINAS.each do |p|
      get vitrine_path(p[:slug])
      assert_response :success, p[:slug]
    end
    PAGINAS.each { |p| assert_select "a[href='#{vitrine_path(p[:slug])}']", { minimum: 1 }, "#{p[:slug]} fora do menu" }
  end
end
