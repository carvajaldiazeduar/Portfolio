Rails.application.configure do
  if ENV.fetch("CACHE_TYPE", "redis") == "local"
    config.cache_store = :memory_store
  else
    redis_host = ENV.fetch("REDIS_HOST", "localhost:6379")
    begin
      Redis.new(url: "redis://#{redis_host}").ping
      config.cache_store = :redis_cache_store, { url: "redis://#{redis_host}" }
    rescue StandardError
      config.cache_store = :memory_store
    end
  end
end