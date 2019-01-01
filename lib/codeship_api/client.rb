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
      uri = URI.join(ROOT, path.sub(/^\//, ""))

      request = Net::HTTP::Get.new(uri, default_headers)
      response = http.request(request)

      parsed_json_from(response)
    end

    def post(path)
      uri = URI.join(ROOT, path.sub(/^\//, ""))

      request = Net::HTTP::Post.new(uri, default_headers)
      response = http.request(request)

      parsed_json_from(response)
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
      uri = URI.join(ROOT, 'auth')

      request = Net::HTTP::Post.new(uri.request_uri, {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      }).tap do |req|
        req.basic_auth(username, password)
      end

      response = http.request(request)

      @authentication = Authentication.new(JSON.parse(response.body))
    end

    def http
      @http ||= begin
        Net::HTTP.new(ROOT.host, ROOT.port).tap do |http|
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

    def parsed_json_from(response)
      if response.body.length > 0
        JSON.parse(response.body)
      else
        nil
      end
    end
  end
end
