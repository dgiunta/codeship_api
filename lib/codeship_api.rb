require "active_support/time"
require "net/http"
require "json"
require "codeship_api/version"
require 'codeship_api/configuration'
require "codeship_api/base"
require "codeship_api/organization"
require "codeship_api/project"
require "codeship_api/build"
require "codeship_api/pipeline"
require "codeship_api/authentication"
require "codeship_api/client"

module CodeshipApi
  ROOT = URI('https://api.codeship.com/v2/')

  class << self
    def configure(&block)
      configuration.instance_eval(&block)
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def client=(client)
      @client = client
    end

    def client
      @client ||= Client.new(configuration.username, configuration.password)
    end
    delegate :organizations, :projects, to: :client

    def excessive_builds(org_uuid, project_uuid, target_branch=nil)
      builds = Project.find_by(org_uuid, project_uuid).builds

      if target_branch
        builds.select! {|build| build.branch == target_branch }
      end

      builds
        .select(&:testing?)
        .group_by(&:branch)
        .inject({}) do |out, (branch, branch_builds)|
          keep, *remove = branch_builds.sort_by(&:queued_at).reverse
          out[branch] = [keep, remove]
          out
      end
    end

    def stop_excessive_builds(org_uuid, project_uuid, target_branch=nil)
      excessive_builds(org_uuid, project_uuid, target_branch)
        .flat_map {|branch, (_keep, remove)| remove }
        .each(&:stop)
    end

    def report_excessive_builds(org_uuid, project_uuid, target_branch=nil)
      excessive_builds(org_uuid, project_uuid, target_branch).each do |branch, (keep, remove)|
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
end
