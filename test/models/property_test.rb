require "test_helper"

class PropertyTest < ActiveSupport::TestCase
  def setup
    @valid_attributes = {
      name: "Test Property",
      property_type: "residential",
      status: "active",
      street_address: "123 Main Street",
      city: "Anytown",
      state_province: "CA",
      postal_code: "90210",
      country: "US"
    }
  end

  test "should create property with valid attributes" do
    property = Property.new(@valid_attributes)
    assert property.valid?
  end

  test "should require name" do
    property = Property.new(@valid_attributes.except(:name))
    assert_not property.valid?
    assert_includes property.errors[:name], "can't be blank"
  end

  test "should require property_type" do
    property = Property.new(@valid_attributes.except(:property_type))
    assert_not property.valid?
    assert_includes property.errors[:property_type], "can't be blank"
  end

  test "should validate property_type inclusion" do
    property = Property.new(@valid_attributes.merge(property_type: "invalid"))
    assert_not property.valid?
    assert_includes property.errors[:property_type], "is not included in the list"
  end

  test "should validate status inclusion" do
    property = Property.new(@valid_attributes.merge(status: "invalid"))
    assert_not property.valid?
    assert_includes property.errors[:status], "is not included in the list"
  end

  test "should require street_address" do
    property = Property.new(@valid_attributes.except(:street_address))
    assert_not property.valid?
    assert_includes property.errors[:street_address], "can't be blank"
  end

  test "should require city" do
    property = Property.new(@valid_attributes.except(:city))
    assert_not property.valid?
    assert_includes property.errors[:city], "can't be blank"
  end

  test "should require country" do
    property = Property.new(@valid_attributes.merge(country: nil))
    assert_not property.valid?
    assert_includes property.errors[:country], "can't be blank"
  end

  test "should return full address" do
    property = Property.new(@valid_attributes)
    expected = "123 Main Street, Anytown, CA, 90210, US"
    assert_equal expected, property.full_address
  end

  test "should handle missing address components in full_address" do
    attrs = @valid_attributes.except(:state_province, :postal_code)
    property = Property.new(attrs)
    expected = "123 Main Street, Anytown, US"
    assert_equal expected, property.full_address
  end

  test "should check coordinates availability" do
    property = Property.new(@valid_attributes)
    assert_not property.coordinates_available?

    property.latitude = 34.0522
    property.longitude = -118.2437
    assert property.coordinates_available?
  end

  test "should calculate distance between properties" do
    property1 = Property.new(@valid_attributes.merge(latitude: 34.0522, longitude: -118.2437))
    property2 = Property.new(@valid_attributes.merge(latitude: 40.7128, longitude: -74.0060))

    distance = property1.distance_to(property2)
    assert distance.present?
    assert distance > 3000 # LA to NYC is roughly 3900km
  end

  test "should return nil distance when coordinates missing" do
    property1 = Property.new(@valid_attributes)
    property2 = Property.new(@valid_attributes.merge(latitude: 40.7128, longitude: -74.0060))

    assert_nil property1.distance_to(property2)
  end

  test "should scope active properties" do
    active_property = Property.create!(@valid_attributes.merge(status: "active"))
    inactive_property = Property.create!(@valid_attributes.merge(status: "inactive", name: "Inactive Property"))

    assert_includes Property.active, active_property
    assert_not_includes Property.active, inactive_property
  end

  test "should scope by property type" do
    residential = Property.create!(@valid_attributes.merge(property_type: "residential"))
    commercial = Property.create!(@valid_attributes.merge(property_type: "commercial", name: "Commercial Property"))

    assert_includes Property.by_type("residential"), residential
    assert_not_includes Property.by_type("residential"), commercial
  end

  test "should scope by city" do
    anytown_property = Property.create!(@valid_attributes.merge(city: "Anytown"))
    othercity_property = Property.create!(@valid_attributes.merge(city: "Othercity", name: "Other Property"))

    assert_includes Property.in_city("Anytown"), anytown_property
    assert_not_includes Property.in_city("Anytown"), othercity_property
  end
end
