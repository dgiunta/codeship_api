require 'codeship_api'
require 'sinatra/base'
require 'sucker_punch'
require 'pry'

module CodeshipApi
  class ProcessWebhookJob
    include SuckerPunch::Job

    def perform(repo_url, ref)
      org = Organization.find_by(ENV.fetch('CODESHIP_API_ORG_UUID'))
      project = org.projects.detect {|proj| proj.repository_url == repo_url }

      if project
        builds_to_keep, *builds_to_stop = project.builds
          .select {|build| build.testing? && build.ref == ref }
          .sort_by(&:queued_at)
          .reverse

        builds_to_stop.each(&:stop)
      end
    end
  end

  class GithubWebhookServer < Sinatra::Base
    configure :production, :development do
      enable :logging
    end

    get '/' do
      erb :homepage
    end

    post '/github_webhook' do
      request.body.rewind
      data = JSON.parse(request.body.read)

      ref = data['ref'].sub(/^refs\//, '')
      repo_url = data['repository']['html_url']

      ProcessWebhookJob.perform_async(repo_url, ref)

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
