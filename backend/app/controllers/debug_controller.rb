class DebugController < ApplicationController
  include SupabaseAuth
  def me
    render json: {
      user: current_user.as_json(only: %i[id email supabase_user_id]),
      counts: {
        applications: Application.where(user: current_user).count,
        messages: Message.joins(:application).where(applications: { user_id: current_user.id }).count
      }
    }
  end
end

# routes
get "/api/v1/debug/me", to: "debug#me"
