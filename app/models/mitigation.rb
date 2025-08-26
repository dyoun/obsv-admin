class Mitigation < ApplicationRecord
  belongs_to :observation

  validates :submitted_at, presence: true
  validates :status, presence: true, inclusion: { in: %w[success failure pending] }
  validates :property_id, presence: true
  validates :response_data, presence: true

  scope :successful, -> { where(status: "success") }
  scope :failed, -> { where(status: "failure") }
  scope :recent, -> { order(submitted_at: :desc) }

  def success?
    status == "success"
  end

  def failure?
    status == "failure"
  end

  def performance_time
    response_data.dig("data", "performance")
  end

  def risk_assessment
    response_data.dig("data", "result")
  end

  def mitigation_recommendations
    # Handle both old single result and new array format
    if response_data.dig("data", "result").is_a?(Array)
      response_data.dig("data", "result")
    else
      response_data.dig("data", "result", "mitigations")
    end
  end

  def safe_distance
    # For array format, get from first result that has distance info
    if response_data.dig("data", "result").is_a?(Array)
      distance_result = response_data.dig("data", "result").find { |r| r["safe_distance"] }
      distance_result&.dig("safe_distance")
    else
      response_data.dig("data", "result", "safe_distance")
    end
  end

  def safe_distance_diff
    # For array format, get from first result that has distance info
    if response_data.dig("data", "result").is_a?(Array)
      distance_result = response_data.dig("data", "result").find { |r| r["safe_distance_diff"] }
      distance_result&.dig("safe_distance_diff")
    else
      response_data.dig("data", "result", "safe_distance_diff")
    end
  end

  def current_distance
    # For array format, get from first result that has distance info
    if response_data.dig("data", "result").is_a?(Array)
      distance_result = response_data.dig("data", "result").find { |r| r["distance"] }
      distance_result&.dig("distance")
    else
      response_data.dig("data", "result", "distance")
    end
  end

  def safe_distance_calc
    # For array format, get from first result that has distance info
    if response_data.dig("data", "result").is_a?(Array)
      distance_result = response_data.dig("data", "result").find { |r| r["safe_distance_calc"] }
      distance_result&.dig("safe_distance_calc")
    else
      response_data.dig("data", "result", "safe_distance_calc")
    end
  end
end
