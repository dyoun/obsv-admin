module AddressValidatable
  extend ActiveSupport::Concern

  included do
    validates :street_address, presence: true, length: { minimum: 5, maximum: 255 }
    validates :city, presence: true, length: { minimum: 2, maximum: 100 }
    validates :state_province, length: { maximum: 100 }, allow_blank: true
    validates :postal_code, length: { maximum: 20 }, allow_blank: true
    validates :country, presence: true, length: { minimum: 2, maximum: 3 }
    validates :latitude, :longitude, numericality: true, allow_nil: true

    validate :address_geocodable, if: :should_validate_address?
  end

  private

  def address_geocodable
    return unless address_validator.present?

    result = address_validator.validate(full_address)
    unless result.valid?
      errors.add(:base, "Address could not be validated: #{result.error_message}")
    else
      self.latitude = result.latitude
      self.longitude = result.longitude
      self.normalized_address = result.formatted_address
    end
  end

  def should_validate_address?
    return false if @skip_address_validation

    street_address_changed? || city_changed? || state_province_changed? ||
    postal_code_changed? || country_changed?
  end

  def full_address
    [ street_address, city, state_province, postal_code, country ].compact.join(", ")
  end

  def address_validator
    @address_validator ||= AddressValidatorFactory.create
  end
end
