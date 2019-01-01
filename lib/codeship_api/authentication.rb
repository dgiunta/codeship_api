module CodeshipApi
  class Authentication
    attr_reader :access_token, :expires_at, :organizations

    def initialize(access_token:, expires_at:, organizations:)
      @access_token = access_token
      @expires_at = expires_at
      @organizations = organizations
    end

    def valid?
      Time.now < @expires_at
    end
  end
end
