class GoogleTokenHealthJob < ApplicationJob
  queue_as :default
  def perform
    User.where.not(google_refresh_token: [nil, ""]).find_each do |u|
      begin
        gmail = GoogleClientFactory.gmail_for(u)
        gmail.list_user_labels("me") # cheap call triggers refresh if needed
      rescue => e
        Rails.logger.error("[TOKENS] user=#{u.id} #{e.class}: #{e.message}")
      end
    end
  end
end
