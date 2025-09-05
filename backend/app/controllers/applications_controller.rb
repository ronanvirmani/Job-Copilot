class ApplicationsController < ApplicationController
  include SupabaseAuth

  def index
    scope = Application.where(user: current_user)
    scope = scope.where(status: params[:status]) if params[:status].present?

    limit  = [[params.fetch(:limit, 50).to_i, 1].max, 100].min
    offset = [params.fetch(:offset, 0).to_i, 0].max
    scope  = scope.order(updated_at: :desc).offset(offset).limit(limit)

    render json: scope.as_json(
      only: %i[id role_title status applied_at last_email_at],
      include: { company: { only: %i[id name domain] } }
    )
  end

  def show
    app = Application.where(user: current_user).find(params[:id])
    render json: app.as_json(include: {
      company: { only: %i[id name domain] },
      messages: { only: %i[id subject snippet classification internal_ts] },
      application_events: { only: %i[event_type payload occurred_at] }
    })
  end
end
