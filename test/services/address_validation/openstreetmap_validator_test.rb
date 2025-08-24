require "test_helper"

class AddressValidation::OpenstreetmapValidatorTest < ActiveSupport::TestCase
  def setup
    @validator = AddressValidation::OpenstreetmapValidator.new(timeout: 5, rate_limit_delay: 0.1)
  end

  test "should validate valid address" do
    stub_successful_response
    
    result = @validator.validate("1600 Amphitheatre Parkway, Mountain View, CA")
    
    assert result.valid?
    assert result.coordinates_available?
    assert_in_delta 37.4219999, result.latitude, 0.1
    assert_in_delta -122.0840575, result.longitude, 0.1
    assert result.formatted_address.present?
  end

  test "should handle empty address" do
    result = @validator.validate("")
    
    assert_not result.valid?
    assert_equal "Address cannot be blank", result.error_message
  end

  test "should handle address not found" do
    stub_empty_response
    
    result = @validator.validate("Nonexistent Address, Nowhere")
    
    assert_not result.valid?
    assert_equal "Address not found", result.error_message
  end

  test "should handle rate limit" do
    stub_rate_limit_response
    
    result = @validator.validate("123 Main St, Anytown, USA")
    
    assert_not result.valid?
    assert_equal "Rate limit exceeded", result.error_message
  end

  test "should handle service error" do
    stub_service_error
    
    result = @validator.validate("123 Main St, Anytown, USA")
    
    assert_not result.valid?
    assert_equal "Service error: 500", result.error_message
  end

  test "should handle timeout" do
    stub_timeout
    
    result = @validator.validate("123 Main St, Anytown, USA")
    
    assert_not result.valid?
    assert_equal "Request timeout", result.error_message
  end

  test "should handle invalid JSON response" do
    stub_invalid_json
    
    result = @validator.validate("123 Main St, Anytown, USA")
    
    assert_not result.valid?
    assert_equal "Invalid response format", result.error_message
  end

  private

  def stub_successful_response
    response_body = [{
      "lat" => "37.4219999",
      "lon" => "-122.0840575",
      "display_name" => "1600, Amphitheatre Parkway, Mountain View, Santa Clara County, California, 94043, United States"
    }].to_json

    stub_request(:get, /nominatim.openstreetmap.org/)
      .to_return(status: 200, body: response_body, headers: { 'Content-Type' => 'application/json' })
  end

  def stub_empty_response
    stub_request(:get, /nominatim.openstreetmap.org/)
      .to_return(status: 200, body: "[]", headers: { 'Content-Type' => 'application/json' })
  end

  def stub_rate_limit_response
    stub_request(:get, /nominatim.openstreetmap.org/)
      .to_return(status: 429, body: "Rate limit exceeded")
  end

  def stub_service_error
    stub_request(:get, /nominatim.openstreetmap.org/)
      .to_return(status: 500, body: "Internal Server Error")
  end

  def stub_timeout
    stub_request(:get, /nominatim.openstreetmap.org/)
      .to_timeout
  end

  def stub_invalid_json
    stub_request(:get, /nominatim.openstreetmap.org/)
      .to_return(status: 200, body: "invalid json")
  end
end