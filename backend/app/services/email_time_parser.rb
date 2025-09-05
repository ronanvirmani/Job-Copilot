class EmailTimeParser
  # Returns [starts_at, ends_at] or [nil, nil]
  def self.extract(text, default_duration: 60.minutes)
    # super naive: look for “on Sept 12 at 3:00 PM” or “9/12/2025 15:00”
    t = text.to_s
    # Try DateTime.parse as a fallback (will often return nil)
    begin
      dt = DateTime.parse(t) rescue nil
      return [dt&.to_time, dt&.to_time&.+(default_duration)] if dt
    rescue ArgumentError
    end
    [nil, nil]
  end
end
