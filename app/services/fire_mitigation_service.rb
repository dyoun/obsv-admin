class FireMitigationService
  def self.submit_observation(observation, request_id: nil, client_options: {})
    client = FireMitigation::ClientFactory.create(**client_options)
    client.submit_observation(observation, request_id: request_id)
  end

  def self.submit_batch_observations(observations, request_prefix: 'batch', client_options: {})
    client = FireMitigation::ClientFactory.create(**client_options)
    client.submit_batch(observations, request_prefix: request_prefix)
  end

  def self.configure_client(type)
    Rails.application.config.fire_mitigation_client = type
  end
end