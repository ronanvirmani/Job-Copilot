class ParsedMessageIngester
  STATUS_MAP = {
    "auto_ack"         => "auto_ack",
    "recruiter_reply"  => "recruiter_replied",
    "oa"               => "oa_assigned",
    "interview_invite" => "interview_scheduled",
    "rejection"        => "rejected",
    "offer"            => "offer"
  }.freeze

  def initialize(user, gm) = (@user = user; @gm = gm)

  def ingest!
    headers = Array(@gm.payload.headers).to_h { |h| [h.name, h.value] }
    subject = headers["Subject"].to_s
    from    = headers["From"].to_s
    body    = extract_text(@gm)

    classifier_result = EmailClassifier.new("#{subject}\n#{body}").classify_with_confidence
    label             = classifier_result[:label]

    company = upsert_company(from)
    contact = upsert_contact(company, from)
    app     = upsert_application(company, subject, body)

    if %w[interview_invite oa].include?(label)
      starts_at, ends_at = EmailTimeParser.extract("#{subject}\n#{body}")
      if starts_at && ends_at
        summary = label == "oa" ? "Online Assessment: #{subject}" : "Interview: #{subject}"
        CalendarWriter.ensure_event_for!(@user, application: app, starts_at:, ends_at:, summary:, location: nil, description: "Auto-created from email")
      end
    end

    message = Message.find_or_initialize_by(gmail_message_id: @gm.id)
    existing_metadata = message.parts_metadata.presence || {}
    classification_metadata = {
      "source" => classifier_result[:source],
      "confidence" => classifier_result[:confidence],
      "raw" => classifier_result[:raw]
    }.compact
    existing_metadata["classification"] = classification_metadata if classification_metadata.present?

    message.update!(
      application: app, contact: contact,
      gmail_thread_id: @gm.thread_id,
      from_addr: from, to_addr: headers["To"],
      subject: subject, snippet: @gm.snippet.to_s,
      classification: label,
      internal_ts: Time.at(@gm.internal_date.to_i / 1000.0),
      raw_headers: headers,
      parts_metadata: existing_metadata
    )

    app.update!(last_email_at: Time.current)

    ApplicationEvent.create!(
      application: app, event_type: "email_ingested",
      payload: { classification: label, confidence: classifier_result[:confidence], source: classifier_result[:source], subject: subject }.compact,
      occurred_at: Time.current
    )

    if (new_status = STATUS_MAP[label])
      app.update!(status: new_status, last_status_change_at: Time.current)
    end
  end

  private

  def extract_text(msg)
    if msg.payload.parts
      plain = find_mime(msg.payload.parts, "text/plain")
      return plain if plain.present?
      html = find_mime(msg.payload.parts, "text/html")
      return ActionView::Base.full_sanitizer.sanitize(html) if html.present?
      ""
    else
      Base64.decode64(msg.payload.body.data.to_s.tr("-_", "+/")) rescue ""
    end
  end

  def find_mime(parts, mime)
    parts.each do |p|
      return Base64.decode64(p.body.data.to_s.tr("-_", "+/")) if p.mime_type == mime
      if p.parts
        nested = find_mime(p.parts, mime)
        return nested if nested
      end
    end
    nil
  end

  def upsert_company(from_header)
    domain = from_header[/@([A-Za-z0-9.-]+)/, 1]&.downcase
    name   = domain&.split(".")&.first&.capitalize || "Unknown"
    Company.where(domain: domain).first_or_create!(name: name)
  end

  def upsert_contact(company, from_header)
    email = from_header[/<([^>]+)>/, 1] || from_header[/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i]
    name  = from_header[/^([^<]+)</, 1]&.strip
    Contact.where(email: email).first_or_create!(company: company, name: name)
  end

  def upsert_application(company, subject, body)
    role = subject[/(?:(?:for|role|position)\s*:?\s*)(.+)$/i, 1] ||
           body[/position\s*:?\s*(.+)/i, 1]
    Application.where(user: @user, company: company, role_title: role&.truncate(120))
               .first_or_create!(status: "applied", applied_at: Time.current)
  end
end
