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

    def build_observations_array
      observations_data = []

      # Windows risk assessment
      if has_window_data?
        observations_data << {
          risk_type: "windows",
          window_type: extract_window_type,
          vegetation_type: extract_vegetation_type,
          distance: extract_distance
        }
      end

      # Attic risk assessment
      if has_attic_data?
        observations_data << {
          risk_type: "attic",
          attic_vent_screens: extract_attic_vent_screens
        }
      end

      # Roof risk assessment
      if has_roof_data?
        observations_data << {
          risk_type: "roof",
          roof_type: extract_roof_type,
          wild_fire_risk: extract_wildfire_risk
        }
      end

      observations_data
    end

    def build_request_id
      request_id || generate_request_id
    end

    def extract_window_type
      observation.observations["window_type"] || "unknown"
    end

    def extract_vegetation_type
      observation.observations["vegetation_type"] || "unknown"
    end

    def extract_distance
      distance_value = observation.observations["distance_to_window"]
      return 0 if distance_value.blank?

      distance_value.to_f.round(1)
    end

    def generate_request_id
      "obs-#{observation.id}-#{Time.current.to_i}"
    end

    # Data availability checks
    def has_window_data?
      observation.observations["window_type"].present? ||
      observation.observations["vegetation_type"].present? ||
      observation.observations["distance_to_window"].present?
    end

    def has_attic_data?
      observation.observations["attic_vent_screen"].present?
    end

    def has_roof_data?
      observation.observations["roof_type"].present? ||
      observation.observations["wildfire_risk"].present?
    end

    # New extraction methods
    def extract_attic_vent_screens
      case observation.observations["attic_vent_screen"]
      when "true", true
        true
      when "false", false
        false
      else
        false
      end
    end

    def extract_roof_type
      observation.observations["roof_type"] || "unknown"
    end

    def extract_wildfire_risk
      observation.observations["wildfire_risk"] || "unknown"
    end
  end
end
