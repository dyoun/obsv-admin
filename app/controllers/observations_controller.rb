class ObservationsController < ApplicationController
  def index
    @observations = Observation.includes(:property, mitigations: [])
                              .recent
                              .page(params[:page])
                              .per(10)
    
    # Get latest mitigation ID from session to highlight it
    @latest_mitigation_id = session.delete(:latest_mitigation_id)
  end

  def new
    @observation = Observation.new
    @property = find_or_create_property
  end

  def create
    @property = find_or_create_property
    @observation = @property.observations.build(observation_params)
    @observation.recorded_at = Time.current

    if @observation.save
      redirect_to new_observation_path, notice: 'Observation recorded successfully!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def submit_to_fire_mitigation
    @observation = Observation.find(params[:id])
    
    result = FireMitigationService.submit_observation(@observation)
    
    # Create mitigation record to store the response
    mitigation = @observation.mitigations.create!(
      submitted_at: Time.current,
      status: result.success? ? 'success' : 'failure',
      request_id: extract_request_id(result.data),
      response_data: {
        message: result.message,
        data: result.data,
        metadata: result.metadata
      }
    )
    
    # Store mitigation ID in session to highlight it on the page
    session[:latest_mitigation_id] = mitigation.id
    
    if result.success?
      Rails.logger.info "Fire mitigation submission successful for observation #{@observation.id}: #{result.message}"
      flash[:notice] = 'Fire mitigation assessment completed successfully!'
    else
      Rails.logger.error "Fire mitigation submission failed for observation #{@observation.id}: #{result.message}"
      flash[:alert] = "Fire mitigation assessment failed: #{result.message}"
    end
    
    redirect_to observations_path
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = 'Observation not found'
    redirect_to observations_path
  rescue StandardError => e
    Rails.logger.error "Fire mitigation submission error: #{e.message}"
    flash[:alert] = 'An error occurred while submitting to fire mitigation service'
    redirect_back(fallback_location: observations_path)
  end

  private

  def observation_params
    params.require(:observation).permit(observations: {})
  end

  def find_or_create_property
    return Property.find(params[:property_id]) if params[:property_id].present?
    
    if params[:normalized_address].present?
      # Try to find existing property by normalized address
      property = Property.find_by(normalized_address: params[:normalized_address])
      return property if property

      # Create new property from normalized address
      address_parts = parse_address(params[:normalized_address])
      
      # Create property and skip address validation since address is already validated
      property = Property.new(
        name: "Property at #{address_parts[:street_address]}",
        property_type: 'residential',
        status: 'pending',
        **address_parts
      )
      
      # Set flag to skip address validation for this save
      property.instance_variable_set(:@skip_address_validation, true)
      property.save!
      property
    else
      # Create a basic property if no address provided
      Property.create!(
        name: "Unknown Property #{Time.current.strftime('%Y%m%d%H%M%S')}",
        property_type: 'residential',
        status: 'pending',
        street_address: 'Unknown',
        city: 'Unknown',
        country: 'US'
      )
    end
  end

  def parse_address(normalized_address)
    # Simple address parsing - in production, you might want more sophisticated parsing
    parts = normalized_address.split(', ')
    
    # Extract country and convert to 2-letter code
    country_part = parts[-1] || 'US'
    country_code = case country_part.downcase
                   when 'united states', 'usa'
                     'US'
                   when 'canada'
                     'CA'
                   when 'united kingdom', 'uk'
                     'GB'
                   else
                     country_part.length <= 3 ? country_part.upcase : 'US'
                   end
    
    # Extract state/province and postal code
    state_postal = parts[-2] || ''
    state_parts = state_postal.split(' ')
    
    {
      street_address: parts[0] || 'Unknown',
      city: parts[-3] || parts[-2] || 'Unknown',
      state_province: state_parts[0] || '',
      postal_code: state_parts[-1] || '',
      country: country_code,
      normalized_address: normalized_address
    }
  rescue => e
    Rails.logger.error "Address parsing failed: #{e.message}"
    {
      street_address: normalized_address.split(',').first || 'Unknown',
      city: 'Unknown',
      country: 'US',
      normalized_address: normalized_address
    }
  end
  
  def extract_request_id(data)
    data&.dig('request_id') || "req-#{Time.current.to_i}"
  end
end
