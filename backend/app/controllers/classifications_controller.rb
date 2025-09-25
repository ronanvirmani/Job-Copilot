# frozen_string_literal: true

class ClassificationsController < ApplicationController
  include SupabaseAuth

  def create
    text = resolved_text
    return render json: { error: "Provide text, or subject/body" }, status: :unprocessable_entity if text.blank?

    result = EmailClassifier.new(text).classify_with_confidence
    render json: build_response(result)
  end

  private

  def resolved_text
    attrs = classification_params
    return attrs[:text] if attrs[:text].present?

    [attrs[:subject], attrs[:body]].compact_blank.join("\n")
  end

  def classification_params
    params.permit(:text, :subject, :body)
  end

  def build_response(result)
    {
      label: result[:label],
      confidence: result[:confidence],
      source: result[:source],
      raw: result[:raw]
    }.compact
  end
end
