class MeController < ApplicationController
    include SupabaseAuth
  
    def show
      render json: { id: current_user.id, supabase_user_id: current_user.supabase_user_id, email: current_user.email }
    end
  end
  