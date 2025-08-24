module AddressValidation
  class NullValidator < BaseValidator
    def validate(address)
      validation_result(valid: true, formatted_address: address)
    end
  end
end