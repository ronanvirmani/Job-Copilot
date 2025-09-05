class GmailIncrementalSyncJob < ApplicationJob
  queue_as :default
  def perform
    User.where.not(google_refresh_token: [nil, ""]).find_each do |u|
      GmailUserSyncJob.perform_later(u.id)
    end
  end
end
