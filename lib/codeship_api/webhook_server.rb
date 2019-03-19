require 'codeship_api'
require 'sinatra/base'
require 'sucker_punch'
module CodeshipApi
  class ProcessWebhookJob
    include SuckerPunch::Job

    attr_reader :repo_url, :ref, :commit_sha

    def perform(repo_url, ref, commit_sha)
      @repo_url, @ref, @commit_sha = repo_url, ref, commit_sha

      if ignore_master?
        log "project=#{project.name} commit_sha=#{commit_sha} IGNORING MASTER COMMIT"
        return
      end

      start = Time.now
      log :start

      if project
        log "project=#{project.name} builds_to_stop=#{builds_to_stop.map(&:uuid).join(",")}"
        builds_to_stop.each(&:stop)
      end
      log "end (#{Time.now - start})"
    end

    private

    def ignore_master?
      ENV['IGNORE_MASTER'].to_b && ref =~ /^heads\/master$/
    end

    def project
      @project ||= CodeshipApi.projects.detect {|proj| proj.repository_url == repo_url }
    end

    def builds_to_stop
      @builds_to_stop ||= project.builds.select(&method(:excessive_build?))
    end

    def log(message="")
      puts [log_prefix, message].join(": ")
    end

    def log_prefix
      "[ProcessWebhookJob#perform repo_url=#{repo_url} ref=#{ref} commit_sha=#{commit_sha}]"
    end

    def excessive_build?(build)
      (build.testing? || build.waiting?) &&
        build.ref == ref &&
        build.commit_sha[0..10] != commit_sha[0..10]
    end
  end

  class WebhookServer < Sinatra::Base
    configure :production, :development do
      enable :logging
    end

    get '/' do
      erb :homepage
    end

    post '/github' do
      request.body.rewind
      data = JSON.parse(request.body.read)

      unless data['deleted']
        ref = data['ref'].sub(/^refs\//, '')
        repo_url = data['repository']['html_url']
        commit_sha = data['head_commit']['id'] if data['head_commit']

        ProcessWebhookJob.perform_async(repo_url, ref, commit_sha)
      end

      [201, {'Content-Type' => 'application/json'}, {'status': 'OK'}.to_json]
    end

    template :layout do
      <<-EOF.gsub(/^        /, '')
        <!DOCTYPE html5 />
        <html>
        <body>
        <%= yield %>
        </body>
        </html>
      EOF
    end

    template :homepage do
      <<-EOF.gsub(/^        /, '')
        <h1>Hello!</h1>
      EOF
    end

    run! if __FILE__ == $0
  end
end
