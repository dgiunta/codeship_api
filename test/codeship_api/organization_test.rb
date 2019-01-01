require 'test_helper'

describe CodeshipApi::Organization do
  describe "#uri" do
    it "returns '/organizations/<uuid>'" do
      uuid = "asdf-asdf-asdf-asdf"
      org = CodeshipApi::Organization.new(uuid: uuid, name: 'blah', scopes: [])
      org.uri.must_equal "/organizations/#{uuid}"
    end
  end
end
