# Rules Engine Project - Rules Admin

A Rails 8 application for managing properties with address validation and geographic capabilities.

## Features

### Property Management
- Create and manage properties with comprehensive validation
- Support for multiple property types (residential, commercial, industrial, mixed_use, land)
- Property status tracking (active, inactive, pending, sold)
- Geographic capabilities with coordinate storage and distance calculations

### Address Validation System
The application includes a robust address validation system built with SOLID principles and enterprise design patterns:

#### Components
- **Property Model** - Main domain model with validations and business logic
- **AddressValidatable Concern** - Single responsibility module for address validation logic
- **Address Validation Services** - Strategy and Factory pattern implementation:
  - `BaseValidator` - Abstract base class (Open/Closed principle)
  - `OpenstreetmapValidator` - OpenStreetMap API integration with rate limiting
  - `NullValidator` - No-op validator for testing/development environments
  - `ValidationResult` - Value object for validation results
  - `AddressValidatorFactory` - Factory pattern for validator selection

#### SOLID Principles Applied
- **Single Responsibility**: Each class has one reason to change
- **Open/Closed**: Easy to add new validators without modifying existing code
- **Liskov Substitution**: All validators implement the same interface
- **Interface Segregation**: Clean, focused interfaces
- **Dependency Inversion**: Property model depends on abstractions, not concrete implementations

#### Address Validation Features
- **OpenStreetMap Integration**: Validates addresses against OpenStreetMap's Nominatim API
- **Rate Limiting**: Built-in rate limiting to respect API guidelines
- **Error Handling**: Comprehensive error handling for network issues and invalid responses
- **Geocoding**: Automatic coordinate extraction and normalization
- **Configurable**: Easy to switch between validators or disable for testing

## Setup

### Ruby version
- Ruby 3.x (Rails 8.0.2+)

### System dependencies
- PostgreSQL
- Internet connection for address validation

### Configuration
Configure the address validator in `config/application.rb`:
```ruby
config.address_validator = :openstreetmap  # Default
# or
config.address_validator = :null  # For development/testing
```

### Database setup
```bash
rails db:create
rails db:migrate
rails db:seed
```

### Installation
```bash
bundle install
```

### How to run the test suite
```bash
rails test
```

The test suite includes:
- Model validations and business logic tests
- Address validation service tests with WebMock HTTP stubbing
- Geographic calculation tests
- Factory and strategy pattern tests

## Usage Examples

### Creating a Property
```ruby
property = Property.create!(
  name: "Downtown Office Building",
  property_type: "commercial",
  status: "active",
  street_address: "123 Main Street",
  city: "San Francisco",
  state_province: "CA",
  postal_code: "94102",
  country: "US"
)

# Address will be automatically validated and geocoded
puts property.latitude   # Populated from OpenStreetMap
puts property.longitude  # Populated from OpenStreetMap
puts property.normalized_address  # Formatted address from OSM
```

### Geographic Operations
```ruby
# Find properties near coordinates
nearby = Property.near_coordinates(37.7749, -122.4194, 5) # 5km radius

# Calculate distance between properties
distance_km = property1.distance_to(property2)

# Check if coordinates are available
if property.coordinates_available?
  puts "Property is located at #{property.latitude}, #{property.longitude}"
end
```

### Querying Properties
```ruby
# Scopes
active_properties = Property.active
residential_properties = Property.by_type("residential")
sf_properties = Property.in_city("San Francisco")

# Chaining scopes
active_residential_in_sf = Property.active.by_type("residential").in_city("San Francisco")
```

## Architecture

The address validation system follows enterprise patterns:

1. **Strategy Pattern**: Different validation strategies (OpenStreetMap, Null, etc.)
2. **Factory Pattern**: `AddressValidatorFactory` creates appropriate validator instances
3. **Dependency Injection**: Models depend on interfaces, not concrete classes
4. **Concern Pattern**: `AddressValidatable` encapsulates validation logic
5. **Value Objects**: `ValidationResult` encapsulates validation outcomes

This architecture makes the system:
- **Testable**: Easy to mock and stub external dependencies
- **Extensible**: New validators can be added without changing existing code
- **Maintainable**: Clear separation of concerns and single responsibilities
- **Configurable**: Runtime selection of validation strategies

## Services

- **Address Validation**: OpenStreetMap Nominatim API integration
- **Geocoding**: Automatic coordinate extraction and storage
- **Geographic Search**: PostGIS-ready coordinate indexing

## Testing

The application includes comprehensive tests covering:
- Property model validations and business logic
- Address validation services with HTTP mocking
- Geographic calculations and distance measurements
- Error handling and edge cases
- Factory and strategy pattern implementations

Run tests with: `rails test`
