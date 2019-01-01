require "test_helper"

describe CodeshipApi do
  it "has a version number" do
    CodeshipApi::VERSION.wont_be_nil
  end

  it "has a ROOT url" do
    CodeshipApi::ROOT.must_equal "https://api.codeship.com/v2/"
  end

  it "has a USERNAME and PASSWORD value based on environment values" do
    CodeshipApi::USERNAME.must_equal "username"
    CodeshipApi::PASSWORD.must_equal "password"
  end

  it "has a client instance" do
    CodeshipApi.client.class.must_equal CodeshipApi::Client
  end
end
