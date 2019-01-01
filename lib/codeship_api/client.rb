module CodeshipApi
  class Client
    def initialize(username=USERNAME, password=PASSWORD)
      @username = username
      @password = password
    end

    def authenticated?
      authentication.valid?
    end

    def get(path)
      uri = URI(ROOT + path.sub(/^\//, ''))

      request = Net::HTTP::Get.new(uri, default_headers)
      response = http.request(request)

      if response.body.length > 0
        JSON.parse(response.body)
      else
        nil
      end
    end

    def post(path)
      uri = URI(ROOT + path.sub(/^\//, ''))

      request = Net::HTTP::Post.new(uri, default_headers)
      response = http.request(request)

      if response.body.length > 0
        JSON.parse(response.body)
      else
        nil
      end
    end

    def organizations
      @organizations ||= authentication.organizations
    end

    def projects
      organizations.flat_map(&:projects)
    end

    private

    attr_reader :username, :password

    def token
      authenticate unless authenticated?
      authentication.access_token
    end

    def authentication
      @authentication || authenticate
    end

    def authenticate
      uri = URI(ROOT + 'auth')

      request = Net::HTTP::Post.new(uri.request_uri, {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      }).tap do |req|
        req.basic_auth(username, password)
      end

      response = http.request request
      data = JSON.parse(response.body)

      @authentication = Authentication.new(
        access_token: data['access_token'],
        expires_at: Time.at(data['expires_at']),
        organizations: data['organizations'].map do |org|
          Organization.new(
            uuid: org['uuid'],
            name: org['name'],
            scopes: org['scopes']
          )
        end
      )
    end

    def http
      @http ||= begin
        uri = URI(ROOT)
        Net::HTTP.new(uri.host, uri.port).tap do |http|
          http.use_ssl = true
        end
      end
    end

    def default_headers
      {
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        "Authorization" => "Bearer #{token}"
      }
    end
  end
end
