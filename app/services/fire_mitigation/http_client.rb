require "uri"
require "json"
require "net/http"
require "timeout"

module FireMitigation
  class HttpClient < BaseClient
    DEFAULT_BASE_URL = ENV.fetch("RULES_ENGINE_URL", "http://localhost:5000")
    DEFAULT_ENDPOINT = "/rules/latest"
    DEFAULT_TIMEOUT = 30

    def initialize(base_url: DEFAULT_BASE_URL, endpoint: DEFAULT_ENDPOINT, timeout: DEFAULT_TIMEOUT)
      @base_url = base_url
      @endpoint = endpoint
      @timeout = timeout
    end

    def submit_observation(observation, request_id: nil)
      return failure_result("Observation is required") if observation.blank?

      payload = PayloadBuilder.build_for_observation(observation, request_id: request_id)

      begin
        response = make_request(payload)
        handle_response(response, observation)
      rescue Net::ReadTimeout, Net::OpenTimeout, Timeout::Error => e
        log_error("Request timeout: #{e.message}")
        failure_result("Request timeout - rules service unavailable")
      rescue StandardError => e
        log_error("Service error: #{e.message}")
        failure_result("Service error - unable to submit observation")
      end
    end

    def submit_batch(observations, request_prefix: "batch")
      return failure_result("No observations provided") if observations.blank?

      results = []
      observations.each_with_index do |observation, index|
        request_id = "#{request_prefix}-#{index + 1}-#{Time.current.to_i}"
        result = submit_observation(observation, request_id: request_id)
        results << result.to_h.merge(observation_id: observation.id)
      end

      BatchResult.new(
        total: observations.count,
        successful: results.count { |r| r[:success] },
        failed: results.count { |r| !r[:success] },
        results: results
      )
    end

    private

    attr_reader :base_url, :endpoint, :timeout

    def make_request(payload)
      uri = URI("#{base_url}#{endpoint}")

      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = timeout
      http.open_timeout = timeout

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["User-Agent"] = "RulesAdmin/1.0"
      request.body = JSON.dump(payload)

      log_info("Submitting to fire mitigation service: #{payload.to_json}")

      http.request(request)
    end

    def handle_response(response, observation)
      case response.code.to_i
      when 200, 201
        handle_success_response(response, observation)
      when 400
        handle_bad_request_response(response, observation)
      when 404
        handle_not_found_response(response)
      when 500
        handle_server_error_response(response)
      else
        handle_unexpected_response(response)
      end
    end

    def handle_success_response(response, observation)
      body = parse_response_body(response.body)
      log_info("Success for observation #{observation.id}: #{response.body}")

      success_result(
        message: "Observation submitted successfully",
        data: body,
        metadata: { http_status: response.code.to_i }
      )
    end

    def handle_bad_request_response(response, observation)
      log_warning("Bad request for observation #{observation.id}: #{response.body}")
      failure_result(
        "Invalid observation data",
        error_code: "BAD_REQUEST",
        metadata: { http_status: response.code.to_i }
      )
    end

    def handle_not_found_response(response)
      log_warning("Endpoint not found: #{response.body}")
      failure_result(
        "Rules service endpoint not available",
        error_code: "NOT_FOUND",
        metadata: { http_status: response.code.to_i }
      )
    end

    def handle_server_error_response(response)
      log_error("Server error: #{response.body}")
      failure_result(
        "Rules service internal error",
        error_code: "SERVER_ERROR",
        metadata: { http_status: response.code.to_i }
      )
    end

    def handle_unexpected_response(response)
      log_error("Unexpected response #{response.code}: #{response.body}")
      failure_result(
        "Unexpected response: #{response.code}",
        error_code: "UNEXPECTED_RESPONSE",
        metadata: { http_status: response.code.to_i }
      )
    end

    def parse_response_body(body)
      JSON.parse(body)
    rescue JSON::ParserError
      { raw_response: body }
    end

    def log_info(message)
      Rails.logger.info "[FireMitigation::HttpClient] #{message}"
    end

    def log_warning(message)
      Rails.logger.warn "[FireMitigation::HttpClient] #{message}"
    end

    def log_error(message)
      Rails.logger.error "[FireMitigation::HttpClient] #{message}"
    end
  end
end
