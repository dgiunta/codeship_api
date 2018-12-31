module CodeshipApi
  class Build
    attr_reader :uuid, :project, :organization, :ref, :commit_sha,
      :status, :username, :commit_message, :finished_at, :allocated_at,
      :queued_at, :branch

    STATES = %w[testing error success stopped]
    def initialize(uuid:, project:, organization:, ref:, commit_sha:,
                   status:, username:, commit_message:, finished_at:,
                   allocated_at:, queued_at:, branch:)

      @uuid, @project, @organization, @ref, @commit_sha,
        @status, @username, @commit_message, @branch =
        uuid, project, organization, ref, commit_sha,
        status, username, commit_message, branch

      @finished_at = Time.parse(finished_at) if finished_at
      @allocated_at = Time.parse(allocated_at) if allocated_at
      @queued_at = Time.parse(queued_at) if queued_at
    end

    STATES.each do |state|
      define_method("#{state}?") do
        status == state
      end
    end

    def uri
      @uri ||= "#{project.uri}/builds/#{uuid}"
    end

    def stop
      CodeshipApi.client.post(uri + "/stop")
    end
  end
end
