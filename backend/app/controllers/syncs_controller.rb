class SyncsController < ApplicationController
  include SupabaseAuth

  def gmail
    GmailUserSyncJob.perform_later(current_user.id)
    render json: { enqueued: true }
  end
end
