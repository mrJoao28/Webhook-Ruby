class CapturesController <ActionController::API
  MAX_BODY = 100_000

  def create
  endpoint = Endpoint.find_by(token: params[:token])
  return head :not_found unless endpoint

  endpoint.captured_requests.create!(
    http_method: request.method,
    headers: captured_headers,
    body: captured_body,
    query_params: request.query_parameters,
    ip: request.remote_ip,
    content_type: request.content_type
  )
  head :ok
  end

  private
  def captured_headers
    request.headers.env
      .select { |key, _| key.start_with?("HTTP_")|| %w[CONTENT_TYPE CONTENT_LENGTH].include?(key)}
      .transform_keys { |key| key.delete_prefix("HTTP_").split("_").map(&:capitalize).join("-")}
  end

  def captured_body
    request.raw_post.to_s.dup.force_encoding("UTF-8").scrub.first(MAX_BODY)
  end
end