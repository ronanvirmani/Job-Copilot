require_relative "boot"

require "rails/all"
Bundler.require(*Rails.groups)

module JobcopilotApi
  class Application < Rails::Application
    config.load_defaults 8.0
    config.api_only = true
    config.active_job.queue_adapter = :sidekiq


    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore, key: "_jobcopilot_session", same_site: :lax
  end
end
