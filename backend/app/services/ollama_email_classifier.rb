# frozen_string_literal: true

require "json"

class OllamaEmailClassifier
  DEFAULT_TEMPERATURE = 0.0
  DEFAULT_MAX_TOKENS = 256

  def initialize(client: nil, model: ENV.fetch("OLLAMA_MODEL", "llama3.1"), categories: EmailClassifier::CATEGORIES, temperature: DEFAULT_TEMPERATURE, max_output_tokens: DEFAULT_MAX_TOKENS)
    @client = client || Ollama::ChatClient.new
    @model = model
    @categories = categories
    @temperature = temperature
    @max_output_tokens = max_output_tokens
  end

  def classify(text)
    trimmed = text.to_s.strip
    return nil if trimmed.empty?

    response = @client.chat(
      model: @model,
      messages: build_messages(trimmed),
      options: { options: { temperature: @temperature, num_predict: @max_output_tokens } }
    )

    parse_response(response)
  rescue Ollama::ChatClient::Error => e
    Rails.logger.warn("[EmailClassifier] Ollama request failed: #{e.message}")
    nil
  end

  private

  def build_messages(text)
    [
      {
        role: "system",
        content: <<~PROMPT.strip
          You are a precise classifier for incoming job-search emails. Classify the email into one of these categories:
          #{formatted_categories}.
          Respond with a minified JSON object like {"label":"interview_invite","confidence":0.82}. Confidence must be a number between 0 and 1. Pick "other" only if nothing else fits. No additional text.
        PROMPT
      },
      { role: "user", content: text }
    ]
  end

  def formatted_categories
    @categories.join(", ")
  end

  def parse_response(response)
    raw_content = extract_content(response)
    return nil unless raw_content

    json = extract_json(raw_content)
    label = normalize_label(json["label"])
    confidence = normalize_confidence(json["confidence"])

    return nil if label.nil?

    {
      label: label,
      confidence: confidence,
      source: "ollama",
      raw: raw_content
    }
  rescue JSON::ParserError => e
    Rails.logger.warn("[EmailClassifier] Invalid JSON from Ollama: #{e.message} -- #{raw_content.inspect}")
    nil
  end

  def extract_content(response)
    message = response.fetch("message", {})
    content = message["content"]
    content.presence
  rescue KeyError
    nil
  end

  def extract_json(content)
    json_str = content.strip
    unless json_str.start_with?("{") && json_str.end_with?("}")
      json_str = json_fragment(json_str)
    end
    JSON.parse(json_str)
  end

  def json_fragment(content)
    fragment = content[/{.*}/m]
    raise JSON::ParserError, "No JSON object found" if fragment.nil?
    fragment
  end

  def normalize_label(value)
    return nil unless value.is_a?(String)

    normalized = value.downcase.strip
    normalized = "other" unless @categories.include?(normalized)
    normalized
  end

  def normalize_confidence(value)
    return nil if value.nil?

    begin
      numeric = Float(value)
    rescue ArgumentError, TypeError
      return nil
    end

    numeric = 0.0 if numeric < 0.0
    numeric = 1.0 if numeric > 1.0
    numeric
  end
end
