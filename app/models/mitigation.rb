class Mitigation < ApplicationRecord
  belongs_to :observation
  
  validates :submitted_at, presence: true
  validates :status, presence: true, inclusion: { in: %w[success failure pending] }
  validates :request_id, presence: true, uniqueness: true
  validates :response_data, presence: true
  
  scope :successful, -> { where(status: 'success') }
  scope :failed, -> { where(status: 'failure') }
  scope :recent, -> { order(submitted_at: :desc) }
  
  def success?
    status == 'success'
  end
  
  def failure?
    status == 'failure'
  end
  
  def performance_time
    response_data.dig('data', 'performance')
  end
  
  def risk_assessment
    response_data.dig('data', 'result')
  end
  
  def mitigation_recommendations
    response_data.dig('data', 'result', 'mitigations')
  end
  
  def safe_distance
    response_data.dig('data', 'result', 'safe_distance')
  end
end
