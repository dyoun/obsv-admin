class Observation < ApplicationRecord
  belongs_to :property

  validates :recorded_at, presence: true
  validates :observations, presence: true

  scope :recent, -> { order(recorded_at: :desc) }
  scope :recorded_between, ->(start_date, end_date) { where(recorded_at: start_date..end_date) }

  def custom_field_value(field_name)
    observations&.dig(field_name.to_s)
  end

  def set_custom_field(field_name, value)
    self.observations ||= {}
    self.observations[field_name.to_s] = value
  end

  def custom_fields
    observations&.keys || []
  end

  def recorded_today?
    recorded_at&.to_date == Date.current
  end
end
