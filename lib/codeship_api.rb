require "codeship_api/version"
require 'active_support/time'
require 'net/http'
require 'json'

module CodeshipApi
  ROOT = 'https://api.codeship.com/v2/'

  USERNAME = ENV.fetch('CODESHIP_API_USERNAME')
  PASSWORD = ENV.fetch('CODESHIP_API_PASSWORD')

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
      @uri ||= "/organziations/#{uuid}"
    end

    def projects
      @projects ||= Project.find_by_organization(self)
    end
  end

  class Project
    attr_reader :uuid, :id, :name, :type, :repository_url, :repository_provider,
      :organization, :created_at, :updated_at

    def self.find_by_organization(org)
      CodeshipApi.get("#{org.uri}/projects")["projects"].map do |proj|
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
      @uri ||= "/organizations/#{organization.uuid}/projects/#{uuid}"
    end

    def builds(per_page: 50, page: 1)
      CodeshipApi.get("#{uri}/builds?per_page=#{per_page}&page=#{page}")["builds"].map do |build|
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
      @uri ||= "/organizations/#{organization.uuid}/projects/#{project.uuid}/builds/#{uuid}"
    end

    def stop
      CodeshipApi.post(uri + "/stop")
    end
  end

  class Authentication
    attr_reader :access_token, :expires_at, :organizations

    def initialize(access_token:, expires_at:, organizations:)
      @access_token = access_token
      @expires_at = Time.at(expires_at)
      @organizations = organizations.map do |org|
        Organization.new(
          uuid: org['uuid'],
          name: org['name'],
          scopes: org['scopes']
        )
      end
    end

    def valid?
      Time.now < @expires_at
    end
  end

  def self.authentication
    @authentication ||= authenticate
  end

  def self.authenticated?
    @authentication && @authentication.valid?
  end

  def self.token
    if authenticated?
      authentication.access_token
    else
      @authentication = authenticate
      @authentication.access_token
    end
  end

  def self.authenticate(username=USERNAME, password=PASSWORD)
    uri = URI(ROOT + '/auth')

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri, {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    })
    request.basic_auth(username, password)

    response = http.request request

    data = JSON.parse(response.body)
    Authentication.new(
      access_token: data['access_token'],
      expires_at: data['expires_at'],
      organizations: data['organizations']
    )
  end

  def self.get(path, params={}, headers={})
    uri = URI(ROOT + path.sub(/^\//, ''))

    headers = {
      "Content-Type" => "application/json",
      "Accept" => "application/json",
      "Authorization" => "Bearer #{token}"
    }.merge(headers)

    request = Net::HTTP::Get.new(uri, headers)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    response = http.request request

    JSON.parse(response.body)
  end

  def self.post(path, params={}, headers={})
    uri = URI(ROOT + path.sub(/^\//, ''))

    headers = {
      "Content-Type" => "application/json",
      "Accept" => "application/json",
      "Authorization" => "Bearer #{token}"
    }.merge(headers)

    request = Net::HTTP::Post.new(uri, headers)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    response = http.request request

    JSON.parse(response.body)
  end

  def self.organizations
    authentication.organizations
  end

  def self.projects
    authentication.organizations.flat_map(&:projects)
  end

  def self.excessive_builds(org_uuid, project_uuid, branch=nil)
    builds = Project.find_by(org_uuid, project_uuid).builds

    if branch
      builds.select! {|build| build.branch == branch }
    end

    categorized_builds = builds
      .select(&:testing?)
      .group_by(&:branch)
      .inject({}) do |out, (branch, builds)|
        keep, *remove = builds.sort_by(&:queued_at).reverse
        out[branch] = [keep, remove]
        out
    end
  end

  def self.stop_excessive_builds(org_uuid, project_uuid, branch=nil)
    excessive_builds(org_uuid, project_uuid, branch).each do |branch, (_keep, remove)|
      remove.each(&:stop)
    end
  end

  def self.report_excessive_builds(org_uuid, project_uuid, branch=nil)
    excessive_builds(org_uuid, project_uuid, branch).each do |branch, (keep, remove)|
      puts "== Branch: #{branch}"
      puts "++ keep #{keep.uuid} - #{keep.queued_at}"
      remove.each do |build|
        puts "-- remove #{build.uuid} - #{build.queued_at}"
      end
      puts
    end

    nil
  end
end
