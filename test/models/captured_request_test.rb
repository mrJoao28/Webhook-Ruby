require "test_helper"

class CapturedRequestTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  test "pretty_body indenta JSON" do
    captured = CapturedRequest.new(body: '{"a":1}')
    assert_equal "{\n  \"a\": 1\n}", captured.pretty_body
  end

  test "pretty_body devolve o texto original quando não é JSON" do
    captured = CapturedRequest.new(body: "texto puro")
    assert_equal "texto puro", captured.pretty_body
  end

  test "pretty_body aceita corpo nulo" do
    assert_nil CapturedRequest.new(body: nil).pretty_body
  end

  test "criar uma requisição transmite para o canal do endpoint" do
    endpoint = endpoints(:one)

    assert_turbo_stream_broadcasts endpoint, count: 1 do
      endpoint.captured_requests.create!(
        http_method: "GET", headers: {}, query_params: {}, ip: "127.0.0.1"
      )
    end
  end
end