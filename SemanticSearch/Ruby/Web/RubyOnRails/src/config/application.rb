require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"

Bundler.require(*Rails.groups)

module SemanticSearchApp
  class Application < Rails::Application
    config.load_defaults 7.1
    config.eager_load = false
    config.logger = Logger.new(STDOUT)
    config.log_level = ENV.fetch("LOG_LEVEL", "info").to_sym
    config.secret_key_base = ENV.fetch("SECRET_KEY_BASE", "semantic-search-dev-key")
  end
end