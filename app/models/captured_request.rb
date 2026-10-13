class CapturedRequest < ApplicationRecord
  scope :older_than, ->(time) { where(created_at: ...time) }
  belongs_to :endpoint

  after_create_commit -> {
    broadcast_prepend_to endpoint, target: "captured_requests"
  }

  def pretty_body 
    JSON.pretty_generate(JSON.parse(body))
  rescue JSON::ParserError
    body
  end
end
