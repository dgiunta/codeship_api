$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require 'pry'
require 'dotenv'
Dotenv.load('.env', '.env.test')

require "codeship_api"

require "minitest/spec"
require "minitest/mock"
require "minitest/pride"
require "minitest/autorun"
