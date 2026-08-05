class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  private

  def cache
    Rails.cache
  end

  def cache_ttl
    ENV.fetch("CACHE_TTL", "300").to_i
  end
end