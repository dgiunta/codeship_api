module CodeshipApi
  class Project < Base
    api_attrs :created_at, :name, :organization_uuid, :repository_provider,
      :repository_url, :type, :updated_at, :uuid

    def self.find_by_organization(org)
      CodeshipApi.client.get("#{org.uri}/projects")["projects"].map {|proj| new(proj) }
    end

    def self.find_by(org_uuid, proj_uuid)
      Organization.find_by(org_uuid).projects.detect {|proj| proj.uuid == proj_uuid }
    end

    def organization
      @organization ||= Organization.find_by(organization_uuid)
    end

    def uri
      @uri ||= "#{organization.uri}/projects/#{uuid}"
    end

    def builds(page: 1, per_page: 50)
      Build.find_by_project(self, page: page, per_page: per_page)
    end
  end
end
