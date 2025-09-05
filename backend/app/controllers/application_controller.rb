class ApplicationController < ActionController::API
  # keep this if you enabled sessions/cookies for Sidekiq::Web
  include ActionController::Cookies
end
