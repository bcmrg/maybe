require "sidekiq/web"
require "sidekiq/cron/web"

# Configure Redis connection
redis_config = { url: ENV.fetch("REDIS_URL", "redis://redis:6379/1") }
Sidekiq.configure_server do |config|
  config.redis = redis_config
  
  # Load cron jobs from config/schedule.yml
  schedule_file = Rails.root.join("config/schedule.yml")
  if File.exist?(schedule_file)
    Sidekiq::Cron::Job.load_from_hash(YAML.load_file(schedule_file))
  end
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end

# Configure Sidekiq web UI authentication
Sidekiq::Web.use(Rack::Auth::Basic) do |username, password|
  configured_username = ::Digest::SHA256.hexdigest(ENV.fetch("SIDEKIQ_WEB_USERNAME", "maybe"))
  configured_password = ::Digest::SHA256.hexdigest(ENV.fetch("SIDEKIQ_WEB_PASSWORD", "maybe"))

  ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username), configured_username) &&
    ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password), configured_password)
end
