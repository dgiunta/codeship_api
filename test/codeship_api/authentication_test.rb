require 'test_helper'

describe CodeshipApi::Authentication do
  describe "valid?" do
    before do
      @expires_at = Time.now
      @auth = CodeshipApi::Authentication.new(
        access_token: "blah",
        expires_at: @expires_at,
        organizations: []
      )
    end

    it "returns true if the expires_at is in the future" do
      Time.stub(:now, @expires_at - 1) do
        assert @auth.valid?
      end
    end

    it "returns false if the expires_at is now" do
      Time.stub(:now, @expires_at) do
        refute @auth.valid?
      end
    end

    it "returns false if the expires_at is in the past" do
      Time.stub(:now, @expires_at + 1) do
        refute @auth.valid?
      end
    end
  end
end
