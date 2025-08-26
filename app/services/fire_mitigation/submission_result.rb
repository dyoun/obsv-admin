module FireMitigation
  class SubmissionResult
    attr_reader :success, :message, :data, :error_code, :metadata

    def initialize(success:, message:, data: nil, error_code: nil, metadata: {})
      @success = success
      @message = message
      @data = data
      @error_code = error_code
      @metadata = metadata || {}
    end

    def success?
      @success
    end

    def failure?
      !@success
    end

    def timestamp
      @metadata[:timestamp]
    end

    def http_status
      @metadata[:http_status]
    end

    def to_h
      {
        success: @success,
        message: @message,
        data: @data,
        error_code: @error_code,
        metadata: @metadata
      }
    end

    def to_json(*args)
      to_h.to_json(*args)
    end
  end
end
