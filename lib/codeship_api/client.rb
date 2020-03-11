module CodeshipApi
  class Client
    class RateLimitExceededError < StandardError; end

    def initialize(username=USERNAME, password=PASSWORD)
      @username = username
      @password = password
    end

    def authenticated?
      authentication.valid?
    end

    def get(path)
      rate_limit_protected! do
        uri = URI.join(ROOT, path.sub(/^\//, ""))

        request = Net::HTTP::Get.new(uri, default_headers)
        response = http.request(request)

        parse_errors_from(response)
        parsed_json_from(response)
      end
    end

    def post(path)
      rate_limit_protected! do
        uri = URI.join(ROOT, path.sub(/^\//, ""))

        request = Net::HTTP::Post.new(uri, default_headers)
        response = http.request(request)

        parse_errors_from(response)
        parsed_json_from(response)
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

    def rate_limit_protected!(&block)
      time_start = Time.now
      block.call.tap do
        duration = Time.now - time_start
        sleep 1.second - duration if duration < 1.second
      end
    rescue RateLimitExceededError => e
      sleep_duration = 60
      print "waiting #{sleep_duration}s for rate limit..."
      sleep sleep_duration
      puts " done."
      rate_limit_protected!(&block)
    end

    def token
      authenticate unless authenticated?
      authentication.access_token
    end

    def authentication
      @authentication || authenticate
    end

    def authenticate
      rate_limit_protected! do
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

    def parse_errors_from(response)
      if response.code.to_i == 403 && response.entity == "Rate Limit Exceeded"
        raise RateLimitExceededError.new(response)
      end
    end

    def parsed_json_from(response)
      return nil unless response.body.length > 0

      JSON.parse(response.body)
    end
  end
end
