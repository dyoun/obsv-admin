class AddressValidatorFactory
  DEFAULT_VALIDATOR = :openstreetmap

  def self.create(type = nil)
    validator_type = type || Rails.application.config.address_validator || DEFAULT_VALIDATOR
    
    case validator_type.to_sym
    when :openstreetmap
      AddressValidation::OpenstreetmapValidator.new
    when :null
      AddressValidation::NullValidator.new
    else
      raise ArgumentError, "Unknown validator type: #{validator_type}"
    end
  end
end