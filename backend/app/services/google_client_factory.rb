class GoogleClientFactory
  TOKEN_URI = "https://oauth2.googleapis.com/token"

  def self.oauth_client_for(user)
    Signet::OAuth2::Client.new(
      client_id: ENV["GOOGLE_CLIENT_ID"],
      client_secret: ENV["GOOGLE_CLIENT_SECRET"],
      token_credential_uri: TOKEN_URI,
      access_token: user.google_access_token,
      refresh_token: user.google_refresh_token,
      expires_at: user.token_expires_at
    )
  end

  def self.refresh_if_needed!(user, client)
    if client.expired?
      client.refresh!
      user.update!(
        google_access_token: client.access_token,
        token_expires_at: Time.at(client.expires_at.to_i)
      )
    end
    client
  end

  def self.gmail_for(user)
    client = refresh_if_needed!(user, oauth_client_for(user))
    svc = Google::Apis::GmailV1::GmailService.new
    svc.authorization = client
    svc
  end
end
