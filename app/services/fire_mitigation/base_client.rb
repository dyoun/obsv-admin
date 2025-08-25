module FireMitigation
  class BaseClient
    def submit_observation(observation, request_id: nil)
      raise NotImplementedError, "Subclasses must implement #submit_observation"
    end

    def submit_batch(observations, options = {})
      raise NotImplementedError, "Subclasses must implement #submit_batch"
    end

    protected

    def success_result(message:, data: nil, metadata: {})
      SubmissionResult.new(
        success: true,
        message: message,
        data: data,
        metadata: metadata.merge(timestamp: Time.current)
      )
    end

    def failure_result(message, error_code: nil, metadata: {})
      SubmissionResult.new(
        success: false,
        message: message,
        error_code: error_code,
        metadata: metadata.merge(timestamp: Time.current)
      )
    end
  end
end