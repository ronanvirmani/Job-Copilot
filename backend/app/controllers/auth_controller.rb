class AuthController < ApplicationController
    include SupabaseAuth
  
    # Body: { google_access_token, google_refresh_token, expires_at }
    def upsert_provider_tokens
      current_user.update!(
        google_access_token: params[:google_access_token],
        google_refresh_token: params[:google_refresh_token],
        token_expires_at: (Time.at(params[:expires_at].to_i) rescue nil)
      )
      render json: { ok: true }
    end
  end
  