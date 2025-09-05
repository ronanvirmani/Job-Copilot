class EmailClassifier
  RULES = {
    offer: /\boffer\b|compensation|package/i,
    interview_invite: /\b(interview|invite|phone screen|onsite|loop)\b/i,
    oa: /(hacker ?rank|codility|codesignal|karat|online assessment|challenge|take-?home)/i,
    recruiter_reply: /(connect|schedule|chat|next steps|availability)/i,
    rejection: /(regret to inform|unfortunately|not moving forward)/i,
    auto_ack: /(thank you for applying|we received your application|application received)/i
  }.freeze

  PRIORITY = %i[offer interview_invite oa recruiter_reply rejection auto_ack].freeze

  def initialize(text) = @t = text.to_s

  def classify
    hits = RULES.transform_values { |r| !!(@t =~ r) }
    (PRIORITY.find { |k| hits[k] } || :other).to_s
  end
end
