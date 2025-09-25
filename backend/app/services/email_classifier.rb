class EmailClassifier
  CATEGORIES = %w[offer interview_invite oa recruiter_reply rejection auto_ack not_job_related other].freeze

  def initialize(text, llm: default_llm)
    @text = text.to_s
    @llm = llm
  end

  def classify
    classify_with_confidence[:label]
  end

  def classify_with_confidence
    llm_result = safe_llm_classify
    return llm_result if llm_result

    {
      label: rule_based_classifier.classify,
      confidence: nil,
      source: "rules"
    }
  end

  private

  def safe_llm_classify
    result = @llm&.classify(@text)
    return nil unless result.is_a?(Hash)

    label = result[:label]
    confidence = result[:confidence]
    return nil unless label.is_a?(String)

    normalized_label = normalize_label(label)
    return nil unless normalized_label

    {
      label: normalized_label,
      confidence: confidence,
      source: result[:source] || "ollama",
      raw: result[:raw]
    }
  rescue => e
    Rails.logger.warn("[EmailClassifier] LLM classification failed: #{e.class}: #{e.message}")
    nil
  end

  def normalize_label(label)
    downcased = label.to_s.downcase.strip
    return downcased if CATEGORIES.include?(downcased)
    nil
  end

  def rule_based_classifier
    @rule_based_classifier ||= RuleBased.new(@text)
  end

  def default_llm
    return nil if ENV["OLLAMA_BASE_URL"].blank? && ENV["OLLAMA_MODEL"].blank?

    OllamaEmailClassifier.new(categories: CATEGORIES)
  rescue ArgumentError => e
    Rails.logger.warn("[EmailClassifier] LLM disabled due to configuration: #{e.message}")
    nil
  end

  class RuleBased
    RULES = {
      offer: /\boffer\b|compensation|package/i,
      interview_invite: /\b(interview|invite|phone screen|onsite|loop)\b/i,
      oa: /(hacker ?rank|codility|codesignal|karat|online assessment|challenge|take-?home)/i,
      recruiter_reply: /(connect|schedule|chat|next steps|availability)/i,
      rejection: /(regret to inform|unfortunately|not moving forward)/i,
      auto_ack: /(thank you for applying|we received your application|application received)/i
    }.freeze

    PRIORITY = %i[offer interview_invite oa recruiter_reply rejection auto_ack].freeze

    def initialize(text)
      @text = text.to_s
    end

    def classify
      hits = RULES.transform_values { |regex| !!(@text =~ regex) }
      (PRIORITY.find { |key| hits[key] } || :other).to_s
    end
  end
end
