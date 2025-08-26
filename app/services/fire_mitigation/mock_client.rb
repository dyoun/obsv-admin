module FireMitigation
  class MockClient < BaseClient
    def initialize(success_rate: 1.0, delay: 0)
      @success_rate = success_rate
      @delay = delay
    end

    def submit_observation(observation, request_id: nil)
      simulate_delay if @delay > 0

      if should_succeed?
        success_result(
          message: "Mock submission successful",
          data: mock_success_response(observation, request_id),
          metadata: { client_type: "mock" }
        )
      else
        failure_result(
          "Mock submission failed",
          error_code: "MOCK_FAILURE",
          metadata: { client_type: "mock" }
        )
      end
    end

    def submit_batch(observations, request_prefix: "batch")
      results = observations.map.with_index do |observation, index|
        request_id = "#{request_prefix}-#{index + 1}-#{Time.current.to_i}"
        submit_observation(observation, request_id: request_id).to_h.merge(observation_id: observation.id)
      end

      BatchResult.new(
        total: observations.count,
        successful: results.count { |r| r[:success] },
        failed: results.count { |r| !r[:success] },
        results: results
      )
    end

    private

    attr_reader :success_rate, :delay

    def should_succeed?
      rand <= success_rate
    end

    def simulate_delay
      sleep(delay)
    end

    def mock_success_response(observation, request_id)
      {
        observation_id: observation.id,
        request_id: request_id,
        risk_assessment: mock_risk_assessment(observation),
        recommendations: mock_recommendations(observation),
        score: rand(1..100)
      }
    end

    def mock_risk_assessment(observation)
      window_type = observation.observations["window_type"]
      vegetation = observation.observations["vegetation_type"]
      distance = observation.observations["distance_to_window"].to_f

      case
      when distance < 10
        "HIGH"
      when distance < 30
        "MEDIUM"
      else
        "LOW"
      end
    end

    def mock_recommendations(observation)
      recommendations = []

      if observation.observations["distance_to_window"].to_f < 30
        recommendations << "Consider increasing distance between vegetation and windows"
      end

      if observation.observations["window_type"] == "single"
        recommendations << "Upgrade to double-pane or tempered glass windows"
      end

      if observation.observations["attic_vent_screen"] == "false"
        recommendations << "Install mesh screening on attic vents"
      end

      recommendations
    end
  end
end
