Sidekiq.configure_server do |config|
    config.redis = { url: ENV.fetch('REDIS_URL_SIDEKIQ', 'redis://host.docker.internal:6379/12') }
end

Sidekiq.configure_client do |config|
    config.redis = { url: ENV.fetch('REDIS_URL_SIDEKIQ', 'redis://host.docker.internal:6379/12') }
end