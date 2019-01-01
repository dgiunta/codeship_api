require 'test_helper'

describe CodeshipApi::Client do
  before do
    @client = CodeshipApi::Client.new
    @fake_success_response = Struct.new(:body).new('{"status": "OK"}')
    @fake_null_response = Struct.new(:body).new('')
    @mock_http = Minitest::Mock.new

    def @client.token
      "fake_token"
    end
  end

  describe "authenticate" do
    it "runs a POST request to /auth and returns an Authentication object" do
      token = "fake_token"
      expires_at = Time.now + (10 * 60 * 60) # 10 minutes from now
      org = {uuid: "asdf-asdf-asdf-asdf", name: "fake_org", scopes: []}

      auth_response = Struct.new(:body).new({
        access_token: token,
        expires_at: expires_at.to_i,
        organizations: [org]
      }.to_json)

      @mock_http.expect(:request, auth_response) do |request|
        request.path.must_equal "/v2/auth"
        request.to_hash["authorization"].first.must_match /^Basic/
      end

      @client.stub(:http, @mock_http) do
        auth = @client.send(:authenticate)
        auth.access_token.must_equal token
        auth.expires_at.to_i.must_equal expires_at.to_i
      end
    end
  end

  describe "authenticated?" do
    it "returns true if the authentication is valid" do
      auth = Struct.new(:valid?).new(true)
      @client.stub(:authentication, auth) do
        assert @client.authenticated?
      end
    end

    it "returns false if the authentication is not valid" do
      auth = Struct.new(:valid?).new(false)
      @client.stub(:authentication, auth) do
        refute @client.authenticated?
      end
    end
  end

  describe "get /test" do
    it "runs a GET request" do
      @mock_http.expect(:request, @fake_success_response, [Net::HTTP::Get])
      @client.stub(:http, @mock_http) do
        @client.get("/test")
      end
    end

    it "appends /test to the ROOT" do
      @mock_http.expect(:request, @fake_success_response) do |request|
        request.uri.to_s.must_equal "https://api.codeship.com/v2/test"
      end

      @client.stub(:http, @mock_http) do
        @client.get("/test")
      end
    end

    it "returns the JSON parsed response" do
      @mock_http.expect(:request, @fake_success_response, [Net::HTTP::Get])
      @client.stub(:http, @mock_http) do
        @client.get("/test").must_equal({"status" => "OK"})
      end
    end

    it "returns nil if the response is empty" do
      @mock_http.expect(:request, @fake_null_response, [Net::HTTP::Get])
      @client.stub(:http, @mock_http) do
        @client.get("/test").must_be_nil
      end
    end
  end

  describe "post /test" do
    it "runs a POST request" do
      @mock_http.expect(:request, @fake_success_response, [Net::HTTP::Post])
      @client.stub(:http, @mock_http) do
        @client.post("/test")
      end
    end

    it "appends /test to the ROOT" do
      @mock_http.expect(:request, @fake_success_response) do |request|
        request.uri.to_s.must_equal "https://api.codeship.com/v2/test"
      end

      @client.stub(:http, @mock_http) do
        @client.post("/test")
      end
    end

    it "returns the JSON parsed response" do
      @mock_http.expect(:request, @fake_success_response, [Net::HTTP::Post])
      @client.stub(:http, @mock_http) do
        @client.post("/test").must_equal({"status" => "OK"})
      end
    end

    it "returns nil if the response is empty" do
      @mock_http.expect(:request, @fake_null_response, [Net::HTTP::Post])
      @client.stub(:http, @mock_http) do
        @client.post("/test").must_be_nil
      end
    end
  end
end
