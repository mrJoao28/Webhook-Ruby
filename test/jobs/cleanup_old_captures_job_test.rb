require "test_helper"

class CleanupOldCapturesJobTest < ActiveJob::TestCase
  test "apaga só as requisições com mais de 7 dias" do
    endpoint = endpoints(:one)
    dados = { http_method: "GET", headers: {}, query_params: {}, ip: "127.0.0.1" }

    antiga  = endpoint.captured_requests.create!(dados.merge(created_at: 8.days.ago))
    recente = endpoint.captured_requests.create!(dados.merge(created_at: 1.day.ago))

    CleanupOldCapturesJob.perform_now

    assert_not CapturedRequest.exists?(antiga.id)
    assert CapturedRequest.exists?(recente.id)
  end
end