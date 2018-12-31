require_relative './lib/codeship_api'
require_relative './lib/codeship_api/github_webhook_server'

run CodeshipApi::GithubWebhookServer
