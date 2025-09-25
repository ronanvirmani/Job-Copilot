# app/controllers/auth_controller.rb
class AuthController < ApplicationController
  include SupabaseAuth

  # POST /api/v1/auth/exchange_code
  # Body: { code: "...", redirect_uri: "http://localhost:5173/auth/callback" }
  def exchange_google_code
    code         = params.require(:code)
    redirect_uri = params.require(:redirect_uri)

    client = Signet::OAuth2::Client.new(
      client_id: ENV.fetch("GOOGLE_CLIENT_ID"),
      client_secret: ENV.fetch("GOOGLE_CLIENT_SECRET"),
      token_credential_uri: "https://oauth2.googleapis.com/token",
      redirect_uri: redirect_uri,
      grant_type: "authorization_code",
      code: code
    )

    client.fetch_access_token! # exchanges code → tokens

    current_user.update!(
      google_access_token: client.access_token,
      google_refresh_token: client.refresh_token, # present on first consent/consent+offline
      token_expires_at: Time.at(client.expires_at.to_i)
    )

    render json: { ok: true }
  rescue Google::Auth::AuthorizationError, Signet::AuthorizationError => e
    Rails.logger.error("[OAUTH] exchange failed: #{e.message}")
    render json: { error: "oauth_exchange_failed" }, status: :unauthorized
  end

  # keep your existing manual upsert (helpful for emergencies)
  def upsert_provider_tokens
    current_user.update!(
      google_access_token: params[:google_access_token],
      google_refresh_token: params[:google_refresh_token],
      token_expires_at: (Time.at(params[:expires_at].to_i) rescue nil)
    )
    render json: { ok: true }
  end
end
