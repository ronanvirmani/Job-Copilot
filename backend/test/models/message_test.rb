require "test_helper"

class MessageTest < ActiveSupport::TestCase
  test "classification helpers read from metadata" do
    message = Message.new(parts_metadata: { "classification" => { "confidence" => 0.42, "source" => "ollama" } })

    assert_in_delta 0.42, message.classification_confidence
    assert_equal "ollama", message.classification_source
  end

  test "classification helpers return nil without metadata" do
    assert_nil Message.new.classification_confidence
    assert_nil Message.new.classification_source
  end
end
