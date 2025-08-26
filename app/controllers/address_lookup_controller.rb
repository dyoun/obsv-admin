class AddressLookupController < ApplicationController
  def index
  end

  def search
    address = params[:address]

    if address.blank?
      render json: { error: "Address is required" }, status: :bad_request
      return
    end

    validator = AddressValidatorFactory.create
    result = validator.validate(address)

    if result.valid?
      render json: {
        success: true,
        formatted_address: result.formatted_address,
        latitude: result.latitude,
        longitude: result.longitude,
        coordinates_available: result.coordinates_available?
      }
    else
      render json: {
        success: false,
        error: result.error_message
      }
    end
  rescue StandardError => e
    Rails.logger.error "Address lookup failed: #{e.message}"
    render json: { error: "Address lookup service unavailable" }, status: :service_unavailable
  end
end
