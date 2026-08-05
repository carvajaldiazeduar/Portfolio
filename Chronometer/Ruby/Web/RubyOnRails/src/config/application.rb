require_relative "boot"

require "rails"
require "active_model/railtie"
require "action_controller/railtie"
require "action_view/railtie"

Bundler.require(*Rails.groups)

module ChronometerApp
  class Application < Rails::Application
    config.load_defaults 7.1

    config.eager_load = false
    config.logger = Logger.new(STDOUT)
    config.log_level = ENV.fetch("LOG_LEVEL", "info").to_sym
    config.secret_key_base = ENV.fetch("SECRET_KEY_BASE", "chronometer-development-secret-key")
  end
end