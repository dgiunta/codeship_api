module CodeshipApi
  class Organization < Base
    api_attrs :name, :scopes, :uuid

    def self.find_by(uuid)
      CodeshipApi.organizations.detect {|org| org.uuid == uuid }
    end

    def uri
      @uri ||= "/organizations/#{uuid}"
    end

    def projects
      @projects ||= Project.find_by_organization(self)
    end
  end
end
