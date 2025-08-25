class PropertiesController < ApplicationController
  def index
    @properties = Property.includes(:observations)
                         .order(:created_at => :desc)
                         .page(params[:page])
                         .per(20)
  end
end