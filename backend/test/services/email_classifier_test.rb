require "test_helper"

class EmailClassifierTest < ActiveSupport::TestCase
  test "falls back to rules when llm unavailable" do
    text = "Unfortunately we are not moving forward"
    classifier = EmailClassifier.new(text, llm: nil)

    result = classifier.classify_with_confidence

    assert_equal "rejection", result[:label]
    assert_nil result[:confidence]
    assert_equal "rules", result[:source]
  end

  test "uses llm result when provided" do
    llm = Class.new do
      def classify(_text)
        { label: "offer", confidence: 0.87, source: "ollama", raw: "{\"label\":\"offer\"}" }
      end
    end.new

    classifier = EmailClassifier.new("Congrats!", llm: llm)
    result = classifier.classify_with_confidence

    assert_equal "offer", result[:label]
    assert_in_delta 0.87, result[:confidence]
    assert_equal "ollama", result[:source]
    assert_equal "{\"label\":\"offer\"}", result[:raw]
  end

  test "ignores llm labels outside the allow list" do
    llm = Class.new do
      def classify(_text)
        { label: "unknown", confidence: 0.5 }
      end
    end.new

    classifier = EmailClassifier.new("Random note", llm: llm)
    result = classifier.classify_with_confidence

    assert_equal "other", result[:label]
    assert_nil result[:confidence]
    assert_equal "rules", result[:source]
  end
end
