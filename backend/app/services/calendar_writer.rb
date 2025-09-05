class CalendarWriter
  def self.ensure_event_for!(user, application:, starts_at:, ends_at:, summary:, location: nil, description: nil)
    svc = GoogleClientFactory.calendar_for(user)
    event = Google::Apis::CalendarV3::Event.new(
      summary: summary,
      location: location,
      description: description,
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: starts_at.iso8601),
      end:   Google::Apis::CalendarV3::EventDateTime.new(date_time: ends_at.iso8601)
    )
    result = svc.insert_event("primary", event)
    CalendarEvent.create!(application: application, google_event_id: result.id, event_type: "interview", starts_at:, ends_at:, location:, notes: summary)
    result.id
  end
end
