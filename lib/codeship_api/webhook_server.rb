require 'codeship_api'
require 'sinatra/base'
require 'sucker_punch'
module CodeshipApi
  class ProcessWebhookJob
    include SuckerPunch::Job

    def perform(repo_url, ref, commit_sha)
      project = CodeshipApi.projects.detect {|proj| proj.repository_url == repo_url }

      if project
        builds_to_stop = project
          .builds
          .select do |build|
            (build.testing? || build.waiting?) &&
              build.ref == ref &&
              build.commit_sha.first(10) != commit_sha.first(10)
          end

        puts "project: #{project.name}"
        puts "builds_to_stop: #{builds_to_stop.map(&:uuid).join(", ")}"

        builds_to_stop.each(&:stop)
      end
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

      ref = data['ref'].sub(/^refs\//, '')
      repo_url = data['repository']['html_url']
      commit_sha = data['head']

      ProcessWebhookJob.perform_async(repo_url, ref, commit_sha)

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
