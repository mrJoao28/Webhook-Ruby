class ApplicationController < ActionController::Base
  before_action :require_admin

  private

  def require_admin
    password = ENV["ADMIN_PASSWORD"]

    if password.blank?
      raise "Defina ADMIN_PASSWORD" if Rails.env.production?
      return
    end

    authenticate_or_request_with_http_basic("Webhook Inspector") do |user, pass|
      ActiveSupport::SecurityUtils.secure_compare(user, ENV.fetch("ADMIN_USER", "admin")) &
        ActiveSupport::SecurityUtils.secure_compare(pass, password)
    end
  end
end