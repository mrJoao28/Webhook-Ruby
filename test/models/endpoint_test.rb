require "test_helper"

class EndpointTest < ActiveSupport::TestCase
  test "gera token automaticamente" do
    endpoint = Endpoint.create!(name: "Novo")
    assert endpoint.token.present?
  end

  test "exige nome" do
    endpoint = Endpoint.new(name: "")
    assert_not endpoint.valid?
    assert endpoint.errors.of_kind?(:name, :blank)
  end

  test "apagar endpoint apaga as requisições capturadas" do
    endpoint = endpoints(:two)
    assert_difference "CapturedRequest.count", -endpoint.captured_requests.count do
      endpoint.destroy
    end
  end
end