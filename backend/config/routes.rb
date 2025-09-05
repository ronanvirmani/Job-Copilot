# config/routes.rb
require "sidekiq/web"

Rails.application.routes.draw do
  get "/health", to: proc { [200, {}, ["OK"]] }

  # (Optional) protect Sidekiq in production
  if Rails.env.production?
    Sidekiq::Web.use Rack::Auth::Basic do |user, pass|
      ActiveSupport::SecurityUtils.secure_compare(user, ENV.fetch("SIDEKIQ_USER", "admin")) &
      ActiveSupport::SecurityUtils.secure_compare(pass, ENV.fetch("SIDEKIQ_PASSWORD", "admin"))
    end
  end

  # Mount ONCE
  mount Sidekiq::Web => "/sidekiq"

  scope "/api/v1" do
    # --- add these two back if missing ---
    post "/auth/upsert_provider_tokens", to: "auth#upsert_provider_tokens"
    get  "/me",                          to: "users#me" # optional, but handy for testing

    # existing endpoints
    post "/sync/gmail", to: "syncs#gmail"
    resources :messages, only: [:index]
    resources :applications, only: [:index, :show]

    get "/insights/summary", to: "insights#summary"
    get "/insights/company_leaderboard", to: "insights#company_leaderboard"
  end
end
