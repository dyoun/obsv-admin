module FireMitigation
  class ClientFactory
    DEFAULT_CLIENT_TYPE = :http

    def self.create(type = nil, **options)
      client_type = type || Rails.application.config.fire_mitigation_client || DEFAULT_CLIENT_TYPE

      case client_type.to_sym
      when :http
        HttpClient.new(**options)
      when :mock
        MockClient.new(**options)
      when :null
        NullClient.new(**options)
      else
        raise ArgumentError, "Unknown client type: #{client_type}"
      end
    end
  end
end