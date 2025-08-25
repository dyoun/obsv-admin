# Fire Mitigation Service

A comprehensive, enterprise-grade service for submitting property observations to fire mitigation rules engines using SOLID principles and proven design patterns.

## Overview

The Fire Mitigation Service provides a clean, extensible interface for submitting observation data to external fire risk assessment systems. Built with SOLID principles and enterprise design patterns, it ensures reliability, testability, and maintainability while handling both individual and batch submissions.

## Architecture

### SOLID Principles Implementation

#### Single Responsibility Principle (SRP)
Each component has one clearly defined responsibility:
- **PayloadBuilder**: Constructs API payloads from observations
- **HttpClient**: Handles HTTP communication with external services
- **SubmissionResult**: Represents the outcome of a submission operation
- **BatchResult**: Manages results from batch operations
- **ClientFactory**: Creates appropriate client instances

#### Open/Closed Principle (OCP)
- **BaseClient**: Abstract base class allows extension without modification
- **New client types** can be added without changing existing code
- **Strategy pattern** enables runtime behavior changes

#### Liskov Substitution Principle (LSP)
- All client implementations (`HttpClient`, `MockClient`, `NullClient`) are interchangeable
- Any client can be substituted without breaking application functionality

#### Interface Segregation Principle (ISP)
- Clean, focused interfaces for each responsibility area
- Clients depend only on methods they actually use
- No forced dependencies on unused functionality

#### Dependency Inversion Principle (DIP)
- High-level service depends on abstractions (`BaseClient`), not concrete implementations
- Factory pattern provides runtime dependency injection
- Configuration-driven client selection

## Enterprise Design Patterns

### Factory Pattern
```ruby
# Runtime client selection
client = FireMitigation::ClientFactory.create(:http)
client = FireMitigation::ClientFactory.create(:mock, success_rate: 0.8)
client = FireMitigation::ClientFactory.create(:null)
```

### Strategy Pattern
Different submission strategies for various environments:
- **HTTP Strategy**: Production submissions to real API
- **Mock Strategy**: Testing with simulated responses
- **Null Strategy**: Development environment with no-op behavior

### Value Objects
Immutable objects that encapsulate operation results:
- **SubmissionResult**: Single operation outcomes
- **BatchResult**: Batch operation summaries

### Builder Pattern
**PayloadBuilder** separates complex payload construction from usage:
```ruby
payload = PayloadBuilder.build_for_observation(observation, request_id: custom_id)
```

### Facade Pattern
**FireMitigationService** provides a simplified interface to the complex subsystem:
```ruby
result = FireMitigationService.submit_observation(observation)
```

## Service Components

### Core Classes

#### FireMitigation::BaseClient
Abstract base class defining the client interface:
```ruby
def submit_observation(observation, request_id: nil)
  raise NotImplementedError
end

def submit_batch(observations, options = {})
  raise NotImplementedError  
end
```

#### FireMitigation::HttpClient
Production HTTP client with comprehensive error handling:
- **Configurable endpoints**: Default `localhost:5000/rules/`
- **Timeout management**: Configurable connection and read timeouts
- **Error recovery**: Structured error handling for network issues
- **Response parsing**: JSON response parsing with fallbacks
- **Logging integration**: Structured logging for monitoring

#### FireMitigation::MockClient
Testing client with realistic simulation:
- **Configurable success rates**: Simulate failure scenarios
- **Response delays**: Test timeout handling
- **Realistic responses**: Mock data that mirrors real API responses
- **Risk assessment simulation**: Dynamic risk scoring based on observation data

#### FireMitigation::NullClient
Development no-op client:
- **Silent operation**: No external API calls
- **Always successful**: Returns success without side effects
- **Logging integration**: Tracks operations for debugging

### Data Transfer Objects

#### SubmissionResult
Encapsulates single submission outcomes:
```ruby
result = SubmissionResult.new(
  success: true,
  message: "Submission successful",
  data: { risk_score: 75 },
  metadata: { http_status: 200, timestamp: Time.current }
)

# Usage
if result.success?
  puts "Success: #{result.message}"
  puts "Risk score: #{result.data[:risk_score]}"
end
```

#### BatchResult
Manages batch operation summaries:
```ruby
batch = BatchResult.new(
  total: 10,
  successful: 8,
  failed: 2,
  results: [...]
)

puts "Success rate: #{batch.success_rate}%"
puts "Status: #{batch.summary[:status]}"
```

### Payload Structure

#### API Payload Format
The service generates payloads matching the required format:
```json
{
  "observations": {
    "risk_type": "windows",
    "window_type": "single",
    "vegetation_type": "tree", 
    "distance": 20.5
  },
  "request_id": "obs-123-1640995200"
}
```

#### Field Mapping
| Observation Field | API Field | Transformation |
|------------------|-----------|----------------|
| `window_type` | `window_type` | Direct mapping |
| `vegetation_type` | `vegetation_type` | Direct mapping |
| `distance_to_window` | `distance` | Convert to float |
| N/A | `risk_type` | Always "windows" |
| N/A | `request_id` | Generated or provided |

## Configuration

### Environment-Based Setup

#### Development Environment
```ruby
# config/environments/development.rb
config.fire_mitigation_client = :mock
```

#### Test Environment
```ruby
# config/environments/test.rb
config.fire_mitigation_client = :null
```

#### Production Environment
```ruby
# config/environments/production.rb
config.fire_mitigation_client = :http
```

### Runtime Configuration
```ruby
# Override default configuration
FireMitigationService.configure_client(:mock)

# Custom client options
result = FireMitigationService.submit_observation(
  observation,
  client_options: {
    base_url: 'https://api.firemitigation.com',
    timeout: 45
  }
)
```

## Usage Examples

### Basic Submission
```ruby
observation = Observation.find(1)
result = FireMitigationService.submit_observation(observation)

if result.success?
  puts "Submitted successfully!"
  puts "Response: #{result.data}"
else
  puts "Failed: #{result.message}"
  puts "Error code: #{result.error_code}"
  puts "HTTP status: #{result.http_status}"
end
```

### Custom Request ID
```ruby
result = FireMitigationService.submit_observation(
  observation,
  request_id: "custom-request-#{Date.current}"
)
```

### Batch Submissions
```ruby
recent_observations = Observation.recent.limit(50)
batch_result = FireMitigationService.submit_batch_observations(
  recent_observations,
  request_prefix: 'weekly-batch'
)

puts "Batch Summary:"
puts "Total: #{batch_result.total}"
puts "Successful: #{batch_result.successful}"
puts "Failed: #{batch_result.failed}"
puts "Success Rate: #{batch_result.success_rate}%"

# Handle failures
batch_result.failed_results.each do |failed|
  puts "Failed observation #{failed[:observation_id]}: #{failed[:message]}"
end
```

### Error Handling
```ruby
begin
  result = FireMitigationService.submit_observation(observation)
rescue StandardError => e
  Rails.logger.error "Submission failed unexpectedly: #{e.message}"
end

# Result-based error handling (preferred)
result = FireMitigationService.submit_observation(observation)
case result.error_code
when 'BAD_REQUEST'
  # Handle invalid data
when 'NOT_FOUND'
  # Handle missing endpoint
when 'SERVER_ERROR'
  # Handle service issues
when 'TIMEOUT'
  # Handle network timeouts
end
```

## Integration Points

### Observation Model Integration
```ruby
class Observation < ApplicationRecord
  after_create :submit_to_fire_mitigation, if: :should_submit?

  private

  def submit_to_fire_mitigation
    FireMitigationService.submit_observation(self)
  end

  def should_submit?
    # Business logic for when to submit
    %w[tree shrub].include?(observations['vegetation_type'])
  end
end
```

### Controller Integration
```ruby
class ObservationsController < ApplicationController
  def create
    @observation = @property.observations.build(observation_params)
    @observation.recorded_at = Time.current

    if @observation.save
      # Submit to fire mitigation service
      result = FireMitigationService.submit_observation(@observation)
      
      if result.success?
        flash[:notice] = 'Observation recorded and submitted for risk assessment'
      else
        flash[:warning] = 'Observation recorded, but risk assessment submission failed'
      end
      
      redirect_to new_observation_path
    else
      render :new, status: :unprocessable_entity
    end
  end
end
```

## Testing

### Unit Testing
```ruby
# Test with mock client
RSpec.describe FireMitigationService do
  let(:observation) { create(:observation) }
  
  before do
    allow(FireMitigation::ClientFactory).to receive(:create)
      .and_return(instance_double(FireMitigation::MockClient))
  end
  
  it 'submits observation successfully' do
    result = FireMitigationService.submit_observation(observation)
    expect(result.success?).to be true
  end
end
```

### Integration Testing
```ruby
# Test with null client in test environment
feature 'Fire mitigation integration' do
  scenario 'submitting observation triggers fire mitigation service' do
    # Observation creation triggers service call
    expect {
      create_observation_via_form
    }.to change { fire_mitigation_submissions_count }.by(1)
  end
end
```

### Performance Testing
```ruby
# Test batch performance
RSpec.describe 'Batch submission performance' do
  it 'handles large batches efficiently' do
    observations = create_list(:observation, 100)
    
    result = nil
    expect {
      result = FireMitigationService.submit_batch_observations(observations)
    }.to perform_under(5).seconds
    
    expect(result.total).to eq(100)
  end
end
```

## Monitoring and Logging

### Structured Logging
The service provides comprehensive logging for monitoring:
```ruby
# Successful submissions
Rails.logger.info "[FireMitigation::HttpClient] Success for observation 123: {...}"

# Failed submissions  
Rails.logger.error "[FireMitigation::HttpClient] Server error: Internal Server Error"

# Batch operations
Rails.logger.info "[FireMitigation::HttpClient] Submitting to fire mitigation service: {...}"
```

### Metrics Collection
```ruby
# Custom metrics integration
class FireMitigationService
  def self.submit_observation_with_metrics(observation, **options)
    start_time = Time.current
    result = submit_observation(observation, **options)
    duration = Time.current - start_time
    
    # Record metrics
    Metrics.record('fire_mitigation.submission.duration', duration)
    Metrics.record('fire_mitigation.submission.success', result.success? ? 1 : 0)
    
    result
  end
end
```

## Error Recovery

### Retry Logic
```ruby
class FireMitigation::HttpClient
  MAX_RETRIES = 3
  RETRY_DELAY = 1.0

  def submit_observation_with_retry(observation, retries: MAX_RETRIES)
    attempt = 0
    
    begin
      attempt += 1
      submit_observation(observation)
    rescue Net::TimeoutError, Net::OpenTimeout => e
      if attempt < retries
        sleep(RETRY_DELAY * attempt) # Exponential backoff
        retry
      else
        failure_result("Max retries exceeded: #{e.message}")
      end
    end
  end
end
```

### Circuit Breaker Pattern
```ruby
class FireMitigation::CircuitBreaker
  def initialize(failure_threshold: 5, timeout: 60)
    @failure_threshold = failure_threshold
    @timeout = timeout
    @failure_count = 0
    @last_failure_time = nil
    @state = :closed
  end

  def call
    case @state
    when :open
      return failure_result('Circuit breaker open') unless can_retry?
    when :half_open
      # Allow one request through
    end

    result = yield
    handle_success if result.success?
    handle_failure unless result.success?
    
    result
  end
end
```

## Performance Considerations

### Connection Pooling
```ruby
# For high-volume production use
class FireMitigation::HttpClient
  def initialize(pool_size: 10)
    @connection_pool = ConnectionPool.new(size: pool_size) do
      Net::HTTP.new(uri.host, uri.port)
    end
  end
end
```

### Async Processing
```ruby
# Background job integration
class FireMitigationJob < ApplicationJob
  queue_as :default

  def perform(observation_id)
    observation = Observation.find(observation_id)
    result = FireMitigationService.submit_observation(observation)
    
    unless result.success?
      # Handle failed submission
      Rails.logger.error "Background submission failed: #{result.message}"
    end
  end
end

# Trigger from model
class Observation < ApplicationRecord
  after_create :queue_fire_mitigation_submission

  private

  def queue_fire_mitigation_submission
    FireMitigationJob.perform_later(id)
  end
end
```

## Security Considerations

### API Key Management
```ruby
class FireMitigation::HttpClient
  def initialize(api_key: nil)
    @api_key = api_key || Rails.application.credentials.fire_mitigation_api_key
  end

  private

  def make_request(payload)
    # Add authentication headers
    request['Authorization'] = "Bearer #{@api_key}" if @api_key
    request['X-API-Key'] = @api_key if @api_key
  end
end
```

### Data Sanitization
```ruby
class FireMitigation::PayloadBuilder
  private

  def sanitize_data(data)
    # Remove sensitive information
    # Validate data types
    # Apply business rules
  end
end
```

This Fire Mitigation Service provides a robust, enterprise-grade foundation for integrating property observations with external fire risk assessment systems while maintaining high standards of reliability, testability, and maintainability.