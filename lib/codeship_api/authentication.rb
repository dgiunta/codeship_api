module CodeshipApi
  class Authentication < Base
    api_attrs :expires_at, :organizations, :access_token

    def expires_at=(time_integer)
      @expires_at = Time.at(time_integer)
    end

    def organizations=(orgs)
      @organizations = orgs.map {|org| Organization.new(org) }
    end

    def valid?
      Time.now < expires_at
    end
  end
end
