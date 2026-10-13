require "test_helper"

class EndpointsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @endpoint = endpoints(:one)
  end

  test "lista endpoints" do
    get endpoints_url
    assert_response :success
  end

  test "mostra o formulário de novo endpoint" do
    get new_endpoint_url
    assert_response :success
  end

  test "cria endpoint e gera o token" do
    assert_difference("Endpoint.count", 1) do
      post endpoints_url, params: { endpoint: { name: "Meu webhook" } }
    end

    criado = Endpoint.find_by!(name: "Meu webhook")
    assert_redirected_to endpoint_url(criado)
    assert criado.token.present?
  end

  test "ignora token enviado pelo formulário" do
    post endpoints_url, params: { endpoint: { name: "Esperto", token: "hackeado" } }

    assert_not_equal "hackeado", Endpoint.find_by!(name: "Esperto").token
  end

  test "não cria endpoint sem nome" do
    assert_no_difference("Endpoint.count") do
      post endpoints_url, params: { endpoint: { name: "" } }
    end

    assert_response 422
  end

  test "mostra o detalhe com as requisições capturadas" do
    get endpoint_url(endpoints(:two))

    assert_response :success
    assert_select ".capture", 1
  end

  test "escapa HTML do corpo capturado" do
    @endpoint.captured_requests.create!(
      http_method: "POST", headers: {}, query_params: {}, ip: "127.0.0.1",
      body: "<script>alert(1)</script>"
    )

    get endpoint_url(@endpoint)

    assert_includes response.body, "&lt;script&gt;"
    assert_not_includes response.body, "<script>alert(1)</script>"
  end

  test "mostra o formulário de edição" do
    get edit_endpoint_url(@endpoint)
    assert_response :success
  end
  test "exige senha quando ADMIN_PASSWORD está definida" do
  ENV["ADMIN_PASSWORD"] = "segredo"

  get endpoints_url
  assert_response :unauthorized

  credenciais = ActionController::HttpAuthentication::Basic.encode_credentials("admin", "segredo")
  get endpoints_url, headers: { "Authorization" => credenciais }
  assert_response :success
ensure
  ENV.delete("ADMIN_PASSWORD")
end

  test "atualiza o endpoint" do
    patch endpoint_url(@endpoint), params: { endpoint: { name: "Renomeado" } }

    assert_redirected_to endpoint_url(@endpoint)
    assert_equal "Renomeado", @endpoint.reload.name
  end

  test "apaga o endpoint" do
    assert_difference("Endpoint.count", -1) do
      delete endpoint_url(@endpoint)
    end

    assert_redirected_to endpoints_url
  end
end