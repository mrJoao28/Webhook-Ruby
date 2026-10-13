require "test_helper"

class CapturesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @endpoint = endpoints(:one)
    @url = hook_url(token: @endpoint.token)
  end

  test "captura POST com JSON" do
    assert_difference -> { @endpoint.captured_requests.count }, 1 do
      post @url, params: { evento: "teste", valor: 42 }, as: :json
    end

    assert_response :ok
    captured = @endpoint.captured_requests.last
    assert_equal "POST", captured.http_method
    assert_equal({ "evento" => "teste", "valor" => 42 }, JSON.parse(captured.body))
    assert_equal "application/json", captured.content_type
  end

  test "captura query params em GET" do
    get hook_url(token: @endpoint.token, a: "1", b: "2")

    captured = @endpoint.captured_requests.last
    assert_equal "GET", captured.http_method
    assert_equal({ "a" => "1", "b" => "2" }, captured.query_params)
  end

  %i[get post put patch delete].each do |verb|
    test "aceita o verbo #{verb.to_s.upcase}" do
      public_send(verb, @url)

      assert_response :ok
      assert_equal verb.to_s.upcase, @endpoint.captured_requests.last.http_method
    end
  end

  test "guarda os headers enviados" do
    post @url, headers: { "X-Meu-Header" => "ola" }

    assert_equal "ola", @endpoint.captured_requests.last.headers["X-Meu-Header"]
  end

  test "responde 404 e não grava nada para token inexistente" do
    assert_no_difference "CapturedRequest.count" do
      post hook_url(token: "inexistente")
    end

    assert_response :not_found
  end

  test "corta corpos maiores que o limite" do
    post @url, params: "x" * 150_000, headers: { "CONTENT_TYPE" => "text/plain" }

    assert_response :ok
    assert_equal CapturesController::MAX_BODY, @endpoint.captured_requests.last.body.length
  end
end