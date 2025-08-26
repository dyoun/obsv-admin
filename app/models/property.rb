class Property < ApplicationRecord
  include AddressValidatable

  has_many :observations, dependent: :destroy

  validates :name, presence: true, length: { minimum: 2, maximum: 255 }
  validates :property_type, presence: true, inclusion: {
    in: %w[residential commercial industrial mixed_use land]
  }
  validates :status, presence: true, inclusion: {
    in: %w[active inactive pending sold]
  }

  scope :active, -> { where(status: "active") }
  scope :by_type, ->(type) { where(property_type: type) }
  scope :in_city, ->(city) { where(city: city) }
  scope :near_coordinates, ->(lat, lng, radius_km = 10) {
    where(
      "earth_distance(ll_to_earth(?, ?), ll_to_earth(latitude, longitude)) < ?",
      lat, lng, radius_km * 1000
    )
  }

  def full_address
    [ street_address, city, state_province, postal_code, country ].compact.join(", ")
  end

  def coordinates_available?
    latitude.present? && longitude.present?
  end

  def distance_to(other_property)
    return nil unless coordinates_available? && other_property.coordinates_available?

    calculate_distance(latitude, longitude, other_property.latitude, other_property.longitude)
  end

  private

  def calculate_distance(lat1, lng1, lat2, lng2)
    rad_per_deg = Math::PI / 180
    rlat1, rlng1, rlat2, rlng2 = [ lat1, lng1, lat2, lng2 ].map { |coord| coord * rad_per_deg }

    dlat = rlat2 - rlat1
    dlng = rlng2 - rlng1

    a = Math.sin(dlat/2)**2 + Math.cos(rlat1) * Math.cos(rlat2) * Math.sin(dlng/2)**2
    c = 2 * Math.asin(Math.sqrt(a))

    6371 * c # Distance in kilometers
  end
end
