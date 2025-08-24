module AddressValidation
  class BaseValidator
    def validate(address)
      raise NotImplementedError, "Subclasses must implement #validate"
    end

    protected

    def validation_result(valid:, latitude: nil, longitude: nil, formatted_address: nil, error_message: nil)
      ValidationResult.new(
        valid: valid,
        latitude: latitude,
        longitude: longitude,
        formatted_address: formatted_address,
        error_message: error_message
      )
    end
  end
end