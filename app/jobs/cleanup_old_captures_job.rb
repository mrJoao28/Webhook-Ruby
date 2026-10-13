class CleanupOldCapturesJob < ApplicationJob
  queue_as :default

  RETENTION = 7.days

  def perform
    removed = CapturedRequest.older_than(RETENTION.ago).delete_all
    Rails.logger.info "[CleanupOldCapturesJob] #{removed} requisições antigas removidas"
  end
end