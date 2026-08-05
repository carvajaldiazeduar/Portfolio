require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"

Bundler.require(*Rails.groups)

module DatabaseUrl
  module_function

  def build
    driver = ENV.fetch("DB_DRIVER", "pgsql")
    name = ENV.fetch("DB_NAME", "tasks")
    host = ENV.fetch("DB_HOST", "localhost")
    port = ENV.fetch("DB_PORT", "5432")
    user = ENV.fetch("DB_USER", "postgres")
    pass = ENV.fetch("DB_PASSWORD", "postgres")
    file = ENV.fetch("DB_FILE", "")

    case driver
    when "sqlite"
      file.empty? ? "sqlite3:db/tasks.sqlite3" : "sqlite3:#{file}"
    when "mysql"
      "mysql2://#{user}:#{pass}@#{host}:#{port}/#{name}"
    when "sqlserver", "mssql"
      "sqlserver://#{user}:#{pass}@#{host}:#{port}/#{name}"
    else
      "postgresql://#{user}:#{pass}@#{host}:#{port}/#{name}"
    end
  end
end

module TasksListApp
  class Application < Rails::Application
    config.load_defaults 7.1

    config.eager_load = false
    config.logger = Logger.new(STDOUT)
    config.log_level = ENV.fetch("LOG_LEVEL", "info").to_sym
    config.secret_key_base = ENV.fetch("SECRET_KEY_BASE", "taskslist-development-secret-key")

    ENV["DATABASE_URL"] = DatabaseUrl.build
  end
end
