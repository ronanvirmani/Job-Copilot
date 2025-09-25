require "test_helper"
require "jwt"
require "securerandom"
require "minitest/mock"

class ClassificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      supabase_user_id: SecureRandom.uuid,
      email: "tester@example.com",
      google_access_token: "token",
      google_refresh_token: "refresh"
    )
    @secret = "test-secret"
    ENV["SUPABASE_JWT_SECRET"] = @secret
  end

  test "returns llm classification" do
    fake_result = { label: "offer", confidence: 0.91, source: "ollama", raw: "{\"label\":\"offer\"}" }
    fake_classifier = Struct.new(:result) do
      def classify_with_confidence
        result
      end
    end

    EmailClassifier.stub :new, ->(_text) { fake_classifier.new(fake_result) } do
      post "/api/v1/classifications/preview", params: { text: "Congrats" }, headers: auth_headers
    end

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "offer", body["label"]
    assert_in_delta 0.91, body["confidence"]
    assert_equal "ollama", body["source"]
    assert_equal "{\"label\":\"offer\"}", body["raw"]
  end

  test "requires text or subject/body" do
    post "/api/v1/classifications/preview", params: {}, headers: auth_headers

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_equal "Provide text, or subject/body", body["error"]
  end

  private

  def auth_headers(user = @user)
    payload = { "sub" => user.supabase_user_id, "aud" => "authenticated" }
    token = JWT.encode(payload, @secret, "HS256")
    { "Authorization" => "Bearer #{token}" }
  end
end
