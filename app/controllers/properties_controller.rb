class PropertiesController < ApplicationController
  def index
    @properties = Property.includes(:observations)
                         .order(:created_at => :desc)
                         .page(params[:page])
                         .per(20)
  end
  
  def edit
    @property = Property.find(params[:id])
  end
  
  def update
    @property = Property.find(params[:id])
    
    if @property.update(property_params)
      redirect_to properties_path, notice: 'Property updated successfully!'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  private
  
  def property_params
    params.require(:property).permit(:name, :property_type, :status, :street_address, 
                                   :city, :state_province, :postal_code, :country)
  end
end