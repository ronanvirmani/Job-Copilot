class MessagesController < ApplicationController
  include SupabaseAuth

  before_action :set_message, only: %i[update claim]

  STATUS_MAP = ParsedMessageIngester::STATUS_MAP

  def index
    scope = Message.joins(:application).where(applications: { user_id: current_user.id })
    scope = scope.where(classification: params[:classification]) if params[:classification].present?

    limit  = [[params.fetch(:limit, 50).to_i, 1].max, 100].min
    offset = [params.fetch(:offset, 0).to_i, 0].max
    scope  = scope.order(internal_ts: :desc).offset(offset).limit(limit)

    render json: serialize_messages(scope)
  end

  def update
    payload = update_params.to_h.symbolize_keys
    classification = payload[:classification].to_s.downcase
    classified_by = payload[:classified_by].to_s.downcase
    if payload.key?(:confidence)
      begin
        payload[:confidence] = normalize_confidence(payload[:confidence])
      rescue ArgumentError
        return render json: { error: "Invalid confidence" }, status: :unprocessable_entity
      end
    end
    payload[:reason] = payload[:reason].presence
    payload[:raw_response] = payload[:raw_response].presence

    unless EmailClassifier::CATEGORIES.include?(classification)
      return render json: { error: "Invalid classification" }, status: :unprocessable_entity
    end

    unless %w[llm rules].include?(classified_by)
      return render json: { error: "Invalid classified_by" }, status: :unprocessable_entity
    end

    payload[:classification] = classification
    payload[:classified_by] = classified_by

    metadata = merged_classification_metadata(@message.parts_metadata, payload)

    Message.transaction do
      @message.update!(classification: payload[:classification], parts_metadata: metadata)
      update_application_status(@message.application, payload[:classification])
      clear_triage_state(@message)
    end

    render json: serialize_message(@message.reload)
  end

  def claim
    metadata = @message.parts_metadata.is_a?(Hash) ? @message.parts_metadata.deep_dup : {}
    triage   = metadata.fetch("triage", {})

    current_claimant = current_claimant_identifier
    claimed_by       = triage["claimed_by"]
    claimed_at       = parse_time(triage["claimed_at"])
    in_progress      = triage["in_progress"]

    if in_progress && claimed_by.present? && claimed_by != current_claimant && claimed_at.present? && claimed_at > 10.minutes.ago
      return render json: { triage_in_progress: false }, status: :conflict
    end

    metadata["triage"] = {
      "in_progress" => true,
      "claimed_by" => current_claimant,
      "claimed_at" => Time.current.iso8601
    }

    @message.update!(parts_metadata: metadata)

    render json: { triage_in_progress: true }
  end

  private

  def set_message
    @message = Message.joins(:application).where(applications: { user_id: current_user.id }).find(params[:id])
  end

  def update_params
    params.require(:classification)
    params.require(:classified_by)
    params.permit(:classification, :classified_by, :confidence, :reason, :raw_response)
  end

  def merged_classification_metadata(existing_metadata, payload)
    metadata = existing_metadata.is_a?(Hash) ? existing_metadata.deep_dup : {}
    classification_metadata = metadata.fetch("classification", {})

    classification_metadata["source"] = payload[:classified_by]
    classification_metadata["confidence"] = payload[:confidence] if payload.key?(:confidence)
    classification_metadata["reason"] = payload[:reason]
    classification_metadata["raw"] = payload[:raw_response]
    classification_metadata["updated_at"] = Time.current.iso8601

    metadata["classification"] = classification_metadata.compact
    metadata
  end

  def update_application_status(application, classification)
    return unless (new_status = STATUS_MAP[classification])

    application.update!(status: new_status, last_status_change_at: Time.current)
  end

  def clear_triage_state(message)
    metadata = message.parts_metadata.is_a?(Hash) ? message.parts_metadata.deep_dup : {}
    return unless metadata.delete("triage")

    message.update_column(:parts_metadata, metadata) # rubocop:disable Rails/SkipsModelValidations
  end

  def serialize_messages(collection)
    Array(collection).map { |message| serialize_message(message) }
  end

  def serialize_message(message)
    message.as_json(
      only: %i[id subject snippet classification internal_ts gmail_thread_id],
      methods: %i[classification_confidence classification_source],
      include: {
        application: { only: %i[id role_title status] },
        contact: { only: %i[id name email] }
      }
    )
  end

  def current_claimant_identifier
    current_user.supabase_user_id.presence || current_user.id.to_s
  end

  def parse_time(value)
    return nil if value.blank?

    Time.zone.parse(value.to_s)
  rescue ArgumentError
    nil
  end

  def normalize_confidence(value)
    return nil if value.nil? || value == ""

    Float(value)
  rescue ArgumentError, TypeError
    raise ArgumentError, "invalid confidence"
  end
end
