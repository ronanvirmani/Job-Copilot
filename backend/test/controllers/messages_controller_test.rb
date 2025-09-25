require "test_helper"
require "jwt"
require "securerandom"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      supabase_user_id: SecureRandom.uuid,
      email: "primary@example.com",
      google_access_token: "token",
      google_refresh_token: "refresh"
    )
    @other_user = User.create!(
      supabase_user_id: SecureRandom.uuid,
      email: "secondary@example.com",
      google_access_token: "token",
      google_refresh_token: "refresh"
    )

    company = Company.create!(name: "Acme", domain: "acme.com")
    contact = Contact.create!(company: company, name: "Recruiter", email: "recruiter@acme.com")
    application = Application.create!(
      user: @user,
      company: company,
      status: "applied",
      role_title: "Engineer"
    )
    @message = Message.create!(
      application: application,
      contact: contact,
      gmail_message_id: SecureRandom.hex(8),
      gmail_thread_id: SecureRandom.hex(8),
      from_addr: "recruiter@acme.com",
      to_addr: "primary@example.com",
      subject: "Interview",
      snippet: "Let's chat",
      classification: "other",
      parts_metadata: {}
    )
    @secret = "test-secret"
    ENV["SUPABASE_JWT_SECRET"] = @secret

    # Ensure deterministic starting state
    @message.update!(classification: "other", parts_metadata: {})
    @message.application.update!(status: "applied")
  end

  test "index returns messages for current user" do
    get "/api/v1/messages", headers: auth_headers(@user)

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.size
    assert_equal @message.id, body.first["id"]
  end

  test "claim marks message in progress and prevents other users" do
    patch "/api/v1/messages/#{@message.id}/claim", headers: auth_headers(@user)

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal true, body["triage_in_progress"]
    assert_equal true, @message.reload.parts_metadata.dig("triage", "in_progress")

    patch "/api/v1/messages/#{@message.id}/claim", headers: auth_headers(@other_user)

    assert_response :not_found
  end

  test "update applies classification metadata and clears triage" do
    # simulate an existing claim
    @message.update!(parts_metadata: { "triage" => { "in_progress" => true } })

    payload = {
      classification: "offer",
      classified_by: "llm",
      confidence: 0.91,
      reason: "explicit offer",
      raw_response: "{\"label\":\"offer\"}"
    }

    patch "/api/v1/messages/#{@message.id}",
          params: payload.to_json,
          headers: auth_headers(@user).merge("Content-Type" => "application/json")

    assert_response :success
    @message.reload

    assert_equal "offer", @message.classification
    assert_in_delta 0.91, @message.classification_confidence
    assert_equal "llm", @message.classification_source
    assert_equal "offer", @message.application.reload.status
    assert_nil @message.parts_metadata["triage"]
  end

  private

  def auth_headers(user)
    payload = { "sub" => user.supabase_user_id, "aud" => "authenticated" }
    token = JWT.encode(payload, @secret, "HS256")
    { "Authorization" => "Bearer #{token}" }
  end
end
