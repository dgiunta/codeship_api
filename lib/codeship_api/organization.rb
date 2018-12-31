module CodeshipApi
  class Organization
    attr_reader :uuid, :name, :scopes

    def self.find_by(uuid)
      cached_org = CodeshipApi.organizations.detect {|org| org.uuid == uuid }
      return cached_org if cached_org

      org = CodeshipApi.get("/organizations/#{uuid}")["organization"]
      new(
        uuid: org['uuid'],
        name: org['name'],
        scopes: org['scopes']
      )
    end

    def initialize(uuid:, name:, scopes:)
      @uuid = uuid
      @name = name
      @scopes = scopes
    end

    def uri
      @uri ||= "/organizations/#{uuid}"
    end

    def projects
      @projects ||= Project.find_by_organization(self)
    end
  end
end
