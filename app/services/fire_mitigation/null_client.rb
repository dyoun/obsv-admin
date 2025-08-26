module FireMitigation
  class NullClient < BaseClient
    def submit_observation(observation, request_id: nil)
      Rails.logger.info "[FireMitigation::NullClient] Skipping submission for observation #{observation.id}"

      success_result(
        message: "Observation submission skipped (null client)",
        data: { observation_id: observation.id, request_id: request_id },
        metadata: { client_type: "null" }
      )
    end

    def submit_batch(observations, request_prefix: "batch")
      Rails.logger.info "[FireMitigation::NullClient] Skipping batch submission for #{observations.count} observations"

      results = observations.map.with_index do |observation, index|
        request_id = "#{request_prefix}-#{index + 1}-#{Time.current.to_i}"
        submit_observation(observation, request_id: request_id).to_h.merge(observation_id: observation.id)
      end

      BatchResult.new(
        total: observations.count,
        successful: observations.count,
        failed: 0,
        results: results
      )
    end
  end
end
