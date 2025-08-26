require "net/http"
require "json"

module AddressValidation
  class OpenstreetmapValidator < BaseValidator
    BASE_URL = "https://nominatim.openstreetmap.org/search"
    USER_AGENT = "RulesAdminApp/1.0"

    def initialize(timeout: 10, rate_limit_delay: 1.0)
      @timeout = timeout
      @rate_limit_delay = rate_limit_delay
      @last_request_time = nil
    end

    def validate(address)
      return validation_result(valid: false, error_message: "Address cannot be blank") if address.blank?

      enforce_rate_limit

      begin
        response = make_request(address)
        parse_response(response, address)
      rescue Net::OpenTimeout, Net::ReadTimeout, Timeout::Error
        validation_result(valid: false, error_message: "Request timeout")
      rescue StandardError => e
        Rails.logger.error "OpenStreetMap validation failed: #{e.message}"
        validation_result(valid: false, error_message: "Validation service unavailable")
      end
    end

    private

    def make_request(address)
      uri = build_uri(address)
      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = USER_AGENT

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = @timeout
      http.open_timeout = @timeout

      @last_request_time = Time.current
      http.request(request)
    end

    def build_uri(address)
      params = {
        q: address,
        format: "json",
        addressdetails: 1,
        limit: 1
      }

      query_string = URI.encode_www_form(params)
      URI("#{BASE_URL}?#{query_string}")
    end

    def parse_response(response, original_address)
      case response.code.to_i
      when 200
        handle_success_response(response.body, original_address)
      when 429
        validation_result(valid: false, error_message: "Rate limit exceeded")
      else
        validation_result(valid: false, error_message: "Service error: #{response.code}")
      end
    end

    def handle_success_response(body, original_address)
      results = JSON.parse(body)

      if results.empty?
        return validation_result(
          valid: false,
          error_message: "Address not found"
        )
      end

      result = results.first
      validation_result(
        valid: true,
        latitude: result["lat"].to_f,
        longitude: result["lon"].to_f,
        formatted_address: result["display_name"]
      )
    rescue JSON::ParserError
      validation_result(valid: false, error_message: "Invalid response format")
    end

    def enforce_rate_limit
      return unless @last_request_time

      time_since_last = Time.current - @last_request_time
      return unless time_since_last < @rate_limit_delay

      sleep(@rate_limit_delay - time_since_last)
    end
  end
end
