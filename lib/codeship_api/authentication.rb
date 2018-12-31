module CodeshipApi
  class Authentication
    attr_reader :access_token, :expires_at, :organizations

    def initialize(access_token:, expires_at:, organizations:)
      @access_token = access_token
      @expires_at = Time.at(expires_at)
      @organizations = organizations.map do |org|
        Organization.new(
          uuid: org['uuid'],
          name: org['name'],
          scopes: org['scopes']
        )
      end
    end

    def valid?
      Time.now < @expires_at
    end
  end
end
