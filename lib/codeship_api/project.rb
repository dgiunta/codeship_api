module CodeshipApi
  class Project
    attr_reader :uuid, :id, :name, :type, :repository_url, :repository_provider,
      :organization, :created_at, :updated_at

    def self.find_by_organization(org)
      CodeshipApi.client.get("#{org.uri}/projects")["projects"].map do |proj|
        new(
          uuid: proj['uuid'],
          id: proj['id'],
          name: proj['name'],
          type: proj['type'],
          repository_url: proj['repository_url'],
          repository_provider: proj['repository_provider'],
          organization: org,
          created_at: proj['created_at'],
          updated_at: proj['updated_at']
        )
      end
    end

    def self.find_by(org_uuid, proj_uuid)
      Organization.find_by(org_uuid).projects.detect {|proj| proj.uuid == proj_uuid }
    end

    def initialize(uuid:, id:, name:, type:, repository_url:, repository_provider:,
                   organization:, created_at:, updated_at:)
      @uuid, @id, @name, @type, @repository_url, @repository_provider,
        @organization, @created_at, @updated_at =
        uuid, id, name, type, repository_url, repository_provider,
        organization, created_at, updated_at
    end

    def uri
      @uri ||= "#{organization.uri}/projects/#{uuid}"
    end

    def builds(per_page: 50, page: 1)
      CodeshipApi.client.get("#{uri}/builds?per_page=#{per_page}&page=#{page}")["builds"].map do |build|
        Build.new(
          uuid: build['uuid'],
          project: self,
          organization: organization,
          ref: build['ref'],
          commit_sha: build['commit_sha'],
          status: build['status'],
          username: build['username'],
          commit_message: build['commit_message'],
          finished_at: build['finished_at'],
          allocated_at: build['allocated_at'],
          queued_at: build['queued_at'],
          branch: build['branch']
        )
      end
    end
  end
end
