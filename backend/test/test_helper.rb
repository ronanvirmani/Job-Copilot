ENV["RAILS_ENV"] ||= "test"
ENV["RAILS_SKIP_TEST_DATABASE"] = "1"
ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"] ||= "m9O8qjHgNsx3Rp3XIan+FJxuxMxDPZWS9Vyuk3F7S3w="
ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"] ||= "VvJpf3uKxRykGGBqBPdZiZsaAJ+lZeX7IuAv89xDSks="
ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"] ||= "n1N7JrLZ7eo0t8NxmPKzW0fvkYl9wH14r2raXIiQunw="
require_relative "../config/environment"
require "rails/test_help"

ActiveRecord::Encryption.configure(
  primary_key: ENV.fetch("ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"),
  deterministic_key: ENV.fetch("ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"),
  key_derivation_salt: ENV.fetch("ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT")
)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Add more helper methods to be used by all tests here...
  end
end
