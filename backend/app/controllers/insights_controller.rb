class InsightsController < ApplicationController
  include SupabaseAuth

  def summary
    apps = Application.where(user: current_user)
    total = apps.count
    replied = apps.where(status: %w[recruiter_replied oa_assigned interview_scheduled offer]).count
    rejected = apps.where(status: "rejected").count
    offer = apps.where(status: "offer").count

    render json: {
      totals: { applications: total, replied: replied, rejected: rejected, offer: offer },
      response_rate: (total.positive? ? (replied.to_f / total).round(3) : 0.0)
    }
  end

  def company_leaderboard
    # which domains reply most (simple heuristic)
    rows = Application.where(user: current_user)
                      .joins(:company)
                      .group("companies.domain")
                      .pluck("companies.domain, count(*) FILTER (WHERE status in ('recruiter_replied','oa_assigned','interview_scheduled','offer'))::int as replies, count(*)::int as total")
                      .map { |domain, replies, total| { domain:, replies:, total:, rate: (total > 0 ? (replies.to_f / total).round(3) : 0.0) } }
                      .sort_by { |h| -h[:rate] }
    render json: rows.first(25)
  end
end
