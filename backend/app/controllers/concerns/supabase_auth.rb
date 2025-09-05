# app/controllers/concerns/supabase_auth.rb
module SupabaseAuth
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_supabase_user!
  end

  def authenticate_supabase_user!
    # 1) Extract bearer token robustly
    token = extract_bearer_token
    return render json: { error: "Missing token" }, status: :unauthorized if token.blank?

    # 2) Decode with HS256 and aud check; allow small clock skew in dev
    secret = ENV["SUPABASE_JWT_SECRET"]
    unless secret.present?
      Rails.logger.error("[AUTH] Missing SUPABASE_JWT_SECRET")
      return render json: { error: "Server auth misconfigured" }, status: :unauthorized
    end

    begin
      options = { algorithm: "HS256", verify_aud: true, aud: "authenticated" }
      # small leeway for clock skew in development
      options[:leeway] = 30 if Rails.env.development?

      decoded, _headers = JWT.decode(token, secret, true, options)
      sub   = decoded["sub"]
      email = decoded["email"]

      if sub.blank?
        Rails.logger.warn("[AUTH] JWT missing sub claim")
        return render json: { error: "Invalid token: missing sub" }, status: :unauthorized
      end

      # 3) Find the user by supabase_user_id
      @current_user = User.find_by(supabase_user_id: sub)
      unless @current_user
        Rails.logger.warn("[AUTH] No user for sub=#{sub.inspect}")
        # In dev, you may choose to auto-provision. For now, fail clearly:
        return render json: { error: "User not found for token sub" }, status: :unauthorized
      end

    rescue JWT::ExpiredSignature
      Rails.logger.info("[AUTH] JWT expired")
      return render json: { error: "Token expired" }, status: :unauthorized
    rescue JWT::InvalidAudError
      Rails.logger.info("[AUTH] JWT invalid aud")
      return render json: { error: "Invalid audience" }, status: :unauthorized
    rescue JWT::DecodeError => e
      Rails.logger.info("[AUTH] JWT decode error: #{e.message}")
      return render json: { error: "Invalid token" }, status: :unauthorized
    rescue => e
      Rails.logger.error("[AUTH] Unexpected error: #{e.class} #{e.message}")
      return render json: { error: "Auth error" }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end

  private

  def extract_bearer_token
    h = request.headers
    # Try the canonical header
    auth = h["Authorization"] || h["HTTP_AUTHORIZATION"] || h["X-Authorization"]
    return nil if auth.blank?

    # Accept "Bearer <token>" and also raw tokens just in case
    if auth =~ /\ABearer\s+(.+)\z/i
      Regexp.last_match(1)
    else
      auth
    end
  end
end
