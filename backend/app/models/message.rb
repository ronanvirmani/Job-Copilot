class Message < ApplicationRecord
  belongs_to :application
  belongs_to :contact

  def classification_confidence
    metadata_fetch("confidence")
  end

  def classification_source
    metadata_fetch("source")
  end

  private

  def metadata_fetch(key)
    classification_metadata = parts_metadata.is_a?(Hash) ? parts_metadata["classification"] : nil
    return nil unless classification_metadata.is_a?(Hash)

    classification_metadata[key]
  end
end
