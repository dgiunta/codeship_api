module CodeshipApi
  class Build < Base
    api_attrs :allocated_at, :branch, :commit_message, :commit_sha,
      :finished_at, :organization_uuid, :project_uuid, :queued_at,
      :ref, :status, :username, :uuid

    parsed_time_attrs :queued_at, :allocated_at, :finished_at

    STATES = %w[waiting testing error success stopped].each do |state|
      define_method("#{state}?") do
        status == state
      end
    end

    def self.find_by_project(project, per_page: 50, page: 1)
      uri = "#{project.uri}/builds?per_page=#{per_page}&page=#{page}"
      CodeshipApi.client.get(uri)["builds"].map {|build| new(build) }
    end

    def organization
      @organization ||= project.organization
    end

    def project
      @project ||= Project.find_by(organization_uuid, project_uuid)
    end

    def uri
      @uri ||= "#{project.uri}/builds/#{uuid}"
    end

    def stop
      CodeshipApi.client.post(uri + "/stop") if waiting? || testing?
    end
  end
end
