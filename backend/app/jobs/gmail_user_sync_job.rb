class GmailUserSyncJob < ApplicationJob
  queue_as :default

  BASE_SUBJECT_QUERY = %(
    subject:(applied OR application OR interview OR "online assessment" OR OA OR HackerRank OR Codility OR CodeSignal OR Karat OR "next steps" OR offer OR regret)
  ).squish

  def perform(user_id)
    user = User.find(user_id)
    return unless user.google_refresh_token.present?

  gmail    = GoogleClientFactory.gmail_for(user)
    attempts = 0
    page_token = nil
  # Determine time window: only fetch messages after the user's last sync.
  # If not set, default to 1 hour ago to avoid a large backfill on first run.
  after_time = user.last_gmail_synced_at || 1.hour.ago
  after_ts = after_time.to_i
  search_q = "label:INBOX after:#{after_ts} #{BASE_SUBJECT_QUERY}"

    loop do
      begin
        res = gmail.list_user_messages("me", q: search_q, page_token: page_token, max_results: 50)
      rescue Google::Apis::AuthorizationError => e
        # One forced refresh, then retry once for this request
        Rails.logger.warn("[GMAIL] auth error, attempting refresh user=#{user.id}: #{e.message}")
        client = gmail.authorization
        client.refresh!
        user.update!(google_access_token: client.access_token, token_expires_at: Time.at(client.expires_at.to_i))
        res = gmail.list_user_messages("me", q: SEARCH_QUERY, page_token: page_token, max_results: 50)
      rescue => e
        attempts += 1
        Rails.logger.error("[GMAIL] transient #{e.class} #{e.message} (attempt #{attempts})")
        sleep([2**attempts, 30].min)
        retry if attempts < 3
        raise
      end

      Array(res.messages).each do |ref|
        msg = gmail.get_user_message("me", ref.id, format: "full")
        ParsedMessageIngester.new(user, msg).ingest!
      end

      page_token = res.next_page_token
      break unless page_token
    end

    # Update user's last synced timestamp to now after successful sync
    user.update!(last_gmail_synced_at: Time.current)
  end
end
