require "redis"
class CreateOrUpdateApplicationJob
  # sidekiq_options retry: false
  include Sidekiq::Job

  def perform(application_token)
    app = ApplicationRepo.new.load_app(application_token)
    raise if app.nil?

    if app["id"].nil?
      created_app = Application.create(app.attributes)
      @redis = Redis.new(host: "host.docker.internal")
      @redis.set("Application_#{application_token}", created_app.to_json, px: 86400000)
    else
      Application.find_by(id: app.id).update(name: app.name, chats_count: app.chats_count)
    end
  end
end

