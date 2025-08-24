module AddressValidation
  class ValidationResult
    attr_reader :valid, :latitude, :longitude, :formatted_address, :error_message

    def initialize(valid:, latitude: nil, longitude: nil, formatted_address: nil, error_message: nil)
      @valid = valid
      @latitude = latitude
      @longitude = longitude
      @formatted_address = formatted_address
      @error_message = error_message
    end

    def valid?
      @valid
    end

    def invalid?
      !@valid
    end

    def coordinates_available?
      latitude.present? && longitude.present?
    end
  end
end