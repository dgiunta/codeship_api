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

    def self.find_all_by_project(
      project,
      page: 1, builds: [],
      filter_by: -> (build) { true },
      stop_when: -> (new_builds, page) { new_builds.empty? },
      &block
    )
      new_builds = find_by_project(project, page: page)
      new_filtered_builds = new_builds.select(&filter_by)

      builds += new_filtered_builds
      block.call(new_filtered_builds, page) if block

      if stop_when.call(new_builds, page)
        builds
      else
        find_all_by_project(
          project, page: page + 1, builds: builds,
          stop_when: stop_when, filter_by: filter_by,
          &block
        )
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

    def pipelines
      @pipelines ||= Pipeline.find_all_by_build(self)
    end

    def uri
      @uri ||= "#{project.uri}/builds/#{uuid}"
    end

    def stop
      CodeshipApi.client.post(uri + "/stop") if waiting? || testing?
    end

    def duration
      duration_in_seconds / 60
    end

    def duration_in_seconds
      (finished_at || Time.now) - (allocated_at || queued_at)
    end
  end
end
