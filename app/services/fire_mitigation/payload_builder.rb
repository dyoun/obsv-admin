module FireMitigation
  class PayloadBuilder
    def self.build_for_observation(observation, request_id: nil)
      new(observation, request_id).build
    end

    def initialize(observation, request_id = nil)
      @observation = observation
      @request_id = request_id
    end

    def build
      {
        observations: build_observations_array,
        property_id: observation.property.id.to_s
      }
    end

    private

    attr_reader :observation, :request_id

    def build_observations_data
      {
        risk_type: 'windows',
        window_type: extract_window_type,
        vegetation_type: extract_vegetation_type,
        distance: extract_distance
      }
    end

    def build_request_id
      request_id || generate_request_id
    end

    def extract_window_type
      observation.observations['window_type'] || 'unknown'
    end

    def extract_vegetation_type
      observation.observations['vegetation_type'] || 'unknown'
    end

    def extract_distance
      distance_value = observation.observations['distance_to_window']
      return 0 if distance_value.blank?
      
      distance_value.to_f.round(1)
    end

    def generate_request_id
      "obs-#{observation.id}-#{Time.current.to_i}"
    end
  end
end