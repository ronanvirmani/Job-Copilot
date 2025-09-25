class MessagesController < ApplicationController
  include SupabaseAuth

  def index
    scope = Message.joins(:application).where(applications: { user_id: current_user.id })
    scope = scope.where(classification: params[:classification]) if params[:classification].present?

    limit  = [[params.fetch(:limit, 50).to_i, 1].max, 100].min
    offset = [params.fetch(:offset, 0).to_i, 0].max
    scope  = scope.order(internal_ts: :desc).offset(offset).limit(limit)  # <-- add order

    render json: scope.as_json(
      only: %i[id subject snippet classification internal_ts gmail_thread_id],
      methods: %i[classification_confidence classification_source],
      include: {
        application: { only: %i[id role_title status] },
        contact: { only: %i[id name email] }
      }
    )
  end
end
