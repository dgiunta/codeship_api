require "codeship_api"
require "optionparser"

module CodeshipApi
  module Cli
    class << self
      def start(argv)
        command, *args = argv
        command ||= 'help'

        send(command.to_sym, *args)
      end

      def help
        puts <<-EOF.gsub(/^ {1,6}/, '')
          #{$PROGRAM_NAME} [sub_commands]
        EOF
      end

      def excess_builds
        org_uuid = ENV.fetch('CODESHIP_API_ORG_UUID')
        project_uuid = ENV.fetch('CODESHIP_API_PROJECT_UUID')
        puts CodeshipApi.report_excessive_builds(org_uuid, project_uuid)
      end

      def console
        require "pry"
        Pry.start(CodeshipApi)
      end

      def webhook_server(*args)
        require 'codeship_api/webhook_server'

        params = Rack::Server::Options.new.parse!(args)
        Rack::Server.start(params.merge(app: CodeshipApi::WebhookServer))
      end
    end
  end
end
