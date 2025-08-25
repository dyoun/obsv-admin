class ObservationsController < ApplicationController
  def index
    @observations = Observation.includes(:property)
                              .recent
                              .page(params[:page])
                              .per(10)
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
end
