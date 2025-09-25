# frozen_string_literal: true

require "json"
require "net/http"

module Ollama
  class ChatClient
    class Error < StandardError; end

    DEFAULT_TIMEOUT = 30

    def initialize(base_url: ENV.fetch("OLLAMA_BASE_URL", "http://localhost:11434"), open_timeout: ENV.fetch("OLLAMA_OPEN_TIMEOUT", 5).to_i, read_timeout: ENV.fetch("OLLAMA_READ_TIMEOUT", DEFAULT_TIMEOUT).to_i)
      @base_uri = parse_base_url(base_url)
      @open_timeout = open_timeout
      @read_timeout = read_timeout
    end

    def chat(model:, messages:, options: {})
      payload = {
        model: model,
        messages: messages,
        stream: false
      }.merge(options)

      request = Net::HTTP::Post.new(api_path("/api/chat"))
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(payload)

      response = perform(request)
      unless response.is_a?(Net::HTTPSuccess)
        raise Error, "Ollama chat request failed with status #{response.code}"
      end

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise Error, "Unable to parse Ollama response JSON: #{e.message}"
    rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Net::OpenTimeout, Net::ReadTimeout => e
      raise Error, "Ollama connection failed: #{e.class}: #{e.message}"
    end

    private

    def perform(request)
      uri = uri_for_path(request.path)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = @open_timeout
      http.read_timeout = @read_timeout
      http.request(request)
    end

    def api_path(path)
      uri = uri_for_path(path)
      uri.request_uri
    end

    def uri_for_path(path)
      merged = @base_uri.dup
      merged.path = normalize_path(path)
      merged
    end

    def normalize_path(path)
      base_path = (@base_uri.path || "").sub(/\/?\z/, "")
      relative = path.start_with?("/") ? path : "/#{path}"
      (base_path + relative).gsub(%r{//+}, "/")
    end

    def parse_base_url(base_url)
      uri = URI.parse(base_url)
      raise ArgumentError, "OLLAMA_BASE_URL must include scheme and host" unless uri.is_a?(URI::HTTP)
      uri
    end
  end
end
