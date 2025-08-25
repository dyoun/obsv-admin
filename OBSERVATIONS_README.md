# Property Observations System

A comprehensive system for recording and managing property-specific observations with flexible, customizable forms and address integration.

## Overview

The Observations system allows users to record detailed property assessments with structured data collection. It integrates seamlessly with the address lookup system to provide location-aware data collection for property inspections, risk assessments, and compliance monitoring.

## Features

### 🏠 Property-Linked Observations
- **Automatic Property Association**: Links observations to properties via normalized addresses
- **Property Auto-Creation**: Creates new properties automatically from address lookup data
- **Address Integration**: Seamlessly integrates with OpenStreetMap address validation
- **Flexible Property Management**: Handles existing and new properties transparently

### 📋 Customizable Form Fields
- **Attic Vent Screen**: Yes/No selection for ventilation screening presence
- **Roof Type Classification**: A, B, C categorization system
- **Wildfire Risk Assessment**: Four-level risk classification (A-D: Low to Extreme)
- **Window Type Documentation**: Single pane, double pane, or tempered glass
- **Vegetation Analysis**: Primary vegetation type around property
- **Distance Measurements**: Precise distance tracking from vegetation to windows

### 💾 Flexible Data Storage
- **JSON-Based Storage**: Uses PostgreSQL JSON fields for flexible data structure
- **Schema-less Design**: Easily extensible without database migrations
- **Custom Field Support**: Add new observation types without code changes
- **Timestamped Records**: Automatic recording timestamps for audit trails

### 🎨 User Experience
- **Responsive Design**: Works on desktop, tablet, and mobile devices
- **Real-time Validation**: Client-side validation with visual feedback
- **Progressive Enhancement**: Works with or without JavaScript
- **Accessible Forms**: Screen reader friendly with proper ARIA labels

## Technical Architecture

### Models

#### Observation
```ruby
class Observation < ApplicationRecord
  belongs_to :property
  
  validates :recorded_at, presence: true
  validates :observations, presence: true
  
  scope :recent, -> { order(recorded_at: :desc) }
  scope :recorded_between, ->(start_date, end_date) { where(recorded_at: start_date..end_date) }
end
```

**Fields:**
- `observations` (JSON) - Flexible storage for all form data
- `notes` (TEXT) - Additional free-form notes
- `recorded_at` (DATETIME) - When observation was recorded
- `property_id` (INTEGER) - Foreign key to properties table

#### Property Integration
- Observations belong to properties via foreign key relationship
- Properties are auto-created from normalized addresses when needed
- Supports finding existing properties by normalized address

### Controllers

#### ObservationsController
- **`new`**: Display observation form, handle property association
- **`create`**: Process form submission, save observation data
- **Smart Property Handling**: Automatically finds or creates properties

**Key Methods:**
- `find_or_create_property`: Intelligent property association logic
- `parse_address`: Converts normalized addresses into property attributes
- `observation_params`: Strong parameter filtering for security

### Database Schema

```sql
CREATE TABLE observations (
  id BIGINT PRIMARY KEY,
  observations JSON NOT NULL DEFAULT '{}',
  notes TEXT,
  recorded_at DATETIME NOT NULL,
  property_id BIGINT NOT NULL REFERENCES properties(id),
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- Indexes for performance
CREATE INDEX idx_observations_property_id ON observations(property_id);
CREATE INDEX idx_observations_recorded_at ON observations(recorded_at);
CREATE INDEX idx_observations_property_recorded ON observations(property_id, recorded_at);
```

## Data Structure

### Observation Data Format
```json
{
  "attic_vent_screen": "true",
  "roof_type": "a",
  "wildfire_risk": "b", 
  "window_type": "double",
  "vegetation_type": "tree",
  "distance_to_window": "8.5"
}
```

### Field Specifications

| Field | Type | Values | Description |
|-------|------|--------|-------------|
| `attic_vent_screen` | Boolean String | "true", "false" | Presence of mesh screening on attic vents |
| `roof_type` | String | "a", "b", "c" | Roof construction classification |
| `wildfire_risk` | String | "a", "b", "c", "d" | Risk level (Low, Moderate, High, Extreme) |
| `window_type` | String | "single", "double", "tempered" | Window glazing type |
| `vegetation_type` | String | "tree", "shrub", "grass" | Primary vegetation around property |
| `distance_to_window` | Numeric String | "0.0" to "999.9" | Distance in feet from vegetation to nearest window |

## Usage Examples

### Creating an Observation

#### Via Address Lookup Integration
1. User searches for address in lookup form
2. Clicks "Record Observation" or navigates to `/observations/new?normalized_address=...`
3. Form pre-populates with address information
4. System finds existing property or creates new one
5. User fills out observation fields and submits

#### Direct Property Association
```ruby
# Find existing property
property = Property.find_by(normalized_address: "123 Main St, Anytown, CA")

# Create observation
observation = property.observations.create!(
  observations: {
    attic_vent_screen: "true",
    roof_type: "b",
    wildfire_risk: "c", 
    window_type: "double",
    vegetation_type: "tree",
    distance_to_window: "12.0"
  },
  notes: "Annual inspection - good condition",
  recorded_at: Time.current
)
```

### Querying Observations

```ruby
# Recent observations across all properties
recent = Observation.recent.limit(10)

# Property-specific observations
property_observations = property.observations.recent

# Date range queries
last_month = Observation.recorded_between(1.month.ago, Time.current)

# Access custom field data
observation.observations["roof_type"]           # => "b"
observation.observations["distance_to_window"]  # => "12.0"
```

### Adding Custom Fields

The JSON storage system allows easy extension:

```ruby
observation.observations["custom_field"] = "custom_value"
observation.observations["inspector_name"] = "John Doe"
observation.observations["weather_conditions"] = "sunny"
observation.save!
```

## API Endpoints

### Web Interface
- `GET /observations/new` - Display observation form
- `POST /observations` - Submit observation data

### Query Parameters
- `normalized_address` - Pre-associate with property by address
- `property_id` - Direct property association

## Integration Points

### Address Lookup System
- Seamless handoff from address validation to observation recording
- Automatic property creation from validated addresses
- Consistent address normalization across systems

### Property Management
- One-to-many relationship with properties
- Automatic property discovery and creation
- Address-based property matching

### Future Extensions
- **API Endpoints**: RESTful API for mobile apps
- **Bulk Import**: CSV/Excel import for historical data
- **Reporting Dashboard**: Analytics and visualization
- **Custom Form Builder**: Dynamic form configuration
- **Integration APIs**: Third-party system connectivity

## Performance Considerations

### Database Optimization
- Indexed on property_id and recorded_at for fast queries
- JSON field indexing for specific observation types (PostgreSQL)
- Efficient property lookups via normalized_address

### Scalability
- Horizontal scaling friendly design
- Minimal database schema dependencies
- Cacheable property lookups
- Efficient JSON storage and retrieval

## Security Features

### Input Validation
- Server-side parameter filtering
- Client-side validation with fallbacks
- SQL injection protection via parameterized queries
- XSS protection through proper escaping

### Access Control
- CSRF token protection on all forms
- Future-ready for role-based permissions
- Audit trail through timestamps

## Development & Testing

### Running Tests
```bash
rails test test/models/observation_test.rb
rails test test/controllers/observations_controller_test.rb
```

### Adding New Fields
1. Update form in `app/views/observations/new.html.erb`
2. Add validation if needed in `app/models/observation.rb`
3. Update tests to cover new fields
4. No database migration required (JSON storage)

## Production Deployment

### Environment Variables
- `DATABASE_URL` - PostgreSQL connection string
- `RAILS_ENV=production` - Production environment
- `SECRET_KEY_BASE` - Session encryption key

### Performance Monitoring
- Monitor JSON field query performance
- Track property creation vs. lookup ratios
- Monitor form submission success rates
- Alert on validation failure spikes

This observations system provides a robust foundation for property data collection while maintaining flexibility for future requirements and integrations.